defmodule LiveUi.RuntimeNavigationTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element
  alias UnifiedIUR.Interactions.Transport, as: BoundaryTransport

  defmodule HomeScreen do
    use LiveUi.Screen, id: :home, title: "Home"

    @impl true
    def mount_defaults do
      %{shared: "preserved", welcome: "Home"}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div><%= @welcome %></div>
      """
    end
  end

  defmodule SettingsScreen do
    use LiveUi.Screen, id: :settings, title: "Settings"

    @impl true
    def mount_defaults do
      %{welcome: "Settings"}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div><%= @welcome %></div>
      """
    end
  end

  test "native runtime dispatch resolves canonical screen transitions on the server" do
    assert {:ok, runtime_state} =
             LiveUi.Runtime.mount(HomeScreen,
               screen_registry: %{settings: SettingsScreen},
               host_route_resolver: fn descriptor, _state ->
                 if descriptor.screen == :settings, do: %{path: "/settings"}, else: nil
               end
             )

    assert {:ok, updated_state, translation} =
             LiveUi.Runtime.dispatch_native_event(
               runtime_state,
               "navigation:open_settings_screen",
               %{},
               family: :navigation,
               intent: :open_settings_screen,
               target: %{
                 navigation: %{
                   action: :navigate_to,
                   screen: :settings,
                   params: %{tab: :profile}
                 }
               }
             )

    assert translation.family == :navigation
    assert updated_state.screen == SettingsScreen
    assert updated_state.mode == :native
    assert updated_state.assigns.shared == "preserved"
    assert updated_state.assigns.current_screen_id == :settings
    assert updated_state.assigns.navigation_params == %{tab: :profile}
    assert updated_state.assigns.navigation_host_route == %{path: "/settings"}
    assert Enum.map(updated_state.navigation.history, & &1.screen_id) == [:home]
  end

  test "canonical boundary fixtures share the same transition resolver, history, and modal state" do
    home_element =
      Element.new(:widget, :text, id: :workspace_home, attributes: %{content: "Workspace Home"})

    screen_transition = BoundaryTransport.boundary_fixture!("screen_transition--settings_profile")
    history_transition = BoundaryTransport.boundary_fixture!("history_transition--back")
    modal_transition = BoundaryTransport.boundary_fixture!("modal_transition--settings_dialog")

    assert {:ok, runtime_state} =
             LiveUi.Runtime.mount_iur(home_element,
               screen_registry: %{settings: SettingsScreen},
               screen_id: :workspace_home
             )

    assert {:ok, screen_translation} =
             LiveUi.Signals.from_interaction(
               screen_transition.interaction,
               screen: :workspace_home,
               mode: :screen,
               boundary: :boundary,
               payload: screen_transition.signal_data
             )

    assert {:ok, after_navigation, _runtime_action} =
             LiveUi.Runtime.handle_boundary_signal(runtime_state, screen_translation.signal)

    assert after_navigation.screen == SettingsScreen
    assert after_navigation.assigns.current_screen_id == :settings

    assert after_navigation.assigns.navigation_history == [
             %{screen_id: :workspace_home, title: "Workspace Home", mode: :canonical, params: %{}}
           ]

    assert {:ok, modal_translation} =
             LiveUi.Signals.from_interaction(
               modal_transition.interaction,
               screen: :settings,
               mode: :screen,
               boundary: :boundary,
               payload: modal_transition.signal_data
             )

    assert {:ok, with_modal, _runtime_action} =
             LiveUi.Runtime.handle_boundary_signal(after_navigation, modal_translation.signal)

    assert with_modal.assigns.current_modal == %{
             modal: modal_transition.summary.modal,
             params: modal_transition.descriptor.target.navigation.params,
             metadata: modal_transition.descriptor.target.navigation.metadata
           }

    assert {:ok, history_translation} =
             LiveUi.Signals.from_interaction(
               history_transition.interaction,
               screen: :settings,
               mode: :screen,
               boundary: :boundary,
               payload: history_transition.signal_data
             )

    assert {:ok, back_home, _runtime_action} =
             LiveUi.Runtime.handle_boundary_signal(with_modal, history_translation.signal)

    assert back_home.mode == :canonical
    assert back_home.screen == LiveUi.Runtime.CanonicalScreen
    assert back_home.assigns.current_screen_id == :workspace_home

    assert back_home.assigns.navigation_forward == [
             %{screen_id: :settings, title: "Settings", mode: :native, params: %{tab: :profile}}
           ]
  end

  test "canonical modal stack fixtures preserve stack behavior without mutating history" do
    home_element =
      Element.new(:widget, :text, id: :workspace_home, attributes: %{content: "Workspace Home"})

    first_modal = BoundaryTransport.boundary_fixture!("modal_transition--settings_dialog")
    second_modal = BoundaryTransport.boundary_fixture!("modal_stack--open_confirm_dialog")
    close_top = BoundaryTransport.boundary_fixture!("modal_stack--close_top")
    close_named = BoundaryTransport.boundary_fixture!("modal_stack--close_named_settings")

    assert {:ok, runtime_state} =
             LiveUi.Runtime.mount_iur(home_element, screen_id: :workspace_home)

    assert {:ok, with_first_modal, _runtime_action} =
             LiveUi.Runtime.handle_boundary_signal(
               runtime_state,
               boundary_signal(first_modal, :workspace_home)
             )

    assert {:ok, with_second_modal, _runtime_action} =
             LiveUi.Runtime.handle_boundary_signal(
               with_first_modal,
               boundary_signal(second_modal, :workspace_home)
             )

    assert with_second_modal.assigns.navigation_history == []

    assert with_second_modal.assigns.navigation_modal_stack == [
             %{
               modal: :settings_dialog,
               params: %{mode: :advanced},
               metadata: %{surface: :workspace}
             },
             %{
               modal: :settings_confirm_dialog,
               params: %{from: :settings_dialog},
               metadata: %{previous_modal: :settings_dialog}
             }
           ]

    assert with_second_modal.assigns.current_modal.modal == :settings_confirm_dialog
    assert with_second_modal.navigation.last_transition.modal_stack.stack_effect == :push_modal

    assert {:ok, after_named_close, _runtime_action} =
             LiveUi.Runtime.handle_boundary_signal(
               with_second_modal,
               boundary_signal(close_named, :workspace_home)
             )

    assert after_named_close.assigns.navigation_modal_stack == [
             %{
               modal: :settings_confirm_dialog,
               params: %{from: :settings_dialog},
               metadata: %{previous_modal: :settings_dialog}
             }
           ]

    assert after_named_close.assigns.current_modal.modal == :settings_confirm_dialog

    assert {:ok, after_top_close, _runtime_action} =
             LiveUi.Runtime.handle_boundary_signal(
               after_named_close,
               boundary_signal(close_top, :workspace_home)
             )

    assert after_top_close.assigns.navigation_modal_stack == []
    assert after_top_close.assigns.current_modal == nil
    assert after_top_close.assigns.navigation_history == []
  end

  test "navigation failures surface deterministic diagnostics" do
    assert {:ok, runtime_state} = LiveUi.Runtime.mount(HomeScreen)

    assert {:error, %LiveUi.Runtime.Error{reason: :unresolved_navigation_target}} =
             LiveUi.Runtime.dispatch_native_event(
               runtime_state,
               "navigation:open_missing",
               %{},
               family: :navigation,
               intent: :open_missing_screen,
               target: %{navigation: %{action: :navigate_to, screen: :missing}}
             )

    assert {:error, %LiveUi.Runtime.Error{reason: :host_route_navigation_syntax}} =
             LiveUi.Runtime.dispatch_native_event(
               runtime_state,
               "navigation:open_route",
               %{},
               family: :navigation,
               intent: :open_settings_screen,
               target: %{
                 navigation: %{action: :navigate_to, screen: :settings, route: "/settings"}
               }
             )
  end

  test "modal stack runtime-local identifiers are rejected" do
    assert {:ok, runtime_state} = LiveUi.Runtime.mount(HomeScreen)

    assert {:error, %LiveUi.Runtime.Error{reason: :host_route_navigation_syntax} = error} =
             LiveUi.Runtime.dispatch_native_event(
               runtime_state,
               "navigation:open_runtime_stack",
               %{},
               family: :navigation,
               intent: :open_settings_modal,
               target: %{
                 navigation: %{
                   action: :open_modal,
                   modal: :settings_dialog,
                   modal_stack: %{
                     operation: :push,
                     target: :symbolic_modal,
                     stack_effect: :push_modal,
                     stack_id: "runtime-stack"
                   }
                 }
               }
             )

    assert error.details.keys == [:stack_id]
  end

  defp boundary_signal(fixture, screen) do
    assert {:ok, translation} =
             LiveUi.Signals.from_interaction(
               fixture.interaction,
               screen: screen,
               mode: :screen,
               boundary: :boundary,
               payload: fixture.signal_data
             )

    translation.signal
  end
end
