defmodule AshUI.Test.AuthoredSupportScreen do
  @moduledoc false

  use UnifiedUi.Dsl

  identity do
    id(:authored_support_screen)
    title("Authored Support Screen")
    description("Support module for Phase 9 persisted UnifiedUi authoring tests.")
    authored_ref([:ash_ui, :tests, :authored_support_screen])
    tags([:test, :phase_9, :semantic])
  end

  composition do
    root(:authored_support_root)
    mode(:screen)
    summary("Phase 9 authoring bridge example")

    column :authored_shell do
      hero :hero_panel do
        eyebrow("Authoring")
        title("Authored through UnifiedUi")
        message("Persisted through AshUI.Resource.Authority.")

        badge :status_badge do
          value("Ready")
        end
      end

      stat :runtime_stat do
        title("Runtime")
        value("Ash UI")
        message("Persistent screen bridge")
      end

      key_value :route_meta do
        label("Route")
        value("/authored")
        description("Persisted route metadata")
      end

      info_list :highlights do
        items([
          %{id: :upstream_dsl, label: "UnifiedUi DSL", value: :upstream_dsl},
          %{id: :ash_ui_persistence, label: "Ash UI persistence", value: :ash_ui_persistence},
          %{id: :semantic_widgets, label: "Semantic widgets", value: :semantic_widgets}
        ])
      end

      form_builder :profile_form do
        submit_intent(:save_profile)

        form_field :display_name_field do
          field_name(:display_name)
          label("Display name")
          help("Used to verify form_field survives the persistence bridge")

          text_input :display_name_input do
            placeholder("Enter your name")
          end
        end
      end
    end
  end
end

defmodule AshUI.Test.CustomBannerExtension do
  @moduledoc false

  alias UnifiedUi.Dsl.Entities.Foundational
  alias UnifiedUi.Dsl.EntitySchema
  alias UnifiedUi.Dsl.Node

  @custom_banner %Spark.Dsl.Entity{
    name: :custom_banner,
    target: Node,
    args: [:id],
    identifier: :id,
    recursive_as: :children,
    auto_set_fields: [family: :foundational, kind: :content],
    entities: [
      children:
        Foundational.entities()
        |> Enum.filter(&(&1.name in [:badge, :text, :button, :spacer]))
    ],
    schema:
      EntitySchema.widget(
        title: [type: :string, required: false],
        message: [type: :string, required: false],
        summary: [type: :string, required: false]
      )
  }

  @patch %Spark.Dsl.Patch.AddEntity{section_path: [:composition], entity: @custom_banner}

  use Spark.Dsl.Extension, dsl_patches: [@patch]
end

defmodule AshUI.Test.AuthoredCustomWidgetScreen do
  @moduledoc false

  use UnifiedUi.Dsl, extensions: [AshUI.Test.CustomBannerExtension]

  identity do
    id(:authored_custom_widget_screen)
    title("Authored Custom Widget Screen")
    authored_ref([:ash_ui, :tests, :authored_custom_widget_screen])
  end

  composition do
    root(:authored_custom_root)
    mode(:screen)

    column :authored_shell do
      custom_banner :banner_shell do
        title("Custom banner")
        message("Provided through an upstream Spark extension")

        badge :banner_badge do
          value("Patched")
        end

        text :banner_copy do
          value("Custom widgets should flow through upstream authoring.")
        end
      end
    end
  end
end
