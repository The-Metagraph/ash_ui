defmodule UnifiedUi.RepoProgressCardCompilerTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Tree
  alias UnifiedUi.Compiler
  alias UnifiedUi.Dsl.Node
  alias UnifiedUi.Dsl.Verifiers.ValidateWidgetComponents

  defmodule RepoProgressCardScreen do
    use UnifiedUi.Dsl

    identity do
      id(:repo_progress_card_screen)
      authored_ref([:tests, :repo_progress_card_screen])
    end

    composition do
      root(:repo_progress_card_root)
      mode(:screen)

      repo_progress_card :ash_ui_repo do
        name("ash_ui")
        repo_path("The-Metagraph/ash_ui")
        progress_pct(0.72)
        active_count(4)
        blocked_count(1)
        last_activity_at(~U[2026-05-19 10:00:00Z])
        depends_on(["unified_iur"])
        depended_by(["ariston-ui"])
        selected?(true)
        focus_intent("focus_repo")
        open_action(%{label: "Open", intent: "open_repo"})
      end
    end
  end

  test "DSL entity registers repo_progress_card as workflow progress and status" do
    assert :repo_progress_card in UnifiedUi.Dsl.Entities.WidgetComponents.workflow_kinds()

    entities =
      UnifiedUi.Dsl.Entities.WidgetComponents.workflow_entities()
      |> Enum.filter(&(&1.name == :repo_progress_card))

    assert [_entity] = entities
  end

  test "compiler lowers repo_progress_card into canonical repo attributes" do
    iur = Compiler.iur!(RepoProgressCardScreen)
    card = Tree.find_by_id(iur, :ash_ui_repo)

    assert card.kind == :repo_progress_card

    assert card.attributes.component == %{
             family: :workflow_progress_and_status,
             kind: :repo_progress_card
           }

    assert card.attributes.repo.id == "ash_ui"
    assert card.attributes.repo.name == "ash_ui"
    assert card.attributes.repo.path == "The-Metagraph/ash_ui"
    assert card.attributes.repo.progress == 72.0
    assert card.attributes.repo.status_counts == %{active: 4, blocked: 1}
    assert card.attributes.repo.activity == %{last_activity_at: ~U[2026-05-19 10:00:00Z]}
    assert card.attributes.repo.state == %{selected?: true}

    assert card.attributes.repo.dependencies == %{
             depends_on: [%{id: "unified_iur", label: "unified_iur", direction: :depends_on}],
             depended_by: [%{id: "ariston-ui", label: "ariston-ui", direction: :depended_by}]
           }

    assert card.attributes.repo.actions.open == %{label: "Open", intent: "open_repo"}
    assert card.attributes.repo.interactions.focus.intent == "focus_repo"
  end

  test "validation rejects invalid progress before renderer dispatch" do
    assert {:error, [:composition, :repo_progress_card, :bad_repo], message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :repo_progress_card,
               id: :bad_repo,
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
    assert {:error, [:composition, :repo_progress_card, :bad_repo], message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :repo_progress_card,
               id: :bad_repo,
               name: "ash_ui",
               progress_pct: 0.5,
               active_count: 0,
               blocked_count: 0,
               depends_on: [],
               depended_by: [],
               open_action: %{
                 :label => "Open",
                 :intent => "open_repo",
                 "phx-click" => "live_ui_interaction"
               }
             })

    assert message =~ "host-specific"
  end
end
