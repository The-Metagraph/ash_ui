defmodule AshUI.Resource.Info do
  @moduledoc """
  Introspection helpers for resource-local Ash UI authoring modules.
  """

  @type composition_edge :: %{
          name: atom(),
          destination: module(),
          type: atom() | nil,
          kind: :child | :companion,
          slot: String.t(),
          placement: String.t(),
          order: non_neg_integer()
        }

  @doc """
  Returns the Ash UI authoring role exposed by a resource module.
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

  @doc """
  Returns true when a module exposes screen or element authoring authority.
  """
  @spec authoritative?(module()) :: boolean()
  def authoritative?(module) when is_atom(module), do: resource_role(module) in [:screen, :element]

  @doc """
  Returns the validated screen definition owned by a screen resource module.
  """
  @spec screen_definition(module()) :: {:ok, map()} | {:error, term()}
  def screen_definition(module) when is_atom(module) do
    case resource_role(module) do
      :screen -> {:ok, module.__ash_ui_screen_definition__()}
      other -> {:error, {:invalid_screen_resource, module, other}}
    end
  end

  @doc """
  Returns the screen-scoped bindings declared on a screen resource module.
  """
  @spec screen_bindings(module()) :: {:ok, [map()]} | {:error, term()}
  def screen_bindings(module) when is_atom(module) do
    case resource_role(module) do
      :screen -> {:ok, module.__ash_ui_bindings__()}
      other -> {:error, {:invalid_screen_resource, module, other}}
    end
  end

  @doc """
  Returns the validated element definition owned by an element resource module.
  """
  @spec element_definition(module()) :: {:ok, map()} | {:error, term()}
  def element_definition(module) when is_atom(module) do
    case resource_role(module) do
      :element -> {:ok, module.__ash_ui_element_definition__()}
      other -> {:error, {:invalid_element_resource, module, other}}
    end
  end

  @doc """
  Returns the element-local bindings declared on an element resource module.
  """
  @spec element_bindings(module()) :: {:ok, [map()]} | {:error, term()}
  def element_bindings(module) when is_atom(module) do
    case resource_role(module) do
      :element -> {:ok, module.__ash_ui_bindings__()}
      other -> {:error, {:invalid_element_resource, module, other}}
    end
  end

  @doc """
  Returns the element-local action declarations owned by an element resource module.
  """
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

  @doc """
  Returns the composition relationships declared by a screen or element module.

  Composition edges are the `has_one` / `has_many` relationships that point at
  other authoritative element resources.
  """
  @spec composition_edges(module()) :: {:ok, [composition_edge()]} | {:error, term()}
  def composition_edges(module) when is_atom(module) do
    case resource_role(module) do
      role when role in [:screen, :element] ->
        relationships =
          module
          |> Ash.Resource.Info.relationships()
          |> Enum.with_index()
          |> Enum.reduce([], fn {relationship, index}, acc ->
            case composition_edge(module, relationship, index) do
              nil -> acc
              edge -> acc ++ [edge]
            end
          end)

        {:ok, relationships}

      other ->
        {:error, {:invalid_authority_resource, module, other}}
    end
  end

  @doc """
  Returns the inline fragment owned by a screen resource module.
  """
  @spec screen_inline_fragment(module()) :: {:ok, map() | nil} | {:error, term()}
  def screen_inline_fragment(module) when is_atom(module) do
    with {:ok, definition} <- screen_definition(module) do
      {:ok, Map.get(definition, :inline_fragment)}
    end
  end

  defp composition_edge(_module, relationship, index) do
    destination = Map.get(relationship, :destination)
    type = Map.get(relationship, :type)

    if type in [:has_many, :has_one] and resource_role(destination) == :element do
      {:ok, definition} = element_definition(destination)
      metadata = Map.get(definition, :metadata, %{})

      %{
        name: Map.get(relationship, :name),
        destination: destination,
        type: type,
        kind: relationship_kind(relationship),
        slot: relationship_slot(metadata),
        placement: relationship_placement(metadata),
        order: relationship_order(metadata, index)
      }
    end
  end

  defp relationship_kind(relationship) do
    name = relationship |> Map.get(:name) |> to_string()

    if String.contains?(name, "companion") do
      :companion
    else
      :child
    end
  end

  defp relationship_slot(metadata) do
    metadata_value(metadata, :slot) ||
      metadata_value(metadata, :section) ||
      "default"
  end

  defp relationship_placement(metadata) do
    metadata_value(metadata, :placement) || "append"
  end

  defp relationship_order(metadata, fallback) do
    case metadata_value(metadata, :order) || metadata_value(metadata, :position) do
      value when is_integer(value) and value >= 0 -> value
      _other -> fallback
    end
  end

  defp metadata_value(metadata, key) when is_map(metadata) do
    Map.get(metadata, key) || Map.get(metadata, to_string(key))
  end
end
