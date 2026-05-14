defmodule DesktopUi.Layer do
  @moduledoc """
  Layered desktop runtime widgets for overlays, popovers, and multiwindow flows.
  """

  alias DesktopUi.Widget

  @kinds [:context_menu, :multi_window, :overlay, :popover]

  @spec kinds() :: [atom()]
  def kinds, do: @kinds

  @spec validation_state() :: map()
  def validation_state do
    %{
      layered_runtime: :ready,
      overlay_surfaces: :ready,
      multiwindow_coordination: :ready,
      bounded_platform_variation: :ready
    }
  end

  @spec overlay(String.t() | atom(), Widget.t(), [Widget.t()], keyword()) :: Widget.t()
  def overlay(id, content, overlays, opts \\ []) do
    Widget.new(:overlay,
      id: id,
      metadata:
        metadata(opts,
          role: :overlay,
          overlay_role: Keyword.get(opts, :overlay_role, :overlay),
          overlay_lifecycle: Keyword.get(opts, :overlay_lifecycle, :managed)
        ),
      attributes: %{stacking: Keyword.get(opts, :stacking, :managed)},
      slot_children: %{content: [content], overlay: overlays},
      styles: styles(opts)
    )
  end

  @spec context_menu(String.t() | atom(), Widget.t(), [map() | keyword()], keyword()) ::
          Widget.t()
  def context_menu(id, anchor, items, opts \\ []) do
    Widget.new(:context_menu,
      id: id,
      metadata:
        metadata(opts,
          role: :context_menu,
          overlay_role: :context_menu,
          overlay_lifecycle: Keyword.get(opts, :overlay_lifecycle, :managed)
        ),
      state: %{open: Keyword.get(opts, :open, true)},
      attributes: %{
        items: normalize_items(items),
        position: Keyword.get(opts, :position, :anchor)
      },
      slot_children: %{anchor: [anchor]},
      events:
        events(
          selection: Keyword.get(opts, :on_select),
          close: Keyword.get(opts, :on_close)
        ),
      styles: styles(opts)
    )
  end

  @spec popover(String.t() | atom(), Widget.t(), Widget.t(), keyword()) :: Widget.t()
  def popover(id, anchor, content, opts \\ []) do
    Widget.new(:popover,
      id: id,
      metadata:
        metadata(opts,
          role: :popover,
          overlay_role: :popover,
          overlay_lifecycle: Keyword.get(opts, :overlay_lifecycle, :managed)
        ),
      state: %{open: Keyword.get(opts, :open, true)},
      slot_children: %{anchor: [anchor], content: [content]},
      events: events(close: Keyword.get(opts, :on_close)),
      styles: styles(opts)
    )
  end

  @spec multi_window(String.t() | atom(), [Widget.t()], keyword()) :: Widget.t()
  def multi_window(id, windows, opts \\ []) do
    Widget.new(:multi_window,
      id: id,
      metadata:
        metadata(opts,
          role: :multi_window,
          window_identity: Keyword.get(opts, :window_identity, id),
          interaction_route: Keyword.get(opts, :interaction_route, :multi_window)
        ),
      attributes: %{continuity: Keyword.get(opts, :continuity, :shared_runtime)},
      children: windows,
      styles: styles(opts)
    )
  end

  defp metadata(opts, defaults),
    do: defaults |> Keyword.merge(Keyword.get(opts, :metadata, [])) |> Map.new()

  defp events(entries),
    do: entries |> Enum.reject(fn {_key, value} -> is_nil(value) end) |> Map.new()

  defp styles(opts), do: Map.new(Keyword.get(opts, :styles, []))

  defp normalize_items(items), do: Enum.map(List.wrap(items), &normalize_item/1)
  defp normalize_item(item) when is_list(item), do: Enum.into(item, %{})
  defp normalize_item(item) when is_map(item), do: Map.new(item)
end
