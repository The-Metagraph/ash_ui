defmodule AshUI.Phase33PackageBoundaryTest do
  use ExUnit.Case, async: true

  @moduletag :conformance

  alias LiveUi.Widgets.WorkflowProgressStatusCard
  alias UnifiedIUR.Widgets.Components

  describe "Section 33.2 - canonical workflow progress and status boundary" do
    test "workflow_progress_status_card is cataloged as workflow_progress_and_status everywhere" do
      assert :workflow_progress_status_card in UnifiedUi.WidgetComponents.kinds()
      assert :workflow_progress_status_card in AshUI.WidgetComponents.kinds()
      assert :workflow_progress_status_card in Components.kinds()
      assert :workflow_progress_status_card in Components.workflow_kinds()

      assert :workflow_progress_status_card in UnifiedUi.WidgetComponents.component_families().workflow_progress_and_status

      assert :workflow_progress_status_card in AshUI.WidgetComponents.families().workflow_progress_and_status

      catalog_entry =
        Enum.find(
          UnifiedUi.WidgetComponents.catalog(),
          &(&1.kind == :workflow_progress_status_card)
        )

      assert catalog_entry.family == :workflow_progress_and_status

      card = Components.workflow_progress_status_card(name: "ash_ui")

      assert card.attributes.component.family == :workflow_progress_and_status
      assert card.attributes.component.kind == :workflow_progress_status_card
    end

    test "workflow_progress_status_card does not introduce workflow or workflow_summary families" do
      refute :workflow in LiveUi.Widgets.families()
      refute :workflow_summary in LiveUi.Widgets.families()
      refute function_exported?(Components, :workflow_summary_kinds, 0)
    end

    test "Live UI registers the native widget in the canonical family" do
      metadata = LiveUi.Component.metadata(WorkflowProgressStatusCard)

      assert :workflow_progress_and_status in LiveUi.Widgets.families()
      assert WorkflowProgressStatusCard in LiveUi.Widgets.WorkflowProgressAndStatus.modules()
      assert WorkflowProgressStatusCard in LiveUi.Widgets.workflow_progress_and_status_modules()
      assert WorkflowProgressStatusCard in LiveUi.Widgets.modules()
      refute WorkflowProgressStatusCard in LiveUi.Widgets.Operational.modules()

      assert metadata.family == :workflow_progress_and_status
      assert metadata.name == :workflow_progress_status_card
    end
  end
end
