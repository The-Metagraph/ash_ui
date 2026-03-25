defmodule UnifiedUi.Examples.ThemedSignalWorkspace do
  @moduledoc """
  Reference workspace for cross-cutting theme inheritance, bindings, canonical
  signals, overlays, and display-system authoring.
  """

  use UnifiedUi.Dsl

  identity do
    id(:themed_signal_workspace)
    title("Themed Signal Workspace")
    description("Cross-cutting example for themes, styles, and canonical signals")
    authored_ref([:examples, :themed_signal_workspace])
    tags([:example, :themes, :signals])
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
    summary("Cross-cutting themed workspace")

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
      target_intent(binding: :active_tab, route: :activity)
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
