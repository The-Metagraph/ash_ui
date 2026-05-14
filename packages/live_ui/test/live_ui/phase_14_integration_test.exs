defmodule LiveUi.Phase14IntegrationTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.{Component, Runtime}
  alias LiveUi.Widget.Identity

  @moduledoc """
  End-to-end integration tests for Phase 14 widget migrations.

  Verifies that overlay, operational, and display widgets work correctly
  together in realistic screen scenarios through the widget component
  architecture.
  """

  defmodule OverlayScreen do
    use LiveUi.Screen, id: :overlay_screen, title: "Overlay Demo Screen"

    @impl true
    def mount_defaults do
      %{
        dialog_open: false,
        toast_message: nil
      }
    end

    @impl true
    def render(assigns) do
      ~H"""
      <LiveUi.Widgets.Box.component id="overlay-demo-box" padding="lg">
        <LiveUi.Widgets.Dialog.component
          id="main-dialog"
          title="Overlay Demo"
          open={@dialog_open}
          inner_block={[
            %{
              __slot__: :inner_block,
              inner_block: fn _, _ -> "This is a dialog overlay."
            end
            }
          ]}
          actions={[
            %{
              __slot__: :actions,
              inner_block: fn _, _ -> "Action Buttons"
            end
            }
          ]}
        />
        <LiveUi.Widgets.Toast.component
          id="status-toast"
          severity="info"
          inner_block={[
            %{
              __slot__: :inner_block,
              inner_block: fn _, _ -> "Status update"
            end
            }
          ]}
        />
      </LiveUi.Widgets.Box.component>
      """
    end
  end

  defmodule OperationalScreen do
    use LiveUi.Screen, id: :operational_screen, title: "Operational Demo Screen"

    @impl true
    def mount_defaults do
      %{
        stream_entries: [
          %{id: "entry-1", message: "System started", severity: "info"},
          %{id: "entry-2", message: "Process spawned", severity: "info"}
        ],
        processes: [
          %{id: "proc-1", pid: "0.123.0", state: :running}
        ]
      }
    end

    @impl true
    def render(assigns) do
      ~H"""
      <LiveUi.Widgets.Box.component id="operational-box" padding="lg">
        <LiveUi.Widgets.Status.component
          id="ops-status"
          text="Operational View"
          severity="info"
        />
        <LiveUi.Widgets.StreamWidget.component
          id="system-stream"
          entries={@stream_entries}
        />
        <LiveUi.Widgets.ProcessMonitor.component
          id="process-monitor"
          processes={@processes}
        />
      </LiveUi.Widgets.Box.component>
      """
    end
  end

  defmodule DisplayScreen do
    use LiveUi.Screen, id: :display_screen, title: "Display Demo Screen"

    @impl true
    def mount_defaults do
      %{
        scroll_position: 0
      }
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div id="display-content">
        <LiveUi.Widgets.Viewport.component
          id="main-viewport"
          inner_block={[
            %{
              __slot__: :inner_block,
              inner_block: fn _, _ -> "Viewport content here"
            end
            }
          ]}
        />
      </div>
      """
    end
  end

  describe "overlay widget integration" do
    test "overlay widgets compose correctly in demo screens" do
      assert {:ok, runtime_state} = Runtime.mount(OverlayScreen)

      html =
        render_component(Runtime.component(),
          id: "overlay-runtime",
          runtime_state: runtime_state
        )

      # Verify dialog widget is present
      assert html =~ ~s(data-live-ui-widget-boundary="dialog")
      assert html =~ "Overlay Demo"

      # Verify toast widget is present
      assert html =~ ~s(data-live-ui-widget-boundary="toast")
      assert html =~ "Status update"

      # Verify container widget is present
      assert html =~ ~s(data-live-ui-widget-boundary="box")
    end
  end

  describe "operational widget integration" do
    test "operational widgets compose correctly in monitoring screens" do
      assert {:ok, runtime_state} = Runtime.mount(OperationalScreen)

      html =
        render_component(Runtime.component(),
          id: "operational-runtime",
          runtime_state: runtime_state
        )

      # Verify status widget is present
      assert html =~ ~s(data-live-ui-widget-boundary="status")
      assert html =~ "Operational View"

      # Verify stream widget is present
      assert html =~ ~s(data-live-ui-widget-boundary="stream_widget")
      assert html =~ "System started"
      assert html =~ "Process spawned"

      # Verify process monitor is present
      assert html =~ ~s(data-live-ui-widget-boundary="process_monitor")
      assert html =~ "0.123.0"
    end
  end

  describe "display system widget integration" do
    test "display widgets compose correctly in layout screens" do
      assert {:ok, runtime_state} = Runtime.mount(DisplayScreen)

      html =
        render_component(Runtime.component(),
          id: "display-runtime",
          runtime_state: runtime_state
        )

      # Verify viewport widget is present
      assert html =~ ~s(data-live-ui-widget-boundary="viewport")
      assert html =~ "Viewport content"
    end
  end

  describe "widget identity preservation for overlay widgets" do
    test "widget identity includes mode differentiation for dialog" do
      native_identity =
        Component.widget_identity(
          LiveUi.Widgets.Dialog,
          %{id: "test-dialog"},
          mode: :native
        )

      canonical_identity =
        Component.widget_identity(
          LiveUi.Widgets.Dialog,
          %{id: "test-dialog"},
          mode: :canonical
        )

      native_key = Identity.key(native_identity)
      canonical_key = Identity.key(canonical_identity)

      refute native_key == canonical_key
      assert native_key == "native:overlay:dialog:test-dialog:root"
      assert canonical_key == "canonical:overlay:dialog:test-dialog:root"
    end
  end

  describe "widget identity preservation for operational widgets" do
    test "widget identity includes mode differentiation for stream_widget" do
      native_identity =
        Component.widget_identity(
          LiveUi.Widgets.StreamWidget,
          %{id: "test-stream"},
          mode: :native
        )

      canonical_identity =
        Component.widget_identity(
          LiveUi.Widgets.StreamWidget,
          %{id: "test-stream"},
          mode: :canonical
        )

      native_key = Identity.key(native_identity)
      canonical_key = Identity.key(canonical_identity)

      refute native_key == canonical_key
      assert native_key == "native:operational:stream_widget:test-stream:root"
      assert canonical_key == "canonical:operational:stream_widget:test-stream:root"
    end
  end

  describe "widget identity preservation for display widgets" do
    test "widget identity includes mode differentiation for viewport" do
      native_identity =
        Component.widget_identity(
          LiveUi.Widgets.Viewport,
          %{id: "test-viewport"},
          mode: :native
        )

      canonical_identity =
        Component.widget_identity(
          LiveUi.Widgets.Viewport,
          %{id: "test-viewport"},
          mode: :canonical
        )

      native_key = Identity.key(native_identity)
      canonical_key = Identity.key(canonical_identity)

      refute native_key == canonical_key
      assert native_key == "native:display:viewport:test-viewport:root"
      assert canonical_key == "canonical:display:viewport:test-viewport:root"
    end
  end

  describe "bounded local state for overlay widgets" do
    test "overlay widgets support local_state_keys" do
      dialog_metadata = Component.metadata(LiveUi.Widgets.Dialog)
      context_menu_metadata = Component.metadata(LiveUi.Widgets.ContextMenu)
      toast_metadata = Component.metadata(LiveUi.Widgets.Toast)

      assert is_list(dialog_metadata.local_state_keys)
      assert is_list(context_menu_metadata.local_state_keys)
      assert is_list(toast_metadata.local_state_keys)
    end
  end

  describe "bounded local state for operational widgets" do
    test "operational widgets support local_state_keys" do
      stream_metadata = Component.metadata(LiveUi.Widgets.StreamWidget)
      monitor_metadata = Component.metadata(LiveUi.Widgets.ProcessMonitor)
      tree_metadata = Component.metadata(LiveUi.Widgets.SupervisionTreeViewer)

      assert is_list(stream_metadata.local_state_keys)
      assert is_list(monitor_metadata.local_state_keys)
      assert is_list(tree_metadata.local_state_keys)
    end
  end

  describe "bounded local state for display widgets" do
    test "display widgets support local_state_keys" do
      viewport_metadata = Component.metadata(LiveUi.Widgets.Viewport)
      scroll_bar_metadata = Component.metadata(LiveUi.Widgets.ScrollBar)
      split_pane_metadata = Component.metadata(LiveUi.Widgets.SplitPane)

      assert is_list(viewport_metadata.local_state_keys)
      assert is_list(scroll_bar_metadata.local_state_keys)
      assert is_list(split_pane_metadata.local_state_keys)
    end
  end
end
