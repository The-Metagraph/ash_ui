defmodule UnifiedIUR.Widgets.AdvancedTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element
  alias UnifiedIUR.Widgets.Advanced

  test "builds operational monitoring widgets with structured ordering, severity, and timestamp metadata" do
    stream =
      Advanced.stream_widget(
        [
          [id: "evt-1", message: "started", severity: :info, timestamp: ~U[2026-03-14 12:00:00Z]],
          [id: "evt-2", message: "failed", severity: :error, timestamp: ~U[2026-03-14 12:01:00Z]]
        ],
        id: "event-stream",
        ordering: :append_only,
        severity_field: :severity,
        timestamp_field: :timestamp
      )

    logs =
      Advanced.log_viewer(
        [
          [id: "log-1", message: "boot complete", timestamp: ~U[2026-03-14 12:00:00Z]]
        ],
        id: "system-logs"
      )

    process_monitor =
      Advanced.process_monitor(
        [
          [id: "proc-1", pid: "#PID<0.10.0>", state: :running, cpu: 12]
        ],
        id: "process-monitor",
        sort_by: :cpu
      )

    cluster =
      Advanced.cluster_dashboard(
        [
          [id: "node-a", status: :up, cpu: 33],
          [id: "node-b", status: :degraded, cpu: 71]
        ],
        id: "cluster-dashboard",
        summary: %{healthy: 1, degraded: 1},
        severity: :warning
      )

    assert %Element{
             kind: :stream_widget,
             attributes: %{
               stream: %{
                 entries: [%{severity: :info}, %{severity: :error}],
                 ordering: :append_only,
                 severity_field: :severity,
                 timestamp_field: :timestamp
               }
             }
           } = stream

    assert %Element{
             kind: :log_viewer,
             attributes: %{logs: %{show_timestamps?: true, wrap?: true}}
           } =
             logs

    assert %Element{kind: :process_monitor, attributes: %{monitor: %{sort_by: :cpu}}} =
             process_monitor

    assert %Element{
             kind: :cluster_dashboard,
             attributes: %{cluster: %{summary: %{healthy: 1, degraded: 1}, severity: :warning}}
           } =
             cluster
  end

  test "builds command, markdown, and inspection-oriented advanced constructs" do
    command_palette =
      Advanced.command_palette(
        [
          [id: :open_file, label: "Open file"],
          [id: :save_file, label: "Save file"]
        ],
        id: "command-palette",
        query: "op",
        active_command: :open_file
      )

    markdown =
      Advanced.markdown_viewer(
        "# Title\n\nBody",
        id: "markdown-doc",
        mode: :rendered
      )

    supervision =
      Advanced.supervision_tree_viewer(
        [
          [
            id: :root_sup,
            label: "Root Supervisor",
            type: :supervisor,
            status: :running,
            children: [
              [id: :worker_1, label: "Worker 1", type: :worker, status: :running, restarts: 0]
            ]
          ]
        ],
        id: "supervision-tree"
      )

    assert %Element{
             kind: :command_palette,
             attributes: %{command_palette: %{query: "op", active_command: :open_file}}
           } = command_palette

    assert %Element{
             kind: :markdown_viewer,
             attributes: %{
               document: %{format: :markdown, source: "# Title\n\nBody", mode: :rendered}
             }
           } = markdown

    assert %Element{
             kind: :supervision_tree_viewer,
             attributes: %{
               inspection: %{
                 expanded?: true,
                 show_restarts?: true,
                 nodes: [%{children: [%{restarts: 0}]}]
               }
             }
           } = supervision
  end
end
