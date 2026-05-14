defmodule DesktopUi.Navigation.IntegrationTest do
  use ExUnit.Case
  alias DesktopUi.Navigation.{Controller, Integration, Signal}
  alias DesktopUi.Runtime.State, as: RuntimeState

  @moduletag :navigation

  # Helper to create a minimal valid Screen struct for tests
  defp test_screen(id) do
    %DesktopUi.Runtime.Screen{
      id: id,
      source_kind: :native,
      platform_target: :test,
      root: %DesktopUi.Widget{id: "root", kind: :box}
    }
  end

  describe "handle_navigation/2" do
    setup do
      defmodule MockScreen do
        def render(_assigns), do: %{}
      end

      {:ok, controller} =
        Controller.start_link(
          name: nil,
          initial_screen: {:home, MockScreen, %{}}
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
        current_screen_module: MockScreen,
        navigation_state: Controller.get_state(controller),
        screen_params: %{}
      }

      %{controller: controller, runtime_state: runtime_state}
    end

    test "handles navigate_to signal", %{runtime_state: runtime_state} do
      signal = Signal.navigate(:detail, %{item_id: 123})

      assert {:ok, new_runtime, _nav_state, {:transition, :navigated}} =
               Integration.handle_navigation(runtime_state, signal)

      assert new_runtime.current_screen_module == DesktopUi.Navigation.Controller.MockScreen.Detail
      assert new_runtime.screen_params == %{item_id: 123}
    end

    test "handles replace_with signal", %{runtime_state: runtime_state} do
      signal = Signal.replace(:error, %{code: 404})

      assert {:ok, _new_runtime, _nav_state, {:transition, :replaced}} =
               Integration.handle_navigation(runtime_state, signal)
    end

    test "handles go_back signal when history is empty", %{runtime_state: runtime_state} do
      signal = Signal.go_back()

      assert {:error, :empty_history} = Integration.handle_navigation(runtime_state, signal)
    end

    test "handles go_forward signal when forward is empty", %{runtime_state: runtime_state} do
      signal = Signal.go_forward()

      assert {:error, :empty_forward} = Integration.handle_navigation(runtime_state, signal)
    end

    test "handles open_modal signal", %{runtime_state: runtime_state} do
      signal = Signal.open_modal(:confirm_dialog, %{message: "OK"})

      assert {:ok, new_runtime, _nav_state, {:transition, :modal_opened}} =
               Integration.handle_navigation(runtime_state, signal)

      assert Integration.modal_open?(new_runtime)
    end

    test "handles close_modal signal", %{runtime_state: runtime_state} do
      # First open a modal
      {:ok, runtime_with_modal, _nav, _transition} =
        Integration.handle_navigation(runtime_state, Signal.open_modal(:confirm_dialog))

      # Then close it
      signal = Signal.close_modal()
      result = Integration.handle_navigation(runtime_with_modal, signal)

      assert {:ok, _new_runtime, _nav_state, {:transition, :modal_closed}} = result
    end

    test "returns error when no navigation controller", %{runtime_state: runtime_state} do
      runtime_without_controller = %{runtime_state | navigation_controller: nil}
      signal = Signal.navigate(:detail)

      assert {:error, :no_navigation_controller} =
               Integration.handle_navigation(runtime_without_controller, signal)
    end
  end

  describe "handle_event/2" do
    setup do
      defmodule MockScreen2 do
        def render(_assigns), do: %{}
      end

      {:ok, controller} =
        Controller.start_link(
          name: nil,
          initial_screen: {:home, MockScreen2, %{}}
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
        current_screen_module: MockScreen2,
        navigation_state: Controller.get_state(controller),
        screen_params: %{}
      }

      %{controller: controller, runtime_state: runtime_state}
    end

    test "handles navigate_to event", %{runtime_state: runtime_state} do
      event = %{
        family: :navigation,
        type: :navigate_to,
        screen_id: :detail,
        params: %{item_id: 1}
      }

      assert {:ok, _new_runtime, _nav_state, {:transition, :navigated}} =
               Integration.handle_event(runtime_state, event)
    end

    test "handles replace_with event", %{runtime_state: runtime_state} do
      event = %{
        family: :navigation,
        type: :replace_with,
        screen_id: :error,
        params: %{code: 500}
      }

      assert {:ok, _new_runtime, _nav_state, {:transition, :replaced}} =
               Integration.handle_event(runtime_state, event)
    end

    test "handles go_back event", %{runtime_state: runtime_state} do
      event = %{
        family: :navigation,
        type: :go_back
      }

      assert {:error, :empty_history} = Integration.handle_event(runtime_state, event)
    end

    test "handles go_forward event", %{runtime_state: runtime_state} do
      event = %{
        family: :navigation,
        type: :go_forward
      }

      assert {:error, :empty_forward} = Integration.handle_event(runtime_state, event)
    end

    test "handles open_modal event", %{runtime_state: runtime_state} do
      event = %{
        family: :navigation,
        type: :open_modal,
        screen_id: :settings,
        params: %{}
      }

      assert {:ok, _new_runtime, _nav_state, {:transition, :modal_opened}} =
               Integration.handle_event(runtime_state, event)
    end

    test "handles close_modal event", %{runtime_state: runtime_state} do
      event = %{
        family: :navigation,
        type: :close_modal
      }

      assert {:error, :no_modal} = Integration.handle_event(runtime_state, event)
    end

    test "returns error for missing screen_id", %{runtime_state: runtime_state} do
      event = %{
        family: :navigation,
        type: :navigate_to
      }

      assert {:error, :missing_screen_id} = Integration.handle_event(runtime_state, event)
    end

    test "returns error for unknown navigation type", %{runtime_state: runtime_state} do
      event = %{
        family: :navigation,
        type: :unknown_type
      }

      assert {:error, :unknown_navigation_type} =
               Integration.handle_event(runtime_state, event)
    end
  end

  describe "navigation_event?/1" do
    test "returns true for navigation events" do
      assert Integration.navigation_event?(%{family: :navigation, type: :navigate_to})
      assert Integration.navigation_event?(%{family: :navigation})
    end

    test "returns false for non-navigation events" do
      refute Integration.navigation_event?(%{family: :click})
      refute Integration.navigation_event?(%{family: :change})
      refute Integration.navigation_event?(%{type: :navigate_to})
    end
  end

  describe "current_screen_module/1" do
    test "returns the current screen module" do
      defmodule TestScreen do
      end

      runtime_state = %RuntimeState{
        runtime_id: "test",
        screen_id: "test",
        source_kind: :native,
        platform_target: :test,
        root: %{},
        screen: test_screen("test-screen"),
        windows: %{},
        current_screen_module: TestScreen
      }

      assert TestScreen = Integration.current_screen_module(runtime_state)
    end

    test "returns nil when no screen module" do
      runtime_state = %RuntimeState{
        runtime_id: "test",
        screen_id: "test",
        source_kind: :native,
        platform_target: :test,
        root: %{},
        screen: test_screen("test-screen"),
        windows: %{}
      }

      assert nil == Integration.current_screen_module(runtime_state)
    end
  end

  describe "current_screen_params/1" do
    test "returns the current screen params" do
      runtime_state = %RuntimeState{
        runtime_id: "test",
        screen_id: "test",
        source_kind: :native,
        platform_target: :test,
        root: %{},
        screen: test_screen("test-screen"),
        windows: %{},
        screen_params: %{item_id: 123, mode: :edit}
      }

      assert %{item_id: 123, mode: :edit} = Integration.current_screen_params(runtime_state)
    end
  end

  describe "modal_open?/1" do
    test "returns true when modal is open" do
      nav_state = %DesktopUi.Navigation.State{modals: [{:modal, Module, %{}}], modal_open?: true}

      runtime_state = %RuntimeState{
        runtime_id: "test",
        screen_id: "test",
        source_kind: :native,
        platform_target: :test,
        root: %{},
        screen: test_screen("test-screen"),
        windows: %{},
        navigation_state: nav_state
      }

      assert Integration.modal_open?(runtime_state)
    end

    test "returns false when no modal is open" do
      runtime_state = %RuntimeState{
        runtime_id: "test",
        screen_id: "test",
        source_kind: :native,
        platform_target: :test,
        root: %{},
        screen: test_screen("test-screen"),
        windows: %{},
        navigation_state: nil
      }

      refute Integration.modal_open?(runtime_state)
    end
  end

  describe "current_modal/1" do
    test "returns current modal when open" do
      nav_state = %DesktopUi.Navigation.State{modals: [{:confirm, ConfirmDialog, %{message: "OK"}}]}

      runtime_state = %RuntimeState{
        runtime_id: "test",
        screen_id: "test",
        source_kind: :native,
        platform_target: :test,
        root: %{},
        screen: test_screen("test-screen"),
        windows: %{},
        navigation_state: nav_state
      }

      assert {:confirm, ConfirmDialog, %{message: "OK"}} = Integration.current_modal(runtime_state)
    end

    test "returns nil when no modal" do
      runtime_state = %RuntimeState{
        runtime_id: "test",
        screen_id: "test",
        source_kind: :native,
        platform_target: :test,
        root: %{},
        screen: test_screen("test-screen"),
        windows: %{},
        navigation_state: nil
      }

      assert nil == Integration.current_modal(runtime_state)
    end
  end

  describe "can_go_back?/1" do
    test "returns true when history has items" do
      nav_state = %DesktopUi.Navigation.State{history: [{:home, HomeScreen, %{}}]}

      runtime_state = %RuntimeState{
        runtime_id: "test",
        screen_id: "test",
        source_kind: :native,
        platform_target: :test,
        root: %{},
        screen: test_screen("test-screen"),
        windows: %{},
        navigation_state: nav_state
      }

      assert Integration.can_go_back?(runtime_state)
    end

    test "returns false when history is empty" do
      nav_state = %DesktopUi.Navigation.State{history: []}

      runtime_state = %RuntimeState{
        runtime_id: "test",
        screen_id: "test",
        source_kind: :native,
        platform_target: :test,
        root: %{},
        screen: test_screen("test-screen"),
        windows: %{},
        navigation_state: nav_state
      }

      refute Integration.can_go_back?(runtime_state)
    end
  end

  describe "can_go_forward?/1" do
    test "returns true when forward has items" do
      nav_state = %DesktopUi.Navigation.State{forward: [{:detail, DetailScreen, %{}}]}

      runtime_state = %RuntimeState{
        runtime_id: "test",
        screen_id: "test",
        source_kind: :native,
        platform_target: :test,
        root: %{},
        screen: test_screen("test-screen"),
        windows: %{},
        navigation_state: nav_state
      }

      assert Integration.can_go_forward?(runtime_state)
    end

    test "returns false when forward is empty" do
      nav_state = %DesktopUi.Navigation.State{forward: []}

      runtime_state = %RuntimeState{
        runtime_id: "test",
        screen_id: "test",
        source_kind: :native,
        platform_target: :test,
        root: %{},
        screen: test_screen("test-screen"),
        windows: %{},
        navigation_state: nav_state
      }

      refute Integration.can_go_forward?(runtime_state)
    end
  end

  describe "shutdown/1" do
    test "stops the navigation controller" do
      defmodule ShutdownTestScreen do
      end

      {:ok, controller} =
        Controller.start_link(
          name: nil,
          initial_screen: {:home, ShutdownTestScreen, %{}}
        )

      runtime_state = %RuntimeState{
        runtime_id: "test",
        screen_id: "test",
        source_kind: :native,
        platform_target: :test,
        root: %{},
        screen: test_screen("test-screen"),
        windows: %{},
        navigation_controller: controller
      }

      assert :ok = Integration.shutdown(runtime_state)
      refute Process.alive?(controller)
    end

    test "returns :ok when no navigation controller" do
      runtime_state = %RuntimeState{
        runtime_id: "test",
        screen_id: "test",
        source_kind: :native,
        platform_target: :test,
        root: %{},
        screen: test_screen("test-screen"),
        windows: %{},
        navigation_controller: nil
      }

      assert :ok = Integration.shutdown(runtime_state)
    end
  end
end
