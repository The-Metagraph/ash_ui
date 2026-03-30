defmodule BasicDashboard.UIAuthoringDomain do
  @moduledoc false

  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource(BasicDashboard.Screen)
    resource(BasicDashboard.HeroElement)
    resource(BasicDashboard.CurrentValueStatElement)
    resource(BasicDashboard.LastActorStatElement)
    resource(BasicDashboard.RendererMetaElement)
    resource(BasicDashboard.EditorPanelElement)
    resource(BasicDashboard.EditorTitleElement)
    resource(BasicDashboard.EditorCopyElement)
    resource(BasicDashboard.DisplayNameFieldElement)
    resource(BasicDashboard.DisplayNameInputElement)
    resource(BasicDashboard.SaveProfileButtonElement)
    resource(BasicDashboard.EditorMetaListElement)
    resource(BasicDashboard.SnapshotPanelElement)
    resource(BasicDashboard.SnapshotTitleElement)
    resource(BasicDashboard.NameRowElement)
    resource(BasicDashboard.EmailRowElement)
    resource(BasicDashboard.StatusRowElement)
    resource(BasicDashboard.TeamRowElement)
    resource(BasicDashboard.ProfileNameRowElement)
    resource(BasicDashboard.ExplainerPanelElement)
    resource(BasicDashboard.ExplainerTitleElement)
    resource(BasicDashboard.ExplainerListElement)
  end
end

defmodule BasicDashboard.UIElementBase do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      use Ash.Resource,
        domain: BasicDashboard.UIAuthoringDomain,
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

defmodule BasicDashboard.HeroElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  relationships do
    has_many :preview_stats, BasicDashboard.CurrentValueStatElement do
      destination_attribute(:parent_id)
    end

    has_many :activity_stats, BasicDashboard.LastActorStatElement do
      destination_attribute(:parent_id)
    end

    has_many :preview_meta_rows, BasicDashboard.RendererMetaElement do
      destination_attribute(:parent_id)
    end
  end

  ui_relationships do
    relationship :preview_stats do
      kind :child
      slot :body
      placement :append
      order 0
    end

    relationship :activity_stats do
      kind :child
      slot :body
      placement :append
      order 1
    end

    relationship :preview_meta_rows do
      kind :companion
      slot :aside
      placement :append
      order 2
    end
  end

  ui_element do
    type :hero

    props %{
      eyebrow: "Resource-first example",
      title: "Model your dashboard. Let the runtime do the wiring.",
      message:
        "This demo is composed from Ash screen and element resources, with inline screen DSL used only for light shell chrome."
    }

    metadata %{id: "dashboard_hero", section: "hero", slot: "body", position: 0}
  end
end

defmodule BasicDashboard.CurrentValueStatElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  ui_element do
    type :stat
    props %{title: "Current value", value: "Pascal", message: "Hydrated from the current ETS user"}
    metadata %{id: "current_value_stat", section: "hero", slot: "body", position: 0}
  end

  ui_bindings do
    binding :current_value do
      source %{resource: "BasicDashboard.User", field: "name", id: "current-user"}
      target "value"
      binding_type :value
      transform %{}
      metadata %{owner: "stat"}
    end
  end
end

defmodule BasicDashboard.LastActorStatElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  ui_element do
    type :stat
    props %{title: "Last actor", value: "none yet", message: "Updated by save_profile"}
    metadata %{id: "last_actor_stat", section: "hero", slot: "body", position: 1}
  end

  ui_bindings do
    binding :last_actor do
      source %{resource: "BasicDashboard.User", field: "last_actor_id", id: "current-user"}
      target "value"
      binding_type :value
      transform %{"function" => "default", "args" => ["none yet"]}
      metadata %{owner: "stat"}
    end
  end
end

defmodule BasicDashboard.RendererMetaElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  ui_element do
    type :key_value
    props %{label: "Renderer path", value: "Ash UI -> LiveView"}
    metadata %{id: "renderer_meta", section: "hero", slot: "aside", position: 2}
  end
