defmodule AshUI.LiveView.IURHydration do
  @moduledoc """
  Applies runtime binding values back onto canonical IUR widgets.

  This keeps the rendered widget tree in sync with the latest evaluated binding
  state so LiveUI rendering can work directly from stored `unified_dsl`.

  ## Repeat expansion

  When a canonical IUR child carries `metadata.composition.repeat = "<binding_id>"`,
  this module treats it as a per-row template. The named binding must be a
  `:list`-typed binding on the parent module; its resolved list value is the
  row source. The single template node is expanded into one hydrated clone per
  row at hydration time. Inside a clone, any element-binding whose `source` is
  shaped `%{scope: :row, field: "<field>"}` resolves to the matching row field.

  This expansion happens here, not in the compiler or renderer — the compiler
  emits one template node, and renderers always see fully-expanded children.
  """

  alias AshUI.LiveView.BindingRuntime

  @type canonical_iur :: map()
  @type binding_state :: map()

  @doc """
  Returns a canonical IUR tree with binding values applied back onto widget
  props, keyed by `element_id` and binding target.
  """
  @spec hydrate(canonical_iur(), map() | [binding_state()]) :: canonical_iur()
  def hydrate(%{"type" => "screen"} = iur, bindings) do
    normalized = normalize_bindings(bindings)

    element_binding_states =
      normalized
      |> Enum.reject(&BindingRuntime.action_binding?/1)
      |> Enum.filter(&(BindingRuntime.owner_scope(&1) == :element))

    list_binding_index = build_list_binding_index(normalized)

    Map.update(iur, "children", [], fn children ->
      expand_and_hydrate_children(children, element_binding_states, list_binding_index)
    end)
  end

  def hydrate(iur, _bindings), do: iur

  # Walk a list of children, expanding any `repeat`-marked node into N clones
  # before hydration. The non-repeat path is identical to the prior behaviour.
  defp expand_and_hydrate_children(children, binding_states, list_binding_index) do
    Enum.flat_map(children, fn child ->
      case repeat_binding_id(child) do
        nil ->
          [hydrate_node(child, binding_states, list_binding_index)]

        repeat_id ->
          rows = lookup_rows(list_binding_index, repeat_id)

          rows
          |> Enum.with_index()
          |> Enum.map(fn {row, index} ->
            cloned = clone_template_for_row(child, row, index)

            hydrate_node(
              cloned,
              binding_states ++ row_binding_states(cloned, row),
              list_binding_index
            )
          end)
      end
    end)
  end

  defp hydrate_node(%{"id" => element_id} = node, binding_states, list_binding_index) do
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
      expand_and_hydrate_children(children, binding_states, list_binding_index)
    end)
  end

  defp hydrate_node(node, binding_states, list_binding_index) when is_map(node) do
    Map.update(node, "children", [], fn children ->
      expand_and_hydrate_children(children, binding_states, list_binding_index)
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

  # === Repeat expansion helpers ===

  # Returns the `repeat` binding id stamped onto the node's composition metadata,
  # if any. Composition metadata is set by the compiler when it walks a
  # `ui_relationship ... repeat ...` declaration.
  defp repeat_binding_id(node) when is_map(node) do
    composition =
      get_in(node, ["metadata", "composition"]) ||
        get_in(node, [:metadata, :composition]) ||
        %{}

    case Map.get(composition, "repeat") || Map.get(composition, :repeat) do
      nil -> nil
      "" -> nil
      value when is_binary(value) -> value
      value when is_atom(value) -> Atom.to_string(value)
      _ -> nil
    end
  end

  defp repeat_binding_id(_node), do: nil

  # Builds a lookup by binding id whose value is the binding state. Only
  # :list-typed binding states are retained — the only ones that can serve as
  # row sources for a repeat.
  defp build_list_binding_index(binding_states) do
    binding_states
    |> Enum.filter(fn state -> binding_type(state) == :list end)
    |> Enum.reduce(%{}, fn state, acc ->
      case binding_lookup_key(state) do
        nil -> acc
        key -> Map.put(acc, key, state)
      end
    end)
  end

  defp binding_lookup_key(state) when is_map(state) do
    case Map.get(state, :id) || Map.get(state, "id") do
      value when is_binary(value) -> value
      value when is_atom(value) and not is_nil(value) -> Atom.to_string(value)
      _ -> nil
    end
  end

  defp binding_lookup_key(_state), do: nil

  # Looks up the rows for a repeat. The list binding's resolved value can be
  # either a bare list or a `%{"items" => [...]}` collection map (the same
  # shapes the existing `:list` widget hydration supports).
  defp lookup_rows(list_binding_index, repeat_id) do
    case Map.get(list_binding_index, repeat_id) do
      nil ->
        []

      binding_state ->
        case binding_value(binding_state) do
          rows when is_list(rows) -> rows
          %{"items" => rows} when is_list(rows) -> rows
          %{items: rows} when is_list(rows) -> rows
          _ -> []
        end
    end
  end

  # Produces a per-row clone of a template IUR node. The clone's `id` is
  # stable across renders for the same row (driven by the row's `id` field if
  # present, otherwise the row index) so LiveView's stream diffing can match.
  # Composition metadata's `repeat` marker is stripped on the clone so the
  # clone itself is not re-expanded.
  defp clone_template_for_row(template, row, index) do
    template_id = Map.get(template, "id") || "repeat"
    row_key = row_id(row, index)
    clone_id = "#{template_id}__row_#{row_key}"

    new_metadata =
      template
      |> Map.get("metadata", %{})
      |> stringify_map_keys()
      |> Map.update("composition", %{}, fn composition ->
        composition
        |> stringify_map_keys()
        |> Map.delete("repeat")
        |> Map.put(
          "repeat_origin",
          Map.get(composition, "repeat") || Map.get(composition, :repeat)
        )
        |> Map.put("repeat_row_index", index)
        |> Map.put("repeat_row_id", row_key)
      end)

    template
    |> Map.put("id", clone_id)
    |> Map.put("metadata", new_metadata)
    |> rewrite_child_ids(template_id, clone_id)
  end

  # Recursively rewrites descendant ids so they remain unique per row.
  defp rewrite_child_ids(node, template_prefix, clone_prefix) when is_map(node) do
    Map.update(node, "children", [], fn children ->
      Enum.map(children, fn child ->
        case Map.get(child, "id") do
          nil ->
            rewrite_child_ids(child, template_prefix, clone_prefix)

          child_id ->
            new_child_id = "#{clone_prefix}__#{child_id}"

            child
            |> Map.put("id", new_child_id)
            |> rewrite_child_ids(template_prefix, clone_prefix)
        end
      end)
    end)
  end

  defp rewrite_child_ids(node, _template_prefix, _clone_prefix), do: node

  # Derives a stable key from a row. Prefers `id`, falls back to the index so
  # row-less or unkeyed rows still get unique element ids.
  defp row_id(row, index) when is_map(row) do
    case Map.get(row, :id) || Map.get(row, "id") do
      nil -> "#{index}"
      value when is_binary(value) -> value
      value when is_integer(value) -> Integer.to_string(value)
      value -> to_string(value)
    end
  end

  defp row_id(_row, index), do: "#{index}"

  # Synthesizes per-row binding states by projecting the cloned template
  # subtree's `scope: :row` bindings against the supplied row. The clone has
  # already had its element ids rewritten (`<template_id>__row_<row_key>`),
  # so the synthesized states reference the clone's element ids and feed
  # cleanly through `hydrate_node/3` and `apply_binding/3`.
  #
  # In addition to projecting authored bindings we always emit a synthetic
  # binding pinning the entire row under `props.row`, so renderers / widgets
  # can read row state without authoring a per-field binding.
  defp row_binding_states(cloned_template, row) do
    clone_id = Map.get(cloned_template, "id")

    [
      %{
        id: "__repeat_row__#{clone_id}",
        element_id: clone_id,
        target: "row",
        value: row,
        binding_type: :value,
        metadata: %{"owner_scope" => "element"}
      }
    ] ++ collect_row_scope_bindings(cloned_template, row)
  end

  # Recursively finds descendants whose canonical IUR `bindings` advertise a
  # `%{scope: :row, field: ...}` source and synthesizes a binding state with
  # the field value pulled from the supplied row.
  #
  # Canonical IUR keeps bindings at the screen level (not per-node), so this
  # function looks instead at any per-node `bindings` array some compilers
  # attach — and at the per-node `props.bindings` shape that ariston-style
  # element resources may pre-flatten. Both shapes are accepted to keep the
  # author DSL free to evolve. If neither shape is present, only the synthetic
  # `row` binding above is emitted; per-field row references are then a future
  # follow-up that lets template Elements declare `scope: :row` in their
  # `ui_bindings`.
  defp collect_row_scope_bindings(node, row) when is_map(node) do
    node_id = Map.get(node, "id")

    own =
      node
      |> Map.get("bindings", [])
      |> List.wrap()
      |> Enum.flat_map(fn binding ->
        case row_scope_field(binding) do
          nil ->
            []

          field ->
            target = Map.get(binding, "target") || Map.get(binding, :target) || field

            [
              %{
                id: "__repeat_field__#{node_id || "_"}__#{target}",
                element_id: node_id,
                target: target,
                value: row_field(row, field),
                binding_type: :value,
                metadata: %{"owner_scope" => "element"}
              }
            ]
        end
      end)

    children =
      node
      |> Map.get("children", [])
      |> Enum.flat_map(&collect_row_scope_bindings(&1, row))

    own ++ children
  end

  defp collect_row_scope_bindings(_node, _row), do: []

  defp row_scope_field(binding) when is_map(binding) do
    source = Map.get(binding, "source") || Map.get(binding, :source) || %{}
    scope = Map.get(source, "scope") || Map.get(source, :scope)
    field = Map.get(source, "field") || Map.get(source, :field)

    cond do
      scope in [:row, "row"] and is_binary(field) and field != "" -> field
      scope in [:row, "row"] and is_atom(field) and not is_nil(field) -> Atom.to_string(field)
      true -> nil
    end
  end

  defp row_scope_field(_binding), do: nil

  defp row_field(row, field) when is_map(row) and is_binary(field) do
    Map.get(row, field) ||
      case safe_existing_atom(field) do
        nil -> nil
        atom -> Map.get(row, atom)
      end
  end

  defp row_field(_row, _field), do: nil

  defp safe_existing_atom(field) do
    String.to_existing_atom(field)
  rescue
    ArgumentError -> nil
  end
end
