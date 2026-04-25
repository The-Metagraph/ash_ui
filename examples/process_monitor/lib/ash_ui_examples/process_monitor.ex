defmodule AshUIExamples.ProcessMonitor do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `process_monitor` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.LiveUIAdapter
  alias AshUI.Resource.Authority

  @directory "process_monitor"
  @screen_name "example/process_monitor"
  @definition %{
    directory: "process_monitor",
    family: :operational,
    title: "Process Monitor Example",
    section: :operational_monitoring,
    subject_type: :"custom:process_monitor",
    subject_props: %{
      description: "A compact runtime process surface fed by one persisted model snapshot.",
      title: "Process monitor",
      class: "ashui-example-process-monitor-shell"
    },
    story_text:
      "Meaningful Interaction Story: switch the monitored process state and confirm the visible process cards update from persisted runtime data rather than decorative placeholders.",
    signal_text:
      "Canonical Signal Preview: nested button click -> ExampleState.payload -> bound process monitor model plus preview label.",
    seed_state: %{
      id: "state-process_monitor",
      status: "Process monitor mounted with the steady-state snapshot.",
      current_value: "steady state",
      payload: %{
        "processes" => [
          %{"meta" => "0 restarts", "name" => "scheduler", "state" => "running"},
          %{"meta" => "1 restart", "name" => "queue_worker", "state" => "running"},
          %{
            "meta" => "0 restarts",
            "name" => "binding_refresher",
            "state" => "idle"
          }
        ],
        "summary" => "Schedulers and workers are healthy with no restart pressure."
      }
    },
    preview_field: :current_value,
    preview_title: "Monitor mode",
    subject_binding: %{
      id: :process_monitor_model,
      target: "model",
      field: :payload,
      transform: %{},
      binding_type: :value
    },
    subject_action: nil,
    subject_children: [
      %{
        position: 0,
        type: :button,
        slot: :actions,
        key: :load_steady_process_monitor_button,
        children: [],
        actions: [
          %{
            id: :action_load_steady_process_monitor_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-process_monitor",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Process monitor mounted with the steady-state snapshot."
                },
                current_value: %{"from" => "static", "value" => "steady state"},
                payload: %{
                  "from" => "static",
                  "value" => %{
                    "processes" => [
                      %{
                        "meta" => "0 restarts",
                        "name" => "scheduler",
                        "state" => "running"
                      },
                      %{
                        "meta" => "1 restart",
                        "name" => "queue_worker",
                        "state" => "running"
                      },
                      %{
                        "meta" => "0 restarts",
                        "name" => "binding_refresher",
                        "state" => "idle"
                      }
                    ],
                    "summary" => "Schedulers and workers are healthy with no restart pressure."
                  }
                }
              }
            }
          }
        ],
        props: %{
          label: "Steady state",
          class: "ashui-example-primary-cta",
          variant: "secondary"
        }
      },
      %{
        position: 10,
        type: :button,
        slot: :actions,
        key: :load_pressure_process_monitor_button,
        children: [],
        actions: [
          %{
            id: :action_load_pressure_process_monitor_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-process_monitor",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Process monitor switched to the restart-pressure snapshot."
                },
                current_value: %{"from" => "static", "value" => "pressure state"},
                payload: %{
                  "from" => "static",
                  "value" => %{
                    "processes" => [
                      %{
                        "meta" => "0 restarts",
                        "name" => "scheduler",
                        "state" => "running"
                      },
                      %{
                        "meta" => "4 restarts",
                        "name" => "queue_worker",
                        "state" => "degraded"
                      },
                      %{
                        "meta" => "2 restarts",
                        "name" => "binding_refresher",
                        "state" => "running"
                      }
                    ],
                    "summary" =>
                      "Retry workers are degraded and the refresh lane is under pressure."
                  }
                }
              }
            }
          }
        ],
        props: %{
          label: "Pressure state",
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
            id: :process_monitor_footer_binding,
            metadata: %{owner: "footer"},
            source: %{
              id: "state-process_monitor",
              resource: "ExampleState",
              field: :status
            },
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :process_monitor_footer,
        children: [],
        props: %{
          class: "ashui-example-surface-meta",
          content: "Process monitor mounted with the steady-state snapshot."
        }
      }
    ],
    support_notice:
      "The `process_monitor` example uses explicit runtime snapshots and nested controls instead of implying a hidden supervisor tap.",
    notes: "Binds one process monitor model map into a renderer-backed operational shell."
  }
  @theme_css File.read!(Path.expand("../../assets/css/app.css", __DIR__))

  def app, do: :ash_ui_example_process_monitor
  def definition, do: @definition
  def title, do: @definition.title
  def theme_css, do: @theme_css
  def screen_name, do: @screen_name

  def ui_storage do
    [
      domain: AshUIExamples.ProcessMonitor.UiStorageDomain,
      resources: [
        screen: AshUIExamples.ProcessMonitor.UiScreen,
        element: AshUIExamples.ProcessMonitor.UiElement,
        binding: AshUIExamples.ProcessMonitor.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.ProcessMonitor.RuntimeDomain]

  def current_user,
    do: %{
      active: true,
      id: "reviewer-process_monitor",
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
        id: "state-process_monitor",
        status: "Process monitor mounted with the steady-state snapshot.",
        current_value: "steady state",
        payload: %{
          "processes" => [
            %{"meta" => "0 restarts", "name" => "scheduler", "state" => "running"},
            %{"meta" => "1 restart", "name" => "queue_worker", "state" => "running"},
            %{
              "meta" => "0 restarts",
              "name" => "binding_refresher",
              "state" => "idle"
            }
          ],
          "summary" => "Schedulers and workers are healthy with no restart pressure."
        }
      }
    )
  end

  def reset! do
    reset_resource!(
      AshUIExamples.ProcessMonitor.Runtime.ExampleState,
      AshUIExamples.ProcessMonitor.RuntimeDomain
    )

    reset_resource!(
      AshUIExamples.ProcessMonitor.UiBinding,
      AshUIExamples.ProcessMonitor.UiStorageDomain
    )

    reset_resource!(
      AshUIExamples.ProcessMonitor.UiElement,
      AshUIExamples.ProcessMonitor.UiStorageDomain
    )

    reset_resource!(
      AshUIExamples.ProcessMonitor.UiScreen,
      AshUIExamples.ProcessMonitor.UiStorageDomain
    )

    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.ProcessMonitor.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.ProcessMonitor.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.ProcessMonitor.Examples.ProcessMonitorScreen,
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
        {Phoenix.PubSub, name: AshUIExamples.ProcessMonitor.PubSub},
        AshUIExamples.ProcessMonitor.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.ProcessMonitor.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    use Ash.Resource,
      domain: AshUIExamples.ProcessMonitor.RuntimeDomain,
      data_layer: Ash.DataLayer.Ets

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
      resource(AshUIExamples.ProcessMonitor.UiScreen)
      resource(AshUIExamples.ProcessMonitor.UiElement)
      resource(AshUIExamples.ProcessMonitor.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.ProcessMonitor.UiStorageDomain,
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
      has_many :elements, AshUIExamples.ProcessMonitor.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.ProcessMonitor.UiBinding do
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
      domain: AshUIExamples.ProcessMonitor.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.ProcessMonitor.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.ProcessMonitor.UiBinding do
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
      domain: AshUIExamples.ProcessMonitor.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.ProcessMonitor.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.ProcessMonitor.UiScreen do
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
      resource(AshUIExamples.ProcessMonitor.Examples.ProcessMonitorScreen)
      resource(AshUIExamples.ProcessMonitor.Examples.ProcessMonitorDemoPanelElement)
      resource(AshUIExamples.ProcessMonitor.Examples.ProcessMonitorSubjectElement)
      resource(AshUIExamples.ProcessMonitor.Examples.ProcessMonitorPreviewElement)
      resource(AshUIExamples.ProcessMonitor.Examples.ProcessMonitorStoryTextElement)
      resource(AshUIExamples.ProcessMonitor.Examples.ProcessMonitorSignalTextElement)
      resource(AshUIExamples.ProcessMonitor.Examples.ProcessMonitorSupportNoticeElement)

      resource(
        AshUIExamples.ProcessMonitor.Examples.ProcessMonitorLoadSteadyProcessMonitorButtonElement
      )

      resource(
        AshUIExamples.ProcessMonitor.Examples.ProcessMonitorLoadPressureProcessMonitorButtonElement
      )

      resource(AshUIExamples.ProcessMonitor.Examples.ProcessMonitorProcessMonitorFooterElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.ProcessMonitor.AuthoringDomain,
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

  defmodule Examples.ProcessMonitorDemoPanelElement do
    use AshUIExamples.ProcessMonitor.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.ProcessMonitor.Examples.ProcessMonitorSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.ProcessMonitor.Examples.ProcessMonitorPreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices,
               AshUIExamples.ProcessMonitor.Examples.ProcessMonitorSupportNoticeElement do
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
      props(%{title: "Process Monitor Example", class: "ashui-example-panel"})
      metadata(%{id: "example-process_monitor-demo", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.ProcessMonitorSubjectElement do
    use AshUIExamples.ProcessMonitor.ExampleElementBase

    relationships do
      has_many :load_steady_process_monitor_button_elements,
               AshUIExamples.ProcessMonitor.Examples.ProcessMonitorLoadSteadyProcessMonitorButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :load_pressure_process_monitor_button_elements,
               AshUIExamples.ProcessMonitor.Examples.ProcessMonitorLoadPressureProcessMonitorButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :process_monitor_footer_elements,
               AshUIExamples.ProcessMonitor.Examples.ProcessMonitorProcessMonitorFooterElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :load_steady_process_monitor_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(0)
      end

      relationship :load_pressure_process_monitor_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(10)
      end

      relationship :process_monitor_footer_elements do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:process_monitor")

      props(%{
        description: "A compact runtime process surface fed by one persisted model snapshot.",
        title: "Process monitor",
        class: "ashui-example-process-monitor-shell"
      })

      metadata(%{
        id: "example-process_monitor-subject",
        section: "demo",
        slot: "body",
        position: 1
      })
    end

    ui_bindings do
      binding :process_monitor_model do
        source(%{resource: "ExampleState", field: :payload, id: "state-process_monitor"})
        target("model")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "subject", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.ProcessMonitorLoadSteadyProcessMonitorButtonElement do
    use AshUIExamples.ProcessMonitor.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Steady state",
        class: "ashui-example-primary-cta",
        variant: "secondary"
      })

      metadata(%{
        id: "load-steady-process-monitor-button",
        position: 0,
        slot: "actions",
        section: "demo"
      })
    end

    ui_actions do
      action :action_load_steady_process_monitor_button do
        signal(:click)
        source(%{id: "state-process_monitor", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Process monitor mounted with the steady-state snapshot."
            },
            current_value: %{"from" => "static", "value" => "steady state"},
            payload: %{
              "from" => "static",
              "value" => %{
                "processes" => [
                  %{"meta" => "0 restarts", "name" => "scheduler", "state" => "running"},
                  %{
                    "meta" => "1 restart",
                    "name" => "queue_worker",
                    "state" => "running"
                  },
                  %{
                    "meta" => "0 restarts",
                    "name" => "binding_refresher",
                    "state" => "idle"
                  }
                ],
                "summary" => "Schedulers and workers are healthy with no restart pressure."
              }
            }
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.ProcessMonitorLoadPressureProcessMonitorButtonElement do
    use AshUIExamples.ProcessMonitor.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Pressure state",
        class: "ashui-example-secondary-cta",
        variant: "secondary"
      })

      metadata(%{
        id: "load-pressure-process-monitor-button",
        position: 10,
        slot: "actions",
        section: "demo"
      })
    end

    ui_actions do
      action :action_load_pressure_process_monitor_button do
        signal(:click)
        source(%{id: "state-process_monitor", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Process monitor switched to the restart-pressure snapshot."
            },
            current_value: %{"from" => "static", "value" => "pressure state"},
            payload: %{
              "from" => "static",
              "value" => %{
                "processes" => [
                  %{"meta" => "0 restarts", "name" => "scheduler", "state" => "running"},
                  %{
                    "meta" => "4 restarts",
                    "name" => "queue_worker",
                    "state" => "degraded"
                  },
                  %{
                    "meta" => "2 restarts",
                    "name" => "binding_refresher",
                    "state" => "running"
                  }
                ],
                "summary" => "Retry workers are degraded and the refresh lane is under pressure."
              }
            }
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.ProcessMonitorProcessMonitorFooterElement do
    use AshUIExamples.ProcessMonitor.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        class: "ashui-example-surface-meta",
        content: "Process monitor mounted with the steady-state snapshot."
      })

      metadata(%{id: "process-monitor-footer", position: 0, slot: "footer", section: "demo"})
    end

    ui_bindings do
      binding :process_monitor_footer_binding do
        source(%{id: "state-process_monitor", resource: "ExampleState", field: :status})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "footer"})
      end
    end
  end

  defmodule Examples.ProcessMonitorPreviewElement do
    use AshUIExamples.ProcessMonitor.ExampleElementBase

    ui_element do
      type(:stat)
      props(%{title: "Monitor mode", value: "steady state"})
      variants([:primary])

      metadata(%{
        id: "example-process_monitor-preview",
        section: "demo",
        slot: "body",
        position: 2
      })
    end

    ui_bindings do
      binding :preview_value do
        source(%{resource: "ExampleState", field: :current_value, id: "state-process_monitor"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.ProcessMonitorStoryTextElement do
    use AshUIExamples.ProcessMonitor.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: switch the monitored process state and confirm the visible process cards update from persisted runtime data rather than decorative placeholders.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-process_monitor-story",
        section: "story",
        slot: "body",
        position: 10
      })
    end
  end

  defmodule Examples.ProcessMonitorSignalTextElement do
    use AshUIExamples.ProcessMonitor.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: nested button click -> ExampleState.payload -> bound process monitor model plus preview label.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-process_monitor-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.ProcessMonitorSupportNoticeElement do
    use AshUIExamples.ProcessMonitor.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The `process_monitor` example uses explicit runtime snapshots and nested controls instead of implying a hidden supervisor tap.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{
        id: "example-process_monitor-support-note",
        section: "demo",
        slot: "body",
        position: 3
      })
    end
  end

  defmodule Examples.ProcessMonitorScreen do
    use Ash.Resource,
      domain: AshUIExamples.ProcessMonitor.AuthoringDomain,
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
               AshUIExamples.ProcessMonitor.Examples.ProcessMonitorDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts,
               AshUIExamples.ProcessMonitor.Examples.ProcessMonitorStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts,
               AshUIExamples.ProcessMonitor.Examples.ProcessMonitorSignalTextElement do
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
        title: "Process Monitor Example",
        example_directory: "process_monitor",
        shell_id: "example-process_monitor-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.ProcessMonitor.seed!(opts)
    def reset!, do: AshUIExamples.ProcessMonitor.reset!()
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

    scope "/", AshUIExamples.ProcessMonitor.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_process_monitor

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
    plug(AshUIExamples.ProcessMonitor.Web.Router)
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

    alias AshUIExamples.ProcessMonitor.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.ProcessMonitor.seed!()

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.ProcessMonitor.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.ProcessMonitor.ui_storage())
        |> Phoenix.Component.assign(
          :ash_ui_domains,
          AshUIExamples.ProcessMonitor.runtime_domains()
        )
        |> Phoenix.Component.assign(:page_title, "Process Monitor Example")
        |> Phoenix.Component.assign(:example_directory, "process_monitor")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.ProcessMonitor.theme_css())

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/process_monitor", params),
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
        summary={"Meaningful Interaction Story: switch the monitored process state and confirm the visible process cards update from persisted runtime data rather than decorative placeholders."}
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
        AshUIExamples.ProcessMonitor.rendered_ui(socket.assigns)
      )
    end
  end
end
