defmodule LiveUi.Viewport do
  @moduledoc """
  Package-facing reference helpers for viewport and scroll-region behavior.
  """

  @spec modules() :: [module()]
  def modules do
    [LiveUi.Widgets.Viewport, LiveUi.Widgets.ScrollBar, LiveUi.Widgets.SplitPane]
  end

  @spec scroll_axes() :: [atom()]
  def scroll_axes do
    [:vertical, :horizontal, :both]
  end

  @spec browser_bridge_hooks() :: [atom()]
  def browser_bridge_hooks do
    [:viewport_measurement, :scroll_tracking, :split_pane_drag]
  end
end
