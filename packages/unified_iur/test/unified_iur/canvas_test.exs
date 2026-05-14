defmodule UnifiedIUR.CanvasTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Canvas
  alias UnifiedIUR.Container
  alias UnifiedIUR.Element
  alias UnifiedIUR.Layer
  alias UnifiedIUR.Layout
  alias UnifiedIUR.Widgets.Foundational

  test "exposes canonical canvas and visualization kinds" do
    assert [:canvas, :sparkline, :bar_chart, :line_chart] == Canvas.kinds()
  end

  test "builds canvas surfaces with positioned renderer-independent operations" do
    canvas =
      Canvas.surface(
        [
          [kind: :cell, position: {1, 2}, text: "A", style_refs: [:accent]],
          [kind: :fragment, position: %{x: 4, y: 8}, size: {10, 2}, text: "Status"]
        ],
        id: "main-canvas",
        width: 80,
        height: 24,
        background: :surface
      )

    assert %Element{
             kind: :canvas,
             attributes: %{
               canvas: %{
                 width: 80,
                 height: 24,
                 unit: :cell,
                 background: :surface,
                 clip?: true,
                 operations: [
                   %{kind: :cell, position: %{x: 1, y: 2}, text: "A", style_refs: [:accent]},
                   %{
                     kind: :fragment,
                     position: %{x: 4, y: 8},
                     size: %{x: 10, y: 2},
                     text: "Status"
                   }
                 ]
               }
             }
           } = canvas
  end

  test "builds sparkline, bar chart, and line chart constructs with shared chart metadata" do
    sparkline = Canvas.sparkline([1, 2, 3, 2], id: "latency-sparkline")

    bar_chart =
      Canvas.bar_chart(
        [
          [id: :requests, label: "Requests", values: [10, 20, 15], color: :blue]
        ],
        id: "requests-chart",
        axes: %{x: %{label: "Minute"}, y: %{label: "Count", min: 0}},
        legend: %{visible?: true, position: :bottom}
      )

    line_chart =
      Canvas.line_chart(
        [
          [id: :cpu, label: "CPU", values: [20, 40, 35], color: :red]
        ],
        id: "cpu-chart",
        scale: %{x: :linear, y: :percentage}
      )

    assert %Element{
             kind: :sparkline,
             attributes: %{chart: %{series: [%{id: :primary, values: [1, 2, 3, 2]}]}}
           } =
             sparkline

    assert %Element{
             kind: :bar_chart,
             attributes: %{
               chart: %{
                 series: [%{id: :requests, label: "Requests", values: [10, 20, 15], color: :blue}],
                 axes: %{x: %{label: "Minute"}, y: %{label: "Count", min: 0}},
                 legend: %{visible?: true, position: :bottom}
               }
             }
           } = bar_chart

    assert %Element{
             kind: :line_chart,
             attributes: %{chart: %{scale: %{x: :linear, y: :percentage}}}
           } = line_chart
  end

  test "canvas and chart constructs compose with layout and overlay structures" do
    chart = Canvas.line_chart([[id: :cpu, values: [10, 20, 30]]], id: "cpu-chart")

    canvas =
      Canvas.surface([[kind: :fragment, position: {0, 0}, text: "Overlay"]], id: "overlay-canvas")

    layout =
      Layout.column(
        [
          {:content, chart},
          {:content, canvas}
        ],
        id: "visualization-column"
      )

    overlay =
      Layer.overlay(
        Container.box([{:content, Foundational.text("Base", id: "base-copy")}], id: "base-layer"),
        [
          {:overlay, layout}
        ],
        id: "visualization-overlay"
      )

    assert %Element{kind: :overlay} = overlay
    assert %Element{kind: :column} = List.last(overlay.children).element
  end
end
