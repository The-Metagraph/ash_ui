defmodule AshUIExamples.Table do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `table` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.LiveUIAdapter
  alias AshUI.Resource.Authority

  @directory "table"
  @screen_name "example/table"
  @definition %{
    directory: "table",
    family: :data_surface,
    title: "Table Example",
    section: :data_surfaces,
    subject_type: :table,
    subject_props: %{
      description: "A tabular collection bound to persisted row data.",
      title: "Service handoff table",
      columns: [
        %{"key" => "service", "label" => "Service"},
        %{"key" => "owner", "label" => "Owner"},
        %{"key" => "status", "label" => "Status"}
      ],
      class: "ashui-example-table-surface"
    },
    story_text:
      "Meaningful Interaction Story: switch the active operational dataset and confirm the table rows refresh through list binding hydration instead of a one-shot render.",
    signal_text:
      "Canonical Signal Preview: nested button click -> ExampleState.items -> hydrated `table` props.items plus preview value for the active dataset.",
    seed_state: %{
      id: "state-table",
      status: "Table binding mounted with the service readiness dataset.",
      items: [
        %{"owner" => "Maya", "service" => "API gateway", "status" => "Ready"},
        %{"owner" => "Noah", "service" => "Worker pool", "status" => "Watching"},
        %{
          "owner" => "Tariq",
          "service" => "Billing sync",
          "status" => "Needs note"
        }
      ],
      current_value: "service readiness"
    },
    preview_field: :current_value,
    preview_title: "Active dataset",
    subject_binding: %{
      id: :table_items,
      target: "items",
      field: :items,
      transform: %{},
      binding_type: :list
    },
    subject_action: nil,
    subject_children: [
      %{
        position: 0,
        type: :button,
        slot: :actions,
        key: :load_service_readiness_button,
        children: [],
        actions: [
          %{
            id: :action_load_service_readiness_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-table",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Table binding mounted with the service readiness dataset."
                },
                items: %{
                  "from" => "static",
                  "value" => [
                    %{
                      "owner" => "Maya",
                      "service" => "API gateway",
                      "status" => "Ready"
                    },
                    %{
                      "owner" => "Noah",
                      "service" => "Worker pool",
                      "status" => "Watching"
                    },
                    %{
                      "owner" => "Tariq",
                      "service" => "Billing sync",
                      "status" => "Needs note"
                    }
                  ]
                },
                current_value: %{
                  "from" => "static",
                  "value" => "service readiness"
                }
              }
            }
          }
        ],
        props: %{
          label: "Service readiness",
          class: "ashui-example-primary-cta",
          variant: "secondary"
        }
      },
      %{
        position: 10,
        type: :button,
        slot: :actions,
        key: :load_handoff_board_button,
        children: [],
        actions: [
          %{
            id: :action_load_handoff_board_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-table",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Table binding switched to the handoff board dataset."
                },
                items: %{
                  "from" => "static",
                  "value" => [
                    %{
                      "owner" => "Idris",
                      "service" => "Ops notes",
                      "status" => "Shared"
                    },
                    %{
                      "owner" => "Jules",
                      "service" => "Escalations",
                      "status" => "Pending"
                    },
                    %{
                      "owner" => "Ari",
                      "service" => "Regional sync",
                      "status" => "Queued"
                    }
                  ]
                },
                current_value: %{"from" => "static", "value" => "handoff board"}
              }
            }
          }
        ],
        props: %{
          label: "Handoff board",
          class: "ashui-example-secondary-cta",
          variant: "secondary"
        }
      },
      %{
        position: 0,
        type: :text,
        slot: :footer,
        bindings: [
          %{
            id: :table_status_binding,
            metadata: %{owner: "footer"},
            source: %{id: "state-table", resource: "ExampleState", field: :status},
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :table_status,
        children: [],
        props: %{
          class: "ashui-example-surface-meta",
          content: "Table binding mounted with the service readiness dataset."
        }
      }
    ],
    support_notice:
      "The `table` example keeps its columns static but refreshes the visible row collection through bound runtime data.",
    notes: "Uses collection hydration for the maintained public `table` widget."
  }
  @theme_css File.read!(Path.expand("../../assets/css/app.css", __DIR__))

  def app, do: :ash_ui_example_table
  def definition, do: @definition
  def title, do: @definition.title
  def theme_css, do: @theme_css
  def screen_name, do: @screen_name

  def ui_storage do
    [
      domain: AshUIExamples.Table.UiStorageDomain,
      resources: [
        screen: AshUIExamples.Table.UiScreen,
        element: AshUIExamples.Table.UiElement,
        binding: AshUIExamples.Table.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.Table.RuntimeDomain]

  def current_user,
    do: %{active: true, id: "reviewer-table", name: "Example Reviewer", role: :admin}

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
        notes: "",
        items: [],
        secondary_items: [],
        metric: %{},
        payload: %{},
        series: []
      },
      %{
        id: "state-table",
        status: "Table binding mounted with the service readiness dataset.",
        items: [
          %{"owner" => "Maya", "service" => "API gateway", "status" => "Ready"},
          %{"owner" => "Noah", "service" => "Worker pool", "status" => "Watching"},
          %{"owner" => "Tariq", "service" => "Billing sync", "status" => "Needs note"}
        ],
        current_value: "service readiness"
      }
    )
  end

  def reset! do
    reset_resource!(AshUIExamples.Table.Runtime.ExampleState, AshUIExamples.Table.RuntimeDomain)
    reset_resource!(AshUIExamples.Table.UiBinding, AshUIExamples.Table.UiStorageDomain)
    reset_resource!(AshUIExamples.Table.UiElement, AshUIExamples.Table.UiStorageDomain)
    reset_resource!(AshUIExamples.Table.UiScreen, AshUIExamples.Table.UiStorageDomain)
    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.Table.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.Table.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.Table.Examples.TableScreen,
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
        {Phoenix.PubSub, name: AshUIExamples.Table.PubSub},
        AshUIExamples.Table.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.Table.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    use Ash.Resource, domain: AshUIExamples.Table.RuntimeDomain, data_layer: Ash.DataLayer.Ets

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
      attribute(:items, {:array, :map}, default: [])
      attribute(:secondary_items, {:array, :map}, default: [])
      attribute(:metric, :map, default: %{})
      attribute(:payload, :map, default: %{})
      attribute(:series, {:array, :map}, default: [])
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
          :notes,
          :items,
          :secondary_items,
          :metric,
          :payload,
          :series
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
          :notes,
          :items,
          :secondary_items,
          :metric,
          :payload,
          :series
        ])
      end
    end
  end

  defmodule UiStorageDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.Table.UiScreen)
      resource(AshUIExamples.Table.UiElement)
      resource(AshUIExamples.Table.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.Table.UiStorageDomain,
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
      has_many :elements, AshUIExamples.Table.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.Table.UiBinding do
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
      domain: AshUIExamples.Table.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.Table.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.Table.UiBinding do
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
      domain: AshUIExamples.Table.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.Table.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.Table.UiScreen do
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
      resource(AshUIExamples.Table.Examples.TableScreen)
      resource(AshUIExamples.Table.Examples.TableDemoPanelElement)
      resource(AshUIExamples.Table.Examples.TableSubjectElement)
      resource(AshUIExamples.Table.Examples.TablePreviewElement)
      resource(AshUIExamples.Table.Examples.TableStoryTextElement)
      resource(AshUIExamples.Table.Examples.TableSignalTextElement)
      resource(AshUIExamples.Table.Examples.TableSupportNoticeElement)
      resource(AshUIExamples.Table.Examples.TableLoadServiceReadinessButtonElement)
      resource(AshUIExamples.Table.Examples.TableLoadHandoffBoardButtonElement)
      resource(AshUIExamples.Table.Examples.TableTableStatusElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.Table.AuthoringDomain,
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

  defmodule Examples.TableDemoPanelElement do
    use AshUIExamples.Table.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.Table.Examples.TableSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.Table.Examples.TablePreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices, AshUIExamples.Table.Examples.TableSupportNoticeElement do
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
      props(%{title: "Table Example", class: "ashui-example-panel"})
      metadata(%{id: "example-table-demo", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.TableSubjectElement do
    use AshUIExamples.Table.ExampleElementBase

    relationships do
      has_many :load_service_readiness_button_elements,
               AshUIExamples.Table.Examples.TableLoadServiceReadinessButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :load_handoff_board_button_elements,
               AshUIExamples.Table.Examples.TableLoadHandoffBoardButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :table_status_elements, AshUIExamples.Table.Examples.TableTableStatusElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :load_service_readiness_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(0)
      end

      relationship :load_handoff_board_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(10)
      end

      relationship :table_status_elements do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:table)

      props(%{
        description: "A tabular collection bound to persisted row data.",
        title: "Service handoff table",
        columns: [
          %{"key" => "service", "label" => "Service"},
          %{"key" => "owner", "label" => "Owner"},
          %{"key" => "status", "label" => "Status"}
        ],
        class: "ashui-example-table-surface"
      })

      metadata(%{id: "example-table-subject", section: "demo", slot: "body", position: 1})
    end

    ui_bindings do
      binding :table_items do
        source(%{resource: "ExampleState", field: :items, id: "state-table"})
        target("items")
        binding_type(:list)
        transform(%{})
        metadata(%{owner: "subject", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.TableLoadServiceReadinessButtonElement do
    use AshUIExamples.Table.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Service readiness",
        class: "ashui-example-primary-cta",
        variant: "secondary"
      })

      metadata(%{
        id: "load-service-readiness-button",
        position: 0,
        slot: "actions",
        section: "demo"
      })
    end

    ui_actions do
      action :action_load_service_readiness_button do
        signal(:click)
        source(%{id: "state-table", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Table binding mounted with the service readiness dataset."
            },
            items: %{
              "from" => "static",
              "value" => [
                %{"owner" => "Maya", "service" => "API gateway", "status" => "Ready"},
                %{"owner" => "Noah", "service" => "Worker pool", "status" => "Watching"},
                %{
                  "owner" => "Tariq",
                  "service" => "Billing sync",
                  "status" => "Needs note"
                }
              ]
            },
            current_value: %{"from" => "static", "value" => "service readiness"}
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.TableLoadHandoffBoardButtonElement do
    use AshUIExamples.Table.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Handoff board",
        class: "ashui-example-secondary-cta",
        variant: "secondary"
      })

      metadata(%{
        id: "load-handoff-board-button",
        position: 10,
        slot: "actions",
        section: "demo"
      })
    end

    ui_actions do
      action :action_load_handoff_board_button do
        signal(:click)
        source(%{id: "state-table", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Table binding switched to the handoff board dataset."
            },
            items: %{
              "from" => "static",
              "value" => [
                %{"owner" => "Idris", "service" => "Ops notes", "status" => "Shared"},
                %{"owner" => "Jules", "service" => "Escalations", "status" => "Pending"},
                %{"owner" => "Ari", "service" => "Regional sync", "status" => "Queued"}
              ]
            },
            current_value: %{"from" => "static", "value" => "handoff board"}
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.TableTableStatusElement do
    use AshUIExamples.Table.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        class: "ashui-example-surface-meta",
        content: "Table binding mounted with the service readiness dataset."
      })

      metadata(%{id: "table-status", position: 0, slot: "footer", section: "demo"})
    end

    ui_bindings do
      binding :table_status_binding do
        source(%{id: "state-table", resource: "ExampleState", field: :status})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "footer"})
      end
    end
  end

  defmodule Examples.TablePreviewElement do
    use AshUIExamples.Table.ExampleElementBase

    ui_element do
      type(:stat)
      props(%{title: "Active dataset", value: "service readiness"})
      variants([:primary])
      metadata(%{id: "example-table-preview", section: "demo", slot: "body", position: 2})
    end

    ui_bindings do
      binding :preview_value do
        source(%{resource: "ExampleState", field: :current_value, id: "state-table"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.TableStoryTextElement do
    use AshUIExamples.Table.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: switch the active operational dataset and confirm the table rows refresh through list binding hydration instead of a one-shot render.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "example-table-story", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.TableSignalTextElement do
    use AshUIExamples.Table.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: nested button click -> ExampleState.items -> hydrated `table` props.items plus preview value for the active dataset.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-table-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.TableSupportNoticeElement do
    use AshUIExamples.Table.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The `table` example keeps its columns static but refreshes the visible row collection through bound runtime data.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{id: "example-table-support-note", section: "demo", slot: "body", position: 3})
    end
  end

  defmodule Examples.TableScreen do
    use Ash.Resource,
      domain: AshUIExamples.Table.AuthoringDomain,
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
      has_many :demo_panels, AshUIExamples.Table.Examples.TableDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUIExamples.Table.Examples.TableStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUIExamples.Table.Examples.TableSignalTextElement do
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
        title: "Table Example",
        example_directory: "table",
        shell_id: "example-table-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.Table.seed!(opts)
    def reset!, do: AshUIExamples.Table.reset!()
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

    scope "/", AshUIExamples.Table.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_table

    @session_options [
      store: :cookie,
      key: "_ash_ui_example_key",
      signing_salt: "ashuiph20"
    ]

    socket("/live", Phoenix.LiveView.Socket,
      websocket: [connect_info: [session: @session_options]]
    )

    plug(Plug.RequestId)
    plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])
    plug(Plug.Session, @session_options)
    plug(AshUIExamples.Table.Web.Router)
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

    alias AshUIExamples.Table.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.Table.seed!()

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.Table.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.Table.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUIExamples.Table.runtime_domains())
        |> Phoenix.Component.assign(:page_title, "Table Example")
        |> Phoenix.Component.assign(:example_directory, "table")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.Table.theme_css())

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/table", params),
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
        summary={"Meaningful Interaction Story: switch the active operational dataset and confirm the table rows refresh through list binding hydration instead of a one-shot render."}
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
        AshUIExamples.Table.rendered_ui(socket.assigns)
      )
    end
  end
end
