defmodule AshUI.Resource.DSL.Screen do
  @moduledoc """
  Compatibility wrapper for the screen DSL helpers.
  """

  defmacro __using__(opts) do
    quote do
      use AshUI.DSL.Screen, unquote(opts)
    end
  end

  @doc """
  Converts screen DSL entries into resource attributes.
  """
  defdelegate to_attributes(entries), to: AshUI.DSL.Screen
end
