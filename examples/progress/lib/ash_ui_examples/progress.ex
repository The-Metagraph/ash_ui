defmodule AshUIExamples.Progress do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `progress` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.LiveUIAdapter
  alias AshUI.Resource.Authority

  @directory "progress"
  @screen_name "example/progress"
  @definition %{
    directory: "progress",
    family: :feedback_chart,
    title: "Progress Example",
    section: :feedback_charts,
    subject_type: :"custom:progress",
    subject_props: %{
      description: "A progress surface fed by persisted rollout metrics.",
      title: "Rollout progress",
      class: "ashui-example-progress-shell"
    },
    story_text:
      "Meaningful Interaction Story: switch the rollout phase and confirm the progress surface updates both its completion amount and explanatory detail.",
    signal_text:
      "Canonical Signal Preview: nested button click -> ExampleState.metric -> bound progress model plus preview value.",
    seed_state: %{
      id: "state-progress",
      status: "Progress surface mounted with the canary rollout.",
      current_value: "42%",
      metric: %{
        "detail" => "42 percent of the planned canary traffic is live.",
        "label" => "Canary rollout",
        "total" => 100,
        "value" => 42
      }
    },
    preview_field: :current_value,
    preview_title: "Completion",
    subject_binding: %{
      id: :progress_metric,
      target: "model",
      field: :metric,
      transform: %{},
      binding_type: :value
    },
    subject_action: nil,
    subject_children: [
      %{
        position: 0,
        type: :button,
        slot: :actions,
        key: :load_canary_progress_button,
        children: [],
        actions: [
          %{
            id: :action_load_canary_progress_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-progress",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Progress surface mounted with the canary rollout."
                },
                current_value: %{"from" => "static", "value" => "42%"},
                metric: %{
                  "from" => "static",
                  "value" => %{
                    "detail" => "42 percent of the planned canary traffic is live.",
                    "label" => "Canary rollout",
                    "total" => 100,
                    "value" => 42
                  }
                }
              }
            }
          }
        ],
        props: %{
          label: "Canary phase",
          class: "ashui-example-primary-cta",
          variant: "secondary"
        }
      },
      %{
        position: 10,
        type: :button,
        slot: :actions,
        key: :load_full_progress_button,
        children: [],
        actions: [
          %{
            id: :action_load_full_progress_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-progress",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Progress surface switched to the completed rollout."
                },
                current_value: %{"from" => "static", "value" => "100%"},
                metric: %{
                  "from" => "static",
                  "value" => %{
                    "detail" => "All target regions are live and the rollout is complete.",
                    "label" => "Full rollout",
                    "total" => 100,
                    "value" => 100
                  }
                }
              }
            }
          }
        ],
        props: %{
          label: "Full rollout",
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
            id: :progress_footer_binding,
            metadata: %{owner: "footer"},
            source: %{
              id: "state-progress",
              resource: "ExampleState",
              field: :status
            },
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :progress_footer,
        children: [],
        props: %{
          class: "ashui-example-surface-meta",
          content: "Progress surface mounted with the canary rollout."
        }
      }
    ],
    support_notice:
      "The `progress` example uses a renderer-backed custom shell so completion visuals stay honest without implying a public maintained progress widget.",
    notes: "Binds one rollout metric map into the progress shell."
  }
  @theme_css File.read!(Path.expand("../../assets/css/app.css", __DIR__))

  def app, do: :ash_ui_example_progress
  def definition, do: @definition
  def title, do: @definition.title
  def theme_css, do: @theme_css
  def screen_name, do: @screen_name

  def ui_storage do
    [
      domain: AshUIExamples.Progress.UiStorageDomain,
      resources: [
        screen: AshUIExamples.Progress.UiScreen,
        element: AshUIExamples.Progress.UiElement,
        binding: AshUIExamples.Progress.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.Progress.RuntimeDomain]

  def current_user,
    do: %{active: true, id: "reviewer-progress", name: "Example Reviewer", role: :admin}

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
        id: "state-progress",
        status: "Progress surface mounted with the canary rollout.",
        current_value: "42%",
        metric: %{
          "detail" => "42 percent of the planned canary traffic is live.",
          "label" => "Canary rollout",
          "total" => 100,
          "value" => 42
        }
      }
    )
  end

  def reset! do
    reset_resource!(
      AshUIExamples.Progress.Runtime.ExampleState,
      AshUIExamples.Progress.RuntimeDomain
    )

    reset_resource!(AshUIExamples.Progress.UiBinding, AshUIExamples.Progress.UiStorageDomain)
    reset_resource!(AshUIExamples.Progress.UiElement, AshUIExamples.Progress.UiStorageDomain)
    reset_resource!(AshUIExamples.Progress.UiScreen, AshUIExamples.Progress.UiStorageDomain)
    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.Progress.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.Progress.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.Progress.Examples.ProgressScreen,
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
        {Phoenix.PubSub, name: AshUIExamples.Progress.PubSub},
        AshUIExamples.Progress.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.Progress.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    use Ash.Resource, domain: AshUIExamples.Progress.RuntimeDomain, data_layer: Ash.DataLayer.Ets

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
      resource(AshUIExamples.Progress.UiScreen)
      resource(AshUIExamples.Progress.UiElement)
      resource(AshUIExamples.Progress.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.Progress.UiStorageDomain,
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
      has_many :elements, AshUIExamples.Progress.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.Progress.UiBinding do
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
      domain: AshUIExamples.Progress.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.Progress.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.Progress.UiBinding do
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
      domain: AshUIExamples.Progress.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.Progress.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.Progress.UiScreen do
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
      resource(AshUIExamples.Progress.Examples.ProgressScreen)
      resource(AshUIExamples.Progress.Examples.ProgressDemoPanelElement)
      resource(AshUIExamples.Progress.Examples.ProgressSubjectElement)
      resource(AshUIExamples.Progress.Examples.ProgressPreviewElement)
      resource(AshUIExamples.Progress.Examples.ProgressStoryTextElement)
      resource(AshUIExamples.Progress.Examples.ProgressSignalTextElement)
      resource(AshUIExamples.Progress.Examples.ProgressSupportNoticeElement)
      resource(AshUIExamples.Progress.Examples.ProgressLoadCanaryProgressButtonElement)
      resource(AshUIExamples.Progress.Examples.ProgressLoadFullProgressButtonElement)
      resource(AshUIExamples.Progress.Examples.ProgressProgressFooterElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.Progress.AuthoringDomain,
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

  defmodule Examples.ProgressDemoPanelElement do
    use AshUIExamples.Progress.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.Progress.Examples.ProgressSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.Progress.Examples.ProgressPreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices, AshUIExamples.Progress.Examples.ProgressSupportNoticeElement do
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
      props(%{title: "Progress Example", class: "ashui-example-panel"})
      metadata(%{id: "example-progress-demo", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.ProgressSubjectElement do
    use AshUIExamples.Progress.ExampleElementBase

    relationships do
      has_many :load_canary_progress_button_elements,
               AshUIExamples.Progress.Examples.ProgressLoadCanaryProgressButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :load_full_progress_button_elements,
               AshUIExamples.Progress.Examples.ProgressLoadFullProgressButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :progress_footer_elements,
               AshUIExamples.Progress.Examples.ProgressProgressFooterElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :load_canary_progress_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(0)
      end

      relationship :load_full_progress_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(10)
      end

      relationship :progress_footer_elements do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:progress")

      props(%{
        description: "A progress surface fed by persisted rollout metrics.",
        title: "Rollout progress",
        class: "ashui-example-progress-shell"
      })

      metadata(%{id: "example-progress-subject", section: "demo", slot: "body", position: 1})
    end

    ui_bindings do
      binding :progress_metric do
        source(%{resource: "ExampleState", field: :metric, id: "state-progress"})
        target("model")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "subject", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.ProgressLoadCanaryProgressButtonElement do
    use AshUIExamples.Progress.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Canary phase",
        class: "ashui-example-primary-cta",
        variant: "secondary"
      })

      metadata(%{
        id: "load-canary-progress-button",
        position: 0,
        slot: "actions",
        section: "demo"
      })
    end

    ui_actions do
      action :action_load_canary_progress_button do
        signal(:click)
        source(%{id: "state-progress", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Progress surface mounted with the canary rollout."
            },
            current_value: %{"from" => "static", "value" => "42%"},
            metric: %{
              "from" => "static",
              "value" => %{
                "detail" => "42 percent of the planned canary traffic is live.",
                "label" => "Canary rollout",
                "total" => 100,
                "value" => 42
              }
            }
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.ProgressLoadFullProgressButtonElement do
    use AshUIExamples.Progress.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Full rollout",
        class: "ashui-example-secondary-cta",
        variant: "secondary"
      })

      metadata(%{
        id: "load-full-progress-button",
        position: 10,
        slot: "actions",
        section: "demo"
      })
    end

    ui_actions do
      action :action_load_full_progress_button do
        signal(:click)
        source(%{id: "state-progress", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Progress surface switched to the completed rollout."
            },
            current_value: %{"from" => "static", "value" => "100%"},
            metric: %{
              "from" => "static",
              "value" => %{
                "detail" => "All target regions are live and the rollout is complete.",
                "label" => "Full rollout",
                "total" => 100,
                "value" => 100
              }
            }
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.ProgressProgressFooterElement do
    use AshUIExamples.Progress.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        class: "ashui-example-surface-meta",
        content: "Progress surface mounted with the canary rollout."
      })

      metadata(%{id: "progress-footer", position: 0, slot: "footer", section: "demo"})
    end

    ui_bindings do
      binding :progress_footer_binding do
        source(%{id: "state-progress", resource: "ExampleState", field: :status})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "footer"})
      end
    end
  end

  defmodule Examples.ProgressPreviewElement do
    use AshUIExamples.Progress.ExampleElementBase

    ui_element do
      type(:stat)
      props(%{title: "Completion", value: "42%"})
      variants([:primary])
      metadata(%{id: "example-progress-preview", section: "demo", slot: "body", position: 2})
    end

    ui_bindings do
      binding :preview_value do
        source(%{resource: "ExampleState", field: :current_value, id: "state-progress"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.ProgressStoryTextElement do
    use AshUIExamples.Progress.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: switch the rollout phase and confirm the progress surface updates both its completion amount and explanatory detail.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "example-progress-story", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.ProgressSignalTextElement do
    use AshUIExamples.Progress.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: nested button click -> ExampleState.metric -> bound progress model plus preview value.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-progress-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.ProgressSupportNoticeElement do
    use AshUIExamples.Progress.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The `progress` example uses a renderer-backed custom shell so completion visuals stay honest without implying a public maintained progress widget.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{id: "example-progress-support-note", section: "demo", slot: "body", position: 3})
    end
  end

  defmodule Examples.ProgressScreen do
    use Ash.Resource,
      domain: AshUIExamples.Progress.AuthoringDomain,
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
      has_many :demo_panels, AshUIExamples.Progress.Examples.ProgressDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUIExamples.Progress.Examples.ProgressStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUIExamples.Progress.Examples.ProgressSignalTextElement do
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
        title: "Progress Example",
        example_directory: "progress",
        shell_id: "example-progress-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.Progress.seed!(opts)
    def reset!, do: AshUIExamples.Progress.reset!()
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

    scope "/", AshUIExamples.Progress.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_progress

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
    plug(AshUIExamples.Progress.Web.Router)
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

    alias AshUIExamples.Progress.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.Progress.seed!()

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.Progress.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.Progress.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUIExamples.Progress.runtime_domains())
        |> Phoenix.Component.assign(:page_title, "Progress Example")
        |> Phoenix.Component.assign(:example_directory, "progress")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.Progress.theme_css())

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/progress", params),
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
        summary={"Meaningful Interaction Story: switch the rollout phase and confirm the progress surface updates both its completion amount and explanatory detail."}
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
        AshUIExamples.Progress.rendered_ui(socket.assigns)
      )
    end
  end
end
