defmodule AshUI.Test.ResourceAuthorityDomain do
  @moduledoc false

  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource(AshUI.Test.ResourceAuthorityScreen)
    resource(AshUI.Test.ResourceAuthorityHeroElement)
    resource(AshUI.Test.ResourceAuthorityStatElement)
    resource(AshUI.Test.ResourceAuthorityKeyValueElement)
    resource(AshUI.Test.ResourceAuthorityInfoListElement)
    resource(AshUI.Test.ResourceAuthorityFormPanelElement)
    resource(AshUI.Test.ResourceAuthorityFormFieldElement)
    resource(AshUI.Test.ResourceAuthorityInputElement)
    resource(AshUI.Test.ResourceAuthorityButtonElement)
    resource(AshUI.Test.RelationshipSemanticsBadgeElement)
    resource(AshUI.Test.RelationshipSemanticsPanelElement)
    resource(AshUI.Test.RelationshipOnlyScreen)
    resource(AshUI.Test.RelationshipMixedScreen)
    resource(AshUI.Test.RepeatRowElement)
    resource(AshUI.Test.RepeatScreen)
    resource(AshUI.Test.RepeatMissingBindingScreen)
    resource(AshUI.Test.RepeatNonListBindingScreen)
  end
end

defmodule AshUI.Test.ResourceAuthorityElementBase do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      use Ash.Resource,
        domain: AshUI.Test.ResourceAuthorityDomain,
        data_layer: Ash.DataLayer.Ets

      use AshUI.Resource.DSL.Element

      ets do
        private?(true)
      end

      attributes do
        uuid_primary_key(:id)
        attribute(:screen_id, :uuid, allow_nil?: true)
        attribute(:parent_id, :uuid, allow_nil?: true)
      end

      actions do
        defaults([:read])
      end
    end
  end
end

defmodule AshUI.Test.ResourceAuthorityHeroElement do
  @moduledoc false

  use AshUI.Test.ResourceAuthorityElementBase

  relationships do
    has_many :stats, AshUI.Test.ResourceAuthorityStatElement do
      destination_attribute(:parent_id)
    end

    has_many :meta_rows, AshUI.Test.ResourceAuthorityKeyValueElement do
      destination_attribute(:parent_id)
    end

    has_many :details_companions, AshUI.Test.ResourceAuthorityInfoListElement do
      destination_attribute(:parent_id)
    end
  end

  ui_relationships do
    relationship :stats do
      kind :child
      slot :body
      placement :append
      order 0
    end

    relationship :meta_rows do
      kind :child
      slot :aside
      placement :append
      order 1
    end

    relationship :details_companions do
      kind :companion
      slot :aside
      placement :append
      order 2
    end
  end

  ui_element do
    type :hero

    props %{
      eyebrow: "Resource authority",
      title: "Elements are the authoritative units",
      message: "The screen composes related element resources instead of one monolithic screen document."
    }

    metadata %{id: "dashboard_hero", section: "hero", slot: "body", position: 0}
  end
end

defmodule AshUI.Test.ResourceAuthorityStatElement do
  @moduledoc false

  use AshUI.Test.ResourceAuthorityElementBase

  ui_element do
    type :stat
    props %{title: "Current value", value: "unhydrated", message: "Owned by the stat element"}
    variants [:primary]
    metadata %{id: "current_value_stat", section: "hero", slot: "body", position: 0}
  end

  ui_bindings do
    binding :current_value do
      source %{resource: "Demo.User", field: "name", id: "user-1"}
      target "value"
      binding_type :value
      transform %{}
      metadata %{owner: "stat"}
    end
  end
end

defmodule AshUI.Test.ResourceAuthorityKeyValueElement do
  @moduledoc false

  use AshUI.Test.ResourceAuthorityElementBase

  ui_element do
    type :key_value
    props %{label: "Renderer path", value: "Ash UI -> Resource Authority"}
    metadata %{id: "renderer_meta", section: "meta", slot: "aside", position: 1}
  end