end

defmodule BasicDashboard.EditorPanelElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  relationships do
    has_many :heading_texts, BasicDashboard.EditorTitleElement do
      destination_attribute(:parent_id)
    end

    has_many :copy_texts, BasicDashboard.EditorCopyElement do
      destination_attribute(:parent_id)
    end

    has_many :form_fields, BasicDashboard.DisplayNameFieldElement do
      destination_attribute(:parent_id)
    end

    has_many :inputs, BasicDashboard.DisplayNameInputElement do
      destination_attribute(:parent_id)
    end

    has_many :action_buttons, BasicDashboard.SaveProfileButtonElement do
      destination_attribute(:parent_id)
    end

    has_many :meta_lists, BasicDashboard.EditorMetaListElement do
      destination_attribute(:parent_id)
    end
  end

  ui_relationships do
    relationship :heading_texts do
      kind :child
      slot :body
      placement :append
      order 0
    end

    relationship :copy_texts do
      kind :child
      slot :body
      placement :append
      order 1
    end

    relationship :form_fields do
      kind :child
      slot :body
      placement :append
      order 2
    end

    relationship :inputs do
      kind :child
      slot :body
      placement :append
      order 3
    end

    relationship :action_buttons do
      kind :companion
      slot :actions
      placement :append
      order 4
    end

    relationship :meta_lists do
      kind :companion
      slot :aside
      placement :append
      order 5
    end
  end

  ui_element do
    type :card
    props %{}
    metadata %{id: "editor_panel", section: "editor", slot: "body", position: 10}
  end
end

defmodule BasicDashboard.EditorTitleElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  ui_element do
    type :text
    props %{content: "Interactive profile editor", size: 24, weight: "600"}
    metadata %{id: "editor_title", section: "editor", slot: "body", position: 0}
  end
end

defmodule BasicDashboard.EditorCopyElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  ui_element do
    type :text

    props %{
      content:
        "Type into the bound field to update the current user immediately, then click save to persist through the save_profile Ash action."
    }

    metadata %{id: "editor_copy", section: "editor", slot: "body", position: 1}
  end
end

defmodule BasicDashboard.DisplayNameFieldElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  ui_element do
    type :form_field
    props %{label: "Display name", name: "display_name", help: "Bound directly on the input element"}
    metadata %{id: "display_name_field", section: "editor", slot: "body", position: 2}
  end
end

defmodule BasicDashboard.DisplayNameInputElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  ui_element do
    type :input
    props %{name: "display_name", label: "Display name", placeholder: "Enter your name", type: "text"}
    metadata %{id: "display_name_input", section: "editor", slot: "body", position: 3}
  end

  ui_bindings do
    binding :display_name_input do
      source %{resource: "BasicDashboard.User", field: "name", id: "current-user"}
      target "display_name"
      binding_type :value
      transform %{}
      metadata %{owner: "input"}
    end
  end
end

defmodule BasicDashboard.SaveProfileButtonElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  ui_element do
    type :button
    props %{label: "Save profile"}
    variants [:primary]
    metadata %{id: "save_profile_button", section: "editor", slot: "actions", position: 4}
  end

  ui_actions do
    action :save_profile do
      signal :click
      source %{resource: "BasicDashboard.User", action: "save_profile", id: "current-user"}
      target "submit"

      transform %{
        params: %{
          display_name: %{"from" => "binding", "key" => "display_name"},
          actor_id: %{"from" => "context", "key" => "user_id"}
        }
      }

      metadata %{intent: "save_profile"}
    end
  end
end

defmodule BasicDashboard.EditorMetaListElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  ui_element do
    type :info_list

    props %{
      items: [
        %{id: :resource, label: "Resource", value: "BasicDashboard.User"},
        %{id: :action, label: "Action", value: "save_profile"},
        %{id: :actor, label: "Actor", value: "current-user"}
      ]
    }

    metadata %{id: "editor_meta", section: "editor", slot: "aside", position: 5}
  end
