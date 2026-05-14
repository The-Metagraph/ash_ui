defmodule AshUI.Rendering.CanonicalIUR do
  @moduledoc """
  Helpers for working with the upgraded canonical Unified IUR boundary.

  Ash UI now emits `%UnifiedIUR.Element{}` roots for renderer-facing output.
  This module keeps runtime adapters focused on dispatch while still allowing
  older in-repo fallback renderers to read a legacy map projection.
  """

  alias UnifiedIUR.{Binding, Element, Interaction, Metadata}
  alias UnifiedIUR.Element.Child

  @type interaction_entry :: %{
          interaction: Interaction.t(),
          element_id: term(),
          element: Element.t(),
          path: [term()]
        }

  @doc """
  Returns true when the value is a canonical Unified IUR element.
  """
  @spec canonical?(term()) :: boolean()
  def canonical?(%Element{}), do: true
  def canonical?(_value), do: false

  @doc """
  Returns a stable root id from either canonical structs or legacy maps.
  """
  @spec id(Element.t() | map()) :: term()
  def id(%Element{id: id}), do: id
  def id(map) when is_map(map), do: Map.get(map, "id") || Map.get(map, :id)

  @doc """
  Returns a stable root type/kind from either canonical structs or legacy maps.
  """
  @spec type(Element.t() | map()) :: term()
  def type(%Element{kind: kind}), do: kind
  def type(map) when is_map(map), do: Map.get(map, "type") || Map.get(map, :type)

  @doc """
  Projects a canonical element into the older string-keyed shape used by the
  in-repo fallback renderers.
  """
  @spec to_legacy_map(Element.t() | map()) :: map()
  def to_legacy_map(%Element{kind: :screen} = element) do
    screen = attr(element, :screen, %{})

    %{
      "id" => element.id,
      "type" => "screen",
      "name" => value(screen, :name) || element.id,
      "layout" => value(screen, :layout),
      "version" => value(screen, :version),
      "metadata" => metadata_to_map(element.metadata),
      "bindings" => encoded_attr(element, :bindings, []),
      "interactions" => encoded_attr(element, :interactions, []),
      "children" => legacy_children(element)
    }
    |> compact_string_map()
  end

  def to_legacy_map(%Element{} = element) do
    %{
      "id" => element.id,
      "type" => to_string(element.kind),
      "kind" => element.kind,
      "metadata" => metadata_to_map(element.metadata),
      "props" => legacy_props(element),
      "bindings" => encoded_attr(element, :bindings, []),
      "interactions" => encoded_attr(element, :interactions, []),
      "children" => legacy_children(element)
    }
    |> compact_string_map()
  end

  def to_legacy_map(map) when is_map(map), do: map

  @doc """
  Returns every canonical interaction with element context.
  """
  @spec interaction_entries(Element.t() | map()) :: [interaction_entry()]
  def interaction_entries(%Element{} = element) do
    collect_interactions(element, [])
  end

  def interaction_entries(_value), do: []

  @doc """
  Returns canonical navigation interactions from a root element.
  """
  @spec navigation_interactions(Element.t() | map()) :: [Interaction.t()]
  def navigation_interactions(root) do
    root
    |> interaction_entries()
    |> Enum.map(& &1.interaction)
    |> Enum.filter(&navigation_interaction?/1)
  end

  @doc """
  Returns true when an interaction carries canonical navigation intent.
  """
  @spec navigation_interaction?(Interaction.t() | map()) :: boolean()
  def navigation_interaction?(%Interaction{} = interaction) do
    interaction.family == :navigation or
      not is_nil(Interaction.navigation_descriptor(interaction))
  end

  def navigation_interaction?(interaction) when is_map(interaction) do
    interaction
    |> Interaction.new()
    |> navigation_interaction?()
  end

  def navigation_interaction?(_interaction), do: false

  @doc """
  Returns Ash UI runtime binding maps preserved inside canonical bindings.
  """
  @spec ash_bindings(Element.t() | map()) :: [map()]
  def ash_bindings(%Element{} = element) do
    element
    |> attr(:bindings, [])
    |> List.wrap()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&ash_binding/1)
  end

  def ash_bindings(map) when is_map(map), do: Map.get(map, "bindings", [])
  def ash_bindings(_value), do: []

  defp collect_interactions(%Element{} = element, path) do
    own =
      element
      |> attr(:interactions, [])
      |> List.wrap()
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn interaction ->
        %{
          interaction: Interaction.new(interaction),
          element_id: element.id,
          element: element,
          path: path
        }
      end)

    child_entries =
      element.children
      |> Enum.with_index()
      |> Enum.flat_map(fn
        {%Child{slot: slot, element: %Element{} = child}, index} ->
          collect_interactions(child, path ++ [slot, index])

        _other ->
          []
      end)

    own ++ child_entries
  end

  defp legacy_children(%Element{} = element) do
    Enum.map(element.children, fn
      %Child{slot: slot, element: %Element{} = child} ->
        child
        |> to_legacy_map()
        |> Map.put("slot", slot)
        |> put_legacy_slot_metadata(slot)

      %Child{slot: slot} ->
        %{"slot" => slot, "type" => "empty", "children" => []}
        |> put_legacy_slot_metadata(slot)
    end)
  end

  defp legacy_props(%Element{} = element) do
    attributes = element.attributes

    attributes
    |> Map.drop([:bindings, :interactions, :style, :theme, :style_refs, :token_refs])
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      merge_legacy_prop(acc, key, value)
    end)
    |> Map.merge(common_legacy_props(attributes))
    |> stringify_keys()
  end

  defp merge_legacy_prop(acc, :content, value) do
    text = value(value, :text) || value(value, :label)

    acc
    |> maybe_put(:content, text)
    |> maybe_put(:label, text)
  end

  defp merge_legacy_prop(acc, :component, value),
    do: Map.put(acc, :component, normalize_map(value))

  defp merge_legacy_prop(acc, key, value) when key in [:icon, :image, :link],
    do: Map.merge(acc, normalize_map(value))

  defp merge_legacy_prop(acc, :layout, value), do: Map.merge(acc, normalize_map(value))
  defp merge_legacy_prop(acc, :button, value), do: Map.merge(acc, normalize_map(value))
  defp merge_legacy_prop(acc, :input, value), do: Map.merge(acc, normalize_map(value))
  defp merge_legacy_prop(acc, :state, value), do: Map.merge(acc, normalize_map(value))
  defp merge_legacy_prop(acc, :selection, value), do: Map.merge(acc, normalize_map(value))
  defp merge_legacy_prop(acc, :navigation, value), do: Map.merge(acc, normalize_map(value))

  defp merge_legacy_prop(acc, key, value)
       when key in [
              :heading,
              :disclosure,
              :kicker,
              :identity,
              :presence,
              :form,
              :composer,
              :row,
              :artifact,
              :workflow,
              :progress,
              :meter,
              :shell,
              :panel,
              :callout,
              :redline,
              :code,
              :repeat,
              :accessibility,
              :text_safety
            ] do
    Map.merge(acc, normalize_map(value))
  end

  defp merge_legacy_prop(acc, key, value), do: Map.put(acc, key, value)

  defp put_legacy_slot_metadata(child, slot) do
    Map.update(child, "metadata", %{"slot" => to_string(slot)}, fn metadata ->
      metadata
      |> normalize_map()
      |> Map.put_new("slot", to_string(slot))
    end)
  end

  defp common_legacy_props(attributes) do
    style = value(attributes, :style)

    %{}
    |> maybe_put(:class, style_extra(style, :class) || nested_attr_value(attributes, :class))
    |> maybe_put(:style, encode_value(style))
    |> maybe_put(
      :inline_style,
      style_extra(style, :css) || nested_attr_value(attributes, :inline_style)
    )
  end

  defp nested_attr_value(attributes, key) do
    string_key = to_string(key)

    Enum.find_value(attributes, fn
      {_attr_key, value} when is_map(value) -> value(value, key)
      {attr_key, value} -> if attr_key == key or attr_key == string_key, do: value
      _entry -> nil
    end)
  end

  defp style_extra(style, key) do
    style
    |> value(:extra)
    |> value(key)
  end

  defp encoded_attr(%Element{} = element, key, default) do
    element
    |> attr(key, default)
    |> List.wrap()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&encode_value/1)
  end

  defp ash_binding(%Binding{} = binding) do
    metadata = normalize_map(binding.metadata)

    preserved =
      metadata
      |> Map.drop([:ash_ui_source, :ash_ui_transform])
      |> Map.drop(["ash_ui_source", "ash_ui_transform"])

    if has_runtime_binding_shape?(preserved) do
      preserved
    else
      fallback_binding(binding)
    end
  end

  defp ash_binding(binding) when is_map(binding), do: binding

  defp ash_binding(binding) do
    %{"id" => inspect(binding), "binding_type" => :value, "metadata" => %{}}
  end

  defp fallback_binding(%Binding{} = binding) do
    %{
      "id" => binding.name,
      "target" => Enum.join(binding.path || [], "."),
      "binding_type" => runtime_binding_type(binding.source),
      "source" => value(binding.metadata, :ash_ui_source) || %{},
      "transform" => value(binding.metadata, :ash_ui_transform) || %{},
      "metadata" => normalize_map(binding.metadata)
    }
  end

  defp runtime_binding_type(:event), do: :action
  defp runtime_binding_type(:collection), do: :list
  defp runtime_binding_type(:bidirectional), do: :value
  defp runtime_binding_type(other), do: other

  defp has_runtime_binding_shape?(binding) do
    not is_nil(value(binding, :id)) and
      (not is_nil(value(binding, :target)) or not is_nil(value(binding, :source)))
  end

  defp encode_value(%Interaction{} = interaction) do
    %{
      family: interaction.family,
      intent: interaction.intent,
      source: encode_value(interaction.source),
      target: encode_value(interaction.target),
      payload: encode_value(interaction.payload),
      metadata: encode_value(interaction.metadata)
    }
  end

  defp encode_value(%Binding{} = binding), do: binding |> Map.from_struct() |> encode_value()
  defp encode_value(%Metadata{} = metadata), do: metadata_to_map(metadata)

  defp encode_value(%_struct{} = value) do
    value
    |> Map.from_struct()
    |> encode_value()
  end

  defp encode_value(value) when is_map(value) do
    Map.new(value, fn {key, value} -> {key, encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values), do: Enum.map(values, &encode_value/1)
  defp encode_value(value), do: value

  defp metadata_to_map(%Metadata{} = metadata) do
    %{
      authored_ref: metadata.authored_ref,
      annotations: metadata.annotations,
      tags: metadata.tags,
      extra: metadata.extra
    }
    |> compact_atom_map()
  end

  defp metadata_to_map(value) when is_map(value), do: value
  defp metadata_to_map(_value), do: %{}

  defp attr(%Element{} = element, key, default) do
    value(element.attributes, key) || default
  end

  defp value(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, to_string(key))
  defp value(_value, _key), do: nil

  defp normalize_map(value) when is_map(value), do: value
  defp normalize_map(value) when is_list(value), do: Enum.into(value, %{})
  defp normalize_map(_value), do: %{}

  defp stringify_keys(map) do
    Map.new(map, fn {key, value} -> {to_string(key), encode_value(value)} end)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp compact_string_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, [], %{}] end)
    |> Map.new()
  end

  defp compact_atom_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, [], %{}] end)
    |> Map.new()
  end
end
