defmodule LiveUi.Widgets.DiffBannerTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component

  describe "metadata" do
    test "is a feedback widget component" do
      metadata = Component.metadata(LiveUi.Widgets.DiffBanner)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.DiffBanner.Component
      assert metadata.family == :feedback
      assert metadata.name == :diff_banner
      assert LiveUi.Widgets.DiffBanner in LiveUi.Widgets.Feedback.modules()
    end
  end

  describe "rendering" do
    test "renders all filter chips including all" do
      html =
        render_component(&LiveUi.Widgets.DiffBanner.component/1, %{
          id: "diff-banner",
          new_count: 3,
          changed_count: 5,
          removed_count: 1,
          active_filter: :all
        })

      assert html =~ ~s(data-live-ui-widget-boundary="diff_banner")
      assert html =~ ~s(data-live-ui-widget="diff-banner")
      assert html =~ "9 all"
      assert html =~ "3 new"
      assert html =~ "5 changed"
      assert html =~ "1 removed"
      assert html =~ ~s(data-filter-kind="all")
      assert html =~ ~s(role="radiogroup")
      assert html =~ ~s(role="radio")
      assert html =~ ~s(aria-checked="true")
    end

    test "renders static chips without radio semantics" do
      html =
        render_component(&LiveUi.Widgets.DiffBanner.component/1, %{
          id: "static-diff-banner",
          new_count: 0,
          changed_count: 2,
          removed_count: 0,
          show_filter_chips?: false
        })

      refute html =~ ~s(role="radiogroup")
      refute html =~ ~s(role="radio")
      assert html =~ "live-ui-diff-banner__chip--static"
    end

    test "hides base label in compact mode" do
      html =
        render_component(&LiveUi.Widgets.DiffBanner.component/1, %{
          id: "compact-diff-banner",
          base_label: "Compared to last run",
          size: :compact
        })

      refute html =~ "Compared to last run"
      assert html =~ ~s(data-live-ui-size="compact")
    end
  end
end
