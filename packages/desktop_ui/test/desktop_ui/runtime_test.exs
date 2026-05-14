defmodule DesktopUi.RuntimeTest do
  use ExUnit.Case, async: true

  alias DesktopUi.Runtime
  alias DesktopUi.Runtime.Error

  test "mounts a minimal native screen through the shared runtime backbone" do
    root =
      DesktopUi.Widgets.window("workspace-window", "Workspace", [
        DesktopUi.Widgets.text("workspace-title", "Workspace"),
        DesktopUi.Widgets.button("save-button", "Save", intent: :save_workspace)
      ])

    screen = %{id: "workspace", title: "Workspace", root: root}

    assert {:ok, state} = Runtime.mount_native_screen(screen, platform_target: :linux)
    assert state.runtime_id == "desktop-ui:workspace"
    assert state.screen_id == "workspace"
    assert state.source_kind == :native
    assert state.platform_target == :linux
    assert state.platform_adapter.target == :linux
    assert state.windows.primary == "window:workspace"
    assert state.redraw.status == :idle
    assert state.realization.validation_state == :foundational_ready
    assert state.event_loop.poller.source == :sdl_event_queue
    assert state.event_loop.input_dispatch.boundary_mode == :canonical_boundary_ready
    assert state.focus.current == "workspace-window"
    assert state.focus.order == ["workspace-window", "save-button"]
    assert state.event_loop.local_events == 0
    assert state.event_loop.boundary_events == 0
    assert state.event_log == []
    assert state.realization.binding_index == %{}
    assert state.realization.event_targets == %{"save-button" => [:click]}
    assert state.realization.diagnostics.layout_guards == :ready
    assert state.screen.composition.root_kind == :window
    assert state.screen.composition.shared_realization
  end

  test "invalid screen input fails with deterministic diagnostics" do
    assert {:error, %Error{} = missing_root_error} =
             Runtime.mount_native_screen(%{id: "broken", title: "Broken"})

    assert missing_root_error.reason == :invalid_screen
    assert :root in missing_root_error.details.missing_keys

    assert {:error, %Error{} = invalid_root_error} =
             Runtime.mount_native_screen(%{id: "broken", title: "Broken", root: %{label: "oops"}})

    assert invalid_root_error.reason == :invalid_screen_root
    assert invalid_root_error.phase == :runtime_boot

    assert {:error, %Error{} = invalid_platform_error} =
             Runtime.mount_native_screen(
               %{
                 id: "broken",
                 title: "Broken",
                 root: %DesktopUi.Widget{id: "root", kind: :window}
               },
               platform_target: :android
             )

    assert invalid_platform_error.reason == :unsupported_platform_target
  end

  test "realization indexes bindings, focus order, and event targets for foundational screens" do
    screen = %{
      id: "workspace",
      title: "Workspace",
      root:
        DesktopUi.Widgets.window("workspace-window", "Workspace", [
          DesktopUi.Widgets.column("workspace-column", [
            DesktopUi.Widgets.text_input("query-input",
              value: "status:ok",
              binding: :query,
              on_submit: %{intent: :run_query}
            ),
            DesktopUi.Widgets.checkbox("alerts-checkbox", "Alerts",
              checked: true,
              binding: :alerts_enabled
            ),
            DesktopUi.Widgets.tabs(
              "workspace-tabs",
              [%{id: :overview, label: "Overview"}, %{id: :activity, label: "Activity"}],
              current: :overview,
              binding: :active_section
            )
          ])
        ])
    }

    assert {:ok, state} = Runtime.mount_native_screen(screen, platform_target: :linux)

    assert state.screen.bindings.names == [:active_section, :alerts_enabled, :query]

    assert state.focus.order == [
             "workspace-window",
             "query-input",
             "alerts-checkbox",
             "workspace-tabs"
           ]

    assert Map.has_key?(state.realization.binding_index, :query)
    assert Map.has_key?(state.realization.binding_index, :alerts_enabled)
    assert Map.has_key?(state.realization.event_targets, "query-input")
    assert Map.has_key?(state.realization.event_targets, "workspace-tabs")
    assert Enum.any?(state.realization.cell_surface, &(&1.kind == :checkbox))
  end

  test "advanced layout, layered runtime, and multiwindow screens share one realization model" do
    screen = %{
      id: "operations",
      title: "Operations",
      root:
        DesktopUi.Layer.multi_window("operations-windows", [
          DesktopUi.Widgets.window("operations-window", "Operations", [
            DesktopUi.Layer.overlay(
              "operations-overlay",
              DesktopUi.Layout.split_pane(
                "operations-split",
                DesktopUi.Layout.viewport(
                  "services-viewport",
                  DesktopUi.Widgets.table(
                    "services-table",
                    [%{id: :service, label: "Service"}],
                    [%{id: :api, cells: ["API"]}],
                    selection_binding: :selected_service
                  )
                ),
                DesktopUi.Widgets.column("operations-sidebar", [
                  DesktopUi.Widgets.log_viewer(
                    "operations-log",
                    [%{id: "entry-1", message: "Booted"}],
                    query_binding: :log_query
                  ),
                  DesktopUi.Widgets.gauge("cpu-gauge", value: 72, label: "CPU")
                ]),
                ratio: 0.6
              ),
              [
                DesktopUi.Widgets.dialog("ops-dialog", "Runbook", [
                  DesktopUi.Widgets.text("dialog-copy", "Runbook loaded")
                ])
              ]
            )
          ]),
          DesktopUi.Widgets.window("details-window", "Details", [
            DesktopUi.Widgets.process_monitor(
              "process-monitor",
              [%{id: :beam, name: "beam.smp"}],
              selection_binding: :selected_process
            )
          ])
        ])
    }

    assert {:ok, state} = Runtime.mount_native_screen(screen, platform_target: :linux)
    assert state.realization.validation_state == :advanced_ready
    assert length(state.realization.layers) >= 2
    assert Enum.any?(state.realization.viewport_regions, &(&1.kind == :viewport))
    assert state.windows.continuity == :multi_window
    assert state.windows.primary == "window:operations-window"
    assert state.windows.secondary_ids == ["window:details-window"]
    assert Enum.sort(state.realization.window_ids) == ["details-window", "operations-window"]
    assert state.screen.composition.window_count == 2
  end

  test "shared runtime routing preserves local desktop handling and canonical boundary translation" do
    native_screen = DesktopUi.Examples.native_foundational_screen()
    canonical_screen = DesktopUi.Examples.canonical_foundational_screen()

    assert {:ok, native_state} =
             Runtime.mount_native_screen(native_screen, platform_target: :linux)

    assert {:ok, canonical_state} =
             Runtime.mount_iur_screen(canonical_screen, platform_target: :linux)

    assert {:ok, focused_state, local_route} =
             Runtime.dispatch_native_event(native_state,
               input_family: :focus,
               boundary: :local,
               focus_target: "workspace-tabs",
               widget_id: "workspace-tabs",
               intent: :focus_workspace_tabs
             )

    assert local_route.route == :local_runtime
    assert local_route.family == :focus
    assert local_route.translation.signal == nil
    assert focused_state.focus.current == "workspace-tabs"
    assert focused_state.event_loop.local_events == 1

    assert {:ok, boundary_state, boundary_route} =
             Runtime.dispatch_widget_interaction(
               canonical_state,
               "refresh-command",
               :command,
               intent: :refresh_workspace,
               runtime_event: "shortcut:refresh_workspace",
               payload: %{command: :refresh}
             )

    assert boundary_route.route == :canonical_boundary
    assert boundary_route.family == :command
    assert boundary_route.translation.signal.type == "desktop_ui.command.refresh_workspace"
    assert boundary_state.event_loop.boundary_events == 1

    assert List.last(boundary_state.event_log).signal_type ==
             "desktop_ui.command.refresh_workspace"

    assert {:ok, inbound_state, inbound_route} =
             Runtime.handle_boundary_signal(boundary_state, boundary_route.translation.signal)

    assert inbound_route.route == :canonical_boundary
    assert inbound_route.family == :command
    assert inbound_state.event_loop.boundary_events == 2
  end
end
