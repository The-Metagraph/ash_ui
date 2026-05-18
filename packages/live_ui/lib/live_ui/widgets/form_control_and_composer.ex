defmodule LiveUi.Widgets.FormControlAndComposer do
  @moduledoc """
  Reference surface for canonical form control and composer widgets.
  """

  @modules [
    LiveUi.Widgets.SegmentedButtonGroup
  ]

  @spec modules() :: [module()]
  def modules, do: @modules
end
