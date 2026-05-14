defmodule DesktopUi.Sdl3ToolingDiagnosticsTest do
  use ExUnit.Case, async: true

  test "inspection and summary surfaces report widget-complete interactive SDL3 execution" do
    inspection = DesktopUi.Inspection.sdl3_adapter_surface()
    info = DesktopUi.Info.sdl3_summary()
    reference = DesktopUi.Reference.sdl3_summary()

    assert inspection.interaction_script.format == :tab_separated_key_values
    assert inspection.renderer_completeness == :widget_complete_interactive
    assert inspection.visible_runner.widget_complete_rendering
    assert inspection.visible_runner.interactive_execution
    refute inspection.visible_runner.placeholder_drawing
    assert length(inspection.manual_review_workflow.compiled_visible_review) > 0

    assert info.renderer_completeness == :widget_complete_interactive
    assert length(info.manual_review_workflow.expectations) > 0

    assert reference.renderer.widget_complete_draw_operations
    assert reference.visible_runner.interaction_summary_reported
    refute reference.renderer.placeholder_draw_operations_allowed
  end
end
