defmodule AshUI.LiveView.IURHydration do
  @moduledoc """
  Applies runtime binding values back onto canonical IUR widgets.

  This keeps the rendered widget tree in sync with the latest evaluated binding
  state so LiveUI rendering can work directly from stored `unified_dsl`.
  """

  alias AshUI.LiveView.BindingRuntime
  alias AshUI.Rendering.CanonicalIUR

  @type canonical_iur :: map()
  @type binding_state :: map()

  @doc """
  Returns a canonical IUR tree with binding values applied back onto widget
  props, keyed by `element_id` and binding target.
  """
  @spec hydrate(canonical_iur(), map() | [binding_state()]) :: canonical_iur()
  def hydrate(%UnifiedIUR.Element{} = iur, bindings) do
    iur
    |> CanonicalIUR.to_legacy_map()
    |> hydrate(bindings)
  end

  def hydrate(%{"type" => "screen"} = iur, bindings) do
    binding_states =
      bindings
      |> normalize_bindings()
      |> Enum.reject(&BindingRuntime.action_binding?/1)
      |> Enum.filter(&(BindingRuntime.owner_scope(&1) == :element))

    Map.update(iur, "children", [], fn children ->
      Enum.map(children, &hydrate_node(&1, binding_states))
    end)
  end

  def hydrate(iur, _bindings), do: iur

  defp hydrate_node(%{"id" => element_id} = node, binding_states) do
    props = Map.get(node, "props", %{})

    hydrated_props =
      binding_states
      |> Enum.filter(&(binding_element_id(&1) == element_id))
      |> Enum.reduce(props, fn binding_state, acc ->
        apply_binding(acc, node, binding_state)
      end)

    node
    |> Map.put("props", hydrated_props)
    |> Map.update("children", [], fn children ->
      Enum.map(children, &hydrate_node(&1, binding_states))
    end)
  end

  defp hydrate_node(node, binding_states) when is_map(node) do
    Map.update(node, "children", [], fn children ->
      Enum.map(children, &hydrate_node(&1, binding_states))
    end)
  end

  defp apply_binding(props, node, binding_state) do
    target = binding_target(binding_state)
    value = binding_value(binding_state)
    widget_type = Map.get(node, "type")
    binding_type = binding_type(binding_state)
    node_id = Map.get(node, "id")
    name = Map.get(props, "name")

    cond do
      is_nil(target) ->
        props

      binding_type == :list and widget_type in ["list", "table"] ->
        hydrate_collection_props(props, value)

      input_like_widget?(widget_type) and target in [name, node_id] ->
        Map.put(props, input_value_key(widget_type), value)

      input_like_widget?(widget_type) and binding_type == :value ->
        Map.put(props, input_value_key(widget_type), value)

      target_path(target) != [] ->
        put_nested_prop(props, target_path(target), value)

      true ->
        Map.put(props, target, value)
    end
  end

  defp normalize_bindings(bindings) when is_map(bindings) do
    bindings
    |> Enum.map(fn {_id, binding_state} -> binding_state end)
    |> Enum.filter(&is_map/1)
  end

  defp normalize_bindings(bindings) when is_list(bindings) do
    Enum.filter(bindings, &is_map/1)
  end

  defp normalize_bindings(_other), do: []

  defp binding_element_id(binding_state) do
    Map.get(binding_state, :element_id) || Map.get(binding_state, "element_id")
  end

  defp binding_target(binding_state) do
    Map.get(binding_state, :target) || Map.get(binding_state, "target")
  end

  defp binding_value(binding_state) do
    Map.get_lazy(binding_state, :value, fn -> Map.get(binding_state, "value") end)
  end

  defp binding_type(binding_state) do
    case Map.get(binding_state, :binding_type) || Map.get(binding_state, "binding_type") do
      value when value in [:list, "list", "collection"] -> :list
      value when value in [:action, "action", "event"] -> :action
      _ -> :value
    end
  end

  defp hydrate_collection_props(props, value) when is_map(value) do
    items = Map.get(value, :items) || Map.get(value, "items", [])

    props
    |> Map.put("items", items)
    |> Map.put("collection", stringify_map_keys(value))
  end

  defp hydrate_collection_props(props, value) when is_list(value) do
    Map.put(props, "items", value)
  end

  defp hydrate_collection_props(props, value), do: Map.put(props, "items", value)

  defp target_path(target) when is_list(target), do: target

  defp target_path(target) when is_binary(target) do
    case String.split(target, ".", trim: true) do
      [] -> []
      parts -> parts
    end
  end

  defp target_path(target) when is_atom(target), do: [Atom.to_string(target)]
  defp target_path(_target), do: []

  defp put_nested_prop(_props, [], value), do: value

  defp put_nested_prop(props, [segment], value) do
    Map.put(props, to_string(segment), value)
  end

  defp put_nested_prop(props, [segment | rest], value) do
    key = to_string(segment)
    nested = Map.get(props, key, %{})
    Map.put(props, key, put_nested_prop(stringify_map_keys(nested), rest, value))
  end

  defp stringify_map_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      {
        to_string(key),
        if(is_map(value), do: stringify_map_keys(value), else: value)
      }
    end)
  end

  defp stringify_map_keys(other), do: other

  defp input_like_widget?(widget_type) do
    widget_type in ["input", "textarea", "select", "slider", "radio", "checkbox", "switch"]
  end

  defp input_value_key(widget_type) when widget_type in ["checkbox", "switch"], do: "checked"
  defp input_value_key(_widget_type), do: "value"
end
