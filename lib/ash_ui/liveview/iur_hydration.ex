defmodule AshUI.LiveView.IURHydration do
  @moduledoc """
  Applies runtime binding values back onto canonical IUR widgets.

  This keeps the rendered widget tree in sync with the latest evaluated binding
  state so LiveUI rendering can work directly from stored `unified_dsl`.
  """

  @type canonical_iur :: map()
  @type binding_state :: map()

  @doc """
  Returns a canonical IUR tree with binding values applied back onto widget
  props, keyed by `element_id` and binding target.
  """
  @spec hydrate(canonical_iur(), map() | [binding_state()]) :: canonical_iur()
  def hydrate(%{"type" => "screen"} = iur, bindings) do
    binding_states = normalize_bindings(bindings)

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
    name = Map.get(props, "name")

    cond do
      is_nil(target) ->
        props

      Map.has_key?(props, target) ->
        Map.put(props, target, value)

      input_like_widget?(widget_type) and target == name ->
        Map.put(props, input_value_key(widget_type), value)

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
    Map.get(binding_state, :value) || Map.get(binding_state, "value")
  end

  defp input_like_widget?(widget_type) do
    widget_type in ["input", "textarea", "select", "slider", "radio", "checkbox", "switch"]
  end

  defp input_value_key(widget_type) when widget_type in ["checkbox", "switch"], do: "checked"
  defp input_value_key(_widget_type), do: "value"
end
