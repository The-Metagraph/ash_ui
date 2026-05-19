defmodule UnifiedIUR.WidgetsTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Widgets
  alias UnifiedIUR.Widgets.{Advanced, Components, Data, Feedback, Foundational, Input, Navigation}

  test "exposes the foundational widget constructor family" do
    assert %{
             advanced: Advanced,
             components: Components,
             foundational: Foundational,
             input: Input,
             navigation: Navigation,
             data: Data,
             feedback: Feedback
           } = Widgets.modules()

    assert [
             :text,
             :label,
             :icon,
             :image,
             :badge,
             :hero,
             :button,
             :link,
             :separator,
             :spacer,
             :content
           ] ==
             Widgets.foundational_kinds()

    assert Widgets.foundational_kinds() == Foundational.kinds()
    assert [:menu, :tabs, :context_selector] == Widgets.navigation_kinds()
    assert Widgets.navigation_kinds() == Navigation.kinds()

    assert [:list, :table, :tree_view, :stat, :key_value, :info_list] ==
             Widgets.data_view_kinds()

    assert Widgets.data_view_kinds() == Data.kinds()

    assert [:status, :progress, :gauge, :inline_feedback, :diff_banner, :confidence_indicator] ==
             Widgets.feedback_kinds()

    assert Widgets.feedback_kinds() == Feedback.kinds()

    assert [
             :stream_widget,
             :log_viewer,
             :process_monitor,
             :cluster_dashboard,
             :command_palette,
             :markdown_viewer,
             :supervision_tree_viewer
           ] == Widgets.advanced_kinds()

    assert Widgets.advanced_kinds() == Advanced.kinds()
    assert Widgets.component_kinds() == Components.kinds()
  end
end
