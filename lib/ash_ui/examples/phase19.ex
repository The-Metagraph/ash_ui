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

  defp display_system_definitions, do: []

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
