defmodule UnifiedUi.WorkflowProgressStatusCardCompilerTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Tree
  alias UnifiedUi.Compiler
  alias UnifiedUi.Dsl.Node
  alias UnifiedUi.Dsl.Verifiers.ValidateWidgetComponents

  defmodule WorkflowProgressStatusCardScreen do
    use UnifiedUi.Dsl

    identity do
      id(:workflow_progress_status_card_screen)
      authored_ref([:tests, :workflow_progress_status_card_screen])
    end

    composition do
      root(:workflow_progress_status_card_root)
      mode(:screen)

      workflow_progress_status_card :ash_ui_subject do
        name("ash_ui")
        subject_path("workspaces/ash_ui")
        progress_pct(0.72)
        active_count(4)
        blocked_count(1)
        last_activity_at(~U[2026-05-19 10:00:00Z])
        depends_on(["unified_iur"])
        depended_by(["ariston-ui"])
        selected?(true)
        focus_intent("focus_subject")
        open_action(%{label: "Open", intent: "open_subject"})
      end
    end
  end

  test "DSL entity registers workflow_progress_status_card as workflow progress and status" do
    assert :workflow_progress_status_card in UnifiedUi.Dsl.Entities.WidgetComponents.workflow_kinds()

    entities =
      UnifiedUi.Dsl.Entities.WidgetComponents.workflow_entities()
      |> Enum.filter(&(&1.name == :workflow_progress_status_card))

    assert [_entity] = entities
  end

  test "compiler lowers workflow_progress_status_card into canonical subject attributes" do
    iur = Compiler.iur!(WorkflowProgressStatusCardScreen)
    card = Tree.find_by_id(iur, :ash_ui_subject)

    assert card.kind == :workflow_progress_status_card

    assert card.attributes.component == %{
             family: :workflow_progress_and_status,
             kind: :workflow_progress_status_card
           }

    assert card.attributes.subject.id == "ash_ui"
    assert card.attributes.subject.name == "ash_ui"
    assert card.attributes.subject.path == "workspaces/ash_ui"
    assert card.attributes.subject.progress == 72.0
    assert card.attributes.subject.status_counts == %{active: 4, blocked: 1}
    assert card.attributes.subject.activity == %{last_activity_at: ~U[2026-05-19 10:00:00Z]}
    assert card.attributes.subject.state == %{selected?: true}

    assert card.attributes.subject.dependencies == %{
             depends_on: [%{id: "unified_iur", label: "unified_iur", direction: :depends_on}],
             depended_by: [%{id: "ariston-ui", label: "ariston-ui", direction: :depended_by}]
           }

    assert card.attributes.subject.actions.open == %{label: "Open", intent: "open_subject"}
    assert card.attributes.subject.interactions.focus.intent == "focus_subject"
  end

  test "validation rejects invalid progress before renderer dispatch" do
    assert {:error, [:composition, :workflow_progress_status_card, :bad_subject], message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :workflow_progress_status_card,
               id: :bad_subject,
               name: "ash_ui",
               progress_pct: 1.5,
               active_count: 0,
               blocked_count: 0,
               depends_on: [],
               depended_by: []
             })

    assert message =~ "progress_pct"
  end

  test "validation rejects host-specific open action transport" do
    assert {:error, [:composition, :workflow_progress_status_card, :bad_subject], message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :workflow_progress_status_card,
               id: :bad_subject,
               name: "ash_ui",
               progress_pct: 0.5,
               active_count: 0,
               blocked_count: 0,
               depends_on: [],
               depended_by: [],
               open_action: %{
                 :label => "Open",
                 :intent => "open_subject",
                 "phx-click" => "live_ui_interaction"
               }
             })

    assert message =~ "host-specific"
  end
end
