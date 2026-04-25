defmodule AshUIExamples.SupervisionTreeViewer do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `supervision_tree_viewer` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.LiveUIAdapter
  alias AshUI.Resource.Authority

  @directory "supervision_tree_viewer"
  @screen_name "example/supervision_tree_viewer"
  @definition %{
    directory: "supervision_tree_viewer",
    family: :operational,
    title: "Supervision Tree Viewer Example",
    story_text:
      "Meaningful Interaction Story: switch the viewed supervision snapshot and confirm the tree structure updates from persisted runtime data instead of a fixed outline.",
    signal_text:
      "Canonical Signal Preview: nested button click -> ExampleState.payload -> bound supervision tree model plus preview label.",
    preview_field: :current_value,
    seed_state: %{
      id: "state-supervision_tree_viewer",
      status: "Supervision tree viewer mounted with the worker supervision snapshot.",
      payload: %{
        "label" => "Worker supervisor",
        "meta" => "Primary",
        "nodes" => [
          %{"label" => "queue_worker", "meta" => "running"},
          %{
            "children" => [
              %{"label" => "retry_worker_a", "meta" => "running"},
              %{"label" => "retry_worker_b", "meta" => "running"}
            ],
            "label" => "retry_supervisor",
            "meta" => "running"
          }
        ]
      },
      current_value: "worker supervision"
    },
    support_notice:
      "The `supervision_tree_viewer` example remains a custom shell because operational supervision visuals are renderer-backed and example-scoped.",
    subject_children: [
      %{
        position: 0,
        type: :button,
        slot: :actions,
        key: :load_worker_supervision_tree_button,
        children: [],
        actions: [
          %{
            id: :action_load_worker_supervision_tree_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-supervision_tree_viewer",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" =>
                    "Supervision tree viewer mounted with the worker supervision snapshot."
                },
                payload: %{
                  "from" => "static",
                  "value" => %{
                    "label" => "Worker supervisor",
                    "meta" => "Primary",
                    "nodes" => [
                      %{"label" => "queue_worker", "meta" => "running"},
                      %{
                        "children" => [
                          %{"label" => "retry_worker_a", "meta" => "running"},
                          %{"label" => "retry_worker_b", "meta" => "running"}
                        ],
                        "label" => "retry_supervisor",
                        "meta" => "running"
                      }
                    ]
                  }
                },
                current_value: %{
                  "from" => "static",
                  "value" => "worker supervision"
                }
              }
            }
          }
        ],
        props: %{
          label: "Worker tree",
          class: "ashui-example-primary-cta",
          variant: "secondary"
        }
      },
      %{
        position: 10,
        type: :button,
        slot: :actions,
        key: :load_recovery_supervision_tree_button,
        children: [],
        actions: [
          %{
            id: :action_load_recovery_supervision_tree_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-supervision_tree_viewer",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" =>
                    "Supervision tree viewer switched to the recovery supervision snapshot."
                },
                payload: %{
                  "from" => "static",
                  "value" => %{
                    "label" => "Recovery supervisor",
                    "meta" => "Failover",
                    "nodes" => [
                      %{"label" => "rollback_worker", "meta" => "running"},
                      %{
                        "children" => [
                          %{"label" => "notify_slack", "meta" => "queued"},
                          %{"label" => "notify_pager", "meta" => "running"}
                        ],
                        "label" => "broadcast_supervisor",
                        "meta" => "running"
                      }
                    ]
                  }
                },
                current_value: %{
                  "from" => "static",
                  "value" => "recovery supervision"
                }
              }
            }
          }
        ],
        props: %{
          label: "Recovery tree",
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
            id: :supervision_tree_footer_binding,
            metadata: %{owner: "footer"},
            source: %{
              id: "state-supervision_tree_viewer",
              resource: "ExampleState",
              field: :status
            },
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :supervision_tree_footer,
        children: [],
        props: %{
          content: "Supervision tree viewer mounted with the worker supervision snapshot.",
          class: "ashui-example-surface-meta"
        }
      }
    ],
    section: :operational_monitoring,
    subject_action: nil,
    subject_binding: %{
      id: :supervision_tree_model,
      target: "model",
      field: :payload,
      transform: %{},
      binding_type: :value
    },
    subject_type: :"custom:supervision_tree_viewer",
    notes: "Binds one supervision tree snapshot into a hierarchical shell.",
    preview_title: "Snapshot",
    subject_props: %{
      description: "A hierarchical operational shell for supervisor and worker relationships.",
      title: "Supervision tree",
      class: "ashui-example-supervision-tree-shell"
    }
  }
  @theme_css File.read!(Path.expand("../../assets/css/app.css", __DIR__))

  def app, do: :ash_ui_example_supervision_tree_viewer
  def definition, do: @definition
  def title, do: @definition.title
  def theme_css, do: @theme_css
  def screen_name, do: @screen_name

  def ui_storage do
    [
      domain: AshUIExamples.SupervisionTreeViewer.UiStorageDomain,
      resources: [
        screen: AshUIExamples.SupervisionTreeViewer.UiScreen,
        element: AshUIExamples.SupervisionTreeViewer.UiElement,
        binding: AshUIExamples.SupervisionTreeViewer.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.SupervisionTreeViewer.RuntimeDomain]

  def admin_user,
    do: %{
      active: true,
      id: "reviewer-supervision_tree_viewer",
      name: "Example Reviewer",
      role: :admin
    }

  def operator_user,
    do: %{
      active: true,
      id: "operator-supervision_tree_viewer",
      name: "Example Operator",
      role: :operator
    }

  def read_only_user,
    do: %{
      active: true,
      id: "viewer-supervision_tree_viewer",
      name: "Example Viewer",
      role: :viewer
    }

  def current_user, do: admin_user()
  def runtime_contract, do: AshUI.Examples.Phase20.runtime_contract_for(@directory)

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
        id: "state-supervision_tree_viewer",
        status: "Supervision tree viewer mounted with the worker supervision snapshot.",
        payload: %{
          "label" => "Worker supervisor",
          "meta" => "Primary",
          "nodes" => [
            %{"label" => "queue_worker", "meta" => "running"},
            %{
              "children" => [
                %{"label" => "retry_worker_a", "meta" => "running"},
                %{"label" => "retry_worker_b", "meta" => "running"}
              ],
              "label" => "retry_supervisor",
              "meta" => "running"
            }
          ]
        },
        current_value: "worker supervision"
      }
    )
  end

  def reset! do
    reset_resource!(
      AshUIExamples.SupervisionTreeViewer.Runtime.ExampleState,
      AshUIExamples.SupervisionTreeViewer.RuntimeDomain
    )

    reset_resource!(
      AshUIExamples.SupervisionTreeViewer.UiBinding,
      AshUIExamples.SupervisionTreeViewer.UiStorageDomain
    )

    reset_resource!(
      AshUIExamples.SupervisionTreeViewer.UiElement,
      AshUIExamples.SupervisionTreeViewer.UiStorageDomain
    )

    reset_resource!(
      AshUIExamples.SupervisionTreeViewer.UiScreen,
      AshUIExamples.SupervisionTreeViewer.UiStorageDomain
    )

    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.SupervisionTreeViewer.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.SupervisionTreeViewer.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.SupervisionTreeViewer.Examples.SupervisionTreeViewerScreen,
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
        {Phoenix.PubSub, name: AshUIExamples.SupervisionTreeViewer.PubSub},
        AshUIExamples.SupervisionTreeViewer.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.SupervisionTreeViewer.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    @resource_topic_prefix "ash_ui:resource:AshUIExamples:SupervisionTreeViewer:Runtime:ExampleState"

    use Ash.Resource,
      domain: AshUIExamples.SupervisionTreeViewer.RuntimeDomain,
      authorizers: [Ash.Policy.Authorizer],
      notifiers: [Ash.Notifier.PubSub],
      data_layer: Ash.DataLayer.Ets

    ets do
      private?(true)
    end

    pub_sub do
      module(AshUI.Notifications)
      prefix(@resource_topic_prefix)

      publish(:create, "changes")
      publish(:update, "changes")
      publish(:destroy, "changes")
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

    policies do
      bypass actor_attribute_equals(:role, :admin) do
        authorize_if(always())
      end

      policy action_type(:read) do
        authorize_if(actor_attribute_equals(:active, true))
      end

      policy action(:create) do
        authorize_if(actor_attribute_equals(:role, :operator))
      end

      policy action([:update, :destroy]) do
        authorize_if(actor_attribute_equals(:role, :operator))
      end
    end
  end

  defmodule UiStorageDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.SupervisionTreeViewer.UiScreen)
      resource(AshUIExamples.SupervisionTreeViewer.UiElement)
      resource(AshUIExamples.SupervisionTreeViewer.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.SupervisionTreeViewer.UiStorageDomain,
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
      has_many :elements, AshUIExamples.SupervisionTreeViewer.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.SupervisionTreeViewer.UiBinding do
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
      domain: AshUIExamples.SupervisionTreeViewer.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.SupervisionTreeViewer.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.SupervisionTreeViewer.UiBinding do
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
      domain: AshUIExamples.SupervisionTreeViewer.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.SupervisionTreeViewer.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.SupervisionTreeViewer.UiScreen do
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
      resource(AshUIExamples.SupervisionTreeViewer.Examples.SupervisionTreeViewerScreen)
      resource(AshUIExamples.SupervisionTreeViewer.Examples.SupervisionTreeViewerDemoPanelElement)
      resource(AshUIExamples.SupervisionTreeViewer.Examples.SupervisionTreeViewerSubjectElement)
      resource(AshUIExamples.SupervisionTreeViewer.Examples.SupervisionTreeViewerPreviewElement)
      resource(AshUIExamples.SupervisionTreeViewer.Examples.SupervisionTreeViewerStoryTextElement)

      resource(
        AshUIExamples.SupervisionTreeViewer.Examples.SupervisionTreeViewerSignalTextElement
      )

      resource(
        AshUIExamples.SupervisionTreeViewer.Examples.SupervisionTreeViewerSupportNoticeElement
      )

      resource(
        AshUIExamples.SupervisionTreeViewer.Examples.SupervisionTreeViewerLoadWorkerSupervisionTreeButtonElement
      )

      resource(
        AshUIExamples.SupervisionTreeViewer.Examples.SupervisionTreeViewerLoadRecoverySupervisionTreeButtonElement
      )

      resource(
        AshUIExamples.SupervisionTreeViewer.Examples.SupervisionTreeViewerSupervisionTreeFooterElement
      )
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.SupervisionTreeViewer.AuthoringDomain,
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

  defmodule Examples.SupervisionTreeViewerDemoPanelElement do
    use AshUIExamples.SupervisionTreeViewer.ExampleElementBase

    relationships do
      has_many :subjects,
               AshUIExamples.SupervisionTreeViewer.Examples.SupervisionTreeViewerSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews,
               AshUIExamples.SupervisionTreeViewer.Examples.SupervisionTreeViewerPreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices,
               AshUIExamples.SupervisionTreeViewer.Examples.SupervisionTreeViewerSupportNoticeElement do
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
      props(%{title: "Supervision Tree Viewer Example", class: "ashui-example-panel"})

      metadata(%{
        id: "example-supervision_tree_viewer-demo",
        section: "demo",
        slot: "body",
        position: 0
      })
    end
  end

  defmodule Examples.SupervisionTreeViewerSubjectElement do
    use AshUIExamples.SupervisionTreeViewer.ExampleElementBase

    relationships do
      has_many :load_worker_supervision_tree_button_elements,
               AshUIExamples.SupervisionTreeViewer.Examples.SupervisionTreeViewerLoadWorkerSupervisionTreeButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :load_recovery_supervision_tree_button_elements,
               AshUIExamples.SupervisionTreeViewer.Examples.SupervisionTreeViewerLoadRecoverySupervisionTreeButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :supervision_tree_footer_elements,
               AshUIExamples.SupervisionTreeViewer.Examples.SupervisionTreeViewerSupervisionTreeFooterElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :load_worker_supervision_tree_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(0)
      end

      relationship :load_recovery_supervision_tree_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(10)
      end

      relationship :supervision_tree_footer_elements do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:supervision_tree_viewer")

      props(%{
        description: "A hierarchical operational shell for supervisor and worker relationships.",
        title: "Supervision tree",
        class: "ashui-example-supervision-tree-shell"
      })

      metadata(%{
        id: "example-supervision_tree_viewer-subject",
        section: "demo",
        slot: "body",
        position: 1
      })
    end

    ui_bindings do
      binding :supervision_tree_model do
        source(%{resource: "ExampleState", field: :payload, id: "state-supervision_tree_viewer"})
        target("model")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "subject", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.SupervisionTreeViewerLoadWorkerSupervisionTreeButtonElement do
    use AshUIExamples.SupervisionTreeViewer.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Worker tree",
        class: "ashui-example-primary-cta",
        variant: "secondary"
      })

      metadata(%{
        id: "load-worker-supervision-tree-button",
        position: 0,
        slot: "actions",
        section: "demo"
      })
    end

    ui_actions do
      action :action_load_worker_supervision_tree_button do
        signal(:click)

        source(%{
          id: "state-supervision_tree_viewer",
          resource: "ExampleState",
          action: "update"
        })

        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Supervision tree viewer mounted with the worker supervision snapshot."
            },
            payload: %{
              "from" => "static",
              "value" => %{
                "label" => "Worker supervisor",
                "meta" => "Primary",
                "nodes" => [
                  %{"label" => "queue_worker", "meta" => "running"},
                  %{
                    "children" => [
                      %{"label" => "retry_worker_a", "meta" => "running"},
                      %{"label" => "retry_worker_b", "meta" => "running"}
                    ],
                    "label" => "retry_supervisor",
                    "meta" => "running"
                  }
                ]
              }
            },
            current_value: %{"from" => "static", "value" => "worker supervision"}
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.SupervisionTreeViewerLoadRecoverySupervisionTreeButtonElement do
    use AshUIExamples.SupervisionTreeViewer.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Recovery tree",
        class: "ashui-example-secondary-cta",
        variant: "secondary"
      })

      metadata(%{
        id: "load-recovery-supervision-tree-button",
        position: 10,
        slot: "actions",
        section: "demo"
      })
    end

    ui_actions do
      action :action_load_recovery_supervision_tree_button do
        signal(:click)

        source(%{
          id: "state-supervision_tree_viewer",
          resource: "ExampleState",
          action: "update"
        })

        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Supervision tree viewer switched to the recovery supervision snapshot."
            },
            payload: %{
              "from" => "static",
              "value" => %{
                "label" => "Recovery supervisor",
                "meta" => "Failover",
                "nodes" => [
                  %{"label" => "rollback_worker", "meta" => "running"},
                  %{
                    "children" => [
                      %{"label" => "notify_slack", "meta" => "queued"},
                      %{"label" => "notify_pager", "meta" => "running"}
                    ],
                    "label" => "broadcast_supervisor",
                    "meta" => "running"
                  }
                ]
              }
            },
            current_value: %{"from" => "static", "value" => "recovery supervision"}
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.SupervisionTreeViewerSupervisionTreeFooterElement do
    use AshUIExamples.SupervisionTreeViewer.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content: "Supervision tree viewer mounted with the worker supervision snapshot.",
        class: "ashui-example-surface-meta"
      })

      metadata(%{id: "supervision-tree-footer", position: 0, slot: "footer", section: "demo"})
    end

    ui_bindings do
      binding :supervision_tree_footer_binding do
        source(%{id: "state-supervision_tree_viewer", resource: "ExampleState", field: :status})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "footer"})
      end
    end
  end

  defmodule Examples.SupervisionTreeViewerPreviewElement do
    use AshUIExamples.SupervisionTreeViewer.ExampleElementBase

    ui_element do
      type(:stat)
      props(%{title: "Snapshot", value: "worker supervision"})
      variants([:primary])

      metadata(%{
        id: "example-supervision_tree_viewer-preview",
        section: "demo",
        slot: "body",
        position: 2
      })
    end

    ui_bindings do
      binding :preview_value do
        source(%{
          resource: "ExampleState",
          field: :current_value,
          id: "state-supervision_tree_viewer"
        })

        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.SupervisionTreeViewerStoryTextElement do
    use AshUIExamples.SupervisionTreeViewer.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: switch the viewed supervision snapshot and confirm the tree structure updates from persisted runtime data instead of a fixed outline.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-supervision_tree_viewer-story",
        section: "story",
        slot: "body",
        position: 10
      })
    end
  end

  defmodule Examples.SupervisionTreeViewerSignalTextElement do
    use AshUIExamples.SupervisionTreeViewer.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: nested button click -> ExampleState.payload -> bound supervision tree model plus preview label.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-supervision_tree_viewer-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.SupervisionTreeViewerSupportNoticeElement do
    use AshUIExamples.SupervisionTreeViewer.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The `supervision_tree_viewer` example remains a custom shell because operational supervision visuals are renderer-backed and example-scoped.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{
        id: "example-supervision_tree_viewer-support-note",
        section: "demo",
        slot: "body",
        position: 3
      })
    end
  end

  defmodule Examples.SupervisionTreeViewerScreen do
    use Ash.Resource,
      domain: AshUIExamples.SupervisionTreeViewer.AuthoringDomain,
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
      has_many :demo_panels,
               AshUIExamples.SupervisionTreeViewer.Examples.SupervisionTreeViewerDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts,
               AshUIExamples.SupervisionTreeViewer.Examples.SupervisionTreeViewerStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts,
               AshUIExamples.SupervisionTreeViewer.Examples.SupervisionTreeViewerSignalTextElement do
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
        title: "Supervision Tree Viewer Example",
        example_directory: "supervision_tree_viewer",
        shell_id: "example-supervision_tree_viewer-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.SupervisionTreeViewer.seed!(opts)
    def reset!, do: AshUIExamples.SupervisionTreeViewer.reset!()
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

    scope "/", AshUIExamples.SupervisionTreeViewer.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_supervision_tree_viewer

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
    plug(AshUIExamples.SupervisionTreeViewer.Web.Router)
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

    alias AshUIExamples.SupervisionTreeViewer.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.SupervisionTreeViewer.seed!()

      socket =
        socket
        |> Phoenix.Component.assign(
          :current_user,
          AshUIExamples.SupervisionTreeViewer.current_user()
        )
        |> Phoenix.Component.assign(
          :ash_ui_storage,
          AshUIExamples.SupervisionTreeViewer.ui_storage()
        )
        |> Phoenix.Component.assign(
          :ash_ui_domains,
          AshUIExamples.SupervisionTreeViewer.runtime_domains()
        )
        |> Phoenix.Component.assign(:page_title, "Supervision Tree Viewer Example")
        |> Phoenix.Component.assign(:example_directory, "supervision_tree_viewer")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.SupervisionTreeViewer.theme_css())

      with {:ok, socket} <-
             Integration.mount_ui_screen(socket, "example/supervision_tree_viewer", params),
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
        summary={"Meaningful Interaction Story: switch the viewed supervision snapshot and confirm the tree structure updates from persisted runtime data instead of a fixed outline."}
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
        AshUIExamples.SupervisionTreeViewer.rendered_ui(socket.assigns)
      )
    end
  end
end
