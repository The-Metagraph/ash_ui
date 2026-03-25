defmodule UnifiedIUR.Reference do
  @moduledoc """
  Package-facing reference helpers for the canonical module areas exposed by
  `UnifiedIUR`.
  """

  alias UnifiedIUR.{Binding, Element, Interaction, Metadata, Normalize, Style}
  alias UnifiedIUR.Tree

  @spec module_areas() :: %{UnifiedIUR.module_area() => module()}
  def module_areas do
    UnifiedIUR.module_areas()
  end

  @spec construct_families() :: [Element.element_type()]
  def construct_families do
    UnifiedIUR.Core.element_types()
  end

  @spec public_type_categories() :: [atom()]
  def public_type_categories do
    [:element, :metadata, :child, :tree, :summary, :snapshot, :diff, :invariant]
  end

  @spec identity_metadata_shape() :: map()
  def identity_metadata_shape do
    %{
      identity_fields: [:id, :type, :kind],
      metadata_fields: [:authored_ref, :description, :annotations, :tags, :extra]
    }
  end

  @spec tree_shape_conventions() :: map()
  def tree_shape_conventions do
    %{
      child_shapes: [:leaf, :single, :multi],
      child_wrapper: UnifiedIUR.Element.Child,
      empty_child_representation: %{slot: :default, element: nil}
    }
  end

  @spec summarize_element(Element.t()) :: map()
  def summarize_element(%Element{} = element) do
    %{
      id: element.id,
      type: element.type,
      kind: element.kind,
      child_shape: Element.child_shape(element),
      child_slots: Enum.map(element.children, & &1.slot),
      metadata: %{
        description: element.metadata.description,
        tags: element.metadata.tags,
        annotation_keys: Map.keys(element.metadata.annotations)
      }
    }
  end

  @spec summarize_tree(Element.t()) :: map()
  def summarize_tree(%Element{} = root) do
    nodes = Tree.depth_first(root)

    %{
      total_elements: length(nodes),
      element_ids: Enum.map(nodes, & &1.id),
      type_histogram: Enum.frequencies_by(nodes, & &1.type),
      shape_signature: Tree.shape_signature(root)
    }
  end

  @spec snapshot(Element.t() | map() | keyword()) :: keyword()
  def snapshot(input) do
    input
    |> Normalize.element!()
    |> snapshot_value()
  end

  @spec equivalent?(Element.t() | map() | keyword(), Element.t() | map() | keyword()) :: boolean()
  def equivalent?(left, right) do
    snapshot(left) == snapshot(right)
  end

  @spec shape_diff(Element.t() | map() | keyword(), Element.t() | map() | keyword()) :: [map()]
  def shape_diff(left, right) do
    diff_values(snapshot(left), snapshot(right), [])
  end

  defp snapshot_value(%Element{} = element) do
    [
      id: element.id,
      type: element.type,
      kind: element.kind,
      metadata: snapshot_value(element.metadata),
      attributes: snapshot_attributes(element.attributes),
      children: Enum.map(element.children, &snapshot_value/1)
    ]
  end

  defp snapshot_value(%UnifiedIUR.Element.Child{} = child) do
    [
      slot: child.slot,
      element: if(is_nil(child.element), do: nil, else: snapshot_value(child.element))
    ]
  end

  defp snapshot_value(%Metadata{} = metadata) do
    [
      authored_ref: metadata.authored_ref,
      description: metadata.description,
      annotations: snapshot_map(metadata.annotations),
      tags: metadata.tags,
      extra: snapshot_map(metadata.extra)
    ]
  end

  defp snapshot_value(%Style{} = style) do
    [
      foreground: style.foreground,
      background: style.background,
      border_color: style.border_color,
      text: snapshot_map(Map.from_struct(style.text)),
      spacing: snapshot_map(style.spacing),
      sizing: snapshot_map(style.sizing),
      alignment: snapshot_map(style.alignment),
      visibility: snapshot_map(style.visibility),
      border: snapshot_map(style.border),
      emphasis: snapshot_map(style.emphasis),
      state_variants: snapshot_map(style.state_variants),
      extra: snapshot_map(style.extra)
    ]
  end

  defp snapshot_value(%Interaction{} = interaction) do
    [
      family: interaction.family,
      intent: interaction.intent,
      source: snapshot_map(interaction.source),
      target: snapshot_map(interaction.target),
      payload: snapshot_map(interaction.payload),
      metadata: snapshot_map(interaction.metadata)
    ]
  end

  defp snapshot_value(%Binding{} = binding) do
    [
      name: binding.name,
      path: binding.path,
      scope: binding.scope,
      value: binding.value,
      default: binding.default,
      format: binding.format,
      source: binding.source,
      collection?: binding.collection?,
      depends_on: Enum.map(sort_bindings(binding.depends_on), &snapshot_value/1),
      derived: snapshot_map(binding.derived),
      metadata: snapshot_map(binding.metadata)
    ]
  end

  defp snapshot_value(map) when is_map(map), do: snapshot_map(map)

  defp snapshot_value(list) when is_list(list) do
    if Keyword.keyword?(list) do
      list
      |> Enum.into(%{})
      |> snapshot_map()
    else
      Enum.map(list, &snapshot_value/1)
    end
  end

  defp snapshot_value(value), do: value

  defp snapshot_attributes(attributes) do
    attributes
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
    |> Enum.map(fn
      {:bindings, bindings} ->
        {:bindings, Enum.map(sort_bindings(bindings), &snapshot_value/1)}

      {:interactions, interactions} ->
        {:interactions, Enum.map(sort_interactions(interactions), &snapshot_value/1)}

      {:theme, theme} ->
        {:theme, snapshot_map(theme)}

      {key, value} ->
        {key, snapshot_value(value)}
    end)
  end

  defp snapshot_map(map) do
    map
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
    |> Enum.map(fn
      {:bindings, bindings} ->
        {:bindings, Enum.map(sort_bindings(bindings), &snapshot_value/1)}

      {:interactions, interactions} ->
        {:interactions, Enum.map(sort_interactions(interactions), &snapshot_value/1)}

      {:token_refs, refs} ->
        {:token_refs, Enum.map(sort_token_refs(refs), &snapshot_value/1)}

      {key, value} ->
        {key, snapshot_value(value)}
    end)
  end

  defp sort_bindings(bindings) do
    Enum.sort_by(bindings, fn binding ->
      binding = Binding.new(binding)

      {Enum.join(Enum.map(binding.scope, &to_string/1), "."),
       Enum.join(Enum.map(binding.path, &to_string/1), "."), to_string(binding.name || "")}
    end)
  end

  defp sort_interactions(interactions) do
    Enum.sort_by(interactions, fn interaction ->
      interaction = Interaction.new(interaction)

      {
        interaction.family,
        to_string(interaction.intent || ""),
        inspect(interaction.source),
        inspect(interaction.target)
      }
    end)
  end

  defp sort_token_refs(refs) do
    Enum.sort_by(refs, fn ref ->
      ref
      |> Map.get(:path, Map.get(ref, "path", []))
      |> Enum.map_join(".", &to_string/1)
    end)
  end

  defp diff_values(left, right, _path) when left == right, do: []

  defp diff_values(left, right, path) when is_list(left) and is_list(right) do
    cond do
      Keyword.keyword?(left) and Keyword.keyword?(right) ->
        keys =
          left
          |> Keyword.keys()
          |> Kernel.++(Keyword.keys(right))
          |> Enum.uniq()

        Enum.flat_map(keys, fn key ->
          diff_values(Keyword.get(left, key), Keyword.get(right, key), path ++ [key])
        end)

      length(left) == length(right) ->
        left
        |> Enum.zip(right)
        |> Enum.with_index()
        |> Enum.flat_map(fn {{left_value, right_value}, index} ->
          diff_values(left_value, right_value, path ++ [index])
        end)

      true ->
        [%{path: path, left: left, right: right}]
    end
  end

  defp diff_values(left, right, path) do
    [%{path: path, left: left, right: right}]
  end
end
