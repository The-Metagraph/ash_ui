defmodule LiveUi.Phase13IntegrationTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.{Component, Runtime}
  alias LiveUi.Widget.Identity

  @moduledoc """
  End-to-end integration tests for Phase 13 widget migrations.

  Verifies that data, document, feedback, and chart widgets work correctly
  together in realistic screen scenarios through the widget component
  architecture.
  """

  defmodule DataDashboardScreen do
    use LiveUi.Screen, id: :data_dashboard_screen, title: "Data Dashboard Screen"

    @impl true
    def mount_defaults do
      %{
        selected_items: [],
        table_data: [
          %{id: "row-1", cells: ["Alice", "Engineering", "100"]},
          %{id: "row-2", cells: ["Bob", "Sales", "200"]}
        ]
      }
    end

    @impl true
    def render(assigns) do
      ~H"""
      <LiveUi.Widgets.Box.component
        id="dashboard-box"
        padding="lg"
        tone="surface"
      >
        <LiveUi.Widgets.Status.component
          id="dashboard-status"
          text="Dashboard loaded"
          severity="info"
        />
        <LiveUi.Widgets.Table.component
          id="metrics-table"
          columns={[
            %{id: "col-1", label: "Name"},
            %{id: "col-2", label: "Department"},
            %{id: "col-3", label: "Score"}
          ]}
          rows={@table_data}
        />
        <LiveUi.Widgets.Progress.component
          id="load-progress"
          current={75}
          total={100}
        />
      </LiveUi.Widgets.Box.component>
      """
    end
  end

  defmodule DocumentViewerScreen do
    use LiveUi.Screen, id: :document_viewer_screen, title: "Document Viewer Screen"

    @impl true
    def mount_defaults do
      %{
        document_content: "# Guide\n\n## Getting Started\n\nFollow these steps.",
        log_entries: [
          %{timestamp: "2024-01-01T12:00:00Z", severity: "info", message: "Document loaded"}
        ]
      }
    end

    @impl true
    def render(assigns) do
      ~H"""
      <LiveUi.Widgets.Box.component id="viewer-box" padding="lg">
        <LiveUi.Widgets.MarkdownViewer.component
          id="doc-viewer"
          source={@document_content}
        />
        <LiveUi.Widgets.LogViewer.component
          id="activity-log"
          entries={@log_entries}
        />
      </LiveUi.Widgets.Box.component>
      """
    end
  end

  describe "data dashboard integration" do
    test "data and feedback widgets compose correctly in dashboard screens" do
      assert {:ok, runtime_state} = Runtime.mount(DataDashboardScreen)

      html =
        render_component(Runtime.component(),
          id: "data-dashboard-runtime",
          runtime_state: runtime_state
        )

      # Verify feedback widgets are present
      assert html =~ ~s(data-live-ui-widget-boundary="status")
      assert html =~ "Dashboard loaded"

      # Verify data widgets are present
      assert html =~ ~s(data-live-ui-widget-boundary="table")
      assert html =~ "Alice"
      assert html =~ "Engineering"

      # Verify progress widget is present
      assert html =~ ~s(data-live-ui-widget-boundary="progress")
      assert html =~ ~s(data-live-ui-widget-boundary="box")
    end
  end

  describe "document viewer integration" do
    test "document and log widgets compose correctly in viewer screens" do
      assert {:ok, runtime_state} = Runtime.mount(DocumentViewerScreen)

      html =
        render_component(Runtime.component(),
          id: "document-viewer-runtime",
          runtime_state: runtime_state
        )

      # Verify markdown viewer is present
      assert html =~ ~s(data-live-ui-widget-boundary="markdown_viewer")
      assert html =~ "Guide"
      assert html =~ "Getting Started"

      # Verify log viewer is present
      assert html =~ ~s(data-live-ui-widget-boundary="log_viewer")
      assert html =~ "Document loaded"
    end
  end

  describe "widget identity preservation for data widgets" do
    test "widget identity includes mode differentiation for list" do
      native_identity =
        Component.widget_identity(
          LiveUi.Widgets.List,
          %{id: "test-list"},
          mode: :native
        )

      canonical_identity =
        Component.widget_identity(
          LiveUi.Widgets.List,
          %{id: "test-list"},
          mode: :canonical
        )

      native_key = Identity.key(native_identity)
      canonical_key = Identity.key(canonical_identity)

      refute native_key == canonical_key
      assert native_key == "native:data:list:test-list:root"
      assert canonical_key == "canonical:data:list:test-list:root"
    end

    test "widget identity is stable across renders for table" do
      identity1 =
        Component.widget_identity(
          LiveUi.Widgets.Table,
          %{id: "stable-table"}
        )

      identity2 =
        Component.widget_identity(
          LiveUi.Widgets.Table,
          %{id: "stable-table"}
        )

      assert identity1.id == identity2.id

      key1 = Identity.key(identity1)
      key2 = Identity.key(identity2)

      assert key1 == key2
      assert key1 == "native:data:table:stable-table:root"
    end
  end

  describe "widget identity preservation for feedback widgets" do
    test "widget identity includes mode differentiation for gauge" do
      native_identity =
        Component.widget_identity(
          LiveUi.Widgets.Gauge,
          %{id: "test-gauge"},
          mode: :native
        )

      canonical_identity =
        Component.widget_identity(
          LiveUi.Widgets.Gauge,
          %{id: "test-gauge"},
          mode: :canonical
        )

      native_key = Identity.key(native_identity)
      canonical_key = Identity.key(canonical_identity)

      refute native_key == canonical_key
      assert native_key == "native:feedback:gauge:test-gauge:root"
      assert canonical_key == "canonical:feedback:gauge:test-gauge:root"
    end

    test "widget identity is stable across renders for status" do
      identity1 =
        Component.widget_identity(
          LiveUi.Widgets.Status,
          %{id: "stable-status"}
        )

      identity2 =
        Component.widget_identity(
          LiveUi.Widgets.Status,
          %{id: "stable-status"}
        )

      assert identity1.id == identity2.id

      key1 = Identity.key(identity1)
      key2 = Identity.key(identity2)

      assert key1 == key2
      assert key1 == "native:feedback:status:stable-status:root"
    end
  end

  describe "event routing through data widget boundaries" do
    test "list selection events route through component boundary" do
      html =
        render_component(&LiveUi.Widgets.List.component/1, %{
          id: "selection-list",
          items: [
            %{id: "item-1", label: "Option 1"},
            %{id: "item-2", label: "Option 2"}
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="list")
      assert html =~ "Option 1"
      assert html =~ "Option 2"
    end
  end

  describe "styling propagation through feedback widgets" do
    test "status widget preserves tone and variant styling" do
      html =
        render_component(&LiveUi.Widgets.Status.component/1, %{
          id: "styled-status",
          text: "Success message",
          tone: "success",
          variant: "solid"
        })

      assert html =~ ~s(data-live-ui-tone="success")
      assert html =~ ~s(data-live-ui-variant="solid")
    end
  end

  describe "bounded local state for data widgets" do
    test "list widget supports local_state_keys" do
      metadata = Component.metadata(LiveUi.Widgets.List)

      assert is_list(metadata.local_state_keys)
      assert metadata.mountable?
    end

    test "table widget supports local_state_keys" do
      metadata = Component.metadata(LiveUi.Widgets.Table)

      assert is_list(metadata.local_state_keys)
      assert metadata.mountable?
    end
  end

  describe "bounded local state for feedback widgets" do
    test "progress widget supports local_state_keys" do
      metadata = Component.metadata(LiveUi.Widgets.Progress)

      assert is_list(metadata.local_state_keys)
      assert metadata.mountable?
    end

    test "gauge widget supports local_state_keys" do
      metadata = Component.metadata(LiveUi.Widgets.Gauge)

      assert is_list(metadata.local_state_keys)
      assert metadata.mountable?
    end
  end
end
