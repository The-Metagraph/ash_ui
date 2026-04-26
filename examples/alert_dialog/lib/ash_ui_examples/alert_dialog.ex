defmodule AshUIExamples.AlertDialog do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `alert_dialog` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.{DesktopUIAdapter, ElmUIAdapter, LiveUIAdapter}
  alias AshUI.Resource.Authority

  @directory "alert_dialog"
  @screen_name "example/alert_dialog"
  @definition %{
    directory: "alert_dialog",
    family: :overlay,
    title: "Alert Dialog Example",
    story_text:
      "Meaningful Interaction Story: acknowledge or defer the alert dialog and verify that the persisted status copy shows which recovery path the reviewer chose.",
    signal_text:
      "Canonical Signal Preview: nested button click -> ExampleState.selected_value -> alert decision summary plus dismissal state on the explicit `custom:alert_dialog` shell.",
    preview_field: :selected_value,
    seed_state: %{
      enabled: true,
      id: "state-alert_dialog",
      status: "Alert dialog is waiting for an escalation choice.",
      selected_value: "pending acknowledgement"
    },
    support_notice:
      "The alert-dialog shell remains explicit `custom:alert_dialog`; severity semantics stay readable in persisted state and nested action resources.",
    subject_children: [
      %{
        position: 0,
        type: :text,
        slot: :body,
        bindings: [
          %{
            id: :alert_dialog_summary_binding,
            metadata: %{owner: "body"},
            source: %{
              id: "state-alert_dialog",
              resource: "ExampleState",
              field: :selected_value
            },
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :alert_dialog_summary,
        children: [],
        props: %{
          content: "pending acknowledgement",
          class: "ashui-example-surface-copy"
        }
      },
      %{
        position: 0,
        type: :text,
        slot: :footer,
        bindings: [
          %{
            id: :alert_dialog_status_binding,
            metadata: %{owner: "footer"},
            source: %{
              id: "state-alert_dialog",
              resource: "ExampleState",
              field: :status
            },
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :alert_dialog_status,
        children: [],
        props: %{
          content: "Alert dialog is waiting for an escalation choice.",
          class: "ashui-example-surface-meta"
        }
      },
      %{
        position: 0,
        type: :button,
        slot: :actions,
        key: :acknowledge_alert_dialog_button,
        children: [],
        actions: [
          %{
            id: :action_acknowledge_alert_dialog_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-alert_dialog",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                enabled: %{"from" => "static", "value" => false},
                status: %{
                  "from" => "static",
                  "value" =>
                    "Alert acknowledged and the dialog closed through the destructive action."
                },
                selected_value: %{"from" => "static", "value" => "acknowledged"}
              }
            }
          }
        ],
        props: %{
          label: "Acknowledge",
          class: "ashui-example-primary-cta",
          variant: "secondary"
        }
      },
      %{
        position: 10,
        type: :button,
        slot: :actions,
        key: :defer_alert_dialog_button,
        children: [],
        actions: [
          %{
            id: :action_defer_alert_dialog_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-alert_dialog",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                enabled: %{"from" => "static", "value" => false},
                status: %{
                  "from" => "static",
                  "value" => "Alert deferred and the dialog closed with a recovery note."
                },
                selected_value: %{"from" => "static", "value" => "deferred"}
              }
            }
          }
        ],
        props: %{
          label: "Keep for later",
          class: "ashui-example-secondary-cta",
          variant: "secondary"
        }
      }
    ],
    section: :overlay_layered_flows,
    subject_action: nil,
    subject_binding: %{
      id: :alert_dialog_open,
      target: "open",
      field: :enabled,
      transform: %{}
    },
    subject_type: :"custom:alert_dialog",
    notes: "Uses the same layered shell contract with stronger alert copy.",
    preview_title: "Alert decision",
    subject_props: %{
      description: "A higher-severity confirmation flow with explicit recovery actions.",
      title: "Escalation required",
      class: "ashui-example-alert-dialog-shell"
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

  def app, do: :ash_ui_example_alert_dialog
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
      domain: AshUIExamples.AlertDialog.UiStorageDomain,
      resources: [
        screen: AshUIExamples.AlertDialog.UiScreen,
        element: AshUIExamples.AlertDialog.UiElement,
        binding: AshUIExamples.AlertDialog.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.AlertDialog.RuntimeDomain]

  def admin_user,
    do: %{
      active: true,
      id: "reviewer-alert_dialog",
      name: "Example Reviewer",
      role: :admin
    }

  def operator_user,
    do: %{
      active: true,
      id: "operator-alert_dialog",
      name: "Example Operator",
      role: :operator
    }

  def read_only_user,
    do: %{
      active: true,
      id: "viewer-alert_dialog",
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
        enabled: true,
        id: "state-alert_dialog",
        status: "Alert dialog is waiting for an escalation choice.",
        selected_value: "pending acknowledgement"
      }
    )
  end

  def reset! do
    reset_resource!(
      AshUIExamples.AlertDialog.Runtime.ExampleState,
      AshUIExamples.AlertDialog.RuntimeDomain
    )

    reset_resource!(
      AshUIExamples.AlertDialog.UiBinding,
      AshUIExamples.AlertDialog.UiStorageDomain
    )

    reset_resource!(
      AshUIExamples.AlertDialog.UiElement,
      AshUIExamples.AlertDialog.UiStorageDomain
    )

    reset_resource!(AshUIExamples.AlertDialog.UiScreen, AshUIExamples.AlertDialog.UiStorageDomain)
    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.AlertDialog.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.AlertDialog.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.AlertDialog.Examples.AlertDialogScreen,
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
        {Phoenix.PubSub, name: AshUIExamples.AlertDialog.PubSub},
        AshUIExamples.AlertDialog.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.AlertDialog.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    @resource_topic_prefix "ash_ui:resource:AshUIExamples:AlertDialog:Runtime:ExampleState"

    use Ash.Resource,
      domain: AshUIExamples.AlertDialog.RuntimeDomain,
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
      resource(AshUIExamples.AlertDialog.UiScreen)
      resource(AshUIExamples.AlertDialog.UiElement)
      resource(AshUIExamples.AlertDialog.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.AlertDialog.UiStorageDomain,
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
      has_many :elements, AshUIExamples.AlertDialog.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.AlertDialog.UiBinding do
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
      domain: AshUIExamples.AlertDialog.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.AlertDialog.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.AlertDialog.UiBinding do
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
      domain: AshUIExamples.AlertDialog.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.AlertDialog.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.AlertDialog.UiScreen do
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
      resource(AshUIExamples.AlertDialog.Examples.AlertDialogScreen)
      resource(AshUIExamples.AlertDialog.Examples.AlertDialogDemoPanelElement)
      resource(AshUIExamples.AlertDialog.Examples.AlertDialogSubjectElement)
      resource(AshUIExamples.AlertDialog.Examples.AlertDialogPreviewElement)
      resource(AshUIExamples.AlertDialog.Examples.AlertDialogStoryTextElement)
      resource(AshUIExamples.AlertDialog.Examples.AlertDialogSignalTextElement)
      resource(AshUIExamples.AlertDialog.Examples.AlertDialogSupportNoticeElement)
      resource(AshUIExamples.AlertDialog.Examples.AlertDialogAlertDialogSummaryElement)
      resource(AshUIExamples.AlertDialog.Examples.AlertDialogAlertDialogStatusElement)
      resource(AshUIExamples.AlertDialog.Examples.AlertDialogAcknowledgeAlertDialogButtonElement)
      resource(AshUIExamples.AlertDialog.Examples.AlertDialogDeferAlertDialogButtonElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.AlertDialog.AuthoringDomain,
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

  defmodule Examples.AlertDialogDemoPanelElement do
    use AshUIExamples.AlertDialog.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.AlertDialog.Examples.AlertDialogSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.AlertDialog.Examples.AlertDialogPreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices,
               AshUIExamples.AlertDialog.Examples.AlertDialogSupportNoticeElement do
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
      props(%{title: "Alert Dialog Example", class: "ashui-example-panel"})
      metadata(%{id: "example-alert_dialog-demo", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.AlertDialogSubjectElement do
    use AshUIExamples.AlertDialog.ExampleElementBase

    relationships do
      has_many :alert_dialog_summary_elements,
               AshUIExamples.AlertDialog.Examples.AlertDialogAlertDialogSummaryElement do
        destination_attribute(:parent_id)
      end

      has_many :alert_dialog_status_elements,
               AshUIExamples.AlertDialog.Examples.AlertDialogAlertDialogStatusElement do
        destination_attribute(:parent_id)
      end

      has_many :acknowledge_alert_dialog_button_elements,
               AshUIExamples.AlertDialog.Examples.AlertDialogAcknowledgeAlertDialogButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :defer_alert_dialog_button_elements,
               AshUIExamples.AlertDialog.Examples.AlertDialogDeferAlertDialogButtonElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :alert_dialog_summary_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :alert_dialog_status_elements do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end

      relationship :acknowledge_alert_dialog_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(0)
      end

      relationship :defer_alert_dialog_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:"custom:alert_dialog")

      props(%{
        description: "A higher-severity confirmation flow with explicit recovery actions.",
        title: "Escalation required",
        class: "ashui-example-alert-dialog-shell"
      })

      metadata(%{id: "example-alert_dialog-subject", section: "demo", slot: "body", position: 1})
    end

    ui_bindings do
      binding :alert_dialog_open do
        source(%{resource: "ExampleState", field: :enabled, id: "state-alert_dialog"})
        target("open")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "subject", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.AlertDialogAlertDialogSummaryElement do
    use AshUIExamples.AlertDialog.ExampleElementBase

    ui_element do
      type(:text)

      props(%{content: "pending acknowledgement", class: "ashui-example-surface-copy"})

      metadata(%{id: "alert-dialog-summary", position: 0, slot: "body", section: "demo"})
    end

    ui_bindings do
      binding :alert_dialog_summary_binding do
        source(%{id: "state-alert_dialog", resource: "ExampleState", field: :selected_value})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "body"})
      end
    end
  end

  defmodule Examples.AlertDialogAlertDialogStatusElement do
    use AshUIExamples.AlertDialog.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content: "Alert dialog is waiting for an escalation choice.",
        class: "ashui-example-surface-meta"
      })

      metadata(%{id: "alert-dialog-status", position: 0, slot: "footer", section: "demo"})
    end

    ui_bindings do
      binding :alert_dialog_status_binding do
        source(%{id: "state-alert_dialog", resource: "ExampleState", field: :status})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "footer"})
      end
    end
  end

  defmodule Examples.AlertDialogAcknowledgeAlertDialogButtonElement do
    use AshUIExamples.AlertDialog.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Acknowledge",
        class: "ashui-example-primary-cta",
        variant: "secondary"
      })

      metadata(%{
        id: "acknowledge-alert-dialog-button",
        position: 0,
        slot: "actions",
        section: "demo"
      })
    end

    ui_actions do
      action :action_acknowledge_alert_dialog_button do
        signal(:click)
        source(%{id: "state-alert_dialog", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            enabled: %{"from" => "static", "value" => false},
            status: %{
              "from" => "static",
              "value" =>
                "Alert acknowledged and the dialog closed through the destructive action."
            },
            selected_value: %{"from" => "static", "value" => "acknowledged"}
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.AlertDialogDeferAlertDialogButtonElement do
    use AshUIExamples.AlertDialog.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Keep for later",
        class: "ashui-example-secondary-cta",
        variant: "secondary"
      })

      metadata(%{
        id: "defer-alert-dialog-button",
        position: 10,
        slot: "actions",
        section: "demo"
      })
    end

    ui_actions do
      action :action_defer_alert_dialog_button do
        signal(:click)
        source(%{id: "state-alert_dialog", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            enabled: %{"from" => "static", "value" => false},
            status: %{
              "from" => "static",
              "value" => "Alert deferred and the dialog closed with a recovery note."
            },
            selected_value: %{"from" => "static", "value" => "deferred"}
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.AlertDialogPreviewElement do
    use AshUIExamples.AlertDialog.ExampleElementBase

    ui_element do
      type(:stat)
      props(%{title: "Alert decision", value: "pending acknowledgement"})
      variants([:primary])
      metadata(%{id: "example-alert_dialog-preview", section: "demo", slot: "body", position: 2})
    end

    ui_bindings do
      binding :preview_value do
        source(%{resource: "ExampleState", field: :selected_value, id: "state-alert_dialog"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.AlertDialogStoryTextElement do
    use AshUIExamples.AlertDialog.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: acknowledge or defer the alert dialog and verify that the persisted status copy shows which recovery path the reviewer chose.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "example-alert_dialog-story", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.AlertDialogSignalTextElement do
    use AshUIExamples.AlertDialog.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: nested button click -> ExampleState.selected_value -> alert decision summary plus dismissal state on the explicit `custom:alert_dialog` shell.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-alert_dialog-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.AlertDialogSupportNoticeElement do
    use AshUIExamples.AlertDialog.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The alert-dialog shell remains explicit `custom:alert_dialog`; severity semantics stay readable in persisted state and nested action resources.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{
        id: "example-alert_dialog-support-note",
        section: "demo",
        slot: "body",
        position: 3
      })
    end
  end

  defmodule Examples.AlertDialogScreen do
    use Ash.Resource,
      domain: AshUIExamples.AlertDialog.AuthoringDomain,
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
      has_many :demo_panels, AshUIExamples.AlertDialog.Examples.AlertDialogDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUIExamples.AlertDialog.Examples.AlertDialogStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUIExamples.AlertDialog.Examples.AlertDialogSignalTextElement do
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
        title: "Alert Dialog Example",
        example_directory: "alert_dialog",
        shell_id: "example-alert_dialog-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.AlertDialog.seed!(opts)
    def reset!, do: AshUIExamples.AlertDialog.reset!()
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

    scope "/", AshUIExamples.AlertDialog.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_alert_dialog

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
    plug(AshUIExamples.AlertDialog.Web.Router)
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

    alias AshUIExamples.AlertDialog.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.AlertDialog.seed!()
      example_runtime = runtime_from_params(params)

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.AlertDialog.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.AlertDialog.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUIExamples.AlertDialog.runtime_domains())
        |> Phoenix.Component.assign(:page_title, "Alert Dialog Example")
        |> Phoenix.Component.assign(:example_directory, "alert_dialog")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.AlertDialog.theme_css())
        |> Phoenix.Component.assign(:example_runtime, example_runtime)
        |> Phoenix.Component.assign(
          :supported_runtimes,
          AshUIExamples.AlertDialog.supported_runtimes()
        )

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/alert_dialog", params),
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
          AshUIExamples.AlertDialog.supported_runtimes()
        end)
        |> Phoenix.Component.assign_new(:example_runtime, fn ->
          AshUIExamples.AlertDialog.default_runtime()
        end)
        |> Phoenix.Component.assign_new(:rendered_runtime, fn ->
          %{
            content: assigns[:rendered_ui] || "",
            description:
              AshUIExamples.AlertDialog.runtime_description(
                AshUIExamples.AlertDialog.default_runtime()
              ),
            mode: :live_fragment,
            runtime: AshUIExamples.AlertDialog.default_runtime()
          }
        end)

      ~H"""
      <ExampleShell.example_shell
        title={@page_title}
        directory={@example_directory}
        summary={"Meaningful Interaction Story: acknowledge or defer the alert dialog and verify that the persisted status copy shows which recovery path the reviewer chose."}
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
        AshUIExamples.AlertDialog.rendered_runtime(
          socket.assigns,
          socket.assigns[:example_runtime] || AshUIExamples.AlertDialog.default_runtime()
        )

      socket
      |> Phoenix.Component.assign(:rendered_runtime, rendered_runtime)
      |> Phoenix.Component.assign(:rendered_ui, rendered_runtime.content)
    end

    defp runtime_from_params(params) do
      params["runtime"]
      |> fallback_runtime()
      |> AshUIExamples.AlertDialog.normalize_runtime!()
    end

    defp fallback_runtime(nil), do: System.get_env("ASH_UI_EXAMPLE_RUNTIME")
    defp fallback_runtime(runtime), do: runtime
  end
end
