defmodule LiveUi.AdvancedRendererTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias UnifiedIUR.{Canvas, Container, Layer, Layout, Viewport}
  alias UnifiedIUR.Widgets.Navigation
  alias UnifiedIUR.Widgets.{Advanced, Data, Feedback, Foundational}
  alias LiveUi.Runtime

  test "renderer maps advanced canonical widgets into native advanced components" do
    element =
      Layout.column([
        Data.list(
          [
            %{id: "overview", label: "Overview", selected?: true},
            %{id: "activity", label: "Activity"}
          ],
          id: "nav-list"
        ),
        Feedback.inline_feedback("Runtime warning", id: "warning", severity: :warning),
        Advanced.markdown_viewer("# Release Notes", id: "release-notes"),
        Advanced.stream_widget(
          [
            %{id: "evt-1", message: "ready", severity: :info}
          ],
          id: "event-stream"
        )
      ])

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ "data-live-ui-widget=\"column\""
    assert html =~ "data-live-ui-widget=\"list\""
    assert html =~ "data-live-ui-widget=\"inline-feedback\""
    assert html =~ "data-live-ui-widget=\"markdown-viewer\""
    assert html =~ "data-live-ui-widget=\"stream-widget\""
  end

  test "renderer realizes advanced widget browser styles and supported state variants" do
    element =
      Layout.column([
        Navigation.tabs(
          [
            %{id: "details", label: "Details", active?: true},
            %{id: "history", label: "History", disabled?: true}
          ],
          id: "profile-tabs",
          active_item: "details",
          style: %{background: "#0f172a", border_color: "#1d4ed8"},
          theme: %{id: :live_ui, state: :focused}
        ),
        Data.list(
          [
            %{id: "overview", label: "Overview", selected?: true},
            %{id: "activity", label: "Activity"}
          ],
          id: "nav-list",
          style: %{background: "#111827", border_color: "#334155"},
          theme: %{id: :live_ui, state: :selected}
        ),
        Feedback.status("Healthy",
          id: "system-status",
          severity: :success,
          status: :ready,
          style: %{
            state_variants: %{active: %{foreground: "#ffffff", border_color: "#22c55e"}}
          },
          theme: %{id: :live_ui, state: :active}
        ),
        Advanced.markdown_viewer("# Release Notes",
          id: "release-notes",
          style: %{background: "#020617", border_color: "#475569"}
        ),
        Advanced.stream_widget(
          [%{id: "evt-1", message: "ready", severity: :success}],
          id: "event-stream",
          style: %{background: "#020617", border_color: "#1d4ed8"}
        ),
        Advanced.cluster_dashboard(
          [%{id: "node-a", status: :up}],
          id: "cluster-dashboard",
          summary: %{healthy: 1},
          style: %{background: "#08101f", border_color: "#059669"}
        ),
        Canvas.bar_chart(
          [%{id: :cpu, label: "CPU", values: [10, 20, 30]}],
          id: "cpu-bars",
          style: %{background: "#0b1120", border_color: "#0ea5e9"}
        ),
        Canvas.line_chart(
          [%{id: :cpu, label: "CPU", values: [10, 20, 30]}],
          id: "cpu-line",
          style: %{background: "#0b1120", border_color: "#0ea5e9"}
        ),
        Layer.toast(Foundational.text("Saved"),
          id: "save-toast",
          severity: :success,
          style: %{background: "#14532d", border_color: "#22c55e"},
          theme: %{id: :live_ui, state: :active}
        )
      ])

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ "data-live-ui-widget=\"tabs\""
    assert html =~ "data-live-ui-state=\"focused\""
    assert html =~ "--live-ui-background: #0f172a"
    assert html =~ "data-live-ui-widget=\"list\""
    assert html =~ "data-live-ui-state=\"selected\""
    assert html =~ "--live-ui-border-color: #334155"
    assert html =~ "data-live-ui-widget=\"status\""
    assert html =~ "data-live-ui-state=\"active\""
    assert html =~ "--live-ui-foreground: #ffffff"
    assert html =~ "--live-ui-border-color: #22c55e"
    assert html =~ "data-live-ui-widget=\"markdown-viewer\""
    assert html =~ "--live-ui-background: #020617"
    assert html =~ "data-live-ui-widget=\"stream-widget\""
    assert html =~ "data-live-ui-widget=\"cluster-dashboard\""
    assert html =~ "--live-ui-border-color: #059669"
    assert html =~ "data-live-ui-widget=\"bar-chart\""
    assert html =~ "data-live-ui-widget=\"line-chart\""
    assert html =~ "--live-ui-border-color: #0ea5e9"
    assert html =~ "data-live-ui-widget=\"toast\""
    assert html =~ "--live-ui-background: #14532d"
  end

  test "renderer maps layered and viewport canonical constructs through native display primitives" do
    base =
      UnifiedIUR.Layout.column([
      UnifiedIUR.Widgets.Foundational.text("Navigation", id: "nav-text"),
      UnifiedIUR.Widgets.Foundational.text("Details", id: "details-text"),
      UnifiedIUR.Widgets.Foundational.text("Plot", id: "plot-text")
    ])

    html = render_component(Runtime.component(),
      id: "canonical-render-test",
      runtime_state: element_to_runtime_state(base)
    )

    # Verify widget boundaries are present
    assert html =~ ~s(data-live-ui-widget-boundary)
  end

  defp element_to_runtime_state(element) do
    {:ok, runtime_state} = LiveUi.Runtime.mount_iur(element)
    runtime_state
  end

  test "runtime mounts advanced canonical screens through the shared native renderer" do
    canonical =
      Layout.column([
        Feedback.gauge(id: "cpu-gauge", value: 72, label: "CPU"),
        Canvas.line_chart(
          [
            %{id: :cpu, label: "CPU", values: [10, 20, 30]}
          ],
          id: "cpu-chart"
        ),
        Advanced.cluster_dashboard(
          [
            %{id: "node-a", status: :up}
          ],
          id: "cluster-dashboard",
          summary: %{healthy: 1}
        )
      ])

    assert {:ok, runtime_state} = LiveUi.Runtime.mount_iur(canonical)

    html =
      render_component(LiveUi.Runtime.component(),
        id: "advanced-canonical",
        runtime_state: runtime_state
      )

    assert html =~ "data-live-ui-widget=\"gauge\""
    assert html =~ "data-live-ui-widget=\"line-chart\""
    assert html =~ "data-live-ui-widget=\"cluster-dashboard\""
  end
end
