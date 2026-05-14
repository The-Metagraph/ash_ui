defmodule UnifiedUi.Phase4IntegrationTest do
  use ExUnit.Case, async: true

  alias UnifiedUi.{Info, Signals, Theme}

  defmodule ThemedSignalWorkspace do
    use UnifiedUi.Dsl

    identity do
      id(:themed_signal_workspace)
      title("Themed Signal Workspace")
      description("Phase 4 authored workspace for themes, styles, and canonical signals")
      authored_ref([:integration, :themed_signal_workspace])
      tags([:integration, :phase_4])
    end

    themes do
      default_theme(:workspace_dark)

      theme do
        id(:workspace)
        summary("Base workspace theme")

        palette_color do
          id(:surface)
          color(named_color(:black))
        end

        palette_color do
          id(:accent)
          color(named_color(:cyan))
        end

        semantic_role do
          id(:primary_text)
          value(named_color(:white))
        end

        token do
          id(:panel_shell)

          value(
            style_value(
              background: token_ref(:surface),
              spacing: %{padding: 2, gap: 1},
              border: %{width: 1, style: :solid}
            )
          )
        end

        component_style do
          id(:panel_shell)
          component(:box)

          style(
            style_value(
              token_refs: [token_ref(:panel_shell)],
              foreground: role_ref(:primary_text)
            )
          )
        end

        component_style do
          id(:modal_shell)
          component(:dialog)
          style(style_value(token_refs: [token_ref(:panel_shell)], visibility: %{opacity: 0.98}))
        end
      end

      theme do
        id(:workspace_dark)
        extends(:workspace)
        summary("Derived workspace theme")

        component_style do
          id(:command_action)
          component(:button)
          variant(:primary)
          state(:focused)

          style(
            style_value(
              border_color: token_ref(:accent),
              emphasis: %{tone: :info}
            )
          )
        end
      end
    end

    composition do
      root(:themed_signal_workspace_root)
      mode(:screen)
      summary("Phase 4 themed workspace")

      box :activity_feed do
        theme_ref(:workspace_dark)
        style_refs([:panel_shell])

        text :activity_title do
          value("Activity feed")
          variant(:headline)
          tone(:info)
        end

        log_viewer :activity_log do
          log_entries([
            %{message: "Service started", severity: :info},
            %{message: "Latency spike", severity: :warning}
          ])

          wrap?(true)
        end
      end

      box :settings_panel do
        theme_ref(:workspace_dark)
        style_refs([:panel_shell])

        text :settings_title do
          value("Workspace settings")
          variant(:headline)
        end
      end

      row :workspace_shell do
        theme_ref(:workspace_dark)
        style_refs([:panel_shell])

        style(
          style_value(
            sizing: %{width: :fill},
            alignment: %{align: :stretch},
            state_variants: %{
              focused: style_value(border_color: token_ref(:accent))
            }
          )
        )

        form_builder :filters_form do
          binding_refs([:filters])
          interaction_refs([:filters_change, :filters_submit])
          submit_intent(:apply_filters)

          field_group :filters_group do
            legend("Filters")

            field :query_field do
              field_name(:query)
              label("Query")
              value_path([:filters, :query])

              text_input :query_input do
                placeholder("service:api")
              end
            end

            field :severity_field do
              field_name(:severity)
              label("Severity")
              default_value(:all)

              select :severity_input do
                options(all: "All", warning: "Warning", critical: "Critical")
              end
            end
          end
        end

        tabs :dashboard_tabs do
          items(overview: "Overview", activity: "Activity")
          active_item(:overview)
          interaction_refs([:navigate_activity])
        end

        gauge :health_gauge do
          current(82)
          minimum(0)
          maximum(100)

          style(style_value(emphasis: %{weight: :strong, tone: :success}))
        end

        button :open_settings_button do
          label("Open settings")
          interaction_refs([:open_settings])
          style_refs([:command_action])
        end

        command_palette :workspace_commands do
          items(open_settings: "Open settings", focus_filters: "Focus filters")
          label("Workspace commands")
          interaction_refs([:open_commands])
        end

        viewport :activity_viewport do
          content_ref(:activity_feed)
          width(80)
          height(24)
          offset({0, 4})
          clip?(true)

          style(
            style_value(
              border: %{width: 1},
              visibility: %{opacity: 0.95}
            )
          )
        end

        canvas :status_canvas do
          width(20)
          height(8)

          operations([
            [kind: :cell, position: {0, 0}, text: "S"],
            [kind: :fragment, position: {2, 1}, text: "SYNC"]
          ])

          style(
            style_value(
              background: token_ref(:surface),
              emphasis: %{intent: :focus}
            )
          )
        end
      end

      dialog :settings_dialog do
        title("Settings")
        content_ref(:settings_panel)
        trigger_ref(:open_settings_button)
        visible?(true)
        theme_ref(:workspace_dark)
        style_refs([:modal_shell])
      end

      overlay :workspace_overlay do
        base_ref(:workspace_shell)
        layer_refs([:settings_dialog])
        background_fill(:scrim)

        style(style_value(emphasis: %{elevation: 3}))
      end
    end

    signals do
      namespace(:workspace)
      default_target(:session)

      data_binding do
        id(:filters)
        path([:filters])
        scope([:screen])
        default(%{query: "", severity: :all})
      end

      data_binding do
        id(:active_tab)
        path([:navigation, :active_tab])
        scope([:screen])
        default(:overview)
      end

      interaction do
        id(:filters_change)
        family(:change)
        intent(:update_filters)
        source_context(element_id: :filters_form, scope: :screen)
        target_intent(binding: :filters, entity: :dashboard)
        payload_mapping(filters: binding_ref(:filters), phase: :draft)
      end

      interaction do
        id(:filters_submit)
        family(:submit)
        intent(:apply_filters)
        source_context(element_id: :filters_form, scope: :screen)
        target_intent(binding: :filters, action: :apply)
        payload_mapping(filters: binding_ref(:filters), action: :apply)
        binding_refs([:filters])
      end

      interaction do
        id(:navigate_activity)
        family(:navigation)
        intent(:navigate_dashboard)
        source_context(element_id: :dashboard_tabs)
        target_intent(binding: :active_tab, destination: :activity)
        payload_mapping(tab: binding_ref(:active_tab), destination: :activity)
      end

      interaction do
        id(:open_settings)
        family(:open)
        intent(:open_settings)
        source_context(element_id: :open_settings_button)
        target_intent(overlay: :settings_dialog)
        payload_mapping(source: :button)
      end

      interaction do
        id(:open_commands)
        family(:command)
        intent(:open_command_palette)
        source_context(element_id: :workspace_commands)
        target_intent(command: :workspace_commands)
        payload_mapping(source: :keyboard_shortcut)
      end
    end
  end

  test "phase 4 authored modules preserve theme inheritance and style composition across widgets, layouts, overlays, and canvas nodes" do
    theme_summary = Theme.module_summary(ThemedSignalWorkspace)

    assert theme_summary.default_theme == :workspace_dark

    workspace_theme = Enum.find(theme_summary.themes, &(&1.id == :workspace))
    derived_theme = Enum.find(theme_summary.themes, &(&1.id == :workspace_dark))

    assert workspace_theme.summary == "Base workspace theme"
    assert workspace_theme.inherit? == true

    assert workspace_theme.palette_colors == [
             %{id: :surface, color: %{mode: :named, name: :black}},
             %{id: :accent, color: %{mode: :named, name: :cyan}}
           ]

    assert workspace_theme.semantic_roles == [
             %{id: :primary_text, value: %{mode: :named, name: :white}}
           ]

    assert workspace_theme.tokens == [
             %{
               id: :panel_shell,
               value: %{
                 background: %{kind: :token_ref, path: [:surface]},
                 spacing: %{gap: 1, padding: 2},
                 border: %{style: :solid, width: 1},
                 inherit?: true
               }
             }
           ]

    assert workspace_theme.component_styles == [
             %{
               id: :panel_shell,
               component: :box,
               style: %{
                 token_refs: [%{kind: :token_ref, path: [:panel_shell]}],
                 foreground: %{kind: :role_ref, id: :primary_text},
                 inherit?: true
               },
               inherit?: true
             },
             %{
               id: :modal_shell,
               component: :dialog,
               style: %{
                 token_refs: [%{kind: :token_ref, path: [:panel_shell]}],
                 visibility: %{opacity: 0.98},
                 inherit?: true
               },
               inherit?: true
             }
           ]

    assert derived_theme == %{
             id: :workspace_dark,
             extends: :workspace,
             summary: "Derived workspace theme",
             inherit?: true,
             component_styles: [
               %{
                 id: :command_action,
                 component: :button,
                 variant: :primary,
                 state: :focused,
                 style: %{
                   border_color: %{kind: :token_ref, path: [:accent]},
                   emphasis: %{tone: :info},
                   inherit?: true
                 },
                 inherit?: true
               }
             ]
           }

    [activity_feed, settings_panel, workspace_shell, settings_dialog, workspace_overlay] =
      Info.composition_summary(ThemedSignalWorkspace)

    assert activity_feed.style_refs == [:panel_shell]
    assert settings_panel.style_refs == [:panel_shell]
    assert workspace_shell.theme_ref == :workspace_dark
    assert workspace_shell.style_refs == [:panel_shell]

    assert workspace_shell.style == %{
             sizing: %{width: :fill},
             alignment: %{align: :stretch},
             state_variants: %{
               focused: %{border_color: %{kind: :token_ref, path: [:accent]}, inherit?: true}
             },
             inherit?: true
           }

    assert Enum.map(workspace_shell.children, &{&1.id, &1.family, &1.kind}) == [
             {:filters_form, :forms, :form_builder},
             {:dashboard_tabs, :navigation, :tabs},
             {:health_gauge, :feedback, :gauge},
             {:open_settings_button, :foundational, :button},
             {:workspace_commands, :navigation, :command_palette},
             {:activity_viewport, :display, :viewport},
             {:status_canvas, :canvas, :canvas}
           ]

    assert settings_dialog.theme_ref == :workspace_dark
    assert settings_dialog.style_refs == [:modal_shell]
    assert workspace_overlay.style == %{emphasis: %{elevation: 3}, inherit?: true}
  end

  test "phase 4 authored modules preserve canonical bindings and interactions across form, navigation, modal, and command flows" do
    assert Signals.module_summary(ThemedSignalWorkspace) == %{
             namespace: :workspace,
             default_target: :session,
             mode: :canonical,
             families: [
               :click,
               :change,
               :submit,
               :open,
               :close,
               :focus,
               :selection,
               :navigation,
               :command
             ],
             bindings: [
               %{
                 id: :filters,
                 path: [:filters],
                 scope: [:screen],
                 default: %{query: "", severity: :all},
                 collection?: false
               },
               %{
                 id: :active_tab,
                 path: [:navigation, :active_tab],
                 scope: [:screen],
                 default: :overview,
                 collection?: false
               }
             ],
             interactions: [
               %{
                 id: :filters_change,
                 family: :change,
                 intent: :update_filters,
                 source_context: %{element_id: :filters_form, scope: :screen},
                 target_intent: %{binding: :filters, entity: :dashboard},
                 payload_mapping: %{
                   filters: %{kind: :binding_ref, id: :filters},
                   phase: :draft
                 }
               },
               %{
                 id: :filters_submit,
                 family: :submit,
                 intent: :apply_filters,
                 source_context: %{element_id: :filters_form, scope: :screen},
                 target_intent: %{binding: :filters, action: :apply},
                 payload_mapping: %{
                   filters: %{kind: :binding_ref, id: :filters},
                   action: :apply
                 },
                 binding_refs: [%{kind: :binding_ref, id: :filters}]
               },
               %{
                 id: :navigate_activity,
                 family: :navigation,
                 intent: :navigate_dashboard,
                 source_context: %{element_id: :dashboard_tabs},
                 target_intent: %{binding: :active_tab, destination: :activity},
                 payload_mapping: %{
                   tab: %{kind: :binding_ref, id: :active_tab},
                   destination: :activity
                 }
               },
               %{
                 id: :open_settings,
                 family: :open,
                 intent: :open_settings,
                 source_context: %{element_id: :open_settings_button},
                 target_intent: %{overlay: :settings_dialog},
                 payload_mapping: %{source: :button}
               },
               %{
                 id: :open_commands,
                 family: :command,
                 intent: :open_command_palette,
                 source_context: %{element_id: :workspace_commands},
                 target_intent: %{command: :workspace_commands},
                 payload_mapping: %{source: :keyboard_shortcut}
               }
             ],
             navigation_descriptors: [
               %{
                 id: :navigate_activity,
                 kind: :local_destination,
                 binding: :active_tab,
                 destination: :activity
               }
             ]
           }

    [workspace_shell] =
      Info.composition_nodes(ThemedSignalWorkspace)
      |> Enum.filter(&(&1.id == :workspace_shell))

    [
      filters_form,
      dashboard_tabs,
      _health_gauge,
      open_settings_button,
      workspace_commands | _rest
    ] =
      workspace_shell.children

    assert filters_form.binding_refs == [:filters]
    assert filters_form.interaction_refs == [:filters_change, :filters_submit]
    assert dashboard_tabs.interaction_refs == [:navigate_activity]
    assert open_settings_button.interaction_refs == [:open_settings]
    assert open_settings_button.style_refs == [:command_action]
    assert workspace_commands.interaction_refs == [:open_commands]
  end

  test "phase 4 invalid style authoring still fails with deterministic diagnostics" do
    assert_compile_dsl_error(
      """
      identity do
        id(:invalid_theme_workspace)
      end

      composition do
        root(:invalid_theme_workspace_root)

        box :shell do
          style(
            style_value(
              state_variants: %{
                hovered: style_value(border_color: named_color(:cyan))
              }
            )
          )
        end
      end
      """,
      "state variant :hovered is not supported"
    )
  end

  test "phase 4 renderer-local signal leakage fails at compile time with actionable diagnostics" do
    assert_compile_dsl_error(
      """
      identity do
        id(:invalid_signal_workspace)
      end

      composition do
        root(:invalid_signal_workspace_root)

        form_builder :settings_form do
          interaction_refs([:save_settings])
        end
      end

      signals do
        data_binding do
          id(:settings)
          path([:settings])
        end

        interaction do
          id(:save_settings)
          family(:submit)
          intent(:save_settings)
          source_context(element_id: :settings_form, phx_submit: "save")
          payload_mapping(settings: binding_ref(:settings))
        end
      end
      """,
      "renderer-local key :phx_submit is not allowed"
    )
  end

  defp compile_module(body) do
    module_name = "Generated#{System.unique_integer([:positive])}"

    Code.compile_string("""
    defmodule UnifiedUi.Phase4IntegrationTest.#{module_name} do
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
