defmodule LiveUi.Widgets.Display do
  @moduledoc """
  Reference surface for advanced display-system native widgets.
  """

  @modules [
    LiveUi.Widgets.Viewport,
    LiveUi.Widgets.ScrollBar,
    LiveUi.Widgets.SplitPane,
    LiveUi.Widgets.Canvas
  ]

  @spec modules() :: [module()]
  def modules do
    @modules
  end
end
