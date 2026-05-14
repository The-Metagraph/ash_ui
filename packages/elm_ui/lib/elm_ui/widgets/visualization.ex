defmodule ElmUi.Widgets.Visualization do
  @moduledoc """
  Advanced charting and canvas widgets for direct-use `elm_ui` dashboards.
  """

  alias ElmUi.Widgets.Builder

  @kinds [:gauge, :sparkline, :bar_chart, :line_chart, :canvas]

  @spec kinds() :: [atom()]
  def kinds, do: @kinds

  @spec gauge(String.t() | atom(), keyword() | map()) :: ElmUi.Widget.t()
  def gauge(id, opts \\ []) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:gauge,
      id: id,
      attributes: %{
        value: Builder.option(opts, :value),
        min: Builder.option(opts, :min, 0),
        max: Builder.option(opts, :max, 100),
        label: Builder.option(opts, :label),
        severity: Builder.option(opts, :severity),
        status: Builder.option(opts, :status)
      },
      state: Builder.state(opts, [:disabled, :loading]),
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :visualization})
    )
  end

  @spec sparkline(String.t() | atom(), [number()], keyword() | map()) :: ElmUi.Widget.t()
  def sparkline(id, series, opts \\ []) when is_list(series) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:sparkline,
      id: id,
      attributes: %{
        series: [%{id: Builder.option(opts, :series_id, :primary), values: series}],
        axes: normalize_axes(Builder.option(opts, :axes, %{})),
        legend: normalize_legend(Builder.option(opts, :legend, %{})),
        scale: normalize_scale(Builder.option(opts, :scale, %{}))
      },
      state: Builder.state(opts, [:disabled, :loading]),
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :visualization})
    )
  end

  @spec bar_chart(String.t() | atom(), [keyword() | map()], keyword() | map()) ::
          ElmUi.Widget.t()
  def bar_chart(id, series, opts \\ []) when is_list(series) do
    chart(:bar_chart, id, series, opts)
  end

  @spec line_chart(String.t() | atom(), [keyword() | map()], keyword() | map()) ::
          ElmUi.Widget.t()
  def line_chart(id, series, opts \\ []) when is_list(series) do
    chart(:line_chart, id, series, opts)
  end

  @spec canvas(String.t() | atom(), [keyword() | map()], keyword() | map()) :: ElmUi.Widget.t()
  def canvas(id, operations, opts \\ []) when is_list(operations) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:canvas,
      id: id,
      attributes: %{
        width: Builder.option(opts, :width),
        height: Builder.option(opts, :height),
        unit: Builder.option(opts, :unit, :cell),
        background: Builder.option(opts, :background),
        clip: Builder.option(opts, :clip, true),
        operations: normalize_operations(operations)
      },
      state: Builder.state(opts, [:disabled, :loading]),
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :visualization})
    )
  end

  defp chart(kind, id, series, opts) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(kind,
      id: id,
      attributes: %{
        series: normalize_series(series),
        axes: normalize_axes(Builder.option(opts, :axes, %{})),
        legend: normalize_legend(Builder.option(opts, :legend, %{})),
        scale: normalize_scale(Builder.option(opts, :scale, %{}))
      },
      state: Builder.state(opts, [:disabled, :loading]),
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :visualization})
    )
  end

  defp normalize_operations(operations) do
    Enum.map(operations, fn operation ->
      operation = Builder.options(operation)

      %{}
      |> Builder.maybe_put(:kind, Builder.option(operation, :kind))
      |> Builder.maybe_put(:position, normalize_position(Builder.option(operation, :position)))
      |> Builder.maybe_put(:size, normalize_position(Builder.option(operation, :size)))
      |> Builder.maybe_put(:text, Builder.option(operation, :text))
      |> Builder.maybe_put(:points, Builder.option(operation, :points))
      |> Builder.maybe_put(:style_refs, Builder.option(operation, :style_refs))
      |> Builder.maybe_put(:metadata, Builder.option(operation, :metadata))
    end)
  end

  defp normalize_series(series) do
    Enum.map(series, fn item ->
      item = Builder.options(item)

      %{}
      |> Builder.maybe_put(:id, Builder.option(item, :id))
      |> Builder.maybe_put(:label, Builder.option(item, :label))
      |> Builder.maybe_put(:values, Builder.option(item, :values))
      |> Builder.maybe_put(:color, Builder.option(item, :color))
      |> Builder.maybe_put(:stack, Builder.option(item, :stack))
    end)
  end

  defp normalize_axes(axes) do
    axes = Builder.options(axes)

    %{}
    |> Builder.maybe_put(:x, normalize_axis(Builder.option(axes, :x)))
    |> Builder.maybe_put(:y, normalize_axis(Builder.option(axes, :y)))
  end

  defp normalize_axis(nil), do: nil

  defp normalize_axis(axis) do
    axis = Builder.options(axis)

    %{}
    |> Builder.maybe_put(:label, Builder.option(axis, :label))
    |> Builder.maybe_put(:min, Builder.option(axis, :min))
    |> Builder.maybe_put(:max, Builder.option(axis, :max))
    |> Builder.maybe_put(:ticks, Builder.option(axis, :ticks))
  end

  defp normalize_legend(legend) do
    legend = Builder.options(legend)

    %{}
    |> Builder.maybe_put(:visible, Builder.option(legend, :visible))
    |> Builder.maybe_put(:position, Builder.option(legend, :position))
  end

  defp normalize_scale(scale) do
    scale = Builder.options(scale)

    %{}
    |> Builder.maybe_put(:x, Builder.option(scale, :x))
    |> Builder.maybe_put(:y, Builder.option(scale, :y))
  end

  defp normalize_position(nil), do: nil
  defp normalize_position({x, y}), do: %{x: x, y: y}

  defp normalize_position(position) when is_map(position) or is_list(position) do
    position = Builder.options(position)

    %{
      x: Builder.option(position, :x),
      y: Builder.option(position, :y)
    }
  end
end
