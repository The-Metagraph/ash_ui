defmodule BasicDashboard.AuthoredScreen do
  @moduledoc false

  use UnifiedUi.Dsl

  identity do
    id(:basic_dashboard_screen)
    title("Basic Dashboard")
    description("Standalone ETS-backed dashboard example authored through UnifiedUi.Dsl.")
    authored_ref([:examples, :basic_dashboard, :basic_dashboard_screen])
    tags([:example, :dashboard, :ets, :phase_12])
  end

  composition do
    root(:basic_dashboard_root)
    mode(:screen)
    summary("ETS-backed dashboard authored through UnifiedUi")

    column :dashboard_shell do
      row :top_bar do
        text :top_bar_label do
          value("Ash UI example")
        end

        text :top_bar_copy do
          value("Basic dashboard on ETS-backed Ash resources")
        end

        badge :theme_badge do
          value("Unified UI DSL")
        end

        badge :data_badge do
          value("ETS + PubSub")
        end

        badge :runtime_badge do
          value("LiveView bindings")
        end
      end

      hero :dashboard_hero do
        eyebrow("Ash-inspired example")
        title("Model your dashboard. Let the runtime do the wiring.")

        message(
          "This screen is authored through UnifiedUi.Dsl, persisted through AshUI.Authoring.Screen, and hydrated from live Ash bindings without a handwritten dashboard shell."
        )

        badge :route_badge do
          value("/dashboard")
        end

        badge :screen_badge do
          value("Basic Dashboard")
        end
      end

      text :preview_title do
        value("Live signal preview")
      end

      text :preview_copy do
        value(
          "The input is bidirectionally bound to a real ETS-backed BasicDashboard.User, and the save button runs the save_profile Ash action with actor context."
        )
      end

      stat :current_value_stat do
        title("Current value")
        value("Pascal")
        message("Hydrated from the current ETS-backed user record")
      end

      stat :last_actor_stat do
        title("Last actor")
        value("none yet")
        message("Updated by the save_profile Ash action")
      end

      key_value :runtime_domain_meta do
        label("Runtime domain")
        value("BasicDashboard.Domain")
      end

      key_value :renderer_meta do
        label("Renderer path")
        value("Ash UI -> LiveView")
      end

      text :editor_overline do
        value("Interactive profile editor")
      end

      text :editor_title do
        value("Update the current user")
      end

      text :editor_copy do
        value(
          "Type into the bound field to update the ETS record immediately, then click save to persist through the save_profile Ash action."
        )
      end

      form_builder :profile_form do
        submit_intent(:save_profile)

        form_field :display_name_field do
          field_name(:display_name)
          label("Display name")
          help("Used to verify UnifiedUi-authored form fields survive persistence and hydration")

          text_input :display_name_input do
            placeholder("Enter your name")
          end
        end

        button :save_profile_button do
          label("Save profile")
          action_intent(:save_profile)
        end
      end

      info_list :editor_meta do
        items([
          %{id: :resource, label: "Resource", value: "BasicDashboard.User"},
          %{id: :action, label: "Action", value: "save_profile"},
          %{id: :actor, label: "Actor", value: "current-user"}
        ])
      end

      text :snapshot_overline do
        value("Snapshot")
      end

      text :snapshot_title do
        value("Current dashboard state")
      end

      key_value :name_row do
        label("Display name")
        value("Pascal")
      end

      key_value :email_row do
        label("Email")
        value("pascal@example.com")
      end

      key_value :status_row do
        label("Status")
        value("Active")
      end

      key_value :team_row do
        label("Team")
        value("Platform")
      end

      key_value :profile_name_row do
        label("Profile name")
        value("Operations")
      end

      text :explainer_overline do
        value("What this demo is showing")
      end

      text :explainer_title do
        value("Persisted layout + runtime bindings")
      end

      info_list :explainer_list do
        items([
          %{
            id: :real_ash_resources,
            label: "Real Ash resources",
            value:
              "BasicDashboard.User and BasicDashboard.Profile live in an ETS data layer domain."
          },
          %{
            id: :runtime_reactivity,
            label: "Runtime reactivity",
            value:
              "PubSub notifications refresh the rendered IUR whenever the bound resources change."
          },
          %{
            id: :stored_ui_contract,
            label: "Stored UI contract",
            value:
              "The dashboard shell, hero, stats, form, and snapshot rows are all authored through UnifiedUi.Dsl and persisted through AshUI.Authoring."
          }
        ])
      end
    end
  end
end
