defmodule LiveUi.RepoProgressCardTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Widgets.RepoProgressCard

  describe "RepoProgressCard Stage-4 Phoenix.Component" do
    test "renders with data-live-ui-widget attribute" do
      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "metagraph",
          progress_pct: 0.75,
          active_count: 3,
          blocked_count: 0
        })

      assert html =~ ~s(data-live-ui-widget="repo-progress-card")
    end

    test "renders repo name in header" do
      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "ash_ui"
        })

      assert html =~ "ash_ui"
    end

    test "renders data-repo-card attribute with name" do
      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "metagraph"
        })

      assert html =~ ~s(data-repo-card="metagraph")
    end

    test "renders data-selected=false when not selected" do
      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "metagraph",
          selected?: false
        })

      assert html =~ ~s(data-selected="false")
      refute html =~ "live-ui-repo-progress-card--selected"
    end

    test "renders data-selected=true and selected class when selected" do
      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "metagraph",
          selected?: true
        })

      assert html =~ ~s(data-selected="true")
      assert html =~ "live-ui-repo-progress-card--selected"
    end

    test "renders ARIA progressbar with correct valuenow" do
      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "metagraph",
          progress_pct: 0.65
        })

      assert html =~ ~s(role="progressbar")
      assert html =~ ~s(aria-valuenow="65")
      assert html =~ ~s(aria-valuemin="0")
      assert html =~ ~s(aria-valuemax="100")
      assert html =~ ~s(aria-label="metagraph progress: 65%")
    end

    test "renders stat chips for active and blocked counts" do
      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "metagraph",
          active_count: 4,
          blocked_count: 2
        })

      assert html =~ "4 active"
      assert html =~ "2 blocked"
    end

    test "renders data-loud=true on blocked chip when blocked_count > 0" do
      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "metagraph",
          blocked_count: 1
        })

      assert html =~ ~s(data-loud="true")
    end

    test "renders data-loud=false when blocked_count is 0" do
      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "metagraph",
          blocked_count: 0
        })

      assert html =~ ~s(data-loud="false")
    end

    test "renders enhanced aria-label on blocked chip when blocked_count > 0" do
      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "metagraph",
          blocked_count: 3
        })

      assert html =~ "attention needed"
    end

    test "renders optional path when provided" do
      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "metagraph",
          path: "/apps/TheMetagraph/metagraph"
        })

      assert html =~ "/apps/TheMetagraph/metagraph"
      assert html =~ "live-ui-repo-progress-card__path"
    end

    test "omits path when not provided" do
      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "metagraph"
        })

      refute html =~ "live-ui-repo-progress-card__path"
    end

    test "renders depends_on list when non-empty" do
      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "ariston-ui",
          depends_on: ["metagraph-analysis", "metagraph-agents"]
        })

      assert html =~ "depends on:"
      assert html =~ "metagraph-analysis"
      assert html =~ "metagraph-agents"
    end

    test "renders depended_by list when non-empty" do
      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "metagraph",
          depended_by: ["metagraph-analysis", "ariston-ui"]
        })

      assert html =~ "depended by:"
      assert html =~ "metagraph-analysis"
      assert html =~ "ariston-ui"
    end

    test "omits dependency sections when empty" do
      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "metagraph",
          depends_on: [],
          depended_by: []
        })

      refute html =~ "depends on:"
      refute html =~ "depended by:"
    end

    test "renders open_action button when always visible and card not selected" do
      open_action = %{label: "Open docs", intent: "open_docs", visible_when: :always}

      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "metagraph",
          selected?: false,
          open_action: open_action
        })

      assert html =~ "Open docs"
      assert html =~ "live-ui-repo-progress-card__open-action"
    end

    test "hides open_action when visible_when is :when_selected and card is not selected" do
      open_action = %{label: "Open chat", intent: "open_chat", visible_when: :when_selected}

      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "metagraph",
          selected?: false,
          open_action: open_action
        })

      refute html =~ "Open chat"
    end

    test "shows open_action when visible_when is :when_selected and card is selected" do
      open_action = %{label: "Open chat", intent: "open_chat", visible_when: :when_selected}

      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "metagraph",
          selected?: true,
          open_action: open_action
        })

      assert html =~ "Open chat"
    end

    test "renders with last_activity_label when provided" do
      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "metagraph",
          last_activity_label: "5m ago"
        })

      assert html =~ "5m ago"
    end

    test "header button has aria-pressed reflecting selected state" do
      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "metagraph",
          selected?: true
        })

      assert html =~ ~s(aria-pressed="true")
    end

    test "has correct semantic article element at root" do
      html =
        render_component(&RepoProgressCard.render/1, %{
          id: "test-repo-card",
          name: "metagraph"
        })

      assert html =~ "<article"
    end

    test "is registered in the operational widget modules" do
      assert RepoProgressCard in LiveUi.Widgets.Operational.modules()
    end
  end
end
