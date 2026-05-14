defmodule ElmUi.TransportTest do
  use ExUnit.Case, async: true

  alias Jido.Signal
  alias ElmUi.FrontendRuntime.Model

  test "transport keeps direct native events local when the boundary is not crossed" do
    assert {:ok, translation} =
             ElmUi.Transport.from_native_event(
               family: :click,
               intent: :open,
               widget_id: :dialog_trigger,
               source_kind: :native
             )

    assert translation.boundary == :local
    assert translation.family == :click
    assert translation.server_action.kind == :local_runtime_event
    assert translation.frontend_update.mode == :bounded_local_feedback

    assert {:ok, %{native_event: %{widget_id: :dialog_trigger}}} =
             ElmUi.Transport.to_server_message(translation)
  end

  test "transport emits canonical boundary events as jido signals" do
    assert {:ok, translation} =
             ElmUi.Transport.from_native_event(
               family: :submit,
               intent: :save,
               widget_id: :save_button,
               screen: "settings",
               payload: %{valid: true},
               boundary: :boundary
             )

    assert translation.boundary == :boundary
    assert %Signal{} = translation.signal
    assert is_binary(translation.cloud_event.specversion)
    assert String.starts_with?(translation.cloud_event.specversion, "1.0")
    assert translation.server_action.kind == :canonical_boundary_event

    assert {:ok, message} = ElmUi.Transport.to_server_message(translation.signal)
    assert message.type == "elm_ui.submit.save"
    assert message.family == :submit
    refute Map.has_key?(message, :native_event)
  end

  test "signal helpers expose the full planned family surface and convergence defaults" do
    assert ElmUi.Signals.families() == [
             :click,
             :change,
             :submit,
             :open,
             :close,
             :navigation,
             :selection,
             :command
           ]

    assert ElmUi.Signals.local_default_families() == [:click, :change, :open, :close]

    assert ElmUi.Signals.boundary_crossing_families() == [
             :submit,
             :navigation,
             :selection,
             :command
           ]

    assert {:ok, native_translation} =
             ElmUi.Signals.from_native_event(
               family: :open,
               intent: :inspect,
               widget_id: :inspect_dialog,
               source_kind: :native
             )

    assert native_translation.boundary == :local
    assert native_translation.runtime_event == "open:inspect"

    assert {:ok, canonical_translation} =
             ElmUi.Signals.from_native_event(
               family: :command,
               intent: :run,
               widget_id: :ops_command_palette,
               source_kind: :canonical,
               runtime_id: "canonical-runtime",
               screen: "advanced-operations"
             )

    assert canonical_translation.boundary == :boundary
    assert canonical_translation.signal.type == "elm_ui.command.run"

    assert {:ok, boundary_translation} =
             ElmUi.Signals.from_boundary_signal(canonical_translation.signal)

    assert boundary_translation.server_action.kind == :canonical_boundary_event
    assert boundary_translation.frontend_update.mode == :server_sync
    assert boundary_translation.runtime_event == "command:run"
  end

  test "frontend bridge builds outgoing envelopes through the shared transport" do
    model = %Model{
      runtime_id: "bridge-runtime",
      title: "Bridge Screen",
      source_kind: :native,
      boundary_mode: :canonical_boundary,
      tree: %{},
      local_state: %{focused_id: nil, flash: nil},
      diagnostics: [],
      metadata: %{}
    }

    assert {:ok, envelope} =
             ElmUi.FrontendRuntime.Bridge.outgoing_interaction(model,
               family: :navigation,
               intent: :open_settings,
               boundary: :boundary,
               widget_id: :settings_link
             )

    assert envelope.kind == :event
    assert envelope.metadata.runtime_id == "bridge-runtime"
    assert envelope.payload.family == :navigation
    assert envelope.payload.runtime_event == "navigation:open_settings"
  end

  test "transport bridge round-trips canonical boundary envelopes for phoenix transport" do
    assert {:ok, translation} =
             ElmUi.Transport.from_native_event(
               family: :submit,
               intent: :save,
               widget_id: :save_button,
               screen: "settings",
               runtime_id: "settings-runtime",
               payload: %{valid: true},
               boundary: :boundary
             )

    assert {:ok, envelope} =
             ElmUi.Transport.Bridge.boundary_envelope(translation,
               transport: :phoenix_socket,
               topic: "elm_ui:settings",
               event: "settings:submit"
             )

    assert envelope.kind == :canonical_boundary
    assert envelope.transport == :phoenix_socket
    assert envelope.topic == "elm_ui:settings"
    assert envelope.event == "settings:submit"

    assert {:ok, signal} = ElmUi.Transport.Bridge.inbound_boundary_envelope(envelope)
    assert signal.type == "elm_ui.submit.save"
  end
end
