defmodule AshUI.Resource.Info do
  @moduledoc """
  Introspection helpers for resource-local Ash UI authoring modules.
  """

  @spec resource_role(module()) :: :screen | :element | nil
  def resource_role(module) when is_atom(module) do
    if Code.ensure_loaded?(module) do
      cond do
        function_exported?(module, :__ash_ui_screen_definition__, 0) -> :screen
        function_exported?(module, :__ash_ui_element_definition__, 0) -> :element
        true -> nil
      end
    else
      nil
    end
  end

  @spec authoritative?(module()) :: boolean()
  def authoritative?(module) when is_atom(module), do: resource_role(module) in [:screen, :element]

  @spec screen_definition(module()) :: {:ok, map()} | {:error, term()}
  def screen_definition(module) when is_atom(module) do
    case resource_role(module) do
      :screen -> {:ok, module.__ash_ui_screen_definition__()}
      other -> {:error, {:invalid_screen_resource, module, other}}
    end
  end

  @spec screen_bindings(module()) :: {:ok, [map()]} | {:error, term()}
  def screen_bindings(module) when is_atom(module) do
    case resource_role(module) do
      :screen -> {:ok, module.__ash_ui_bindings__()}
      other -> {:error, {:invalid_screen_resource, module, other}}
    end
  end

  @spec element_definition(module()) :: {:ok, map()} | {:error, term()}
  def element_definition(module) when is_atom(module) do
    case resource_role(module) do
      :element -> {:ok, module.__ash_ui_element_definition__()}
      other -> {:error, {:invalid_element_resource, module, other}}
    end
  end

  @spec element_bindings(module()) :: {:ok, [map()]} | {:error, term()}
  def element_bindings(module) when is_atom(module) do
    case resource_role(module) do
      :element -> {:ok, module.__ash_ui_bindings__()}
      other -> {:error, {:invalid_element_resource, module, other}}
    end
  end

  @spec element_actions(module()) :: {:ok, [map()]} | {:error, term()}
  def element_actions(module) when is_atom(module) do
    case resource_role(module) do
      :element ->
        if function_exported?(module, :__ash_ui_actions__, 0) do
          {:ok, module.__ash_ui_actions__()}
        else
          {:ok, []}
        end

      other ->
        {:error, {:invalid_element_resource, module, other}}
    end
  end
end
