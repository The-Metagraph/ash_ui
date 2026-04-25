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

  @type runtime_contract_entry :: %{
          required(:mount_actor) => :active_viewer_required,
          required(:mutate_roles) => [atom()],
          required(:subscription_mode) => :seeded_action_refresh | :notification_required,
          required(:shell_state_surface) => atom(),
          required(:shell_state_story) => %{
            required(:loading) => String.t(),
            required(:failure) => String.t(),
            required(:recovery) => String.t()
          },
          optional(:directory) => String.t(),
          optional(:section) => atom(),
          optional(:family) => atom()
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

  defp feedback_chart_definitions do
    [
      %{
        directory: "status",
        section: :feedback_charts,
        family: :feedback_chart,
        title: "Status Example",
        subject_type: :"custom:status",
        subject_props: %{
          title: "System readiness",
          description: "A compact signal surface for current operational health.",
          class: "ashui-example-status-shell"
        },
        story_text:
          "Meaningful Interaction Story: switch the operational health state and confirm the status surface updates its visible tone and detail from persisted runtime data.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.metric -> bound status model plus preview state.",
        seed_state: %{
          id: "state-status",
          current_value: "watching",
          status: "Status surface mounted with the watching signal.",
          metric: %{
            "label" => "Watching",
            "tone" => "warning",
            "detail" => "Escalation depth is elevated but still within response targets."
          }
        },
        preview_field: :current_value,
        preview_title: "Current signal",
        subject_binding: %{
          id: :status_metric,
          field: :metric,
          target: "model",
          binding_type: :value,
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          state_button(
            :load_healthy_status_button,
            "Healthy",
            "state-status",
            %{
              current_value: "healthy",
              status: "Status surface switched to the healthy signal.",
              metric: %{
                "label" => "Healthy",
                "tone" => "success",
                "detail" => "All review queues are within their normal operating range."
              }
            },
            :actions,
            0
          ),
          state_button(
            :load_risk_status_button,
            "Risk",
            "state-status",
            %{
              current_value: "risk",
              status: "Status surface switched to the risk signal.",
              metric: %{
                "label" => "Risk",
                "tone" => "danger",
                "detail" => "Retry volume crossed the operator threshold for intervention."
              }
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          ),
          slot_text(
            :footer,
            :status_footer,
            "Status surface mounted with the watching signal.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-status"
          )
        ],
        support_notice:
          "The `status` example remains an explicit custom shell so tone and badge semantics stay example-scoped rather than silently widening the public widget surface.",
        notes: "Binds one status model map into a renderer-backed signal surface."
      },
      %{
        directory: "progress",
        section: :feedback_charts,
        family: :feedback_chart,
        title: "Progress Example",
        subject_type: :"custom:progress",
        subject_props: %{
          title: "Rollout progress",
          description: "A progress surface fed by persisted rollout metrics.",
          class: "ashui-example-progress-shell"
        },
        story_text:
          "Meaningful Interaction Story: switch the rollout phase and confirm the progress surface updates both its completion amount and explanatory detail.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.metric -> bound progress model plus preview value.",
        seed_state: %{
          id: "state-progress",
          current_value: "42%",
          status: "Progress surface mounted with the canary rollout.",
          metric: %{
            "label" => "Canary rollout",
            "value" => 42,
            "total" => 100,
            "detail" => "42 percent of the planned canary traffic is live."
          }
        },
        preview_field: :current_value,
        preview_title: "Completion",
        subject_binding: %{
          id: :progress_metric,
          field: :metric,
          target: "model",
          binding_type: :value,
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          state_button(
            :load_canary_progress_button,
            "Canary phase",
            "state-progress",
            %{
              current_value: "42%",
              status: "Progress surface mounted with the canary rollout.",
              metric: %{
                "label" => "Canary rollout",
                "value" => 42,
                "total" => 100,
                "detail" => "42 percent of the planned canary traffic is live."
              }
            },
            :actions,
            0
          ),
          state_button(
            :load_full_progress_button,
            "Full rollout",
            "state-progress",
            %{
              current_value: "100%",
              status: "Progress surface switched to the completed rollout.",
              metric: %{
                "label" => "Full rollout",
                "value" => 100,
                "total" => 100,
                "detail" => "All target regions are live and the rollout is complete."
              }
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          ),
          slot_text(
            :footer,
            :progress_footer,
            "Progress surface mounted with the canary rollout.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-progress"
          )
        ],
        support_notice:
          "The `progress` example uses a renderer-backed custom shell so completion visuals stay honest without implying a public maintained progress widget.",
        notes: "Binds one rollout metric map into the progress shell."
      },
      %{
        directory: "gauge",
        section: :feedback_charts,
        family: :feedback_chart,
        title: "Gauge Example",
        subject_type: :"custom:gauge",
        subject_props: %{
          title: "Capacity gauge",
          description: "A compact capacity surface that reads one bounded metric model.",
          class: "ashui-example-gauge-shell"
        },
        story_text:
          "Meaningful Interaction Story: switch the live capacity snapshot and confirm the gauge surface updates both its visible fill amount and its supporting detail.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.metric -> bound gauge model plus preview state.",
        seed_state: %{
          id: "state-gauge",
          current_value: "63%",
          status: "Gauge surface mounted with the normal capacity snapshot.",
          metric: %{
            "label" => "CPU saturation",
            "value" => 63,
            "max" => 100,
            "detail" => "Current saturation is within the operating budget."
          }
        },
        preview_field: :current_value,
        preview_title: "Capacity",
        subject_binding: %{
          id: :gauge_metric,
          field: :metric,
          target: "model",
          binding_type: :value,
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          state_button(
            :load_nominal_gauge_button,
            "Nominal",
            "state-gauge",
            %{
              current_value: "63%",
              status: "Gauge surface mounted with the normal capacity snapshot.",
              metric: %{
                "label" => "CPU saturation",
                "value" => 63,
                "max" => 100,
                "detail" => "Current saturation is within the operating budget."
              }
            },
            :actions,
            0
          ),
          state_button(
            :load_elevated_gauge_button,
            "Elevated",
            "state-gauge",
            %{
              current_value: "87%",
              status: "Gauge surface switched to the elevated capacity snapshot.",
              metric: %{
                "label" => "CPU saturation",
                "value" => 87,
                "max" => 100,
                "detail" => "Capacity is approaching the point where intervention is required."
              }
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          ),
          slot_text(
            :footer,
            :gauge_footer,
            "Gauge surface mounted with the normal capacity snapshot.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-gauge"
          )
        ],
        support_notice:
          "The `gauge` example stays a custom shell because its radial/threshold presentation is renderer-backed rather than part of the maintained public widget set.",
        notes: "Binds a bounded metric map into a gauge-style visual."
      },
      %{
        directory: "inline_feedback",
        section: :feedback_charts,
        family: :feedback_chart,
        title: "Inline Feedback Example",
        subject_type: :"custom:inline_feedback",
        subject_props: %{
          title: "Recovery note",
          description: "A compact inline advisory surface for operator-visible guidance.",
          class: "ashui-example-inline-feedback-shell"
        },
        story_text:
          "Meaningful Interaction Story: switch the advisory message and confirm the inline feedback surface updates its visible tone and message from persisted runtime data.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.metric -> bound feedback model plus preview tone.",
        seed_state: %{
          id: "state-inline_feedback",
          current_value: "success",
          status: "Inline feedback mounted with the recovery-ready note.",
          metric: %{
            "tone" => "success",
            "title" => "Rollback ready",
            "detail" => "The recovery checklist is complete and ready if the rollout degrades."
          }
        },
        preview_field: :current_value,
        preview_title: "Tone",
        subject_binding: %{
          id: :inline_feedback_metric,
          field: :metric,
          target: "model",
          binding_type: :value,
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          state_button(
            :load_success_feedback_button,
            "Recovery ready",
            "state-inline_feedback",
            %{
              current_value: "success",
              status: "Inline feedback mounted with the recovery-ready note.",
              metric: %{
                "tone" => "success",
                "title" => "Rollback ready",
                "detail" =>
                  "The recovery checklist is complete and ready if the rollout degrades."
              }
            },
            :actions,
            0
          ),
          state_button(
            :load_warning_feedback_button,
            "Review risk",
            "state-inline_feedback",
            %{
              current_value: "warning",
              status: "Inline feedback switched to the review-risk note.",
              metric: %{
                "tone" => "warning",
                "title" => "Review risk",
                "detail" =>
                  "The current release should stay under review until retries return to baseline."
              }
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          ),
          slot_text(
            :footer,
            :inline_feedback_footer,
            "Inline feedback mounted with the recovery-ready note.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-inline_feedback"
          )
        ],
        support_notice:
          "The `inline_feedback` example uses a custom surface to keep tone-box styling and semantics example-scoped.",
        notes: "Binds one advisory model map into the feedback shell."
      },
      %{
        directory: "sparkline",
        section: :feedback_charts,
        family: :feedback_chart,
        title: "Sparkline Example",
        subject_type: :"custom:sparkline",
        subject_props: %{
          title: "Latency sparkline",
          description: "A compact trend surface for quick directional review.",
          class: "ashui-example-sparkline-shell"
        },
        story_text:
          "Meaningful Interaction Story: switch the active mini-series and confirm the sparkline redraws its trend points from persisted runtime data.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.series -> bound sparkline points plus preview series label.",
        seed_state: %{
          id: "state-sparkline",
          current_value: "queue latency",
          status: "Sparkline mounted with the queue-latency trend.",
          series: [
            %{"label" => "00m", "value" => 18},
            %{"label" => "05m", "value" => 22},
            %{"label" => "10m", "value" => 19},
            %{"label" => "15m", "value" => 24},
            %{"label" => "20m", "value" => 21}
          ]
        },
        preview_field: :current_value,
        preview_title: "Series",
        subject_binding: %{
          id: :sparkline_series,
          field: :series,
          target: "series",
          binding_type: :value,
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          state_button(
            :load_latency_sparkline_button,
            "Queue latency",
            "state-sparkline",
            %{
              current_value: "queue latency",
              status: "Sparkline mounted with the queue-latency trend.",
              series: [
                %{"label" => "00m", "value" => 18},
                %{"label" => "05m", "value" => 22},
                %{"label" => "10m", "value" => 19},
                %{"label" => "15m", "value" => 24},
                %{"label" => "20m", "value" => 21}
              ]
            },
            :actions,
            0
          ),
          state_button(
            :load_backlog_sparkline_button,
            "Worker backlog",
            "state-sparkline",
            %{
              current_value: "worker backlog",
              status: "Sparkline switched to the worker-backlog trend.",
              series: [
                %{"label" => "00m", "value" => 8},
                %{"label" => "05m", "value" => 10},
                %{"label" => "10m", "value" => 13},
                %{"label" => "15m", "value" => 12},
                %{"label" => "20m", "value" => 15}
              ]
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          ),
          slot_text(
            :footer,
            :sparkline_footer,
            "Sparkline mounted with the queue-latency trend.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-sparkline"
          )
        ],
        support_notice:
          "The `sparkline` example uses a renderer-backed custom shell because lightweight chart glyphs are not a maintained public fallback surface.",
        notes: "Binds one short point series into the sparkline shell."
      },
      %{
        directory: "bar_chart",
        section: :feedback_charts,
        family: :feedback_chart,
        title: "Bar Chart Example",
        subject_type: :"custom:bar_chart",
        subject_props: %{
          title: "Volume bars",
          description: "A categorical comparison surface driven by persisted runtime series.",
          class: "ashui-example-bar-chart-shell"
        },
        story_text:
          "Meaningful Interaction Story: switch the active categorical series and confirm the bar chart redraws its bars from persisted runtime data.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.series -> bound bar series plus preview label.",
        seed_state: %{
          id: "state-bar_chart",
          current_value: "region volume",
          status: "Bar chart mounted with the regional volume series.",
          series: [
            %{"label" => "us-east", "value" => 84},
            %{"label" => "us-west", "value" => 63},
            %{"label" => "eu-central", "value" => 58}
          ]
        },
        preview_field: :current_value,
        preview_title: "Series",
        subject_binding: %{
          id: :bar_chart_series,
          field: :series,
          target: "series",
          binding_type: :value,
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          state_button(
            :load_region_bar_chart_button,
            "Region volume",
            "state-bar_chart",
            %{
              current_value: "region volume",
              status: "Bar chart mounted with the regional volume series.",
              series: [
                %{"label" => "us-east", "value" => 84},
                %{"label" => "us-west", "value" => 63},
                %{"label" => "eu-central", "value" => 58}
              ]
            },
            :actions,
            0
          ),
          state_button(
            :load_service_bar_chart_button,
            "Service mix",
            "state-bar_chart",
            %{
              current_value: "service mix",
              status: "Bar chart switched to the service-mix series.",
              series: [
                %{"label" => "gateway", "value" => 72},
                %{"label" => "workers", "value" => 91},
                %{"label" => "billing", "value" => 44}
              ]
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          ),
          slot_text(
            :footer,
            :bar_chart_footer,
            "Bar chart mounted with the regional volume series.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-bar_chart"
          )
        ],
        support_notice:
          "The `bar_chart` example uses an explicit custom surface because categorical chart rendering is a renderer-backed extension, not a maintained public widget.",
        notes: "Binds one categorical point series into the bar-chart shell."
      },
      %{
        directory: "line_chart",
        section: :feedback_charts,
        family: :feedback_chart,
        title: "Line Chart Example",
        subject_type: :"custom:line_chart",
        subject_props: %{
          title: "Trend line",
          description: "A longer-running trend surface for directional review.",
          class: "ashui-example-line-chart-shell"
        },
        story_text:
          "Meaningful Interaction Story: switch the active trend series and confirm the line-chart surface redraws its points from persisted runtime data.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.series -> bound line series plus preview label.",
        seed_state: %{
          id: "state-line_chart",
          current_value: "error trend",
          status: "Line chart mounted with the error-trend series.",
          series: [
            %{"label" => "Mon", "value" => 7},
            %{"label" => "Tue", "value" => 9},
            %{"label" => "Wed", "value" => 6},
            %{"label" => "Thu", "value" => 8},
            %{"label" => "Fri", "value" => 5}
          ]
        },
        preview_field: :current_value,
        preview_title: "Series",
        subject_binding: %{
          id: :line_chart_series,
          field: :series,
          target: "series",
          binding_type: :value,
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          state_button(
            :load_error_line_chart_button,
            "Error trend",
            "state-line_chart",
            %{
              current_value: "error trend",
              status: "Line chart mounted with the error-trend series.",
              series: [
                %{"label" => "Mon", "value" => 7},
                %{"label" => "Tue", "value" => 9},
                %{"label" => "Wed", "value" => 6},
                %{"label" => "Thu", "value" => 8},
                %{"label" => "Fri", "value" => 5}
              ]
            },
            :actions,
            0
          ),
          state_button(
            :load_recovery_line_chart_button,
            "Recovery trend",
            "state-line_chart",
            %{
              current_value: "recovery trend",
              status: "Line chart switched to the recovery-trend series.",
              series: [
                %{"label" => "Mon", "value" => 42},
                %{"label" => "Tue", "value" => 55},
                %{"label" => "Wed", "value" => 61},
                %{"label" => "Thu", "value" => 73},
                %{"label" => "Fri", "value" => 88}
              ]
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          ),
          slot_text(
            :footer,
            :line_chart_footer,
            "Line chart mounted with the error-trend series.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-line_chart"
          )
        ],
        support_notice:
          "The `line_chart` example stays a custom shell because trend-line rendering is intentionally renderer-backed and example-scoped.",
        notes: "Binds one trend point series into the line-chart shell."
      }
    ]
  end

  defp operational_definitions do
    [
      %{
        directory: "stream_widget",
        section: :operational_monitoring,
        family: :operational,
        title: "Stream Widget Example",
        subject_type: :"custom:stream_widget",
        subject_props: %{
          title: "Activity stream",
          description:
            "A bounded operational feed that swaps between representative runtime streams.",
          class: "ashui-example-stream-widget-shell"
        },
        story_text:
          "Meaningful Interaction Story: switch the active operational feed and confirm the stream surface redraws from persisted runtime entries instead of claiming an unimplemented live transport.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.items -> bound stream entries plus preview label.",
        seed_state: %{
          id: "state-stream_widget",
          current_value: "ingest stream",
          status: "Stream widget mounted with the ingest feed snapshot.",
          items: [
            %{
              "timestamp" => "13:04:12",
              "label" => "ingest",
              "message" => "Batch handoff packet accepted for triage."
            },
            %{
              "timestamp" => "13:04:27",
              "label" => "ingest",
              "message" => "Escalation queue hydration completed."
            },
            %{
              "timestamp" => "13:04:39",
              "label" => "ingest",
              "message" => "Operator summary card published."
            }
          ]
        },
        preview_field: :current_value,
        preview_title: "Active feed",
        subject_binding: %{
          id: :stream_entries,
          field: :items,
          target: "entries",
          binding_type: :value,
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          state_button(
            :load_ingest_stream_widget_button,
            "Ingest feed",
            "state-stream_widget",
            %{
              current_value: "ingest stream",
              status: "Stream widget mounted with the ingest feed snapshot.",
              items: [
                %{
                  "timestamp" => "13:04:12",
                  "label" => "ingest",
                  "message" => "Batch handoff packet accepted for triage."
                },
                %{
                  "timestamp" => "13:04:27",
                  "label" => "ingest",
                  "message" => "Escalation queue hydration completed."
                },
                %{
                  "timestamp" => "13:04:39",
                  "label" => "ingest",
                  "message" => "Operator summary card published."
                }
              ]
            },
            :actions,
            0
          ),
          state_button(
            :load_deploy_stream_widget_button,
            "Deploy feed",
            "state-stream_widget",
            %{
              current_value: "deploy stream",
              status: "Stream widget switched to the deploy feed snapshot.",
              items: [
                %{
                  "timestamp" => "13:12:01",
                  "label" => "deploy",
                  "message" => "Canary reached 25 percent of its target scope."
                },
                %{
                  "timestamp" => "13:12:18",
                  "label" => "deploy",
                  "message" => "Regional readiness checks returned healthy."
                },
                %{
                  "timestamp" => "13:12:32",
                  "label" => "deploy",
                  "message" => "Rollback plan archived with the release packet."
                }
              ]
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          ),
          slot_text(
            :footer,
            :stream_widget_footer,
            "Stream widget mounted with the ingest feed snapshot.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-stream_widget"
          )
        ],
        support_notice:
          "The `stream_widget` example intentionally swaps persisted snapshots through nested controls; it does not claim a live subscription transport the package does not ship yet.",
        notes: "Uses representative runtime feed snapshots with explicit operator controls."
      },
      %{
        directory: "process_monitor",
        section: :operational_monitoring,
        family: :operational,
        title: "Process Monitor Example",
        subject_type: :"custom:process_monitor",
        subject_props: %{
          title: "Process monitor",
          description: "A compact runtime process surface fed by one persisted model snapshot.",
          class: "ashui-example-process-monitor-shell"
        },
        story_text:
          "Meaningful Interaction Story: switch the monitored process state and confirm the visible process cards update from persisted runtime data rather than decorative placeholders.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.payload -> bound process monitor model plus preview label.",
        seed_state: %{
          id: "state-process_monitor",
          current_value: "steady state",
          status: "Process monitor mounted with the steady-state snapshot.",
          payload: %{
            "summary" => "Schedulers and workers are healthy with no restart pressure.",
            "processes" => [
              %{"name" => "scheduler", "state" => "running", "meta" => "0 restarts"},
              %{"name" => "queue_worker", "state" => "running", "meta" => "1 restart"},
              %{"name" => "binding_refresher", "state" => "idle", "meta" => "0 restarts"}
            ]
          }
        },
        preview_field: :current_value,
        preview_title: "Monitor mode",
        subject_binding: %{
          id: :process_monitor_model,
          field: :payload,
          target: "model",
          binding_type: :value,
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          state_button(
            :load_steady_process_monitor_button,
            "Steady state",
            "state-process_monitor",
            %{
              current_value: "steady state",
              status: "Process monitor mounted with the steady-state snapshot.",
              payload: %{
                "summary" => "Schedulers and workers are healthy with no restart pressure.",
                "processes" => [
                  %{"name" => "scheduler", "state" => "running", "meta" => "0 restarts"},
                  %{"name" => "queue_worker", "state" => "running", "meta" => "1 restart"},
                  %{"name" => "binding_refresher", "state" => "idle", "meta" => "0 restarts"}
                ]
              }
            },
            :actions,
            0
          ),
          state_button(
            :load_pressure_process_monitor_button,
            "Pressure state",
            "state-process_monitor",
            %{
              current_value: "pressure state",
              status: "Process monitor switched to the restart-pressure snapshot.",
              payload: %{
                "summary" => "Retry workers are degraded and the refresh lane is under pressure.",
                "processes" => [
                  %{"name" => "scheduler", "state" => "running", "meta" => "0 restarts"},
                  %{"name" => "queue_worker", "state" => "degraded", "meta" => "4 restarts"},
                  %{"name" => "binding_refresher", "state" => "running", "meta" => "2 restarts"}
                ]
              }
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          ),
          slot_text(
            :footer,
            :process_monitor_footer,
            "Process monitor mounted with the steady-state snapshot.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-process_monitor"
          )
        ],
        support_notice:
          "The `process_monitor` example uses explicit runtime snapshots and nested controls instead of implying a hidden supervisor tap.",
        notes: "Binds one process monitor model map into a renderer-backed operational shell."
      },
      %{
        directory: "supervision_tree_viewer",
        section: :operational_monitoring,
        family: :operational,
        title: "Supervision Tree Viewer Example",
        subject_type: :"custom:supervision_tree_viewer",
        subject_props: %{
          title: "Supervision tree",
          description:
            "A hierarchical operational shell for supervisor and worker relationships.",
          class: "ashui-example-supervision-tree-shell"
        },
        story_text:
          "Meaningful Interaction Story: switch the viewed supervision snapshot and confirm the tree structure updates from persisted runtime data instead of a fixed outline.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.payload -> bound supervision tree model plus preview label.",
        seed_state: %{
          id: "state-supervision_tree_viewer",
          current_value: "worker supervision",
          status: "Supervision tree viewer mounted with the worker supervision snapshot.",
          payload: %{
            "label" => "Worker supervisor",
            "meta" => "Primary",
            "nodes" => [
              %{"label" => "queue_worker", "meta" => "running"},
              %{
                "label" => "retry_supervisor",
                "meta" => "running",
                "children" => [
                  %{"label" => "retry_worker_a", "meta" => "running"},
                  %{"label" => "retry_worker_b", "meta" => "running"}
                ]
              }
            ]
          }
        },
        preview_field: :current_value,
        preview_title: "Snapshot",
        subject_binding: %{
          id: :supervision_tree_model,
          field: :payload,
          target: "model",
          binding_type: :value,
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          state_button(
            :load_worker_supervision_tree_button,
            "Worker tree",
            "state-supervision_tree_viewer",
            %{
              current_value: "worker supervision",
              status: "Supervision tree viewer mounted with the worker supervision snapshot.",
              payload: %{
                "label" => "Worker supervisor",
                "meta" => "Primary",
                "nodes" => [
                  %{"label" => "queue_worker", "meta" => "running"},
                  %{
                    "label" => "retry_supervisor",
                    "meta" => "running",
                    "children" => [
                      %{"label" => "retry_worker_a", "meta" => "running"},
                      %{"label" => "retry_worker_b", "meta" => "running"}
                    ]
                  }
                ]
              }
            },
            :actions,
            0
          ),
          state_button(
            :load_recovery_supervision_tree_button,
            "Recovery tree",
            "state-supervision_tree_viewer",
            %{
              current_value: "recovery supervision",
              status: "Supervision tree viewer switched to the recovery supervision snapshot.",
              payload: %{
                "label" => "Recovery supervisor",
                "meta" => "Failover",
                "nodes" => [
                  %{"label" => "rollback_worker", "meta" => "running"},
                  %{
                    "label" => "broadcast_supervisor",
                    "meta" => "running",
                    "children" => [
                      %{"label" => "notify_slack", "meta" => "queued"},
                      %{"label" => "notify_pager", "meta" => "running"}
                    ]
                  }
                ]
              }
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          ),
          slot_text(
            :footer,
            :supervision_tree_footer,
            "Supervision tree viewer mounted with the worker supervision snapshot.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-supervision_tree_viewer"
          )
        ],
        support_notice:
          "The `supervision_tree_viewer` example remains a custom shell because operational supervision visuals are renderer-backed and example-scoped.",
        notes: "Binds one supervision tree snapshot into a hierarchical shell."
      },
      %{
        directory: "cluster_dashboard",
        section: :operational_monitoring,
        family: :operational,
        title: "Cluster Dashboard Example",
        subject_type: :"custom:cluster_dashboard",
        subject_props: %{
          title: "Cluster dashboard",
          description: "The flagship operational composition example for multi-region review.",
          class: "ashui-example-cluster-dashboard-shell"
        },
        story_text:
          "Meaningful Interaction Story: switch the dashboard between stable and incident snapshots and confirm the headline, regional cards, and alert rail all update from persisted runtime data.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.payload -> bound dashboard model plus preview label.",
        seed_state: %{
          id: "state-cluster_dashboard",
          current_value: "stable cluster",
          status: "Cluster dashboard mounted with the stable multi-region snapshot.",
          payload: %{
            "headline" => "Regional cluster stable",
            "detail" => "All regions are inside their latency and retry budgets.",
            "regions" => [
              %{"label" => "us-east", "status" => "Healthy", "load" => "63%"},
              %{"label" => "us-west", "status" => "Healthy", "load" => "58%"},
              %{"label" => "eu-central", "status" => "Watching", "load" => "61%"}
            ],
            "alerts" => [
              %{"title" => "Billing lag", "message" => "Watching retriable writes."},
              %{"title" => "Worker backlog", "message" => "Trending down after rebalance."}
            ]
          }
        },
        preview_field: :current_value,
        preview_title: "Snapshot",
        subject_binding: %{
          id: :cluster_dashboard_model,
          field: :payload,
          target: "model",
          binding_type: :value,
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          state_button(
            :load_stable_cluster_dashboard_button,
            "Stable snapshot",
            "state-cluster_dashboard",
            %{
              current_value: "stable cluster",
              status: "Cluster dashboard mounted with the stable multi-region snapshot.",
              payload: %{
                "headline" => "Regional cluster stable",
                "detail" => "All regions are inside their latency and retry budgets.",
                "regions" => [
                  %{"label" => "us-east", "status" => "Healthy", "load" => "63%"},
                  %{"label" => "us-west", "status" => "Healthy", "load" => "58%"},
                  %{"label" => "eu-central", "status" => "Watching", "load" => "61%"}
                ],
                "alerts" => [
                  %{"title" => "Billing lag", "message" => "Watching retriable writes."},
                  %{
                    "title" => "Worker backlog",
                    "message" => "Trending down after rebalance."
                  }
                ]
              }
            },
            :actions,
            0
          ),
          state_button(
            :load_incident_cluster_dashboard_button,
            "Incident snapshot",
            "state-cluster_dashboard",
            %{
              current_value: "incident cluster",
              status: "Cluster dashboard switched to the incident response snapshot.",
              payload: %{
                "headline" => "Regional cluster degraded",
                "detail" =>
                  "Two regions are above the retry threshold and operator response is active.",
                "regions" => [
                  %{"label" => "us-east", "status" => "Degraded", "load" => "87%"},
                  %{"label" => "us-west", "status" => "Healthy", "load" => "59%"},
                  %{"label" => "eu-central", "status" => "Degraded", "load" => "82%"}
                ],
                "alerts" => [
                  %{"title" => "Gateway retries", "message" => "Crossed the paging threshold."},
                  %{
                    "title" => "Recovery broadcast",
                    "message" => "Queued for operator acknowledgment."
                  }
                ]
              }
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          ),
          slot_text(
            :footer,
            :cluster_dashboard_footer,
            "Cluster dashboard mounted with the stable multi-region snapshot.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-cluster_dashboard"
          )
        ],
        support_notice:
          "The `cluster_dashboard` example is a composed custom shell that stays explicit about using representative snapshots and nested public controls rather than hidden runtime shortcuts.",
        notes: "Binds one dashboard model map into the flagship operational shell."
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
    overlay_definitions() ++
      data_surface_definitions() ++
      feedback_chart_definitions() ++
      operational_definitions()
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

  @doc """
  Returns the Phase 20 runtime contract for each advanced example section.
  """
  @spec runtime_contract() :: map()
  def runtime_contract do
    %{
      overlay_layered_flows: %{
        mount_actor: :active_viewer_required,
        mutate_roles: [:operator, :admin],
        subscription_mode: :seeded_action_refresh,
        shell_state_surface: :preview_and_footer,
        shell_state_story: %{
          loading:
            "Layered examples surface their mounted state through persisted preview and footer copy instead of hidden browser-only state.",
          failure:
            "Dismissal, defer, and escalation outcomes stay visible in persisted status fields owned by nested resources.",
          recovery:
            "Nested public controls restore the closed or acknowledged state without leaving the shared Ash HQ shell."
        }
      },
      data_surfaces: %{
        mount_actor: :active_viewer_required,
        mutate_roles: [:operator, :admin],
        subscription_mode: :notification_required,
        shell_state_surface: :preview_and_status,
        shell_state_story: %{
          loading:
            "Data-surface examples expose the active dataset through preview and status copy as soon as the seeded screen mounts.",
          failure:
            "Fallback or warning states must stay visible in the shared shell status copy rather than being implied by an empty collection alone.",
          recovery:
            "Operator-driven dataset changes and runtime notifications refresh the mounted viewer session through real binding reevaluation."
        }
      },
      feedback_charts: %{
        mount_actor: :active_viewer_required,
        mutate_roles: [:operator, :admin],
        subscription_mode: :notification_required,
        shell_state_surface: :preview_and_status,
        shell_state_story: %{
          loading:
            "Feedback examples mount with an explicit seeded metric snapshot so the first visible state is already reviewer-verifiable.",
          failure:
            "Risk, warning, and degraded chart states remain visible through the rendered metric shell and preview status copy.",
          recovery:
            "Operator metric writes and notification-backed refresh restore the viewer-visible signal without ad hoc local state."
        }
      },
      operational_monitoring: %{
        mount_actor: :active_viewer_required,
        mutate_roles: [:operator, :admin],
        subscription_mode: :notification_required,
        shell_state_surface: :status_and_support_notice,
        shell_state_story: %{
          loading:
            "Operational examples expose the mounted snapshot through shell status copy and support notes instead of pretending to stream unseen background state.",
          failure:
            "Incident and pressure snapshots must render degraded copy inside the primary surface and shared status/footer surfaces.",
          recovery:
            "Stable snapshot controls and notification-backed refresh return the mounted view to a healthy state without remounting."
        }
      }
    }
  end

  @doc """
  Returns the runtime contract that applies to one authored Phase 20 example.
  """
  @spec runtime_contract_for(String.t()) :: runtime_contract_entry()
  def runtime_contract_for(directory) when is_binary(directory) do
    definition = definition!(directory)

    runtime_contract()
    |> Map.fetch!(definition.section)
    |> Map.put(:directory, definition.directory)
    |> Map.put(:section, definition.section)
    |> Map.put(:family, definition.family)
  end
end