end

defmodule AshUI.Test.ResourceAuthorityInfoListElement do
  @moduledoc false

  use AshUI.Test.ResourceAuthorityElementBase

  ui_element do
    type :info_list

    props %{
      items: [
        %{id: "ownership", label: "Ownership", value: "Element-local"},
        %{id: "bindings", label: "Bindings", value: "Declared on the owning resource"}
      ]
    }

    metadata %{id: "explainer_list", section: "meta", slot: "aside", position: 2}
  end
end

defmodule AshUI.Test.ResourceAuthorityFormPanelElement do
  @moduledoc false

  use AshUI.Test.ResourceAuthorityElementBase

  relationships do
    has_many :fields, AshUI.Test.ResourceAuthorityFormFieldElement do
      destination_attribute(:parent_id)
    end

    has_many :inputs, AshUI.Test.ResourceAuthorityInputElement do
      destination_attribute(:parent_id)
    end

    has_many :actions_companions, AshUI.Test.ResourceAuthorityButtonElement do
      destination_attribute(:parent_id)
    end
  end

  ui_relationships do
    relationship :fields do
      kind :child
      slot :body
      placement :append
      order 0
    end

    relationship :inputs do
      kind :child
      slot :body
      placement :append
      order 1
    end

    relationship :actions_companions do
      kind :companion
      slot :actions
      placement :append
      order 2
    end
  end

  ui_element do
    type :card
    props %{title: "Interactive profile editor"}
    metadata %{id: "form_panel", section: "form", slot: "body", position: 10}
  end
end

defmodule AshUI.Test.ResourceAuthorityFormFieldElement do
  @moduledoc false

  use AshUI.Test.ResourceAuthorityElementBase

  ui_element do
    type :form_field

    props %{
      label: "Display name",
      name: "display_name",
      help: "Bound directly by the owning input element"
    }

    metadata %{id: "profile_field", section: "form", slot: "body", position: 0}
  end
end

defmodule AshUI.Test.ResourceAuthorityInputElement do
  @moduledoc false

  use AshUI.Test.ResourceAuthorityElementBase

  ui_element do
    type :input

    props %{
      name: "display_name",
      label: "Display name",
      placeholder: "Enter your name",
      type: "text"
    }

    metadata %{id: "display_name_input", section: "form", slot: "body", position: 1}
  end

  ui_bindings do
    binding :display_name_input do
      source %{resource: "Demo.User", field: "name", id: "user-1"}
      target "display_name"
      binding_type :value
      transform %{}
      metadata %{owner: "input"}
    end
  end
end

defmodule AshUI.Test.ResourceAuthorityButtonElement do
  @moduledoc false

  use AshUI.Test.ResourceAuthorityElementBase

  ui_element do
    type :button
    props %{label: "Save profile"}
    variants [:primary]
    metadata %{id: "save_profile_button", section: "form", slot: "actions", position: 2}
  end

  ui_actions do
    action :save_profile do
      signal :click
      source %{resource: "Demo.Profile", action: "save_profile", id: "user-1"}
      target "submit"

      transform %{
        params: %{
          display_name: %{"from" => "binding", "key" => "display_name"}
        }
      }

      metadata %{intent: "save_profile"}
    end
  end
end

