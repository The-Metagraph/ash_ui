defmodule AshUIExamples.StreamWidget do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `stream_widget` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.LiveUIAdapter
  alias AshUI.Resource.Authority

  @directory "stream_widget"
  @screen_name "example/stream_widget"
  @definition %{
    directory: "stream_widget",
    family: :operational,
    title: "Stream Widget Example",
    story_text:
      "Meaningful Interaction Story: switch the active operational feed and confirm the stream surface redraws from persisted runtime entries instead of claiming an unimplemented live transport.",
    signal_text:
      "Canonical Signal Preview: nested button click -> ExampleState.items -> bound stream entries plus preview label.",
    preview_field: :current_value,
    seed_state: %{
      id: "state-stream_widget",
      status: "Stream widget mounted with the ingest feed snapshot.",
      items: [
        %{
          "label" => "ingest",
          "message" => "Batch handoff packet accepted for triage.",
          "timestamp" => "13:04:12"
        },
        %{
          "label" => "ingest",
          "message" => "Escalation queue hydration completed.",
          "timestamp" => "13:04:27"
        },
        %{
          "label" => "ingest",
          "message" => "Operator summary card published.",
          "timestamp" => "13:04:39"
        }
      ],
      current_value: "ingest stream"
    },
    support_notice:
      "The `stream_widget` example intentionally swaps persisted snapshots through nested controls; it does not claim a live subscription transport the package does not ship yet.",
    subject_children: [
      %{
        position: 0,
        type: :button,
        slot: :actions,
        key: :load_ingest_stream_widget_button,
        children: [],
        actions: [
          %{
            id: :action_load_ingest_stream_widget_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-stream_widget",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Stream widget mounted with the ingest feed snapshot."
                },
                items: %{
                  "from" => "static",
                  "value" => [
                    %{
                      "label" => "ingest",
                      "message" => "Batch handoff packet accepted for triage.",
                      "timestamp" => "13:04:12"
                    },
                    %{
                      "label" => "ingest",
                      "message" => "Escalation queue hydration completed.",
                      "timestamp" => "13:04:27"
                    },
                    %{
                      "label" => "ingest",
                      "message" => "Operator summary card published.",
                      "timestamp" => "13:04:39"
                    }
                  ]
                },
                current_value: %{"from" => "static", "value" => "ingest stream"}
              }
            }
          }
        ],
        props: %{
          label: "Ingest feed",
          class: "ashui-example-primary-cta",
          variant: "secondary"
        }
      },
      %{
        position: 10,
        type: :button,
        slot: :actions,
        key: :load_deploy_stream_widget_button,
        children: [],
        actions: [
          %{
            id: :action_load_deploy_stream_widget_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-stream_widget",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Stream widget switched to the deploy feed snapshot."
                },
                items: %{
                  "from" => "static",
                  "value" => [
                    %{
                      "label" => "deploy",
                      "message" => "Canary reached 25 percent of its target scope.",
                      "timestamp" => "13:12:01"
                    },
                    %{
                      "label" => "deploy",
                      "message" => "Regional readiness checks returned healthy.",
                      "timestamp" => "13:12:18"
                    },
                    %{
                      "label" => "deploy",
                      "message" => "Rollback plan archived with the release packet.",
                      "timestamp" => "13:12:32"
                    }
                  ]
                },
                current_value: %{"from" => "static", "value" => "deploy stream"}
              }
            }
          }
        ],
        props: %{
          label: "Deploy feed",
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
            id: :stream_widget_footer_binding,
            metadata: %{owner: "footer"},
            source: %{
              id: "state-stream_widget",
              resource: "ExampleState",
              field: :status
            },
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :stream_widget_footer,
        children: [],
        props: %{
          content: "Stream widget mounted with the ingest feed snapshot.",
          class: "ashui-example-surface-meta"
        }
      }
    ],
    section: :operational_monitoring,
    subject_action: nil,
    subject_binding: %{
      id: :stream_entries,
      target: "entries",
      field: :items,
      transform: %{},
      binding_type: :value
    },
    subject_type: :"custom:stream_widget",
    notes: "Uses representative runtime feed snapshots with explicit operator controls.",
    preview_title: "Active feed",
    subject_props: %{
      description:
        "A bounded operational feed that swaps between representative runtime streams.",
      title: "Activity stream",
      class: "ashui-example-stream-widget-shell"
    }
  }
  @theme_css File.read!(Path.expand("../../assets/css/app.css", __DIR__))

  def app, do: :ash_ui_example_stream_widget
  def definition, do: @definition
  def title, do: @definition.title
  def theme_css, do: @theme_css
  def screen_name, do: @screen_name

  def ui_storage do
    [
      domain: AshUIExamples.StreamWidget.UiStorageDomain,
      resources: [
        screen: AshUIExamples.StreamWidget.UiScreen,
        element: AshUIExamples.StreamWidget.UiElement,
        binding: AshUIExamples.StreamWidget.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.StreamWidget.RuntimeDomain]

  def admin_user,
    do: %{
      active: true,
      id: "reviewer-stream_widget",
      name: "Example Reviewer",
      role: :admin
    }

  def operator_user,
    do: %{
      active: true,
      id: "operator-stream_widget",
      name: "Example Operator",
      role: :operator
    }

  def read_only_user,
    do: %{
      active: true,
      id: "viewer-stream_widget",
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
        id: "state-stream_widget",
        status: "Stream widget mounted with the ingest feed snapshot.",
        items: [
          %{
            "label" => "ingest",
            "message" => "Batch handoff packet accepted for triage.",
            "timestamp" => "13:04:12"
          },
          %{
            "label" => "ingest",
            "message" => "Escalation queue hydration completed.",
            "timestamp" => "13:04:27"
          },
          %{
            "label" => "ingest",
            "message" => "Operator summary card published.",
            "timestamp" => "13:04:39"
          }
        ],
        current_value: "ingest stream"
      }
    )
  end

  def reset! do
    reset_resource!(
      AshUIExamples.StreamWidget.Runtime.ExampleState,
      AshUIExamples.StreamWidget.RuntimeDomain
    )

    reset_resource!(
      AshUIExamples.StreamWidget.UiBinding,
      AshUIExamples.StreamWidget.UiStorageDomain
    )

    reset_resource!(
      AshUIExamples.StreamWidget.UiElement,
      AshUIExamples.StreamWidget.UiStorageDomain
    )

    reset_resource!(
      AshUIExamples.StreamWidget.UiScreen,
      AshUIExamples.StreamWidget.UiStorageDomain
    )

    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.StreamWidget.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.StreamWidget.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.StreamWidget.Examples.StreamWidgetScreen,
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
        {Phoenix.PubSub, name: AshUIExamples.StreamWidget.PubSub},
        AshUIExamples.StreamWidget.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.StreamWidget.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    @resource_topic_prefix "ash_ui:resource:AshUIExamples:StreamWidget:Runtime:ExampleState"

    use Ash.Resource,
      domain: AshUIExamples.StreamWidget.RuntimeDomain,
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
      resource(AshUIExamples.StreamWidget.UiScreen)
      resource(AshUIExamples.StreamWidget.UiElement)
      resource(AshUIExamples.StreamWidget.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.StreamWidget.UiStorageDomain,
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
      has_many :elements, AshUIExamples.StreamWidget.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.StreamWidget.UiBinding do
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
      domain: AshUIExamples.StreamWidget.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.StreamWidget.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.StreamWidget.UiBinding do
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
      domain: AshUIExamples.StreamWidget.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.StreamWidget.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.StreamWidget.UiScreen do
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
      resource(AshUIExamples.StreamWidget.Examples.StreamWidgetScreen)
      resource(AshUIExamples.StreamWidget.Examples.StreamWidgetDemoPanelElement)
      resource(AshUIExamples.StreamWidget.Examples.StreamWidgetSubjectElement)
      resource(AshUIExamples.StreamWidget.Examples.StreamWidgetPreviewElement)
      resource(AshUIExamples.StreamWidget.Examples.StreamWidgetStoryTextElement)
      resource(AshUIExamples.StreamWidget.Examples.StreamWidgetSignalTextElement)
      resource(AshUIExamples.StreamWidget.Examples.StreamWidgetSupportNoticeElement)

      resource(
        AshUIExamples.StreamWidget.Examples.StreamWidgetLoadIngestStreamWidgetButtonElement
      )

      resource(
        AshUIExamples.StreamWidget.Examples.StreamWidgetLoadDeployStreamWidgetButtonElement
      )

      resource(AshUIExamples.StreamWidget.Examples.StreamWidgetStreamWidgetFooterElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.StreamWidget.AuthoringDomain,
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

  defmodule Examples.StreamWidgetDemoPanelElement do
    use AshUIExamples.StreamWidget.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.StreamWidget.Examples.StreamWidgetSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.StreamWidget.Examples.StreamWidgetPreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices,
               AshUIExamples.StreamWidget.Examples.StreamWidgetSupportNoticeElement do
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
      props(%{title: "Stream Widget Example", class: "ashui-example-panel"})
      metadata(%{id: "example-stream_widget-demo", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.StreamWidgetSubjectElement do
    use AshUIExamples.StreamWidget.ExampleElementBase

    relationships do
      has_many :load_ingest_stream_widget_button_elements,
               AshUIExamples.StreamWidget.Examples.StreamWidgetLoadIngestStreamWidgetButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :load_deploy_stream_widget_button_elements,
               AshUIExamples.StreamWidget.Examples.StreamWidgetLoadDeployStreamWidgetButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :stream_widget_footer_elements,
               AshUIExamples.StreamWidget.Examples.StreamWidgetStreamWidgetFooterElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :load_ingest_stream_widget_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(0)
      end

      relationship :load_deploy_stream_widget_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(10)
      end

      relationship :stream_widget_footer_elements do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:stream_widget")

      props(%{
        description:
          "A bounded operational feed that swaps between representative runtime streams.",
        title: "Activity stream",
        class: "ashui-example-stream-widget-shell"
      })

      metadata(%{id: "example-stream_widget-subject", section: "demo", slot: "body", position: 1})
    end

    ui_bindings do
      binding :stream_entries do
        source(%{resource: "ExampleState", field: :items, id: "state-stream_widget"})
        target("entries")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "subject", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.StreamWidgetLoadIngestStreamWidgetButtonElement do
    use AshUIExamples.StreamWidget.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Ingest feed",
        class: "ashui-example-primary-cta",
        variant: "secondary"
      })

      metadata(%{
        id: "load-ingest-stream-widget-button",
        position: 0,
        slot: "actions",
        section: "demo"
      })
    end

    ui_actions do
      action :action_load_ingest_stream_widget_button do
        signal(:click)
        source(%{id: "state-stream_widget", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Stream widget mounted with the ingest feed snapshot."
            },
            items: %{
              "from" => "static",
              "value" => [
                %{
                  "label" => "ingest",
                  "message" => "Batch handoff packet accepted for triage.",
                  "timestamp" => "13:04:12"
                },
                %{
                  "label" => "ingest",
                  "message" => "Escalation queue hydration completed.",
                  "timestamp" => "13:04:27"
                },
                %{
                  "label" => "ingest",
                  "message" => "Operator summary card published.",
                  "timestamp" => "13:04:39"
                }
              ]
            },
            current_value: %{"from" => "static", "value" => "ingest stream"}
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.StreamWidgetLoadDeployStreamWidgetButtonElement do
    use AshUIExamples.StreamWidget.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Deploy feed",
        class: "ashui-example-secondary-cta",
        variant: "secondary"
      })

      metadata(%{
        id: "load-deploy-stream-widget-button",
        position: 10,
        slot: "actions",
        section: "demo"
      })
    end

    ui_actions do
      action :action_load_deploy_stream_widget_button do
        signal(:click)
        source(%{id: "state-stream_widget", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Stream widget switched to the deploy feed snapshot."
            },
            items: %{
              "from" => "static",
              "value" => [
                %{
                  "label" => "deploy",
                  "message" => "Canary reached 25 percent of its target scope.",
                  "timestamp" => "13:12:01"
                },
                %{
                  "label" => "deploy",
                  "message" => "Regional readiness checks returned healthy.",
                  "timestamp" => "13:12:18"
                },
                %{
                  "label" => "deploy",
                  "message" => "Rollback plan archived with the release packet.",
                  "timestamp" => "13:12:32"
                }
              ]
            },
            current_value: %{"from" => "static", "value" => "deploy stream"}
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.StreamWidgetStreamWidgetFooterElement do
    use AshUIExamples.StreamWidget.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content: "Stream widget mounted with the ingest feed snapshot.",
        class: "ashui-example-surface-meta"
      })

      metadata(%{id: "stream-widget-footer", position: 0, slot: "footer", section: "demo"})
    end

    ui_bindings do
      binding :stream_widget_footer_binding do
        source(%{id: "state-stream_widget", resource: "ExampleState", field: :status})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "footer"})
      end
    end
  end

  defmodule Examples.StreamWidgetPreviewElement do
    use AshUIExamples.StreamWidget.ExampleElementBase

    ui_element do
      type(:stat)
      props(%{title: "Active feed", value: "ingest stream"})
      variants([:primary])
      metadata(%{id: "example-stream_widget-preview", section: "demo", slot: "body", position: 2})
    end

    ui_bindings do
      binding :preview_value do
        source(%{resource: "ExampleState", field: :current_value, id: "state-stream_widget"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.StreamWidgetStoryTextElement do
    use AshUIExamples.StreamWidget.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: switch the active operational feed and confirm the stream surface redraws from persisted runtime entries instead of claiming an unimplemented live transport.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "example-stream_widget-story", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.StreamWidgetSignalTextElement do
    use AshUIExamples.StreamWidget.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: nested button click -> ExampleState.items -> bound stream entries plus preview label.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-stream_widget-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.StreamWidgetSupportNoticeElement do
    use AshUIExamples.StreamWidget.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The `stream_widget` example intentionally swaps persisted snapshots through nested controls; it does not claim a live subscription transport the package does not ship yet.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{
        id: "example-stream_widget-support-note",
        section: "demo",
        slot: "body",
        position: 3
      })
    end
  end

  defmodule Examples.StreamWidgetScreen do
    use Ash.Resource,
      domain: AshUIExamples.StreamWidget.AuthoringDomain,
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
      has_many :demo_panels, AshUIExamples.StreamWidget.Examples.StreamWidgetDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUIExamples.StreamWidget.Examples.StreamWidgetStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUIExamples.StreamWidget.Examples.StreamWidgetSignalTextElement do
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
        title: "Stream Widget Example",
        example_directory: "stream_widget",
        shell_id: "example-stream_widget-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.StreamWidget.seed!(opts)
    def reset!, do: AshUIExamples.StreamWidget.reset!()
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

    scope "/", AshUIExamples.StreamWidget.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_stream_widget

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
    plug(AshUIExamples.StreamWidget.Web.Router)
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

    alias AshUIExamples.StreamWidget.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.StreamWidget.seed!()

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.StreamWidget.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.StreamWidget.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUIExamples.StreamWidget.runtime_domains())
        |> Phoenix.Component.assign(:page_title, "Stream Widget Example")
        |> Phoenix.Component.assign(:example_directory, "stream_widget")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.StreamWidget.theme_css())

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/stream_widget", params),
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
        summary={"Meaningful Interaction Story: switch the active operational feed and confirm the stream surface redraws from persisted runtime entries instead of claiming an unimplemented live transport."}
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
        AshUIExamples.StreamWidget.rendered_ui(socket.assigns)
      )
    end
  end
end
