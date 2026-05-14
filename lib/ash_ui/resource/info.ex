defmodule AshUI.Resource.Info do
  @moduledoc """
  Introspection helpers for resource-local Ash UI authoring modules.
  """

  alias Ash.Resource.Info, as: AshResourceInfo

  @type composition_edge :: %{
          name: atom(),
          destination: module(),
          type: atom() | nil,
          kind: :child | :companion,
          slot: String.t(),
          placement: String.t(),
          order: non_neg_integer(),
          repeat: map() | nil
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
  def authoritative?(module) when is_atom(module),
    do: resource_role(module) in [:screen, :element]

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
  Returns the screen-scoped action declarations owned by a screen resource module.
  """
  @spec screen_actions(module()) :: {:ok, [map()]} | {:error, term()}
  def screen_actions(module) when is_atom(module) do
    case resource_role(module) do
      :screen ->
        if function_exported?(module, :__ash_ui_actions__, 0) do
          {:ok, module.__ash_ui_actions__()}
        else
          {:ok, []}
        end

      other ->
        {:error, {:invalid_screen_resource, module, other}}
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
        relationship_semantics = relationship_semantics(module)

        with {:ok, relationships} <-
               module
               |> AshResourceInfo.relationships()
               |> Enum.with_index()
               |> Enum.reduce_while({:ok, []}, fn {relationship, index}, {:ok, acc} ->
                 case composition_edge(module, relationship, index, relationship_semantics) do
                   {:ok, nil} -> {:cont, {:ok, acc}}
                   {:ok, edge} -> {:cont, {:ok, acc ++ [edge]}}
                   {:error, reason} -> {:halt, {:error, reason}}
                 end
               end) do
          case unknown_relationship_semantics(module, relationship_semantics, relationships) do
            [] -> {:ok, relationships}
            unknown -> {:error, {:unknown_composition_relationships, module, unknown}}
          end
        end

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

  defp composition_edge(module, relationship, index, relationship_semantics) do
    destination = Map.get(relationship, :destination)
    type = Map.get(relationship, :type)
    name = Map.get(relationship, :name)

    if type in [:has_many, :has_one] and resource_role(destination) == :element do
      semantics =
        Map.get(relationship_semantics, name) ||
          inferred_relationship_semantics(destination, relationship, index)

      with :ok <- validate_repeat_semantics(module, relationship, destination, semantics) do
        {:ok,
         %{
           name: name,
           destination: destination,
           type: type,
           kind: semantics.kind,
           slot: semantics.slot,
           placement: semantics.placement,
           order: semantics.order,
           repeat: Map.get(semantics, :repeat)
         }}
      end
    else
      {:ok, nil}
    end
  end

  defp relationship_semantics(module) do
    if function_exported?(module, :__ash_ui_relationships__, 0) do
      module.__ash_ui_relationships__()
    else
      %{}
    end
  end

  defp unknown_relationship_semantics(module, semantics, edges) do
    valid_names =
      module
      |> AshResourceInfo.relationships()
      |> Enum.map(&Map.get(&1, :name))
      |> MapSet.new()

    used_names = MapSet.new(Enum.map(edges, & &1.name))

    semantics
    |> Map.keys()
    |> Enum.reject(fn name ->
      MapSet.member?(valid_names, name) and MapSet.member?(used_names, name)
    end)
  end

  defp inferred_relationship_semantics(destination, relationship, index) do
    {:ok, definition} = element_definition(destination)
    metadata = Map.get(definition, :metadata, %{})

    %{
      kind: relationship_kind(relationship),
      slot: relationship_slot(metadata),
      placement: relationship_placement(metadata),
      order: relationship_order(metadata, index),
      repeat: nil
    }
  end

  defp validate_repeat_semantics(_module, _relationship, _destination, %{repeat: nil}), do: :ok

  defp validate_repeat_semantics(module, relationship, destination, semantics) do
    repeat = Map.get(semantics, :repeat)
    name = Map.get(relationship, :name)
    type = Map.get(relationship, :type)
    binding_id = repeat_value(repeat, :binding_id)

    cond do
      is_nil(repeat) ->
        :ok

      type != :has_many ->
        {:error, {:invalid_repeat_relationship, module, name, :requires_has_many}}

      not destination_list_binding?(destination, binding_id) ->
        {:error,
         {:invalid_repeat_relationship, module, name, {:missing_list_binding, binding_id}}}

      true ->
        :ok
    end
  end

  defp destination_list_binding?(destination, binding_id) do
    with {:ok, bindings} <- element_bindings(destination) do
      Enum.any?(bindings, fn binding ->
        same_identifier?(Map.get(binding, :id), binding_id) and
          Map.get(binding, :binding_type) == :list
      end)
    else
      _other -> false
    end
  end

  defp same_identifier?(left, right), do: to_string(left) == to_string(right)

  defp repeat_value(repeat, key) when is_map(repeat) do
    Map.get(repeat, key) || Map.get(repeat, Atom.to_string(key))
  end

  defp repeat_value(_repeat, _key), do: nil

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
