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
