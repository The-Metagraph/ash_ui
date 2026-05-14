defmodule ElmUi.RenderPipelineTest do
  use ExUnit.Case, async: true

  test "server view state produces a deterministic foundational render tree" do
    screen =
      ElmUi.Widgets.screen("native-workspace", "Native Workspace", [
        ElmUi.Widgets.content("workspace-header", [
          ElmUi.Widgets.text("workspace-title", "Workspace"),
          ElmUi.Widgets.tabs(
            "workspace-tabs",
            [
              [id: :overview, label: "Overview", active: true],
              [id: :activity, label: "Activity"]
            ],
            active_item: :overview,
            on_navigate: %{intent: :switch_tab}
          )
        ]),
        ElmUi.Widgets.form("workspace-form", [
          ElmUi.Widgets.field_group("query-group", [
            ElmUi.Widgets.field(
              "query-field",
              ElmUi.Widgets.text_input("query-input",
                name: :query,
                value: "Pascal",
                on_focus: %{intent: :focus_query},
                on_change: %{intent: :rename_query}
              ),
              name: :query,
              label: "Search Query",
              help: "Used for preview filtering"
            )
          ])
        ])
      ])

    assert {:ok, state} = ElmUi.Runtime.mount_native_screen(screen)

    payload = ElmUi.ServerRuntime.frontend_payload(state)
    input_node = find_node(payload.tree, "query-input")

    assert payload.tree.dom.tag == "div"
    assert input_node.dom.tag == "input"
    assert input_node.interactions.focusable?
    assert input_node.interactions.editable?
    assert input_node.diagnostics.event_names == [:change, :focus]
  end

  test "frontend realization layers bounded browser state onto the server render tree" do
    screen =
      ElmUi.Widgets.screen("native-dashboard", "Native Dashboard", [
        ElmUi.Widgets.text_input("query-input",
          name: :query,
          value: "",
          on_focus: %{intent: :focus_query}
        )
      ])

    assert {:ok, state} = ElmUi.Runtime.mount_native_screen(screen)
    assert {:ok, model} = ElmUi.Runtime.hydrate_frontend(state)

    assert find_node(model.tree, "query-input").browser.focused? == false

    assert {:ok, focused_model} =
             ElmUi.FrontendRuntime.put_local_state(model, :focused_id, "query-input")

    assert {:ok, editing_model} =
             ElmUi.FrontendRuntime.put_local_state(focused_model, :editing_ids, ["query-input"])

    query_node = find_node(editing_model.tree, "query-input")

    assert query_node.tag == "input"
    assert query_node.browser.focused?
    assert query_node.browser.editing?
    assert editing_model.render_tree == model.render_tree
  end

  test "advanced widgets reuse the same server and frontend render pipeline" do
    screen =
      ElmUi.Widgets.screen("ops-dashboard", "Ops Dashboard", [
        ElmUi.Widgets.table(
          "cluster-table",
          [[id: :name, label: "Name"], [id: :status, label: "Status"]],
          [[id: "node-a", cells: ["Node A", "healthy"]]],
          on_sort: %{intent: :sort_cluster}
        ),
        ElmUi.Widgets.progress("deploy-progress", current: 3, total: 5, label: "Deploy"),
        ElmUi.Widgets.command_palette(
          "ops-command-palette",
          [[id: :restart, label: "Restart Node"]],
          placeholder: "Run command",
          on_command: %{intent: :run_command}
        )
      ])

    assert {:ok, state} = ElmUi.Runtime.mount_native_screen(screen)

    payload = ElmUi.ServerRuntime.frontend_payload(state)
    table_node = find_node(payload.tree, "cluster-table")
    progress_node = find_node(payload.tree, "deploy-progress")
    palette_node = find_node(payload.tree, "ops-command-palette")

    assert table_node.dom.tag == "table"
    assert table_node.dom.role == "grid"
    assert progress_node.dom.tag == "progress"
    assert progress_node.dom.attributes.value == 3
    assert progress_node.dom.attributes.max == 5
    assert palette_node.dom.role == "combobox"
    assert palette_node.interactions.focusable?
    assert palette_node.interactions.editable?

    assert {:ok, model} = ElmUi.Runtime.hydrate_frontend(state)

    assert find_node(model.tree, "ops-command-palette").browser.focusable?
    assert find_node(model.tree, "cluster-table").tag == "table"
  end

  test "display systems and layered widgets reuse the same render and realization flow" do
    overlay =
      ElmUi.Layer.overlay(
        "ops-overlay",
        ElmUi.Layout.split_pane(
          "ops-split",
          ElmUi.Layout.viewport(
            "log-viewport",
            ElmUi.Widgets.log_viewer(
              "ops-log-viewer",
              [[id: "entry-1", message: "Connected", severity: :info]],
              follow: true
            ),
            offset: {0, 120},
            on_scroll: %{intent: :scroll_logs}
          ),
          ElmUi.Widgets.content("details-panel", [
            ElmUi.Widgets.text("details-title", "Details")
          ]),
          ratio: 0.6,
          on_resize: %{intent: :resize_split}
        ),
        [
          ElmUi.Layer.dialog(
            "inspect-dialog",
            ElmUi.Widgets.content("dialog-content", [
              ElmUi.Widgets.text("dialog-copy", "Inspect node")
            ]),
            title: "Inspect Node",
            modal: true
          )
        ],
        on_dismiss: %{intent: :dismiss_overlay}
      )

    screen = ElmUi.Widgets.screen("ops-surface", "Ops Surface", [overlay])

    assert {:ok, state} = ElmUi.Runtime.mount_native_screen(screen)

    payload = ElmUi.ServerRuntime.frontend_payload(state)
    overlay_node = find_node(payload.tree, "ops-overlay")
    viewport_node = find_node(payload.tree, "log-viewport")
    dialog_node = find_node(payload.tree, "inspect-dialog")

    assert overlay_node.dom.role == "presentation"
    assert overlay_node.interactions.interactive?
    assert viewport_node.dom.role == "region"
    assert viewport_node.attributes.offset == %{x: 0, y: 120}
    assert dialog_node.dom.tag == "dialog"
    assert dialog_node.dom.attributes.modal

    assert {:ok, model} = ElmUi.Runtime.hydrate_frontend(state)

    assert find_node(model.tree, "inspect-dialog").browser.focusable?
    assert find_node(model.tree, "log-viewport").tag == "div"
  end

  defp find_node(node, id) when is_map(node) do
    if node.id == id do
      node
    else
      node.slots
      |> Enum.flat_map(& &1.children)
      |> Enum.find_value(&find_node(&1, id))
    end
  end

  defp find_node(nil, _id), do: nil
end
