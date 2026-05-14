defmodule DesktopUi.Sdl3RenderPlanTest do
  use ExUnit.Case, async: true

  alias DesktopUi.Sdl3.{App, FrameEncoder, RenderPlan, Renderer, Window}

  test "native window sessions distinguish top-level windows from transient layers" do
    assert {:ok, state} =
             DesktopUi.Runtime.mount_native_screen(advanced_screen(), platform_target: :linux)

    assert {:ok, registry} = Window.registry(state)

    assert registry.primary_id == "window:operations-window"
    assert registry.continuity == :multi_window
    assert registry.validation_state == :native_window_registry_ready

    assert Enum.map(registry.sessions, & &1.id) == [
             "window:details-window",
             "window:operations-window"
           ]

    operations_window = Enum.find(registry.sessions, &(&1.id == "window:operations-window"))
    details_window = Enum.find(registry.sessions, &(&1.id == "window:details-window"))

    assert operations_window.native_window?
    assert "operations-window" in operations_window.owned_widget_ids
    assert "ops-dialog" in operations_window.owned_layer_ids
    assert Enum.any?(operations_window.transient_layers, &(&1.role == :overlay))
    assert details_window.owned_layer_ids == []

    assert :ok =
             Window.validate_transition(
               registry,
               "window:operations-window",
               "window:details-window"
             )
  end

  test "render plans preserve logical bounds, clipping, and widget-complete draw operations" do
    assert {:ok, state} =
             DesktopUi.Runtime.mount_native_screen(advanced_screen(), platform_target: :linux)

    assert {:ok, plan} = RenderPlan.build(state)
    assert {:ok, frame_payload} = FrameEncoder.encode(plan)

    assert plan.runtime_id == "desktop-ui:operations"
    assert plan.screen_id == "operations"
    assert plan.presentation.backend == :sdl_renderer
    assert plan.presentation.logical_units
    refute plan.presentation.placeholder_draw_operations
    assert plan.presentation.widget_complete_draw_operations
    assert plan.presentation.validation_state == :render_plan_ready
    assert plan.diagnostics.window_count == 2
    assert plan.diagnostics.draw_operation_count > 0
    assert plan.diagnostics.draw_kind_counts.window_chrome >= 1

    operations_window = Enum.find(plan.windows, &(&1.window_id == "window:operations-window"))

    assert operations_window.logical_bounds.units == :logical
    assert Enum.any?(operations_window.clip_regions, &(&1.kind == :viewport))
    assert Enum.any?(operations_window.transient_layers, &(&1.widget_id == "ops-dialog"))
    assert Enum.any?(operations_window.draw_operations, &(&1.widget_id == "operations-window"))
    assert Enum.any?(operations_window.draw_operations, &(&1.draw_kind == :overlay_surface))
    assert Enum.any?(operations_window.draw_operations, &(&1.draw_kind == :split_pane_surface))
    assert Enum.any?(operations_window.draw_operations, &(&1.draw_kind == :table_surface))
    assert Enum.any?(operations_window.draw_operations, &(&1.clip_bounds != nil))

    assert FrameEncoder.contract().payload_family == :frame
    assert frame_payload.validation_state == :frame_payload_ready
    assert frame_payload.presentation.logical_presentation.units == :logical
    assert frame_payload.presentation.widget_complete_draw_operations
    assert Enum.any?(frame_payload.windows, &(&1.window_id == "window:operations-window"))
  end

  test "SDL3 renderer presents render plans through an SDL_Renderer-first seam" do
    assert {:ok, state} =
             DesktopUi.Runtime.mount_native_screen(advanced_screen(), platform_target: :linux)

    assert {:ok, plan} = Renderer.prepare_frame(state)
    assert {:ok, presentation} = Renderer.present(plan)

    assert Renderer.contract().first_backend == :sdl_renderer
    assert Renderer.contract().future_backend == :sdl_gpu
    assert Renderer.contract().frame_encoder == :host_protocol_payload
    assert Renderer.contract().widget_complete_draw_operations
    assert Renderer.contract().interactive_visible_execution
    refute Renderer.contract().placeholder_draw_operations_allowed
    assert presentation.backend == :sdl_renderer
    assert presentation.presented_frame?
    assert presentation.widget_complete_draw_operations?
    assert presentation.window_count == 2

    assert Enum.any?(
             presentation.presented_windows,
             &(&1.window_id == "window:operations-window")
           )

    assert presentation.draw_kind_counts.window_chrome >= 1
    assert presentation.logical_presentation.units == :logical
    assert presentation.validation_state == :presented_frame_ready

    assert {:ok, boot_request} =
             App.boot_native_screen(advanced_screen(), platform_target: :linux)

    assert boot_request.windows.validation_state == :native_window_registry_ready
    assert boot_request.frame_request.validation_state == :render_plan_ready
    assert %RenderPlan{} = boot_request.frame_request.presentation.render_plan
  end

  defp advanced_screen do
    %{
      id: "operations",
      title: "Operations",
      root:
        DesktopUi.Layer.multi_window("operations-windows", [
          DesktopUi.Widgets.window("operations-window", "Operations", [
            DesktopUi.Layer.overlay(
              "operations-overlay",
              DesktopUi.Layout.split_pane(
                "operations-split",
                DesktopUi.Layout.viewport(
                  "services-viewport",
                  DesktopUi.Widgets.table(
                    "services-table",
                    [%{id: :service, label: "Service"}],
                    [%{id: :api, cells: ["API"]}],
                    selection_binding: :selected_service
                  )
                ),
                DesktopUi.Widgets.column("operations-sidebar", [
                  DesktopUi.Widgets.log_viewer(
                    "operations-log",
                    [%{id: "entry-1", message: "Booted"}],
                    query_binding: :log_query
                  ),
                  DesktopUi.Widgets.gauge("cpu-gauge", value: 72, label: "CPU")
                ]),
                ratio: 0.6
              ),
              [
                DesktopUi.Widgets.dialog("ops-dialog", "Runbook", [
                  DesktopUi.Widgets.text("dialog-copy", "Runbook loaded")
                ])
              ]
            )
          ]),
          DesktopUi.Widgets.window("details-window", "Details", [
            DesktopUi.Widgets.process_monitor(
              "process-monitor",
              [%{id: :beam, name: "beam.smp"}],
              selection_binding: :selected_process
            )
          ])
        ])
    }
  end
end
