defmodule ElmUi.RuntimeNavigationTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element
  alias ElmUi.FrontendRuntime
  alias ElmUi.Widgets

  defp home_screen do
    Widgets.screen("home", "Home", [
      Widgets.button("settings-link", "Settings")
    ])
  end

  defp settings_screen do
    Widgets.screen("settings", "Settings", [
      Widgets.text("settings-title", "Settings")
    ])
  end

  test "authoritative server navigation updates frontend screen selection through acknowledgements" do
    assert {:ok, runtime_state} =
             ElmUi.Runtime.mount_native_screen(home_screen(),
               runtime_id: "nav-runtime",
               screen_registry: %{settings: settings_screen()},
               host_route_resolver: fn descriptor, _state ->
                 if descriptor.screen == "settings", do: %{path: "/settings"}, else: nil
               end
             )

    assert {:ok, frontend_model} = ElmUi.Runtime.hydrate_frontend(runtime_state)
    assert frontend_model.screen_id == "home"

    assert {:ok, frontend_after_dispatch, event_message} =
             FrontendRuntime.dispatch_interaction(frontend_model,
               family: :navigation,
               intent: :open_settings_screen,
               boundary: :boundary,
               widget_id: "settings-link",
               target: %{
                 navigation: %{
                   action: :navigate_to,
                   screen: :settings,
                   params: %{tab: :profile}
                 }
               }
             )

    assert frontend_after_dispatch.local_state.pending_boundary_event.runtime_event ==
             "navigation:open_settings_screen"

    assert {:ok, next_state, ack_message} =
             ElmUi.Runtime.handle_frontend_event(runtime_state, event_message)

    assert next_state.screen_id == "settings"
    assert next_state.boundary_mode == :native_local
    assert ack_message.payload.authoritative_screen.screen_id == "settings"

    assert ack_message.payload.authoritative_screen.metadata.navigation.current_screen_id ==
             "settings"

    assert ack_message.payload.authoritative_screen.metadata.navigation.host_route == %{
             path: "/settings"
           }

    assert {:ok, frontend_after_ack} =
             ElmUi.FrontendRuntime.apply_server_message(frontend_after_dispatch, ack_message)

    assert frontend_after_ack.screen_id == "settings"
    assert frontend_after_ack.title == "Settings"

    assert frontend_after_ack.local_state.last_server_ack.authoritative_screen.screen_id ==
             "settings"
  end

  test "canonical boundary navigation reports divergence when frontend route state disagrees" do
    element =
      Element.new(:widget, :text, id: "workspace-home", attributes: %{content: "Workspace"})

    assert {:ok, runtime_state} =
             ElmUi.Runtime.mount_iur_screen(element,
               runtime_id: "canonical-nav",
               screen_registry: %{settings: settings_screen()}
             )

    assert {:ok, translation} =
             ElmUi.Transport.from_native_event(
               family: :navigation,
               intent: :open_settings_screen,
               widget_id: "settings-link",
               screen: runtime_state.screen_id,
               runtime_id: runtime_state.runtime_id,
               source_kind: :canonical,
               boundary_mode: :canonical_boundary,
               target: %{
                 navigation: %{
                   action: :navigate_to,
                   screen: :settings,
                   params: %{tab: :profile}
                 }
               },
               metadata: %{route_state: %{screen_id: "wrong-screen"}}
             )

    assert {:ok, envelope} =
             ElmUi.Transport.Bridge.boundary_envelope(translation, topic: "elm_ui:navigation")

    assert {:ok, next_state, ack_message} =
             ElmUi.Runtime.handle_boundary_envelope(runtime_state, envelope)

    assert next_state.screen_id == "settings"

    assert Enum.any?(next_state.diagnostics, fn diagnostic ->
             diagnostic.reason == :frontend_route_state_divergence and
               diagnostic.authoritative_screen == "settings"
           end)

    assert Enum.any?(ack_message.payload.diagnostics, fn diagnostic ->
             diagnostic.reason == :frontend_route_state_divergence and
               diagnostic.authoritative_screen == "settings"
           end)
  end
end
