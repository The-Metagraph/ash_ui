defmodule LiveUi.Widgets.LayerShellAndCallout do
  @moduledoc """
  Reference surface for canonical layer shell and callout widgets.
  """

  @modules [
    LiveUi.Widgets.RightRail
  ]

  @spec modules() :: [module()]
  def modules, do: @modules
end
