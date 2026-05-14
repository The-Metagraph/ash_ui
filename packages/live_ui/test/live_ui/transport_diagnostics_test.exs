defmodule LiveUi.TransportDiagnosticsTest do
  use ExUnit.Case, async: true

  alias Jido.Signal
  alias LiveUi.Transport.Error
  alias UnifiedIUR.Interaction

  test "rejects renderer-local event names at the canonical boundary" do
    assert {:error, %Error{reason: :renderer_local_event_name}} =
             LiveUi.Signals.from_native(
               family: :change,
               intent: :rename_profile,
               screen: :profile,
               element_id: :name_input,
               boundary: :boundary,
               runtime_event: "phx-change",
               payload: %{name: "Pascal"}
             )
  end

  test "rejects renderer-local payload keys at the canonical boundary" do
    assert {:error, %Error{reason: :renderer_local_payload}} =
             LiveUi.Signals.from_native(
               family: :submit,
               intent: :save_profile,
               screen: :profile,
               element_id: :profile_form,
               boundary: :boundary,
               payload: %{phx_value_name: "Pascal"}
             )
  end

  test "rejects leaked host-route syntax on canonical navigation targets" do
    assert {:error, %Error{reason: :host_route_syntax}} =
             LiveUi.Signals.from_native(
               family: :navigation,
               intent: :open_settings_screen,
               screen: :profile,
               element_id: :settings_link,
               boundary: :boundary,
               target: %{
                 navigation: %{action: :navigate_to, screen: :settings, route: "/settings"}
               }
             )
  end

  test "rejects URL-like targets, host-router names, and runtime module references" do
    for {key, value} <- [
          url: "https://example.invalid/settings",
          router: :workspace_router,
          runtime_module: LiveUi.Runtime
        ] do
      assert {:error, %Error{reason: :host_route_syntax, details: %{keys: [^key]}}} =
               LiveUi.Signals.from_native(
                 family: :navigation,
                 intent: :open_settings_screen,
                 screen: :profile,
                 element_id: :settings_link,
                 boundary: :boundary,
                 target: %{
                   navigation:
                     Map.merge(%{action: :navigate_to, screen: :settings}, %{key => value})
                 }
               )
    end
  end

  test "rejects missing canonical context and invalid families" do
    interaction = Interaction.submit(intent: :save_profile, element_id: :profile_form)

    assert {:error, %Error{reason: :missing_boundary_context}} =
             LiveUi.Signals.from_interaction(interaction, boundary: :boundary)

    assert {:error, %Error{reason: :invalid_family}} =
             LiveUi.Signals.from_native(
               family: :hover,
               screen: :profile,
               element_id: :name_input,
               boundary: :boundary
             )
  end

  test "rejects malformed boundary signals and channel envelopes" do
    {:ok, signal} =
      Signal.new(
        "live_ui.change.rename_profile",
        %{name: "Ari"},
        source: "/live_ui/canonical/screen/profile",
        extensions: %{
          live_ui_runtime_event: "rename"
        }
      )

    assert {:error, %Error{reason: :invalid_boundary_signal}} =
             LiveUi.Transport.decode_boundary_signal(signal)

    assert {:error, %Error{reason: :invalid_channel_envelope}} =
             LiveUi.Transport.Channel.inbound(%{kind: :oops})
  end

  test "rejects unsupported hooks and leaked hook payload keys" do
    assert {:error, %Error{reason: :unsupported_hook}} =
             LiveUi.Runtime.BrowserBridge.normalize_payload(:mystery_hook, %{})

    assert {:error, %Error{reason: :renderer_local_payload}} =
             LiveUi.Runtime.BrowserBridge.normalize_payload(:resize_observer, %{
               "renderer_width" => 42
             })
  end
end