defmodule AshUI.Test.ResourceAuthorityScreen do
  @moduledoc false

  use Ash.Resource,
    domain: AshUI.Test.ResourceAuthorityDomain,
    data_layer: Ash.DataLayer.Ets

  use AshUI.Resource.DSL.Screen

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read])
  end

  relationships do
    has_many :hero_elements, AshUI.Test.ResourceAuthorityHeroElement do
      destination_attribute(:screen_id)
    end

    has_many :form_panels, AshUI.Test.ResourceAuthorityFormPanelElement do
      destination_attribute(:screen_id)
    end
  end

  ui_relationships do
    relationship :hero_elements do
      kind :child
      slot :body
      placement :append
      order 0
    end

    relationship :form_panels do
      kind :child
      slot :body
      placement :append
      order 10
    end
  end

  ui_screen do
    layout :column
    route "/resource-authority"
    metadata %{title: "Resource Authority Screen", priority: 14}

    inline_fragment %{
      type: "column",
      props: %{spacing: 16},
      children: [
        %{
          type: "text",
          props: %{content: "Inline screen chrome"},
          children: [],
          signals: [],
          metadata: %{id: "screen_banner", source: "screen"}
        }
      ],
      signals: [],
      metadata: %{id: "screen_shell", source: "screen"}
    }
  end

  ui_screen_bindings do
    binding :screen_notice do
      source %{resource: "Demo.Page", field: "notice", id: "page-1"}
      target "flash.notice"
      binding_type :value
      transform %{default: "ready"}
      metadata %{scope: "screen"}
    end
  end
end

defmodule AshUI.Test.RelationshipSemanticsBadgeElement do
  @moduledoc false

  use AshUI.Test.ResourceAuthorityElementBase

  ui_element do
    type :badge
    props %{label: "Leading"}
    metadata %{id: "leading_badge", slot: "header", position: 0}
  end
end

defmodule AshUI.Test.RelationshipSemanticsPanelElement do
  @moduledoc false

  use AshUI.Test.ResourceAuthorityElementBase

  ui_element do
    type :card
    props %{title: "Body panel"}
    metadata %{id: "body_panel", slot: "body", position: 10}
  end
end

defmodule AshUI.Test.RelationshipSemanticsBaseScreen do
  @moduledoc false

  defmacro __using__(opts) do
    inline_fragment = Keyword.get(opts, :inline_fragment)

    quote do
      use Ash.Resource,
        domain: AshUI.Test.ResourceAuthorityDomain,
        data_layer: Ash.DataLayer.Ets

      use AshUI.Resource.DSL.Screen

      ets do
        private?(true)
      end

      attributes do
        uuid_primary_key(:id)
      end

      actions do
        defaults([:read])
      end

      relationships do
        has_many :leading_badges, AshUI.Test.RelationshipSemanticsBadgeElement do
          destination_attribute(:screen_id)
        end

        has_many :body_panels, AshUI.Test.RelationshipSemanticsPanelElement do
          destination_attribute(:screen_id)
        end
      end

      ui_relationships do
        relationship :leading_badges do
          kind :companion
          slot :header
          placement :prepend
          order 0
        end

        relationship :body_panels do
          kind :child
          slot :body
          placement :append
          order 10
        end
      end

      ui_screen do
        layout :column
        route "/relationship-semantics"
        metadata %{title: "Relationship Semantics", audience: "tests"}
        inline_fragment unquote(inline_fragment)
      end

      ui_screen_bindings do
        binding :screen_title do
          source %{resource: "Demo.Page", field: "title", id: "screen-1"}
          target "title"
          binding_type :value
          transform %{default: "Relationship Semantics"}
          metadata %{scope: "screen"}
        end
      end
    end
  end
end

defmodule AshUI.Test.RelationshipOnlyScreen do
  @moduledoc false

  use AshUI.Test.RelationshipSemanticsBaseScreen
end

defmodule AshUI.Test.RelationshipMixedScreen do
  @moduledoc false

  use AshUI.Test.RelationshipSemanticsBaseScreen,
    inline_fragment: %{
      type: "column",
      props: %{spacing: 8},
      children: [
        %{
          type: "text",
          props: %{content: "Mixed shell"},
          children: [],
          signals: [],
          metadata: %{id: "mixed_shell_label", source: "screen"}
        }
      ],
      signals: [],
      metadata: %{id: "mixed_shell", source: "screen"}
    }
end

