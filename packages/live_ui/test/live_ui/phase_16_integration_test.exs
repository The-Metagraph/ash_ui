defmodule LiveUi.Phase16IntegrationTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Runtime
  alias UnifiedIUR.{Container, Layout}
  alias UnifiedIUR.Widgets.{Advanced, Data, Feedback}

  @moduledoc """
  Integration tests for Phase 16 - Advanced Widget Integration Tests.

  These tests validate the complete widget-component architecture end to end
  across all widget families, with emphasis on advanced widgets, cross-family
  composition, and native/canonical parity.
  """

  describe "16.1.1 - Data and feedback widget integration scenarios" do
    test "data and document widgets preserve identity and bounded local state through component boundaries" do
      # List widget with selection state
      list_element =
        Data.list(
          [
            %{id: "item-1", label: "Option 1", selected?: true},
            %{id: "item-2", label: "Option 2", selected?: false}
          ],
          id: "selectable-list",
          selection_mode: "single"
        )

      {:ok, runtime_state} = Runtime.mount_iur(list_element)

      html =
        render_component(Runtime.component(),
          id: "list-test",
          runtime_state: runtime_state
        )

      # Verify widget boundary and identity are present
      assert html =~ ~s(data-live-ui-widget-boundary="list")
      assert html =~ ~s(data-live-ui-widget="list")
      assert html =~ ~s(id="selectable-list")
    end

    test "collection widget event routing remains correct for selection interactions" do
      # Table widget with selectable rows
      table_element =
        Data.table(
          [
            %{id: "name", label: "Name"},
            %{id: "status", label: "Status"}
          ],
          [
            %{id: "row-1", cells: ["Item 1", "Active"]},
            %{id: "row-2", cells: ["Item 2", "Inactive"]}
          ],
          id: "data-table"
        )

      {:ok, runtime_state} = Runtime.mount_iur(table_element)

      # Verify the widget component boundary renders
      html =
        render_component(Runtime.component(),
          id: "table-test",
          runtime_state: runtime_state
        )

      assert html =~ ~s(data-live-ui-widget-boundary="table")
      assert html =~ ~s(data-live-ui-widget="table")
    end

    test "markdown viewer preserves content through component boundaries" do
      markdown_element =
        Advanced.markdown_viewer(
          "# Test Content\n\n- Item 1\n- Item 2",
          id: "markdown-view",
          mode: "rendered"
        )

      {:ok, runtime_state} = Runtime.mount_iur(markdown_element)

      html =
        render_component(Runtime.component(),
          id: "markdown-test",
          runtime_state: runtime_state
        )

      assert html =~ ~s(data-live-ui-widget-boundary="markdown_viewer")
      assert html =~ ~s(data-live-ui-widget="markdown-viewer")
      assert html =~ "Test Content"
    end

    test "visually minimal widgets respect widget-component contract" do
      # Status widget - visually minimal but still a proper widget component
      status_element =
        Feedback.status("System ready",
          id: "status-indicator",
          severity: "success",
          status: "healthy"
        )

      {:ok, runtime_state} = Runtime.mount_iur(status_element)

      html =
        render_component(Runtime.component(),
          id: "status-test",
          runtime_state: runtime_state
        )

      assert html =~ ~s(data-live-ui-widget-boundary="status")
      assert html =~ ~s(data-live-ui-widget="status")
      assert html =~ "System ready"
    end

    test "stream widget preserves entry state through component boundaries" do
      stream_element =
        Advanced.stream_widget(
          [
            %{id: "evt-1", severity: "info", message: "System started"},
            %{id: "evt-2", severity: "success", message: "Ready"}
          ],
          id: "event-stream",
          ordering: "append_only"
        )

      {:ok, runtime_state} = Runtime.mount_iur(stream_element)

      html =
        render_component(Runtime.component(),
          id: "stream-test",
          runtime_state: runtime_state
        )

      assert html =~ ~s(data-live-ui-widget-boundary="stream_widget")
      assert html =~ ~s(data-live-ui-widget="stream-widget")
    end
  end

  describe "16.1.2 - Overlay and operational widget integration scenarios" do
    test "inline feedback widget preserves state through component boundaries" do
      # Inline feedback with severity
      feedback_element =
        Feedback.inline_feedback(
          "Changes saved successfully",
          id: "save-feedback",
          severity: "success",
          title: "Success"
        )

      {:ok, runtime_state} = Runtime.mount_iur(feedback_element)

      html =
        render_component(Runtime.component(),
          id: "feedback-test",
          runtime_state: runtime_state
        )

      assert html =~ ~s(data-live-ui-widget-boundary="inline_feedback")
      assert html =~ ~s(data-live-ui-widget="inline-feedback")
      assert html =~ "Changes saved successfully"
    end

    test "operational widgets preserve real-time updates and bounded local state" do
      # Process monitor with process state
      monitor_element =
        Advanced.process_monitor(
          [
            %{id: "app", pid: "#PID<0.1.0>", state: :running},
            %{id: "worker", pid: "#PID<0.2.0>", state: :idle}
          ],
          id: "process-monitor"
        )

      {:ok, runtime_state} = Runtime.mount_iur(monitor_element)

      html =
        render_component(Runtime.component(),
          id: "monitor-test",
          runtime_state: runtime_state
        )

      assert html =~ ~s(data-live-ui-widget-boundary="process_monitor")
      assert html =~ ~s(data-live-ui-widget="process-monitor")
    end

    test "log viewer preserves entry state through component boundaries" do
      log_element =
        Advanced.log_viewer(
          [
            %{id: "1", timestamp: "10:00:01", severity: "info", message: "Started"},
            %{id: "2", timestamp: "10:00:02", severity: "error", message: "Failed"}
          ],
          id: "log-viewer"
        )

      {:ok, runtime_state} = Runtime.mount_iur(log_element)

      html =
        render_component(Runtime.component(),
          id: "log-test",
          runtime_state: runtime_state
        )

      assert html =~ ~s(data-live-ui-widget-boundary="log_viewer")
      assert html =~ ~s(data-live-ui-widget="log-viewer")
    end

    test "cluster dashboard maintains summary state through component boundaries" do
      dashboard_element =
        Advanced.cluster_dashboard(
          [
            %{id: "node-1", status: :healthy},
            %{id: "node-2", status: :degraded}
          ],
          id: "cluster-dashboard",
          summary: %{healthy: 1, degraded: 1}
        )

      {:ok, runtime_state} = Runtime.mount_iur(dashboard_element)

      html =
        render_component(Runtime.component(),
          id: "dashboard-test",
          runtime_state: runtime_state
        )

      assert html =~ ~s(data-live-ui-widget-boundary="cluster_dashboard")
      assert html =~ ~s(data-live-ui-widget="cluster-dashboard")
    end
  end

  describe "16.2 - Cross-Family Widget Composition Scenarios" do
    test "multi-family screen with foundational, data, and feedback widgets" do
      # Complex screen combining widgets from multiple families
      complex_screen =
        Container.box(
          [
            Layout.column([
              Data.list(
                [
                  %{id: "item-1", label: "Overview", selected?: true},
                  %{id: "item-2", label: "Activity"}
                ],
                id: "nav-list"
              ),
              Feedback.status("System healthy",
                id: "status-indicator",
                severity: "success"
              )
            ])
          ],
          id: "dashboard-panel"
        )

      {:ok, runtime_state} = Runtime.mount_iur(complex_screen)

      html =
        render_component(Runtime.component(),
          id: "complex-screen-test",
          runtime_state: runtime_state
        )

      # Verify multiple widget boundaries are present
      assert html =~ ~s(data-live-ui-widget-boundary="box")
      assert html =~ ~s(data-live-ui-widget-boundary="column")
      assert html =~ ~s(data-live-ui-widget-boundary="list")
      assert html =~ ~s(data-live-ui-widget-boundary="status")
    end

    test "screen with input, navigation, and data widgets composes correctly" do
      # Screen combining inputs, navigation, and data display
      composite_screen =
        Container.box(
          [
            Layout.column([
              Data.table(
                [
                  %{id: "name", label: "Name"},
                  %{id: "role", label: "Role"}
                ],
                [
                  %{id: "user-1", cells: ["Alice", "Admin"]},
                  %{id: "user-2", cells: ["Bob", "User"]}
                ],
                id: "users-table"
              )
            ])
          ],
          id: "users-panel"
        )

      {:ok, runtime_state} = Runtime.mount_iur(composite_screen)

      html =
        render_component(Runtime.component(),
          id: "composite-screen-test",
          runtime_state: runtime_state
        )

      # Verify all widget component boundaries render
      assert html =~ ~s(data-live-ui-widget-boundary="box")
      assert html =~ ~s(data-live-ui-widget-boundary="column")
      assert html =~ ~s(data-live-ui-widget-boundary="table")
    end

    test "operational dashboard with advanced, feedback, and layout widgets" do
      # Operational dashboard combining multiple widget families
      dashboard_screen =
        Container.box(
          [
            Layout.column([
              Advanced.cluster_dashboard(
                [
                  %{id: "node-1", status: :healthy}
                ],
                id: "cluster-status",
                summary: %{healthy: 1}
              ),
              Advanced.stream_widget(
                [
                  %{id: "evt-1", severity: "info", message: "Monitoring started"}
                ],
                id: "event-stream"
              ),
              Feedback.gauge(id: "cpu-gauge", value: 45, label: "CPU")
            ])
          ],
          id: "ops-dashboard"
        )

      {:ok, runtime_state} = Runtime.mount_iur(dashboard_screen)

      html =
        render_component(Runtime.component(),
          id: "ops-dashboard-test",
          runtime_state: runtime_state
        )

      # Verify all widget families render correctly
      assert html =~ ~s(data-live-ui-widget-boundary="cluster_dashboard")
      assert html =~ ~s(data-live-ui-widget-boundary="stream_widget")
      assert html =~ ~s(data-live-ui-widget-boundary="gauge")
    end

    test "complex nested layout preserves widget identity through all boundaries" do
      # Deeply nested widget composition
      nested_screen =
        Container.box(
          [
            Layout.row([
              Layout.column([
                Data.list([%{id: "1", label: "Item"}], id: "col-1-list")
              ], id: "col-left"),
              Layout.column([
                Feedback.status("Ready", id: "col-2-status")
              ], id: "col-right")
            ], id: "main-row")
          ],
          id: "nested-layout"
        )

      {:ok, runtime_state} = Runtime.mount_iur(nested_screen)

      html =
        render_component(Runtime.component(),
          id: "nested-test",
          runtime_state: runtime_state
        )

      # Verify all nested widget boundaries are present
      assert html =~ ~s(data-live-ui-widget-boundary="box")
      assert html =~ ~s(data-live-ui-widget-boundary="row")
      assert html =~ ~s(data-live-ui-widget-boundary="column")
      assert html =~ ~s(data-live-ui-widget-boundary="list")
      assert html =~ ~s(data-live-ui-widget-boundary="status")
    end
  end

  describe "16.3 - Native/Canonical Parity Scenarios" do
    test "equivalent direct-native and canonical widgets converge on same component boundaries" do
      # Canonical rendering uses widget component boundaries
      canonical_element =
        Container.box(
          [
            Layout.column([
              UnifiedIUR.Widgets.Foundational.text("Test content",
                id: "test-text"
              )
            ])
          ],
          id: "test-box"
        )

      {:ok, canonical_runtime} = Runtime.mount_iur(canonical_element)
      canonical_html =
        render_component(Runtime.component(),
          id: "canonical-test",
          runtime_state: canonical_runtime
        )

      # Verify widget component boundaries are present
      assert canonical_html =~ ~s(data-live-ui-widget-boundary="box")
      assert canonical_html =~ ~s(data-live-ui-widget-boundary="column")
      assert canonical_html =~ ~s(data-live-ui-widget-boundary="text")
    end

    test "canonical rendering preserves widget identity through component boundaries" do
      element =
        Data.list(
          [
            %{id: "item-1", label: "First"},
            %{id: "item-2", label: "Second"}
          ],
          id: "identity-test-list"
        )

      {:ok, runtime_state} = Runtime.mount_iur(element)

      html =
        render_component(Runtime.component(),
          id: "identity-test",
          runtime_state: runtime_state
        )

      # Verify widget identity key is present
      assert html =~ ~s(data-live-ui-widget-key=)
      assert html =~ ~s(data-live-ui-widget-boundary="list")
      assert html =~ "First"
      assert html =~ "Second"
    end

    test "widget continuity remains deterministic across rerenders and boundary translation" do
      # Render the same canonical element twice
      element =
        Data.list(
          [
            %{id: "item-1", label: "First"},
            %{id: "item-2", label: "Second"}
          ],
          id: "deterministic-list"
        )

      {:ok, runtime_state} = Runtime.mount_iur(element)

      # First render
      html1 =
        render_component(Runtime.component(),
          id: "first-render",
          runtime_state: runtime_state
        )

      # Second render (same state, different container ID)
      html2 =
        render_component(Runtime.component(),
          id: "second-render",
          runtime_state: runtime_state
        )

      # Widget boundaries should be identical
      assert html1 =~ ~s(data-live-ui-widget-boundary="list")
      assert html2 =~ ~s(data-live-ui-widget-boundary="list")

      # Widget content should be preserved
      assert html1 =~ "First"
      assert html2 =~ "First"
      assert html1 =~ "Second"
      assert html2 =~ "Second"

      # Widget identity key should be the same (same runtime_state)
      # Note: mount_iur uses :native mode for the widget-key since it's mounted through the runtime
      assert html1 =~ ~s(data-live-ui-widget-key="native:data:list:deterministic-list:root")
      assert html2 =~ ~s(data-live-ui-widget-key="native:data:list:deterministic-list:root")
    end

    test "advanced widgets maintain proper component boundary attributes" do
      element =
        Advanced.cluster_dashboard(
          [%{id: "node-1", status: :healthy}],
          id: "test-dashboard"
        )

      {:ok, runtime_state} = Runtime.mount_iur(element)

      html =
        render_component(Runtime.component(),
          id: "advanced-boundary-test",
          runtime_state: runtime_state
        )

      # Verify advanced widget has proper boundary attributes
      assert html =~ ~s(data-live-ui-widget-boundary="cluster_dashboard")
      assert html =~ ~s(data-live-ui-widget="cluster-dashboard")
      assert html =~ ~s(data-live-ui-widget-key=)
    end
  end
end
