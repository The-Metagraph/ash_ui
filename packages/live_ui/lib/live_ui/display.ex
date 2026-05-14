defmodule LiveUi.Display do
  @moduledoc """
  Package-facing reference surface for advanced display primitives.
  """

  @bridge_hooks [:viewport_measurement, :scroll_tracking, :canvas_pointer, :split_pane_drag]

  @spec modules() :: [module()]
  def modules do
    LiveUi.Widgets.Display.modules()
  end

  @spec primitives() :: [atom()]
  def primitives do
    [:viewport, :scroll_bar, :split_pane, :canvas]
  end

  @spec browser_bridge_hooks() :: [atom()]
  def browser_bridge_hooks do
    @bridge_hooks
  end

  @spec bounded_bridge?() :: boolean()
  def bounded_bridge?, do: true
end
