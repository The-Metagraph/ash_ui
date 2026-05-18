defmodule LiveUi.Widgets.RowAndArtifact do
  @moduledoc """
  Reference surface for row and artifact widgets.
  """

  @modules [
    LiveUi.Widgets.BlockerRow
  ]

  @spec modules() :: [module()]
  def modules, do: @modules
end
