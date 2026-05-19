defmodule AshUI.Rendering.WorkflowProgressStatusRendererTest do
  use ExUnit.Case, async: true

  alias AshUI.Rendering.{DesktopUIAdapter, ElmUIAdapter}
  alias UnifiedIUR.Widgets.Components

  @moduletag :conformance

  test "Elm UI fallback preserves workflow progress status card diagnostics" do
    assert {:ok, html} = ElmUIAdapter.render(canonical_card(), force_fallback: true)

    assert html =~ ~s(data-ash-ui-renderer-diagnostic="unsupported_component_fallback")
    assert html =~ ~s(data-renderer="elm_ui")
    assert html =~ ~s(data-component-id="workflow-subject-card")
    assert html =~ ~s(data-component-kind="workflow_progress_status_card")
    assert html =~ ~s(data-component-family="workflow_progress_and_status")
  end

  test "Desktop UI fallback preserves workflow progress status card diagnostics" do
    assert {:ok, card} = DesktopUIAdapter.render(canonical_card(), force_fallback: true)

    assert card["widget_type"] == "workflow_progress_status_card"

    assert card["diagnostic"] == %{
             "code" => "unsupported_component_fallback",
             "renderer" => "desktop_ui",
             "element_id" => "workflow-subject-card",
             "component_kind" => :workflow_progress_status_card,
             "component_family" => :workflow_progress_and_status,
             "message" => "Desktop fallback preserved canonical component identity."
           }
  end

  defp canonical_card do
    Components.workflow_progress_status_card(
      id: "workflow-subject-card",
      subject_id: "subject:ash_ui",
      name: "ash_ui",
      path: "workspaces/ash_ui",
      progress_pct: 0.72,
      active_count: 4,
      blocked_count: 1,
      depends_on: ["unified_iur"],
      depended_by: ["live_ui"]
    )
  end
end
