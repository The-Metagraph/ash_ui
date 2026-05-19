defmodule AshUI.Phase33PackageBoundaryTest do
  use ExUnit.Case, async: true

  @moduletag :conformance

  alias LiveUi.Widgets.RepoProgressCard
  alias UnifiedIUR.Widgets.Components

  describe "Section 33.2 - canonical workflow progress and status boundary" do
    test "repo_progress_card is cataloged as workflow_progress_and_status everywhere" do
      assert :repo_progress_card in UnifiedUi.WidgetComponents.kinds()
      assert :repo_progress_card in AshUI.WidgetComponents.kinds()
      assert :repo_progress_card in Components.kinds()
      assert :repo_progress_card in Components.workflow_kinds()

      assert :repo_progress_card in
               UnifiedUi.WidgetComponents.component_families().workflow_progress_and_status

      assert :repo_progress_card in
               AshUI.WidgetComponents.families().workflow_progress_and_status

      catalog_entry =
        Enum.find(UnifiedUi.WidgetComponents.catalog(), &(&1.kind == :repo_progress_card))

      assert catalog_entry.family == :workflow_progress_and_status

      card = Components.repo_progress_card(name: "ash_ui")

      assert card.attributes.component.family == :workflow_progress_and_status
      assert card.attributes.component.kind == :repo_progress_card
    end

    test "repo_progress_card does not introduce workflow or workflow_summary families" do
      refute :workflow in LiveUi.Widgets.families()
      refute :workflow_summary in LiveUi.Widgets.families()
      refute function_exported?(Components, :workflow_summary_kinds, 0)
    end

    test "Live UI registers the native widget in the canonical family" do
      metadata = LiveUi.Component.metadata(RepoProgressCard)

      assert :workflow_progress_and_status in LiveUi.Widgets.families()
      assert RepoProgressCard in LiveUi.Widgets.WorkflowProgressAndStatus.modules()
      assert RepoProgressCard in LiveUi.Widgets.workflow_progress_and_status_modules()
      assert RepoProgressCard in LiveUi.Widgets.modules()
      refute RepoProgressCard in LiveUi.Widgets.Operational.modules()

      assert metadata.family == :workflow_progress_and_status
      assert metadata.name == :repo_progress_card
    end
  end
end
