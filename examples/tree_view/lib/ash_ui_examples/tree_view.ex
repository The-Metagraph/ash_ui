defmodule AshUIExamples.TreeView do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `tree_view` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.LiveUIAdapter
  alias AshUI.Resource.Authority

  @directory "tree_view"
  @screen_name "example/tree_view"
  @definition %{
    directory: "tree_view",
    family: :data_surface,
    title: "Tree View Example",
    section: :data_surfaces,
    subject_type: :"custom:tree_view",
    subject_props: %{
      description: "A nested review surface that shows hierarchical runtime structure.",
      title: "System topology",
      class: "ashui-example-tree-view-shell"
    },
    story_text:
      "Meaningful Interaction Story: switch the focused hierarchy and confirm the tree viewer redraws its nested branches from persisted runtime data rather than a static shell.",
    signal_text:
      "Canonical Signal Preview: nested button click -> ExampleState.items -> bound tree model plus selected-branch preview.",
    seed_state: %{
      id: "state-tree_view",
      status: "Tree viewer mounted with the runtime hierarchy.",
      items: [
        %{
          "children" => [
            %{"label" => "Phoenix endpoint", "meta" => "Healthy"},
            %{"label" => "Binding runtime", "meta" => "Healthy"},
            %{
              "children" => [
                %{"label" => "Action events", "meta" => "Ready"},
                %{"label" => "Value changes", "meta" => "Ready"}
              ],
              "label" => "Event pipeline",
              "meta" => "Watching"
            }
          ],
          "label" => "Runtime graph",
          "meta" => "Primary"
        }
      ],
      selected_value: "runtime graph"
    },
    preview_field: :selected_value,
    preview_title: "Focused branch",
    subject_binding: %{
      id: :tree_model,
      target: "model",
      field: :items,
      transform: %{},
      binding_type: :value
    },
    subject_action: nil,
    subject_children: [
      %{
        position: 0,
        type: :button,
        slot: :actions,
        key: :load_runtime_tree_button,
        children: [],
        actions: [
          %{
            id: :action_load_runtime_tree_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-tree_view",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Tree viewer mounted with the runtime hierarchy."
                },
                items: %{
                  "from" => "static",
                  "value" => [
                    %{
                      "children" => [
                        %{"label" => "Phoenix endpoint", "meta" => "Healthy"},
                        %{"label" => "Binding runtime", "meta" => "Healthy"},
                        %{
                          "children" => [
                            %{"label" => "Action events", "meta" => "Ready"},
                            %{"label" => "Value changes", "meta" => "Ready"}
                          ],
                          "label" => "Event pipeline",
                          "meta" => "Watching"
                        }
                      ],
                      "label" => "Runtime graph",
                      "meta" => "Primary"
                    }
                  ]
                },
                selected_value: %{"from" => "static", "value" => "runtime graph"}
              }
            }
          }
        ],
        props: %{
          label: "Runtime graph",
          class: "ashui-example-primary-cta",
          variant: "secondary"
        }
      },
      %{
        position: 10,
        type: :button,
        slot: :actions,
        key: :load_rollout_tree_button,
        children: [],
        actions: [
          %{
            id: :action_load_rollout_tree_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-tree_view",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Tree viewer switched to the rollout hierarchy."
                },
                items: %{
                  "from" => "static",
                  "value" => [
                    %{
                      "children" => [
                        %{"label" => "Canary cohort", "meta" => "12%"},
                        %{"label" => "Regional wave", "meta" => "Queued"},
                        %{
                          "children" => [
                            %{
                              "label" => "Feature flag rollback",
                              "meta" => "Ready"
                            },
                            %{"label" => "Operator broadcast", "meta" => "Ready"}
                          ],
                          "label" => "Recovery plan",
                          "meta" => "Prepared"
                        }
                      ],
                      "label" => "Rollout graph",
                      "meta" => "Primary"
                    }
                  ]
                },
                selected_value: %{"from" => "static", "value" => "rollout graph"}
              }
            }
          }
        ],
        props: %{
          label: "Rollout graph",
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
            id: :tree_status_binding,
            metadata: %{owner: "footer"},
            source: %{
              id: "state-tree_view",
              resource: "ExampleState",
              field: :status
            },
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :tree_status,
        children: [],
        props: %{
          class: "ashui-example-surface-meta",
          content: "Tree viewer mounted with the runtime hierarchy."
        }
      }
    ],
    support_notice:
      "The tree example uses an explicit custom shell because hierarchical disclosure rendering is not a maintained public fallback surface.",
    notes: "Binds one structured tree model map into the example-only renderer."
  }
  @theme_css File.read!(Path.expand("../../assets/css/app.css", __DIR__))

  def app, do: :ash_ui_example_tree_view
  def definition, do: @definition
  def title, do: @definition.title
  def theme_css, do: @theme_css
  def screen_name, do: @screen_name

  def ui_storage do
    [
      domain: AshUIExamples.TreeView.UiStorageDomain,
      resources: [
        screen: AshUIExamples.TreeView.UiScreen,
        element: AshUIExamples.TreeView.UiElement,
        binding: AshUIExamples.TreeView.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.TreeView.RuntimeDomain]

  def current_user,
    do: %{
      active: true,
      id: "reviewer-tree_view",
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
        notes: "",
        items: [],
        secondary_items: [],
        metric: %{},
        payload: %{},
        series: []
      },
      %{
        id: "state-tree_view",
        status: "Tree viewer mounted with the runtime hierarchy.",
        items: [
          %{
            "children" => [
              %{"label" => "Phoenix endpoint", "meta" => "Healthy"},
              %{"label" => "Binding runtime", "meta" => "Healthy"},
              %{
                "children" => [
                  %{"label" => "Action events", "meta" => "Ready"},
                  %{"label" => "Value changes", "meta" => "Ready"}
                ],
                "label" => "Event pipeline",
                "meta" => "Watching"
              }
            ],
            "label" => "Runtime graph",
            "meta" => "Primary"
          }
        ],
        selected_value: "runtime graph"
      }
    )
  end

  def reset! do
    reset_resource!(
      AshUIExamples.TreeView.Runtime.ExampleState,
      AshUIExamples.TreeView.RuntimeDomain
    )

    reset_resource!(AshUIExamples.TreeView.UiBinding, AshUIExamples.TreeView.UiStorageDomain)
    reset_resource!(AshUIExamples.TreeView.UiElement, AshUIExamples.TreeView.UiStorageDomain)
    reset_resource!(AshUIExamples.TreeView.UiScreen, AshUIExamples.TreeView.UiStorageDomain)
    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.TreeView.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.TreeView.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.TreeView.Examples.TreeViewScreen,
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
        {Phoenix.PubSub, name: AshUIExamples.TreeView.PubSub},
        AshUIExamples.TreeView.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.TreeView.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    use Ash.Resource, domain: AshUIExamples.TreeView.RuntimeDomain, data_layer: Ash.DataLayer.Ets

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
      resource(AshUIExamples.TreeView.UiScreen)
      resource(AshUIExamples.TreeView.UiElement)
      resource(AshUIExamples.TreeView.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.TreeView.UiStorageDomain,
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
      has_many :elements, AshUIExamples.TreeView.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.TreeView.UiBinding do
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
      domain: AshUIExamples.TreeView.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.TreeView.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.TreeView.UiBinding do
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
      domain: AshUIExamples.TreeView.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.TreeView.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.TreeView.UiScreen do
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
      resource(AshUIExamples.TreeView.Examples.TreeViewScreen)
      resource(AshUIExamples.TreeView.Examples.TreeViewDemoPanelElement)
      resource(AshUIExamples.TreeView.Examples.TreeViewSubjectElement)
      resource(AshUIExamples.TreeView.Examples.TreeViewPreviewElement)
      resource(AshUIExamples.TreeView.Examples.TreeViewStoryTextElement)
      resource(AshUIExamples.TreeView.Examples.TreeViewSignalTextElement)
      resource(AshUIExamples.TreeView.Examples.TreeViewSupportNoticeElement)
      resource(AshUIExamples.TreeView.Examples.TreeViewLoadRuntimeTreeButtonElement)
      resource(AshUIExamples.TreeView.Examples.TreeViewLoadRolloutTreeButtonElement)
      resource(AshUIExamples.TreeView.Examples.TreeViewTreeStatusElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.TreeView.AuthoringDomain,
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

  defmodule Examples.TreeViewDemoPanelElement do
    use AshUIExamples.TreeView.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.TreeView.Examples.TreeViewSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.TreeView.Examples.TreeViewPreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices, AshUIExamples.TreeView.Examples.TreeViewSupportNoticeElement do
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
      props(%{title: "Tree View Example", class: "ashui-example-panel"})
      metadata(%{id: "example-tree_view-demo", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.TreeViewSubjectElement do
    use AshUIExamples.TreeView.ExampleElementBase

    relationships do
      has_many :load_runtime_tree_button_elements,
               AshUIExamples.TreeView.Examples.TreeViewLoadRuntimeTreeButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :load_rollout_tree_button_elements,
               AshUIExamples.TreeView.Examples.TreeViewLoadRolloutTreeButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :tree_status_elements, AshUIExamples.TreeView.Examples.TreeViewTreeStatusElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :load_runtime_tree_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(0)
      end

      relationship :load_rollout_tree_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(10)
      end

      relationship :tree_status_elements do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:tree_view")

      props(%{
        description: "A nested review surface that shows hierarchical runtime structure.",
        title: "System topology",
        class: "ashui-example-tree-view-shell"
      })

      metadata(%{id: "example-tree_view-subject", section: "demo", slot: "body", position: 1})
    end

    ui_bindings do
      binding :tree_model do
        source(%{resource: "ExampleState", field: :items, id: "state-tree_view"})
        target("model")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "subject", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.TreeViewLoadRuntimeTreeButtonElement do
    use AshUIExamples.TreeView.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Runtime graph",
        class: "ashui-example-primary-cta",
        variant: "secondary"
      })

      metadata(%{id: "load-runtime-tree-button", position: 0, slot: "actions", section: "demo"})
    end

    ui_actions do
      action :action_load_runtime_tree_button do
        signal(:click)
        source(%{id: "state-tree_view", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Tree viewer mounted with the runtime hierarchy."
            },
            items: %{
              "from" => "static",
              "value" => [
                %{
                  "children" => [
                    %{"label" => "Phoenix endpoint", "meta" => "Healthy"},
                    %{"label" => "Binding runtime", "meta" => "Healthy"},
                    %{
                      "children" => [
                        %{"label" => "Action events", "meta" => "Ready"},
                        %{"label" => "Value changes", "meta" => "Ready"}
                      ],
                      "label" => "Event pipeline",
                      "meta" => "Watching"
                    }
                  ],
                  "label" => "Runtime graph",
                  "meta" => "Primary"
                }
              ]
            },
            selected_value: %{"from" => "static", "value" => "runtime graph"}
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.TreeViewLoadRolloutTreeButtonElement do
    use AshUIExamples.TreeView.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Rollout graph",
        class: "ashui-example-secondary-cta",
        variant: "secondary"
      })

      metadata(%{
        id: "load-rollout-tree-button",
        position: 10,
        slot: "actions",
        section: "demo"
      })
    end

    ui_actions do
      action :action_load_rollout_tree_button do
        signal(:click)
        source(%{id: "state-tree_view", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Tree viewer switched to the rollout hierarchy."
            },
            items: %{
              "from" => "static",
              "value" => [
                %{
                  "children" => [
                    %{"label" => "Canary cohort", "meta" => "12%"},
                    %{"label" => "Regional wave", "meta" => "Queued"},
                    %{
                      "children" => [
                        %{"label" => "Feature flag rollback", "meta" => "Ready"},
                        %{"label" => "Operator broadcast", "meta" => "Ready"}
                      ],
                      "label" => "Recovery plan",
                      "meta" => "Prepared"
                    }
                  ],
                  "label" => "Rollout graph",
                  "meta" => "Primary"
                }
              ]
            },
            selected_value: %{"from" => "static", "value" => "rollout graph"}
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.TreeViewTreeStatusElement do
    use AshUIExamples.TreeView.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        class: "ashui-example-surface-meta",
        content: "Tree viewer mounted with the runtime hierarchy."
      })

      metadata(%{id: "tree-status", position: 0, slot: "footer", section: "demo"})
    end

    ui_bindings do
      binding :tree_status_binding do
        source(%{id: "state-tree_view", resource: "ExampleState", field: :status})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "footer"})
      end
    end
  end

  defmodule Examples.TreeViewPreviewElement do
    use AshUIExamples.TreeView.ExampleElementBase

    ui_element do
      type(:stat)
      props(%{title: "Focused branch", value: "runtime graph"})
      variants([:primary])
      metadata(%{id: "example-tree_view-preview", section: "demo", slot: "body", position: 2})
    end

    ui_bindings do
      binding :preview_value do
        source(%{resource: "ExampleState", field: :selected_value, id: "state-tree_view"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.TreeViewStoryTextElement do
    use AshUIExamples.TreeView.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: switch the focused hierarchy and confirm the tree viewer redraws its nested branches from persisted runtime data rather than a static shell.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "example-tree_view-story", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.TreeViewSignalTextElement do
    use AshUIExamples.TreeView.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: nested button click -> ExampleState.items -> bound tree model plus selected-branch preview.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-tree_view-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.TreeViewSupportNoticeElement do
    use AshUIExamples.TreeView.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The tree example uses an explicit custom shell because hierarchical disclosure rendering is not a maintained public fallback surface.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{
        id: "example-tree_view-support-note",
        section: "demo",
        slot: "body",
        position: 3
      })
    end
  end

  defmodule Examples.TreeViewScreen do
    use Ash.Resource,
      domain: AshUIExamples.TreeView.AuthoringDomain,
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
      has_many :demo_panels, AshUIExamples.TreeView.Examples.TreeViewDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUIExamples.TreeView.Examples.TreeViewStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUIExamples.TreeView.Examples.TreeViewSignalTextElement do
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
        title: "Tree View Example",
        example_directory: "tree_view",
        shell_id: "example-tree_view-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.TreeView.seed!(opts)
    def reset!, do: AshUIExamples.TreeView.reset!()
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

    scope "/", AshUIExamples.TreeView.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_tree_view

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
    plug(AshUIExamples.TreeView.Web.Router)
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

    alias AshUIExamples.TreeView.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.TreeView.seed!()

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.TreeView.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.TreeView.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUIExamples.TreeView.runtime_domains())
        |> Phoenix.Component.assign(:page_title, "Tree View Example")
        |> Phoenix.Component.assign(:example_directory, "tree_view")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.TreeView.theme_css())

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/tree_view", params),
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
        summary={"Meaningful Interaction Story: switch the focused hierarchy and confirm the tree viewer redraws its nested branches from persisted runtime data rather than a static shell."}
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
        AshUIExamples.TreeView.rendered_ui(socket.assigns)
      )
    end
  end
end