end

defmodule BasicDashboard.SnapshotPanelElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  relationships do
    has_many :heading_texts, BasicDashboard.SnapshotTitleElement do
      destination_attribute(:parent_id)
    end

    has_many :summary_rows, BasicDashboard.NameRowElement do
      destination_attribute(:parent_id)
    end

    has_many :email_rows, BasicDashboard.EmailRowElement do
      destination_attribute(:parent_id)
    end

    has_many :status_rows, BasicDashboard.StatusRowElement do
      destination_attribute(:parent_id)
    end

    has_many :team_rows, BasicDashboard.TeamRowElement do
      destination_attribute(:parent_id)
    end

    has_many :profile_rows, BasicDashboard.ProfileNameRowElement do
      destination_attribute(:parent_id)
    end
  end

  ui_relationships do
    relationship :heading_texts do
      kind :child
      slot :body
      placement :append
      order 0
    end

    relationship :summary_rows do
      kind :child
      slot :body
      placement :append
      order 1
    end

    relationship :email_rows do
      kind :child
      slot :body
      placement :append
      order 2
    end

    relationship :status_rows do
      kind :child
      slot :body
      placement :append
      order 3
    end

    relationship :team_rows do
      kind :child
      slot :body
      placement :append
      order 4
    end

    relationship :profile_rows do
      kind :child
      slot :body
      placement :append
      order 5
    end
  end

  ui_element do
    type :card
    props %{}
    metadata %{id: "snapshot_panel", section: "snapshot", slot: "body", position: 20}
  end
end

defmodule BasicDashboard.SnapshotTitleElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  ui_element do
    type :text
    props %{content: "Current dashboard state", size: 20, weight: "600"}
    metadata %{id: "snapshot_title", section: "snapshot", slot: "body", position: 0}
  end
end

defmodule BasicDashboard.NameRowElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  ui_element do
    type :key_value
    props %{label: "Display name", value: "Pascal"}
    metadata %{id: "name_row", section: "snapshot", slot: "body", position: 1}
  end

  ui_bindings do
    binding :name_row do
      source %{resource: "BasicDashboard.User", field: "name", id: "current-user"}
      target "value"
      binding_type :value
      transform %{}
      metadata %{owner: "snapshot"}
    end
  end
end

defmodule BasicDashboard.EmailRowElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  ui_element do
    type :key_value
    props %{label: "Email", value: "pascal@example.com"}
    metadata %{id: "email_row", section: "snapshot", slot: "body", position: 2}
  end

  ui_bindings do
    binding :email_row do
      source %{resource: "BasicDashboard.User", field: "email", id: "current-user"}
      target "value"
      binding_type :value
      transform %{}
      metadata %{owner: "snapshot"}
    end
  end
end

defmodule BasicDashboard.StatusRowElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  ui_element do
    type :key_value
    props %{label: "Status", value: "Active"}
    metadata %{id: "status_row", section: "snapshot", slot: "body", position: 3}
  end

  ui_bindings do
    binding :status_row do
      source %{resource: "BasicDashboard.User", field: "status", id: "current-user"}
      target "value"
      binding_type :value
      transform %{}
      metadata %{owner: "snapshot"}
    end
  end
end

defmodule BasicDashboard.TeamRowElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  ui_element do
    type :key_value
    props %{label: "Team", value: "Platform"}
    metadata %{id: "team_row", section: "snapshot", slot: "body", position: 4}
  end

  ui_bindings do
    binding :team_row do
      source %{resource: "BasicDashboard.User", relationship: "profile.team", id: "current-user"}
      target "value"
      binding_type :value
      transform %{}
      metadata %{owner: "snapshot"}
    end
  end
end

