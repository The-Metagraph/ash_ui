defmodule AshUI.Resource.DSL.Element do
  @moduledoc """
  Compatibility wrapper for the element DSL helpers.
  """

  defmacro __using__(opts) do
    quote do
      use AshUI.DSL.Element, unquote(opts)
    end
  end

  @doc """
  Converts element DSL entries into resource attributes.
  """
  defdelegate to_attributes(entries), to: AshUI.DSL.Element
end
