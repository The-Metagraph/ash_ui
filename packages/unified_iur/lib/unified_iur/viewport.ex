defmodule UnifiedIUR.Viewport do
  @moduledoc """
  Canonical viewport, scroll-bar, and split-region constructors for advanced
  display semantics in `UnifiedIUR`.
  """

  alias UnifiedIUR.Attachment
  alias UnifiedIUR.Element
  alias UnifiedIUR.Element.Child

  @kinds [:viewport, :scroll_bar, :split_pane]

  @spec kinds() :: [atom()]
  def kinds do
    @kinds
  end

  @spec region(Element.t(), keyword() | map()) :: Element.t()
  def region(%Element{} = content, opts \\ []) do
    opts = normalize_opts(opts)

    Element.new(:layout, :viewport,
      id: option(opts, :id),
      metadata: option(opts, :metadata),
      attributes:
        %{
          viewport:
            %{}
            |> maybe_put(:axis, option(opts, :axis, :vertical))
            |> maybe_put(:offset, normalize_offset(option(opts, :offset, 0)))
            |> maybe_put(:clip?, option(opts, :clip?, true))
            |> maybe_put(:scrollbars, option(opts, :scrollbars, :auto))
            |> maybe_put(:width, option(opts, :width))
            |> maybe_put(:height, option(opts, :height))
            |> maybe_put(:sync_group, option(opts, :sync_group))
            |> maybe_put(:independent_scroll?, option(opts, :independent_scroll?))
        }
        |> Attachment.merge(opts, component: :viewport),
      children: [Child.new(:content, content)]
    )
  end

  @spec scroll_bar(keyword() | map()) :: Element.t()
  def scroll_bar(opts \\ []) do
    opts = normalize_opts(opts)

    Element.new(:widget, :scroll_bar,
      id: option(opts, :id),
      metadata: option(opts, :metadata),
      attributes:
        %{
          scroll_bar:
            %{}
            |> maybe_put(:orientation, option(opts, :orientation, :vertical))
            |> maybe_put(:position, normalize_scroll_position(option(opts, :position, 0)))
            |> maybe_put(:viewport_size, option(opts, :viewport_size))
            |> maybe_put(:content_size, option(opts, :content_size))
            |> maybe_put(:viewport_ref, option(opts, :viewport_ref))
            |> maybe_put(:sync_group, option(opts, :sync_group))
        }
        |> Attachment.merge(opts, component: :scroll_bar),
      children: []
    )
  end

  @spec split_pane(Element.t(), Element.t(), keyword() | map()) :: Element.t()
  def split_pane(%Element{} = primary, %Element{} = secondary, opts \\ []) do
    opts = normalize_opts(opts)

    Element.new(:layout, :split_pane,
      id: option(opts, :id),
      metadata: option(opts, :metadata),
      attributes:
        %{
          split:
            %{}
            |> maybe_put(:direction, option(opts, :direction, :horizontal))
            |> maybe_put(:ratio, option(opts, :ratio, 0.5))
            |> maybe_put(:resizable?, option(opts, :resizable?, true))
            |> maybe_put(:min_primary, option(opts, :min_primary))
            |> maybe_put(:min_secondary, option(opts, :min_secondary))
            |> maybe_put(:primary_size, option(opts, :primary_size))
            |> maybe_put(:secondary_size, option(opts, :secondary_size))
            |> maybe_put(
              :divider,
              normalize_divider(
                option(opts, :divider, %{}),
                option(opts, :divider_size),
                option(opts, :divider_style)
              )
            )
            |> maybe_put(:sync_scroll, option(opts, :sync_scroll))
        }
        |> Attachment.merge(opts, component: :split_pane),
      children: [
        Child.new(:primary, primary),
        Child.new(:secondary, secondary)
      ]
    )
  end

  defp normalize_offset(value) when is_integer(value) do
    %{x: 0, y: value}
  end

  defp normalize_offset({x, y}) when is_integer(x) and is_integer(y) do
    %{x: x, y: y}
  end

  defp normalize_offset(value) when is_map(value) do
    %{
      x: Map.get(value, :x, Map.get(value, "x", 0)),
      y: Map.get(value, :y, Map.get(value, "y", 0))
    }
  end

  defp normalize_scroll_position(value) when is_number(value) do
    %{start: value, end: value}
  end

  defp normalize_scroll_position({start_pos, end_pos})
       when is_number(start_pos) and is_number(end_pos) do
    %{start: start_pos, end: end_pos}
  end

  defp normalize_scroll_position(value), do: value

  defp normalize_divider(divider, divider_size, divider_style) do
    divider
    |> normalize_map()
    |> maybe_put(:size, divider_size)
    |> maybe_put(:style, divider_style)
  end

  defp normalize_map(nil), do: %{}
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp normalize_opts(opts) when is_list(opts), do: Enum.into(opts, %{})
  defp normalize_opts(opts) when is_map(opts), do: Map.new(opts)

  defp option(opts, key, default \\ nil) do
    Map.get(opts, key, Map.get(opts, Atom.to_string(key), default))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