defmodule BasicDashboard.ProfileNameRowElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  ui_element do
    type :key_value
    props %{label: "Profile name", value: "Operations"}
    metadata %{id: "profile_name_row", section: "snapshot", slot: "body", position: 5}
  end

  ui_bindings do
    binding :profile_name_row do
      source %{resource: "BasicDashboard.User", relationship: "profile.name", id: "current-user"}
      target "value"
      binding_type :value
      transform %{}
      metadata %{owner: "snapshot"}
    end
  end
end

defmodule BasicDashboard.ExplainerPanelElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  relationships do
    has_many :heading_texts, BasicDashboard.ExplainerTitleElement do
      destination_attribute(:parent_id)
    end

    has_many :detail_lists, BasicDashboard.ExplainerListElement do
      destination_attribute(:parent_id)
    end
  end

  ui_relationships do
    relationship :heading_texts do
      kind :child
      slot :body
      placement :append
      order 0
    end

    relationship :detail_lists do
      kind :child
      slot :body
      placement :append
      order 1
    end
  end

  ui_element do
    type :card
    props %{}
    metadata %{id: "explainer_panel", section: "explainer", slot: "body", position: 30}
  end
end

defmodule BasicDashboard.ExplainerTitleElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  ui_element do
    type :text
    props %{content: "Persisted layout + runtime bindings", size: 20, weight: "600"}
    metadata %{id: "explainer_title", section: "explainer", slot: "body", position: 0}
  end
end

defmodule BasicDashboard.ExplainerListElement do
  @moduledoc false

  use BasicDashboard.UIElementBase

  ui_element do
    type :info_list

    props %{
      items: [
        %{
          id: :real_resources,
          label: "Real Ash resources",
          value: "BasicDashboard.User and BasicDashboard.Profile live in an ETS-backed Ash domain."
        },
        %{
          id: :resource_graph,
          label: "Resource graph composition",
          value: "The dashboard is built from screen and element resource relationships, not a single inlined screen tree."
        },
        %{
          id: :runtime_reactivity,
          label: "Runtime reactivity",
          value: "Value bindings and actions stay local to their owning elements."
        }
      ]
    }

    metadata %{id: "explainer_list", section: "explainer", slot: "body", position: 1}
  end
end

defmodule BasicDashboard.Screen do
  @moduledoc false

  use Ash.Resource,
    domain: BasicDashboard.UIAuthoringDomain,
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
    has_many :hero_sections, BasicDashboard.HeroElement do
      destination_attribute(:screen_id)
    end

    has_many :editor_panels, BasicDashboard.EditorPanelElement do
      destination_attribute(:screen_id)
    end

    has_many :snapshot_panels, BasicDashboard.SnapshotPanelElement do
      destination_attribute(:screen_id)
    end

    has_many :explainer_panels, BasicDashboard.ExplainerPanelElement do
      destination_attribute(:screen_id)
    end
  end

  ui_relationships do
    relationship :hero_sections do
      kind :child
      slot :body
      placement :append
      order 0
    end

    relationship :editor_panels do
      kind :child
      slot :body
      placement :append
      order 10
    end

    relationship :snapshot_panels do
      kind :child
      slot :body
      placement :append
      order 20
    end

    relationship :explainer_panels do
      kind :child
      slot :body
      placement :append
      order 30
    end
  end

  ui_screen do
    layout :column
    route "/dashboard"
    metadata %{title: "Basic Dashboard", theme: "resource_authority"}

    inline_fragment %{
      type: "column",
      props: %{spacing: 12},
      children: [
        %{
          type: "row",
          props: %{spacing: 12},
          children: [
            %{
              type: "text",
              props: %{content: "Ash UI example", weight: "600"},
              children: [],
              signals: [],
              metadata: %{id: "screen_label", source: "screen"}
            },
            %{
              type: "badge",
              props: %{label: "Resource graph"},
              children: [],
              signals: [],
              metadata: %{id: "screen_badge", source: "screen"}
            }
          ],
          signals: [],
          metadata: %{id: "screen_top_bar", source: "screen"}
        }
      ],
      signals: [],
      metadata: %{id: "screen_shell", source: "screen"}
    }
  end
end
