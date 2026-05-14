defmodule ElmUi.Examples do
  @moduledoc """
  Maintained direct-native and canonical example inputs for `elm_ui`.
  """

  alias UnifiedIUR.Element
  alias UnifiedIUR.Element.Child
  alias UnifiedIUR.Interactions.Transport, as: BoundaryTransport
  alias ElmUi.Widgets

  @display_kinds [:viewport, :scroll_bar, :split_pane]
  @layer_kinds [:overlay, :dialog, :toast, :alert_dialog, :context_menu]

  @spec native_counter_screen() :: map()
  def native_counter_screen do
    Widgets.screen("native-counter", "Native Counter", [
      Widgets.text(:count, "0", styles: %{tone: :accent}),
      Widgets.button(:increment, "Increment",
        on_click: %{family: :click, intent: :increment, boundary: :local}
      )
    ])
  end

  @spec canonical_welcome_screen() :: Element.t()
  def canonical_welcome_screen do
    Element.new(:widget, :text,
      id: "welcome-message",
      attributes: %{content: "Welcome to elm_ui"}
    )
  end

  @spec native_foundational_screen() :: map()
  def native_foundational_screen do
    %{
      id: "workspace-layout",
      title: "Native Foundational",
      root:
        Widgets.column("workspace-layout", [
          Widgets.content("workspace-header", [
            Widgets.text("workspace-title", "Workspace"),
            Widgets.tabs(
              "workspace-tabs",
              [
                [id: :overview, label: "Overview", active: true],
                [id: :activity, label: "Activity"]
              ],
              active_item: :overview,
              on_navigate: %{intent: :switch_tab}
            )
          ]),
          Widgets.form(
            "workspace-form",
            [
              Widgets.field_group(
                "workspace-group",
                [
                  Widgets.field(
                    "query-field",
                    Widgets.text_input("query-input",
                      name: :query,
                      value: "Pascal",
                      placeholder: "Search",
                      on_change: %{intent: :rename_query}
                    ),
                    name: :query,
                    label: "Search Query",
                    help: "Used for preview filtering"
                  ),
                  Widgets.field(
                    "alerts-field",
                    Widgets.checkbox("alerts-checkbox", "Alerts",
                      name: :alerts,
                      checked: true,
                      on_change: %{intent: :toggle_alerts}
                    ),
                    name: :alerts,
                    label: "Alerts",
                    help: "Enable workspace notifications"
                  )
                ],
                legend: "Workspace"
              )
            ],
            on_submit: %{intent: :save_workspace}
          ),
          Widgets.row(
            "workspace-actions",
            [
              Widgets.button("save-button", "Save", on_click: %{intent: :save_workspace})
            ],
            justify: :end
          )
        ]),
      metadata: %{source: :native_foundational, bridge: :phoenix_elm}
    }
  end

  @spec canonical_foundational_screen() :: Element.t()
  def canonical_foundational_screen do
    Element.new(:layout, :column,
      id: "workspace-layout",
      children: [
        Element.new(:widget, :content,
          id: "workspace-header",
          children: [
            Element.new(:widget, :text,
              id: "workspace-title",
              attributes: %{content: "Workspace"}
            ),
            Element.new(:widget, :tabs,
              id: "workspace-tabs",
              attributes: %{
                active_item: :overview,
                items: [
                  %{id: :overview, label: "Overview", active: true},
                  %{id: :activity, label: "Activity"}
                ]
              }
            )
          ]
        ),
        Element.new(:composite, :form,
          id: "workspace-form",
          children: [
            Element.new(:composite, :field_group,
              id: "workspace-group",
              attributes: %{legend: "Workspace"},
              children: [
                Element.new(:composite, :field,
                  id: "query-field",
                  attributes: %{name: :query},
                  children: [
                    Child.new(
                      :label,
                      Element.new(:widget, :label,
                        id: "query-field-label",
                        attributes: %{content: "Search Query"}
                      )
                    ),
                    Child.new(
                      :control,
                      Element.new(:widget, :text_input,
                        id: "query-input",
                        attributes: %{name: :query, value: "Pascal", placeholder: "Search"}
                      )
                    ),
                    Child.new(
                      :help,
                      Element.new(:widget, :text,
                        id: "query-input-help",
                        attributes: %{content: "Used for preview filtering"}
                      )
                    )
                  ]
                ),
                Element.new(:composite, :field,
                  id: "alerts-field",
                  attributes: %{name: :alerts},
                  children: [
                    Child.new(
                      :label,
                      Element.new(:widget, :label,
                        id: "alerts-field-label",
                        attributes: %{content: "Alerts"}
                      )
                    ),
                    Child.new(
                      :control,
                      Element.new(:widget, :checkbox,
                        id: "alerts-checkbox",
                        attributes: %{name: :alerts, checked: true, label: "Alerts"}
                      )
                    ),
                    Child.new(
                      :help,
                      Element.new(:widget, :text,
                        id: "alerts-checkbox-help",
                        attributes: %{content: "Enable workspace notifications"}
                      )
                    )
                  ]
                )
              ]
            )
          ]
        ),
        Element.new(:layout, :row,
          id: "workspace-actions",
          attributes: %{justify: :end},
          children: [
            Element.new(:widget, :button,
              id: "save-button",
              attributes: %{label: "Save"}
            )
          ]
        )
      ]
    )
  end

  @spec native_transport_screen() :: map()
  def native_transport_screen do
    Widgets.screen(
      "transport-workspace",
      "Native Transport Workspace",
      [
        Widgets.content("transport-header", [
          Widgets.text("transport-title", "Transport Workspace"),
          Widgets.inline_feedback(
            "transport-feedback",
            "Direct native usage keeps this workflow local."
          )
        ]),
        Widgets.form(
          "transport-form",
          [
            Widgets.field_group(
              "transport-group",
              [
                Widgets.field(
                  "transport-query-field",
                  Widgets.text_input("transport-query-input",
                    name: :query,
                    value: "status:ready",
                    placeholder: "Filter nodes",
                    on_change: %{family: :change, intent: :refine_query, boundary: :local}
                  ),
                  name: :query,
                  label: "Query"
                )
              ],
              legend: "Transport Filter"
            )
          ],
          on_submit: %{family: :submit, intent: :save_workspace, boundary: :local}
        ),
        Widgets.row(
          "transport-actions",
          [
            Widgets.button("preview-button", "Preview",
              on_click: %{family: :open, intent: :open_preview, boundary: :local}
            ),
            Widgets.button("save-button", "Save Workspace",
              on_click: %{family: :submit, intent: :save_workspace, boundary: :local}
            )
          ],
          justify: :end,
          gap: :md
        )
      ],
      source: :native_transport,
      bridge: :phoenix_elm
    )
  end

  @spec canonical_transport_screen() :: Element.t()
  def canonical_transport_screen do
    Element.new(:layout, :column,
      id: "transport-workspace",
      attributes: %{gap: :md},
      children: [
        Element.new(:widget, :content,
          id: "transport-header",
          children: [
            Element.new(:widget, :text,
              id: "transport-title",
              attributes: %{content: "Transport Workspace"}
            ),
            Element.new(:widget, :inline_feedback,
              id: "transport-feedback",
              attributes: %{
                message: "Canonical rendering crosses the boundary for the same workflow."
              }
            )
          ]
        ),
        Element.new(:composite, :form,
          id: "transport-form",
          children: [
            Element.new(:composite, :field_group,
              id: "transport-group",
              attributes: %{legend: "Transport Filter"},
              children: [
                Element.new(:composite, :field,
                  id: "transport-query-field",
                  attributes: %{name: :query},
                  children: [
                    Child.new(
                      :label,
                      Element.new(:widget, :label,
                        id: "transport-query-label",
                        attributes: %{content: "Query"}
                      )
                    ),
                    Child.new(
                      :control,
                      Element.new(:widget, :text_input,
                        id: "transport-query-input",
                        attributes: %{
                          name: :query,
                          value: "status:ready",
                          placeholder: "Filter nodes"
                        }
                      )
                    )
                  ]
                )
              ]
            )
          ]
        ),
        Element.new(:layout, :row,
          id: "transport-actions",
          attributes: %{justify: :end, gap: :md},
          children: [
            Element.new(:widget, :button,
              id: "preview-button",
              attributes: %{label: "Preview"}
            ),
            Element.new(:widget, :button,
              id: "save-button",
              attributes: %{label: "Save Workspace"}
            )
          ]
        )
      ]
    )
  end

  @spec native_navigation_screen() :: map()
  def native_navigation_screen do
    Widgets.screen(
      "home",
      "Navigation Home",
      [
        Widgets.content("navigation-header", [
          Widgets.text("navigation-title", "Navigation Home"),
          Widgets.inline_feedback(
            "navigation-feedback",
            "Server-side transitions remain authoritative even when the browser keeps local route state."
          )
        ]),
        Widgets.row(
          "navigation-actions",
          [
            Widgets.button("settings-link", "Open Settings"),
            Widgets.button("dialog-link", "Open Dialog")
          ],
          gap: :md
        )
      ],
      source: :native_navigation,
      bridge: :phoenix_elm
    )
  end

  @spec canonical_navigation_screen() :: Element.t()
  def canonical_navigation_screen do
    Element.new(:layout, :column,
      id: "home",
      attributes: %{gap: :md},
      children: [
        Element.new(:widget, :content,
          id: "navigation-header",
          children: [
            Element.new(:widget, :text,
              id: "navigation-title",
              attributes: %{content: "Navigation Home"}
            ),
            Element.new(:widget, :inline_feedback,
              id: "navigation-feedback",
              attributes: %{
                message:
                  "Canonical transitions stay screen-based while host routes remain external."
              }
            )
          ]
        ),
        Element.new(:layout, :row,
          id: "navigation-actions",
          attributes: %{gap: :md},
          children: [
            Element.new(:widget, :button,
              id: "settings-link",
              attributes: %{label: "Open Settings"}
            ),
            Element.new(:widget, :button,
              id: "dialog-link",
              attributes: %{label: "Open Dialog"}
            )
          ]
        )
      ]
    )
  end

  @spec native_advanced_screen() :: map()
  def native_advanced_screen do
    %{
      id: "advanced-operations",
      title: "Native Advanced Operations",
      root:
        Widgets.column(
          "advanced-operations",
          [
            Widgets.content("advanced-header", [
              Widgets.text("advanced-title", "Operations Workspace"),
              Widgets.status("cluster-status", "Watching cluster", severity: :info)
            ]),
            ElmUi.Layer.overlay(
              "operations-overlay",
              ElmUi.Layout.split_pane(
                "operations-split",
                ElmUi.Layout.viewport(
                  "log-viewport",
                  Widgets.log_viewer(
                    "ops-log-viewer",
                    [
                      [
                        id: "log-1",
                        message: "Accepted connection",
                        severity: :info,
                        timestamp: "2026-03-21T09:00:00Z"
                      ],
                      [
                        id: "log-2",
                        message: "Replica promoted",
                        severity: :warning,
                        timestamp: "2026-03-21T09:02:00Z"
                      ]
                    ],
                    follow: true
                  ),
                  offset: {0, 120},
                  height: 24,
                  sync_group: :logs
                ),
                Widgets.column(
                  "operations-secondary",
                  [
                    Widgets.table(
                      "cluster-table",
                      [
                        [id: :name, label: "Name", sortable: true],
                        [id: :status, label: "Status"]
                      ],
                      [
                        [id: "node-a", cells: ["Node A", "healthy"]],
                        [id: "node-b", cells: ["Node B", "degraded"]]
                      ],
                      sort_key: :name,
                      sort_direction: :asc
                    ),
                    Widgets.row(
                      "operations-metrics",
                      [
                        Widgets.progress("deploy-progress",
                          current: 3,
                          total: 5,
                          label: "Deploy"
                        ),
                        Widgets.gauge("cluster-gauge", value: 72, label: "Cluster Health"),
                        Widgets.sparkline("throughput-sparkline", [12, 16, 18, 17])
                      ],
                      gap: :lg
                    ),
                    Widgets.bar_chart("requests-chart", [
                      [id: :requests, label: "Requests", values: [12, 18, 16]],
                      [id: :errors, label: "Errors", values: [1, 0, 2]]
                    ]),
                    Widgets.command_palette(
                      "ops-command-palette",
                      [
                        [id: :deploy, label: "Deploy", value: :deploy],
                        [id: :rollback, label: "Rollback", value: :rollback]
                      ],
                      query: "deploy"
                    ),
                    Widgets.canvas(
                      "cluster-canvas",
                      [
                        [kind: :cell, position: {0, 0}, text: "A", style_refs: [:accent]],
                        [kind: :cell, position: {1, 0}, text: "B"]
                      ],
                      width: 20,
                      height: 10
                    ),
                    Widgets.cluster_dashboard(
                      "cluster-dashboard",
                      [
                        [id: "node-a", status: :healthy],
                        [id: "node-b", status: :degraded]
                      ],
                      summary: %{healthy: 1, degraded: 1}
                    )
                  ],
                  gap: :lg
                ),
                ratio: 0.6
              ),
              [
                ElmUi.Layer.dialog(
                  "inspect-dialog",
                  Widgets.content("dialog-content", [
                    Widgets.markdown_viewer("dialog-doc", "# Inspect\n\nNode A is healthy.")
                  ]),
                  title: "Inspect Node",
                  modal: true
                ),
                ElmUi.Layer.toast(
                  "deploy-toast",
                  Widgets.text("toast-copy", "Deploy complete"),
                  placement: :top_end
                )
              ],
              on_dismiss: %{intent: :dismiss_overlay}
            ),
            ElmUi.Layout.scroll_bar("log-scrollbar",
              viewport_ref: "log-viewport",
              viewport_size: 24,
              content_size: 120,
              sync_group: :logs
            )
          ],
          gap: :lg
        ),
      metadata: %{source: :native_advanced, bridge: :phoenix_elm}
    }
  end

  @spec canonical_advanced_screen() :: Element.t()
  def canonical_advanced_screen do
    Element.new(:layout, :column,
      id: "advanced-operations",
      attributes: %{gap: :lg},
      children: [
        Element.new(:widget, :content,
          id: "advanced-header",
          children: [
            Element.new(:widget, :text,
              id: "advanced-title",
              attributes: %{content: "Operations Workspace"}
            ),
            Element.new(:widget, :status,
              id: "cluster-status",
              attributes: %{text: "Watching cluster", severity: :info}
            )
          ]
        ),
        Element.new(:layer, :overlay,
          id: "operations-overlay",
          attributes: %{events: %{dismiss: %{intent: :dismiss_overlay}}},
          children: [
            Child.new(
              :base,
              Element.new(:layout, :split_pane,
                id: "operations-split",
                attributes: %{ratio: 0.6},
                children: [
                  Child.new(
                    :primary,
                    Element.new(:layout, :viewport,
                      id: "log-viewport",
                      attributes: %{offset: %{x: 0, y: 120}, height: 24, sync_group: :logs},
                      children: [
                        Child.new(
                          :content,
                          Element.new(:widget, :log_viewer,
                            id: "ops-log-viewer",
                            attributes: %{
                              entries: [
                                %{
                                  id: "log-1",
                                  message: "Accepted connection",
                                  severity: :info,
                                  timestamp: "2026-03-21T09:00:00Z"
                                },
                                %{
                                  id: "log-2",
                                  message: "Replica promoted",
                                  severity: :warning,
                                  timestamp: "2026-03-21T09:02:00Z"
                                }
                              ],
                              follow: true
                            }
                          )
                        )
                      ]
                    )
                  ),
                  Child.new(
                    :secondary,
                    Element.new(:layout, :column,
                      id: "operations-secondary",
                      attributes: %{gap: :lg},
                      children: [
                        Element.new(:widget, :table,
                          id: "cluster-table",
                          attributes: %{
                            columns: [
                              %{id: :name, label: "Name", sortable: true},
                              %{id: :status, label: "Status"}
                            ],
                            rows: [
                              %{id: "node-a", cells: ["Node A", "healthy"]},
                              %{id: "node-b", cells: ["Node B", "degraded"]}
                            ],
                            sort_key: :name,
                            sort_direction: :asc
                          }
                        ),
                        Element.new(:layout, :row,
                          id: "operations-metrics",
                          attributes: %{gap: :lg},
                          children: [
                            Element.new(:widget, :progress,
                              id: "deploy-progress",
                              attributes: %{current: 3, total: 5, label: "Deploy"}
                            ),
                            Element.new(:widget, :gauge,
                              id: "cluster-gauge",
                              attributes: %{value: 72, label: "Cluster Health"}
                            ),
                            Element.new(:widget, :sparkline,
                              id: "throughput-sparkline",
                              attributes: %{series: [[12, 16, 18, 17]]}
                            )
                          ]
                        ),
                        Element.new(:widget, :bar_chart,
                          id: "requests-chart",
                          attributes: %{
                            series: [
                              %{id: :requests, label: "Requests", values: [12, 18, 16]},
                              %{id: :errors, label: "Errors", values: [1, 0, 2]}
                            ]
                          }
                        ),
                        Element.new(:widget, :command_palette,
                          id: "ops-command-palette",
                          attributes: %{
                            commands: [
                              %{id: :deploy, label: "Deploy", value: :deploy},
                              %{id: :rollback, label: "Rollback", value: :rollback}
                            ],
                            query: "deploy"
                          }
                        ),
                        Element.new(:widget, :canvas,
                          id: "cluster-canvas",
                          attributes: %{
                            operations: [
                              %{
                                kind: :cell,
                                position: %{x: 0, y: 0},
                                text: "A",
                                style_refs: [:accent]
                              },
                              %{kind: :cell, position: %{x: 1, y: 0}, text: "B"}
                            ],
                            width: 20,
                            height: 10
                          }
                        ),
                        Element.new(:widget, :cluster_dashboard,
                          id: "cluster-dashboard",
                          attributes: %{
                            nodes: [
                              %{id: "node-a", status: :healthy},
                              %{id: "node-b", status: :degraded}
                            ],
                            summary: %{healthy: 1, degraded: 1}
                          }
                        )
                      ]
                    )
                  )
                ]
              )
            ),
            Child.new(
              :layers,
              Element.new(:layer, :dialog,
                id: "inspect-dialog",
                attributes: %{title: "Inspect Node", modal: true},
                children: [
                  Child.new(
                    :content,
                    Element.new(:widget, :content,
                      id: "dialog-content",
                      children: [
                        Element.new(:widget, :markdown_viewer,
                          id: "dialog-doc",
                          attributes: %{source: "# Inspect\n\nNode A is healthy."}
                        )
                      ]
                    )
                  )
                ]
              )
            ),
            Child.new(
              :layers,
              Element.new(:layer, :toast,
                id: "deploy-toast",
                attributes: %{placement: :top_end},
                children: [
                  Child.new(
                    :content,
                    Element.new(:widget, :text,
                      id: "toast-copy",
                      attributes: %{content: "Deploy complete"}
                    )
                  )
                ]
              )
            )
          ]
        ),
        Element.new(:widget, :scroll_bar,
          id: "log-scrollbar",
          attributes: %{
            viewport_ref: "log-viewport",
            viewport_size: 24,
            content_size: 120,
            sync_group: :logs
          }
        )
      ]
    )
  end

  @spec native_styling_screen() :: map()
  def native_styling_screen do
    %{
      id: "styling-workbench",
      title: "Native Styling Review",
      root:
        Widgets.column(
          "styling-workbench",
          [
            Widgets.content(
              "styling-header",
              [
                Widgets.text("styling-title", "Styling Workbench",
                  tone: :accent,
                  style_hooks: [:theme_tokens],
                  theme_tokens: %{text: [:text, :hero]}
                ),
                Widgets.inline_feedback(
                  "styling-banner",
                  "Server theme meaning stays authoritative.",
                  severity: :info,
                  tone: :info,
                  background: :accent_tint,
                  emphasis: :strong
                )
              ],
              surface: :panel,
              background: :panel
            ),
            Widgets.form("styling-form", [
              Widgets.field_group(
                "styling-group",
                [
                  Widgets.field(
                    "style-query-field",
                    Widgets.text_input("style-query",
                      name: :query,
                      value: "cluster:west",
                      focused: true,
                      style_hooks: [:state_variants, :theme_tokens],
                      theme_tokens: %{surface: [:surface, :default]},
                      state_variants: %{focused: %{border: :focus_ring}}
                    ),
                    name: :query,
                    label: "Query"
                  )
                ],
                legend: "Styling Filters"
              )
            ]),
            ElmUi.Layer.overlay(
              "styling-overlay",
              Widgets.content(
                "styling-surface",
                [
                  Widgets.row(
                    "styling-actions",
                    [
                      Widgets.button("primary-action", "Deploy",
                        variant: :primary,
                        style_hooks: [:theme_tokens],
                        theme_tokens: %{button: [:button, :primary]}
                      ),
                      Widgets.button("quiet-action", "Preview",
                        variant: :quiet,
                        tone: :muted
                      )
                    ],
                    gap: :md
                  ),
                  Widgets.status("styling-status", "Theme ready",
                    severity: :info,
                    tone: :info
                  )
                ],
                surface: :elevated,
                background: :panel
              ),
              [
                ElmUi.Layer.dialog(
                  "style-inspector",
                  Widgets.content(
                    "style-dialog-content",
                    [
                      Widgets.text(
                        "style-dialog-text",
                        "Resolved styles remain aligned.",
                        typography: :body,
                        tone: :content
                      )
                    ],
                    surface: :elevated,
                    background: :panel
                  ),
                  title: "Style Inspector",
                  modal: true,
                  size: :md,
                  background: :panel,
                  border: :strong
                )
              ],
              background: :scrim,
              emphasis: :intense,
              on_dismiss: %{intent: :dismiss_style_overlay}
            )
          ],
          gap: :lg
        ),
      metadata: %{source: :native_styling, bridge: :phoenix_elm, theme: :midnight}
    }
  end

  @spec canonical_styling_screen() :: Element.t()
  def canonical_styling_screen do
    Element.new(:layout, :column,
      id: "styling-workbench",
      attributes: %{gap: :lg},
      children: [
        Element.new(:widget, :content,
          id: "styling-header",
          attributes: %{
            styles: %{surface: :panel, background: :panel}
          },
          children: [
            Element.new(:widget, :text,
              id: "styling-title",
              attributes: %{
                content: "Styling Workbench",
                styles: %{tone: :accent, theme_tokens: %{text: [:text, :hero]}},
                style_hooks: [:theme_tokens]
              }
            ),
            Element.new(:widget, :inline_feedback,
              id: "styling-banner",
              attributes: %{
                message: "Server theme meaning stays authoritative.",
                severity: :info,
                styles: %{tone: :info, background: :accent_tint, emphasis: :strong}
              }
            )
          ]
        ),
        Element.new(:composite, :form,
          id: "styling-form",
          children: [
            Element.new(:composite, :field_group,
              id: "styling-group",
              attributes: %{legend: "Styling Filters"},
              children: [
                Element.new(:composite, :field,
                  id: "style-query-field",
                  attributes: %{name: :query},
                  children: [
                    Child.new(
                      :label,
                      Element.new(:widget, :label,
                        id: "style-query-label",
                        attributes: %{content: "Query"}
                      )
                    ),
                    Child.new(
                      :control,
                      Element.new(:widget, :text_input,
                        id: "style-query",
                        attributes: %{
                          name: :query,
                          value: "cluster:west",
                          state: %{focused: true},
                          styles: %{
                            theme_tokens: %{surface: [:surface, :default]},
                            state_variants: %{focused: %{border: :focus_ring}}
                          },
                          style_hooks: [:state_variants, :theme_tokens]
                        }
                      )
                    )
                  ]
                )
              ]
            )
          ]
        ),
        Element.new(:layer, :overlay,
          id: "styling-overlay",
          attributes: %{
            styles: %{background: :scrim, emphasis: :intense},
            events: %{dismiss: %{intent: :dismiss_style_overlay}}
          },
          children: [
            Child.new(
              :base,
              Element.new(:widget, :content,
                id: "styling-surface",
                attributes: %{styles: %{surface: :elevated, background: :panel}},
                children: [
                  Element.new(:layout, :row,
                    id: "styling-actions",
                    attributes: %{gap: :md},
                    children: [
                      Element.new(:widget, :button,
                        id: "primary-action",
                        attributes: %{
                          label: "Deploy",
                          styles: %{
                            variant: :primary,
                            theme_tokens: %{button: [:button, :primary]}
                          },
                          style_hooks: [:theme_tokens]
                        }
                      ),
                      Element.new(:widget, :button,
                        id: "quiet-action",
                        attributes: %{
                          label: "Preview",
                          styles: %{variant: :quiet, tone: :muted}
                        }
                      )
                    ]
                  ),
                  Element.new(:widget, :status,
                    id: "styling-status",
                    attributes: %{
                      text: "Theme ready",
                      severity: :info,
                      styles: %{tone: :info}
                    }
                  )
                ]
              )
            ),
            Child.new(
              :layers,
              Element.new(:layer, :dialog,
                id: "style-inspector",
                attributes: %{
                  title: "Style Inspector",
                  modal: true,
                  styles: %{background: :panel, border: :strong}
                },
                children: [
                  Child.new(
                    :content,
                    Element.new(:widget, :content,
                      id: "style-dialog-content",
                      attributes: %{styles: %{surface: :elevated, background: :panel}},
                      children: [
                        Element.new(:widget, :text,
                          id: "style-dialog-text",
                          attributes: %{
                            content: "Resolved styles remain aligned.",
                            styles: %{typography: :body, tone: :content}
                          }
                        )
                      ]
                    )
                  )
                ]
              )
            )
          ]
        )
      ]
    )
  end

  @spec comparison_examples() :: map()
  def comparison_examples do
    %{
      native: native_counter_screen(),
      canonical: canonical_welcome_screen(),
      native_foundational: native_foundational_screen(),
      canonical_foundational: canonical_foundational_screen(),
      foundational_continuity: foundational_comparison(),
      native_transport: native_transport_screen(),
      canonical_transport: canonical_transport_screen(),
      mixed_transport: mixed_transport_comparison(),
      native_navigation: native_navigation_screen(),
      canonical_navigation: canonical_navigation_screen(),
      navigation_continuity: navigation_comparison(),
      native_advanced: native_advanced_screen(),
      canonical_advanced: canonical_advanced_screen(),
      advanced_continuity: advanced_comparison(),
      native_styling: native_styling_screen(),
      canonical_styling: canonical_styling_screen(),
      styling_continuity: styling_comparison()
    }
  end

  @spec metadata(atom()) :: map() | nil
  def metadata(id) when is_atom(id) do
    catalog()
    |> Enum.find(&(&1.id == id))
  end

  @spec native_examples() :: [map()]
  def native_examples do
    catalog_by_category(:native)
  end

  @spec canonical_examples() :: [map()]
  def canonical_examples do
    catalog_by_category(:canonical)
  end

  @spec mixed_examples() :: [map()]
  def mixed_examples do
    catalog_by_category(:mixed)
  end

  @spec coverage_matrix() :: map()
  def coverage_matrix do
    catalog = catalog()

    %{
      categories: Enum.group_by(catalog, & &1.category, & &1.id),
      workflows: Enum.group_by(catalog, & &1.workflow, & &1.id),
      parity_groups:
        catalog
        |> Enum.group_by(& &1.parity_group, & &1.id)
        |> Map.delete(nil)
    }
  end

  @spec catalog() :: [map()]
  def catalog do
    catalog_entries()
    |> Enum.map(&decorate_catalog_entry/1)
  end

  @spec foundational_comparison() :: map()
  def foundational_comparison do
    {:ok, native_state} = ElmUi.Runtime.mount_native_screen(native_foundational_screen())
    {:ok, native_frontend} = ElmUi.Runtime.hydrate_frontend(native_state)

    {:ok, canonical_state} = ElmUi.Runtime.mount_iur_screen(canonical_foundational_screen())
    {:ok, canonical_frontend} = ElmUi.Runtime.hydrate_frontend(canonical_state)

    native = snapshot(native_state.rendered_tree, native_frontend.tree)
    canonical = snapshot(canonical_state.rendered_tree, canonical_frontend.tree)

    %{
      native: native,
      canonical: canonical,
      continuity: %{
        widget_kinds_match?: native.widget_kinds == canonical.widget_kinds,
        render_tags_match?: native.render_tags == canonical.render_tags,
        shared_ids:
          native.widget_ids
          |> Enum.filter(&(&1 in canonical.widget_ids))
          |> Enum.uniq()
          |> Enum.sort()
      }
    }
  end

  @spec advanced_comparison() :: map()
  def advanced_comparison do
    {:ok, native_state} = ElmUi.Runtime.mount_native_screen(native_advanced_screen())
    {:ok, native_frontend} = ElmUi.Runtime.hydrate_frontend(native_state)

    {:ok, canonical_state} = ElmUi.Runtime.mount_iur_screen(canonical_advanced_screen())
    {:ok, canonical_frontend} = ElmUi.Runtime.hydrate_frontend(canonical_state)

    native = snapshot(native_state.rendered_tree, native_frontend.tree)
    canonical = snapshot(canonical_state.rendered_tree, canonical_frontend.tree)

    %{
      native: native,
      canonical: canonical,
      continuity: %{
        widget_kinds_match?: native.widget_kinds == canonical.widget_kinds,
        render_tags_match?: native.render_tags == canonical.render_tags,
        display_kinds_match?: native.display_kinds == canonical.display_kinds,
        layer_kinds_match?: native.layer_kinds == canonical.layer_kinds,
        shared_ids:
          native.widget_ids
          |> Enum.filter(&(&1 in canonical.widget_ids))
          |> Enum.uniq()
          |> Enum.sort()
      }
    }
  end

  @spec mixed_transport_comparison() :: map()
  def mixed_transport_comparison do
    {:ok, native_state} =
      ElmUi.Runtime.mount_native_screen(native_transport_screen(), runtime_id: "native-transport")

    {:ok, native_frontend} = ElmUi.Runtime.hydrate_frontend(native_state)

    {:ok, native_frontend_after_dispatch, native_event_message} =
      ElmUi.FrontendRuntime.dispatch_interaction(native_frontend,
        family: :submit,
        intent: :save_workspace,
        boundary: :local,
        widget_id: "save-button",
        payload: %{mode: :draft}
      )

    {:ok, native_state_after_event, native_ack} =
      ElmUi.Runtime.handle_frontend_event(native_state, native_event_message)

    {:ok, canonical_state} =
      ElmUi.Runtime.mount_iur_screen(
        canonical_transport_screen(),
        runtime_id: "canonical-transport"
      )

    {:ok, canonical_frontend} = ElmUi.Runtime.hydrate_frontend(canonical_state)

    {:ok, canonical_frontend_after_dispatch, canonical_event_message} =
      ElmUi.FrontendRuntime.dispatch_interaction(canonical_frontend,
        family: :submit,
        intent: :save_workspace,
        widget_id: "save-button",
        payload: %{mode: :commit}
      )

    {:ok, canonical_state_after_event, canonical_ack} =
      ElmUi.Runtime.handle_frontend_event(canonical_state, canonical_event_message)

    %{
      native: %{
        screen_id: native_state_after_event.screen_id,
        boundary: native_event_message.metadata.boundary,
        mode: List.last(native_state_after_event.event_log).mode,
        ack: native_ack.payload,
        frontend_scope: native_frontend_after_dispatch.local_state.flash.scope
      },
      canonical: %{
        screen_id: canonical_state_after_event.screen_id,
        boundary: canonical_event_message.metadata.boundary,
        mode: List.last(canonical_state_after_event.event_log).mode,
        ack: canonical_ack.payload,
        signal_type: canonical_state_after_event.last_boundary_signal.type,
        frontend_scope: canonical_frontend_after_dispatch.local_state.flash.scope
      },
      continuity: %{
        same_family?: native_ack.payload.family == canonical_ack.payload.family,
        same_intent?: native_ack.payload.intent == canonical_ack.payload.intent,
        local_and_boundary_paths_diverge?:
          native_event_message.metadata.boundary == :local and
            canonical_event_message.metadata.boundary == :boundary,
        server_authority_preserved?:
          native_ack.payload.server_authority and canonical_ack.payload.server_authority
      }
    }
  end

  @spec navigation_comparison() :: map()
  def navigation_comparison do
    route_fixture = navigation_host_route_fixture()

    native = navigation_flow(:native)
    canonical = navigation_flow(:canonical)

    %{
      native: native,
      canonical: canonical,
      host_route_fixture: route_fixture,
      continuity: %{
        same_navigation_target?:
          native.after_navigate.screen_id == "settings" and
            canonical.after_navigate.screen_id == "settings",
        frontend_coordination?:
          native.after_navigate.frontend_screen_id == native.after_navigate.screen_id and
            canonical.after_navigate.frontend_screen_id == canonical.after_navigate.screen_id,
        same_modal_identifier?:
          get_in(native, [:after_modal, :navigation, :current_modal, :modal]) ==
            get_in(canonical, [:after_modal, :navigation, :current_modal, :modal]),
        same_second_modal_identifier?:
          get_in(native, [:after_second_modal, :navigation, :current_modal, :modal]) ==
            get_in(canonical, [:after_second_modal, :navigation, :current_modal, :modal]),
        top_close_restores_previous_modal?:
          get_in(native, [:after_top_close, :navigation, :current_modal, :modal]) ==
            get_in(native, [:after_modal, :navigation, :current_modal, :modal]) and
            get_in(canonical, [:after_top_close, :navigation, :current_modal, :modal]) ==
              get_in(canonical, [:after_modal, :navigation, :current_modal, :modal]),
        modal_stack_reflected?:
          length(native.after_second_modal.navigation.modals) == 2 and
            length(canonical.after_second_modal.navigation.modals) == 2 and
            length(native.after_top_close.navigation.modals) == 1 and
            length(canonical.after_top_close.navigation.modals) == 1,
        same_replacement_target?:
          native.after_replace.screen_id == "home" and canonical.after_replace.screen_id == "home",
        host_route_externalized?:
          is_nil(get_in(route_fixture, [:canonical_target, :route])) and
            get_in(native, [:after_navigate, :authoritative_host_route, :path]) ==
              get_in(canonical, [:after_navigate, :authoritative_host_route, :path]) and
            get_in(native, [:after_navigate, :route_state, :path]) ==
              get_in(route_fixture, [:host_application, :frontend_route_state, :path]),
        server_authority_preserved?:
          Enum.all?(
            [
              native.after_navigate.server_authoritative?,
              native.after_modal.server_authoritative?,
              native.after_second_modal.server_authoritative?,
              native.after_top_close.server_authoritative?,
              native.after_replace.server_authoritative?,
              canonical.after_navigate.server_authoritative?,
              canonical.after_modal.server_authoritative?,
              canonical.after_second_modal.server_authoritative?,
              canonical.after_top_close.server_authoritative?,
              canonical.after_replace.server_authoritative?
            ],
            & &1
          )
      }
    }
  end

  @spec styling_comparison() :: map()
  def styling_comparison do
    {:ok, native_state} =
      ElmUi.Runtime.mount_native_screen(native_styling_screen(), runtime_id: "native-styling")

    {:ok, canonical_state} =
      ElmUi.Runtime.mount_iur_screen(
        canonical_styling_screen(),
        runtime_id: "canonical-styling",
        theme: :midnight
      )

    {:ok, report} =
      ElmUi.Continuity.compare(
        native_state,
        canonical_state,
        native_local_state: %{focused_id: "style-query", editing_ids: ["style-query"]},
        canonical_local_state: %{focused_id: "style-query", editing_ids: ["style-query"]}
      )

    Map.put(
      report,
      :review_artifact,
      review_artifact(report, [
        "styling-title",
        "style-query",
        "primary-action",
        "style-inspector"
      ])
    )
  end

  defp catalog_by_category(category) do
    catalog()
    |> Enum.filter(&(&1.category == category))
  end

  defp navigation_flow(kind) do
    second_modal_fixture = BoundaryTransport.boundary_fixture!("modal_stack--open_confirm_dialog")
    close_top_fixture = BoundaryTransport.boundary_fixture!("modal_stack--close_top")

    {mount_result, screen_registry} =
      case kind do
        :native ->
          home_screen = native_navigation_screen()

          {
            ElmUi.Runtime.mount_native_screen(home_screen,
              runtime_id: "native-navigation",
              screen_registry: %{
                home: home_screen,
                settings: native_navigation_settings_screen()
              },
              host_route_resolver: &resolve_navigation_host_route/2
            ),
            %{home: home_screen, settings: native_navigation_settings_screen()}
          }

        :canonical ->
          home_element = canonical_navigation_screen()

          {
            ElmUi.Runtime.mount_iur_screen(home_element,
              runtime_id: "canonical-navigation",
              screen_registry: %{
                home: home_element,
                settings: canonical_navigation_settings_screen()
              },
              host_route_resolver: &resolve_navigation_host_route/2
            ),
            %{home: home_element, settings: canonical_navigation_settings_screen()}
          }
      end

    {:ok, runtime_state} = mount_result
    {:ok, frontend_model} = ElmUi.Runtime.hydrate_frontend(runtime_state)

    {:ok, frontend_after_navigate_dispatch, navigate_event_message} =
      ElmUi.FrontendRuntime.dispatch_interaction(frontend_model,
        family: :navigation,
        intent: :open_settings_screen,
        boundary: :boundary,
        widget_id: "settings-link",
        target: navigation_target(:navigate_to, screen: :settings, params: %{tab: :profile}),
        route_state: navigation_route_state("settings", %{tab: :profile})
      )

    {:ok, state_after_navigate, navigate_ack} =
      ElmUi.Runtime.handle_frontend_event(runtime_state, navigate_event_message)

    {:ok, frontend_after_navigate} =
      ElmUi.FrontendRuntime.apply_server_message(
        frontend_after_navigate_dispatch,
        navigate_ack
      )

    {:ok, frontend_after_modal_dispatch, modal_event_message} =
      ElmUi.FrontendRuntime.dispatch_interaction(frontend_after_navigate,
        family: :navigation,
        intent: :open_settings_modal,
        boundary: :boundary,
        widget_id: "dialog-link",
        target:
          navigation_target(:open_modal,
            modal: :settings_dialog,
            params: %{mode: :advanced},
            metadata: %{surface: :workspace}
          )
      )

    {:ok, state_after_modal, modal_ack} =
      ElmUi.Runtime.handle_frontend_event(state_after_navigate, modal_event_message)

    {:ok, frontend_after_modal} =
      ElmUi.FrontendRuntime.apply_server_message(frontend_after_modal_dispatch, modal_ack)

    {:ok, frontend_after_second_modal_dispatch, second_modal_event_message} =
      ElmUi.FrontendRuntime.dispatch_interaction(frontend_after_modal,
        family: :navigation,
        intent: :open_settings_confirm_dialog,
        boundary: :boundary,
        widget_id: "dialog-link",
        target: second_modal_fixture.descriptor.target
      )

    {:ok, state_after_second_modal, second_modal_ack} =
      ElmUi.Runtime.handle_frontend_event(state_after_modal, second_modal_event_message)

    {:ok, frontend_after_second_modal} =
      ElmUi.FrontendRuntime.apply_server_message(
        frontend_after_second_modal_dispatch,
        second_modal_ack
      )

    {:ok, frontend_after_top_close_dispatch, close_top_event_message} =
      ElmUi.FrontendRuntime.dispatch_interaction(frontend_after_second_modal,
        family: :navigation,
        intent: :close_top_modal,
        boundary: :boundary,
        widget_id: "dialog-link",
        target: close_top_fixture.descriptor.target
      )

    {:ok, state_after_top_close, close_top_ack} =
      ElmUi.Runtime.handle_frontend_event(state_after_second_modal, close_top_event_message)

    {:ok, frontend_after_top_close} =
      ElmUi.FrontendRuntime.apply_server_message(
        frontend_after_top_close_dispatch,
        close_top_ack
      )

    {:ok, frontend_after_replace_dispatch, replace_event_message} =
      ElmUi.FrontendRuntime.dispatch_interaction(frontend_after_top_close,
        family: :navigation,
        intent: :replace_home_screen,
        boundary: :boundary,
        widget_id: "settings-link",
        target:
          navigation_target(:replace_with,
            screen: :home,
            params: %{source: :command_palette}
          ),
        route_state: navigation_route_state("home", %{source: :command_palette})
      )

    {:ok, state_after_replace, replace_ack} =
      ElmUi.Runtime.handle_frontend_event(state_after_top_close, replace_event_message)

    {:ok, frontend_after_replace} =
      ElmUi.FrontendRuntime.apply_server_message(frontend_after_replace_dispatch, replace_ack)

    %{
      category: kind,
      registry_size: map_size(screen_registry),
      after_navigate:
        navigation_snapshot(
          state_after_navigate,
          frontend_after_navigate,
          navigate_ack,
          navigation_route_state("settings", %{tab: :profile})
        ),
      after_modal: navigation_snapshot(state_after_modal, frontend_after_modal, modal_ack, nil),
      after_second_modal:
        navigation_snapshot(
          state_after_second_modal,
          frontend_after_second_modal,
          second_modal_ack,
          nil
        ),
      after_top_close:
        navigation_snapshot(state_after_top_close, frontend_after_top_close, close_top_ack, nil),
      after_replace:
        navigation_snapshot(
          state_after_replace,
          frontend_after_replace,
          replace_ack,
          navigation_route_state("home", %{source: :command_palette})
        )
    }
  end

  defp navigation_snapshot(state, frontend_model, ack_message, route_state) do
    authoritative_screen = ack_message.payload.authoritative_screen
    navigation = authoritative_screen.metadata.navigation

    %{
      screen_id: to_string(state.screen_id),
      title: state.title,
      source_kind: state.source_kind,
      boundary_mode: state.boundary_mode,
      frontend_screen_id: to_string(frontend_model.screen_id),
      frontend_title: frontend_model.title,
      server_authoritative?: ack_message.payload.server_authority,
      signal_type: state.last_boundary_signal && state.last_boundary_signal.type,
      authoritative_screen: authoritative_screen,
      authoritative_host_route: navigation.host_route,
      navigation: navigation,
      route_state: route_state
    }
  end

  defp navigation_target(action, attrs) do
    %{navigation: attrs |> Enum.into(%{}) |> Map.put(:action, action)}
  end

  defp navigation_host_route_fixture do
    %{
      canonical_target: %{action: :navigate_to, screen: :settings, params: %{tab: :profile}},
      host_application: %{
        phoenix_route: %{path: "/workspace/settings", params: %{tab: :profile}},
        frontend_route_state: navigation_route_state("settings", %{tab: :profile}),
        note:
          "Browser route matching and URL generation remain host concerns rather than canonical transition fields."
      }
    }
  end

  defp navigation_route_state(screen_id, params) do
    %{
      screen_id: screen_id,
      path: "/workspace/#{screen_id}",
      params: normalize_map(params)
    }
  end

  defp resolve_navigation_host_route(descriptor, _state) do
    screen =
      case Map.get(descriptor, :screen) do
        screen when is_atom(screen) -> Atom.to_string(screen)
        screen when is_binary(screen) -> screen
        _other -> nil
      end

    case screen do
      screen when screen in ["home", "settings"] ->
        {:ok,
         %{
           path: "/workspace/#{screen}",
           params: normalize_map(Map.get(descriptor, :params, %{}))
         }}

      _other ->
        {:ok, nil}
    end
  end

  defp native_navigation_settings_screen do
    Widgets.screen(
      "settings",
      "Settings",
      [
        Widgets.content("settings-header", [
          Widgets.text("settings-title", "Settings"),
          Widgets.inline_feedback(
            "settings-feedback",
            "The server selected this screen and the Elm frontend acknowledged it."
          )
        ])
      ],
      source: :native_navigation,
      bridge: :phoenix_elm
    )
  end

  defp canonical_navigation_settings_screen do
    Element.new(:layout, :column,
      id: "settings",
      children: [
        Element.new(:widget, :text,
          id: "settings-title",
          attributes: %{content: "Settings"}
        ),
        Element.new(:widget, :inline_feedback,
          id: "settings-feedback",
          attributes: %{
            message: "The authoritative Phoenix runtime coordinated this frontend screen change."
          }
        )
      ]
    )
  end

  defp snapshot(widget_tree, frontend_tree) do
    %{
      widget_ids: collect_widget_ids(widget_tree),
      widget_kinds: collect_widget_kinds(widget_tree),
      display_kinds: collect_filtered_kinds(widget_tree, @display_kinds),
      layer_kinds: collect_filtered_kinds(widget_tree, @layer_kinds),
      render_tags: collect_render_tags(frontend_tree)
    }
  end

  defp collect_widget_ids(%ElmUi.Widget{} = widget) do
    [to_string(widget.id)] ++
      (widget.slot_children
       |> Map.values()
       |> List.flatten()
       |> Enum.flat_map(&collect_widget_ids/1))
  end

  defp collect_widget_kinds(%ElmUi.Widget{} = widget) do
    [widget.kind] ++
      (widget.slot_children
       |> Map.values()
       |> List.flatten()
       |> Enum.flat_map(&collect_widget_kinds/1))
  end

  defp collect_filtered_kinds(%ElmUi.Widget{} = widget, allowed) do
    widget
    |> collect_widget_kinds()
    |> Enum.filter(&(&1 in allowed))
  end

  defp collect_render_tags(node) when is_map(node) do
    [node.tag] ++
      (node.slots
       |> Enum.flat_map(& &1.children)
       |> Enum.flat_map(&collect_render_tags/1))
  end

  defp review_artifact(report, ids) do
    %{
      ids: ids,
      server: %{
        native: select_style_nodes(report.native.server.style_nodes, ids),
        canonical: select_style_nodes(report.canonical.server.style_nodes, ids)
      },
      frontend: %{
        native: select_style_nodes(report.native.frontend.style_nodes, ids),
        canonical: select_style_nodes(report.canonical.frontend.style_nodes, ids)
      },
      continuity: %{
        shared_ids: Enum.filter(ids, &(&1 in report.continuity.shared_ids)),
        validation: report.continuity.validation
      }
    }
  end

  defp select_style_nodes(nodes, ids) do
    nodes
    |> Enum.filter(&(to_string(&1.id) in ids))
    |> Enum.sort_by(&to_string(&1.id))
  end

  defp decorate_catalog_entry(entry) do
    Map.merge(entry, %{
      artifact_names: artifact_names(entry.id),
      traceability: traceability(entry)
    })
  end

  defp artifact_names(id) do
    base = "elm_ui.examples.#{id}"

    %{
      preview: "#{base}.preview",
      inspection: "#{base}.inspection",
      export: "#{base}.export",
      comparison: "#{base}.comparison"
    }
  end

  defp traceability(entry) do
    %{
      package_specs: package_spec_surfaces(entry.category),
      runtime_obligations: runtime_obligations(entry.category),
      coverage_obligations: entry.coverage
    }
  end

  defp package_spec_surfaces(:native),
    do: [:native_widgets, :server_runtime, :frontend_runtime, :tooling]

  defp package_spec_surfaces(:canonical),
    do: [:iur_renderer, :server_runtime, :frontend_runtime, :tooling]

  defp package_spec_surfaces(:mixed),
    do: [:native_widgets, :iur_renderer, :transport, :tooling]

  defp runtime_obligations(:native),
    do: [:phoenix_authoritative, :elm_realization, :direct_native_reviewable]

  defp runtime_obligations(:canonical),
    do: [:phoenix_authoritative, :elm_realization, :canonical_reviewable]

  defp runtime_obligations(:mixed),
    do: [:phoenix_authoritative, :elm_realization, :native_canonical_parity]

  defp catalog_entries do
    [
      %{
        id: :canonical_foundational,
        category: :canonical,
        workflow: :foundational,
        summary: "Canonical foundational workspace",
        coverage: [:canonical_renderer, :foundational_widgets, :forms, :split_runtime],
        parity_group: :foundational_workspace,
        parity_with: [:native_foundational, :foundational_continuity]
      },
      %{
        id: :canonical_advanced,
        category: :canonical,
        workflow: :advanced,
        summary: "Canonical advanced operations workspace",
        coverage: [:canonical_renderer, :advanced_widgets, :display_systems, :layering],
        parity_group: :advanced_operations,
        parity_with: [:native_advanced, :advanced_continuity]
      },
      %{
        id: :canonical_navigation,
        category: :canonical,
        workflow: :navigation,
        summary: "Canonical web navigation workspace",
        coverage: [:canonical_renderer, :navigation, :server_authority, :route_boundary],
        parity_group: :navigation_workspace,
        parity_with: [:native_navigation, :navigation_continuity]
      },
      %{
        id: :canonical_styling,
        category: :canonical,
        workflow: :styling,
        summary: "Canonical styling review workspace",
        coverage: [:canonical_renderer, :themes, :style_resolution, :inspection],
        parity_group: :styling_review,
        parity_with: [:native_styling, :styling_continuity]
      },
      %{
        id: :canonical_transport,
        category: :canonical,
        workflow: :transport,
        summary: "Canonical transport-focused workspace",
        coverage: [:canonical_renderer, :transport_boundary, :server_authority],
        parity_group: :transport_workspace,
        parity_with: [:native_transport, :mixed_transport]
      },
      %{
        id: :canonical_welcome,
        category: :canonical,
        workflow: :minimal,
        summary: "Canonical welcome message",
        coverage: [:canonical_renderer, :minimal_widget, :runtime_hydration],
        parity_group: :welcome_runtime,
        parity_with: [:native_counter]
      },
      %{
        id: :advanced_continuity,
        category: :mixed,
        workflow: :advanced,
        summary: "Native and canonical advanced comparison",
        coverage: [:comparison_artifact, :advanced_widgets, :display_systems, :layering],
        parity_group: :advanced_operations,
        parity_with: [:native_advanced, :canonical_advanced]
      },
      %{
        id: :foundational_continuity,
        category: :mixed,
        workflow: :foundational,
        summary: "Native and canonical foundational comparison",
        coverage: [:comparison_artifact, :foundational_widgets, :forms, :split_runtime],
        parity_group: :foundational_workspace,
        parity_with: [:native_foundational, :canonical_foundational]
      },
      %{
        id: :mixed_transport,
        category: :mixed,
        workflow: :transport,
        summary: "Native and canonical transport workflow comparison",
        coverage: [:comparison_artifact, :transport_boundary, :server_authority],
        parity_group: :transport_workspace,
        parity_with: [:native_transport, :canonical_transport]
      },
      %{
        id: :navigation_continuity,
        category: :mixed,
        workflow: :navigation,
        summary: "Native and canonical web navigation transition comparison",
        coverage: [:comparison_artifact, :navigation, :server_authority, :route_boundary],
        parity_group: :navigation_workspace,
        parity_with: [:native_navigation, :canonical_navigation]
      },
      %{
        id: :native_advanced,
        category: :native,
        workflow: :advanced,
        summary: "Direct-native advanced operations workspace",
        coverage: [:advanced_widgets, :display_systems, :layering, :native_runtime],
        parity_group: :advanced_operations,
        parity_with: [:canonical_advanced, :advanced_continuity]
      },
      %{
        id: :native_counter,
        category: :native,
        workflow: :minimal,
        summary: "Minimal native counter",
        coverage: [:foundational_widgets, :native_runtime, :local_events],
        parity_group: :welcome_runtime,
        parity_with: [:canonical_welcome]
      },
      %{
        id: :native_foundational,
        category: :native,
        workflow: :foundational,
        summary: "Direct-native foundational workspace",
        coverage: [:foundational_widgets, :forms, :navigation, :split_runtime],
        parity_group: :foundational_workspace,
        parity_with: [:canonical_foundational, :foundational_continuity]
      },
      %{
        id: :native_navigation,
        category: :native,
        workflow: :navigation,
        summary: "Direct-native web navigation workspace",
        coverage: [:navigation, :native_runtime, :server_authority, :route_boundary],
        parity_group: :navigation_workspace,
        parity_with: [:canonical_navigation, :navigation_continuity]
      },
      %{
        id: :native_styling,
        category: :native,
        workflow: :styling,
        summary: "Direct-native styling review workspace",
        coverage: [:themes, :style_resolution, :layered_styling, :inspection],
        parity_group: :styling_review,
        parity_with: [:canonical_styling, :styling_continuity]
      },
      %{
        id: :native_transport,
        category: :native,
        workflow: :transport,
        summary: "Direct-native transport-focused workspace",
        coverage: [:transport_local, :forms, :actions, :native_runtime],
        parity_group: :transport_workspace,
        parity_with: [:canonical_transport, :mixed_transport]
      },
      %{
        id: :styling_continuity,
        category: :mixed,
        workflow: :styling,
        summary: "Native and canonical styling comparison",
        coverage: [:comparison_artifact, :style_continuity, :inspection],
        parity_group: :styling_review,
        parity_with: [:native_styling, :canonical_styling]
      }
    ]
  end

  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(_other), do: %{}
end
