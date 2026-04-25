defmodule AshUIExamples.Menu do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `menu` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.LiveUIAdapter
  alias AshUI.Resource.Authority

  @directory "menu"
  @screen_name "example/menu"
  @definition %{
    directory: "menu",
    family: :navigation,
    title: "Menu Example",
    story_text:
      "Meaningful Interaction Story: select a menu item and confirm the selection state changes through nested public button resources while the outer subject remains an explicit `custom:menu` shell.",
    signal_text:
      "Canonical Signal Preview: nested button click -> ExampleState.selected_value -> menu summary text and preview stat.",
    preview_field: :selected_value,
    seed_state: %{
      id: "state-menu",
      status: "Menu selection stays local to nested public buttons.",
      selected_value: "overview"
    },
    support_notice:
      "The `menu` example remains an explicit `custom:menu` surface; selection actions stay on nested public button resources.",
    subject_children: [
      %{
        position: 0,
        type: :button,
        slot: :nav,
        key: :overview_button,
        children: [],
        actions: [
          %{
            id: :select_overview,
            metadata: %{
              intent: "select_navigation",
              success_message: "Selection updated"
            },
            signal: :click,
            source: %{
              id: "state-menu",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Overview item selected."
                },
                selected_value: %{"from" => "static", "value" => "overview"}
              }
            }
          }
        ],
        props: %{
          label: "Overview",
          class: "ashui-example-nav-button",
          variant: "secondary"
        }
      },
      %{
        position: 10,
        type: :button,
        slot: :nav,
        key: :monitoring_button,
        children: [],
        actions: [
          %{
            id: :select_monitoring,
            metadata: %{
              intent: "select_navigation",
              success_message: "Selection updated"
            },
            signal: :click,
            source: %{
              id: "state-menu",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Monitoring item selected."
                },
                selected_value: %{"from" => "static", "value" => "monitoring"}
              }
            }
          }
        ],
        props: %{
          label: "Monitoring",
          class: "ashui-example-nav-button",
          variant: "secondary"
        }
      },
      %{
        position: 20,
        type: :button,
        slot: :nav,
        key: :handoff_button,
        children: [],
        actions: [
          %{
            id: :select_handoff,
            metadata: %{
              intent: "select_navigation",
              success_message: "Selection updated"
            },
            signal: :click,
            source: %{
              id: "state-menu",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{"from" => "static", "value" => "Handoff item selected."},
                selected_value: %{"from" => "static", "value" => "handoff"}
              }
            }
          }
        ],
        props: %{
          label: "Handoff",
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
            id: :menu_selected_value,
            metadata: %{owner: "summary"},
            source: %{
              id: "state-menu",
              resource: "ExampleState",
              field: :selected_value
            },
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :menu_summary,
        children: [],
        props: %{
          content: "overview",
          class: "ashui-example-surface-copy ashui-example-menu-summary"
        }
      },
      %{
        position: 0,
        type: :text,
        slot: :footer,
        bindings: [
          %{
            id: :menu_status_copy,
            metadata: %{owner: "footer"},
            source: %{id: "state-menu", resource: "ExampleState", field: :status},
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :menu_status,
        children: [],
        props: %{
          content: "Menu selection stays local to nested public buttons.",
          class: "ashui-example-surface-meta"
        }
      }
    ],
    section: :layout_navigation,
    subject_action: nil,
    subject_binding: nil,
    subject_type: :"custom:menu",
    notes: "Uses a dedicated example-only custom shell with nested public buttons.",
    preview_title: "Selected menu item",
    subject_props: %{
      description:
        "Nested public buttons own selection changes inside an explicit custom menu shell.",
      title: "Workspace menu",
      class: "ashui-example-menu-shell"
    }
  }
  @theme_css File.read!(Path.expand("../../assets/css/app.css", __DIR__))

  def app, do: :ash_ui_example_menu
  def definition, do: @definition
  def title, do: @definition.title
  def theme_css, do: @theme_css
  def screen_name, do: @screen_name

  def ui_storage do
    [
      domain: AshUIExamples.Menu.UiStorageDomain,
      resources: [
        screen: AshUIExamples.Menu.UiScreen,
        element: AshUIExamples.Menu.UiElement,
        binding: AshUIExamples.Menu.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.Menu.RuntimeDomain]

  def current_user,
    do: %{active: true, id: "reviewer-menu", name: "Example Reviewer", role: :admin}

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
        id: "state-menu",
        status: "Menu selection stays local to nested public buttons.",
        selected_value: "overview"
      }
    )
  end

  def reset! do
    reset_resource!(AshUIExamples.Menu.Runtime.ExampleState, AshUIExamples.Menu.RuntimeDomain)
    reset_resource!(AshUIExamples.Menu.UiBinding, AshUIExamples.Menu.UiStorageDomain)
    reset_resource!(AshUIExamples.Menu.UiElement, AshUIExamples.Menu.UiStorageDomain)
    reset_resource!(AshUIExamples.Menu.UiScreen, AshUIExamples.Menu.UiStorageDomain)
    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.Menu.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.Menu.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.Menu.Examples.MenuScreen,
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

    socket =
      build_socket(%{
        current_user: seeded.actor,
        ash_ui_storage: seeded.ui_storage,
        ash_ui_domains: runtime_domains()
      })

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
        {Phoenix.PubSub, name: AshUIExamples.Menu.PubSub},
        AshUIExamples.Menu.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.Menu.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    use Ash.Resource, domain: AshUIExamples.Menu.RuntimeDomain, data_layer: Ash.DataLayer.Ets

    ets do
      private?(true)
    end

    attributes do
      attribute :id, :string do
        primary_key?(true)
        allow_nil?(false)
      end

      attribute(:current_value, :string, default: "Ready")
      attribute(:display_value, :string, default: "Ready")
      attribute(:status, :string, default: "Mounted")
      attribute(:submitted_value, :string, default: "Not submitted")
      attribute(:selected_value, :string, default: "primary")
      attribute(:checked, :boolean, default: false)
      attribute(:enabled, :boolean, default: false)
      attribute(:notes, :string, default: "")
    end

    actions do
      defaults([:read, :destroy])

      create :create do
        primary?(true)

        accept([
          :id,
          :current_value,
          :display_value,
          :status,
          :submitted_value,
          :selected_value,
          :checked,
          :enabled,
          :notes
        ])
      end

      update :update do
        primary?(true)

        accept([
          :current_value,
          :display_value,
          :status,
          :submitted_value,
          :selected_value,
          :checked,
          :enabled,
          :notes
        ])
      end
    end
  end

  defmodule UiStorageDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.Menu.UiScreen)
      resource(AshUIExamples.Menu.UiElement)
      resource(AshUIExamples.Menu.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.Menu.UiStorageDomain,
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
      has_many :elements, AshUIExamples.Menu.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.Menu.UiBinding do
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
      domain: AshUIExamples.Menu.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.Menu.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.Menu.UiBinding do
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
      domain: AshUIExamples.Menu.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.Menu.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.Menu.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end
    end

    actions do
      defaults([:read, :destroy])

      create :create do
        primary?(true)

        accept([
          :source,
          :target,
          :binding_type,
          :transform,
          :element_id,
          :screen_id,
          :metadata,
          :active,
          :version
        ])
      end

      update :update do
        primary?(true)

        accept([
          :source,
          :target,
          :binding_type,
          :transform,
          :element_id,
          :screen_id,
          :metadata,
          :active
        ])

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
      resource(AshUIExamples.Menu.Examples.MenuScreen)
      resource(AshUIExamples.Menu.Examples.MenuDemoPanelElement)
      resource(AshUIExamples.Menu.Examples.MenuSubjectElement)
      resource(AshUIExamples.Menu.Examples.MenuPreviewElement)
      resource(AshUIExamples.Menu.Examples.MenuStoryTextElement)
      resource(AshUIExamples.Menu.Examples.MenuSignalTextElement)
      resource(AshUIExamples.Menu.Examples.MenuSupportNoticeElement)
      resource(AshUIExamples.Menu.Examples.MenuOverviewButtonElement)
      resource(AshUIExamples.Menu.Examples.MenuMonitoringButtonElement)
      resource(AshUIExamples.Menu.Examples.MenuHandoffButtonElement)
      resource(AshUIExamples.Menu.Examples.MenuMenuSummaryElement)
      resource(AshUIExamples.Menu.Examples.MenuMenuStatusElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.Menu.AuthoringDomain,
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

  defmodule Examples.MenuDemoPanelElement do
    use AshUIExamples.Menu.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.Menu.Examples.MenuSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.Menu.Examples.MenuPreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices, AshUIExamples.Menu.Examples.MenuSupportNoticeElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :subjects do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :previews do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :support_notices do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end
    end

    ui_element do
      type(:card)
      props(%{title: "Menu Example", class: "ashui-example-panel"})
      metadata(%{id: "example-menu-demo", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.MenuSubjectElement do
    use AshUIExamples.Menu.ExampleElementBase

    relationships do
      has_many :overview_button_elements, AshUIExamples.Menu.Examples.MenuOverviewButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :monitoring_button_elements,
               AshUIExamples.Menu.Examples.MenuMonitoringButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :handoff_button_elements, AshUIExamples.Menu.Examples.MenuHandoffButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :menu_summary_elements, AshUIExamples.Menu.Examples.MenuMenuSummaryElement do
        destination_attribute(:parent_id)
      end

      has_many :menu_status_elements, AshUIExamples.Menu.Examples.MenuMenuStatusElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :overview_button_elements do
        kind(:child)
        slot(:nav)
        placement(:append)
        order(0)
      end

      relationship :monitoring_button_elements do
        kind(:child)
        slot(:nav)
        placement(:append)
        order(10)
      end

      relationship :handoff_button_elements do
        kind(:child)
        slot(:nav)
        placement(:append)
        order(20)
      end

      relationship :menu_summary_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :menu_status_elements do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:menu")

      props(%{
        description:
          "Nested public buttons own selection changes inside an explicit custom menu shell.",
        title: "Workspace menu",
        class: "ashui-example-menu-shell"
      })

      metadata(%{id: "example-menu-subject", section: "demo", slot: "body", position: 1})
    end
  end

  defmodule Examples.MenuOverviewButtonElement do
    use AshUIExamples.Menu.ExampleElementBase

    ui_element do
      type(:button)

      props(%{label: "Overview", class: "ashui-example-nav-button", variant: "secondary"})

      metadata(%{id: "overview-button", position: 0, slot: "nav", section: "demo"})
    end

    ui_actions do
      action :select_overview do
        signal(:click)
        source(%{id: "state-menu", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{"from" => "static", "value" => "Overview item selected."},
            selected_value: %{"from" => "static", "value" => "overview"}
          }
        })

        metadata(%{intent: "select_navigation", success_message: "Selection updated"})
      end
    end
  end

  defmodule Examples.MenuMonitoringButtonElement do
    use AshUIExamples.Menu.ExampleElementBase

    ui_element do
      type(:button)

      props(%{label: "Monitoring", class: "ashui-example-nav-button", variant: "secondary"})

      metadata(%{id: "monitoring-button", position: 10, slot: "nav", section: "demo"})
    end

    ui_actions do
      action :select_monitoring do
        signal(:click)
        source(%{id: "state-menu", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{"from" => "static", "value" => "Monitoring item selected."},
            selected_value: %{"from" => "static", "value" => "monitoring"}
          }
        })

        metadata(%{intent: "select_navigation", success_message: "Selection updated"})
      end
    end
  end

  defmodule Examples.MenuHandoffButtonElement do
    use AshUIExamples.Menu.ExampleElementBase

    ui_element do
      type(:button)

      props(%{label: "Handoff", class: "ashui-example-nav-button", variant: "secondary"})

      metadata(%{id: "handoff-button", position: 20, slot: "nav", section: "demo"})
    end

    ui_actions do
      action :select_handoff do
        signal(:click)
        source(%{id: "state-menu", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{"from" => "static", "value" => "Handoff item selected."},
            selected_value: %{"from" => "static", "value" => "handoff"}
          }
        })

        metadata(%{intent: "select_navigation", success_message: "Selection updated"})
      end
    end
  end

  defmodule Examples.MenuMenuSummaryElement do
    use AshUIExamples.Menu.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content: "overview",
        class: "ashui-example-surface-copy ashui-example-menu-summary"
      })

      metadata(%{id: "menu-summary", position: 0, slot: "body", section: "demo"})
    end

    ui_bindings do
      binding :menu_selected_value do
        source(%{id: "state-menu", resource: "ExampleState", field: :selected_value})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "summary"})
      end
    end
  end

  defmodule Examples.MenuMenuStatusElement do
    use AshUIExamples.Menu.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content: "Menu selection stays local to nested public buttons.",
        class: "ashui-example-surface-meta"
      })

      metadata(%{id: "menu-status", position: 0, slot: "footer", section: "demo"})
    end

    ui_bindings do
      binding :menu_status_copy do
        source(%{id: "state-menu", resource: "ExampleState", field: :status})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "footer"})
      end
    end
  end

  defmodule Examples.MenuPreviewElement do
    use AshUIExamples.Menu.ExampleElementBase

    ui_element do
      type(:stat)
      props(%{title: "Selected menu item", value: "overview"})
      variants([:primary])
      metadata(%{id: "example-menu-preview", section: "demo", slot: "body", position: 2})
    end

    ui_bindings do
      binding :preview_value do
        source(%{resource: "ExampleState", field: :selected_value, id: "state-menu"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.MenuStoryTextElement do
    use AshUIExamples.Menu.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: select a menu item and confirm the selection state changes through nested public button resources while the outer subject remains an explicit `custom:menu` shell.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "example-menu-story", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.MenuSignalTextElement do
    use AshUIExamples.Menu.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: nested button click -> ExampleState.selected_value -> menu summary text and preview stat.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-menu-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.MenuSupportNoticeElement do
    use AshUIExamples.Menu.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The `menu` example remains an explicit `custom:menu` surface; selection actions stay on nested public button resources.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{id: "example-menu-support-note", section: "demo", slot: "body", position: 3})
    end
  end

  defmodule Examples.MenuScreen do
    use Ash.Resource,
      domain: AshUIExamples.Menu.AuthoringDomain,
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
      has_many :demo_panels, AshUIExamples.Menu.Examples.MenuDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUIExamples.Menu.Examples.MenuStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUIExamples.Menu.Examples.MenuSignalTextElement do
        destination_attribute(:screen_id)
      end
    end

    ui_relationships do
      relationship :demo_panels do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :story_texts do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :signal_texts do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end
    end

    ui_screen do
      layout(:column)
      route("/")

      metadata(%{
        title: "Menu Example",
        example_directory: "menu",
        shell_id: "example-menu-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.Menu.seed!(opts)
    def reset!, do: AshUIExamples.Menu.reset!()
  end

  defmodule Web.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:protect_from_forgery)
      plug(:put_secure_browser_headers)
    end

    scope "/", AshUIExamples.Menu.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_menu

    @session_options [
      store: :cookie,
      key: "_ash_ui_example_key",
      signing_salt: "ashuiph19"
    ]

    socket("/live", Phoenix.LiveView.Socket,
      websocket: [connect_info: [session: @session_options]]
    )

    plug(Plug.RequestId)
    plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])
    plug(Plug.Session, @session_options)
    plug(AshUIExamples.Menu.Web.Router)
  end

  defmodule Web.Components.ExampleShell do
    use Phoenix.Component

    attr(:title, :string, required: true)
    attr(:directory, :string, required: true)
    attr(:summary, :string, required: true)
    attr(:theme_css, :string, required: true)
    slot(:inner_block, required: true)

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

    alias AshUIExamples.Menu.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.Menu.seed!()

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.Menu.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.Menu.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUIExamples.Menu.runtime_domains())
        |> Phoenix.Component.assign(:page_title, "Menu Example")
        |> Phoenix.Component.assign(:example_directory, "menu")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.Menu.theme_css())

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/menu", params),
           {:ok, socket} <- EventHandler.wire_handlers(socket) do
        {:ok, refresh_rendered_ui(socket)}
      else
        {:error, reason} ->
          {:ok,
           Phoenix.Component.assign(socket, :rendered_ui, "Mount failed: #{inspect(reason)}")}
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
        summary={"Meaningful Interaction Story: select a menu item and confirm the selection state changes through nested public button resources while the outer subject remains an explicit `custom:menu` shell."}
        theme_css={@theme_css}
      >
        <%= Phoenix.HTML.raw(@rendered_ui || "") %>
      </ExampleShell.example_shell>
      """
    end

    defp refresh_rendered_ui(socket) do
      Phoenix.Component.assign(
        socket,
        :rendered_ui,
        AshUIExamples.Menu.rendered_ui(socket.assigns)
      )
    end
  end
end
