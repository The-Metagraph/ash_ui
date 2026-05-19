defmodule AshUI.Resource.WorkflowProgressStatusCardTest do
  use ExUnit.Case, async: true

  alias AshUI.DSL.Storage
  alias AshUI.Resources.Validations.Authoring

  describe "workflow_progress_status_card authoring admission" do
    test "admits canonical resource and persisted DSL card names" do
      assert Storage.valid_widget_type?("workflow_progress_status_card")

      assert Storage.canonical_widget_type(:workflow_progress_status_card) ==
               {:ok, "workflow_progress_status_card"}

      assert %{
               type: :workflow_progress_status_card,
               props: %{name: "ash_ui", progress_pct: 0.5}
             } =
               Authoring.validate_element_definition!(%{
                 type: :workflow_progress_status_card,
                 props: %{name: "ash_ui", progress_pct: 0.5}
               })
    end

    test "keeps app-specific subject card names behind custom:*" do
      refute Storage.valid_widget_type?("team_workflow_progress_status_card")
      assert Storage.valid_widget_type?("custom:team_workflow_progress_status_card")

      assert_raise ArgumentError, ~r/known widget type/, fn ->
        Authoring.validate_element_definition!(%{
          type: :team_workflow_progress_status_card,
          props: %{name: "ash_ui"}
        })
      end

      assert %{
               type: "custom:team_workflow_progress_status_card",
               props: %{name: "ash_ui"}
             } =
               Authoring.validate_element_definition!(%{
                 type: "custom:team_workflow_progress_status_card",
                 props: %{name: "ash_ui"}
               })
    end

    test "allows semantic click actions on workflow subject cards" do
      definition =
        Authoring.validate_element_definition!(%{
          type: :workflow_progress_status_card,
          props: %{name: "ash_ui", progress_pct: 0.5}
        })

      action =
        Authoring.validate_action_definition!(%{
          id: :open_subject,
          signal: :click,
          source: %{resource: "Demo.WorkItem", action: "open", id: "ash_ui"},
          target: "subject.actions.open"
        })

      assert :ok = Authoring.validate_element_authority!(definition, [], [action])
    end
  end
end
