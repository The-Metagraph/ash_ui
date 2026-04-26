defmodule AshUIExamples.Gauge do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `gauge` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.{DesktopUIAdapter, ElmUIAdapter, LiveUIAdapter}
  alias AshUI.Resource.Authority

  @directory "gauge"
  @screen_name "example/gauge"
  @definition %{
    directory: "gauge",
    family: :feedback_chart,
    title: "Gauge Example",
    story_text:
      "Meaningful Interaction Story: switch the live capacity snapshot and confirm the gauge surface updates both its visible fill amount and its supporting detail.",
    signal_text:
      "Canonical Signal Preview: nested button click -> ExampleState.metric -> bound gauge model plus preview state.",
    preview_field: :current_value,
    seed_state: %{
      id: "state-gauge",
      status: "Gauge surface mounted with the normal capacity snapshot.",
      current_value: "63%",
      metric: %{
        "detail" => "Current saturation is within the operating budget.",
        "label" => "CPU saturation",
        "max" => 100,
        "value" => 63
      }
    },
    support_notice:
      "The `gauge` example stays a custom shell because its radial/threshold presentation is renderer-backed rather than part of the maintained public widget set.",
    subject_children: [
      %{
        position: 0,
        type: :button,
        slot: :actions,
        key: :load_nominal_gauge_button,
        children: [],
        actions: [
          %{
            id: :action_load_nominal_gauge_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-gauge",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Gauge surface mounted with the normal capacity snapshot."
                },
                current_value: %{"from" => "static", "value" => "63%"},
                metric: %{
                  "from" => "static",
                  "value" => %{
                    "detail" => "Current saturation is within the operating budget.",
                    "label" => "CPU saturation",
                    "max" => 100,
                    "value" => 63
                  }
                }
              }
            }
          }
        ],
        props: %{
          label: "Nominal",
          class: "ashui-example-primary-cta",
          variant: "secondary"
        }
      },
      %{
        position: 10,
        type: :button,
        slot: :actions,
        key: :load_elevated_gauge_button,
        children: [],
        actions: [
          %{
            id: :action_load_elevated_gauge_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-gauge",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Gauge surface switched to the elevated capacity snapshot."
                },
                current_value: %{"from" => "static", "value" => "87%"},
                metric: %{
                  "from" => "static",
                  "value" => %{
                    "detail" =>
                      "Capacity is approaching the point where intervention is required.",
                    "label" => "CPU saturation",
                    "max" => 100,
                    "value" => 87
                  }
                }
              }
            }
          }
        ],
        props: %{
          label: "Elevated",
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
            id: :gauge_footer_binding,
            metadata: %{owner: "footer"},
            source: %{id: "state-gauge", resource: "ExampleState", field: :status},
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :gauge_footer,
        children: [],
        props: %{
          content: "Gauge surface mounted with the normal capacity snapshot.",
          class: "ashui-example-surface-meta"
        }
      }
    ],
    section: :feedback_charts,
    subject_action: nil,
    subject_binding: %{
      id: :gauge_metric,
      target: "model",
      field: :metric,
      transform: %{},
      binding_type: :value
    },
    subject_type: :"custom:gauge",
    notes: "Binds a bounded metric map into a gauge-style visual.",
    preview_title: "Capacity",
    subject_props: %{
      description: "A compact capacity surface that reads one bounded metric model.",
      title: "Capacity gauge",
      class: "ashui-example-gauge-shell"
    }
  }
  @theme_css File.read!(Path.expand("../../assets/css/app.css", __DIR__))
  @default_runtime "live_ui"
  @supported_runtimes ["live_ui", "elm_ui", "desktop_ui"]
  @runtime_aliases %{
    "desktop" => "desktop_ui",
    "desktop_ui" => "desktop_ui",
    "elm" => "elm_ui",
    "elm_ui" => "elm_ui",
    "live" => "live_ui",
    "live-ui" => "live_ui",
    "live_ui" => "live_ui",
    "liveview" => "live_ui"
  }
  @runtime_descriptions %{
    "live_ui" =>
      "Default runtime: renders the live_ui surface inside the Phoenix LiveView example shell.",
    "elm_ui" =>
      "Alternate runtime: renders the canonical IUR through elm_ui and previews the generated document inside the Phoenix LiveView example shell.",
    "desktop_ui" =>
      "Alternate runtime: renders the canonical IUR to desktop_ui instructions and previews the generated payload inside the Phoenix LiveView example shell."
  }

  def app, do: :ash_ui_example_gauge
  def default_runtime, do: @default_runtime
  def definition, do: @definition
  def title, do: @definition.title

  def runtime_description(runtime),
    do: runtime |> normalize_runtime!() |> then(&Map.fetch!(@runtime_descriptions, &1))

  def supported_runtimes, do: @supported_runtimes
  def theme_css, do: @theme_css
  def screen_name, do: @screen_name

  def ui_storage do
    [
      domain: AshUIExamples.Gauge.UiStorageDomain,
      resources: [
        screen: AshUIExamples.Gauge.UiScreen,
        element: AshUIExamples.Gauge.UiElement,
        binding: AshUIExamples.Gauge.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.Gauge.RuntimeDomain]

  def admin_user,
    do: %{active: true, id: "reviewer-gauge", name: "Example Reviewer", role: :admin}

  def operator_user,
    do: %{active: true, id: "operator-gauge", name: "Example Operator", role: :operator}

  def read_only_user,
    do: %{active: true, id: "viewer-gauge", name: "Example Viewer", role: :viewer}

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
        id: "state-gauge",
        status: "Gauge surface mounted with the normal capacity snapshot.",
        current_value: "63%",
        metric: %{
          "detail" => "Current saturation is within the operating budget.",
          "label" => "CPU saturation",
          "max" => 100,
          "value" => 63
        }
      }
    )
  end

  def reset! do
    reset_resource!(AshUIExamples.Gauge.Runtime.ExampleState, AshUIExamples.Gauge.RuntimeDomain)
    reset_resource!(AshUIExamples.Gauge.UiBinding, AshUIExamples.Gauge.UiStorageDomain)
    reset_resource!(AshUIExamples.Gauge.UiElement, AshUIExamples.Gauge.UiStorageDomain)
    reset_resource!(AshUIExamples.Gauge.UiScreen, AshUIExamples.Gauge.UiStorageDomain)
    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.Gauge.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.Gauge.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.Gauge.Examples.GaugeScreen,
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
    assigns
    |> rendered_runtime()
    |> then(& &1.content)
  end

  def normalize_runtime(nil), do: {:ok, @default_runtime}

  def normalize_runtime(runtime) when is_binary(runtime) do
    runtime =
      runtime
      |> String.trim()
      |> String.downcase()

    case Map.fetch(@runtime_aliases, runtime) do
      {:ok, canonical} -> {:ok, canonical}
      :error -> {:error, {:unsupported_runtime, runtime, @supported_runtimes}}
    end
  end

  def normalize_runtime!(runtime) do
    case normalize_runtime(runtime) do
      {:ok, canonical} ->
        canonical

      {:error, {:unsupported_runtime, value, supported}} ->
        raise ArgumentError,
              "unsupported runtime #{inspect(value)}; expected one of: #{Enum.join(supported, ", ")}"
    end
  end

  def rendered_runtime(assigns, runtime \\ default_runtime()) do
    runtime = normalize_runtime!(runtime)

    iur =
      assigns[:ash_ui_iur] ||
        Integration.hydrate_iur(assigns[:ash_ui_base_iur], assigns[:ash_ui_bindings] || %{})

    bindings = Map.values(assigns[:ash_ui_bindings] || %{})

    case runtime do
      "live_ui" ->
        {:ok, markup} =
          LiveUIAdapter.render(
            iur,
            bindings: bindings,
            event_prefix: "ash_ui",
            force_fallback: true
          )

        %{
          content: markup,
          description: runtime_description(runtime),
          mode: :live_fragment,
          runtime: runtime
        }

      "elm_ui" ->
        {:ok, html_document} = ElmUIAdapter.render(iur, title: title())

        %{
          content: html_document,
          description: runtime_description(runtime),
          mode: :html_document,
          runtime: runtime
        }

      "desktop_ui" ->
        {:ok, instructions} = DesktopUIAdapter.render(iur, window_title: title())

        %{
          content: Jason.encode!(instructions, pretty: true),
          description: runtime_description(runtime),
          mode: :desktop_instructions,
          runtime: runtime
        }
    end
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
        {Phoenix.PubSub, name: AshUIExamples.Gauge.PubSub},
        AshUIExamples.Gauge.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.Gauge.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    @resource_topic_prefix "ash_ui:resource:AshUIExamples:Gauge:Runtime:ExampleState"

    use Ash.Resource,
      domain: AshUIExamples.Gauge.RuntimeDomain,
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
      resource(AshUIExamples.Gauge.UiScreen)
      resource(AshUIExamples.Gauge.UiElement)
      resource(AshUIExamples.Gauge.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.Gauge.UiStorageDomain,
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
      has_many :elements, AshUIExamples.Gauge.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.Gauge.UiBinding do
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
      domain: AshUIExamples.Gauge.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.Gauge.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.Gauge.UiBinding do
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
      domain: AshUIExamples.Gauge.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.Gauge.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.Gauge.UiScreen do
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
      resource(AshUIExamples.Gauge.Examples.GaugeScreen)
      resource(AshUIExamples.Gauge.Examples.GaugeDemoPanelElement)
      resource(AshUIExamples.Gauge.Examples.GaugeSubjectElement)
      resource(AshUIExamples.Gauge.Examples.GaugePreviewElement)
      resource(AshUIExamples.Gauge.Examples.GaugeStoryTextElement)
      resource(AshUIExamples.Gauge.Examples.GaugeSignalTextElement)
      resource(AshUIExamples.Gauge.Examples.GaugeSupportNoticeElement)
      resource(AshUIExamples.Gauge.Examples.GaugeLoadNominalGaugeButtonElement)
      resource(AshUIExamples.Gauge.Examples.GaugeLoadElevatedGaugeButtonElement)
      resource(AshUIExamples.Gauge.Examples.GaugeGaugeFooterElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.Gauge.AuthoringDomain,
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

  defmodule Examples.GaugeDemoPanelElement do
    use AshUIExamples.Gauge.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.Gauge.Examples.GaugeSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.Gauge.Examples.GaugePreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices, AshUIExamples.Gauge.Examples.GaugeSupportNoticeElement do
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
      props(%{title: "Gauge Example", class: "ashui-example-panel"})
      metadata(%{id: "example-gauge-demo", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.GaugeSubjectElement do
    use AshUIExamples.Gauge.ExampleElementBase

    relationships do
      has_many :load_nominal_gauge_button_elements,
               AshUIExamples.Gauge.Examples.GaugeLoadNominalGaugeButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :load_elevated_gauge_button_elements,
               AshUIExamples.Gauge.Examples.GaugeLoadElevatedGaugeButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :gauge_footer_elements, AshUIExamples.Gauge.Examples.GaugeGaugeFooterElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :load_nominal_gauge_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(0)
      end

      relationship :load_elevated_gauge_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(10)
      end

      relationship :gauge_footer_elements do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:gauge")

      props(%{
        description: "A compact capacity surface that reads one bounded metric model.",
        title: "Capacity gauge",
        class: "ashui-example-gauge-shell"
      })

      metadata(%{id: "example-gauge-subject", section: "demo", slot: "body", position: 1})
    end

    ui_bindings do
      binding :gauge_metric do
        source(%{resource: "ExampleState", field: :metric, id: "state-gauge"})
        target("model")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "subject", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.GaugeLoadNominalGaugeButtonElement do
    use AshUIExamples.Gauge.ExampleElementBase

    ui_element do
      type(:button)

      props(%{label: "Nominal", class: "ashui-example-primary-cta", variant: "secondary"})

      metadata(%{
        id: "load-nominal-gauge-button",
        position: 0,
        slot: "actions",
        section: "demo"
      })
    end

    ui_actions do
      action :action_load_nominal_gauge_button do
        signal(:click)
        source(%{id: "state-gauge", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Gauge surface mounted with the normal capacity snapshot."
            },
            current_value: %{"from" => "static", "value" => "63%"},
            metric: %{
              "from" => "static",
              "value" => %{
                "detail" => "Current saturation is within the operating budget.",
                "label" => "CPU saturation",
                "max" => 100,
                "value" => 63
              }
            }
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.GaugeLoadElevatedGaugeButtonElement do
    use AshUIExamples.Gauge.ExampleElementBase

    ui_element do
      type(:button)

      props(%{label: "Elevated", class: "ashui-example-secondary-cta", variant: "secondary"})

      metadata(%{
        id: "load-elevated-gauge-button",
        position: 10,
        slot: "actions",
        section: "demo"
      })
    end

    ui_actions do
      action :action_load_elevated_gauge_button do
        signal(:click)
        source(%{id: "state-gauge", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Gauge surface switched to the elevated capacity snapshot."
            },
            current_value: %{"from" => "static", "value" => "87%"},
            metric: %{
              "from" => "static",
              "value" => %{
                "detail" => "Capacity is approaching the point where intervention is required.",
                "label" => "CPU saturation",
                "max" => 100,
                "value" => 87
              }
            }
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.GaugeGaugeFooterElement do
    use AshUIExamples.Gauge.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content: "Gauge surface mounted with the normal capacity snapshot.",
        class: "ashui-example-surface-meta"
      })

      metadata(%{id: "gauge-footer", position: 0, slot: "footer", section: "demo"})
    end

    ui_bindings do
      binding :gauge_footer_binding do
        source(%{id: "state-gauge", resource: "ExampleState", field: :status})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "footer"})
      end
    end
  end

  defmodule Examples.GaugePreviewElement do
    use AshUIExamples.Gauge.ExampleElementBase

    ui_element do
      type(:stat)
      props(%{title: "Capacity", value: "63%"})
      variants([:primary])
      metadata(%{id: "example-gauge-preview", section: "demo", slot: "body", position: 2})
    end

    ui_bindings do
      binding :preview_value do
        source(%{resource: "ExampleState", field: :current_value, id: "state-gauge"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.GaugeStoryTextElement do
    use AshUIExamples.Gauge.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: switch the live capacity snapshot and confirm the gauge surface updates both its visible fill amount and its supporting detail.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "example-gauge-story", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.GaugeSignalTextElement do
    use AshUIExamples.Gauge.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: nested button click -> ExampleState.metric -> bound gauge model plus preview state.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-gauge-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.GaugeSupportNoticeElement do
    use AshUIExamples.Gauge.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The `gauge` example stays a custom shell because its radial/threshold presentation is renderer-backed rather than part of the maintained public widget set.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{id: "example-gauge-support-note", section: "demo", slot: "body", position: 3})
    end
  end

  defmodule Examples.GaugeScreen do
    use Ash.Resource,
      domain: AshUIExamples.Gauge.AuthoringDomain,
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
      has_many :demo_panels, AshUIExamples.Gauge.Examples.GaugeDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUIExamples.Gauge.Examples.GaugeStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUIExamples.Gauge.Examples.GaugeSignalTextElement do
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
        title: "Gauge Example",
        example_directory: "gauge",
        shell_id: "example-gauge-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.Gauge.seed!(opts)
    def reset!, do: AshUIExamples.Gauge.reset!()
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

    scope "/", AshUIExamples.Gauge.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_gauge

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
    plug(AshUIExamples.Gauge.Web.Router)
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

    alias AshUIExamples.Gauge.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.Gauge.seed!()
      example_runtime = runtime_from_params(params)

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.Gauge.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.Gauge.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUIExamples.Gauge.runtime_domains())
        |> Phoenix.Component.assign(:page_title, "Gauge Example")
        |> Phoenix.Component.assign(:example_directory, "gauge")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.Gauge.theme_css())
        |> Phoenix.Component.assign(:example_runtime, example_runtime)
        |> Phoenix.Component.assign(:supported_runtimes, AshUIExamples.Gauge.supported_runtimes())

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/gauge", params),
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
      assigns =
        assigns
        |> Phoenix.Component.assign_new(:supported_runtimes, fn ->
          AshUIExamples.Gauge.supported_runtimes()
        end)
        |> Phoenix.Component.assign_new(:example_runtime, fn ->
          AshUIExamples.Gauge.default_runtime()
        end)
        |> Phoenix.Component.assign_new(:rendered_runtime, fn ->
          %{
            content: assigns[:rendered_ui] || "",
            description:
              AshUIExamples.Gauge.runtime_description(AshUIExamples.Gauge.default_runtime()),
            mode: :live_fragment,
            runtime: AshUIExamples.Gauge.default_runtime()
          }
        end)

      ~H"""
      <ExampleShell.example_shell
        title={@page_title}
        directory={@example_directory}
        summary={"Meaningful Interaction Story: switch the live capacity snapshot and confirm the gauge surface updates both its visible fill amount and its supporting detail."}
        theme_css={@theme_css}
      >
        <section class="ashui-example-runtime-panel" id={"example-#{@example_directory}-runtime"}>
          <div class="ashui-example-runtime-copy">
            <h2 class="ashui-example-runtime-title">
              Runtime preview: <%= @rendered_runtime.runtime %>
            </h2>
            <p class="ashui-example-runtime-copy"><%= @rendered_runtime.description %></p>
          </div>
          <div class="ashui-example-runtime-actions">
            <%= for runtime <- @supported_runtimes do %>
              <code class="ashui-example-runtime-command">mix example.start <%= runtime %></code>
            <% end %>
          </div>
        </section>
        <section class="ashui-example-runtime-view">
          <%= case @rendered_runtime.mode do %>
            <% :html_document -> %>
              <iframe
                class="ashui-example-runtime-frame"
                sandbox="allow-same-origin"
                srcdoc={@rendered_runtime.content}
                title={"#{@example_directory}-#{@rendered_runtime.runtime}"}
              />
            <% :desktop_instructions -> %>
              <pre class="ashui-example-runtime-pre"><%= @rendered_runtime.content %></pre>
            <% :live_fragment -> %>
              <%= Phoenix.HTML.raw(@rendered_runtime.content) %>
          <% end %>
        </section>
      </ExampleShell.example_shell>
      """
    end

    defp refresh_rendered_ui(socket) do
      rendered_runtime =
        AshUIExamples.Gauge.rendered_runtime(
          socket.assigns,
          socket.assigns[:example_runtime] || AshUIExamples.Gauge.default_runtime()
        )

      socket
      |> Phoenix.Component.assign(:rendered_runtime, rendered_runtime)
      |> Phoenix.Component.assign(:rendered_ui, rendered_runtime.content)
    end

    defp runtime_from_params(params) do
      params["runtime"]
      |> fallback_runtime()
      |> AshUIExamples.Gauge.normalize_runtime!()
    end

    defp fallback_runtime(nil), do: System.get_env("ASH_UI_EXAMPLE_RUNTIME")
    defp fallback_runtime(runtime), do: runtime
  end
end
