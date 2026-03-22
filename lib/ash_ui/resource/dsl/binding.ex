defmodule AshUI.Resource.DSL.Binding do
  @moduledoc """
  Compatibility wrapper for the binding DSL helpers.
  """

  defmacro __using__(opts) do
    quote do
      use AshUI.DSL.Binding, unquote(opts)
    end
  end

  @doc """
  Converts binding DSL entries into resource attributes.
  """
  defdelegate to_attributes(entries), to: AshUI.DSL.Binding
end
