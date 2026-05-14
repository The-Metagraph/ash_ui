defmodule ElmUi.Widgets.Layout do
  @moduledoc """
  Native layout and display-system widgets used by direct-native and canonical
  `elm_ui` flows.
  """

  alias ElmUi.Widgets.Builder

  @kinds [:stack, :panel, :row, :column, :grid, :viewport, :scroll_bar, :split_pane]

  @spec kinds() :: [atom()]
  def kinds, do: @kinds

  @spec stack(String.t() | atom(), [ElmUi.Widget.t() | map() | keyword()], keyword() | map()) ::
          ElmUi.Widget.t()
  def stack(id, children, opts \\ []) when is_list(children) do
    opts = Builder.options(opts)

    Builder.widget(:stack,
      id: id,
      attributes: %{
        direction: Builder.option(opts, :direction, :column),
        gap: Builder.option(opts, :gap)
      },
      slot_children: %{default: Builder.children!(children)},
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :layout})
    )
  end

  @spec panel(
          String.t() | atom(),
          String.t(),
          [ElmUi.Widget.t() | map() | keyword()],
          keyword() | map()
        ) ::
          ElmUi.Widget.t()
  def panel(id, title, children, opts \\ []) when is_list(children) do
    opts = Builder.options(opts)

    Builder.widget(:panel,
      id: id,
      attributes: %{
        title: title,
        tone: Builder.option(opts, :tone, :default)
      },
      slot_children: %{default: Builder.children!(children)},
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :layout, role: :panel})
    )
  end

  @spec row(String.t() | atom(), [ElmUi.Widget.t() | map() | keyword()], keyword() | map()) ::
          ElmUi.Widget.t()
  def row(id, children, opts \\ []) when is_list(children) do
    build_linear(:row, id, children, opts, :horizontal)
  end

  @spec column(String.t() | atom(), [ElmUi.Widget.t() | map() | keyword()], keyword() | map()) ::
          ElmUi.Widget.t()
  def column(id, children, opts \\ []) when is_list(children) do
    build_linear(:column, id, children, opts, :vertical)
  end

  @spec grid(String.t() | atom(), [ElmUi.Widget.t() | map() | keyword()], keyword() | map()) ::
          ElmUi.Widget.t()
  def grid(id, children, opts \\ []) when is_list(children) do
    opts = Builder.options(opts)

    Builder.widget(:grid,
      id: id,
      attributes: %{
        columns: Builder.option(opts, :columns),
        rows: Builder.option(opts, :rows),
        auto_flow: Builder.option(opts, :auto_flow, :row),
        gap: Builder.option(opts, :gap),
        align: Builder.option(opts, :align),
        justify: Builder.option(opts, :justify)
      },
      slot_children: %{default: Builder.children!(children)},
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :layout, display_system: true})
    )
  end

  @spec viewport(String.t() | atom(), ElmUi.Widget.t() | map() | keyword(), keyword() | map()) ::
          ElmUi.Widget.t()
  def viewport(id, content, opts \\ []) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))
    validate_viewport_opts!(opts)

    Builder.widget(:viewport,
      id: id,
      attributes: %{
        axis: Builder.option(opts, :axis, :vertical),
        offset: normalize_offset(Builder.option(opts, :offset, 0)),
        clip: Builder.option(opts, :clip, true),
        scrollbars: Builder.option(opts, :scrollbars, :auto),
        width: Builder.option(opts, :width),
        height: Builder.option(opts, :height),
        sync_group: Builder.option(opts, :sync_group),
        independent_scroll: Builder.option(opts, :independent_scroll, false)
      },
      slot_children: Builder.slot_map([{:content, content}]),
      state: Builder.state(opts, [:disabled, :focused, :scrolled]),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_scroll: :scroll),
      metadata: Builder.metadata(opts, %{native_surface: :layout, display_system: true})
    )
  end

  @spec scroll_bar(String.t() | atom(), keyword() | map()) :: ElmUi.Widget.t()
  def scroll_bar(id, opts \\ []) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))
    validate_scroll_bar_opts!(opts)

    Builder.widget(:scroll_bar,
      id: id,
      attributes: %{
        orientation: Builder.option(opts, :orientation, :vertical),
        position: normalize_position(Builder.option(opts, :position, 0)),
        viewport_size: Builder.option(opts, :viewport_size),
        content_size: Builder.option(opts, :content_size),
        viewport_ref: Builder.option(opts, :viewport_ref),
        sync_group: Builder.option(opts, :sync_group)
      },
      state: Builder.state(opts, [:disabled, :focused, :scrolled]),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_scroll: :scroll),
      metadata: Builder.metadata(opts, %{native_surface: :layout, display_system: true})
    )
  end

  @spec split_pane(
          String.t() | atom(),
          ElmUi.Widget.t() | map() | keyword(),
          ElmUi.Widget.t() | map() | keyword(),
          keyword() | map()
        ) :: ElmUi.Widget.t()
  def split_pane(id, primary, secondary, opts \\ []) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))
    primary = Builder.child!(primary)
    secondary = Builder.child!(secondary)
    ratio = Builder.option(opts, :ratio, 0.5)

    validate_ratio!(ratio)
    validate_split_scroll_sync!(primary, secondary, opts)

    Builder.widget(:split_pane,
      id: id,
      attributes: %{
        direction: Builder.option(opts, :direction, :horizontal),
        ratio: ratio,
        resizable: Builder.option(opts, :resizable, true),
        min_primary: Builder.option(opts, :min_primary),
        min_secondary: Builder.option(opts, :min_secondary),
        primary_size: Builder.option(opts, :primary_size),
        secondary_size: Builder.option(opts, :secondary_size),
        divider: normalize_divider(opts),
        sync_scroll: Builder.option(opts, :sync_scroll, false)
      },
      slot_children:
        Builder.slot_map([
          {:primary, primary},
          {:secondary, secondary}
        ]),
      state: Builder.state(opts, [:disabled, :focused]),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_resize: :resize),
      metadata: Builder.metadata(opts, %{native_surface: :layout, display_system: true})
    )
  end

  defp build_linear(kind, id, children, opts, direction) do
    opts = Builder.options(opts)

    Builder.widget(kind,
      id: id,
      attributes: %{
        direction: direction,
        gap: Builder.option(opts, :gap),
        align: Builder.option(opts, :align),
        justify: Builder.option(opts, :justify)
      },
      slot_children: %{default: Builder.children!(children)},
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :layout})
    )
  end

  defp validate_viewport_opts!(opts) do
    if Builder.option(opts, :independent_scroll, false) and
         not is_nil(Builder.option(opts, :sync_group)) do
      raise ArgumentError,
            "elm_ui viewport widgets cannot declare :independent_scroll and :sync_group together"
    end
  end

  defp validate_scroll_bar_opts!(opts) do
    if is_nil(Builder.option(opts, :viewport_ref)) and is_nil(Builder.option(opts, :sync_group)) do
      raise ArgumentError,
            "elm_ui scroll_bar widgets require either :viewport_ref or :sync_group"
    end
  end

  defp validate_ratio!(ratio) when is_number(ratio) and ratio > 0 and ratio < 1, do: :ok

  defp validate_ratio!(_ratio) do
    raise ArgumentError, "elm_ui split_pane widgets require a :ratio between 0 and 1"
  end

  defp validate_split_scroll_sync!(primary, secondary, opts) do
    if Builder.option(opts, :sync_scroll, false) and
         Enum.any?([primary, secondary], &(&1.kind != :viewport)) do
      raise ArgumentError,
            "elm_ui split_pane widgets require both panes to be :viewport widgets when :sync_scroll is true"
    end
  end

  defp normalize_offset(value) when is_integer(value), do: %{x: 0, y: value}
  defp normalize_offset({x, y}) when is_integer(x) and is_integer(y), do: %{x: x, y: y}

  defp normalize_offset(value) when is_map(value) or is_list(value) do
    value = Builder.options(value)

    %{
      x: Builder.option(value, :x, 0),
      y: Builder.option(value, :y, 0)
    }
  end

  defp normalize_offset(_value) do
    raise ArgumentError,
          "elm_ui viewport widgets require :offset to be an integer, {x, y}, or map-like coordinates"
  end

  defp normalize_position(value) when is_number(value), do: %{start: value, end: value}

  defp normalize_position({start_pos, end_pos})
       when is_number(start_pos) and is_number(end_pos) do
    %{start: start_pos, end: end_pos}
  end

  defp normalize_position(value) when is_map(value) or is_list(value) do
    value = Builder.options(value)

    %{}
    |> Builder.maybe_put(:start, Builder.option(value, :start))
    |> Builder.maybe_put(:end, Builder.option(value, :end))
  end

  defp normalize_position(_value) do
    raise ArgumentError,
          "elm_ui scroll_bar widgets require :position to be numeric, {start, end}, or map-like"
  end

  defp normalize_divider(opts) do
    divider =
      opts
      |> Builder.option(:divider, %{})
      |> Builder.options()

    %{}
    |> Builder.maybe_put(
      :size,
      Builder.option(divider, :size, Builder.option(opts, :divider_size))
    )
    |> Builder.maybe_put(
      :style,
      Builder.option(divider, :style, Builder.option(opts, :divider_style))
    )
  end
end
