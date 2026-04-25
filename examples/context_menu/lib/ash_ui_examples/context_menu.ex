defmodule AshUIExamples.ContextMenu do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `context_menu` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.LiveUIAdapter
  alias AshUI.Resource.Authority

  @directory "context_menu"
  @screen_name "example/context_menu"
  @definition %{
  directory: "context_menu",
  family: :overlay,
  title: "Context Menu Example",
  section: :overlay_layered_flows,
  subject_type: :"custom:context_menu",
  subject_props: %{
    description: "A focused action menu that opens around one review target.",
    title: "Row actions",
    class: "ashui-example-context-menu-shell"
  },
  story_text: "Meaningful Interaction Story: open the context menu, choose one action, and verify the chosen operation is reflected in persisted summary copy and preview state.",
  signal_text: "Canonical Signal Preview: nested menu button click -> ExampleState.selected_value -> context-menu summary text and footer status.",
  seed_state: %{
    enabled: true,
    id: "state-context_menu",
    status: "Context menu is focused on one record-level action set.",
    selected_value: "inspect record"
  },
  preview_field: :selected_value,
  preview_title: "Chosen action",
  subject_binding: %{
    id: :context_menu_open,
    target: "open",
    field: :enabled,
    transform: %{}
  },
  subject_action: nil,
  subject_children: [
    %{
      position: 0,
      type: :button,
      slot: :menu,
      key: :inspect_record_button,
      children: [],
      actions: [
        %{
          id: :action_inspect_record_button,
          metadata: %{
            intent: "update_example_state",
            success_message: "Layered state updated"
          },
          signal: :click,
          source: %{
            id: "state-context_menu",
            resource: "ExampleState",
            action: "update"
          },
          target: "submit",
          transform: %{
            params: %{
              status: %{
                "from" => "static",
                "value" => "Inspect record selected from the nested context menu."
              },
              selected_value: %{"from" => "static", "value" => "inspect record"}
            }
          }
        }
      ],
      props: %{
        label: "Inspect record",
        class: "ashui-example-nav-button",
        variant: "secondary"
      }
    },
    %{
      position: 10,
      type: :button,
      slot: :menu,
      key: :reassign_owner_button,
      children: [],
      actions: [
        %{
          id: :action_reassign_owner_button,
          metadata: %{
            intent: "update_example_state",
            success_message: "Layered state updated"
          },
          signal: :click,
          source: %{
            id: "state-context_menu",
            resource: "ExampleState",
            action: "update"
          },
          target: "submit",
          transform: %{
            params: %{
              status: %{
                "from" => "static",
                "value" => "Reassign owner selected from the nested context menu."
              },
              selected_value: %{"from" => "static", "value" => "reassign owner"}
            }
          }
        }
      ],
      props: %{
        label: "Reassign owner",
        class: "ashui-example-nav-button",
        variant: "secondary"
      }
    },
    %{
      position: 20,
      type: :button,
      slot: :menu,
      key: :add_watcher_button,
      children: [],
      actions: [
        %{
          id: :action_add_watcher_button,
          metadata: %{
            intent: "update_example_state",
            success_message: "Layered state updated"
          },
          signal: :click,
          source: %{
            id: "state-context_menu",
            resource: "ExampleState",
            action: "update"
          },
          target: "submit",
          transform: %{
            params: %{
              status: %{
                "from" => "static",
                "value" => "Add watcher selected from the nested context menu."
              },
              selected_value: %{"from" => "static", "value" => "add watcher"}
            }
          }
        }
      ],
      props: %{
        label: "Add watcher",
        class: "ashui-example-nav-button",
        variant: "secondary"
      }
    },
    %{
      position: 0,
      type: :text,
      slot: :body,
      bindings: [
        %{
          id: :context_menu_summary_binding,
          metadata: %{owner: "body"},
          source: %{
            id: "state-context_menu",
            resource: "ExampleState",
            field: :selected_value
          },
          target: "content",
          transform: %{},
          binding_type: :value
        }
      ],
      key: :context_menu_summary,
      children: [],
      props: %{class: "ashui-example-surface-copy", content: "inspect record"}
    },
    %{
      position: 0,
      type: :text,
      slot: :footer,
      bindings: [
        %{
          id: :context_menu_status_binding,
          metadata: %{owner: "footer"},
          source: %{
            id: "state-context_menu",
            resource: "ExampleState",
            field: :status
          },
          target: "content",
          transform: %{},
          binding_type: :value
        }
      ],
      key: :context_menu_status,
      children: [],
      props: %{
        class: "ashui-example-surface-meta",
        content: "Context menu is focused on one record-level action set."
      }
    }
  ],
  support_notice: "The context-menu shell stays explicit `custom:context_menu`; the menu items remain plain button resources with persisted action outcomes.",
  notes: "Uses menu, body, and footer slots."
}
  @theme_css File.read!(Path.expand("../../assets/css/app.css", __DIR__))

  def app, do: :ash_ui_example_context_menu
  def definition, do: @definition
  def title, do: @definition.title
  def theme_css, do: @theme_css
  def screen_name, do: @screen_name

  def ui_storage do
    [
      domain: AshUIExamples.ContextMenu.UiStorageDomain,
      resources: [
        screen: AshUIExamples.ContextMenu.UiScreen,
        element: AshUIExamples.ContextMenu.UiElement,
        binding: AshUIExamples.ContextMenu.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.ContextMenu.RuntimeDomain]

  def current_user, do: %{
  active: true,
  id: "reviewer-context_menu",
  name: "Example Reviewer",
  role: :admin
}
  def seed_state do
    Map.merge(
      %{
        id: "state-" <> @directory,
        current_value: "Ready",
        display_value: "Ready",
        status: "Mounted",
        submitted_value: "Not submitted",
        selected_value: "primary",
        checked: false,
        enabled: false,
        notes: ""
      },
%{
  enabled: true,
  id: "state-context_menu",
  status: "Context menu is focused on one record-level action set.",
  selected_value: "inspect record"
}
    )
  end

  def reset! do
    reset_resource!(AshUIExamples.ContextMenu.Runtime.ExampleState, AshUIExamples.ContextMenu.RuntimeDomain)
    reset_resource!(AshUIExamples.ContextMenu.UiBinding, AshUIExamples.ContextMenu.UiStorageDomain)
    reset_resource!(AshUIExamples.ContextMenu.UiElement, AshUIExamples.ContextMenu.UiStorageDomain)
    reset_resource!(AshUIExamples.ContextMenu.UiScreen, AshUIExamples.ContextMenu.UiStorageDomain)
    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()
    {:ok, _state} =
      Ash.create(
AshUIExamples.ContextMenu.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.ContextMenu.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
AshUIExamples.ContextMenu.Examples.ContextMenuScreen,
        actor: actor,
        name: @screen_name,
        ui_storage: ui_storage()
      )

    %{
      actor: actor,
      screen: screen,
      screen_name: @screen_name,
      ui_storage: ui_storage()
    }
  end

  def build_socket(extra_assigns \\ %{}) do
    base_assigns = %{
      __changed__: %{},
      flash: %{},
      current_user: current_user(),
      ash_ui_storage: ui_storage(),
      ash_ui_domains: runtime_domains()
    }

    %Phoenix.LiveView.Socket{assigns: Map.merge(base_assigns, extra_assigns)}
  end

  def mount_seeded!(opts \\ []) do
    seeded = seed!(opts)
    socket = build_socket(%{current_user: seeded.actor, ash_ui_storage: seeded.ui_storage, ash_ui_domains: runtime_domains()})
    {:ok, mounted_socket} = Integration.mount_ui_screen(socket, seeded.screen_name, %{})
    {:ok, mounted_socket} = EventHandler.wire_handlers(mounted_socket)
    Map.put(seeded, :socket, mounted_socket)
  end

  def rendered_ui(assigns) do
    iur =
      assigns[:ash_ui_iur] ||
        Integration.hydrate_iur(assigns[:ash_ui_base_iur], assigns[:ash_ui_bindings] || %{})

    {:ok, markup} =
      LiveUIAdapter.render(
        iur,
        bindings: Map.values(assigns[:ash_ui_bindings] || %{}),
        event_prefix: "ash_ui",
        force_fallback: true
      )

    markup
  end

  defp reset_resource!(resource, domain) do
    resource
    |> Ash.read!(domain: domain, authorize?: false)
    |> Enum.each(&Ash.destroy!(&1, domain: domain, authorize?: false))
  end

  defmodule Application do
    use Elixir.Application

    def start(_type, _args) do
      children = [
        {Phoenix.PubSub, name: AshUIExamples.ContextMenu.PubSub},
AshUIExamples.ContextMenu.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.ContextMenu.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    use Ash.Resource, domain: AshUIExamples.ContextMenu.RuntimeDomain, data_layer: Ash.DataLayer.Ets

    ets do
      private?(true)
    end

    attributes do
      attribute :id, :string do
        primary_key?(true)
        allow_nil?(false)
      end

      attribute :current_value, :string, default: "Ready"
      attribute :display_value, :string, default: "Ready"
      attribute :status, :string, default: "Mounted"
      attribute :submitted_value, :string, default: "Not submitted"
      attribute :selected_value, :string, default: "primary"
      attribute :checked, :boolean, default: false
      attribute :enabled, :boolean, default: false
      attribute :notes, :string, default: ""
    end

    actions do
      defaults([:read, :destroy])

      create :create do
        primary?(true)
        accept([:id, :current_value, :display_value, :status, :submitted_value, :selected_value, :checked, :enabled, :notes])
      end

      update :update do
        primary?(true)
        accept([:current_value, :display_value, :status, :submitted_value, :selected_value, :checked, :enabled, :notes])
      end
    end
  end

  defmodule UiStorageDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.ContextMenu.UiScreen)
      resource(AshUIExamples.ContextMenu.UiElement)
      resource(AshUIExamples.ContextMenu.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.ContextMenu.UiStorageDomain,
      authorizers: [Ash.Policy.Authorizer],
      data_layer: Ash.DataLayer.Ets

    ets do
      private?(true)
    end

    attributes do
      uuid_primary_key(:id)
      attribute(:name, :string, allow_nil?: false)
      attribute(:unified_dsl, :map, default: %{})
      attribute(:layout, :atom, default: :default)
      attribute(:route, :string)
      attribute(:metadata, :map, default: %{})
      attribute(:active, :boolean, default: true)
      attribute(:version, :integer, default: 1)
      create_timestamp(:inserted_at)
      update_timestamp(:updated_at)
    end

    relationships do
      has_many :elements, AshUIExamples.ContextMenu.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.ContextMenu.UiBinding do
        destination_attribute(:screen_id)
      end
    end

    actions do
      defaults([:read])

      read :mount do
        get?(true)

        argument :user_id, :string do
          allow_nil?(false)
        end

        argument :params, :map do
          allow_nil?(false)
          default(%{})
        end
      end

      create :create do
        primary?(true)
        accept([:name, :unified_dsl, :layout, :route, :metadata, :active, :version])
      end

      update :update do
        primary?(true)
        accept([:name, :unified_dsl, :layout, :route, :metadata, :active])
        change(increment(:version))
      end

      destroy :destroy do
        primary?(true)
      end
    end

    policies do
      bypass actor_absent() do
        authorize_if(always())
      end

      bypass actor_attribute_equals(:role, :admin) do
        authorize_if(always())
      end

      policy action([:read, :mount]) do
        authorize_if({AshUI.Authorization.Checks.ScreenAccess, mode: :read})
      end

      policy action(:create) do
        authorize_if({AshUI.Authorization.Checks.ScreenAccess, mode: :manage})
      end

      policy action([:update, :destroy]) do
        authorize_if({AshUI.Authorization.Checks.ScreenAccess, mode: :manage})
      end
    end
  end

  defmodule UiElement do
    use Ash.Resource,
      domain: AshUIExamples.ContextMenu.UiStorageDomain,
      authorizers: [Ash.Policy.Authorizer],
      data_layer: Ash.DataLayer.Ets

    ets do
      private?(true)
    end

    attributes do
      uuid_primary_key(:id)
      attribute(:type, :atom, allow_nil?: false)
      attribute(:props, :map, default: %{})
      attribute(:variants, {:array, :atom}, default: [])
      attribute(:position, :integer, default: 0)
      attribute(:metadata, :map, default: %{})
      attribute(:active, :boolean, default: true)
      attribute(:version, :integer, default: 1)
      create_timestamp(:inserted_at)
      update_timestamp(:updated_at)
    end

    relationships do
      belongs_to :screen, AshUIExamples.ContextMenu.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.ContextMenu.UiBinding do
        destination_attribute(:element_id)
      end
    end

    actions do
      defaults([:read, :destroy])

      create :create do
        primary?(true)
        accept([:type, :props, :variants, :position, :screen_id, :metadata, :active, :version])
      end

      update :update do
        primary?(true)
        accept([:type, :props, :variants, :position, :screen_id, :metadata, :active])
        change(increment(:version))
      end
    end

    policies do
      bypass actor_absent() do
        authorize_if(always())
      end

      bypass actor_attribute_equals(:role, :admin) do
        authorize_if(always())
      end

      policy action_type(:read) do
        authorize_if({AshUI.Authorization.Checks.ElementAccess, mode: :read})
      end

      policy action([:create, :update, :destroy]) do
        authorize_if({AshUI.Authorization.Checks.ElementAccess, mode: :manage})
      end
    end
  end

  defmodule UiBinding do
    use Ash.Resource,
      domain: AshUIExamples.ContextMenu.UiStorageDomain,
      authorizers: [Ash.Policy.Authorizer],
      data_layer: Ash.DataLayer.Ets

    ets do
      private?(true)
    end

    attributes do
      uuid_primary_key(:id)
      attribute(:source, :map, allow_nil?: false, default: %{})
      attribute(:target, :string, allow_nil?: false)
      attribute(:binding_type, :atom, constraints: [one_of: [:value, :list, :action]])
      attribute(:transform, :map, default: %{})
      attribute(:metadata, :map, default: %{})
      attribute(:active, :boolean, default: true)
      attribute(:version, :integer, default: 1)
      create_timestamp(:inserted_at)
      update_timestamp(:updated_at)
    end

    relationships do
      belongs_to :element, AshUIExamples.ContextMenu.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.ContextMenu.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end
    end

    actions do
      defaults([:read, :destroy])

      create :create do
        primary?(true)
        accept([:source, :target, :binding_type, :transform, :element_id, :screen_id, :metadata, :active, :version])
      end

      update :update do
        primary?(true)
        accept([:source, :target, :binding_type, :transform, :element_id, :screen_id, :metadata, :active])
        change(increment(:version))
      end
    end

    policies do
      bypass actor_absent() do
        authorize_if(always())
      end

      bypass actor_attribute_equals(:role, :admin) do
        authorize_if(always())
      end

      policy action_type(:read) do
        authorize_if({AshUI.Authorization.Checks.BindingAccess, mode: :read})
      end

      policy action([:create, :update, :destroy]) do
        authorize_if({AshUI.Authorization.Checks.BindingAccess, mode: :manage})
      end
    end
  end

  defmodule AuthoringDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do

            resource(AshUIExamples.ContextMenu.Examples.ContextMenuScreen)
            resource(AshUIExamples.ContextMenu.Examples.ContextMenuDemoPanelElement)
            resource(AshUIExamples.ContextMenu.Examples.ContextMenuSubjectElement)
            resource(AshUIExamples.ContextMenu.Examples.ContextMenuPreviewElement)
            resource(AshUIExamples.ContextMenu.Examples.ContextMenuStoryTextElement)
            resource(AshUIExamples.ContextMenu.Examples.ContextMenuSignalTextElement)
            resource(AshUIExamples.ContextMenu.Examples.ContextMenuSupportNoticeElement)
            resource(AshUIExamples.ContextMenu.Examples.ContextMenuInspectRecordButtonElement)
            resource(AshUIExamples.ContextMenu.Examples.ContextMenuReassignOwnerButtonElement)
            resource(AshUIExamples.ContextMenu.Examples.ContextMenuAddWatcherButtonElement)
            resource(AshUIExamples.ContextMenu.Examples.ContextMenuContextMenuSummaryElement)
            resource(AshUIExamples.ContextMenu.Examples.ContextMenuContextMenuStatusElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.ContextMenu.AuthoringDomain,
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

  defmodule Examples.ContextMenuDemoPanelElement do
    use AshUIExamples.ContextMenu.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.ContextMenu.Examples.ContextMenuSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.ContextMenu.Examples.ContextMenuPreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices, AshUIExamples.ContextMenu.Examples.ContextMenuSupportNoticeElement do
        destination_attribute(:parent_id)
      end

    end

    ui_relationships do
      relationship :subjects do
        kind :child
        slot :body
        placement :append
        order 0
      end

      relationship :previews do
        kind :child
        slot :body
        placement :append
        order 10
      end

      relationship :support_notices do
        kind :child
        slot :body
        placement :append
        order 20
      end

    end

    ui_element do
      type :card
      props %{title: "Context Menu Example", class: "ashui-example-panel"}
      metadata %{id: "example-context_menu-demo", section: "demo", slot: "body", position: 0}
    end
  end

  defmodule Examples.ContextMenuSubjectElement do
    use AshUIExamples.ContextMenu.ExampleElementBase

          relationships do
            has_many :inspect_record_button_elements, AshUIExamples.ContextMenu.Examples.ContextMenuInspectRecordButtonElement do
              destination_attribute(:parent_id)
            end
            
            has_many :reassign_owner_button_elements, AshUIExamples.ContextMenu.Examples.ContextMenuReassignOwnerButtonElement do
              destination_attribute(:parent_id)
            end
            
            has_many :add_watcher_button_elements, AshUIExamples.ContextMenu.Examples.ContextMenuAddWatcherButtonElement do
              destination_attribute(:parent_id)
            end
            
            has_many :context_menu_summary_elements, AshUIExamples.ContextMenu.Examples.ContextMenuContextMenuSummaryElement do
              destination_attribute(:parent_id)
            end
            
            has_many :context_menu_status_elements, AshUIExamples.ContextMenu.Examples.ContextMenuContextMenuStatusElement do
              destination_attribute(:parent_id)
            end
          end

          ui_relationships do
            relationship :inspect_record_button_elements do
              kind :child
              slot :menu
              placement :append
              order 0
            end
            
            relationship :reassign_owner_button_elements do
              kind :child
              slot :menu
              placement :append
              order 10
            end
            
            relationship :add_watcher_button_elements do
              kind :child
              slot :menu
              placement :append
              order 20
            end
            
            relationship :context_menu_summary_elements do
              kind :child
              slot :body
              placement :append
              order 0
            end
            
            relationship :context_menu_status_elements do
              kind :child
              slot :footer
              placement :append
              order 0
            end
          end
    ui_element do
      type :"custom:context_menu"
      props %{
  description: "A focused action menu that opens around one review target.",
  title: "Row actions",
  class: "ashui-example-context-menu-shell"
}
      metadata %{id: "example-context_menu-subject", section: "demo", slot: "body", position: 1}
    end

    ui_bindings do
      binding :context_menu_open do
        source %{resource: "ExampleState", field: :enabled, id: "state-context_menu"}
        target "open"
        binding_type :value
        transform %{}
        metadata %{owner: "subject", owner_signal: "change"}
      end
    end


  end

        defmodule Examples.ContextMenuInspectRecordButtonElement do
        
          use AshUIExamples.ContextMenu.ExampleElementBase
        
          ui_element do
        
            type :button
        
            props %{
          label: "Inspect record",
          class: "ashui-example-nav-button",
          variant: "secondary"
        }
        
            metadata %{id: "inspect-record-button", position: 0, slot: "menu", section: "demo"}
        
          end
        
        ui_actions do
          action :action_inspect_record_button do
            signal :click
            source %{id: "state-context_menu", resource: "ExampleState", action: "update"}
            target "submit"
            transform %{
            params: %{
              status: %{
                "from" => "static",
                "value" => "Inspect record selected from the nested context menu."
              },
              selected_value: %{"from" => "static", "value" => "inspect record"}
            }
          }
            metadata %{intent: "update_example_state", success_message: "Layered state updated"}
          end
        end
        
        end
        
        defmodule Examples.ContextMenuReassignOwnerButtonElement do
        
          use AshUIExamples.ContextMenu.ExampleElementBase
        
          ui_element do
        
            type :button
        
            props %{
          label: "Reassign owner",
          class: "ashui-example-nav-button",
          variant: "secondary"
        }
        
            metadata %{id: "reassign-owner-button", position: 10, slot: "menu", section: "demo"}
        
          end
        
        ui_actions do
          action :action_reassign_owner_button do
            signal :click
            source %{id: "state-context_menu", resource: "ExampleState", action: "update"}
            target "submit"
            transform %{
            params: %{
              status: %{
                "from" => "static",
                "value" => "Reassign owner selected from the nested context menu."
              },
              selected_value: %{"from" => "static", "value" => "reassign owner"}
            }
          }
            metadata %{intent: "update_example_state", success_message: "Layered state updated"}
          end
        end
        
        end
        
        defmodule Examples.ContextMenuAddWatcherButtonElement do
        
          use AshUIExamples.ContextMenu.ExampleElementBase
        
          ui_element do
        
            type :button
        
            props %{label: "Add watcher", class: "ashui-example-nav-button", variant: "secondary"}
        
            metadata %{id: "add-watcher-button", position: 20, slot: "menu", section: "demo"}
        
          end
        
        ui_actions do
          action :action_add_watcher_button do
            signal :click
            source %{id: "state-context_menu", resource: "ExampleState", action: "update"}
            target "submit"
            transform %{
            params: %{
              status: %{
                "from" => "static",
                "value" => "Add watcher selected from the nested context menu."
              },
              selected_value: %{"from" => "static", "value" => "add watcher"}
            }
          }
            metadata %{intent: "update_example_state", success_message: "Layered state updated"}
          end
        end
        
        end
        
        defmodule Examples.ContextMenuContextMenuSummaryElement do
        
          use AshUIExamples.ContextMenu.ExampleElementBase
        
          ui_element do
        
            type :text
        
            props %{class: "ashui-example-surface-copy", content: "inspect record"}
        
            metadata %{id: "context-menu-summary", position: 0, slot: "body", section: "demo"}
        
          end
        
        ui_bindings do
          binding :context_menu_summary_binding do
            source %{id: "state-context_menu", resource: "ExampleState", field: :selected_value}
            target "content"
            binding_type :value
            transform %{}
            metadata %{owner: "body"}
          end
        end
        
        end
        
        defmodule Examples.ContextMenuContextMenuStatusElement do
        
          use AshUIExamples.ContextMenu.ExampleElementBase
        
          ui_element do
        
            type :text
        
            props %{
          class: "ashui-example-surface-meta",
          content: "Context menu is focused on one record-level action set."
        }
        
            metadata %{id: "context-menu-status", position: 0, slot: "footer", section: "demo"}
        
          end
        
        ui_bindings do
          binding :context_menu_status_binding do
            source %{id: "state-context_menu", resource: "ExampleState", field: :status}
            target "content"
            binding_type :value
            transform %{}
            metadata %{owner: "footer"}
          end
        end
        
        end
  defmodule Examples.ContextMenuPreviewElement do
    use AshUIExamples.ContextMenu.ExampleElementBase

    ui_element do
      type :stat
      props %{title: "Chosen action", value: "inspect record"}
      variants [:primary]
      metadata %{id: "example-context_menu-preview", section: "demo", slot: "body", position: 2}
    end

    ui_bindings do
      binding :preview_value do
        source %{resource: "ExampleState", field: :selected_value, id: "state-context_menu"}
        target "value"
        binding_type :value
        transform %{}
        metadata %{owner: "preview"}
      end
    end

  end

  defmodule Examples.ContextMenuStoryTextElement do
    use AshUIExamples.ContextMenu.ExampleElementBase

    ui_element do
      type :text
      props %{content: "Meaningful Interaction Story: open the context menu, choose one action, and verify the chosen operation is reflected in persisted summary copy and preview state.", class: "ashui-example-code-surface"}
      metadata %{id: "example-context_menu-story", section: "story", slot: "body", position: 10}
    end
  end

  defmodule Examples.ContextMenuSignalTextElement do
    use AshUIExamples.ContextMenu.ExampleElementBase

    ui_element do
      type :text
      props %{content: "Canonical Signal Preview: nested menu button click -> ExampleState.selected_value -> context-menu summary text and footer status.", class: "ashui-example-code-surface"}
      metadata %{id: "example-context_menu-signal-preview", section: "signal_preview", slot: "body", position: 20}
    end
  end

  defmodule Examples.ContextMenuSupportNoticeElement do
    use AshUIExamples.ContextMenu.ExampleElementBase

    ui_element do
      type :text
      props %{content: "The context-menu shell stays explicit `custom:context_menu`; the menu items remain plain button resources with persisted action outcomes.", class: "ashui-example-focus-ring"}
      metadata %{id: "example-context_menu-support-note", section: "demo", slot: "body", position: 3}
    end
  end

  defmodule Examples.ContextMenuScreen do
    use Ash.Resource,
      domain: AshUIExamples.ContextMenu.AuthoringDomain,
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
      has_many :demo_panels, AshUIExamples.ContextMenu.Examples.ContextMenuDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUIExamples.ContextMenu.Examples.ContextMenuStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUIExamples.ContextMenu.Examples.ContextMenuSignalTextElement do
        destination_attribute(:screen_id)
      end
    end

    ui_relationships do
      relationship :demo_panels do
        kind :child
        slot :body
        placement :append
        order 0
      end

      relationship :story_texts do
        kind :child
        slot :body
        placement :append
        order 10
      end

      relationship :signal_texts do
        kind :child
        slot :body
        placement :append
        order 20
      end
    end

    ui_screen do
      layout :column
      route "/"
      metadata %{title: "Context Menu Example", example_directory: "context_menu", shell_id: "example-context_menu-shell"}
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.ContextMenu.seed!(opts)
    def reset!, do: AshUIExamples.ContextMenu.reset!()
  end

  defmodule Web.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router

    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :protect_from_forgery
      plug :put_secure_browser_headers
    end

    scope "/", AshUIExamples.ContextMenu.Web do
      pipe_through :browser
      live "/", ExampleLive
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_context_menu
    @session_options [
      store: :cookie,
      key: "_ash_ui_example_key",
      signing_salt: "ashuiph20"
    ]

    socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

    plug Plug.RequestId
    plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
    plug Plug.Session, @session_options
    plug AshUIExamples.ContextMenu.Web.Router
  end

  defmodule Web.Components.ExampleShell do
    use Phoenix.Component

    attr :title, :string, required: true
    attr :directory, :string, required: true
    attr :summary, :string, required: true
    attr :theme_css, :string, required: true
    slot :inner_block, required: true

    def example_shell(assigns) do
      ~H"""
      <style><%= Phoenix.HTML.raw(@theme_css) %></style>
      <main id={"example-#{@directory}-shell"} class="ashui-example-shell">
        <header class="ashui-example-shell-header">
          <p class="ashui-example-shell-kicker">Ash UI Example</p>
          <h1 class="ashui-example-shell-title"><%= @title %></h1>
          <p class="ashui-example-shell-summary"><%= @summary %></p>
        </header>
        <section class="ashui-example-live-surface">
          <%= render_slot(@inner_block) %>
        </section>
      </main>
      """
    end
  end

  defmodule Web.ExampleLive do
    use Phoenix.LiveView

    alias AshUIExamples.ContextMenu.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.ContextMenu.seed!()

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.ContextMenu.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.ContextMenu.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUIExamples.ContextMenu.runtime_domains())
        |> Phoenix.Component.assign(:page_title, "Context Menu Example")
        |> Phoenix.Component.assign(:example_directory, "context_menu")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.ContextMenu.theme_css())

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/context_menu", params),
           {:ok, socket} <- EventHandler.wire_handlers(socket) do
        {:ok, refresh_rendered_ui(socket)}
      else
        {:error, reason} ->
          {:ok, Phoenix.Component.assign(socket, :rendered_ui, "Mount failed: #{inspect(reason)}")}
      end
    end

    def handle_event("ash_ui_change", params, socket) do
      case EventHandler.handle_value_change(params, socket) do
        {:noreply, socket} -> {:noreply, refresh_rendered_ui(socket)}
        other -> other
      end
    end

    def handle_event("ash_ui_action", params, socket) do
      case EventHandler.handle_action_event(params, socket) do
        {:reply, payload, socket} -> {:reply, payload, refresh_rendered_ui(socket)}
        {:noreply, socket} -> {:noreply, refresh_rendered_ui(socket)}
      end
    end

    def render(assigns) do
      ~H"""
      <ExampleShell.example_shell
        title={@page_title}
        directory={@example_directory}
        summary={"Meaningful Interaction Story: open the context menu, choose one action, and verify the chosen operation is reflected in persisted summary copy and preview state."}
        theme_css={@theme_css}
      >
        <%= Phoenix.HTML.raw(@rendered_ui || "") %>
      </ExampleShell.example_shell>
      """
    end

    defp refresh_rendered_ui(socket) do
      Phoenix.Component.assign(socket, :rendered_ui, AshUIExamples.ContextMenu.rendered_ui(socket.assigns))
    end
  end
end
