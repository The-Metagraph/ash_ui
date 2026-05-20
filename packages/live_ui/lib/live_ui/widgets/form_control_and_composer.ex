defmodule LiveUi.Widgets.FormControlAndComposer do
  @moduledoc """
  Reference surface for canonical form control and composer widgets.
  """

  @modules [
    LiveUi.Widgets.SegmentedButtonGroup,
    LiveUi.Widgets.CollectionPicker
  ]

  @spec modules() :: [module()]
  def modules, do: @modules
end
