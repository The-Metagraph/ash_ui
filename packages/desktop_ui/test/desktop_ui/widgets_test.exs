defmodule DesktopUi.WidgetsTest do
  use ExUnit.Case, async: true

  test "foundational native widgets cover content, action, input, and navigation families" do
    screen =
      DesktopUi.Widgets.window("workspace", "Workspace", [
        DesktopUi.Widgets.column("body", [
          DesktopUi.Widgets.content("header", [
            DesktopUi.Widgets.icon("workspace-icon", :workspace),
            DesktopUi.Widgets.label("title-label", "Workspace"),
            DesktopUi.Widgets.text("title", "Native Desktop Workspace")
          ]),
          DesktopUi.Widgets.text_input("name", placeholder: "Name", binding: :workspace_name),
          DesktopUi.Widgets.checkbox("alerts", "Alerts", checked: true, binding: :alerts_enabled),
          DesktopUi.Widgets.radio_group(
            "view-mode",
            [%{id: :overview, label: "Overview"}, %{id: :activity, label: "Activity"}],
            selected: :overview,
            binding: :view_mode
          ),
          DesktopUi.Widgets.tabs(
            "navigation-tabs",
            [%{id: :overview, label: "Overview"}, %{id: :activity, label: "Activity"}],
            current: :overview,
            binding: :active_tab
          ),
          DesktopUi.Widgets.list(
            "results-list",
            [%{id: :alpha, label: "Alpha"}, %{id: :beta, label: "Beta"}],
            current: :alpha,
            binding: :selected_result
          ),
          DesktopUi.Widgets.button("save", "Save", intent: :save_workspace),
          DesktopUi.Widgets.command("refresh", "Refresh",
            shortcut: "Cmd+R",
            intent: :refresh_workspace
          )
        ])
      ])

    assert screen.kind == :window
    assert screen.family == :window
    assert screen.attributes.window_title == "Workspace"
    assert Enum.any?(screen.children, &(&1.kind == :column))
    assert :content in DesktopUi.Widgets.kinds()
    assert :checkbox in DesktopUi.Widgets.kinds()
    assert :tabs in DesktopUi.Widgets.kinds()
    assert DesktopUi.Widgets.family_for_kind(:tabs) == :navigation
    assert DesktopUi.Widgets.registration_model().direct_native_only
    refute DesktopUi.Widgets.registration_model().canonical_branching
    assert DesktopUi.Widgets.validation_state().foundational_content_widgets == :ready
    assert DesktopUi.Widgets.validation_state().foundational_navigation_widgets == :ready
    assert :checked in DesktopUi.Widget.contract().bindings
    assert :window_title in DesktopUi.Widget.contract().attributes
    assert :shortcut in DesktopUi.Widget.contract().metadata
    assert :selection in DesktopUi.Widget.contract().events
  end

  test "widget helpers preserve focus, binding, and shortcut metadata for foundational families" do
    shortcut_command =
      DesktopUi.Widgets.command("save-command", "Save",
        shortcut: "Cmd+S",
        intent: :save_workspace
      )

    checkbox =
      DesktopUi.Widgets.checkbox("toggle-notifications", "Notifications",
        checked: true,
        binding: :notifications_enabled
      )

    tabs =
      DesktopUi.Widgets.tabs(
        "workspace-sections",
        [%{id: :overview, label: "Overview"}, %{id: :settings, label: "Settings"}],
        current: :overview,
        binding: :section
      )

    assert shortcut_command.metadata.focusable
    assert shortcut_command.metadata.shortcut == "Cmd+S"
    assert shortcut_command.events.shortcut.intent == :save_workspace

    assert checkbox.bindings.checked == :notifications_enabled
    assert checkbox.state.checked

    assert tabs.bindings.current == :section
    assert tabs.attributes.current == :overview
    assert tabs.events.navigation.intent == :navigate
  end

  test "advanced widget families cover data, feedback, visualization, and operational surfaces" do
    table =
      DesktopUi.Widgets.table(
        "services-table",
        [%{id: :service, label: "Service"}, %{id: :status, label: "Status"}],
        [%{id: :api, cells: ["API", "healthy"]}],
        selection_binding: :selected_service,
        sort_key: :service
      )

    dialog =
      DesktopUi.Widgets.dialog(
        "ops-dialog",
        "Operations",
        [
          DesktopUi.Widgets.text("dialog-copy", "Runbook loaded")
        ],
        open: true
      )

    chart =
      DesktopUi.Widgets.bar_chart("service-chart", [%{id: :healthy, values: [4, 6, 8]}])

    palette =
      DesktopUi.Widgets.command_palette(
        "ops-palette",
        [%{id: :reload, label: "Reload"}, %{id: :restart, label: "Restart"}],
        query_binding: :command_query,
        window_identity: :ops_window
      )

    assert table.family == :data
    assert table.bindings.selection == :selected_service
    assert table.metadata.sort_key == :service

    assert dialog.family == :window
    assert dialog.metadata.overlay_role == :dialog
    assert dialog.state.open

    assert chart.family == :visualization
    assert palette.family == :operational
    assert palette.metadata.window_identity == :ops_window

    assert :table in DesktopUi.Widgets.kinds()
    assert :toast in DesktopUi.Widgets.kinds()
    assert :bar_chart in DesktopUi.Widgets.kinds()
    assert :command_palette in DesktopUi.Widgets.kinds()
    assert DesktopUi.Widgets.validation_state().advanced_data_widgets == :ready
    assert DesktopUi.Widgets.validation_state().advanced_operational_widgets == :ready
    assert :selection_mode in DesktopUi.Widget.contract().metadata
    assert :sort in DesktopUi.Widget.contract().events
    assert :columns in DesktopUi.Widget.contract().attributes
  end
end
