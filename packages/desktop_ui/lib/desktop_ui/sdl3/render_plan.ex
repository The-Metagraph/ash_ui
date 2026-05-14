defmodule DesktopUi.Sdl3.RenderPlan do
  @moduledoc """
  Retained render-plan structures for the SDL3 adapter seam.
  """

  alias DesktopUi.Runtime.{Error, State}
  alias DesktopUi.Sdl3.Window
  alias DesktopUi.Widget

  @enforce_keys [:runtime_id, :screen_id, :windows, :presentation, :diagnostics]
  defstruct [:runtime_id, :screen_id, :windows, :presentation, :diagnostics]

  @slot_priority %{
    overlay: [:content, :overlay],
    popover: [:anchor, :content],
    context_menu: [:anchor],
    split_pane: [:primary, :secondary],
    viewport: [:content],
    scroll_region: [:content],
    default: [:default, :header, :content, :footer, :overlay, :primary, :secondary, :anchor]
  }

  @fill_kinds [
    :viewport,
    :scroll_region,
    :split_pane,
    :table,
    :process_monitor,
    :log_viewer,
    :command_palette,
    :cluster_dashboard,
    :canvas_surface,
    :content
  ]

  @type t :: %__MODULE__{
          runtime_id: String.t(),
          screen_id: String.t(),
          windows: [map()],
          presentation: map(),
          diagnostics: map()
        }

  @spec build(State.t()) :: {:ok, t()} | {:error, Error.t()}
  def build(%State{} = runtime_state) do
    with {:ok, registry} <- Window.registry(runtime_state) do
      node_index = index_realized_nodes(runtime_state.realization.tree)
      source_index = index_source_widgets(runtime_state.root)
      clip_regions = runtime_state.realization.viewport_regions

      windows =
        registry.sessions
        |> Enum.with_index()
        |> Enum.map(fn {session, index} ->
          draw_operations =
            build_window_operations(
              session,
              index,
              node_index,
              source_index,
              runtime_state.focus.current,
              runtime_state.realization.tree,
              runtime_state.root
            )

          %{
            window_id: session.id,
            window_identity: session.window_identity,
            title: session.title,
            role: session.role,
            native_window?: session.native_window?,
            logical_bounds: logical_bounds(index),
            clip_regions: Enum.filter(clip_regions, &(&1.widget_id in session.owned_widget_ids)),
            transient_layers: session.transient_layers,
            draw_operations: draw_operations
          }
        end)

      draw_operations = Enum.flat_map(windows, & &1.draw_operations)

      {:ok,
       %__MODULE__{
         runtime_id: runtime_state.runtime_id,
         screen_id: runtime_state.screen_id,
         windows: windows,
         presentation: %{
           backend: :sdl_renderer,
           logical_units: true,
           placeholder_draw_operations: false,
           widget_complete_draw_operations: true,
           iur_widget_coverage: :complete,
           supported_iur_kinds: length(DesktopUi.Renderer.supported_kinds()),
           validation_state: :iur_renderer_complete
         },
         diagnostics: %{
           window_count: length(windows),
           draw_operation_count: length(draw_operations),
           clip_region_count: windows |> Enum.flat_map(& &1.clip_regions) |> length(),
           draw_kind_counts: Enum.frequencies_by(draw_operations, & &1.draw_kind)
         }
       }}
    end
  end

  defp build_window_operations(
         session,
         index,
         node_index,
         source_index,
         focus_target,
         fallback_node,
         fallback_source
       ) do
    bounds = logical_bounds(index)

    session
    |> window_root_id(node_index)
    |> case do
      nil ->
        case session.owned_widget_ids |> Enum.filter(&Map.has_key?(node_index, &1)) do
          [] ->
            layout_node(
              fallback_node,
              Map.get(source_index, normalize_id(fallback_source.id), fallback_source),
              bounds,
              node_index,
              source_index,
              focus_target,
              nil
            )

          owned_widget_ids ->
            Enum.map(owned_widget_ids, fn widget_id ->
              node = Map.fetch!(node_index, widget_id)
              source = Map.get(source_index, widget_id, source_stub(node))
              draw_operation(node, source, draw_bounds(node, index), focus_target, nil)
            end)
        end

      widget_id ->
        node = Map.fetch!(node_index, widget_id)
        source = Map.get(source_index, widget_id, source_stub(node))
        layout_node(node, source, bounds, node_index, source_index, focus_target, nil)
    end
  end

  defp window_root_id(session, node_index) do
    Enum.find(session.owned_widget_ids, fn widget_id ->
      case Map.get(node_index, widget_id) do
        %{kind: :window} -> true
        _other -> false
      end
    end)
  end

  defp layout_node(node, source, bounds, node_index, source_index, focus_target, inherited_clip) do
    operation = draw_operation(node, source, bounds, focus_target, inherited_clip)
    child_clip = next_clip_bounds(node, bounds, inherited_clip)

    child_operations =
      node
      |> child_layout_specs(source, bounds, node_index, source_index, child_clip)
      |> Enum.flat_map(fn {child, child_source, child_bounds, child_clip_bounds} ->
        layout_node(
          child,
          child_source,
          child_bounds,
          node_index,
          source_index,
          focus_target,
          child_clip_bounds
        )
      end)

    [operation | child_operations]
  end

  defp child_layout_specs(node, source, bounds, node_index, source_index, inherited_clip) do
    children = ordered_children(node, source, node_index, source_index)
    inner_bounds = content_bounds(node, bounds)

    case node.kind do
      kind when kind in [:window, :dialog, :column] ->
        layout_column(children, inner_bounds, node, source, source_index, inherited_clip)

      kind when kind in [:row, :content] ->
        layout_row(children, inner_bounds, node, source, source_index, inherited_clip)

      :box ->
        layout_column(children, inner_bounds, node, source, source_index, inherited_clip)

      :grid ->
        layout_grid(children, inner_bounds, node, source, source_index, inherited_clip)

      :split_pane ->
        layout_split_pane(children, inner_bounds, source, source_index, inherited_clip)

      kind when kind in [:viewport, :scroll_region] ->
        layout_single_child(children, inner_bounds, inherited_clip || inner_bounds)

      :scroll_bar ->
        layout_single_child(children, inner_bounds, inner_bounds)

      :overlay ->
        layout_overlay(children, inner_bounds, source, source_index, inherited_clip)

      :canvas_surface ->
        layout_canvas_surface(children, inner_bounds, source, source_index, inherited_clip)

      :absolute ->
        layout_absolute(children, inner_bounds, inherited_clip)

      _other ->
        layout_default(children, inner_bounds, source_index, inherited_clip)
    end
  end

  defp layout_column(children, bounds, node, _source, source_index, inherited_clip) do
    gap = gap_px(node)
    preferred_heights = Enum.map(children, &preferred_height/1)
    expandable_indexes = expandable_indexes(children)
    available_height = max(bounds.height - gap * max(length(children) - 1, 0), 0)
    base_height = Enum.sum(preferred_heights)
    extra_height = max(available_height - base_height, 0)
    expansion = distribute_extra(extra_height, expandable_indexes)

    {specs, _next_y} =
      Enum.reduce(Enum.with_index(children), {[], bounds.y}, fn {child, index}, {specs, y} ->
        height = preferred_heights |> Enum.at(index) |> Kernel.+(Map.get(expansion, index, 0))

        child_bounds = %{
          x: bounds.x,
          y: y,
          width: bounds.width,
          height: min(height, max(bounds.y + bounds.height - y, 32)),
          units: :logical
        }

        {
          specs ++
            [
              {child, Map.get(source_index, normalize_id(child.id), source_stub(child)),
               child_bounds, inherited_clip}
            ],
          y + child_bounds.height + gap
        }
      end)

    specs
  end

  defp layout_row(children, bounds, node, _source, source_index, inherited_clip) do
    gap = gap_px(node)
    preferred_widths = Enum.map(children, &preferred_width(&1, bounds.width))
    expandable_indexes = expandable_indexes(children)
    available_width = max(bounds.width - gap * max(length(children) - 1, 0), 0)
    base_width = Enum.sum(preferred_widths)
    extra_width = max(available_width - base_width, 0)
    expansion = distribute_extra(extra_width, expandable_indexes)

    {specs, _next_x} =
      Enum.reduce(Enum.with_index(children), {[], bounds.x}, fn {child, index}, {specs, x} ->
        width = preferred_widths |> Enum.at(index) |> Kernel.+(Map.get(expansion, index, 0))

        child_bounds = %{
          x: x,
          y: bounds.y,
          width: min(width, max(bounds.x + bounds.width - x, 32)),
          height: bounds.height,
          units: :logical
        }

        {
          specs ++
            [
              {child, Map.get(source_index, normalize_id(child.id), source_stub(child)),
               child_bounds, inherited_clip}
            ],
          x + child_bounds.width + gap
        }
      end)

    specs
  end

  defp layout_grid(children, bounds, node, source, source_index, inherited_clip) do
    # Get grid dimensions from attributes
    columns = Map.get(source.attributes, :columns) || Map.get(node.attributes, :columns, 2)
    rows = Map.get(node.attributes, :rows)
    gap = gap_px(node) || 8

    # If rows are specified, use them; otherwise calculate based on children count
    child_count = length(children)
    calculated_rows = ceil(child_count / columns)
    row_count = if rows, do: rows, else: calculated_rows

    # Calculate cell dimensions
    column_gap = Map.get(source.attributes, :column_gap) || gap
    row_gap = Map.get(source.attributes, :row_gap) || gap
    total_gap_width = column_gap * max(columns - 1, 0)
    total_gap_height = row_gap * max(trunc(row_count) - 1, 0)

    cell_width = max((bounds.width - total_gap_width) / columns, 32)
    cell_height = if rows do
      max((bounds.height - total_gap_height) / row_count, 32)
    else
      # Calculate based on available height divided by rows needed
      max((bounds.height - total_gap_height) / calculated_rows, 32)
    end

    specs =
      Enum.with_index(children)
      |> Enum.map(fn {child, index} ->
        col = rem(index, columns)
        row = div(index, columns)

        x = bounds.x + col * (cell_width + column_gap)
        y = bounds.y + row * (cell_height + row_gap)

        child_bounds = %{
          x: round(x),
          y: round(y),
          width: round(cell_width),
          height: round(cell_height),
          units: :logical
        }

        {child, Map.get(source_index, normalize_id(child.id), source_stub(child)),
         child_bounds, inherited_clip}
      end)

    specs
  end

  defp layout_split_pane(children, bounds, source, source_index, inherited_clip) do
    ratio = Map.get(source.attributes, :ratio, 0.5)
    direction = Map.get(source.attributes, :direction, :horizontal)
    divider = 10

    case children do
      [primary, secondary | rest] ->
        {primary_bounds, secondary_bounds} =
          case direction do
            :vertical ->
              primary_height = round((bounds.height - divider) * ratio)

              {
                %{bounds | height: primary_height},
                %{
                  x: bounds.x,
                  y: bounds.y + primary_height + divider,
                  width: bounds.width,
                  height: max(bounds.height - primary_height - divider, 32),
                  units: :logical
                }
              }

            _other ->
              primary_width = round((bounds.width - divider) * ratio)

              {
                %{bounds | width: primary_width},
                %{
                  x: bounds.x + primary_width + divider,
                  y: bounds.y,
                  width: max(bounds.width - primary_width - divider, 32),
                  height: bounds.height,
                  units: :logical
                }
              }
          end

        specs = [
          {primary, Map.get(source_index, normalize_id(primary.id), source_stub(primary)),
           primary_bounds, inherited_clip},
          {secondary, Map.get(source_index, normalize_id(secondary.id), source_stub(secondary)),
           secondary_bounds, inherited_clip}
        ]

        extra =
          Enum.with_index(rest, 1)
          |> Enum.map(fn {child, offset} ->
            extra_bounds = %{
              x: secondary_bounds.x,
              y: secondary_bounds.y + offset * 36,
              width: secondary_bounds.width,
              height: max(secondary_bounds.height - offset * 24, 32),
              units: :logical
            }

            {child, Map.get(source_index, normalize_id(child.id), source_stub(child)),
             extra_bounds, inherited_clip}
          end)

        specs ++ extra

      _other ->
        layout_default(children, bounds, source_index, inherited_clip)
    end
  end

  defp layout_overlay(children, bounds, source, source_index, inherited_clip) do
    content_ids =
      source.slot_children
      |> Map.get(:content, [])
      |> Enum.map(&normalize_id(&1.id))

    _overlay_ids =
      source.slot_children
      |> Map.get(:overlay, [])
      |> Enum.map(&normalize_id(&1.id))

    {content_children, overlay_children} =
      Enum.split_with(children, fn child -> normalize_id(child.id) in content_ids end)

    content_specs =
      content_children
      |> Enum.map(fn child ->
        {child, Map.get(source_index, normalize_id(child.id), source_stub(child)), bounds,
         inherited_clip}
      end)

    overlay_specs =
      overlay_children
      |> Enum.with_index()
      |> Enum.map(fn {child, index} ->
        overlay_bounds =
          cond do
            child.kind == :dialog ->
              centered_bounds(bounds, 0.58, 0.44)

            child.kind == :context_menu ->
              %{
                x: bounds.x + max(bounds.width - 300, 32),
                y: bounds.y + 32,
                width: min(280, bounds.width - 32),
                height: max(120, 88 + item_count(child) * 28),
                units: :logical
              }

            true ->
              centered_bounds(bounds, 0.48, 0.36 + index * 0.04)
          end

        {child, Map.get(source_index, normalize_id(child.id), source_stub(child)), overlay_bounds,
         inherited_clip}
      end)

    content_specs ++ overlay_specs
  end

  defp layout_canvas_surface(children, bounds, source, source_index, inherited_clip) do
    width_units = max(Map.get(source.attributes, :width, 20), 1)
    height_units = max(Map.get(source.attributes, :height, 10), 1)
    cell_width = max(div(bounds.width, width_units), 20)
    cell_height = max(div(bounds.height, height_units), 20)

    Enum.map(children, fn child ->
      child_source = Map.get(source_index, normalize_id(child.id), source_stub(child))
      x_units = Map.get(child_source.attributes, :x, 0)
      y_units = Map.get(child_source.attributes, :y, 0)

      child_bounds = %{
        x: bounds.x + x_units * cell_width,
        y: bounds.y + y_units * cell_height,
        width: max(div(cell_width * 3, 2), 60),
        height: max(cell_height + 12, 32),
        units: :logical
      }

      {child, child_source, child_bounds, inherited_clip}
    end)
  end

  defp layout_absolute(children, bounds, inherited_clip) do
    Enum.map(children, fn child ->
      {child, source_stub(child), bounds, inherited_clip}
    end)
  end

  defp layout_single_child(children, bounds, inherited_clip) do
    Enum.map(children, fn child ->
      {child, source_stub(child), bounds, inherited_clip}
    end)
  end

  defp layout_default(children, bounds, source_index, inherited_clip) do
    Enum.map(children, fn child ->
      {child, Map.get(source_index, normalize_id(child.id), source_stub(child)), bounds,
       inherited_clip}
    end)
  end

  defp ordered_children(node, source, node_index, source_index) do
    preferred_ids =
      source
      |> ordered_source_children()
      |> Enum.map(&normalize_id(&1.id))

    node.children
    |> Enum.sort_by(fn child ->
      Enum.find_index(preferred_ids, &(&1 == normalize_id(child.id))) || length(preferred_ids)
    end)
    |> Enum.map(fn child ->
      Map.get(
        node_index,
        normalize_id(child.id),
        Map.get(source_index, normalize_id(child.id), child)
      )
    end)
  end

  defp ordered_source_children(source) do
    prioritized =
      Map.get(@slot_priority, source.kind, @slot_priority.default)
      |> Enum.flat_map(fn slot -> Map.get(source.slot_children, slot, []) end)

    remainder =
      source.children
      |> Enum.reject(fn child ->
        normalize_id(child.id) in Enum.map(prioritized, &normalize_id(&1.id))
      end)

    prioritized ++ remainder
  end

  defp next_clip_bounds(node, bounds, inherited_clip) do
    if node.kind in [:viewport, :scroll_region] do
      content_bounds(node, bounds)
    else
      inherited_clip
    end
  end

  defp content_bounds(node, bounds) do
    padding = padding_px(get_in(node, [:resolved_styles, :padding]))

    case node.kind do
      :window ->
        inset_bounds(bounds, padding + 18, 60, padding + 18, padding + 18)

      :dialog ->
        inset_bounds(bounds, padding + 18, 52, padding + 18, padding + 18)

      kind
      when kind in [:overlay, :viewport, :scroll_region, :scroll_bar, :content, :column, :row, :split_pane, :box, :grid] ->
        inset_bounds(bounds, padding + 12, padding + 12, padding + 12, padding + 12)

      :canvas_surface ->
        inset_bounds(bounds, 16, 16, 16, 16)

      _other ->
        inset_bounds(bounds, padding + 8, padding + 8, padding + 8, padding + 8)
    end
  end

  defp draw_operation(node, source, bounds, focus_target, clip_bounds) do
    content = draw_content(node)

    %{
      widget_id: node.id,
      kind: node.kind,
      family: node.family,
      draw_kind: draw_kind(node.kind),
      logical_bounds: bounds,
      clip?: not is_nil(clip_bounds),
      clip_bounds: clip_bounds,
      layer_role: node.layer_role,
      semantic_role: get_in(node, [:resolved_styles, :semantic_role]) || source.metadata[:role],
      resolved_styles: Map.get(node, :resolved_styles, %{}),
      resource: draw_resource(node),
      interaction: interaction_metadata(source),
      visual_state: %{
        disabled: truthy?(node.disabled),
        focused:
          normalize_id(node.id) == normalize_id(focus_target) || truthy?(node.state[:focused]),
        selected: truthy?(node.state[:selected]),
        checked: truthy?(node.state[:checked]),
        active: truthy?(node.state[:active]),
        open: truthy?(node.state[:open]),
        current: truthy?(node.state[:current]),
        loading: truthy?(node.state[:loading])
      },
      metrics: %{
        child_count: length(node.children),
        item_count: item_count(node),
        row_count: row_count(node),
        column_count: column_count(node),
        series_count: series_count(node),
        current_index: current_index(node),
        selected_index: selected_index(node),
        value: numeric_value(node),
        max_value: max_value(node),
        content_length: String.length(content)
      },
      content: content
    }
  end

  defp draw_resource(node) do
    case node.kind do
      :image ->
        %{
          kind: :image,
          source: node.attributes[:source],
          alt: node.attributes[:alt]
        }

      :icon ->
        %{
          kind: :icon,
          name: node.attributes[:icon]
        }

      _other ->
        %{}
    end
  end

  defp interaction_metadata(source) do
    events = Map.get(source, :events, %{})

    %{
      focusable: Map.get(source.metadata, :focusable, false),
      shortcut: Map.get(source.metadata, :shortcut) || get_in(events, [:shortcut, :key]),
      shortcut_intent: event_intent(Map.get(events, :shortcut)),
      click_intent: event_intent(Map.get(events, :click)),
      submit_intent: event_intent(Map.get(events, :submit)),
      selection_intent: event_intent(Map.get(events, :selection)),
      command_intent: event_intent(Map.get(events, :command)),
      close_intent: event_intent(Map.get(events, :close)),
      navigation_intent: event_intent(Map.get(events, :navigation)),
      window_identity: Map.get(source.metadata, :window_identity),
      overlay_role: Map.get(source.metadata, :overlay_role),
      selection_mode:
        Map.get(source.metadata, :selection_mode, Map.get(source.attributes, :selection_mode))
    }
  end

  defp event_intent(nil), do: nil
  defp event_intent(event) when is_map(event), do: Map.get(event, :intent)
  defp event_intent(_event), do: nil

  defp draw_content(node) do
    cond do
      is_binary(node.attributes[:content]) -> node.attributes[:content]
      is_binary(node.attributes[:label]) -> node.attributes[:label]
      is_binary(node.attributes[:window_title]) -> node.attributes[:window_title]
      is_binary(node.attributes[:message]) -> node.attributes[:message]
      is_binary(node.attributes[:query]) -> node.attributes[:query]
      is_binary(node.attributes[:alt]) -> node.attributes[:alt]
      is_binary(node.attributes[:placeholder]) -> node.attributes[:placeholder]
      true -> to_string(node.kind)
    end
  end

  defp draw_kind(:window), do: :window_chrome
  defp draw_kind(:dialog), do: :dialog_surface
  defp draw_kind(:text), do: :text_block
  defp draw_kind(:label), do: :label_block
  defp draw_kind(:icon), do: :icon_block
  defp draw_kind(:image), do: :image_block
  defp draw_kind(:badge), do: :badge_block
  defp draw_kind(:hero), do: :hero_block
  defp draw_kind(kind) when kind in [:button, :window_command], do: :button_control
  defp draw_kind(:command), do: :command_control
  defp draw_kind(:link), do: :link_control
  defp draw_kind(:text_input), do: :text_input_control
  defp draw_kind(:numeric_input), do: :numeric_input_control
  defp draw_kind(:slider), do: :slider_control
  defp draw_kind(:date_input), do: :date_input_control
  defp draw_kind(:time_input), do: :time_input_control
  defp draw_kind(:file_input), do: :file_input_control
  defp draw_kind(:pick_list), do: :pick_list_surface
  defp draw_kind(:checkbox), do: :checkbox_control
  defp draw_kind(:radio_group), do: :radio_group_surface
  defp draw_kind(:select), do: :select_surface
  defp draw_kind(:separator), do: :separator_line
  defp draw_kind(:spacer), do: :spacer_gap
  defp draw_kind(:tabs), do: :tabs_surface
  defp draw_kind(:list), do: :list_surface
  defp draw_kind(:menu), do: :menu_surface
  defp draw_kind(:table), do: :table_surface
  defp draw_kind(:tree_view), do: :tree_view_surface
  defp draw_kind(:stat), do: :stat_block
  defp draw_kind(:key_value), do: :key_value_block
  defp draw_kind(:info_list), do: :info_list_block
  defp draw_kind(:status), do: :status_block
  defp draw_kind(:sparkline), do: :sparkline_surface
  defp draw_kind(:progress), do: :progress_block
  defp draw_kind(:inline_feedback), do: :inline_feedback_surface
  defp draw_kind(:process_monitor), do: :process_monitor_surface
  defp draw_kind(:log_viewer), do: :log_viewer_surface
  defp draw_kind(:stream_widget), do: :stream_widget_surface
  defp draw_kind(:supervision_tree_viewer), do: :supervision_tree_surface
  defp draw_kind(:cluster_dashboard), do: :cluster_dashboard_surface
  defp draw_kind(:command_palette), do: :command_palette_surface
  defp draw_kind(:gauge), do: :gauge_surface
  defp draw_kind(:viewport), do: :viewport_surface
  defp draw_kind(:scroll_bar), do: :scroll_bar_surface
  defp draw_kind(:split_pane), do: :split_pane_surface
  defp draw_kind(:overlay), do: :overlay_surface
  defp draw_kind(:context_menu), do: :context_menu_surface
  defp draw_kind(:canvas_surface), do: :canvas_surface
  defp draw_kind(:absolute), do: :positioned_fragment
  defp draw_kind(_kind), do: :container_surface

  defp preferred_height(node) do
    cond do
      node.kind in [:text, :label] -> 28
      node.kind == :badge -> badge_height(node)
      node.kind == :hero -> 180
      node.kind in [:button, :command, :window_command] -> 42
      node.kind == :link -> 32
      node.kind == :checkbox -> 36
      node.kind == :text_input -> 46
      node.kind == :numeric_input -> 46
      node.kind == :slider -> slider_thickness(node)
      node.kind == :date_input -> 46
      node.kind == :time_input -> 46
      node.kind == :file_input -> 46
      node.kind == :pick_list -> pick_list_height(node)
      node.kind == :radio_group -> 42 + option_count(node) * 36
      node.kind == :select -> 46
      node.kind == :separator -> separator_thickness(node)
      node.kind == :spacer -> spacer_size(node)
      node.kind == :tabs -> 52
      node.kind == :list -> 56 + item_count(node) * 34
      node.kind == :menu -> 52 + item_count(node) * 28
      node.kind in [:table, :process_monitor] -> 88 + row_count(node) * 28
      node.kind == :tree_view -> tree_view_height(node)
      node.kind == :stat -> stat_height(node)
      node.kind == :key_value -> key_value_height(node)
      node.kind == :info_list -> info_list_height(node)
      node.kind == :status -> 32
      node.kind == :sparkline -> sparkline_height(node)
      node.kind == :progress -> progress_height(node)
      node.kind == :inline_feedback -> 48
      node.kind == :log_viewer -> max(152, 52 + item_count(node) * 26)
      node.kind == :stream_widget -> max(120, 52 + item_count(node) * 18)
      node.kind == :supervision_tree_viewer -> supervision_tree_height(node)
      node.kind == :cluster_dashboard -> 160
      node.kind == :command_palette -> 156
      node.kind == :gauge -> 108
      node.kind == :viewport -> 280
      node.kind == :scroll_bar -> scroll_bar_thickness(node)
      node.kind == :split_pane -> 320
      node.kind == :dialog -> 240
      node.kind == :canvas_surface -> 200
      node.kind == :overlay -> 340
      node.kind == :context_menu -> 132
      node.kind == :window -> 520
      true -> 64
    end
  end

  defp badge_height(node) do
    case node.attributes[:size] do
      :sm -> 20
      :lg -> 32
      _ -> 24
    end
  end

  defp slider_thickness(node) do
    if node.attributes[:orientation] == :vertical, do: 120, else: 42
  end

  defp pick_list_height(node) do
    base = 46
    if node.attributes[:open] || node.attributes[:focused] do
      base + min(option_count(node), 6) * 36
    else
      base
    end
  end

  defp tree_view_height(node) do
    base = 64
    node_count = item_count(node)
    if node_count > 0 do
      base + min(node_count, 8) * 28
    else
      base
    end
  end

  defp stat_height(node) do
    case node.attributes[:size] do
      :xs -> 56
      :sm -> 72
      :lg -> 120
      :xl -> 140
      _ -> 96
    end
  end

  defp key_value_height(node) do
    case node.attributes[:size] do
      :xs -> 32
      :sm -> 40
      :lg -> 64
      _ -> 48
    end
  end

  defp info_list_height(node) do
    base = 32
    item_count = item_count(node)
    if item_count > 0 do
      base + min(item_count, 10) * 24
    else
      base + 24
    end
  end

  defp progress_height(node) do
    if node.attributes[:indeterminate] do
      8
    else
      case node.attributes[:size] do
        :xs -> 6
        :sm -> 8
        :lg -> 12
        _ -> 8
      end
    end
  end

  defp sparkline_height(node) do
    case node.attributes[:height] do
      h when is_integer(h) -> h
      :xs -> 24
      :sm -> 32
      :lg -> 64
      :xl -> 96
      _ -> 48
    end
  end

  defp scroll_bar_thickness(node) do
    case node.attributes[:thickness] do
      t when is_integer(t) -> t
      :xs -> 8
      :sm -> 10
      :lg -> 16
      :xl -> 20
      _ -> 12
    end
  end

  defp supervision_tree_height(node) do
    base = 80
    node_count = item_count(node)
    if node_count > 0 do
      base + min(node_count, 10) * 32
    else
      base + 32
    end
  end

  defp separator_thickness(node) do
    if node.attributes[:orientation] == :vertical, do: 1, else: 1
  end

  defp spacer_size(node) do
    case node.attributes[:size] do
      :xs -> 4
      :sm -> 8
      :lg -> 24
      :xl -> 32
      _ -> 16
    end
  end

  defp preferred_width(node, available_width) do
    cond do
      node.kind == :icon ->
        56

      node.kind == :badge ->
        badge_width(node)

      node.kind == :hero ->
        min(600, available_width)

      node.kind in [:button, :command, :window_command] ->
        min(180, available_width)

      node.kind == :link ->
        link_width(node, available_width)

      node.kind == :checkbox ->
        min(220, available_width)

      node.kind == :numeric_input ->
        min(180, available_width)

      node.kind == :slider ->
        if node.attributes[:orientation] == :vertical, do: 52, else: min(200, available_width)

      node.kind in [:text_input, :date_input, :time_input, :file_input] ->
        min(320, available_width)

      node.kind == :pick_list ->
        min(320, available_width)

      node.kind == :radio_group ->
        min(200, available_width)

      node.kind == :select ->
        min(240, available_width)

      node.kind == :stat ->
        stat_width(node, available_width)

      node.kind == :key_value ->
        min(200, available_width)

      node.kind == :info_list ->
        min(240, available_width)

      node.kind == :tree_view ->
        min(240, available_width)

      node.kind == :status ->
        min(120, available_width)

      node.kind == :progress ->
        min(160, available_width)

      node.kind == :inline_feedback ->
        min(240, available_width)

      node.kind == :stream_widget ->
        min(320, available_width)

      node.kind == :supervision_tree_viewer ->
        min(280, available_width)

      node.kind in [:text, :label] ->
        min(max(String.length(draw_content(node)) * 12, 96), available_width)

      node.kind == :separator ->
        available_width

      node.kind == :spacer ->
        spacer_size(node)

      true ->
        max(div(available_width, 2), 96)
    end
  end

  defp badge_width(node) do
    content_length = String.length(draw_content(node))
    base_width = content_length * 10 + 16

    case node.attributes[:size] do
      :sm -> max(32, base_width)
      :lg -> max(48, base_width + 8)
      _ -> max(40, base_width)
    end
  end

  defp link_width(node, available_width) do
    content_length = String.length(draw_content(node))
    min(max(content_length * 11, 64), available_width)
  end

  defp stat_width(node, available_width) do
    case node.attributes[:size] do
      :xs -> min(96, available_width)
      :sm -> min(128, available_width)
      :lg -> min(200, available_width)
      :xl -> min(240, available_width)
      _ -> min(160, available_width)
    end
  end

  defp option_count(node) do
    case node.attributes[:options] do
      nil -> 0
      opts when is_list(opts) -> length(opts)
      _ -> 3
    end
  end

  defp expandable_indexes(children) do
    children
    |> Enum.with_index()
    |> Enum.filter(fn {child, _index} -> child.kind in @fill_kinds end)
    |> Enum.map(&elem(&1, 1))
  end

  defp distribute_extra(_extra, []), do: %{}

  defp distribute_extra(extra, indexes) do
    per_child = div(extra, length(indexes))
    remainder = rem(extra, length(indexes))

    indexes
    |> Enum.with_index()
    |> Map.new(fn {index, offset} ->
      {index, per_child + if(offset < remainder, do: 1, else: 0)}
    end)
  end

  defp item_count(node),
    do:
      (node.attributes[:items] || node.attributes[:options] || node.attributes[:commands] ||
         node.attributes[:entries] || node.attributes[:processes] || node.attributes[:nodes] ||
         [])
      |> List.wrap()
      |> length()

  defp row_count(node),
    do:
      (node.attributes[:rows] || node.attributes[:entries] || node.attributes[:processes] || [])
      |> List.wrap()
      |> length()

  defp column_count(node),
    do:
      (node.attributes[:columns] || [])
      |> List.wrap()
      |> length()

  defp series_count(node),
    do:
      (node.attributes[:series] || [])
      |> List.wrap()
      |> length()

  defp current_index(node) do
    items =
      node.attributes[:items] || node.attributes[:options] || node.attributes[:commands] ||
        node.attributes[:rows] || []

    find_index(items, node.state[:current] || node.attributes[:current])
  end

  defp selected_index(node) do
    items =
      node.attributes[:items] || node.attributes[:options] || node.attributes[:rows] ||
        node.attributes[:processes] || node.attributes[:entries] || []

    find_index(items, node.state[:selected] || node.state[:checked])
  end

  defp find_index(_items, nil), do: -1

  defp find_index(items, target) do
    items
    |> List.wrap()
    |> Enum.find_index(fn
      %{id: id} -> id == target
      %{value: value} -> value == target
      %{label: label} -> label == target
      %{name: name} -> name == target
      other -> other == target
    end)
    |> case do
      nil -> -1
      index -> index
    end
  end

  defp truthy?(value), do: value not in [false, nil, :idle, :closed]

  defp numeric_value(node) do
    node.attributes[:value] || node.state[:value] || node.state[:progress] || 0
  end

  defp max_value(node) do
    node.attributes[:max] || node.attributes[:total] || 100
  end

  defp logical_bounds(index) do
    %{
      x: 56 + 48 * index,
      y: 48 + 36 * index,
      width: 1280,
      height: 800,
      units: :logical
    }
  end

  defp draw_bounds(node, window_index) do
    %{
      x: 24 * length(node.path),
      y: 20 * length(node.path) + 32 * window_index,
      width: 320,
      height: preferred_height(node),
      units: :logical
    }
  end

  defp gap_px(node) do
    node.attributes[:gap]
    |> case do
      value when is_integer(value) and value > 0 -> value
      _other -> 14
    end
  end

  defp padding_px(:none), do: 0
  defp padding_px(:xs), do: 6
  defp padding_px(:sm), do: 10
  defp padding_px(:md), do: 16
  defp padding_px(:lg), do: 24
  defp padding_px(value) when is_integer(value), do: value
  defp padding_px(_value), do: 8

  defp inset_bounds(bounds, left, top, right, bottom) do
    %{
      x: bounds.x + left,
      y: bounds.y + top,
      width: max(bounds.width - left - right, 32),
      height: max(bounds.height - top - bottom, 32),
      units: :logical
    }
  end

  defp centered_bounds(bounds, width_ratio, height_ratio) do
    width = max(round(bounds.width * width_ratio), 180)
    height = max(round(bounds.height * height_ratio), 140)

    %{
      x: bounds.x + div(bounds.width - width, 2),
      y: bounds.y + div(bounds.height - height, 2),
      width: min(width, bounds.width - 24),
      height: min(height, bounds.height - 24),
      units: :logical
    }
  end

  defp index_realized_nodes(node) do
    node
    |> flatten_realized_nodes([])
    |> Map.new(fn current -> {normalize_id(current.id), current} end)
  end

  defp flatten_realized_nodes(node, acc) do
    Enum.reduce(Map.get(node, :children, []), acc ++ [node], &flatten_realized_nodes(&1, &2))
  end

  defp index_source_widgets(widget) do
    widget
    |> flatten_source_widgets([])
    |> Map.new(fn current -> {normalize_id(current.id), current} end)
  end

  defp flatten_source_widgets(%Widget{} = widget, acc) do
    widget.children
    |> Enum.reduce(acc ++ [widget], fn child, child_acc ->
      flatten_source_widgets(child, child_acc)
    end)
  end

  defp source_stub(node) do
    %Widget{
      id: node.id,
      kind: node.kind,
      family: node.family,
      metadata: node.metadata,
      state: node.state,
      bindings: node.bindings,
      slot_children: %{default: []},
      attributes: node.attributes,
      styles: node.styles,
      events: Map.new(Enum.map(node.events, &{&1, %{}})),
      children: []
    }
  end

  defp normalize_id(nil), do: "anonymous"
  defp normalize_id(id) when is_binary(id), do: id
  defp normalize_id(id), do: to_string(id)
end
