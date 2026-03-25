defmodule UnifiedIUR.Normalize do
  @moduledoc """
  Normalization and conversion helpers that shape authored compile output into
  stable canonical values.
  """

  alias UnifiedIUR.Attachment
  alias UnifiedIUR.{Binding, Element, Interaction, Metadata, Style, Validate}
  alias UnifiedIUR.Element.Child
  alias UnifiedIUR.Validate.Error

  @reserved_element_keys ~w(id type kind metadata attributes children)a
  @attachment_keys ~w(
    style
    theme
    theme_id
    style_refs
    token_refs
    variant
    state
    tone
    inherit_style?
    interaction
    interactions
    interaction_scope
    interaction_scope_mode
    interaction_scope_namespace
    interaction_scope_target_path
    interaction_scope_inherit?
    binding
    bindings
  )a

  @spec element(Element.t() | map() | keyword()) :: {:ok, Element.t()} | {:error, [Error.t()]}
  def element(input) do
    with {:ok, element} <- do_normalize_element(input),
         :ok <- Validate.element(element) do
      {:ok, element}
    end
  end

  @spec element!(Element.t() | map() | keyword()) :: Element.t()
  def element!(input) do
    case element(input) do
      {:ok, element} ->
        element

      {:error, errors} ->
        message =
          errors
          |> Enum.map_join("\n", fn %Error{} = error -> Error.format(error) end)

        raise ArgumentError, message
    end
  end

  @spec elements([Element.t() | map() | keyword()]) ::
          {:ok, [Element.t()]} | {:error, [Error.t()]}
  def elements(inputs) when is_list(inputs) do
    Enum.reduce_while(inputs, {:ok, []}, fn input, {:ok, acc} ->
      case element(input) do
        {:ok, normalized} -> {:cont, {:ok, acc ++ [normalized]}}
        {:error, errors} -> {:halt, {:error, errors}}
      end
    end)
  end

  @spec fixture(Element.t() | map() | keyword()) :: {:ok, Element.t()} | {:error, [Error.t()]}
  def fixture(input), do: element(input)

  @spec fixture!(Element.t() | map() | keyword()) :: Element.t()
  def fixture!(input), do: element!(input)

  defp do_normalize_element(%Element{} = element) do
    children_result =
      element.children
      |> Enum.map(&normalize_child/1)
      |> collect_results()

    with {:ok, children} <- children_result do
      {:ok,
       Element.new(element.type, element.kind,
         id: element.id,
         metadata: Metadata.new(element.metadata),
         attributes: canonicalize_attributes(element.attributes, element.kind),
         children: children
       )}
    end
  end

  defp do_normalize_element(input) when is_list(input) do
    input
    |> Enum.into(%{})
    |> do_normalize_element()
  end

  defp do_normalize_element(input) when is_map(input) do
    input = Map.new(input)
    type = fetch(input, :type)
    kind = fetch(input, :kind)

    cond do
      is_nil(type) ->
        {:error, [Error.new(:missing_type, "canonical element input is missing :type")]}

      is_nil(kind) ->
        {:error, [Error.new(:missing_kind, "canonical element input is missing :kind")]}

      true ->
        children_result =
          input
          |> fetch(:children, [])
          |> List.wrap()
          |> Enum.map(&normalize_child/1)
          |> collect_results()

        with {:ok, children} <- children_result do
          {:ok,
           Element.new(type, kind,
             id: fetch(input, :id),
             metadata: Metadata.new(fetch(input, :metadata)),
             attributes: input |> extract_attributes() |> canonicalize_attributes(kind),
             children: children
           )}
        end
    end
  end

  defp do_normalize_element(other) do
    {:error,
     [
       Error.new(
         :invalid_element_input,
         "canonical element input must be an element struct, map, or keyword list",
         details: %{value: inspect(other)}
       )
     ]}
  end

  defp normalize_child(%Child{} = child) do
    case child.element do
      nil -> {:ok, Child.new(child.slot, nil)}
      element -> do_normalize_element(element) |> map_child_result(child.slot)
    end
  end

  defp normalize_child({slot, nil}) when is_atom(slot) or is_binary(slot) do
    {:ok, Child.new(slot, nil)}
  end

  defp normalize_child({slot, element}) when is_atom(slot) or is_binary(slot) do
    do_normalize_element(element) |> map_child_result(slot)
  end

  defp normalize_child(%{"slot" => slot, "element" => element})
       when is_atom(slot) or is_binary(slot) do
    normalize_child(%{slot: slot, element: element})
  end

  defp normalize_child(%{slot: slot, element: element}) when is_atom(slot) or is_binary(slot) do
    case element do
      nil -> {:ok, Child.new(slot, nil)}
      value -> do_normalize_element(value) |> map_child_result(slot)
    end
  end

  defp normalize_child(%Element{} = element) do
    do_normalize_element(element) |> map_child_result(:default)
  end

  defp normalize_child(element) when is_map(element) or is_list(element) do
    do_normalize_element(element) |> map_child_result(:default)
  end

  defp normalize_child(other) do
    {:error,
     [
       Error.new(
         :invalid_child,
         "canonical child input must be an element, child wrapper, or slot tuple",
         details: %{value: inspect(other)}
       )
     ]}
  end

  defp canonicalize_attributes(attributes, kind) do
    raw_attributes = normalize_generic_map(attributes)
    attachment_source = Map.new(raw_attributes)

    base_attributes =
      raw_attributes
      |> Map.drop(@attachment_keys ++ string_keys(@attachment_keys))
      |> compact_map()

    base_attributes
    |> Attachment.merge(attachment_source,
      component: kind,
      local_style: fetch(attachment_source, :style)
    )
    |> compact_map()
  end

  defp extract_attributes(input) do
    embedded =
      input
      |> fetch(:attributes, %{})
      |> normalize_generic_map()

    lifted =
      input
      |> Map.drop(@reserved_element_keys ++ string_keys(@reserved_element_keys))
      |> normalize_generic_map()

    Map.merge(embedded, lifted)
  end

  defp normalize_generic_value(%Element{} = element), do: element!(element)
  defp normalize_generic_value(%Metadata{} = metadata), do: Metadata.new(metadata)
  defp normalize_generic_value(%Style{} = style), do: Style.new(style)
  defp normalize_generic_value(%Interaction{} = interaction), do: Interaction.new(interaction)
  defp normalize_generic_value(%Binding{} = binding), do: Binding.new(binding)
  defp normalize_generic_value(%_{} = struct), do: struct
  defp normalize_generic_value(list) when is_list(list), do: normalize_generic_list(list)
  defp normalize_generic_value(map) when is_map(map), do: normalize_generic_map(map)
  defp normalize_generic_value(value), do: value

  defp normalize_generic_list([]), do: []

  defp normalize_generic_list(list) do
    if Keyword.keyword?(list) do
      list
      |> Enum.into(%{})
      |> normalize_generic_map()
    else
      Enum.map(list, &normalize_generic_value/1)
    end
  end

  defp normalize_generic_map(map) when is_map(map) do
    map
    |> Map.new(fn {key, value} -> {normalize_key(key), normalize_generic_value(value)} end)
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> empty_value?(value) end)
    |> Enum.map(fn {key, value} -> {key, compact_value(value)} end)
    |> Enum.reject(fn {_key, value} -> empty_value?(value) end)
    |> Map.new()
  end

  defp compact_value(%Element{} = element), do: element
  defp compact_value(%Child{} = child), do: child
  defp compact_value(%Style{} = style), do: style
  defp compact_value(%Metadata{} = metadata), do: metadata
  defp compact_value(%Interaction{} = interaction), do: interaction
  defp compact_value(%Binding{} = binding), do: binding
  defp compact_value(%_{} = struct), do: struct
  defp compact_value(list) when is_list(list), do: Enum.map(list, &compact_value/1)
  defp compact_value(map) when is_map(map), do: compact_map(map)
  defp compact_value(value), do: value

  defp empty_value?(nil), do: true
  defp empty_value?(%_{}), do: false
  defp empty_value?(%{} = value), do: map_size(value) == 0
  defp empty_value?([]), do: true
  defp empty_value?(_value), do: false

  defp collect_results(results) do
    Enum.reduce_while(results, {:ok, []}, fn
      {:ok, value}, {:ok, acc} -> {:cont, {:ok, acc ++ [value]}}
      {:error, errors}, _acc -> {:halt, {:error, errors}}
    end)
  end

  defp map_child_result({:ok, element}, slot), do: {:ok, Child.new(slot, element)}
  defp map_child_result({:error, errors}, _slot), do: {:error, errors}

  defp fetch(source, key, default \\ nil) do
    Map.get(source, key, Map.get(source, Atom.to_string(key), default))
  end

  defp normalize_key(key) when is_binary(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> key
    end
  end

  defp normalize_key(key), do: key

  defp string_keys(keys), do: Enum.map(keys, &Atom.to_string/1)
end
