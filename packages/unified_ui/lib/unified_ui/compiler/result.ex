defmodule UnifiedUi.Compiler.Result do
  @moduledoc """
  Canonical compiler result for one authored `UnifiedUi` module.
  """

  alias UnifiedIUR.{Binding, Element, Interaction, Theme}
  alias UnifiedIUR.Tree
  alias UnifiedUi.Info

  @type t :: %__MODULE__{
          module: module(),
          identity: map(),
          composition: map(),
          iur: Element.t(),
          themes: [Theme.t()],
          default_theme: atom() | String.t() | nil,
          bindings: [Binding.t()],
          interactions: [Interaction.t()],
          trace: map()
        }

  defstruct module: nil,
            identity: %{},
            composition: %{},
            iur: nil,
            themes: [],
            default_theme: nil,
            bindings: [],
            interactions: [],
            trace: %{}

  @spec summary(t()) :: map()
  def summary(%__MODULE__{} = result) do
    %{
      module: result.module,
      identity_id: result.identity.id,
      authored_ref: result.identity.authored_ref,
      root_id: result.composition.root,
      mode: result.composition.mode,
      default_theme: result.default_theme,
      top_level_children: Enum.map(result.iur.children, &child_summary/1),
      theme_ids: Enum.map(result.themes, & &1.id),
      binding_names: Enum.map(result.bindings, & &1.name),
      interaction_families: Enum.map(result.interactions, & &1.family),
      interaction_intents: Enum.map(result.interactions, & &1.intent),
      trace: trace_summary(result.trace)
    }
  end

  @spec listing(t()) :: map()
  def listing(%__MODULE__{} = result) do
    elements = Tree.depth_first(result.iur)
    authored_nodes = result.module |> Info.composition_nodes() |> flatten_authored_nodes()

    %{
      module: result.module,
      authored: %{
        identity_id: result.identity.id,
        authored_ref: result.identity.authored_ref,
        authored_ids: sort_terms(Map.get(result.trace, :authored_ids, [])),
        style_ref_ids: authored_style_ref_ids(authored_nodes),
        themed_node_ids: authored_themed_node_ids(authored_nodes)
      },
      compiled: %{
        element_types: elements |> Enum.map(& &1.type) |> sort_terms(),
        widget_kinds: elements |> filter_kinds(:widget) |> sort_terms(),
        layout_kinds: elements |> filter_kinds(:layout) |> sort_terms(),
        composite_kinds: elements |> filter_kinds(:composite) |> sort_terms(),
        layer_kinds: elements |> filter_kinds(:layer) |> sort_terms(),
        display_systems: display_system_usage(elements)
      },
      themes: %{
        default_theme: result.default_theme,
        theme_ids: result.themes |> Enum.map(& &1.id) |> sort_terms(),
        style_ref_ids: authored_style_ref_ids(authored_nodes),
        themed_element_ids: authored_themed_node_ids(authored_nodes)
      },
      bindings: %{
        names: result.bindings |> Enum.map(& &1.name) |> sort_terms(),
        paths: result.bindings |> Enum.map(& &1.path) |> Enum.uniq() |> Enum.sort(),
        scopes: result.bindings |> Enum.map(& &1.scope) |> Enum.uniq() |> Enum.sort()
      },
      signals: %{
        ids: result.trace |> Map.get(:interaction_by_id, %{}) |> Map.keys() |> sort_terms(),
        families: result.interactions |> Enum.map(& &1.family) |> sort_terms(),
        intents:
          result.interactions
          |> Enum.map(& &1.intent)
          |> Enum.reject(&is_nil/1)
          |> sort_terms(),
        source_element_ids:
          result.interactions
          |> Enum.map(&get_in(&1.source, [:element_id]))
          |> Enum.reject(&is_nil/1)
          |> sort_terms(),
        target_bindings:
          result.interactions
          |> Enum.map(&binding_target_id/1)
          |> Enum.reject(&is_nil/1)
          |> sort_terms()
      },
      trace: trace_listing(result, elements)
    }
  end

  defp child_summary(child) do
    case child.element do
      nil ->
        %{slot: child.slot, id: nil, type: nil, kind: nil}

      element ->
        %{slot: child.slot, id: element.id, type: element.type, kind: element.kind}
    end
  end

  defp trace_summary(trace) do
    %{
      authored_ids: Map.get(trace, :authored_ids, []),
      binding_ids: trace |> Map.get(:binding_by_id, %{}) |> Map.keys() |> Enum.sort(),
      interaction_ids: trace |> Map.get(:interaction_by_id, %{}) |> Map.keys() |> Enum.sort(),
      theme_ids: trace |> Map.get(:theme_by_id, %{}) |> Map.keys() |> Enum.sort()
    }
  end

  defp filter_kinds(elements, type) do
    elements
    |> Enum.filter(&(&1.type == type))
    |> Enum.map(& &1.kind)
  end

  defp display_system_usage(elements) do
    layer_kinds = sort_terms(filter_kinds(elements, :layer))

    viewport_kinds =
      elements
      |> Enum.map(& &1.kind)
      |> Enum.filter(&(&1 in [:viewport, :scroll_bar, :split_pane]))
      |> sort_terms()

    canvas_kinds =
      elements
      |> Enum.map(& &1.kind)
      |> Enum.filter(&(&1 in [:canvas, :sparkline, :bar_chart, :line_chart]))
      |> sort_terms()

    %{
      layer_kinds: layer_kinds,
      viewport_kinds: viewport_kinds,
      canvas_kinds: canvas_kinds,
      layered?: layer_kinds != [],
      viewport?: viewport_kinds != [],
      canvas?: canvas_kinds != []
    }
  end

  defp authored_style_ref_ids(nodes) do
    nodes
    |> Enum.flat_map(&(Map.get(&1, :style_refs, []) |> List.wrap()))
    |> sort_terms()
  end

  defp authored_themed_node_ids(nodes) do
    nodes
    |> Enum.filter(&(not is_nil(Map.get(&1, :theme_ref))))
    |> Enum.map(& &1.id)
    |> sort_terms()
  end

  defp binding_target_id(interaction) do
    case get_in(interaction.target, [:binding]) do
      %{id: id} -> id
      %{"id" => id} -> id
      value when is_atom(value) or is_binary(value) -> value
      _other -> nil
    end
  end

  defp trace_listing(result, elements) do
    authored_ids = sort_terms(Map.get(result.trace, :authored_ids, []))
    compiled_element_ids = elements |> Enum.map(& &1.id) |> sort_terms()

    %{
      authored_ids: authored_ids,
      compiled_element_ids: compiled_element_ids,
      authored_to_compiled:
        elements
        |> Enum.filter(&(&1.id in authored_ids))
        |> Enum.map(fn element ->
          %{
            authored_id: element.id,
            compiled_id: element.id,
            type: element.type,
            kind: element.kind
          }
        end)
        |> Enum.sort_by(fn trace -> {to_string(trace.authored_id), to_string(trace.kind)} end),
      binding_ids: result.trace |> Map.get(:binding_by_id, %{}) |> Map.keys() |> sort_terms(),
      interaction_ids:
        result.trace |> Map.get(:interaction_by_id, %{}) |> Map.keys() |> sort_terms(),
      theme_ids: result.trace |> Map.get(:theme_by_id, %{}) |> Map.keys() |> sort_terms()
    }
  end

  defp sort_terms(values) do
    values
    |> Enum.uniq()
    |> Enum.sort_by(&to_string/1)
  end

  defp flatten_authored_nodes(nodes) do
    Enum.flat_map(nodes, fn node ->
      [node | flatten_authored_nodes(Map.get(node, :children, []))]
    end)
  end
end
