defmodule ElmUi.PhaseOneIntegrationTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element
  alias ElmUi.FrontendRuntime.{Boot, Message}
  alias ElmUi.ServerRuntime

  test "package and split runtime entrypoints stay available without owning application startup" do
    assert ElmUi.server() == ElmUi.Server
    assert ElmUi.frontend() == ElmUi.Frontend
    assert ElmUi.runtime() == ElmUi.Runtime
    assert ElmUi.renderer() == ElmUi.Renderer
    assert ElmUi.transport() == ElmUi.Transport
  end

  test "minimal native screen mounts, hydrates, and renders through the backbone" do
    assert {:ok, runtime_state} =
             ElmUi.Runtime.mount_native_screen(ElmUi.Examples.native_counter_screen())

    envelope = ServerRuntime.frontend_envelope(runtime_state)
    assert {:ok, frontend_model} = Boot.hydrate_message(envelope)

    assert runtime_state.rendered_tree.kind == :stack
    assert frontend_model.tree.kind == :stack
    assert frontend_model.boundary_mode == :native_local
  end

  test "canonical screens reuse the same runtime and frontend flow" do
    element =
      Element.new(:widget, :button,
        id: :phase_one_button,
        attributes: %{label: "Continue"}
      )

    assert {:ok, runtime_state} = ElmUi.Runtime.mount_iur_screen(element, runtime_id: "phase-one")
    assert {:ok, frontend_model} = ElmUi.Runtime.hydrate_frontend(runtime_state)

    assert runtime_state.boundary_mode == :canonical_boundary
    assert frontend_model.tree.kind == :button
  end

  test "malformed widget declarations, hydration payloads, and wiring fail with deterministic diagnostics" do
    assert {:error, %ServerRuntime.Error{reason: :invalid_screen}} =
             ElmUi.Runtime.mount_native_screen(%{id: :broken, title: "Broken"})

    assert {:error, %ElmUi.FrontendRuntime.Error{reason: :invalid_hydration_payload}} =
             Boot.hydrate(%{runtime_id: "missing"})

    assert {:error, %ServerRuntime.Error{reason: :unsupported_frontend_message}} =
             ServerRuntime.receive_frontend_message(
               %ElmUi.ServerRuntime.State{
                 runtime_id: "phase-one",
                 rendered_tree: ElmUi.Widgets.text(:id, "ok")
               },
               Message.new(:hydrate, %{runtime_id: "phase-one"})
             )
  end

  test "reference helpers and inspection surfaces expose phase one boundaries without renderer coupling" do
    reference = ElmUi.reference()
    info = ElmUi.info()

    widget =
      ElmUi.Widgets.button(:save, "Save",
        on_click: %{family: :click, intent: :save, boundary: :local}
      )

    assert :hydration_envelope in reference.runtime.bridge_boundaries

    assert reference.widgets.contract.metadata == [
             :label,
             :description,
             :role,
             :variant,
             :native_surface
           ]

    assert info.bridge.boundaries == [:hydration_envelope, :event_envelope, :acknowledgement]
    assert ElmUi.Info.widget_summary(widget).event_keys == [:click]
  end
end
