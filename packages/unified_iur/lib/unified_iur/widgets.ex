defmodule UnifiedIUR.Widgets do
  @moduledoc """
  Reference surface for canonical widget constructors exposed by `UnifiedIUR`.
  """

  alias UnifiedIUR.Widgets.{Advanced, Data, Feedback, Foundational, Input, Navigation}

  @foundational_kinds [
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
  ]
  @input_kinds [
    :text_input,
    :numeric_input,
    :toggle,
    :checkbox,
    :radio_group,
    :select,
    :pick_list,
    :slider,
    :date_input,
    :time_input,
    :file_input
  ]
  @navigation_kinds [:menu, :tabs]
  @data_view_kinds [:list, :table, :tree_view, :stat, :key_value, :info_list]
  @feedback_kinds [:status, :progress, :gauge, :inline_feedback]
  @advanced_kinds [
    :stream_widget,
    :log_viewer,
    :process_monitor,
    :cluster_dashboard,
    :command_palette,
    :markdown_viewer,
    :supervision_tree_viewer
  ]

  @spec modules() :: %{
          advanced: module(),
          data: module(),
          feedback: module(),
          foundational: module(),
          input: module(),
          navigation: module()
        }
  def modules do
    %{
      advanced: Advanced,
      foundational: Foundational,
      input: Input,
      navigation: Navigation,
      data: Data,
      feedback: Feedback
    }
  end

  @spec foundational_kinds() :: [atom()]
  def foundational_kinds do
    @foundational_kinds
  end

  @spec input_kinds() :: [atom()]
  def input_kinds do
    @input_kinds
  end

  @spec navigation_kinds() :: [atom()]
  def navigation_kinds do
    @navigation_kinds
  end

  @spec data_view_kinds() :: [atom()]
  def data_view_kinds do
    @data_view_kinds
  end

  @spec feedback_kinds() :: [atom()]
  def feedback_kinds do
    @feedback_kinds
  end

  @spec advanced_kinds() :: [atom()]
  def advanced_kinds do
    @advanced_kinds
  end
end
