defmodule UnifiedUi.AdvancedWidgetFamiliesTest do
  use ExUnit.Case, async: true

  alias Spark.Dsl.Extension

  defmodule OperationsDashboard do
    use UnifiedUi.Dsl

    identity do
      id(:operations_dashboard)
      authored_ref([:examples, :operations_dashboard])
    end

    composition do
      root(:operations_dashboard_root)
      mode(:screen)

      column :operations_shell do
        summary("Operations shell")

        list :incident_list do
          items([
            [id: :sev_1, label: "SEV-1 outage", description: "Database failover in progress"],
            [
              id: :sev_2,
              label: "SEV-2 queue lag",
              description: "Background jobs delayed",
              selected?: true
            ]
          ])

          selection_mode(:single)
          empty_state("No incidents")
        end

        table :deployments_table do
          table_columns(name: "Name", status: "Status")

          table_rows([
            [name: "API", status: "Healthy"],
            [name: "Web", status: "Degraded"]
          ])

          empty_state("No deployments")
        end

        tree_view :cluster_tree do
          tree_nodes([
            [id: :cluster, label: "Cluster", children: [[id: :node_a, label: "Node A"]]]
          ])
        end

        gauge :cpu_gauge do
          current(72)
          maximum(100)
          severity(:warning)
        end

        sparkline :cpu_trend do
          points([30, 45, 51, 72])
        end

        stream_widget :event_stream do
          entries([
            [id: "evt-1", message: "ready", severity: :info],
            [id: "evt-2", message: "warning", severity: :warning]
          ])

          severity_field(:severity)
        end

        process_monitor :processes do
          processes([
            [pid: "#PID<0.10.0>", name: "api", state: :running]
          ])

          sort_by(:cpu)
        end

        cluster_dashboard :cluster_status do
          cluster_nodes([
            [id: :node_a, status: :up],
            [id: :node_b, status: :degraded]
          ])

          metrics(%{healthy: 1, degraded: 1})
        end
      end
    end
  end

  test "registers advanced data, feedback, and operational widget kinds for package inspection" do
    assert UnifiedUi.Widgets.data_kinds() == [
             :list,
             :table,
             :tree_view,
             :stat,
             :key_value,
             :info_list,
             :markdown_viewer,
             :log_viewer
           ]

    assert UnifiedUi.Widgets.Feedback.kinds() == [
             :status,
             :progress,
             :gauge,
             :inline_feedback,
             :sparkline,
             :bar_chart,
             :line_chart
           ]

    assert UnifiedUi.Widgets.Advanced.kinds() == [
             :stream_widget,
             :process_monitor,
             :supervision_tree_viewer,
             :cluster_dashboard
           ]

    assert UnifiedUi.Widgets.kinds() == [
             :text,
             :label,
             :icon,
             :image,
             :badge,
             :hero,
             :content,
             :button,
             :link,
             :separator,
             :spacer,
             :text_input,
             :numeric_input,
             :toggle,
             :checkbox,
             :radio_group,
             :select,
             :pick_list,
             :date_input,
             :time_input,
             :file_input,
             :menu,
             :tabs,
             :command_palette,
             :list,
             :table,
             :tree_view,
             :stat,
             :key_value,
             :info_list,
             :markdown_viewer,
             :log_viewer,
             :status,
             :progress,
             :gauge,
             :inline_feedback,
             :sparkline,
             :bar_chart,
             :line_chart,
             :stream_widget,
             :process_monitor,
             :supervision_tree_viewer,
             :cluster_dashboard,
             :inline_rich_text_heading,
             :disclosure,
             :kicker,
             :avatar,
             :presence_dot,
             :segmented_button_group,
             :runtime_form_shell,
             :chat_composer,
             :list_item_multi_column,
             :artifact_row,
             :thread_card,
             :pipeline_stepper_horizontal,
             :segmented_progress_bar,
             :workflow_stage_list_vertical,
             :meter_thin,
             :workflow_progress_status_card,
             :sticky_frosted_header,
             :slide_over_panel,
             :event_callout,
             :composer_query_preview,
             :right_rail,
             :redline_inline,
             :code_block_syntax_highlighted,
             :list_repeat
           ]
  end

  test "stores advanced widget families inside authored dashboard layouts" do
    [dashboard] = Extension.get_entities(OperationsDashboard, [:composition])

    assert dashboard.family == :layout
    assert dashboard.kind == :column

    assert Enum.map(dashboard.children, &{&1.id, &1.family, &1.kind}) == [
             {:incident_list, :data, :list},
             {:deployments_table, :data, :table},
             {:cluster_tree, :data, :tree_view},
             {:cpu_gauge, :feedback, :gauge},
             {:cpu_trend, :feedback, :sparkline},
             {:event_stream, :advanced, :stream_widget},
             {:processes, :advanced, :process_monitor},
             {:cluster_status, :advanced, :cluster_dashboard}
           ]
  end

  test "summarizes advanced authored dashboards without any renderer runtime" do
    assert UnifiedUi.Info.composition_summary(OperationsDashboard) == [
             %{
               id: :operations_shell,
               family: :layout,
               kind: :column,
               summary: "Operations shell",
               children: [
                 %{
                   id: :incident_list,
                   family: :data,
                   items: [
                     [
                       id: :sev_1,
                       label: "SEV-1 outage",
                       description: "Database failover in progress"
                     ],
                     [
                       id: :sev_2,
                       label: "SEV-2 queue lag",
                       description: "Background jobs delayed",
                       selected?: true
                     ]
                   ],
                   kind: :list,
                   ordered?: false,
                   selection_mode: :single,
                   empty_state: "No incidents"
                 },
                 %{
                   id: :deployments_table,
                   family: :data,
                   kind: :table,
                   empty_state: "No deployments"
                 },
                 %{
                   id: :cluster_tree,
                   family: :data,
                   kind: :tree_view,
                   expanded?: true
                 },
                 %{
                   id: :cpu_gauge,
                   family: :feedback,
                   kind: :gauge,
                   current: 72,
                   minimum: 0,
                   maximum: 100,
                   severity: :warning
                 },
                 %{id: :cpu_trend, family: :feedback, kind: :sparkline},
                 %{
                   id: :event_stream,
                   family: :advanced,
                   kind: :stream_widget,
                   severity_field: :severity,
                   ordering: :append_only
                 },
                 %{
                   id: :processes,
                   family: :advanced,
                   kind: :process_monitor,
                   sort_by: :cpu
                 },
                 %{
                   id: :cluster_status,
                   family: :advanced,
                   kind: :cluster_dashboard
                 }
               ]
             }
           ]
  end
end
