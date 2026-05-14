defmodule ElmUi.PhaseFourIntegrationTest do
  use ExUnit.Case, async: true

  alias ElmUi.FrontendRuntime.Message
  alias ElmUi.ServerRuntime

  test "direct-native interactions remain local while preserving canonical family and intent meaning" do
    comparison = ElmUi.Examples.mixed_transport_comparison()

    assert comparison.native.boundary == :local
    assert comparison.native.mode == :local
    assert comparison.native.ack.family == :submit
    assert comparison.native.ack.intent == :save_workspace

    assert comparison.canonical.boundary == :boundary
    assert comparison.canonical.mode == :boundary
    assert comparison.canonical.ack.family == :submit
    assert comparison.canonical.ack.intent == :save_workspace

    assert comparison.continuity.same_family?
    assert comparison.continuity.same_intent?
    assert comparison.continuity.local_and_boundary_paths_diverge?
  end

  test "canonical boundary events round-trip through jido signal semantics and server acknowledgements" do
    assert {:ok, runtime_state} =
             ElmUi.Runtime.mount_iur_screen(
               ElmUi.Examples.canonical_transport_screen(),
               runtime_id: "canonical-transport"
             )

    assert {:ok, frontend_model} = ElmUi.Runtime.hydrate_frontend(runtime_state)

    assert {:ok, frontend_after_dispatch, event_message} =
             ElmUi.FrontendRuntime.dispatch_interaction(frontend_model,
               family: :submit,
               intent: :save_workspace,
               widget_id: "save-button",
               payload: %{mode: :commit}
             )

    assert event_message.metadata.boundary == :boundary
    assert event_message.payload.type == "elm_ui.submit.save_workspace"

    assert frontend_after_dispatch.local_state.pending_boundary_event.runtime_event ==
             "submit:save_workspace"

    assert {:ok, next_state, ack_message} =
             ElmUi.Runtime.handle_frontend_event(runtime_state, event_message)

    assert Enum.at(next_state.event_log, -1).mode == :boundary
    assert next_state.last_boundary_signal.type == "elm_ui.submit.save_workspace"
    assert ack_message.payload.family == :submit
    assert ack_message.payload.intent == :save_workspace
    assert ack_message.payload.boundary == :boundary
  end

  test "server-side runtime remains authoritative across translated events and frontend updates" do
    assert {:ok, runtime_state} =
             ElmUi.Runtime.mount_iur_screen(
               ElmUi.Examples.canonical_transport_screen(),
               runtime_id: "canonical-transport"
             )

    assert {:ok, frontend_model} = ElmUi.Runtime.hydrate_frontend(runtime_state)

    assert {:ok, frontend_after_dispatch, event_message} =
             ElmUi.FrontendRuntime.dispatch_interaction(frontend_model,
               family: :submit,
               intent: :save_workspace,
               widget_id: "save-button",
               payload: %{mode: :commit}
             )

    assert frontend_after_dispatch.local_state.flash.scope == :pending_server_sync

    assert {:ok, next_state, ack_message} =
             ElmUi.Runtime.handle_frontend_event(runtime_state, event_message)

    assert {:ok, frontend_after_ack} =
             ElmUi.FrontendRuntime.apply_server_message(frontend_after_dispatch, ack_message)

    refute Map.has_key?(frontend_after_ack.local_state, :pending_boundary_event)
    assert frontend_after_ack.local_state.last_server_ack.server_authority
    assert frontend_after_ack.local_state.flash.scope == :server_ack
    assert Enum.at(next_state.event_log, -1).mode == :boundary
  end

  test "bounded elm-side behavior contributes responsiveness without displacing server authority" do
    assert {:ok, runtime_state} =
             ElmUi.Runtime.mount_native_screen(
               ElmUi.Examples.native_transport_screen(),
               runtime_id: "native-transport"
             )

    assert {:ok, frontend_model} = ElmUi.Runtime.hydrate_frontend(runtime_state)

    assert {:ok, frontend_after_dispatch, event_message} =
             ElmUi.FrontendRuntime.dispatch_interaction(frontend_model,
               family: :submit,
               intent: :save_workspace,
               boundary: :local,
               widget_id: "save-button",
               payload: %{mode: :draft}
             )

    assert frontend_after_dispatch.local_state.flash.scope == :local_feedback
    refute Map.has_key?(frontend_after_dispatch.local_state, :pending_boundary_event)

    assert {:ok, next_state, ack_message} =
             ElmUi.Runtime.handle_frontend_event(runtime_state, event_message)

    assert Enum.at(next_state.event_log, -1).mode == :local
    assert ack_message.payload.server_authority
    assert ack_message.payload.boundary == :local
  end

  test "invalid boundary leakage fails with actionable diagnostics" do
    assert {:ok, runtime_state} =
             ElmUi.Runtime.mount_native_screen(
               ElmUi.Examples.native_transport_screen(),
               runtime_id: "native-transport"
             )

    leaked_message =
      Message.new(
        :event,
        %{
          family: :submit,
          intent: :save_workspace,
          boundary: :local,
          widget_id: "save-button",
          runtime_event: "phx-submit",
          payload: %{browser_width: 120}
        }
      )

    assert {:error, %ServerRuntime.Error{reason: :invalid_frontend_payload, details: details}} =
             ElmUi.Runtime.handle_frontend_event(runtime_state, leaked_message)

    assert details.reason == :renderer_local_payload

    assert {:error,
            %ServerRuntime.Error{
              reason: :invalid_boundary_envelope,
              details: boundary_details
            }} =
             ElmUi.Runtime.handle_boundary_envelope(runtime_state, %{
               kind: :canonical_boundary,
               native_event: %{widget_id: "save-button"}
             })

    assert boundary_details.reason == :package_local_transport_detail
  end
end
