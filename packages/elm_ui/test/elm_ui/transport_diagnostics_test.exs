defmodule ElmUi.TransportDiagnosticsTest do
  use ExUnit.Case, async: true

  alias Jido.Signal
  alias ElmUi.ServerRuntime
  alias ElmUi.Transport.Error

  test "rejects renderer-local event names at the canonical boundary" do
    assert {:error, %Error{reason: :renderer_local_event_name}} =
             ElmUi.Signals.from_native_event(
               family: :submit,
               intent: :save,
               boundary: :boundary,
               screen: "settings",
               runtime_id: "settings-runtime",
               widget_id: :save_button,
               runtime_event: "phx-submit",
               payload: %{valid: true}
             )
  end

  test "rejects renderer-local payload keys at the canonical boundary" do
    assert {:error, %Error{reason: :renderer_local_payload}} =
             ElmUi.Signals.from_native_event(
               family: :submit,
               intent: :save,
               boundary: :boundary,
               screen: "settings",
               runtime_id: "settings-runtime",
               widget_id: :save_button,
               payload: %{phx_value_name: "Pascal"}
             )
  end

  test "rejects leaked host-route syntax on canonical navigation targets" do
    assert {:error, %Error{reason: :host_route_syntax}} =
             ElmUi.Signals.from_native_event(
               family: :navigation,
               intent: :open_settings_screen,
               boundary: :boundary,
               screen: "settings",
               runtime_id: "settings-runtime",
               widget_id: :settings_link,
               target: %{
                 navigation: %{action: :navigate_to, screen: :settings, route: "/settings"}
               }
             )
  end

  test "rejects URL-like targets, host-router names, and runtime module references" do
    for {key, value} <- [
          url: "https://example.invalid/settings",
          router: :workspace_router,
          runtime_module: ElmUi.Runtime
        ] do
      assert {:error, %Error{reason: :host_route_syntax, details: %{keys: [^key]}}} =
               ElmUi.Signals.from_native_event(
                 family: :navigation,
                 intent: :open_settings_screen,
                 boundary: :boundary,
                 screen: "settings",
                 runtime_id: "settings-runtime",
                 widget_id: :settings_link,
                 target: %{
                   navigation:
                     Map.merge(%{action: :navigate_to, screen: :settings}, %{key => value})
                 }
               )
    end
  end

  test "rejects missing canonical context and invalid families" do
    assert {:error, %Error{reason: :missing_boundary_context}} =
             ElmUi.Signals.from_native_event(
               family: :submit,
               intent: :save,
               boundary: :boundary,
               widget_id: :save_button
             )

    assert {:error, %Error{reason: :invalid_family}} =
             ElmUi.Signals.from_native_event(
               family: :hover,
               intent: :inspect,
               widget_id: :mystery_widget
             )
  end

  test "rejects malformed boundary signals and envelopes" do
    {:ok, signal} =
      Signal.new(
        "elm_ui.change.rename_profile",
        %{name: "Ari"},
        source: "/elm_ui/canonical/profile",
        extensions: %{
          elm_ui_runtime_event: "change:rename_profile"
        }
      )

    assert {:error, %Error{reason: :invalid_family}} =
             ElmUi.Transport.from_boundary_signal(signal)

    assert {:error, %Error{reason: :invalid_boundary_envelope}} =
             ElmUi.Transport.Bridge.inbound_boundary_envelope(%{kind: :oops})

    signal_map =
      signal
      |> Map.from_struct()
      |> Map.delete(:__meta__)

    assert {:error, %Error{reason: :package_local_transport_detail}} =
             ElmUi.Transport.Bridge.inbound_boundary_envelope(%{
               kind: :canonical_boundary,
               signal: signal_map,
               native_event: %{widget_id: :name_input}
             })
  end

  test "runtime distinguishes local event validation failures from boundary envelope failures" do
    assert {:ok, state} =
             ElmUi.Runtime.mount_native_screen(
               ElmUi.Examples.native_counter_screen(),
               runtime_id: "native-runtime"
             )

    local_message =
      ElmUi.FrontendRuntime.Message.new(
        :event,
        %{
          family: :click,
          intent: :increment,
          boundary: :local,
          widget_id: :increment,
          runtime_event: "phx-click"
        }
      )

    assert {:error, %ServerRuntime.Error{reason: :invalid_local_event}} =
             ServerRuntime.handle_frontend_event(state, local_message)

    assert {:error, %ServerRuntime.Error{reason: :invalid_boundary_envelope}} =
             ServerRuntime.handle_boundary_envelope(state, %{kind: :canonical_boundary})
  end
end
