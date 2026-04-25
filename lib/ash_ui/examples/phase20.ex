defmodule AshUI.Examples.Phase20 do
  @moduledoc """
  Phase 20 example-suite definitions and path helpers.

  The standalone example directories under `examples/` are generated from these
  definitions so the checked-in projects, tests, and planning artifacts stay in
  sync while the advanced example families land section by section.
  """

  @type definition :: %{
          directory: String.t(),
          section: atom(),
          family: atom(),
          title: String.t(),
          subject_type: atom(),
          subject_props: map(),
          story_text: String.t(),
          signal_text: String.t(),
          seed_state: map(),
          preview_field: atom() | nil,
          preview_title: String.t() | nil,
          subject_binding: map() | nil,
          subject_action: map() | nil,
          subject_children: [map()],
          support_notice: String.t() | nil,
          notes: String.t() | nil
        }

  @sections [
    :overlay_layered_flows,
    :data_surfaces,
    :feedback_charts,
    :operational_monitoring,
    :runtime_realism,
    :integration
  ]

  defp overlay_definitions do
    [
      %{
        directory: "overlay",
        section: :overlay_layered_flows,
        family: :overlay,
        title: "Overlay Example",
        subject_type: :"custom:overlay",
        subject_props: %{
          title: "Inspection overlay",
          description:
            "A layered review surface that opens and dismisses through nested controls.",
          class: "ashui-example-overlay-shell"
        },
        story_text:
          "Meaningful Interaction Story: open the overlay, inspect the layered body copy, and dismiss it again without losing the shared Ash HQ shell around the example.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.enabled -> overlay visibility and status copy inside the explicit `custom:overlay` shell.",
        seed_state: %{
          id: "state-overlay",
          enabled: false,
          status: "Overlay closed until the nested trigger opens it."
        },
        preview_field: :status,
        preview_title: "Overlay state",
        subject_binding: %{
          id: :overlay_open,
          field: :enabled,
          target: "open",
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          slot_text(
            :body,
            :overlay_status_copy,
            "Overlay closed until the nested trigger opens it.",
            "ashui-example-surface-copy",
            0,
            field: :status,
            state_id: "state-overlay"
          ),
          state_button(
            :open_overlay_button,
            "Open overlay",
            "state-overlay",
            %{enabled: true, status: "Overlay opened from the nested trigger."},
            :actions,
            0
          ),
          state_button(
            :dismiss_overlay_button,
            "Dismiss",
            "state-overlay",
            %{enabled: false, status: "Overlay dismissed without leaving the review shell."},
            :actions,
            10,
            "ashui-example-secondary-cta"
          )
        ],
        support_notice:
          "The overlay shell remains explicit `custom:overlay`; open and dismiss semantics stay on nested public button resources.",
        notes: "Uses body and action slots inside an example-only layered surface."
      },
      %{
        directory: "dialog",
        section: :overlay_layered_flows,
        family: :overlay,
        title: "Dialog Example",
        subject_type: :"custom:dialog",
        subject_props: %{
          title: "Confirm handoff",
          description: "A composed dialog shell with nested confirm and cancel controls.",
          class: "ashui-example-dialog-shell"
        },
        story_text:
          "Meaningful Interaction Story: confirm or cancel the dialog and verify that the result lands in persisted runtime state rather than living only inside ephemeral shell markup.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.selected_value and ExampleState.status -> dialog summary copy and preview stat.",
        seed_state: %{
          id: "state-dialog",
          enabled: true,
          selected_value: "awaiting decision",
          status: "Dialog is awaiting a handoff decision."
        },
        preview_field: :selected_value,
        preview_title: "Dialog result",
        subject_binding: %{
          id: :dialog_open,
          field: :enabled,
          target: "open",
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          slot_text(
            :body,
            :dialog_summary,
            "awaiting decision",
            "ashui-example-surface-copy",
            0,
            field: :selected_value,
            state_id: "state-dialog"
          ),
          slot_text(
            :footer,
            :dialog_status,
            "Dialog is awaiting a handoff decision.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-dialog"
          ),
          state_button(
            :confirm_dialog_button,
            "Confirm handoff",
            "state-dialog",
            %{
              enabled: false,
              selected_value: "confirmed",
              status: "Dialog confirmed and dismissed from the nested action row."
            },
            :actions,
            0
          ),
          state_button(
            :cancel_dialog_button,
            "Cancel",
            "state-dialog",
            %{
              enabled: false,
              selected_value: "cancelled",
              status: "Dialog cancelled and dismissed from the nested action row."
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          )
        ],
        support_notice:
          "The dialog shell stays explicit `custom:dialog` while the decision buttons own the action declarations.",
        notes: "Uses body, actions, and footer slots."
      },
      %{
        directory: "alert_dialog",
        section: :overlay_layered_flows,
        family: :overlay,
        title: "Alert Dialog Example",
        subject_type: :"custom:alert_dialog",
        subject_props: %{
          title: "Escalation required",
          description: "A higher-severity confirmation flow with explicit recovery actions.",
          class: "ashui-example-alert-dialog-shell"
        },
        story_text:
          "Meaningful Interaction Story: acknowledge or defer the alert dialog and verify that the persisted status copy shows which recovery path the reviewer chose.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.selected_value -> alert decision summary plus dismissal state on the explicit `custom:alert_dialog` shell.",
        seed_state: %{
          id: "state-alert_dialog",
          enabled: true,
          selected_value: "pending acknowledgement",
          status: "Alert dialog is waiting for an escalation choice."
        },
        preview_field: :selected_value,
        preview_title: "Alert decision",
        subject_binding: %{
          id: :alert_dialog_open,
          field: :enabled,
          target: "open",
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          slot_text(
            :body,
            :alert_dialog_summary,
            "pending acknowledgement",
            "ashui-example-surface-copy",
            0,
            field: :selected_value,
            state_id: "state-alert_dialog"
          ),
          slot_text(
            :footer,
            :alert_dialog_status,
            "Alert dialog is waiting for an escalation choice.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-alert_dialog"
          ),
          state_button(
            :acknowledge_alert_dialog_button,
            "Acknowledge",
            "state-alert_dialog",
            %{
              enabled: false,
              selected_value: "acknowledged",
              status: "Alert acknowledged and the dialog closed through the destructive action."
            },
            :actions,
            0
          ),
          state_button(
            :defer_alert_dialog_button,
            "Keep for later",
            "state-alert_dialog",
            %{
              enabled: false,
              selected_value: "deferred",
              status: "Alert deferred and the dialog closed with a recovery note."
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          )
        ],
        support_notice:
          "The alert-dialog shell remains explicit `custom:alert_dialog`; severity semantics stay readable in persisted state and nested action resources.",
        notes: "Uses the same layered shell contract with stronger alert copy."
      },
      %{
        directory: "context_menu",
        section: :overlay_layered_flows,
        family: :overlay,
        title: "Context Menu Example",
        subject_type: :"custom:context_menu",
        subject_props: %{
          title: "Row actions",
          description: "A focused action menu that opens around one review target.",
          class: "ashui-example-context-menu-shell"
        },
        story_text:
          "Meaningful Interaction Story: open the context menu, choose one action, and verify the chosen operation is reflected in persisted summary copy and preview state.",
        signal_text:
          "Canonical Signal Preview: nested menu button click -> ExampleState.selected_value -> context-menu summary text and footer status.",
        seed_state: %{
          id: "state-context_menu",
          enabled: true,
          selected_value: "inspect record",
          status: "Context menu is focused on one record-level action set."
        },
        preview_field: :selected_value,
        preview_title: "Chosen action",
        subject_binding: %{
          id: :context_menu_open,
          field: :enabled,
          target: "open",
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          state_button(
            :inspect_record_button,
            "Inspect record",
            "state-context_menu",
            %{
              selected_value: "inspect record",
              status: "Inspect record selected from the nested context menu."
            },
            :menu,
            0,
            "ashui-example-nav-button"
          ),
          state_button(
            :reassign_owner_button,
            "Reassign owner",
            "state-context_menu",
            %{
              selected_value: "reassign owner",
              status: "Reassign owner selected from the nested context menu."
            },
            :menu,
            10,
            "ashui-example-nav-button"
          ),
          state_button(
            :add_watcher_button,
            "Add watcher",
            "state-context_menu",
            %{
              selected_value: "add watcher",
              status: "Add watcher selected from the nested context menu."
            },
            :menu,
            20,
            "ashui-example-nav-button"
          ),
          slot_text(
            :body,
            :context_menu_summary,
            "inspect record",
            "ashui-example-surface-copy",
            0,
            field: :selected_value,
            state_id: "state-context_menu"
          ),
          slot_text(
            :footer,
            :context_menu_status,
            "Context menu is focused on one record-level action set.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-context_menu"
          )
        ],
        support_notice:
          "The context-menu shell stays explicit `custom:context_menu`; the menu items remain plain button resources with persisted action outcomes.",
        notes: "Uses menu, body, and footer slots."
      },
      %{
        directory: "toast",
        section: :overlay_layered_flows,
        family: :overlay,
        title: "Toast Example",
        subject_type: :"custom:toast",
        subject_props: %{
          title: "Activity toast",
          description: "A transient-style notification shell driven by persisted runtime fields.",
          class: "ashui-example-toast-shell"
        },
        story_text:
          "Meaningful Interaction Story: trigger different toast variants and confirm the visible message and status copy update through nested controls instead of hard-coded shell text.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.current_value and ExampleState.status -> toast body copy and preview stat inside the explicit `custom:toast` shell.",
        seed_state: %{
          id: "state-toast",
          enabled: true,
          current_value: "No toast triggered yet.",
          status: "Toast example is waiting for a nested trigger."
        },
        preview_field: :current_value,
        preview_title: "Toast message",
        subject_binding: %{
          id: :toast_visible,
          field: :enabled,
          target: "visible",
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          slot_text(
            :body,
            :toast_copy,
            "No toast triggered yet.",
            "ashui-example-surface-copy",
            0,
            field: :current_value,
            state_id: "state-toast"
          ),
          slot_text(
            :footer,
            :toast_status,
            "Toast example is waiting for a nested trigger.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-toast"
          ),
          state_button(
            :send_success_toast_button,
            "Send success toast",
            "state-toast",
            %{
              current_value: "Deployment verified. Success toast delivered.",
              status: "Success toast triggered from the nested action row."
            },
            :actions,
            0
          ),
          state_button(
            :send_risk_toast_button,
            "Send risk toast",
            "state-toast",
            %{
              current_value: "Risk signal elevated. Recovery toast delivered.",
              status: "Risk toast triggered from the nested action row."
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          )
        ],
        support_notice:
          "The toast shell remains explicit `custom:toast`; trigger semantics stay on nested button resources and persisted runtime fields.",
        notes: "Uses body, footer, and action slots."
      }
    ]
  end

  defp data_surface_definitions do
    [
      %{
        directory: "list",
        section: :data_surfaces,
        family: :data_surface,
        title: "List Example",
        subject_type: :list,
        subject_props: %{
          title: "Review queue",
          description:
            "A bound list surface that refreshes its rows from persisted runtime data.",
          empty_text: "No review rows available.",
          class: "ashui-example-list-surface"
        },
        story_text:
          "Meaningful Interaction Story: switch between review queues and confirm the collection surface refreshes through a list binding instead of hard-coded inline rows.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.items -> hydrated `list` props.items plus preview status inside the shared Ash HQ shell.",
        seed_state: %{
          id: "state-list",
          current_value: "triage queue",
          status: "List binding mounted with the triage queue.",
          items: [
            %{
              "title" => "Urgent approvals",
              "summary" => "4 records are waiting for owner review.",
              "meta" => "SLA 15m"
            },
            %{
              "title" => "Escalation follow-ups",
              "summary" => "2 records need a second reviewer.",
              "meta" => "SLA 30m"
            },
            %{
              "title" => "Customer callbacks",
              "summary" => "3 callbacks are staged for the next handoff.",
              "meta" => "SLA 60m"
            }
          ]
        },
        preview_field: :current_value,
        preview_title: "Active queue",
        subject_binding: %{
          id: :list_items,
          field: :items,
          target: "items",
          binding_type: :list,
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          state_button(
            :load_triage_queue_button,
            "Load triage queue",
            "state-list",
            %{
              current_value: "triage queue",
              status: "List binding mounted with the triage queue.",
              items: [
                %{
                  "title" => "Urgent approvals",
                  "summary" => "4 records are waiting for owner review.",
                  "meta" => "SLA 15m"
                },
                %{
                  "title" => "Escalation follow-ups",
                  "summary" => "2 records need a second reviewer.",
                  "meta" => "SLA 30m"
                },
                %{
                  "title" => "Customer callbacks",
                  "summary" => "3 callbacks are staged for the next handoff.",
                  "meta" => "SLA 60m"
                }
              ]
            },
            :actions,
            0
          ),
          state_button(
            :load_handoff_queue_button,
            "Load handoff queue",
            "state-list",
            %{
              current_value: "handoff queue",
              status: "List binding switched to the handoff queue.",
              items: [
                %{
                  "title" => "Shift summary packet",
                  "summary" => "Ready for the next operator handoff.",
                  "meta" => "Owner Maya"
                },
                %{
                  "title" => "Paging rota changes",
                  "summary" => "Needs explicit confirmation before shift close.",
                  "meta" => "Owner Idris"
                },
                %{
                  "title" => "Retention audit",
                  "summary" => "Queued for overnight review and logging.",
                  "meta" => "Owner Jules"
                }
              ]
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          ),
          slot_text(
            :footer,
            :list_status,
            "List binding mounted with the triage queue.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-list"
          )
        ],
        support_notice:
          "The `list` example uses a real list binding on the maintained public widget instead of hiding collection changes inside static markup.",
        notes:
          "Actions switch the bound collection while the subject surface stays a maintained public widget."
      },
      %{
        directory: "table",
        section: :data_surfaces,
        family: :data_surface,
        title: "Table Example",
        subject_type: :table,
        subject_props: %{
          title: "Service handoff table",
          description: "A tabular collection bound to persisted row data.",
          columns: [
            %{"key" => "service", "label" => "Service"},
            %{"key" => "owner", "label" => "Owner"},
            %{"key" => "status", "label" => "Status"}
          ],
          class: "ashui-example-table-surface"
        },
        story_text:
          "Meaningful Interaction Story: switch the active operational dataset and confirm the table rows refresh through list binding hydration instead of a one-shot render.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.items -> hydrated `table` props.items plus preview value for the active dataset.",
        seed_state: %{
          id: "state-table",
          current_value: "service readiness",
          status: "Table binding mounted with the service readiness dataset.",
          items: [
            %{"service" => "API gateway", "owner" => "Maya", "status" => "Ready"},
            %{"service" => "Worker pool", "owner" => "Noah", "status" => "Watching"},
            %{"service" => "Billing sync", "owner" => "Tariq", "status" => "Needs note"}
          ]
        },
        preview_field: :current_value,
        preview_title: "Active dataset",
        subject_binding: %{
          id: :table_items,
          field: :items,
          target: "items",
          binding_type: :list,
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          state_button(
            :load_service_readiness_button,
            "Service readiness",
            "state-table",
            %{
              current_value: "service readiness",
              status: "Table binding mounted with the service readiness dataset.",
              items: [
                %{"service" => "API gateway", "owner" => "Maya", "status" => "Ready"},
                %{"service" => "Worker pool", "owner" => "Noah", "status" => "Watching"},
                %{"service" => "Billing sync", "owner" => "Tariq", "status" => "Needs note"}
              ]
            },
            :actions,
            0
          ),
          state_button(
            :load_handoff_board_button,
            "Handoff board",
            "state-table",
            %{
              current_value: "handoff board",
              status: "Table binding switched to the handoff board dataset.",
              items: [
                %{"service" => "Ops notes", "owner" => "Idris", "status" => "Shared"},
                %{"service" => "Escalations", "owner" => "Jules", "status" => "Pending"},
                %{"service" => "Regional sync", "owner" => "Ari", "status" => "Queued"}
              ]
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          ),
          slot_text(
            :footer,
            :table_status,
            "Table binding mounted with the service readiness dataset.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-table"
          )
        ],
        support_notice:
          "The `table` example keeps its columns static but refreshes the visible row collection through bound runtime data.",
        notes: "Uses collection hydration for the maintained public `table` widget."
      },
      %{
        directory: "tree_view",
        section: :data_surfaces,
        family: :data_surface,
        title: "Tree View Example",
        subject_type: :"custom:tree_view",
        subject_props: %{
          title: "System topology",
          description: "A nested review surface that shows hierarchical runtime structure.",
          class: "ashui-example-tree-view-shell"
        },
        story_text:
          "Meaningful Interaction Story: switch the focused hierarchy and confirm the tree viewer redraws its nested branches from persisted runtime data rather than a static shell.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.items -> bound tree model plus selected-branch preview.",
        seed_state: %{
          id: "state-tree_view",
          selected_value: "runtime graph",
          status: "Tree viewer mounted with the runtime hierarchy.",
          items: [
            %{
              "label" => "Runtime graph",
              "meta" => "Primary",
              "children" => [
                %{"label" => "Phoenix endpoint", "meta" => "Healthy"},
                %{"label" => "Binding runtime", "meta" => "Healthy"},
                %{
                  "label" => "Event pipeline",
                  "meta" => "Watching",
                  "children" => [
                    %{"label" => "Action events", "meta" => "Ready"},
                    %{"label" => "Value changes", "meta" => "Ready"}
                  ]
                }
              ]
            }
          ]
        },
        preview_field: :selected_value,
        preview_title: "Focused branch",
        subject_binding: %{
          id: :tree_model,
          field: :items,
          target: "model",
          binding_type: :value,
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          state_button(
            :load_runtime_tree_button,
            "Runtime graph",
            "state-tree_view",
            %{
              selected_value: "runtime graph",
              status: "Tree viewer mounted with the runtime hierarchy.",
              items: [
                %{
                  "label" => "Runtime graph",
                  "meta" => "Primary",
                  "children" => [
                    %{"label" => "Phoenix endpoint", "meta" => "Healthy"},
                    %{"label" => "Binding runtime", "meta" => "Healthy"},
                    %{
                      "label" => "Event pipeline",
                      "meta" => "Watching",
                      "children" => [
                        %{"label" => "Action events", "meta" => "Ready"},
                        %{"label" => "Value changes", "meta" => "Ready"}
                      ]
                    }
                  ]
                }
              ]
            },
            :actions,
            0
          ),
          state_button(
            :load_rollout_tree_button,
            "Rollout graph",
            "state-tree_view",
            %{
              selected_value: "rollout graph",
              status: "Tree viewer switched to the rollout hierarchy.",
              items: [
                %{
                  "label" => "Rollout graph",
                  "meta" => "Primary",
                  "children" => [
                    %{"label" => "Canary cohort", "meta" => "12%"},
                    %{"label" => "Regional wave", "meta" => "Queued"},
                    %{
                      "label" => "Recovery plan",
                      "meta" => "Prepared",
                      "children" => [
                        %{"label" => "Feature flag rollback", "meta" => "Ready"},
                        %{"label" => "Operator broadcast", "meta" => "Ready"}
                      ]
                    }
                  ]
                }
              ]
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          ),
          slot_text(
            :footer,
            :tree_status,
            "Tree viewer mounted with the runtime hierarchy.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-tree_view"
          )
        ],
        support_notice:
          "The tree example uses an explicit custom shell because hierarchical disclosure rendering is not a maintained public fallback surface.",
        notes: "Binds one structured tree model map into the example-only renderer."
      },
      %{
        directory: "markdown_viewer",
        section: :data_surfaces,
        family: :data_surface,
        title: "Markdown Viewer Example",
        subject_type: :"custom:markdown_viewer",
        subject_props: %{
          title: "Review notes",
          description: "A document viewer that swaps between authored markdown sources.",
          class: "ashui-example-markdown-shell"
        },
        story_text:
          "Meaningful Interaction Story: switch the active document and confirm the markdown viewer updates its rendered body from persisted runtime content instead of duplicated static copy.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.notes -> bound markdown content plus active-document preview.",
        seed_state: %{
          id: "state-markdown_viewer",
          current_value: "incident guide",
          status: "Markdown viewer mounted with the incident guide.",
          notes: """
          # Incident Guide

          - Confirm the alert scope.
          - Capture the current owner.
          - Record the next handoff window.
          """
        },
        preview_field: :current_value,
        preview_title: "Active document",
        subject_binding: %{
          id: :markdown_content,
          field: :notes,
          target: "content",
          binding_type: :value,
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          state_button(
            :load_incident_guide_button,
            "Incident guide",
            "state-markdown_viewer",
            %{
              current_value: "incident guide",
              status: "Markdown viewer mounted with the incident guide.",
              notes: """
              # Incident Guide

              - Confirm the alert scope.
              - Capture the current owner.
              - Record the next handoff window.
              """
            },
            :actions,
            0
          ),
          state_button(
            :load_release_notes_button,
            "Release notes",
            "state-markdown_viewer",
            %{
              current_value: "release notes",
              status: "Markdown viewer switched to the release notes.",
              notes: """
              # Release Notes

              ## Rollout

              - Canary enabled for `us-east-1`.
              - Queue rebalance completed.
              - Recovery checklist attached.
              """
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          ),
          slot_text(
            :footer,
            :markdown_status,
            "Markdown viewer mounted with the incident guide.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-markdown_viewer"
          )
        ],
        support_notice:
          "The markdown viewer stays an explicit custom example shell because the fallback renderer does not expose markdown semantics as a maintained public widget.",
        notes: "Binds markdown content into a renderer-backed document surface."
      },
      %{
        directory: "log_viewer",
        section: :data_surfaces,
        family: :data_surface,
        title: "Log Viewer Example",
        subject_type: :"custom:log_viewer",
        subject_props: %{
          title: "Event stream",
          description: "A bounded log review surface fed by persisted runtime rows.",
          class: "ashui-example-log-shell"
        },
        story_text:
          "Meaningful Interaction Story: switch the active stream and confirm the visible log rows refresh through persisted runtime data rather than one fixed code sample.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.items -> bound log entries plus active-stream preview state.",
        seed_state: %{
          id: "state-log_viewer",
          current_value: "live tail",
          status: "Log viewer mounted with the live application tail.",
          items: [
            %{
              "timestamp" => "12:04:19",
              "level" => "INFO",
              "message" => "Ash UI screen mounted with 5 element bindings."
            },
            %{
              "timestamp" => "12:04:26",
              "level" => "WARN",
              "message" => "Escalation queue crossed the review threshold."
            },
            %{
              "timestamp" => "12:04:33",
              "level" => "INFO",
              "message" => "Operator acknowledged the handoff packet."
            }
          ]
        },
        preview_field: :current_value,
        preview_title: "Active stream",
        subject_binding: %{
          id: :log_entries,
          field: :items,
          target: "entries",
          binding_type: :value,
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          state_button(
            :load_live_tail_button,
            "Live tail",
            "state-log_viewer",
            %{
              current_value: "live tail",
              status: "Log viewer mounted with the live application tail.",
              items: [
                %{
                  "timestamp" => "12:04:19",
                  "level" => "INFO",
                  "message" => "Ash UI screen mounted with 5 element bindings."
                },
                %{
                  "timestamp" => "12:04:26",
                  "level" => "WARN",
                  "message" => "Escalation queue crossed the review threshold."
                },
                %{
                  "timestamp" => "12:04:33",
                  "level" => "INFO",
                  "message" => "Operator acknowledged the handoff packet."
                }
              ]
            },
            :actions,
            0
          ),
          state_button(
            :load_deploy_stream_button,
            "Deploy stream",
            "state-log_viewer",
            %{
              current_value: "deploy stream",
              status: "Log viewer switched to the deploy stream.",
              items: [
                %{
                  "timestamp" => "12:31:04",
                  "level" => "INFO",
                  "message" => "Canary deployment reached 25% of target traffic."
                },
                %{
                  "timestamp" => "12:31:18",
                  "level" => "INFO",
                  "message" => "Telemetry check passed for worker saturation."
                },
                %{
                  "timestamp" => "12:31:26",
                  "level" => "ERROR",
                  "message" => "Billing sync reported one retriable write failure."
                }
              ]
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          ),
          slot_text(
            :footer,
            :log_status,
            "Log viewer mounted with the live application tail.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-log_viewer"
          )
        ],
        support_notice:
          "The log viewer remains a custom example surface while still using persisted runtime rows and nested public controls for state changes.",
        notes: "Uses a bound entry list and nested controls to swap representative streams."
      }
    ]
  end

  defp state_button(
         key,
         label,
         state_id,
         params,
         slot,
         position,
         class \\ "ashui-example-primary-cta"
       ) do
    %{
      key: key,
      type: :button,
      props: %{
        label: label,
        variant: "secondary",
        class: class
      },
      slot: slot,
      position: position,
      actions: [
        %{
          id: String.to_atom("action_#{key}"),
          signal: :click,
          source: %{resource: "ExampleState", action: "update", id: state_id},
          target: "submit",
          transform: %{params: static_params(params)},
          metadata: %{intent: "update_example_state", success_message: "Layered state updated"}
        }
      ],
      children: []
    }
  end

  defp static_params(params) do
    Map.new(params, fn {key, value} ->
      {key, %{"from" => "static", "value" => value}}
    end)
  end

  defp slot_text(slot, key, content, class, position, opts) do
    text = %{
      key: key,
      type: :text,
      props: %{content: content, class: class},
      slot: slot,
      position: position,
      children: []
    }

    case Keyword.fetch(opts, :field) do
      {:ok, field} ->
        state_id = Keyword.fetch!(opts, :state_id)
        target = Keyword.get(opts, :target, "content")
        metadata = Keyword.get(opts, :metadata, %{owner: Atom.to_string(slot)})

        Map.put(text, :bindings, [
          %{
            id: :"#{key}_binding",
            source: %{resource: "ExampleState", field: field, id: state_id},
            target: target,
            binding_type: :value,
            transform: %{},
            metadata: metadata
          }
        ])

      :error ->
        text
    end
  end

  @doc """
  Returns every currently authored Phase 20 definition.
  """
  @spec definitions() :: [definition()]
  def definitions do
    overlay_definitions() ++ data_surface_definitions()
  end

  @doc """
  Returns the authored sections known to Phase 20.
  """
  @spec sections() :: [atom()]
  def sections, do: @sections

  @doc """
  Returns the definitions for one section.
  """
  @spec definitions_for(atom()) :: [definition()]
  def definitions_for(section) when section in @sections do
    Enum.filter(definitions(), &(&1.section == section))
  end

  @doc """
  Fetches one definition by directory name.
  """
  @spec definition!(String.t()) :: definition()
  def definition!(directory) when is_binary(directory) do
    Enum.find(definitions(), &(&1.directory == directory)) ||
      raise ArgumentError, "unknown Phase 20 example directory: #{inspect(directory)}"
  end

  @doc """
  Returns the app atom for a generated standalone example.
  """
  @spec app_atom(String.t()) :: atom()
  def app_atom(directory) when is_binary(directory) do
    String.to_atom("ash_ui_example_#{directory}")
  end

  @doc """
  Returns the root Elixir module for a generated standalone example.
  """
  @spec example_module(String.t()) :: module()
  def example_module(directory) when is_binary(directory) do
    directory
    |> Macro.camelize()
    |> then(&Module.concat([AshUIExamples, &1]))
  end

  @doc """
  Returns the canonical screen name for one example directory.
  """
  @spec screen_name(String.t()) :: String.t()
  def screen_name(directory) when is_binary(directory), do: "example/#{directory}"

  @doc """
  Returns the on-disk example project path for a directory.
  """
  @spec project_path(String.t()) :: String.t()
  def project_path(directory) when is_binary(directory) do
    Path.expand("../../../examples/#{directory}", __DIR__)
  end

  @doc """
  Returns every currently authored example directory.
  """
  @spec directories() :: [String.t()]
  def directories do
    definitions()
    |> Enum.map(& &1.directory)
    |> Enum.sort()
  end
end
