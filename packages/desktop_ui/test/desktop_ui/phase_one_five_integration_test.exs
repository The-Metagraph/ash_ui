defmodule DesktopUi.PhaseOneFiveIntegrationTest do
  use ExUnit.Case, async: true

  test "SDL3 lifecycle adapters, runtime handoff objects, window sessions, and render plans connect coherently" do
    assert {:ok, native_boot} =
             DesktopUi.Sdl3.App.boot_native_screen(
               DesktopUi.Examples.native_foundational_screen(),
               platform_target: :linux
             )

    assert {:ok, canonical_boot} =
             DesktopUi.Sdl3.App.boot_iur_screen(
               DesktopUi.Examples.canonical_foundational_screen(),
               platform_target: :linux
             )

    assert native_boot.foundation == :sdl3
    assert native_boot.lifecycle.state == :ready
    assert native_boot.windows.validation_state == :native_window_registry_ready
    assert native_boot.frame_request.validation_state == :render_plan_ready

    assert native_boot.frame_request.presentation.render_plan.presentation.backend ==
             :sdl_renderer

    assert native_boot.frame_request.presentation.render_plan.diagnostics.draw_operation_count > 0

    assert canonical_boot.foundation == :sdl3
    assert canonical_boot.runtime.source_kind == :canonical
    assert canonical_boot.runtime.direct_native_and_canonical_share_runtime

    assert canonical_boot.frame_request.presentation.render_plan.presentation.validation_state ==
             :render_plan_ready
  end

  test "minimal native screens can produce native-window state and widget-complete draw plans" do
    assert {:ok, state} =
             DesktopUi.Runtime.mount_native_screen(
               DesktopUi.Examples.native_foundational_screen(),
               platform_target: :linux
             )

    assert {:ok, registry} = DesktopUi.Sdl3.Window.registry(state)
    assert {:ok, plan} = DesktopUi.Sdl3.RenderPlan.build(state)
    assert {:ok, presentation} = DesktopUi.Sdl3.Renderer.present(plan)

    assert registry.primary_id == "window:workspace-foundation"
    assert registry.continuity == :single_window
    assert hd(plan.windows).logical_bounds.units == :logical
    assert Enum.any?(hd(plan.windows).draw_operations, &(&1.draw_kind == :window_chrome))
    refute plan.presentation.placeholder_draw_operations
    assert plan.presentation.widget_complete_draw_operations
    assert presentation.backend == :sdl_renderer
    assert presentation.widget_complete_draw_operations?
    assert presentation.validation_state == :presented_frame_ready
  end

  test "invalid callback ordering, malformed event payloads, and broken window ownership fail with deterministic adapter diagnostics" do
    lifecycle =
      DesktopUi.Sdl3.Lifecycle.scaffold()
      |> DesktopUi.Sdl3.Lifecycle.begin_boot(%{
        runtime_id: "desktop-ui:broken",
        screen_id: "broken"
      })
      |> DesktopUi.Sdl3.Lifecycle.fail(:callback_order_violation, %{callback: :app_quit})

    assert lifecycle.last_error.reason == :callback_order_violation

    assert {:error, %DesktopUi.Runtime.Error{reason: :unsupported_sdl3_event_type}} =
             DesktopUi.Sdl3.Events.normalize(%{type: :unknown_event})

    assert {:ok, broken_state} =
             DesktopUi.Runtime.mount_native_screen(%{
               id: "broken-overlay",
               title: "Broken Overlay",
               root:
                 DesktopUi.Layer.multi_window(
                   "broken-multi-window",
                   [
                     DesktopUi.Widgets.dialog("orphaned-dialog", "Detached", [
                       DesktopUi.Widgets.text("overlay-copy", "No owning window")
                     ])
                   ]
                 )
             })

    assert {:error, %DesktopUi.Runtime.Error{reason: :orphaned_transient_layer}} =
             DesktopUi.Sdl3.Window.registry(broken_state)
  end

  test "reference and inspection helpers expose SDL3 namespaces, lifecycle boundaries, and widget-complete validation state" do
    reference = DesktopUi.reference()
    inspection = DesktopUi.Inspection.sdl3_adapter_surface()

    assert DesktopUi.Sdl3 in reference.sdl3.modules
    assert DesktopUi.Sdl3.RenderPlan in reference.sdl3.modules
    assert DesktopUi.Sdl3.FrameEncoder in reference.sdl3.modules
    assert :window_registry in reference.sdl3.scope
    assert reference.inspection.sdl3_adapter_surface.lifecycle.foundation == :sdl3
    assert inspection.renderer.first_backend == :sdl_renderer
    assert inspection.renderer.future_backend == :sdl_gpu
    assert inspection.interaction_script.format == :tab_separated_key_values
    assert inspection.renderer_completeness == :widget_complete_interactive
    assert inspection.validation_state.adapter == :app_handoff_ready
    assert inspection.validation_state.frame_encoder == :frame_encoding_ready
    assert inspection.validation_state.interaction_script == :interaction_script_ready
  end

  test "validation and helper output distinguish widget-complete SDL3 execution from bounded fallback review" do
    report = DesktopUi.Validate.validation_report()
    summary = DesktopUi.Validate.validation_summary(report)

    assert report.sdl3_adapter_surface.status == :pass
    assert report.release_readiness.status == :pass
    assert DesktopUi.Info.sdl3_summary().renderer_completeness == :widget_complete_interactive
    refute DesktopUi.Reference.sdl3_summary().renderer.placeholder_draw_operations_allowed
    assert summary =~ "SDL3 adapter surface passing?: true"
    assert summary =~ "widget-complete native rendering?: true"
    assert summary =~ "release ready?: true"
  end
end
