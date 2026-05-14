defmodule DesktopUi.Runtime.Realization do
  @moduledoc """
  Shared desktop realization for native and canonical widget trees.
  """

  alias DesktopUi.{Layer, Layout}
  alias DesktopUi.Runtime.{Error, Screen}
  alias DesktopUi.Widget

  @layout_kinds [:column, :content, :dialog, :row, :stack, :window] ++ Layout.kinds()

  @type realized_node :: map()

  @spec realize_screen(Screen.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def realize_screen(%Screen{} = screen, opts \\ []) do
    with {:ok, tree} <- realize_widget(screen.root, [screen.id], opts) do
      focus_order = collect_focus_order(tree)
      binding_index = collect_binding_index(tree)
      layers = collect_layers(tree)
      viewport_regions = collect_viewport_regions(tree)
      window_ids = collect_window_ids(tree)

      {:ok,
       %{
         screen_id: screen.id,
         tree: tree,
         focus_order: focus_order,
         current_focus: List.first(focus_order),
         binding_index: binding_index,
         event_targets: collect_event_targets(tree),
         cell_surface: to_cell_surface(tree),
         layers: layers,
         viewport_regions: viewport_regions,
         window_ids: window_ids,
         validation_state: validation_state_for(tree),
         diagnostics: %{
           source_kind: screen.source_kind,
           shared_runtime: true,
           root_kind: screen.root.kind,
           layout_kinds: screen.composition.layout_kinds,
           layer_kinds: screen.composition.layer_kinds,
           window_count: screen.composition.window_count,
           widget_count: screen.composition.widget_count,
           binding_names: Map.keys(binding_index),
           focus_traversal: :ready,
           event_targeting: :ready,
           layout_guards: :ready,
           layer_count: length(layers),
           viewport_count: length(viewport_regions),
           window_ids: window_ids,
           invalid_layout_state: nil,
           invalid_layering_state: nil
         }
       }}
    end
  end

  @spec focus_state(map()) :: map()
  def focus_state(realization) when is_map(realization) do
    %{
      current: Map.get(realization, :current_focus),
      order: Map.get(realization, :focus_order, [])
    }
  end

  defp realize_widget(%Widget{} = widget, path, opts) do
    cond do
      widget.kind not in supported_kinds() ->
        {:error,
         Error.new(
           :unsupported_foundational_widget,
           %{kind: widget.kind, widget_id: normalize_id(widget.id)},
           :realization
         )}

      invalid_layout_state?(widget) ->
        {:error,
         Error.new(
           :invalid_layout_state,
           %{kind: widget.kind, widget_id: normalize_id(widget.id)},
           :realization
         )}

      invalid_layering_state?(widget) ->
        {:error,
         Error.new(
           :invalid_layering_state,
           %{kind: widget.kind, widget_id: normalize_id(widget.id)},
           :realization
         )}

      orphaned_window_state?(widget) ->
        {:error,
         Error.new(
           :orphaned_windows,
           %{kind: widget.kind, widget_id: normalize_id(widget.id)},
           :realization
         )}

      true ->
        widget.children
        |> Enum.with_index()
        |> Enum.reduce_while({:ok, []}, fn {child, index}, {:ok, acc} ->
          case realize_widget(child, path ++ ["#{normalize_id(widget.id)}:#{index}"], opts) do
            {:ok, realized_child} -> {:cont, {:ok, acc ++ [realized_child]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)
        |> case do
          {:ok, children} ->
            {:ok,
             %{
               id: normalize_id(widget.id),
               kind: widget.kind,
               family: widget.family,
               path: path,
               focusable:
                 Map.get(widget.metadata, :focusable, false) &&
                   !Map.get(widget.state, :disabled, false),
               disabled: Map.get(widget.state, :disabled, false),
               bindings: widget.bindings,
               events: Map.keys(widget.events),
               metadata: widget.metadata,
               state: widget.state,
               attributes: widget.attributes,
               styles: widget.styles,
               layout?: widget.kind in @layout_kinds,
               viewport:
                 widget.kind in Layout.kinds() &&
                   widget.kind in [:viewport, :scroll_region, :split_pane],
               positioned: widget.kind in [:canvas_surface, :absolute],
               layer_role:
                 Map.get(widget.metadata, :overlay_role) ||
                   if(widget.kind in Layer.kinds(), do: widget.kind),
               children: children,
               render_target: Keyword.get(opts, :render_target, :shared_desktop_runtime)
             }}

          {:error, error} ->
            {:error, error}
        end
    end
  end

  defp collect_focus_order(node) do
    node
    |> flatten_nodes([])
    |> Enum.filter(& &1.focusable)
    |> Enum.map(& &1.id)
  end

  defp collect_binding_index(node) do
    Enum.reduce(flatten_nodes(node, []), %{}, fn current, acc ->
      Enum.reduce(current.bindings, acc, fn {_slot, binding_name}, index ->
        if is_nil(binding_name) do
          index
        else
          Map.update(index, binding_name, [%{widget_id: current.id}], fn entries ->
            entries ++ [%{widget_id: current.id}]
          end)
        end
      end)
    end)
  end

  defp collect_event_targets(node) do
    flatten_nodes(node, [])
    |> Enum.filter(&(length(&1.events) > 0))
    |> Map.new(fn current -> {current.id, current.events} end)
  end

  defp collect_layers(node) do
    flatten_nodes(node, [])
    |> Enum.filter(&(not is_nil(&1.layer_role)))
    |> Enum.map(fn current ->
      %{widget_id: current.id, kind: current.kind, role: current.layer_role}
    end)
  end

  defp collect_viewport_regions(node) do
    flatten_nodes(node, [])
    |> Enum.filter(&(&1.viewport || &1.positioned))
    |> Enum.map(fn current ->
      %{
        widget_id: current.id,
        kind: current.kind,
        viewport: current.viewport,
        positioned: current.positioned
      }
    end)
  end

  defp collect_window_ids(node) do
    flatten_nodes(node, [])
    |> Enum.filter(&(&1.kind == :window))
    |> Enum.map(& &1.id)
  end

  defp to_cell_surface(node) do
    flatten_nodes(node, [])
    |> Enum.map(fn current ->
      %{
        widget_id: current.id,
        kind: current.kind,
        family: current.family,
        content:
          current.attributes[:content] || current.attributes[:label] ||
            current.attributes[:window_title] || to_string(current.kind)
      }
    end)
  end

  defp flatten_nodes(node, acc) do
    Enum.reduce(node.children, acc ++ [node], &flatten_nodes(&1, &2))
  end

  defp supported_kinds do
    DesktopUi.Widgets.kinds() ++ Layout.kinds() ++ Layer.kinds()
  end

  defp invalid_layout_state?(widget) do
    widget.kind in [:column, :content, :row, :stack, :window, :dialog, :absolute, :canvas_surface] and
      !is_list(widget.children)
  end

  defp invalid_layering_state?(%Widget{kind: :overlay, slot_children: slot_children}) do
    Map.get(slot_children, :content, []) == [] or Map.get(slot_children, :overlay, []) == []
  end

  defp invalid_layering_state?(%Widget{kind: kind, slot_children: slot_children})
       when kind in [:context_menu, :popover] do
    Map.get(slot_children, :anchor, []) == []
  end

  defp invalid_layering_state?(%Widget{kind: :split_pane, slot_children: slot_children}) do
    Map.get(slot_children, :primary, []) == [] or Map.get(slot_children, :secondary, []) == []
  end

  defp invalid_layering_state?(_widget), do: false

  defp orphaned_window_state?(%Widget{kind: :multi_window, children: children}) do
    Enum.any?(children, &(&1.kind not in [:window, :dialog]))
  end

  defp orphaned_window_state?(_widget), do: false

  defp validation_state_for(tree) do
    if collect_layers(tree) == [] and collect_viewport_regions(tree) == [] and
         length(collect_window_ids(tree)) <= 1 do
      :foundational_ready
    else
      :advanced_ready
    end
  end

  defp normalize_id(nil), do: "anonymous"
  defp normalize_id(id), do: to_string(id)
end
