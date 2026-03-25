defmodule UnifiedIUR.Layout do
  @moduledoc """
  Canonical directional, grid, split, and scroll-oriented layout constructors
  for `UnifiedIUR`.
  """

  alias UnifiedIUR.Attachment
  alias UnifiedIUR.Element
  alias UnifiedIUR.Element.Child
  alias UnifiedIUR.Viewport

  @type child_input ::
          Child.t()
          | Element.t()
          | {Child.slot(), Element.t() | nil}
          | %{required(:slot) => Child.slot(), required(:element) => Element.t() | nil}
          | %{required(String.t()) => term()}

  @kinds [:row, :column, :stack, :grid, :split_pane, :viewport, :scroll_bar]

  @spec kinds() :: [atom()]
  def kinds do
    @kinds
  end

  @spec row([child_input()], keyword() | map()) :: Element.t()
  def row(children \\ [], opts \\ []) when is_list(children) do
    build_layout(:row, children, opts, %{direction: :horizontal})
  end

  @spec column([child_input()], keyword() | map()) :: Element.t()
  def column(children \\ [], opts \\ []) when is_list(children) do
    build_layout(:column, children, opts, %{direction: :vertical})
  end

  @spec stack([child_input()], keyword() | map()) :: Element.t()
  def stack(children \\ [], opts \\ []) when is_list(children) do
    opts = normalize_opts(opts)

    build_layout(:stack, children, opts, %{
      stacking: option(opts, :stacking, :overlay)
    })
  end

  @spec grid([child_input()], keyword() | map()) :: Element.t()
  def grid(children \\ [], opts \\ []) when is_list(children) do
    opts = normalize_opts(opts)

    build_layout(:grid, children, opts, %{
      columns: option(opts, :columns),
      rows: option(opts, :rows),
      auto_flow: option(opts, :auto_flow, :row)
    })
  end

  @spec split_pane(Element.t(), Element.t(), keyword() | map()) :: Element.t()
  def split_pane(%Element{} = primary, %Element{} = secondary, opts \\ []) do
    Viewport.split_pane(primary, secondary, opts)
  end

  @spec scroll_region(Element.t(), keyword() | map()) :: Element.t()
  def scroll_region(%Element{} = content, opts \\ []) do
    Viewport.region(content, opts)
  end

  @spec scroll_bar(keyword() | map()) :: Element.t()
  def scroll_bar(opts \\ []) do
    Viewport.scroll_bar(opts)
  end

  defp build_layout(kind, children, opts, specific_attributes) do
    opts = normalize_opts(opts)

    Element.new(:layout, kind,
      id: option(opts, :id),
      metadata: option(opts, :metadata),
      attributes:
        %{
          layout:
            %{}
            |> maybe_put(:gap, option(opts, :gap))
            |> maybe_put(:padding, option(opts, :padding))
            |> maybe_put(:align, option(opts, :align))
            |> maybe_put(:justify, option(opts, :justify))
            |> maybe_put(:width, option(opts, :width))
            |> maybe_put(:height, option(opts, :height))
            |> maybe_put(:min_width, option(opts, :min_width))
            |> maybe_put(:max_width, option(opts, :max_width))
            |> maybe_put(:min_height, option(opts, :min_height))
            |> maybe_put(:max_height, option(opts, :max_height))
            |> maybe_put(:order, option(opts, :order))
            |> Map.merge(
              Enum.reject(specific_attributes, fn {_key, value} -> is_nil(value) end)
              |> Map.new()
            )
        }
        |> Attachment.merge(opts, component: kind),
      children: children
    )
  end

  defp normalize_opts(opts) when is_list(opts), do: Enum.into(opts, %{})
  defp normalize_opts(opts) when is_map(opts), do: Map.new(opts)

  defp option(opts, key, default \\ nil) do
    Map.get(opts, key, Map.get(opts, Atom.to_string(key), default))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