# === Repeat (per-row) composition fixtures ===
#
# These fixtures exercise the `ui_relationship ... repeat <binding_id>`
# directive. The template Element renders once per row of the resolved list
# binding at hydration time. Row-scoped value bindings (`scope: :row, field:
# "..."`) declared on the template project per-row field values onto the
# clone.

defmodule AshUI.Test.RepeatRowElement do
  @moduledoc false

  use AshUI.Test.ResourceAuthorityElementBase

  ui_element do
    type :text
    props %{content: "Row placeholder"}
    metadata %{id: "manuscript_block_template", section: "body", slot: "body", position: 0}
  end

  ui_bindings do
    binding :row_title do
      source %{scope: :row, field: "title"}
      target "content"
      binding_type :value
      transform %{}
      metadata %{owner: "row_template"}
    end
  end
end

defmodule AshUI.Test.RepeatScreen do
  @moduledoc false

  use Ash.Resource,
    domain: AshUI.Test.ResourceAuthorityDomain,
    data_layer: Ash.DataLayer.Ets

  use AshUI.Resource.DSL.Screen

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read])
  end

  relationships do
    has_many :manuscript_blocks, AshUI.Test.RepeatRowElement do
      destination_attribute(:screen_id)
    end
  end

  ui_relationships do
    relationship :manuscript_blocks do
      kind :child
      slot :body
      placement :append
      order 0
      repeat :manuscript_block_rows
    end
  end

  ui_screen do
    layout :column
    route "/repeat-fixture"
    metadata %{title: "Repeat fixture"}
  end

  ui_screen_bindings do
    binding :manuscript_block_rows do
      source %{resource: "Demo.Doc", relationship: "blocks", id: "doc-1"}
      target "screen.manuscript_block_rows"
      binding_type :list
      transform %{}
      metadata %{scope: "screen"}
    end
  end
end

# Negative-path screen: declares `repeat :nonexistent_binding` on its only
# repeat-bearing relationship but never authors that binding id. Payload
# generation must error with `:unknown_repeat_binding`.
defmodule AshUI.Test.RepeatMissingBindingScreen do
  @moduledoc false

  use Ash.Resource,
    domain: AshUI.Test.ResourceAuthorityDomain,
    data_layer: Ash.DataLayer.Ets

  use AshUI.Resource.DSL.Screen

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read])
  end

  relationships do
    has_many :rows, AshUI.Test.RepeatRowElement do
      destination_attribute(:screen_id)
    end
  end

  ui_relationships do
    relationship :rows do
      kind :child
      slot :body
      placement :append
      order 0
      repeat :nonexistent_binding
    end
  end

  ui_screen do
    layout :column
    route "/missing-binding"
    metadata %{title: "Missing binding"}
  end
end

# Negative-path screen: declares `repeat :a_value_binding` pointing at a
# `:value`-typed binding instead of a `:list` binding. Payload generation
# must error with `:invalid_repeat_binding_type`.
defmodule AshUI.Test.RepeatNonListBindingScreen do
  @moduledoc false

  use Ash.Resource,
    domain: AshUI.Test.ResourceAuthorityDomain,
    data_layer: Ash.DataLayer.Ets

  use AshUI.Resource.DSL.Screen

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read])
  end

  relationships do
    has_many :rows, AshUI.Test.RepeatRowElement do
      destination_attribute(:screen_id)
    end
  end

  ui_relationships do
    relationship :rows do
      kind :child
      slot :body
      placement :append
      order 0
      repeat :a_value_binding
    end
  end

  ui_screen do
    layout :column
    route "/non-list-binding"
    metadata %{title: "Non-list binding"}
  end

  ui_screen_bindings do
    binding :a_value_binding do
      source %{resource: "Demo.Page", field: "title", id: "page-1"}
      target "title"
      binding_type :value
      transform %{}
      metadata %{scope: "screen"}
    end
  end
end
