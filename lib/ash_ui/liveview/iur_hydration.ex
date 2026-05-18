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
    all_states =
      bindings
      |> normalize_bindings()
      |> Enum.reject(&BindingRuntime.action_binding?/1)

    element_states = Enum.filter(all_states, &(BindingRuntime.owner_scope(&1) == :element))

    Map.update(iur, "children", [], fn children ->
      Enum.map(children, &hydrate_node(&1, element_states, all_states))
    end)
  end

  def hydrate(iur, _bindings), do: iur

  defp hydrate_node(%{"id" => element_id} = node, binding_states, all_states \\ []) do
    props = Map.get(node, "props", %{})

    hydrated_props =
      binding_states
      |> Enum.filter(&(binding_element_id(&1) == element_id))
      |> Enum.reduce(props, fn binding_state, acc ->
        apply_binding(acc, node, binding_state)
      end)

    hydrated_children =
      node
      |> Map.get("children", [])
      |> Enum.map(&hydrate_node(&1, binding_states, all_states))

    node
    |> Map.put("props", hydrated_props)
    |> Map.put("children", hydrated_children)
    |> expand_list_repeat()
    |> expand_repeat_template(all_states)
  end

  defp hydrate_node(node, binding_states, all_states) when is_map(node) do
    Map.update(node, "children", [], fn children ->
      Enum.map(children, &hydrate_node(&1, binding_states, all_states))
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

      binding_type == :list and widget_type in ["list", "table", "list_repeat"] ->
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

  defp expand_list_repeat(%{"type" => "list_repeat", "props" => props} = node) do
    case repeat_items(props) do
      {:ok, items} ->
        templates = Map.get(node, "children", [])
        row_scope = Map.get(props, "row_scope") || "row"
        row_fields = Map.get(props, "row_fields", [])

        expanded_children =
          items
          |> Enum.with_index()
          |> Enum.flat_map(fn {row, row_index} ->
            templates
            |> Enum.with_index()
            |> Enum.map(fn {template, template_index} ->
              materialize_repeat_template(
                template,
                row,
                row_index,
                template_index,
                row_scope,
                row_fields
              )
            end)
          end)

        updated_props =
          props
          |> Map.put("hydrated?", true)
          |> Map.put("row_count", length(items))

        node
        |> Map.put("props", updated_props)
        |> Map.put("children", expanded_children)

      :none ->
        node
    end
  end

  defp expand_list_repeat(node), do: node

  # Expands a repeat-marked node whose type is NOT "list_repeat" (e.g.
  # "artifact_row", "custom:doc_block_numbered") but which carries repeat
  # metadata in `metadata.composition.repeat.binding_id`.  This handles the
  # case where the repeat directive lives on the screen's or parent element's
  # `ui_relationships` entry and is compiled by the LiveView's `compile_node`
  # helper, as opposed to the canonical `list_repeat` widget which carries its
  # own list binding as an element-scoped binding resolved before hydration.
  #
  # Called *after* `expand_list_repeat/1` so that a node with type
  # "list_repeat" that already expanded (and set props["hydrated?"] = true) is
  # a no-op here.
  defp expand_repeat_template(node, all_states) do
    repeat = get_in(node, ["metadata", "composition", "repeat"])

    with %{} <- repeat,
         binding_id when not is_nil(binding_id) <-
           Map.get(repeat, "binding_id") || Map.get(repeat, :binding_id),
         false <- Map.get(node["props"] || %{}, "hydrated?") == true,
         {:ok, items} <- find_binding_items(all_states, binding_id) do
      row_scope = Map.get(repeat, "row_scope") || Map.get(repeat, :row_scope) || "row"
      row_fields = Map.get(repeat, "row_fields") || Map.get(repeat, :row_fields) || []

      expanded_children =
        items
        |> Enum.with_index()
        |> Enum.map(fn {row, row_index} ->
          node
          |> strip_repeat_metadata()
          |> materialize_repeat_template(
            row,
            row_index,
            row_index,
            row_scope,
            row_fields
          )
        end)

      # Wrap expanded rows in a synthetic container node. The "hydrated?" flag
      # prevents re-expansion on subsequent hydrate calls. The wrapper uses
      # "list_repeat" type so the LiveUIAdapter renders its children as a
      # contiguous repeat group.
      %{
        "type" => "list_repeat",
        "id" => "#{node["id"]}:repeat_wrapper",
        "props" => %{
          "hydrated?" => true,
          "row_count" => length(items)
        },
        "children" => expanded_children,
        "metadata" => node["metadata"] || %{}
      }
    else
      _ -> node
    end
  end

  # Remove the repeat directive from a node's composition metadata so that
  # cloned row instances do not re-trigger `expand_repeat_template/2`.
  defp strip_repeat_metadata(%{"metadata" => %{"composition" => composition} = meta} = node)
       when is_map(composition) do
    stripped_composition = Map.delete(composition, "repeat") |> Map.delete(:repeat)
    Map.put(node, "metadata", Map.put(meta, "composition", stripped_composition))
  end

  defp strip_repeat_metadata(node), do: node

  defp find_binding_items(all_states, binding_id) do
    binding_id_str = to_string(binding_id)

    matching =
      Enum.find(all_states, fn state ->
        id = Map.get(state, :id) || Map.get(state, "id")
        target = Map.get(state, :target) || Map.get(state, "target")

        to_string(id) == binding_id_str or
          to_string(target) == binding_id_str
      end)

    case matching do
      nil ->
        :none

      state ->
        value = Map.get(state, :value) || Map.get(state, "value")

        cond do
          is_list(value) ->
            {:ok, value}

          is_map(value) ->
            items =
              Map.get(value, :items) || Map.get(value, "items")

            if is_list(items), do: {:ok, items}, else: :none

          true ->
            :none
        end
    end
  end

  defp repeat_items(props) do
    cond do
      Map.has_key?(props, "items") and is_list(Map.get(props, "items")) ->
        {:ok, Map.get(props, "items")}

      is_map(Map.get(props, "collection")) and
        Map.has_key?(Map.get(props, "collection"), "items") and
          is_list(get_in(props, ["collection", "items"])) ->
        {:ok, get_in(props, ["collection", "items"])}

      true ->
        :none
    end
  end

  defp materialize_repeat_template(
         template,
         row,
         row_index,
         template_index,
         row_scope,
         row_fields
       ) do
    row_identity = row_value(row, "id") || row_value(row, "row_identity") || row_index

    template
    |> resolve_row_scoped_node(row, row_scope, row_fields)
    |> put_repeat_child_id(row_identity, template_index)
    |> put_repeat_metadata(row_index, row_identity)
  end

  defp resolve_row_scoped_node(%{} = node, row, row_scope, row_fields) do
    node
    |> Map.update("props", %{}, fn props ->
      props
      |> resolve_row_scoped_value(row, row_scope, row_fields)
      |> stringify_map_keys()
    end)
    |> Map.update("children", [], fn children ->
      Enum.map(children, &resolve_row_scoped_node(&1, row, row_scope, row_fields))
    end)
  end

  defp resolve_row_scoped_node(node, _row, _row_scope, _row_fields), do: node

  defp resolve_row_scoped_value(%{} = value, row, row_scope, row_fields) do
    scope = Map.get(value, "scope") || Map.get(value, :scope)
    field = Map.get(value, "field") || Map.get(value, :field)

    if row_scope?(scope, row_scope) and repeat_row_field_allowed?(field, row_fields) do
      row_value(row, field)
    else
      Map.new(value, fn {key, nested} ->
        {key, resolve_row_scoped_value(nested, row, row_scope, row_fields)}
      end)
    end
  end

  defp resolve_row_scoped_value(value, row, row_scope, row_fields) when is_list(value) do
    Enum.map(value, &resolve_row_scoped_value(&1, row, row_scope, row_fields))
  end

  defp resolve_row_scoped_value(value, _row, _row_scope, _row_fields), do: value

  defp row_scope?(scope, row_scope), do: to_string(scope) == to_string(row_scope)

  defp repeat_row_field_allowed?(field, row_fields) do
    normalized_fields = Enum.map(List.wrap(row_fields), &to_string/1)
    normalized_fields == [] or to_string(field) in normalized_fields
  end

  defp row_value(row, field) when is_map(row) do
    Enum.find_value([field, to_string(field), safe_atom(field)], fn key ->
      if Map.has_key?(row, key) do
        {:value, Map.get(row, key)}
      end
    end)
    |> case do
      {:value, value} -> value
      nil -> nil
    end
  end

  defp row_value(_row, _field), do: nil

  defp safe_atom(value) when is_atom(value), do: value

  defp safe_atom(value) when is_binary(value) do
    String.to_existing_atom(value)
  rescue
    ArgumentError -> value
  end

  defp safe_atom(value), do: value

  defp put_repeat_child_id(%{} = node, row_identity, template_index) do
    base_id = Map.get(node, "id") || "repeat-child"
    Map.put(node, "id", "#{base_id}:row:#{row_identity}:#{template_index}")
  end

  defp put_repeat_metadata(%{} = node, row_index, row_identity) do
    metadata = Map.get(node, "metadata", %{})
    repeat = %{"row_index" => row_index, "row_identity" => row_identity}

    Map.put(node, "metadata", Map.put(metadata, "repeat", repeat))
  end

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
