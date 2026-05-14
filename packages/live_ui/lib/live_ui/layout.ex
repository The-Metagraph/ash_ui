defmodule LiveUi.Layout do
  @moduledoc """
  Reference surface for foundational native layout primitives.
  """

  @modules [
    LiveUi.Layout.Row,
    LiveUi.Layout.Column,
    LiveUi.Layout.Grid
  ]

  @spec modules() :: [module()]
  def modules do
    @modules
  end

  @spec structural_modules() :: [module()]
  def structural_modules do
    @modules
  end

  @spec structural?(module()) :: boolean()
  def structural?(module) when is_atom(module) do
    module in @modules
  end
end
