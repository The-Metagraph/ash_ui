defmodule UnifiedUi.Phase3IntegrationTest do
  use ExUnit.Case, async: true

  defmodule OperationsControlRoom do
    use UnifiedUi.Dsl

    identity do
      id(:operations_control_room)
      title("Operations Control Room")
      authored_ref([:integration, :operations_control_room])
      tags([:integration, :phase_3])
    end

    composition do
      root(:operations_control_room_root)
      mode(:screen)
      summary("Phase 3 control room")

      box :activity_panel do
        text :activity_title do
          value("Activity stream")
        end
      end

      box :settings_panel do
        text :settings_title do
          value("Settings")
        end
      end

      row :workspace_shell do
        summary("Operational shell")

        menu :workspace_nav do
          items(overview: "Overview", incidents: "Incidents")
          active_item(:overview)
        end

        button :open_settings do
          label("Open settings")
          action_intent(:open_settings)
        end

        button :open_context do
          label("Open actions")
          action_intent(:open_actions)
        end

        table :incident_table do
          table_columns(id: "ID", severity: "Severity")

          table_rows([
            [id: "INC-101", severity: "warning"],
            [id: "INC-102", severity: "critical"]
          ])
        end

        line_chart :incident_trend do
          series([
            [id: :warning, values: [1, 2, 3]],
            [id: :critical, values: [0, 1, 1]]
          ])

          x_label("Hour")
          y_label("Incidents")
        end

        viewport :activity_viewport do
          content_ref(:activity_panel)
          width(80)
          height(24)
          offset({0, 8})
        end

        canvas :activity_canvas do
          width(80)
          height(24)

          operations([
            [kind: :cell, position: {0, 0}, text: "X"],
            [kind: :fragment, position: {3, 2}, text: "Alert"]
          ])
        end

        cluster_dashboard :cluster_status do
          cluster_nodes([
            [id: :node_a, status: :up],
            [id: :node_b, status: :degraded]
          ])

          metrics(%{healthy: 1, degraded: 1})
        end
      end

      dialog :settings_dialog do
        title("Settings")
        content_ref(:settings_panel)
        trigger_ref(:open_settings)
        visible?(true)
      end

      context_menu :workspace_menu do
        options(retry: "Retry", silence: "Silence")
        target_ref(:workspace_shell)
        trigger_ref(:open_context)
      end

      toast :action_toast do
        title("Updated")
        message("Action completed")
        severity(:success)
      end

      absolute :floating_badge do
        content_ref(:settings_panel)
        target_ref(:workspace_shell)
        x(12)
        y(4)
        z_index(2)
      end

      overlay :control_overlay do
        base_ref(:workspace_shell)
        layer_refs([:settings_dialog, :workspace_menu, :action_toast, :floating_badge])
        background_fill(:scrim)
      end

      split_pane :workspace_split do
        primary_ref(:workspace_shell)
        secondary_ref(:settings_panel)
        ratio(0.4)
      end

      scroll_bar :activity_scroll do
        target_ref(:activity_viewport)
        position(8)
        viewport_size(24)
        content_size(96)
      end
    end
  end

  test "phase 3 authored control rooms combine advanced widgets, overlays, and display systems through public inspection helpers" do
    summary = UnifiedUi.Info.composition_summary(OperationsControlRoom)

    assert Enum.map(summary, &{&1.id, &1.family, &1.kind}) == [
             {:activity_panel, :layout, :box},
             {:settings_panel, :layout, :box},
             {:workspace_shell, :layout, :row},
             {:settings_dialog, :overlay, :dialog},
             {:workspace_menu, :overlay, :context_menu},
             {:action_toast, :overlay, :toast},
             {:floating_badge, :overlay, :absolute},
             {:control_overlay, :overlay, :overlay},
             {:workspace_split, :display, :split_pane},
             {:activity_scroll, :display, :scroll_bar}
           ]

    assert Enum.map(Enum.at(summary, 2).children, &{&1.id, &1.family, &1.kind}) == [
             {:workspace_nav, :navigation, :menu},
             {:open_settings, :foundational, :button},
             {:open_context, :foundational, :button},
             {:incident_table, :data, :table},
             {:incident_trend, :feedback, :line_chart},
             {:activity_viewport, :display, :viewport},
             {:activity_canvas, :canvas, :canvas},
             {:cluster_status, :advanced, :cluster_dashboard}
           ]

    assert UnifiedUi.Info.inspect_module(OperationsControlRoom).sections == %{
             composition: true,
             identity: true,
             signals: false,
             themes: false
           }
  end

  test "phase 3 advanced examples remain introspectable and renderer-independent" do
    assert Enum.map(UnifiedUi.Reference.example_catalog(), & &1.id) == [
             :foundational_screen,
             :profile_form,
             :overlay_workspace,
             :operations_dashboard,
             :themed_signal_workspace
           ]

    overlay_example =
      UnifiedUi.Info.example_summaries()
      |> Enum.find(&(&1.id == :overlay_workspace))

    assert overlay_example.constructs == [:overlay, :display, :layout]

    assert Enum.map(overlay_example.composition, &{&1.id, &1.family, &1.kind}) == [
             {:workspace_shell, :layout, :row},
             {:settings_panel, :layout, :box},
             {:settings_dialog, :overlay, :dialog},
             {:workspace_menu, :overlay, :context_menu},
             {:save_toast, :overlay, :toast},
             {:workspace_split, :display, :split_pane},
             {:workspace_scroll, :display, :scroll_bar}
           ]
  end

  test "phase 3 placement rules surface the advanced legality contracts" do
    assert Enum.map(UnifiedUi.Reference.placement_rules().rules, & &1.id) |> Enum.sort() ==
             [
               :canvas_operations_require_kind_and_position,
               :default_slot_requires_fragment_mode,
               :field_requires_one_input_child,
               :layer_refs_must_target_overlay_nodes,
               :leaf_nodes_cannot_have_children,
               :overlay_content_refs_must_resolve,
               :required_identity_and_composition_sections,
               :root_identifier_must_differ_from_module_identifier,
               :split_pane_refs_must_be_distinct,
               :viewport_and_scroll_refs_must_target_displayable_content
             ]
             |> Enum.sort()
  end

  test "phase 3 invalid advanced placement still fails at compile time with actionable diagnostics" do
    assert_compile_dsl_error(
      """
      identity do
        id(:broken_phase_3)
      end

      composition do
        root(:broken_phase_3_root)

        toast :notice do
          message("Saved")
        end

        overlay :broken_overlay do
          base_ref(:notice)
          layer_refs([:notice])
        end
      end
      """,
      "may not target overlay nodes through base_ref"
    )
  end

  defp compile_module(body) do
    module_name = "Generated#{System.unique_integer([:positive])}"

    Code.compile_string("""
    defmodule UnifiedUi.Phase3IntegrationTest.#{module_name} do
      use UnifiedUi.Dsl

      #{body}
    end
    """)
  end

  defp assert_compile_dsl_error(body, expected_message) do
    {pid, ref} = spawn_monitor(fn -> compile_module(body) end)

    receive do
      {:DOWN, ^ref, :process, ^pid, :normal} ->
        flunk("expected authored module compilation to fail, but it succeeded")

      {:DOWN, ^ref, :process, ^pid, reason} ->
        assert Exception.format_exit(reason) =~ expected_message
    end
  end
end
