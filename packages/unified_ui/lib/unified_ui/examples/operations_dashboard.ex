defmodule UnifiedUi.Examples.OperationsDashboard do
  @moduledoc """
  Reference dashboard for advanced data, feedback, and operational widgets.
  """

  use UnifiedUi.Dsl

  identity do
    id(:operations_dashboard)
    title("Operations Dashboard")
    authored_ref([:examples, :operations_dashboard])
    tags([:example, :advanced, :dashboard])
  end

  composition do
    root(:operations_dashboard_root)
    mode(:screen)

    column :operations_shell do
      summary("Operations shell")

      table :deployments_table do
        table_columns(name: "Name", status: "Status")

        table_rows([
          [name: "API", status: "Healthy"],
          [name: "Web", status: "Degraded"]
        ])

        empty_state("No deployments")
      end

      tree_view :cluster_tree do
        tree_nodes([
          [id: :cluster, label: "Cluster", children: [[id: :node_a, label: "Node A"]]]
        ])
      end

      markdown_viewer :release_notes do
        source("## Release notes\n- Deployment stabilized\n- Cluster healthy")
      end

      log_viewer :activity_log do
        log_entries([
          %{message: "Service started", severity: :info},
          %{message: "Latency spike", severity: :warning}
        ])

        wrap?(true)
      end

      gauge :cpu_gauge do
        current(72)
        maximum(100)
        severity(:warning)
      end

      sparkline :cpu_trend do
        points([30, 45, 51, 72])
      end

      stream_widget :event_stream do
        entries([
          [id: "evt-1", message: "ready", severity: :info],
          [id: "evt-2", message: "warning", severity: :warning]
        ])

        severity_field(:severity)
      end

      process_monitor :processes do
        processes([
          [pid: "#PID<0.10.0>", name: "api", state: :running]
        ])

        sort_by(:cpu)
      end

      cluster_dashboard :cluster_status do
        cluster_nodes([
          [id: :node_a, status: :up],
          [id: :node_b, status: :degraded]
        ])

        metrics(%{healthy: 1, degraded: 1})
      end
    end
  end
end
