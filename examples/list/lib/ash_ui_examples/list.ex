defmodule AshUIExamples.List do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `list` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.{DesktopUIAdapter, ElmUIAdapter, LiveUIAdapter}
  alias AshUI.Resource.Authority

  @directory "list"
  @screen_name "example/list"
  @definition %{
    directory: "list",
    family: :data_surface,
    title: "List Example",
    story_text:
      "Meaningful Interaction Story: switch between review queues and confirm the collection surface refreshes through a list binding instead of hard-coded inline rows.",
    signal_text:
      "Canonical Signal Preview: nested button click -> ExampleState.items -> hydrated `list` props.items plus preview status inside the shared Ash HQ shell.",
    preview_field: :current_value,
    seed_state: %{
      id: "state-list",
      status: "List binding mounted with the triage queue.",
      items: [
        %{
          "meta" => "SLA 15m",
          "summary" => "4 records are waiting for owner review.",
          "title" => "Urgent approvals"
        },
        %{
          "meta" => "SLA 30m",
          "summary" => "2 records need a second reviewer.",
          "title" => "Escalation follow-ups"
        },
        %{
          "meta" => "SLA 60m",
          "summary" => "3 callbacks are staged for the next handoff.",
          "title" => "Customer callbacks"
        }
      ],
      current_value: "triage queue"
    },
    support_notice:
      "The `list` example uses a real list binding on the maintained public widget instead of hiding collection changes inside static markup.",
    subject_children: [
      %{
        position: 0,
        type: :button,
        slot: :actions,
        key: :load_triage_queue_button,
        children: [],
        actions: [
          %{
            id: :action_load_triage_queue_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-list",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "List binding mounted with the triage queue."
                },
                items: %{
                  "from" => "static",
                  "value" => [
                    %{
                      "meta" => "SLA 15m",
                      "summary" => "4 records are waiting for owner review.",
                      "title" => "Urgent approvals"
                    },
                    %{
                      "meta" => "SLA 30m",
                      "summary" => "2 records need a second reviewer.",
                      "title" => "Escalation follow-ups"
                    },
                    %{
                      "meta" => "SLA 60m",
                      "summary" => "3 callbacks are staged for the next handoff.",
                      "title" => "Customer callbacks"
                    }
                  ]
                },
                current_value: %{"from" => "static", "value" => "triage queue"}
              }
            }
          }
        ],
        props: %{
          label: "Load triage queue",
          class: "ashui-example-primary-cta",
          variant: "secondary"
        }
      },
      %{
        position: 10,
        type: :button,
        slot: :actions,
        key: :load_handoff_queue_button,
        children: [],
        actions: [
          %{
            id: :action_load_handoff_queue_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-list",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "List binding switched to the handoff queue."
                },
                items: %{
                  "from" => "static",
                  "value" => [
                    %{
                      "meta" => "Owner Maya",
                      "summary" => "Ready for the next operator handoff.",
                      "title" => "Shift summary packet"
                    },
                    %{
                      "meta" => "Owner Idris",
                      "summary" => "Needs explicit confirmation before shift close.",
                      "title" => "Paging rota changes"
                    },
                    %{
                      "meta" => "Owner Jules",
                      "summary" => "Queued for overnight review and logging.",
                      "title" => "Retention audit"
                    }
                  ]
                },
                current_value: %{"from" => "static", "value" => "handoff queue"}
              }
            }
          }
        ],
        props: %{
          label: "Load handoff queue",
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
            id: :list_status_binding,
            metadata: %{owner: "footer"},
            source: %{id: "state-list", resource: "ExampleState", field: :status},
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :list_status,
        children: [],
        props: %{
          content: "List binding mounted with the triage queue.",
          class: "ashui-example-surface-meta"
        }
      }
    ],
    section: :data_surfaces,
    subject_action: nil,
    subject_binding: %{
      id: :list_items,
      target: "items",
      field: :items,
      transform: %{},
      binding_type: :list
    },
    subject_type: :list,
    notes:
      "Actions switch the bound collection while the subject surface stays a maintained public widget.",
    preview_title: "Active queue",
    subject_props: %{
      description: "A bound list surface that refreshes its rows from persisted runtime data.",
      title: "Review queue",
      class: "ashui-example-list-surface",
      empty_text: "No review rows available."
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

  def app, do: :ash_ui_example_list
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
      domain: AshUIExamples.List.UiStorageDomain,
      resources: [
        screen: AshUIExamples.List.UiScreen,
        element: AshUIExamples.List.UiElement,
        binding: AshUIExamples.List.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.List.RuntimeDomain]

  def admin_user, do: %{active: true, id: "reviewer-list", name: "Example Reviewer", role: :admin}

  def operator_user,
    do: %{active: true, id: "operator-list", name: "Example Operator", role: :operator}

  def read_only_user,
    do: %{active: true, id: "viewer-list", name: "Example Viewer", role: :viewer}

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
        id: "state-list",
        status: "List binding mounted with the triage queue.",
        items: [
          %{
            "meta" => "SLA 15m",
            "summary" => "4 records are waiting for owner review.",
            "title" => "Urgent approvals"
          },
          %{
            "meta" => "SLA 30m",
            "summary" => "2 records need a second reviewer.",
            "title" => "Escalation follow-ups"
          },
          %{
            "meta" => "SLA 60m",
            "summary" => "3 callbacks are staged for the next handoff.",
            "title" => "Customer callbacks"
          }
        ],
        current_value: "triage queue"
      }
    )
  end

  def reset! do
    reset_resource!(AshUIExamples.List.Runtime.ExampleState, AshUIExamples.List.RuntimeDomain)
    reset_resource!(AshUIExamples.List.UiBinding, AshUIExamples.List.UiStorageDomain)
    reset_resource!(AshUIExamples.List.UiElement, AshUIExamples.List.UiStorageDomain)
    reset_resource!(AshUIExamples.List.UiScreen, AshUIExamples.List.UiStorageDomain)
    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.List.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.List.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.List.Examples.ListScreen,
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
        {Phoenix.PubSub, name: AshUIExamples.List.PubSub},
        AshUIExamples.List.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.List.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    @resource_topic_prefix "ash_ui:resource:AshUIExamples:List:Runtime:ExampleState"

    use Ash.Resource,
      domain: AshUIExamples.List.RuntimeDomain,
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
      resource(AshUIExamples.List.UiScreen)
      resource(AshUIExamples.List.UiElement)
      resource(AshUIExamples.List.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.List.UiStorageDomain,
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
      has_many :elements, AshUIExamples.List.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.List.UiBinding do
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
      domain: AshUIExamples.List.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.List.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.List.UiBinding do
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
      domain: AshUIExamples.List.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.List.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.List.UiScreen do
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
      resource(AshUIExamples.List.Examples.ListScreen)
      resource(AshUIExamples.List.Examples.ListDemoPanelElement)
      resource(AshUIExamples.List.Examples.ListSubjectElement)
      resource(AshUIExamples.List.Examples.ListPreviewElement)
      resource(AshUIExamples.List.Examples.ListStoryTextElement)
      resource(AshUIExamples.List.Examples.ListSignalTextElement)
      resource(AshUIExamples.List.Examples.ListSupportNoticeElement)
      resource(AshUIExamples.List.Examples.ListLoadTriageQueueButtonElement)
      resource(AshUIExamples.List.Examples.ListLoadHandoffQueueButtonElement)
      resource(AshUIExamples.List.Examples.ListListStatusElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.List.AuthoringDomain,
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

  defmodule Examples.ListDemoPanelElement do
    use AshUIExamples.List.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.List.Examples.ListSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.List.Examples.ListPreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices, AshUIExamples.List.Examples.ListSupportNoticeElement do
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
      props(%{title: "List Example", class: "ashui-example-panel"})
      metadata(%{id: "example-list-demo", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.ListSubjectElement do
    use AshUIExamples.List.ExampleElementBase

    relationships do
      has_many :load_triage_queue_button_elements,
               AshUIExamples.List.Examples.ListLoadTriageQueueButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :load_handoff_queue_button_elements,
               AshUIExamples.List.Examples.ListLoadHandoffQueueButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :list_status_elements, AshUIExamples.List.Examples.ListListStatusElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :load_triage_queue_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(0)
      end

      relationship :load_handoff_queue_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(10)
      end

      relationship :list_status_elements do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:list)

      props(%{
        description: "A bound list surface that refreshes its rows from persisted runtime data.",
        title: "Review queue",
        class: "ashui-example-list-surface",
        empty_text: "No review rows available."
      })

      metadata(%{id: "example-list-subject", section: "demo", slot: "body", position: 1})
    end

    ui_bindings do
      binding :list_items do
        source(%{resource: "ExampleState", field: :items, id: "state-list"})
        target("items")
        binding_type(:list)
        transform(%{})
        metadata(%{owner: "subject", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.ListLoadTriageQueueButtonElement do
    use AshUIExamples.List.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Load triage queue",
        class: "ashui-example-primary-cta",
        variant: "secondary"
      })

      metadata(%{id: "load-triage-queue-button", position: 0, slot: "actions", section: "demo"})
    end

    ui_actions do
      action :action_load_triage_queue_button do
        signal(:click)
        source(%{id: "state-list", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "List binding mounted with the triage queue."
            },
            items: %{
              "from" => "static",
              "value" => [
                %{
                  "meta" => "SLA 15m",
                  "summary" => "4 records are waiting for owner review.",
                  "title" => "Urgent approvals"
                },
                %{
                  "meta" => "SLA 30m",
                  "summary" => "2 records need a second reviewer.",
                  "title" => "Escalation follow-ups"
                },
                %{
                  "meta" => "SLA 60m",
                  "summary" => "3 callbacks are staged for the next handoff.",
                  "title" => "Customer callbacks"
                }
              ]
            },
            current_value: %{"from" => "static", "value" => "triage queue"}
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.ListLoadHandoffQueueButtonElement do
    use AshUIExamples.List.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Load handoff queue",
        class: "ashui-example-secondary-cta",
        variant: "secondary"
      })

      metadata(%{
        id: "load-handoff-queue-button",
        position: 10,
        slot: "actions",
        section: "demo"
      })
    end

    ui_actions do
      action :action_load_handoff_queue_button do
        signal(:click)
        source(%{id: "state-list", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "List binding switched to the handoff queue."
            },
            items: %{
              "from" => "static",
              "value" => [
                %{
                  "meta" => "Owner Maya",
                  "summary" => "Ready for the next operator handoff.",
                  "title" => "Shift summary packet"
                },
                %{
                  "meta" => "Owner Idris",
                  "summary" => "Needs explicit confirmation before shift close.",
                  "title" => "Paging rota changes"
                },
                %{
                  "meta" => "Owner Jules",
                  "summary" => "Queued for overnight review and logging.",
                  "title" => "Retention audit"
                }
              ]
            },
            current_value: %{"from" => "static", "value" => "handoff queue"}
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.ListListStatusElement do
    use AshUIExamples.List.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content: "List binding mounted with the triage queue.",
        class: "ashui-example-surface-meta"
      })

      metadata(%{id: "list-status", position: 0, slot: "footer", section: "demo"})
    end

    ui_bindings do
      binding :list_status_binding do
        source(%{id: "state-list", resource: "ExampleState", field: :status})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "footer"})
      end
    end
  end

  defmodule Examples.ListPreviewElement do
    use AshUIExamples.List.ExampleElementBase

    ui_element do
      type(:stat)
      props(%{title: "Active queue", value: "triage queue"})
      variants([:primary])
      metadata(%{id: "example-list-preview", section: "demo", slot: "body", position: 2})
    end

    ui_bindings do
      binding :preview_value do
        source(%{resource: "ExampleState", field: :current_value, id: "state-list"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.ListStoryTextElement do
    use AshUIExamples.List.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: switch between review queues and confirm the collection surface refreshes through a list binding instead of hard-coded inline rows.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "example-list-story", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.ListSignalTextElement do
    use AshUIExamples.List.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: nested button click -> ExampleState.items -> hydrated `list` props.items plus preview status inside the shared Ash HQ shell.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-list-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.ListSupportNoticeElement do
    use AshUIExamples.List.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The `list` example uses a real list binding on the maintained public widget instead of hiding collection changes inside static markup.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{id: "example-list-support-note", section: "demo", slot: "body", position: 3})
    end
  end

  defmodule Examples.ListScreen do
    use Ash.Resource,
      domain: AshUIExamples.List.AuthoringDomain,
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
      has_many :demo_panels, AshUIExamples.List.Examples.ListDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUIExamples.List.Examples.ListStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUIExamples.List.Examples.ListSignalTextElement do
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
        title: "List Example",
        example_directory: "list",
        shell_id: "example-list-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.List.seed!(opts)
    def reset!, do: AshUIExamples.List.reset!()
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

    scope "/", AshUIExamples.List.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_list

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
    plug(AshUIExamples.List.Web.Router)
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

    alias AshUIExamples.List.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.List.seed!()
      example_runtime = runtime_from_params(params)

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.List.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.List.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUIExamples.List.runtime_domains())
        |> Phoenix.Component.assign(:page_title, "List Example")
        |> Phoenix.Component.assign(:example_directory, "list")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.List.theme_css())
        |> Phoenix.Component.assign(:example_runtime, example_runtime)
        |> Phoenix.Component.assign(:supported_runtimes, AshUIExamples.List.supported_runtimes())

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/list", params),
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
          AshUIExamples.List.supported_runtimes()
        end)
        |> Phoenix.Component.assign_new(:example_runtime, fn ->
          AshUIExamples.List.default_runtime()
        end)
        |> Phoenix.Component.assign_new(:rendered_runtime, fn ->
          %{
            content: assigns[:rendered_ui] || "",
            description:
              AshUIExamples.List.runtime_description(AshUIExamples.List.default_runtime()),
            mode: :live_fragment,
            runtime: AshUIExamples.List.default_runtime()
          }
        end)

      ~H"""
      <ExampleShell.example_shell
        title={@page_title}
        directory={@example_directory}
        summary={"Meaningful Interaction Story: switch between review queues and confirm the collection surface refreshes through a list binding instead of hard-coded inline rows."}
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
        AshUIExamples.List.rendered_runtime(
          socket.assigns,
          socket.assigns[:example_runtime] || AshUIExamples.List.default_runtime()
        )

      socket
      |> Phoenix.Component.assign(:rendered_runtime, rendered_runtime)
      |> Phoenix.Component.assign(:rendered_ui, rendered_runtime.content)
    end

    defp runtime_from_params(params) do
      params["runtime"]
      |> fallback_runtime()
      |> AshUIExamples.List.normalize_runtime!()
    end

    defp fallback_runtime(nil), do: System.get_env("ASH_UI_EXAMPLE_RUNTIME")
    defp fallback_runtime(runtime), do: runtime
  end
end
