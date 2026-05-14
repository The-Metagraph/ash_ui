defmodule LiveUi.AdvancedWidgetsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  test "advanced data, document, feedback, and chart widgets render with stable metadata" do
    html =
      Phoenix.HTML.raw("""
      #{render_component(&LiveUi.Widgets.Table.render/1, %{id: "table", columns: [%{id: "name", label: "Name"}], rows: [%{id: "row-1", cells: ["Pascal"]}]})}
      #{render_component(&LiveUi.Widgets.TreeView.render/1, %{id: "tree", nodes: [%{id: "root", label: "Root", children: [%{id: "child", label: "Child"}]}]})}
      #{render_component(&LiveUi.Widgets.MarkdownViewer.render/1, %{id: "markdown", source: "# Heading"})}
      #{render_component(&LiveUi.Widgets.LogViewer.render/1, %{id: "logs", entries: [%{id: "log-1", message: "boot"}]})}
      #{render_component(&LiveUi.Widgets.Gauge.render/1, %{id: "gauge", value: 42, label: "CPU"})}
      #{render_component(&LiveUi.Widgets.Sparkline.render/1, %{id: "spark", series: [1, 2, 3]})}
      #{render_component(&LiveUi.Widgets.BarChart.render/1, %{id: "bars", series: [%{id: "cpu", values: [10, 20]}]})}
      #{render_component(&LiveUi.Widgets.LineChart.render/1, %{id: "line", series: [%{id: "cpu", values: [10, 20]}]})}
      """)
      |> Phoenix.HTML.safe_to_string()

    assert html =~ "data-live-ui-widget=\"table\""
    assert html =~ "data-live-ui-widget=\"tree-view\""
    assert html =~ "data-live-ui-widget=\"markdown-viewer\""
    assert html =~ "data-live-ui-widget=\"log-viewer\""
    assert html =~ "data-live-ui-widget=\"gauge\""
    assert html =~ "data-live-ui-widget=\"sparkline\""
    assert html =~ "data-live-ui-widget=\"bar-chart\""
    assert html =~ "data-live-ui-widget=\"line-chart\""
  end

  test "operational widgets render structured assigns and update-ready metadata" do
    html =
      Phoenix.HTML.raw("""
      #{render_component(&LiveUi.Widgets.StreamWidget.render/1, %{id: "stream", entries: [%{id: "evt-1", message: "ready"}]})}
      #{render_component(&LiveUi.Widgets.ProcessMonitor.render/1, %{id: "processes", processes: [%{id: "proc-1", pid: "#PID<0.10.0>", state: :running}]})}
      #{render_component(&LiveUi.Widgets.SupervisionTreeViewer.render/1, %{id: "sup-tree", nodes: [%{id: "root", label: "Root", type: :supervisor, children: [%{id: "worker", label: "Worker", type: :worker}]}]})}
      #{render_component(&LiveUi.Widgets.ClusterDashboard.render/1, %{id: "cluster", nodes: [%{id: "node-a", status: :up}], summary: %{healthy: 1}})}
      """)
      |> Phoenix.HTML.safe_to_string()

    assert html =~ "data-live-ui-widget=\"stream-widget\""
    assert html =~ "data-live-ui-widget=\"process-monitor\""
    assert html =~ "data-live-ui-widget=\"supervision-tree-viewer\""
    assert html =~ "data-live-ui-widget=\"cluster-dashboard\""
  end

  test "advanced widget families are registered in the native widget surface" do
    metadata = Enum.map(LiveUi.Widgets.advanced_modules(), &LiveUi.Component.metadata/1)

    assert Enum.any?(metadata, &(&1.name == :table and &1.family == :data))
    assert Enum.any?(metadata, &(&1.name == :gauge and &1.family == :feedback))
    assert Enum.any?(metadata, &(&1.name == :stream_widget and &1.family == :operational))
  end
end
