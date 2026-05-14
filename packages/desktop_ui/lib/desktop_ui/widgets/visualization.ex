defmodule DesktopUi.Widgets.Visualization do
  @moduledoc """
  Advanced visualization widgets for direct-native `desktop_ui`.
  """

  alias DesktopUi.Widget

  @spec kinds() :: [atom()]
  def kinds do
    [:bar_chart, :canvas, :gauge, :line_chart, :timeline]
  end

  @spec gauge(String.t() | atom(), keyword()) :: Widget.t()
  def gauge(id, opts \\ []) do
    Widget.new(:gauge,
      id: id,
      metadata: metadata(opts, role: :gauge),
      state:
        state(opts, value: Keyword.get(opts, :value), severity: Keyword.get(opts, :severity)),
      bindings: bindings(value: Keyword.get(opts, :binding)),
      attributes: %{
        value: Keyword.get(opts, :value),
        min: Keyword.get(opts, :min, 0),
        max: Keyword.get(opts, :max, 100),
        label: Keyword.get(opts, :label)
      },
      styles: styles(opts)
    )
  end

  @spec bar_chart(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def bar_chart(id, series, opts \\ []) do
    chart(:bar_chart, id, series, opts)
  end

  @spec line_chart(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def line_chart(id, series, opts \\ []) do
    chart(:line_chart, id, series, opts)
  end

  @spec timeline(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def timeline(id, items, opts \\ []) do
    Widget.new(:timeline,
      id: id,
      metadata: metadata(opts, role: :timeline),
      attributes: %{events: normalize_items(items), mode: Keyword.get(opts, :mode, :relative)},
      styles: styles(opts)
    )
  end

  @spec canvas(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def canvas(id, operations, opts \\ []) do
    Widget.new(:canvas,
      id: id,
      metadata:
        metadata(opts,
          role: :canvas,
          positioning_mode: Keyword.get(opts, :positioning_mode, :absolute)
        ),
      attributes: %{
        width: Keyword.get(opts, :width),
        height: Keyword.get(opts, :height),
        operations: normalize_items(operations)
      },
      events: events(selection: Keyword.get(opts, :on_select)),
      styles: styles(opts)
    )
  end

  defp chart(kind, id, series, opts) do
    Widget.new(kind,
      id: id,
      metadata: metadata(opts, role: kind),
      attributes: %{series: normalize_items(series), axes: Keyword.get(opts, :axes, %{})},
      styles: styles(opts)
    )
  end

  defp metadata(opts, defaults),
    do: defaults |> Keyword.merge(Keyword.get(opts, :metadata, [])) |> Map.new()

  defp state(opts, defaults),
    do:
      defaults
      |> Keyword.merge(disabled: Keyword.get(opts, :disabled, false), focused: false)
      |> Map.new()

  defp bindings(entries), do: entries |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()
  defp events(entries), do: entries |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()
  defp styles(opts), do: Map.new(Keyword.get(opts, :styles, []))
  defp normalize_items(items), do: Enum.map(List.wrap(items), &normalize_item/1)
  defp normalize_item(item) when is_list(item), do: Enum.into(item, %{})
  defp normalize_item(item) when is_map(item), do: Map.new(item)
end
