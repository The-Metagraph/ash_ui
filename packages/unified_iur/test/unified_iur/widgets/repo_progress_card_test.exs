defmodule UnifiedIUR.Widgets.RepoProgressCardTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element
  alias UnifiedIUR.Widgets.Components

  describe "repo_progress_card constructor" do
    test "builds a valid element with required name" do
      card = Components.repo_progress_card(name: "metagraph", progress_pct: 0.5)

      assert %Element{kind: :repo_progress_card} = card

      assert card.attributes.component == %{
               family: :workflow_progress_and_status,
               kind: :repo_progress_card
             }

      assert card.attributes.repo.name == "metagraph"
      assert card.attributes.repo.progress_pct == 0.5
    end

    test "defaults progress_pct, active_count, blocked_count to zero" do
      card = Components.repo_progress_card(name: "ash_ui")

      assert card.attributes.repo.progress_pct == 0.0
      assert card.attributes.repo.active_count == 0
      assert card.attributes.repo.blocked_count == 0
    end

    test "accepts optional path, depends_on, depended_by" do
      card =
        Components.repo_progress_card(
          name: "metagraph",
          path: "/Users/mjdecour/apps/TheMetagraph/metagraph",
          depends_on: [],
          depended_by: ["ariston-ui", "metagraph-analysis"]
        )

      assert card.attributes.repo.path == "/Users/mjdecour/apps/TheMetagraph/metagraph"
      assert card.attributes.repo.depends_on == []
      assert card.attributes.repo.depended_by == ["ariston-ui", "metagraph-analysis"]
    end

    test "accepts selected? and focus_intent" do
      card =
        Components.repo_progress_card(
          name: "metagraph",
          selected?: true,
          focus_intent: "select_repo"
        )

      assert card.attributes.repo.selected? == true
      assert card.attributes.repo.focus_intent == "select_repo"
    end

    test "defaults selected? to false and focus_intent to focus_repo" do
      card = Components.repo_progress_card(name: "metagraph")

      assert card.attributes.repo.selected? == false
      assert card.attributes.repo.focus_intent == "focus_repo"
    end

    test "accepts open_action with label and intent" do
      open_action = %{label: "Open chat", intent: "open_chat", visible_when: :when_selected}
      card = Components.repo_progress_card(name: "metagraph", open_action: open_action)

      assert card.attributes.open_action[:label] == "Open chat"
      assert card.attributes.open_action[:intent] == "open_chat"
    end

    test "accepts last_activity_at as DateTime" do
      dt = DateTime.utc_now()
      card = Components.repo_progress_card(name: "metagraph", last_activity_at: dt)

      assert card.attributes.repo.last_activity_at == dt
    end

    test "raises when :name is missing" do
      assert_raise ArgumentError, ~r/requires a non-empty :name/, fn ->
        Components.repo_progress_card(progress_pct: 0.5)
      end
    end

    test "raises when :name is empty string" do
      assert_raise ArgumentError, ~r/requires a non-empty :name/, fn ->
        Components.repo_progress_card(name: "")
      end
    end

    test "raises when :progress_pct is out of range (above 1.0)" do
      assert_raise ArgumentError, ~r/progress_pct must be in 0\.0\.\.1\.0/, fn ->
        Components.repo_progress_card(name: "metagraph", progress_pct: 1.5)
      end
    end

    test "raises when :progress_pct is negative" do
      assert_raise ArgumentError, ~r/progress_pct must be in 0\.0\.\.1\.0/, fn ->
        Components.repo_progress_card(name: "metagraph", progress_pct: -0.1)
      end
    end

    test "raises when :active_count is negative" do
      assert_raise ArgumentError, ~r/active_count must be a non-negative integer/, fn ->
        Components.repo_progress_card(name: "metagraph", active_count: -1)
      end
    end

    test "raises when :blocked_count is negative" do
      assert_raise ArgumentError, ~r/blocked_count must be a non-negative integer/, fn ->
        Components.repo_progress_card(name: "metagraph", blocked_count: -3)
      end
    end

    test "raises when :open_action is malformed (missing :intent)" do
      assert_raise ArgumentError, ~r/open_action must have :label and :intent/, fn ->
        Components.repo_progress_card(name: "metagraph", open_action: %{label: "Open"})
      end
    end

    test "raises when :open_action is malformed (missing :label)" do
      assert_raise ArgumentError, ~r/open_action must have :label and :intent/, fn ->
        Components.repo_progress_card(name: "metagraph", open_action: %{intent: "open_chat"})
      end
    end

    test "raises when :depends_on contains non-strings" do
      assert_raise ArgumentError, ~r/depends_on must be a list of strings/, fn ->
        Components.repo_progress_card(name: "metagraph", depends_on: [:atom_dep])
      end
    end

    test "raises when :depended_by contains non-strings" do
      assert_raise ArgumentError, ~r/depended_by must be a list of strings/, fn ->
        Components.repo_progress_card(name: "metagraph", depended_by: [123])
      end
    end

    test "is included in workflow_summary_kinds" do
      assert :repo_progress_card in Components.workflow_summary_kinds()
    end

    test "is included in Components.kinds()" do
      assert :repo_progress_card in Components.kinds()
    end
  end
end
