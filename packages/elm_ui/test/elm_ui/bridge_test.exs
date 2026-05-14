defmodule ElmUi.BridgeTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element
  alias ElmUi.FrontendRuntime.{Boot, Message, Model}
  alias ElmUi.ServerRuntime

  test "server runtime exposes deterministic hydration envelopes" do
    assert {:ok, state} =
             ElmUi.Runtime.mount_native_screen(ElmUi.Examples.native_counter_screen())

    envelope = ServerRuntime.frontend_envelope(state)

    assert envelope.kind == :hydrate
    assert envelope.payload.runtime_id == state.runtime_id
    assert envelope.payload.boundary_mode == :native_local
  end

  test "server runtime rejects unsupported frontend messages with deterministic diagnostics" do
    assert {:ok, state} =
             ElmUi.Runtime.mount_native_screen(ElmUi.Examples.native_counter_screen())

    assert {:error, %ServerRuntime.Error{reason: :unsupported_frontend_message}} =
             ServerRuntime.receive_frontend_message(
               state,
               Message.new(:hydrate, %{runtime_id: state.runtime_id})
             )
  end

  test "frontend runtime rejects non-hydrate boot messages before hydration" do
    message = Message.new(:event, %{family: :click, runtime_event: "click:open"})

    assert {:error, %ElmUi.FrontendRuntime.Error{reason: :invalid_boot_order}} =
             Boot.hydrate_message(message)
  end

  test "server runtime rejects malformed boundary routing" do
    assert {:ok, state} =
             ElmUi.Runtime.mount_native_screen(ElmUi.Examples.native_counter_screen())

    assert {:error, %ServerRuntime.Error{reason: :missing_boundary_signal}} =
             ServerRuntime.handle_event(state, %{
               boundary: :boundary,
               family: :click,
               runtime_event: "click:submit",
               signal: nil
             })
  end

  test "server runtime rejects frontend payloads that leak renderer-local keys" do
    assert {:ok, state} =
             ElmUi.Runtime.mount_native_screen(ElmUi.Examples.native_counter_screen())

    leaked_message =
      Message.new(
        :event,
        %{
          family: :click,
          intent: :increment,
          boundary: :local,
          widget_id: :increment,
          payload: %{phx_value_step: 1}
        }
      )

    assert {:error, %ServerRuntime.Error{reason: :invalid_frontend_payload}} =
             ServerRuntime.handle_frontend_event(state, leaked_message)
  end

  test "frontend bridge decodes incoming envelopes through the shared message contract" do
    model = %Model{
      runtime_id: "incoming-runtime",
      title: "Incoming Screen",
      source_kind: :native,
      boundary_mode: :native_local,
      tree: %{},
      local_state: %{focused_id: nil, flash: nil},
      diagnostics: [],
      metadata: %{}
    }

    {:ok, event_message} =
      ElmUi.FrontendRuntime.Bridge.outgoing_interaction(model,
        family: :click,
        intent: :open,
        boundary: :local,
        widget_id: :open_button
      )

    assert {:ok, %{kind: :event, payload: %{family: :click}}} =
             ElmUi.FrontendRuntime.Bridge.incoming_message(event_message)
  end

  test "frontend bridge infers canonical boundary translation for canonical models" do
    model = %Model{
      runtime_id: "canonical-runtime",
      title: "Canonical Screen",
      source_kind: :canonical,
      boundary_mode: :canonical_boundary,
      tree: %{},
      local_state: %{focused_id: nil, flash: nil},
      diagnostics: [],
      metadata: %{}
    }

    {:ok, event_message} =
      ElmUi.FrontendRuntime.Bridge.outgoing_interaction(model,
        family: :command,
        intent: :run,
        widget_id: :ops_command_palette
      )

    assert event_message.metadata.boundary == :boundary
    assert event_message.payload.family == :command
    assert event_message.payload.type == "elm_ui.command.run"
  end

  test "frontend runtime dispatches interactions with bounded local responsiveness" do
    assert {:ok, runtime_state} =
             ElmUi.Runtime.mount_native_screen(
               ElmUi.Examples.native_counter_screen(),
               runtime_id: "native-runtime"
             )

    assert {:ok, model} = ElmUi.Runtime.hydrate_frontend(runtime_state)

    assert {:ok, updated_model, event_message} =
             ElmUi.FrontendRuntime.dispatch_interaction(model,
               family: :change,
               intent: :filter,
               widget_id: :search_input,
               payload: %{query: "ops"}
             )

    assert updated_model.local_state.focused_id == :search_input
    assert :search_input in updated_model.local_state.editing_ids
    assert updated_model.local_state.flash.scope == :local_feedback
    assert event_message.kind == :event
    assert event_message.payload.family == :change
  end

  test "frontend runtime applies server acknowledgements without becoming canonical authority" do
    assert {:ok, runtime_state} =
             ElmUi.Runtime.mount_native_screen(
               ElmUi.Examples.native_counter_screen(),
               runtime_id: "canonical-runtime"
             )

    assert {:ok, %Model{} = hydrated_model} = ElmUi.Runtime.hydrate_frontend(runtime_state)

    model = %Model{
      hydrated_model
      | source_kind: :canonical,
        boundary_mode: :canonical_boundary,
        local_state:
          Map.merge(hydrated_model.local_state, %{
            focused_id: :ops_command_palette,
            flash: %{scope: :pending_server_sync},
            pending_boundary_event: %{family: :command, intent: :run}
          })
    }

    ack_message =
      Message.new(
        :ack,
        %{
          runtime_id: "canonical-runtime",
          family: :command,
          intent: :run,
          runtime_event: "command:run",
          server_authority: true,
          diagnostics: [%{level: :info, message: "acknowledged"}]
        }
      )

    assert {:ok, updated_model} = ElmUi.FrontendRuntime.apply_server_message(model, ack_message)
    refute Map.has_key?(updated_model.local_state, :pending_boundary_event)
    assert updated_model.local_state.last_server_ack.runtime_id == "canonical-runtime"
    assert updated_model.local_state.flash.scope == :server_ack
    assert updated_model.diagnostics == [%{level: :info, message: "acknowledged"}]
  end

  test "frontend runtime accepts canonical hydration envelopes" do
    element = Element.new(:widget, :text, id: :canonical_message, attributes: %{content: "Hi"})
    assert {:ok, state} = ElmUi.Runtime.mount_iur_screen(element)

    envelope = ServerRuntime.frontend_envelope(state)

    assert {:ok, model} = Boot.hydrate_message(envelope)
    assert model.source_kind == :canonical
    assert model.tree.kind == :text
  end
end
