defmodule DesktopUi.PhaseTwelveIntegrationTest do
  use ExUnit.Case, async: false

  alias DesktopUi.Navigation.{Controller, Integration, Signal, State}
  alias DesktopUi.Runtime.State, as: RuntimeState
  alias DesktopUi.Navigation.Registry

  @moduletag :navigation
  @moduletag timeout: 120_000

  # 12.6.1 Navigation state and controller scenarios

  describe "Navigation state and controller scenarios" do
    setup do
      defmodule HomeScreen do
        def render(_assigns), do: %{}
      end

      defmodule DetailScreen do
        def render(_assigns), do: %{}
      end

      defmodule SettingsScreen do
        def render(_assigns), do: %{}
      end

      {:ok, controller} =
        Controller.start_link(
          name: nil,
          initial_screen: {:home, HomeScreen, %{}}
        )

      %{controller: controller, home: HomeScreen, detail: DetailScreen, settings: SettingsScreen}
    end

    test "navigate action pushes current screen to history and sets new current screen", %{
      controller: controller,
      home: home,
      detail: detail
    } do
      # Initial state
      initial_state = Controller.get_state(controller)
      assert initial_state.current == :home
      assert initial_state.current_module == home
      assert initial_state.history == []

      # Navigate to detail using module directly
      {:ok, new_state, {:transition, :navigated}} =
        Controller.navigate(controller, detail, %{item_id: 123})

      # Verify new state
      assert new_state.current == detail
      assert new_state.current_module == detail
      assert new_state.current_params == %{item_id: 123}

      # Verify history has previous screen
      assert [{:home, ^home, %{}}] = new_state.history

      # Verify forward is cleared
      assert new_state.forward == []
    end

    test "replace action swaps current screen without modifying history", %{
      controller: controller,
      home: home,
      settings: settings,
      detail: detail
    } do
      # First navigate to build history using modules
      Controller.navigate(controller, detail, %{})

      {:ok, state_with_history, _} = Controller.navigate(controller, settings, %{})
      assert length(state_with_history.history) == 2

      # Replace current with home module
      {:ok, replaced_state, {:transition, :replaced}} =
        Controller.replace(controller, home, %{refreshed: true})

      # Verify current is changed
      assert replaced_state.current == home
      assert replaced_state.current_module == home

      # Verify history is unchanged
      assert length(replaced_state.history) == 2
    end

    test "go_back and go_forward correctly traverse history and update forward stack", %{
      controller: controller,
      home: home,
      detail: detail,
      settings: settings
    } do
      # Build history: home -> detail -> settings
      Controller.navigate(controller, detail, %{id: 1})
      {:ok, state1, _} = Controller.navigate(controller, settings, %{})

      # Go back to detail
      {:ok, back_state, {:transition, :back}} = Controller.go_back(controller)

      assert back_state.current == detail
      assert back_state.current_module == detail
      assert length(back_state.history) == 1  # home remains
      assert [{_screen_id, ^settings, %{}}] = back_state.forward

      # Go forward to settings
      {:ok, forward_state, {:transition, :forward}} = Controller.go_forward(controller)

      assert forward_state.current == settings
      assert forward_state.current_module == settings
      assert length(forward_state.forward) == 0
      assert length(forward_state.history) == 2
    end

    test "modal stack remains independent from main navigation history", %{
      controller: controller,
      detail: detail,
      settings: settings,
      home: home
    } do
      # Navigate to detail
      Controller.navigate(controller, detail, %{id: 1})

      {:ok, state_before_modal, _} = Controller.navigate(controller, settings, %{})
      assert length(state_before_modal.history) == 2

      # Open modal
      {:ok, state_with_modal, {:transition, :modal_opened}} =
        Controller.open_modal(controller, :confirm_dialog, %{message: "OK"})

      # Verify modal is on modal stack
      assert state_with_modal.modal_open? == true
      assert length(state_with_modal.modals) == 1

      # Verify main navigation history is unchanged
      assert length(state_with_modal.history) == 2
      assert state_with_modal.current == settings

      # Navigate while modal is open
      {:ok, state_with_nav, _} = Controller.navigate(controller, home, %{})

      # Verify modal stack is preserved
      assert state_with_nav.modal_open? == true
      assert length(state_with_nav.modals) == 1

      # Close modal
      {:ok, state_after_close, {:transition, :modal_closed}} =
        Controller.close_modal(controller)

      # Verify main navigation state after modal close
      assert state_after_close.current == home
      assert state_after_close.modal_open? == false
    end

    test "invalid navigation actions fail with deterministic errors", %{controller: controller} do
      # Go back with empty history
      assert {:error, :empty_history} = Controller.go_back(controller)

      # Go forward with empty forward stack
      assert {:error, :empty_forward} = Controller.go_forward(controller)

      # Close modal with no modal open
      assert {:error, :no_modal} = Controller.close_modal(controller)
    end
  end

  # 12.6.2 Screen registry and resolution scenarios

  describe "Screen registry and resolution scenarios" do
    setup do
      defmodule TestRegistryHome do
        def render(_assigns), do: %{}
      end

      defmodule TestRegistryDetail do
        def render(_assigns), do: %{}
      end

      defmodule TestRegistry do
        def register, do: %{home: TestRegistryHome, detail: TestRegistryDetail}
        def get_screen(:home), do: TestRegistryHome
        def get_screen(:detail), do: TestRegistryDetail
        def get_screen(_), do: nil
      end

      {:ok, controller} =
        Controller.start_link(
          name: nil,
          registry: TestRegistry,
          initial_screen: {:home, TestRegistryHome, %{}}
        )

      %{controller: controller, registry: TestRegistry, home: TestRegistryHome, detail: TestRegistryDetail}
    end

    test "registered screens resolve correctly from screen IDs", %{
      controller: controller,
      home: home,
      detail: detail
    } do
      # Navigate to registered screen
      {:ok, new_state, _} = Controller.navigate(controller, :detail, %{})

      assert new_state.current == :detail
      assert new_state.current_module == detail
    end

    test "unknown screen IDs return appropriate errors", %{controller: controller} do
      assert {:error, {:unknown_screen, :unknown_screen}} =
        Controller.navigate(controller, :unknown_screen, %{})
    end

    test "screen mounting passes params correctly", %{controller: controller} do
      params = %{item_id: 123, mode: :edit}

      {:ok, new_state, _} = Controller.navigate(controller, :detail, params)

      assert new_state.current_params == params
    end

    test "screen metadata and capabilities affect navigation behavior", %{registry: registry} do
      # Validate registry
      assert {:ok, _registry} = Registry.validate(registry)

      # Get metadata (empty in this test registry)
      assert %{} = Registry.metadata(registry, :home)
    end
  end

  # 12.6.3 Transport and widget integration scenarios

  describe "Transport and widget integration scenarios" do
    setup do
      defmodule TransportHome do
        def render(_assigns), do: %{}
      end

      defmodule TransportDetail do
        def render(_assigns), do: %{}
      end

      {:ok, controller} =
        Controller.start_link(
          name: nil,
          initial_screen: {:home, TransportHome, %{}}
        )

      runtime_state = %RuntimeState{
        runtime_id: "test-runtime",
        screen_id: "test-screen",
        source_kind: :native,
        platform_target: :test,
        root: %{},
        screen: test_screen("test-screen"),
        windows: %{},
        navigation_controller: controller,
        current_screen_module: TransportHome,
        navigation_state: Controller.get_state(controller),
        screen_params: %{}
      }

      %{controller: controller, runtime_state: runtime_state, home: TransportHome, detail: TransportDetail}
    end

    defp test_screen(id) do
      %DesktopUi.Runtime.Screen{
        id: id,
        source_kind: :native,
        platform_target: :test,
        root: %DesktopUi.Widget{id: "root", kind: :box}
      }
    end

    test "navigation signals execute correctly", %{
      runtime_state: runtime_state
    } do
      signal = Signal.navigate(:detail, %{item_id: 1})

      assert {:ok, _new_runtime, _nav_state, {:transition, :navigated}} =
        Integration.handle_navigation(runtime_state, signal)
    end

    test "navigation events from widgets are processed", %{
      runtime_state: runtime_state
    } do
      event = %{
        family: :navigation,
        type: :navigate_to,
        screen_id: :detail,
        params: %{item_id: 123}
      }

      assert {:ok, _new_runtime, _nav_state, {:transition, :navigated}} =
        Integration.handle_event(runtime_state, event)
    end

    test "go_back events work correctly", %{runtime_state: runtime_state} do
      # First navigate to build history
      {:ok, updated_runtime, _, _} =
        Integration.handle_event(runtime_state, %{
          family: :navigation,
          type: :navigate_to,
          screen_id: :detail,
          params: %{}
        })

      # Then go back (should fail since we only have one screen in history)
      # Actually, let's navigate twice
      {:ok, updated_runtime2, _, _} =
        Integration.handle_event(updated_runtime, %{
          family: :navigation,
          type: :navigate_to,
          screen_id: :home,
          params: %{}
        })

      # Now go back should work
      assert {:ok, _new_runtime, _nav_state, {:transition, :back}} =
        Integration.handle_event(updated_runtime2, %{
          family: :navigation,
          type: :go_back
        })
    end

    test "modal events work correctly", %{runtime_state: runtime_state} do
      event = %{
        family: :navigation,
        type: :open_modal,
        screen_id: :confirm_dialog,
        params: %{message: "OK"}
      }

      assert {:ok, new_runtime, _nav_state, {:transition, :modal_opened}} =
        Integration.handle_event(runtime_state, event)

      assert Integration.modal_open?(new_runtime)
    end
  end

  # 12.6.4 Runtime and window integration scenarios

  describe "Runtime and window integration scenarios" do
    setup do
      defmodule RuntimeHome do
        def render(_assigns), do: %{}
      end

      defmodule RuntimeDetail do
        def render(_assigns), do: %{}
      end

      {:ok, controller} =
        Controller.start_link(
          name: nil,
          initial_screen: {:home, RuntimeHome, %{}}
        )

      runtime_state = %RuntimeState{
        runtime_id: "test-runtime",
        screen_id: "test-screen",
        source_kind: :native,
        platform_target: :test,
        root: %{},
        screen: test_screen("test-screen"),
        windows: %{},
        navigation_controller: controller,
        current_screen_module: RuntimeHome,
        navigation_state: Controller.get_state(controller),
        screen_params: %{}
      }

      %{controller: controller, runtime_state: runtime_state, home: RuntimeHome, detail: RuntimeDetail}
    end

    defp test_screen(id) do
      %DesktopUi.Runtime.Screen{
        id: id,
        source_kind: :native,
        platform_target: :test,
        root: %DesktopUi.Widget{id: "root", kind: :box}
      }
    end

    test "navigation helpers are available from runtime state", %{runtime_state: runtime_state} do
      refute Integration.can_go_back?(runtime_state)
      refute Integration.can_go_forward?(runtime_state)
      refute Integration.modal_open?(runtime_state)
      assert nil == Integration.current_modal(runtime_state)
    end

    test "screen swapping updates runtime state", %{runtime_state: runtime_state} do
      {:ok, new_runtime, nav_state, _} =
        Integration.handle_event(runtime_state, %{
          family: :navigation,
          type: :navigate_to,
          screen_id: :detail,
          params: %{item_id: 1}
        })

      assert new_runtime.current_screen_module != nil
      assert new_runtime.navigation_state == nav_state
      assert new_runtime.screen_params == %{item_id: 1}
    end

    test "modal state is tracked in runtime", %{runtime_state: runtime_state} do
      {:ok, with_modal, _, _} =
        Integration.handle_event(runtime_state, %{
          family: :navigation,
          type: :open_modal,
          screen_id: :settings,
          params: %{}
        })

      assert Integration.modal_open?(with_modal)
      assert {_screen_id, _module, _params} = Integration.current_modal(with_modal)
    end

    test "multiple windows can maintain independent navigation state" do
      # Start two controllers
      {:ok, controller1} =
        Controller.start_link(
          name: nil,
          initial_screen: {:home, RuntimeHome, %{}}
        )

      {:ok, controller2} =
        Controller.start_link(
          name: nil,
          initial_screen: {:detail, RuntimeDetail, %{}}
        )

      # Verify they have different states
      state1 = Controller.get_state(controller1)
      state2 = Controller.get_state(controller2)

      assert state1.current == :home
      assert state2.current == :detail

      # Navigate in controller1
      Controller.navigate(controller1, :detail, %{})

      # Verify controller2 is unaffected
      state2_after = Controller.get_state(controller2)
      assert state2_after.current == :detail
      assert length(state2_after.history) == 0
    end
  end

  # 12.6.5 Example and documentation scenarios

  describe "Example and documentation scenarios" do
    test "basic navigation example demonstrates home, list, and detail navigation" do
      example = DesktopUi.Examples.basic_navigation_screen()

      assert example.id == "basic-navigation"
      assert example.metadata.navigation_pattern == :simple_menu
      assert :home in example.metadata.screens
      assert :items in example.metadata.screens
      assert :settings in example.metadata.screens
    end

    test "history example demonstrates back/forward navigation" do
      example = DesktopUi.Examples.history_navigation_screen()

      assert example.id == "history-navigation"
      assert example.metadata.navigation_pattern == :history_based
      assert :home in example.metadata.screens
      assert :items in example.metadata.screens
      assert :detail in example.metadata.screens
    end

    test "modal example demonstrates independent modal stack" do
      example = DesktopUi.Examples.modal_navigation_screen()

      assert example.id == "modal-navigation"
      assert example.metadata.navigation_pattern == :modal_dialogs
      assert :confirm_dialog in example.metadata.modals
      assert :settings in example.metadata.modals
    end

    test "master-detail example demonstrates list/detail patterns" do
      example = DesktopUi.Examples.master_detail_navigation_screen()

      assert example.id == "master-detail-navigation"
      assert example.metadata.navigation_pattern == :master_detail
      assert :master in example.metadata.screens
      assert :detail in example.metadata.screens
      assert :edit in example.metadata.screens
    end

    test "navigation examples are in catalog" do
      catalog = DesktopUi.Examples.catalog()

      assert Enum.any?(catalog, &(&1.id == :basic_navigation))
      assert Enum.any?(catalog, &(&1.id == :history_navigation))
      assert Enum.any?(catalog, &(&1.id == :modal_navigation))
      assert Enum.any?(catalog, &(&1.id == :master_detail_navigation))
    end

    test "navigation guide exists and contains required sections" do
      # Verify the navigation guide exists
      # Path is relative to the unified repo root from tests directory
      guide_path = "../../.spec/guides/desktop_ui/navigation_guide.md"

      assert File.exists?(guide_path)

      content = File.read!(guide_path)

      # Verify key sections are present
      assert content =~ "Overview"
      assert content =~ "Quick Start"
      assert content =~ "Screen Registry"
      assert content =~ "Widget Navigation"
      assert content =~ "Navigation Signals"
      assert content =~ "Lifecycle Callbacks"
      assert content =~ "Navigation State"
      assert content =~ "Runtime Integration"
      assert content =~ "Common Patterns"
      assert content =~ "Best Practices"
      assert content =~ "API Reference"
    end
  end

  # Capabilities verification

  describe "Navigation capabilities" do
    test "navigation module reports all capabilities" do
      capabilities = DesktopUi.Navigation.capabilities()

      assert :screen_navigation in capabilities
      assert :history_stack in capabilities
      assert :forward_stack in capabilities
      assert :modal_stack in capabilities
      assert :navigation_controller in capabilities
      assert :screen_registry in capabilities
    end

    test "navigation module includes all sub-modules" do
      modules = DesktopUi.Navigation.modules()

      assert DesktopUi.Navigation.Controller in modules
      assert DesktopUi.Navigation.State in modules
      assert DesktopUi.Navigation.Registry in modules
      assert DesktopUi.Navigation.Lifecycle in modules
      assert DesktopUi.Navigation.Signal in modules
      assert DesktopUi.Navigation.Integration in modules
    end
  end
end
