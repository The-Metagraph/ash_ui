defmodule UnifiedIUR.Widgets.RepoProgressCardTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.{Element, Interaction, Validate}
  alias UnifiedIUR.Widgets.Components

  describe "repo_progress_card constructor" do
    test "builds a valid element with required identity and default status shape" do
      card = Components.repo_progress_card(name: "metagraph", progress_pct: 0.5)

      assert %Element{kind: :repo_progress_card} = card

      assert card.attributes.component == %{
               family: :workflow_progress_and_status,
               kind: :repo_progress_card
             }

      assert card.attributes.repo.id == "metagraph"
      assert card.attributes.repo.name == "metagraph"
      assert card.attributes.repo.progress == 50.0
      assert card.attributes.repo.status_counts == %{active: 0, blocked: 0}
      assert card.attributes.repo.dependencies == %{depends_on: [], depended_by: []}
      assert card.attributes.repo.state == %{selected?: false}

      assert %Interaction{family: :focus, intent: "focus_repo"} =
               card.attributes.repo.interactions.focus

      assert :ok = Validate.element(card)
    end

    test "accepts a full canonical declaration and preserves dependency order" do
      open_interaction = Interaction.open(intent: :open_repo, entity: "ash_ui")
      focus_interaction = Interaction.focus(intent: :focus_repo, entity: "ash_ui")

      dependency_select_interaction =
        Interaction.selection(intent: :select_dependency, entity: "ash_ui")

      card =
        Components.repo_progress_card(
          repo_id: "repo:ash_ui",
          name: "ash_ui",
          path: "The-Metagraph/ash_ui",
          progress: 72,
          active_count: 4,
          blocked_count: 1,
          done_count: 6,
          custom_counts: [%{key: :reviews, value: 2, label: "Reviews"}],
          activity: %{label: "Synced"},
          last_activity_at: ~U[2026-05-19 10:00:00Z],
          depends_on: [
            "unified_iur",
            %{id: "unified_ui", label: "Unified UI", state: :active}
          ],
          depended_by: ["ariston-ui", "ash-hq"],
          selected?: true,
          focus_interaction: focus_interaction,
          dependency_select_interaction: dependency_select_interaction,
          open_action: %{
            label: "Open",
            intent: :open_repo,
            visible_when: :when_selected,
            interaction: open_interaction
          }
        )

      assert card.attributes.repo == %{
               id: "repo:ash_ui",
               name: "ash_ui",
               path: "The-Metagraph/ash_ui",
               progress: 72.0,
               status_counts: %{
                 active: 4,
                 blocked: 1,
                 done: 6,
                 custom: [%{key: :reviews, value: 2, label: "Reviews"}]
               },
               activity: %{label: "Synced", last_activity_at: ~U[2026-05-19 10:00:00Z]},
               dependencies: %{
                 depends_on: [
                   %{id: "unified_iur", label: "unified_iur", direction: :depends_on},
                   %{
                     id: "unified_ui",
                     label: "Unified UI",
                     state: :active,
                     direction: :depends_on
                   }
                 ],
                 depended_by: [
                   %{id: "ariston-ui", label: "ariston-ui", direction: :depended_by},
                   %{id: "ash-hq", label: "ash-hq", direction: :depended_by}
                 ]
               },
               state: %{selected?: true},
               actions: %{
                 open: %{
                   label: "Open",
                   intent: :open_repo,
                   visible_when: :when_selected,
                   interaction: open_interaction
                 }
               },
               interactions: %{
                 focus: focus_interaction,
                 dependency_select: dependency_select_interaction
               }
             }

      assert :ok = Validate.element(card)
    end

    test "raises when :name or :repo_id is missing" do
      assert_raise ArgumentError, ~r/requires a non-empty :name/, fn ->
        Components.repo_progress_card(progress_pct: 0.5)
      end

      assert_raise ArgumentError, ~r/requires a non-empty :repo_id/, fn ->
        Components.repo_progress_card(repo_id: "", name: "metagraph")
      end
    end

    test "raises when progress is out of range" do
      assert_raise ArgumentError, ~r/progress_pct must be in 0\.0\.\.1\.0/, fn ->
        Components.repo_progress_card(name: "metagraph", progress_pct: 1.5)
      end

      assert_raise ArgumentError, ~r/progress must be in 0\.0\.\.100\.0/, fn ->
        Components.repo_progress_card(name: "metagraph", progress: 101)
      end
    end

    test "raises when status counts, actions, or dependencies are malformed" do
      assert_raise ArgumentError, ~r/active_count must be a non-negative integer/, fn ->
        Components.repo_progress_card(name: "metagraph", active_count: -1)
      end

      assert_raise ArgumentError, ~r/open_action must have :label and :intent/, fn ->
        Components.repo_progress_card(name: "metagraph", open_action: %{label: "Open"})
      end

      assert_raise ArgumentError, ~r/depends_on must be a list of strings or maps/, fn ->
        Components.repo_progress_card(name: "metagraph", depends_on: [:atom_dep])
      end
    end

    test "validates malformed raw cards with structured diagnostics" do
      invalid =
        Element.new(:widget, :repo_progress_card,
          attributes: %{
            component: %{family: :workflow_progress_and_status, kind: :repo_progress_card},
            repo: %{
              id: "",
              name: "ash_ui",
              progress: 125,
              status_counts: %{active: -1, blocked: 0},
              dependencies: %{
                depends_on: [%{"phx-click" => "select", id: "unified_iur"}],
                depended_by: ["ash-hq"]
              },
              actions: %{open: nil},
              interactions: %{focus: "focus_repo"}
            }
          }
        )

      assert {:error, errors} = Validate.element(invalid)

      assert [
               :invalid_repo_contract,
               :invalid_repo_contract,
               :invalid_repo_status_count,
               :invalid_repo_dependency,
               :invalid_repo_dependency,
               :invalid_repo_dependency,
               :invalid_repo_action,
               :invalid_repo_interaction
             ] = Enum.map(errors, & &1.code)
    end

    test "validates LiveView event leakage in actions and interactions" do
      invalid_action =
        Element.new(:widget, :repo_progress_card,
          attributes: %{
            component: %{family: :workflow_progress_and_status, kind: :repo_progress_card},
            repo: %{
              id: "ash_ui",
              name: "ash_ui",
              progress: 50,
              status_counts: %{active: 1, blocked: 0},
              dependencies: %{depends_on: [], depended_by: []},
              actions: %{open: %{"phx-click" => "open", label: "Open", intent: "open_repo"}}
            }
          }
        )

      invalid_interaction =
        Components.repo_progress_card(
          name: "ash_ui",
          focus_interaction: %Interaction{
            family: :focus,
            intent: :focus_repo,
            target: %{"phx-click" => "focus_repo"}
          }
        )

      assert {:error, [action_error]} = Validate.element(invalid_action)
      assert action_error.code == :invalid_repo_action

      assert {:error, [interaction_error]} = Validate.element(invalid_interaction)
      assert interaction_error.code == :invalid_repo_interaction
    end

    test "is included in workflow and aggregate component kind lists" do
      assert :repo_progress_card in Components.workflow_kinds()
      assert :repo_progress_card in Components.kinds()
    end
  end
end
