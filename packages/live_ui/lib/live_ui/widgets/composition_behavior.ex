defmodule LiveUi.Widgets.CompositionBehavior do
  @moduledoc """
  Reference surface for canonical composition behavior widgets.
  """

  @modules [
    LiveUi.Widgets.ListRepeat
  ]

  @spec modules() :: [module()]
  def modules, do: @modules
end
