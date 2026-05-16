defmodule LiveUi.OperationalWidgetsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component
  alias LiveUi.Widget.Identity

  @moduledoc """
  Regression tests for operational widgets to verify they preserve
  identity, styling, slots, and event semantics through the widget
  component architecture.
  """

  describe "stream_widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.StreamWidget)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.StreamWidget.Component
      assert metadata.family == :operational
      assert metadata.name == :stream_widget
    end

    test "stream_widget component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.StreamWidget.component/1, %{
          id: "test-stream",
          entries: [
            %{id: "entry-1", message: "First entry"},
            %{id: "entry-2", message: "Second entry"}
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="stream_widget")
      assert html =~ "First entry"
      assert html =~ "Second entry"
    end

    test "stream_widget supports ordering modes" do
      html =
        render_component(&LiveUi.Widgets.StreamWidget.component/1, %{
          id: "ordered-stream",
          entries: [],
          ordering: "append_only"
        })

      assert html =~ ~s(data-live-ui-ordering="append_only")
    end

    test "stream_widget supports entry severity levels" do
      html =
        render_component(&LiveUi.Widgets.StreamWidget.component/1, %{
          id: "severity-stream",
          entries: [
            %{id: "entry-1", message: "Info", severity: "info"},
            %{id: "entry-2", message: "Error", severity: "error"}
          ]
        })

      assert html =~ ~s(data-severity="info")
      assert html =~ ~s(data-severity="error")
    end
  end

  describe "process_monitor widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.ProcessMonitor)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.ProcessMonitor.Component
      assert metadata.family == :operational
      assert metadata.name == :process_monitor
    end

    test "process_monitor component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.ProcessMonitor.component/1, %{
          id: "test-monitor",
          processes: [
            %{id: "proc-1", pid: "0.123.0", state: :running},
            %{id: "proc-2", pid: "0.124.0", state: :sleeping}
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="process_monitor")
      assert html =~ "0.123.0"
      assert html =~ "0.124.0"
    end

    test "process_monitor displays process states" do
      html =
        render_component(&LiveUi.Widgets.ProcessMonitor.component/1, %{
          id: "state-monitor",
          processes: [
            %{id: "proc-1", label: "MyApp", state: :running}
          ]
        })

      assert html =~ "MyApp"
      assert html =~ ":running"
    end
  end

  describe "supervision_tree_viewer widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.SupervisionTreeViewer)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.SupervisionTreeViewer.Component
      assert metadata.family == :operational
      assert metadata.name == :supervision_tree_viewer
    end

    test "supervision_tree_viewer component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.SupervisionTreeViewer.component/1, %{
          id: "test-tree",
          nodes: [
            %{id: "sup-1", label: "MySupervisor", type: :supervisor}
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="supervision_tree_viewer")
      assert html =~ "MySupervisor"
    end

    test "supervision_tree_viewer supports nested children" do
      html =
        render_component(&LiveUi.Widgets.SupervisionTreeViewer.component/1, %{
          id: "nested-tree",
          nodes: [
            %{
              id: "sup-1",
              label: "Supervisor",
              type: :supervisor,
              children: [
                %{id: "worker-1", label: "Worker 1", type: :worker},
                %{id: "worker-2", label: "Worker 2", type: :worker}
              ]
            }
          ]
        })

      assert html =~ "Supervisor"
      assert html =~ "Worker 1"
      assert html =~ "Worker 2"
    end

    test "supervision_tree_viewer supports expanded state" do
      html =
        render_component(&LiveUi.Widgets.SupervisionTreeViewer.component/1, %{
          id: "expanded-tree",
          nodes: [],
          expanded: true
        })

      assert html =~ ~s(data-live-ui-expanded)
    end

    test "supervision_tree_viewer displays node status" do
      html =
        render_component(&LiveUi.Widgets.SupervisionTreeViewer.component/1, %{
          id: "status-tree",
          nodes: [
            %{id: "node-1", label: "RunningNode", type: :worker, status: :running}
          ]
        })

      assert html =~ ~s(data-status="running")
    end
  end

  describe "cluster_dashboard widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.ClusterDashboard)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.ClusterDashboard.Component
      assert metadata.family == :operational
      assert metadata.name == :cluster_dashboard
    end

    test "cluster_dashboard component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.ClusterDashboard.component/1, %{
          id: "test-dashboard",
          nodes: [
            %{id: "node-1", status: :up},
            %{id: "node-2", status: :down}
          ],
          summary: %{total: 2, up: 1, down: 1}
        })

      assert html =~ ~s(data-live-ui-widget-boundary="cluster_dashboard")
      assert html =~ "node-1"
      assert html =~ "node-2"
    end

    test "cluster_dashboard displays node status" do
      html =
        render_component(&LiveUi.Widgets.ClusterDashboard.component/1, %{
          id: "status-dashboard",
          nodes: [
            %{id: "healthy-node", status: :up}
          ],
          summary: %{}
        })

      assert html =~ ~s(data-status="up")
    end

    test "cluster_dashboard includes summary information" do
      html =
        render_component(&LiveUi.Widgets.ClusterDashboard.component/1, %{
          id: "summary-dashboard",
          nodes: [],
          summary: %{total_nodes: 5, healthy: 4}
        })

      assert html =~ ~s(data-summary)
    end
  end

  describe "widget identity preservation" do
    test "widget identity is stable across renders for stream_widget" do
      identity1 =
        Identity.new(
          Component.metadata(LiveUi.Widgets.StreamWidget),
          %{id: "stable-stream"}
        )

      identity2 =
        Identity.new(
          Component.metadata(LiveUi.Widgets.StreamWidget),
          %{id: "stable-stream"}
        )

      assert identity1.id == identity2.id
      assert Identity.key(identity1) == Identity.key(identity2)
      assert Identity.key(identity1) == "native:operational:stream_widget:stable-stream:root"
    end

    test "widget identity includes mode in key for process_monitor" do
      native_identity =
        Identity.new(
          Component.metadata(LiveUi.Widgets.ProcessMonitor),
          %{id: "mode-monitor"},
          mode: :native
        )

      canonical_identity =
        Identity.new(
          Component.metadata(LiveUi.Widgets.ProcessMonitor),
          %{id: "mode-monitor"},
          mode: :canonical
        )

      assert Identity.key(native_identity) ==
               "native:operational:process_monitor:mode-monitor:root"

      assert Identity.key(canonical_identity) ==
               "canonical:operational:process_monitor:mode-monitor:root"
    end
  end

  describe "event semantics preservation" do
    test "stream_widget has change events in metadata" do
      metadata = Component.metadata(LiveUi.Widgets.StreamWidget)

      assert :change in metadata.events
    end

    test "process_monitor has change events in metadata" do
      metadata = Component.metadata(LiveUi.Widgets.ProcessMonitor)

      assert :change in metadata.events
    end

    test "supervision_tree_viewer has change events in metadata" do
      metadata = Component.metadata(LiveUi.Widgets.SupervisionTreeViewer)

      assert :change in metadata.events
    end

    test "cluster_dashboard has change events in metadata" do
      metadata = Component.metadata(LiveUi.Widgets.ClusterDashboard)

      assert :change in metadata.events
    end
  end

  describe "bounded local state support" do
    test "operational widgets support local_state_keys for bounded state" do
      stream_metadata = Component.metadata(LiveUi.Widgets.StreamWidget)
      monitor_metadata = Component.metadata(LiveUi.Widgets.ProcessMonitor)
      tree_metadata = Component.metadata(LiveUi.Widgets.SupervisionTreeViewer)

      # Operational widgets can have local_state_keys for bounded UI state
      # like expanded nodes, selected items, etc.
      assert is_list(stream_metadata.local_state_keys)
      assert is_list(monitor_metadata.local_state_keys)
      assert is_list(tree_metadata.local_state_keys)
    end
  end

  describe "real-time update support" do
    test "stream_widget supports append-only ordering" do
      html =
        render_component(&LiveUi.Widgets.StreamWidget.component/1, %{
          id: "append-stream",
          entries: [
            %{id: "entry-1", message: "First"},
            %{id: "entry-2", message: "Second"},
            %{id: "entry-3", message: "Third"}
          ],
          ordering: "append_only"
        })

      assert html =~ "First"
      assert html =~ "Second"
      assert html =~ "Third"
    end

    test "process_monitor supports multiple process entries" do
      html =
        render_component(&LiveUi.Widgets.ProcessMonitor.component/1, %{
          id: "multi-process",
          processes: [
            %{id: "proc-1", pid: "0.100.0", state: :running},
            %{id: "proc-2", pid: "0.101.0", state: :sleeping},
            %{id: "proc-3", pid: "0.102.0", state: :exited}
          ]
        })

      assert html =~ "0.100.0"
      assert html =~ "0.101.0"
      assert html =~ "0.102.0"
    end
  end
end
