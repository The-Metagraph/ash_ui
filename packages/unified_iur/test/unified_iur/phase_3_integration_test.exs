defmodule UnifiedIUR.Phase3IntegrationTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Canvas
  alias UnifiedIUR.Container
  alias UnifiedIUR.Core.Invariant
  alias UnifiedIUR.Element
  alias UnifiedIUR.Layer
  alias UnifiedIUR.Layout
  alias UnifiedIUR.Reference
  alias UnifiedIUR.Tree
  alias UnifiedIUR.Viewport
  alias UnifiedIUR.Widgets.{Advanced, Data, Foundational}

  test "phase 3 overlays, dialogs, toasts, and context menus preserve layered child relationships and placement metadata" do
    nav =
      Data.list(
        [
          [id: :overview, label: "Overview", selected?: true],
          [id: :details, label: "Details"]
        ],
        id: "nav-list"
      )

    detail =
      Container.box(
        [
          {:content, Foundational.label("Detail", id: "detail-title")},
          {:content, Foundational.text("Detail content", id: "detail-copy")}
        ],
        id: "detail-box"
      )

    base_screen =
      Viewport.split_pane(
        Viewport.region(nav, id: "nav-viewport", offset: 0),
        Viewport.region(detail, id: "detail-viewport", offset: {0, 10}),
        id: "workspace-split",
        direction: :vertical,
        ratio: 0.25,
        divider_size: 1,
        divider_style: :solid
      )

    dialog =
      Layer.dialog(
        Container.content([{:content, Foundational.text("Edit settings", id: "dialog-copy")}],
          id: "dialog-content"
        ),
        id: "settings-dialog",
        title: "Settings"
      )

    toast =
      Layer.toast(
        Foundational.text("Saved", id: "toast-copy"),
        id: "save-toast",
        severity: :success,
        placement: :bottom_end
      )

    context_menu =
      Layer.context_menu(
        [
          [id: :copy, label: "Copy", active?: true],
          [id: :delete, label: "Delete"]
        ],
        id: "row-menu",
        anchor: %{target_id: "detail-box", x: 12, y: 8}
      )

    layered =
      Layer.overlay(
        base_screen,
        [
          {:modal, dialog},
          {:transient, toast},
          {:popup, context_menu}
        ],
        id: "workspace-overlay",
        background_fill: :scrim
      )

    assert %Element{kind: :overlay, children: [base, modal, transient, popup]} = layered
    assert base.slot == :base
    assert modal.element.kind == :dialog
    assert transient.element.kind == :toast
    assert popup.element.kind == :context_menu

    assert %{context_menu: %{anchor: %{target_id: "detail-box", x: 12, y: 8}}} =
             popup.element.attributes
  end

  test "phase 3 viewport and split-pane constructs preserve clipping and offset semantics in canonical shape" do
    body =
      Container.content(
        [
          {:content, Foundational.text("Body", id: "body-copy")}
        ],
        id: "body-container"
      )

    left =
      Viewport.region(body, id: "left-viewport", offset: %{x: 0, y: 8}, sync_group: :left_panel)

    right = Viewport.region(body, id: "right-viewport", offset: {3, 21}, sync_group: :right_panel)

    split =
      Viewport.split_pane(left, right,
        id: "editor-split",
        ratio: 0.6,
        primary_size: 60,
        secondary_size: 40,
        sync_scroll: :independent
      )

    assert %Element{
             kind: :split_pane,
             attributes: %{
               split: %{
                 ratio: 0.6,
                 primary_size: 60,
                 secondary_size: 40,
                 sync_scroll: :independent
               }
             }
           } = split

    assert %{viewport: %{offset: %{x: 0, y: 8}, sync_group: :left_panel}} =
             Tree.find_by_id(split, "left-viewport").attributes

    assert %{viewport: %{offset: %{x: 3, y: 21}, sync_group: :right_panel}} =
             Tree.find_by_id(split, "right-viewport").attributes
  end

  test "phase 3 canvas and chart constructs remain portable and free of runtime-local payloads" do
    canvas =
      Canvas.surface(
        [
          [kind: :cell, position: {0, 0}, text: "X"],
          [kind: :fragment, position: {3, 2}, size: {12, 4}, text: "Legend"]
        ],
        id: "surface-canvas",
        width: 80,
        height: 24
      )

    line_chart =
      Canvas.line_chart(
        [
          [id: :cpu, label: "CPU", values: [10, 30, 20]]
        ],
        id: "cpu-chart",
        axes: %{x: %{label: "Time"}, y: %{label: "Percent", min: 0, max: 100}},
        scale: %{x: :linear, y: :percentage}
      )

    shell =
      Layout.column(
        [
          {:content, canvas},
          {:content, line_chart}
        ],
        id: "visual-shell"
      )

    assert %Element{kind: :column} = Invariant.assert_canonical_element!(shell)

    assert %{chart: %{scale: %{x: :linear, y: :percentage}}} =
             Tree.find_by_id(shell, "cpu-chart").attributes

    assert %{canvas: %{operations: [%{kind: :cell}, %{kind: :fragment}]}} =
             Tree.find_by_id(shell, "surface-canvas").attributes
  end

  test "phase 3 operational widgets preserve structured metadata needed for runtime realization" do
    stream =
      Advanced.stream_widget(
        [
          [id: "evt-1", message: "ready", severity: :info, timestamp: ~U[2026-03-14 12:00:00Z]],
          [
            id: "evt-2",
            message: "degraded",
            severity: :warning,
            timestamp: ~U[2026-03-14 12:01:00Z]
          ]
        ],
        id: "event-stream",
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

    monitor =
      Advanced.process_monitor(
        [
          [id: "proc-1", pid: "#PID<0.10.0>", state: :running, cpu: 12]
        ],
        id: "process-monitor"
      )

    cluster =
      Advanced.cluster_dashboard(
        [
          [id: "node-a", status: :up],
          [id: "node-b", status: :degraded]
        ],
        id: "cluster-dashboard",
        summary: %{healthy: 1, degraded: 1}
      )

    dashboard =
      Layout.column(
        [
          {:content, stream},
          {:content, logs},
          {:content, monitor},
          {:content, cluster}
        ],
        id: "ops-dashboard"
      )

    assert %{
             total_elements: 5,
             type_histogram: %{layout: 1, widget: 4}
           } = Reference.summarize_tree(dashboard)

    assert %{stream: %{severity_field: :severity, timestamp_field: :timestamp}} =
             Tree.find_by_id(dashboard, "event-stream").attributes
  end

  test "phase 3 command, markdown, and inspection constructs compose with layout and layering systems" do
    command_palette =
      Advanced.command_palette(
        [
          [id: :open, label: "Open file"],
          [id: :save, label: "Save file"]
        ],
        id: "command-palette",
        query: "op",
        active_command: :open
      )

    markdown = Advanced.markdown_viewer("# Release Notes", id: "release-notes")

    supervision =
      Advanced.supervision_tree_viewer(
        [
          [
            id: :root_sup,
            label: "Root Supervisor",
            type: :supervisor,
            children: [[id: :worker, label: "Worker", type: :worker]]
          ]
        ],
        id: "supervision-tree"
      )

    inspector =
      Layout.column(
        [
          {:content, command_palette},
          {:content, markdown},
          {:content, supervision}
        ],
        id: "inspector-column"
      )

    layered =
      Layer.overlay(
        Container.box([{:content, Foundational.text("Workspace", id: "workspace-copy")}],
          id: "workspace-base"
        ),
        [
          {:overlay, inspector}
        ],
        id: "inspector-overlay"
      )

    assert %Element{kind: :overlay} = layered
    assert %Element{kind: :column} = List.last(layered.children).element

    assert %{command_palette: %{active_command: :open}} =
             Tree.find_by_id(layered, "command-palette").attributes
  end

  test "phase 3 equivalent operational screens yield deterministic canonical shapes across complex nested displays" do
    left =
      Layer.overlay(
        Viewport.region(
          Advanced.markdown_viewer("# Ops", id: "ops-doc"),
          id: "ops-viewport",
          offset: {0, 4}
        ),
        [
          {:overlay,
           Advanced.command_palette(
             [
               [id: :open, label: "Open"]
             ],
             id: "ops-palette",
             query: "op"
           )},
          {:overlay, Canvas.sparkline([1, 3, 2], id: "ops-sparkline")}
        ],
        id: "ops-overlay"
      )

    right =
      Layer.overlay(
        Viewport.region(
          Advanced.markdown_viewer("# Ops", %{"id" => "ops-doc"}),
          %{"id" => "ops-viewport", "offset" => %{"x" => 0, "y" => 4}}
        ),
        [
          {:overlay,
           Advanced.command_palette(
             [
               %{"id" => :open, "label" => "Open"}
             ],
             %{"id" => "ops-palette", "query" => "op"}
           )},
          {:overlay, Canvas.sparkline([1, 3, 2], %{"id" => "ops-sparkline"})}
        ],
        %{"id" => "ops-overlay"}
      )

    assert :ok = Invariant.assert_shape_stable!(left, right)
    assert Tree.shape_signature(left) == Tree.shape_signature(right)

    assert Reference.summarize_tree(left).type_histogram ==
             Reference.summarize_tree(right).type_histogram
  end
end
