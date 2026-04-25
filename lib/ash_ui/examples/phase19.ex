defmodule AshUI.Examples.Phase19 do
  @moduledoc """
  Phase 19 example-suite definitions and path helpers.

  The standalone example directories under `examples/` are generated from these
  definitions so the checked-in projects, tests, and planning artifacts stay in
  sync.
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

  @sections [:layout_navigation, :display_systems, :integration]

  defp layout_navigation_definitions do
    [
      %{
        directory: "row",
        section: :layout_navigation,
        family: :layout,
        title: "Row Example",
        subject_type: :row,
        subject_props: %{
          spacing: 18,
          class: "ashui-example-row-layout"
        },
        story_text:
          "Meaningful Interaction Story: review the horizontal lane sequence and confirm the row example compiles its order from related child resources rather than one inline screen fragment.",
        signal_text:
          "Canonical Signal Preview: relationship order -> compiler composition -> rendered lane sequence inside the maintained row widget.",
        seed_state: %{
          id: "state-row",
          status: "Row ordering preserved through child relationships."
        },
        preview_field: :status,
        preview_title: "Composition note",
        subject_binding: nil,
        subject_action: nil,
        subject_children: [
          layout_card(
            :primary_lane,
            "Primary lane",
            "Relationship order 1 keeps the triage lane left-most.",
            0
          ),
          layout_card(
            :inspector_lane,
            "Inspector lane",
            "Relationship order 2 keeps detail review in the middle.",
            10
          ),
          layout_card(
            :action_lane,
            "Action lane",
            "Relationship order 3 reserves the closing lane for follow-up work.",
            20
          )
        ],
        support_notice:
          "The `row` example treats nested element relationships as the primary composition path rather than relying on an inline screen body.",
        notes: "Uses the maintained public `row` widget directly."
      },
      %{
        directory: "column",
        section: :layout_navigation,
        family: :layout,
        title: "Column Example",
        subject_type: :column,
        subject_props: %{
          spacing: 16,
          class: "ashui-example-column-layout"
        },
        story_text:
          "Meaningful Interaction Story: inspect the vertical review flow and confirm the column example makes ordering obvious through related child resources and consistent spacing.",
        signal_text:
          "Canonical Signal Preview: relationship order -> compiler composition -> rendered stack sequence inside the maintained column widget.",
        seed_state: %{
          id: "state-column",
          status: "Column ordering preserved through child relationships."
        },
        preview_field: :status,
        preview_title: "Composition note",
        subject_binding: nil,
        subject_action: nil,
        subject_children: [
          layout_card(
            :incident_summary,
            "Incident summary",
            "The first child frames the review before deeper operational detail.",
            0
          ),
          layout_card(
            :approval_queue,
            "Approval queue",
            "The second child keeps work-in-flight context centered in the stack.",
            10
          ),
          layout_card(
            :handoff_notes,
            "Handoff notes",
            "The final child closes the stack with secondary coordination detail.",
            20
          )
        ],
        support_notice:
          "The `column` example uses nested child resources as the authored stack, not one monolithic inline fragment.",
        notes: "Uses the maintained public `column` widget directly."
      },
      %{
        directory: "grid",
        section: :layout_navigation,
        family: :layout,
        title: "Grid Example",
        subject_type: :grid,
        subject_props: %{
          columns: 2,
          spacing: 18,
          class: "ashui-example-grid-layout"
        },
        story_text:
          "Meaningful Interaction Story: review the multi-tile structure and confirm the grid example keeps tile ordering, spacing, and grouping in related element resources.",
        signal_text:
          "Canonical Signal Preview: relationship order + grid props -> rendered tile matrix inside the maintained grid widget.",
        seed_state: %{
          id: "state-grid",
          status: "Grid tiles preserved through child relationships and explicit column props."
        },
        preview_field: :status,
        preview_title: "Composition note",
        subject_binding: nil,
        subject_action: nil,
        subject_children: [
          layout_card(
            :queue_tile,
            "Queue tile",
            "Tile one anchors the highest-priority lane.",
            0
          ),
          layout_card(
            :trend_tile,
            "Trend tile",
            "Tile two keeps a paired metric adjacent to the queue.",
            10
          ),
          layout_card(
            :sla_tile,
            "SLA tile",
            "Tile three starts the lower row with service commitment context.",
            20
          ),
          layout_card(
            :handoff_tile,
            "Handoff tile",
            "Tile four closes the grid with a follow-up handoff panel.",
            30
          )
        ],
        support_notice:
          "The `grid` example keeps tile order and grouping in the resource graph so the compiler output still makes the authored structure visible.",
        notes: "Uses the maintained public `grid` widget directly."
      },
      %{
        directory: "menu",
        section: :layout_navigation,
        family: :navigation,
        title: "Menu Example",
        subject_type: :"custom:menu",
        subject_props: %{
          title: "Workspace menu",
          description:
            "Nested public buttons own selection changes inside an explicit custom menu shell.",
          class: "ashui-example-menu-shell"
        },
        story_text:
          "Meaningful Interaction Story: select a menu item and confirm the selection state changes through nested public button resources while the outer subject remains an explicit `custom:menu` shell.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.selected_value -> menu summary text and preview stat.",
        seed_state: %{
          id: "state-menu",
          selected_value: "overview",
          status: "Menu selection stays local to nested public buttons."
        },
        preview_field: :selected_value,
        preview_title: "Selected menu item",
        subject_binding: nil,
        subject_action: nil,
        subject_children: [
          nav_button(
            :overview_button,
            "Overview",
            "overview",
            "state-menu",
            "Overview item selected."
          ),
          nav_button(
            :monitoring_button,
            "Monitoring",
            "monitoring",
            "state-menu",
            "Monitoring item selected."
          ),
          nav_button(
            :handoff_button,
            "Handoff",
            "handoff",
            "state-menu",
            "Handoff item selected."
          ),
          %{
            key: :menu_summary,
            type: :text,
            props: %{
              content: "overview",
              class: "ashui-example-surface-copy ashui-example-menu-summary"
            },
            slot: :body,
            position: 0,
            bindings: [
              %{
                id: :menu_selected_value,
                source: %{resource: "ExampleState", field: :selected_value, id: "state-menu"},
                target: "content",
                binding_type: :value,
                transform: %{},
                metadata: %{owner: "summary"}
              }
            ],
            children: []
          },
          %{
            key: :menu_status,
            type: :text,
            props: %{
              content: "Menu selection stays local to nested public buttons.",
              class: "ashui-example-surface-meta"
            },
            slot: :footer,
            position: 0,
            bindings: [
              %{
                id: :menu_status_copy,
                source: %{resource: "ExampleState", field: :status, id: "state-menu"},
                target: "content",
                binding_type: :value,
                transform: %{},
                metadata: %{owner: "footer"}
              }
            ],
            children: []
          }
        ],
        support_notice:
          "The `menu` example remains an explicit `custom:menu` surface; selection actions stay on nested public button resources.",
        notes: "Uses a dedicated example-only custom shell with nested public buttons."
      },
      %{
        directory: "tabs",
        section: :layout_navigation,
        family: :navigation,
        title: "Tabs Example",
        subject_type: :"custom:tabs",
        subject_props: %{
          title: "Triage tabs",
          description:
            "Nested public buttons own tab switching while the outer shell stays explicit.",
          class: "ashui-example-tabs-shell"
        },
        story_text:
          "Meaningful Interaction Story: switch tabs and confirm the active panel value changes through nested public button resources while the outer subject remains an explicit `custom:tabs` shell.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.selected_value -> active panel text and preview stat.",
        seed_state: %{
          id: "state-tabs",
          selected_value: "overview",
          status: "Tab switching stays local to nested public buttons."
        },
        preview_field: :selected_value,
        preview_title: "Active tab",
        subject_binding: nil,
        subject_action: nil,
        subject_children: [
          nav_button(
            :overview_tab_button,
            "Overview",
            "overview",
            "state-tabs",
            "Overview tab selected."
          ),
          nav_button(
            :metrics_tab_button,
            "Metrics",
            "metrics",
            "state-tabs",
            "Metrics tab selected."
          ),
          nav_button(
            :escalations_tab_button,
            "Escalations",
            "escalations",
            "state-tabs",
            "Escalations tab selected."
          ),
          %{
            key: :active_panel,
            type: :text,
            props: %{
              content: "overview",
              class: "ashui-example-surface-copy ashui-example-tabs-panel"
            },
            slot: :body,
            position: 0,
            bindings: [
              %{
                id: :tabs_selected_value,
                source: %{resource: "ExampleState", field: :selected_value, id: "state-tabs"},
                target: "content",
                binding_type: :value,
                transform: %{},
                metadata: %{owner: "panel"}
              }
            ],
            children: []
          },
          %{
            key: :tabs_status,
            type: :text,
            props: %{
              content: "Tab switching stays local to nested public buttons.",
              class: "ashui-example-surface-meta"
            },
            slot: :footer,
            position: 0,
            bindings: [
              %{
                id: :tabs_status_copy,
                source: %{resource: "ExampleState", field: :status, id: "state-tabs"},
                target: "content",
                binding_type: :value,
                transform: %{},
                metadata: %{owner: "footer"}
              }
            ],
            children: []
          }
        ],
        support_notice:
          "The `tabs` example keeps tab switching on nested public buttons instead of claiming a first-class public tabs widget.",
        notes: "Uses a dedicated example-only custom shell with nested public buttons."
      },
      %{
        directory: "command_palette",
        section: :layout_navigation,
        family: :navigation,
        title: "Command Palette Example",
        subject_type: :"custom:command_palette",
        subject_props: %{
          title: "Command palette",
          description:
            "Search input and command actions stay public children inside an explicit custom palette shell.",
          class: "ashui-example-command-palette-shell"
        },
        story_text:
          "Meaningful Interaction Story: change the query and execute a command to confirm the example keeps both the input and the actions on nested public child resources while the shell remains explicit.",
        signal_text:
          "Canonical Signal Preview: input change -> ExampleState.current_value; nested button click -> ExampleState.submitted_value and ExampleState.status.",
        seed_state: %{
          id: "state-command_palette",
          current_value: "open alerts",
          submitted_value: "triage alerts",
          status: "Command execution stays local to nested public controls."
        },
        preview_field: :submitted_value,
        preview_title: "Last command run",
        subject_binding: nil,
        subject_action: nil,
        subject_children: [
          %{
            key: :palette_query_input,
            type: :input,
            props: %{
              name: "query",
              type: "text",
              value: "open alerts",
              placeholder: "Search commands",
              class: "ashui-example-input"
            },
            slot: :search,
            position: 0,
            bindings: [
              %{
                id: :palette_query,
                source: %{
                  resource: "ExampleState",
                  field: :current_value,
                  id: "state-command_palette"
                },
                target: "query",
                binding_type: :value,
                transform: %{},
                metadata: %{owner: "input", owner_signal: "change"}
              }
            ],
            children: []
          },
          command_button(
            :triage_command_button,
            "Run triage",
            "Triage command executed.",
            "state-command_palette",
            0
          ),
          command_button(
            :handoff_command_button,
            "Prepare handoff",
            "Handoff command executed.",
            "state-command_palette",
            10
          ),
          %{
            key: :command_result,
            type: :text,
            props: %{
              content: "triage alerts",
              class: "ashui-example-surface-meta"
            },
            slot: :footer,
            position: 0,
            bindings: [
              %{
                id: :command_palette_result,
                source: %{
                  resource: "ExampleState",
                  field: :submitted_value,
                  id: "state-command_palette"
                },
                target: "content",
                binding_type: :value,
                transform: %{},
                metadata: %{owner: "footer"}
              }
            ],
            children: []
          }
        ],
        support_notice:
          "The `command_palette` example keeps query changes and command execution on nested public input/button resources instead of claiming a public palette widget.",
        notes: "Uses a dedicated example-only custom shell with nested public controls."
      }
    ]
  end

  defp display_system_definitions do
    [
      %{
        directory: "viewport",
        section: :display_systems,
        family: :display,
        title: "Viewport Example",
        subject_type: :"custom:viewport",
        subject_props: %{
          title: "Operations viewport",
          description:
            "Nested public buttons in the aside move viewport focus while the larger shell stays explicit.",
          class: "ashui-example-viewport-shell"
        },
        story_text:
          "Meaningful Interaction Story: change the focused lane from the viewport aside and confirm the larger display surface updates through nested public controls rather than a monolithic screen authority fragment.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.selected_value -> viewport body copy, footer status, and preview stat.",
        seed_state: %{
          id: "state-viewport",
          selected_value: "queue lane",
          status: "Viewport focus stays local to nested public controls."
        },
        preview_field: :selected_value,
        preview_title: "Focused lane",
        subject_binding: nil,
        subject_action: nil,
        subject_children: [
          slot_text(
            :body,
            :viewport_focus_copy,
            "queue lane",
            "ashui-example-surface-copy",
            0,
            field: :selected_value,
            state_id: "state-viewport"
          ),
          slot_card(
            :body,
            :viewport_support_panel,
            "Viewport support panel",
            "The body keeps the current lane visible while adjacent controls stay in related child resources.",
            10
          ),
          display_button(
            :focus_queue_lane,
            :queue_viewport_button,
            "Queue lane",
            "queue lane",
            "state-viewport",
            "Queue lane focused in the viewport.",
            :aside,
            0
          ),
          display_button(
            :focus_timeline_lane,
            :timeline_viewport_button,
            "Timeline lane",
            "timeline lane",
            "state-viewport",
            "Timeline lane focused in the viewport.",
            :aside,
            10
          ),
          display_button(
            :focus_handoff_lane,
            :handoff_viewport_button,
            "Handoff lane",
            "handoff lane",
            "state-viewport",
            "Handoff lane focused in the viewport.",
            :aside,
            20
          ),
          slot_text(
            :footer,
            :viewport_status,
            "Viewport focus stays local to nested public controls.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-viewport"
          )
        ],
        support_notice:
          "The `viewport` example remains an explicit `custom:viewport` surface; the focus controls live on related child resources in the aside.",
        notes: "Uses a dedicated example-only custom shell with bound body and footer text."
      },
      %{
        directory: "scroll_bar",
        section: :display_systems,
        family: :display,
        title: "Scroll Bar Example",
        subject_type: :"custom:scroll_bar",
        subject_props: %{
          title: "Lane scroll",
          description:
            "Nested public buttons shift the focused lane while the outer custom shell owns the larger scroll-track surface only.",
          thumb_label: "queue lane",
          class: "ashui-example-scroll-bar-shell"
        },
        story_text:
          "Meaningful Interaction Story: change the scroll focus through nested public buttons and confirm the thumb label plus status copy update without turning `scroll_bar` into an admitted public widget.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.selected_value -> thumb label binding, body copy, and preview stat.",
        seed_state: %{
          id: "state-scroll_bar",
          selected_value: "queue lane",
          status: "Scroll focus stays local to nested public controls."
        },
        preview_field: :selected_value,
        preview_title: "Thumb focus",
        subject_binding: %{
          id: :scroll_thumb_focus,
          field: :selected_value,
          target: "thumb_label",
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          slot_text(
            :body,
            :scroll_focus_copy,
            "queue lane",
            "ashui-example-surface-copy",
            0,
            field: :selected_value,
            state_id: "state-scroll_bar"
          ),
          display_button(
            :focus_queue_thumb,
            :queue_scroll_button,
            "Queue lane",
            "queue lane",
            "state-scroll_bar",
            "Queue lane aligned with the scroll thumb.",
            :body,
            10
          ),
          display_button(
            :focus_escalations_thumb,
            :escalations_scroll_button,
            "Escalations lane",
            "escalations lane",
            "state-scroll_bar",
            "Escalations lane aligned with the scroll thumb.",
            :body,
            20
          ),
          display_button(
            :focus_handoff_thumb,
            :handoff_scroll_button,
            "Handoff lane",
            "handoff lane",
            "state-scroll_bar",
            "Handoff lane aligned with the scroll thumb.",
            :body,
            30
          ),
          slot_text(
            :footer,
            :scroll_status,
            "Scroll focus stays local to nested public controls.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-scroll_bar"
          )
        ],
        support_notice:
          "The `scroll_bar` example keeps focus changes on nested public buttons while the thumb itself is driven through a subject-level binding.",
        notes: "Uses an explicit custom shell with a bound thumb label."
      },
      %{
        directory: "split_pane",
        section: :display_systems,
        family: :display,
        title: "Split Pane Example",
        subject_type: :"custom:split_pane",
        subject_props: %{
          title: "Review split pane",
          description:
            "Primary and secondary panes stay in related child resources while footer actions switch the emphasized pane.",
          class: "ashui-example-split-pane-shell"
        },
        story_text:
          "Meaningful Interaction Story: move emphasis between split panes and confirm the active pane copy changes through nested public actions instead of screen-local imperative layout code.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.selected_value -> secondary pane copy, status text, and preview stat.",
        seed_state: %{
          id: "state-split_pane",
          selected_value: "details pane",
          status: "Split-pane emphasis stays local to nested public controls."
        },
        preview_field: :selected_value,
        preview_title: "Active pane",
        subject_binding: nil,
        subject_action: nil,
        subject_children: [
          slot_card(
            :primary,
            :primary_review_panel,
            "Primary review panel",
            "The primary pane keeps the durable operational context visible at all times.",
            0
          ),
          slot_text(
            :secondary,
            :secondary_focus_copy,
            "details pane",
            "ashui-example-surface-copy",
            0,
            field: :selected_value,
            state_id: "state-split_pane"
          ),
          slot_text(
            :secondary,
            :split_status,
            "Split-pane emphasis stays local to nested public controls.",
            "ashui-example-surface-meta",
            10,
            field: :status,
            state_id: "state-split_pane"
          ),
          display_button(
            :select_details_pane,
            :details_pane_button,
            "Details pane",
            "details pane",
            "state-split_pane",
            "Details pane moved into focus.",
            :actions,
            0,
            "ashui-example-command-button"
          ),
          display_button(
            :select_handoff_pane,
            :handoff_pane_button,
            "Handoff pane",
            "handoff pane",
            "state-split_pane",
            "Handoff pane moved into focus.",
            :actions,
            10,
            "ashui-example-command-button"
          )
        ],
        support_notice:
          "The `split_pane` example keeps pane emphasis and action ownership on related child resources instead of collapsing the whole layout into one screen fragment.",
        notes: "Uses explicit primary, secondary, and actions slots."
      },
      %{
        directory: "canvas",
        section: :display_systems,
        family: :display,
        title: "Canvas Example",
        subject_type: :"custom:canvas",
        subject_props: %{
          title: "Response canvas",
          description:
            "Toolbar controls and legend copy stay in related child resources while the board remains an explicit custom display surface.",
          class: "ashui-example-canvas-shell"
        },
        story_text:
          "Meaningful Interaction Story: switch the active layer from the toolbar and confirm the board plus legend update through nested public controls while the canvas shell remains explicit.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.selected_value -> canvas board copy, legend status, and preview stat.",
        seed_state: %{
          id: "state-canvas",
          selected_value: "incident map",
          status: "Canvas layer selection stays local to nested public controls."
        },
        preview_field: :selected_value,
        preview_title: "Active layer",
        subject_binding: nil,
        subject_action: nil,
        subject_children: [
          display_button(
            :select_incident_map_layer,
            :incident_map_button,
            "Incident map",
            "incident map",
            "state-canvas",
            "Incident map layer selected on the canvas.",
            :toolbar,
            0,
            "ashui-example-command-button"
          ),
          display_button(
            :select_handoff_path_layer,
            :handoff_path_button,
            "Handoff path",
            "handoff path",
            "state-canvas",
            "Handoff path layer selected on the canvas.",
            :toolbar,
            10,
            "ashui-example-command-button"
          ),
          slot_text(
            :body,
            :canvas_active_layer,
            "incident map",
            "ashui-example-surface-copy",
            0,
            field: :selected_value,
            state_id: "state-canvas"
          ),
          slot_text(
            :body,
            :canvas_board_copy,
            "The board stays intentionally sparse so the authored layer relationship remains readable.",
            "ashui-example-surface-meta",
            10
          ),
          slot_text(
            :legend,
            :canvas_status,
            "Canvas layer selection stays local to nested public controls.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-canvas"
          )
        ],
        support_notice:
          "The `canvas` example keeps toolbar controls and legend updates on related child resources while the board remains an explicit `custom:canvas` surface.",
        notes: "Uses explicit toolbar, body, and legend slots."
      }
    ]
  end

  defp layout_card(key, title, detail, position) do
    %{
      key: key,
      type: :card,
      props: %{class: "ashui-example-layout-card"},
      position: position,
      children: [
        %{
          key: :"#{key}_title",
          type: :text,
          props: %{content: title, class: "ashui-example-layout-title"},
          position: 0,
          children: []
        },
        %{
          key: :"#{key}_detail",
          type: :text,
          props: %{content: detail, class: "ashui-example-layout-copy"},
          position: 10,
          children: []
        }
      ]
    }
  end

  defp slot_card(slot, key, title, detail, position) do
    layout_card(key, title, detail, position)
    |> Map.put(:slot, slot)
  end

  defp nav_button(key, label, selected_value, state_id, status_copy) do
    %{
      key: key,
      type: :button,
      props: %{
        label: label,
        variant: "secondary",
        class: "ashui-example-nav-button"
      },
      slot: :nav,
      position: nav_position_for(key),
      actions: [
        %{
          id: String.to_atom("select_#{selected_value}"),
          signal: :click,
          source: %{resource: "ExampleState", action: "update", id: state_id},
          target: "submit",
          transform: %{
            params: %{
              selected_value: %{"from" => "static", "value" => selected_value},
              status: %{"from" => "static", "value" => status_copy}
            }
          },
          metadata: %{intent: "select_navigation", success_message: "Selection updated"}
        }
      ],
      children: []
    }
  end

  defp nav_position_for(:overview_button), do: 0
  defp nav_position_for(:overview_tab_button), do: 0
  defp nav_position_for(:monitoring_button), do: 10
  defp nav_position_for(:metrics_tab_button), do: 10
  defp nav_position_for(:handoff_button), do: 20
  defp nav_position_for(:escalations_tab_button), do: 20
  defp nav_position_for(_key), do: 0

  defp command_button(key, label, status_copy, state_id, position) do
    %{
      key: key,
      type: :button,
      props: %{
        label: label,
        variant: "primary",
        class: "ashui-example-command-button"
      },
      slot: :body,
      position: position,
      actions: [
        %{
          id: action_id_for_command(key),
          signal: :click,
          source: %{resource: "ExampleState", action: "update", id: state_id},
          target: "submit",
          transform: %{
            params: %{
              submitted_value: %{"from" => "binding", "key" => "query"},
              status: %{"from" => "static", "value" => status_copy}
            }
          },
          metadata: %{intent: "run_command", success_message: "Command executed"}
        }
      ],
      children: []
    }
  end

  defp display_button(
         action_id,
         key,
         label,
         selected_value,
         state_id,
         status_copy,
         slot,
         position,
         class \\ "ashui-example-nav-button"
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
          id: action_id,
          signal: :click,
          source: %{resource: "ExampleState", action: "update", id: state_id},
          target: "submit",
          transform: %{
            params: %{
              selected_value: %{"from" => "static", "value" => selected_value},
              status: %{"from" => "static", "value" => status_copy}
            }
          },
          metadata: %{intent: "select_display_surface", success_message: "Selection updated"}
        }
      ],
      children: []
    }
  end

  defp slot_text(slot, key, content, class, position, opts \\ []) do
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

  defp action_id_for_command(:triage_command_button), do: :run_triage_command
  defp action_id_for_command(:handoff_command_button), do: :run_handoff_command

  @doc """
  Returns every currently authored Phase 19 definition.
  """
  @spec definitions() :: [definition()]
  def definitions do
    layout_navigation_definitions() ++ display_system_definitions()
  end

  @doc """
  Returns the authored sections known to Phase 19.
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
      raise ArgumentError, "unknown Phase 19 example directory: #{inspect(directory)}"
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
