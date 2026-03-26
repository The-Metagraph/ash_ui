defmodule UnifiedIUR.Canvas do
  @moduledoc """
  Canonical canvas and visualization constructors for advanced display
  composition in `UnifiedIUR`.
  """

  alias UnifiedIUR.Attachment
  alias UnifiedIUR.Element
  alias UnifiedIUR.Metadata

  @kinds [:canvas, :sparkline, :bar_chart, :line_chart]

  @spec kinds() :: [atom()]
  def kinds do
    @kinds
  end

  @spec surface([map() | keyword()], keyword() | map()) :: Element.t()
  def surface(operations \\ [], opts \\ []) when is_list(operations) do
    opts = normalize_opts(opts)

    Element.new(:widget, :canvas,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          canvas:
            %{}
            |> maybe_put(:width, option(opts, :width))
            |> maybe_put(:height, option(opts, :height))
            |> maybe_put(:unit, option(opts, :unit, :cell))
            |> maybe_put(:background, option(opts, :background))
            |> maybe_put(:clip?, option(opts, :clip?, true))
            |> maybe_put(:operations, normalize_operations(operations))
        }
        |> Attachment.merge(opts, component: :canvas),
      children: []
    )
  end

  @spec sparkline([number()], keyword() | map()) :: Element.t()
  def sparkline(series, opts \\ []) when is_list(series) do
    opts = normalize_opts(opts)

    chart(:sparkline, [%{id: option(opts, :series_id, :primary), values: series}], opts)
  end

  @spec bar_chart([map() | keyword()], keyword() | map()) :: Element.t()
  def bar_chart(series, opts \\ []) when is_list(series) do
    chart(:bar_chart, normalize_series(series), opts)
  end

  @spec line_chart([map() | keyword()], keyword() | map()) :: Element.t()
  def line_chart(series, opts \\ []) when is_list(series) do
    chart(:line_chart, normalize_series(series), opts)
  end

  defp chart(kind, series, opts) do
    opts = normalize_opts(opts)

    Element.new(:widget, kind,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          chart:
            %{}
            |> maybe_put(:series, series)
            |> maybe_put(:axes, normalize_axes(option(opts, :axes, %{})))
            |> maybe_put(:legend, normalize_legend(option(opts, :legend, %{})))
            |> maybe_put(:scale, normalize_scale(option(opts, :scale, %{})))
        }
        |> Attachment.merge(opts, component: kind),
      children: []
    )
  end

  defp normalize_operations(operations) do
    Enum.map(operations, fn operation ->
      operation = normalize_opts(operation)
      kind = option(operation, :kind)

      %{}
      |> maybe_put(:kind, kind)
      |> maybe_put(:position, normalize_position(option(operation, :position)))
      |> maybe_put(:size, normalize_position(option(operation, :size)))
      |> maybe_put(:text, option(operation, :text))
      |> maybe_put(:points, option(operation, :points))
      |> maybe_put(:style_refs, option(operation, :style_refs))
      |> maybe_put(:metadata, normalize_map(option(operation, :metadata, %{})))
    end)
  end

  defp normalize_series(series) do
    Enum.map(series, fn item ->
      item = normalize_opts(item)

      %{}
      |> maybe_put(:id, option(item, :id))
      |> maybe_put(:label, option(item, :label))
      |> maybe_put(:values, option(item, :values))
      |> maybe_put(:color, option(item, :color))
      |> maybe_put(:stack, option(item, :stack))
    end)
  end

  defp normalize_axes(axes) do
    axes
    |> normalize_map()
    |> maybe_put(:x, normalize_axis(Map.get(axes, :x, Map.get(axes, "x"))))
    |> maybe_put(:y, normalize_axis(Map.get(axes, :y, Map.get(axes, "y"))))
  end

  defp normalize_axis(nil), do: nil

  defp normalize_axis(axis) do
    axis = normalize_map(axis)

    %{}
    |> maybe_put(:label, Map.get(axis, :label, Map.get(axis, "label")))
    |> maybe_put(:min, Map.get(axis, :min, Map.get(axis, "min")))
    |> maybe_put(:max, Map.get(axis, :max, Map.get(axis, "max")))
    |> maybe_put(:ticks, Map.get(axis, :ticks, Map.get(axis, "ticks")))
  end

  defp normalize_legend(legend) do
    legend
    |> normalize_map()
    |> maybe_put(:visible?, Map.get(legend, :visible?, Map.get(legend, "visible?")))
    |> maybe_put(:position, Map.get(legend, :position, Map.get(legend, "position")))
  end

  defp normalize_scale(scale) do
    scale
    |> normalize_map()
    |> maybe_put(:x, Map.get(scale, :x, Map.get(scale, "x")))
    |> maybe_put(:y, Map.get(scale, :y, Map.get(scale, "y")))
  end

  defp normalize_position(nil), do: nil

  defp normalize_position({x, y}) do
    %{x: x, y: y}
  end

  defp normalize_position(position) when is_map(position) do
    %{
      x: Map.get(position, :x, Map.get(position, "x")),
      y: Map.get(position, :y, Map.get(position, "y"))
    }
  end

  defp normalize_metadata(opts) do
    opts
    |> option(:metadata)
    |> Metadata.merge(%{
      description: option(opts, :description),
      annotations: option(opts, :annotations, %{}),
      tags: option(opts, :tags, [])
    })
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
