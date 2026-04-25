defmodule AshUIExamples.Dialog do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `dialog` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.LiveUIAdapter
  alias AshUI.Resource.Authority

  @directory "dialog"
  @screen_name "example/dialog"
  @definition %{
    directory: "dialog",
    family: :overlay,
    title: "Dialog Example",
    story_text:
      "Meaningful Interaction Story: confirm or cancel the dialog and verify that the result lands in persisted runtime state rather than living only inside ephemeral shell markup.",
    signal_text:
      "Canonical Signal Preview: nested button click -> ExampleState.selected_value and ExampleState.status -> dialog summary copy and preview stat.",
    preview_field: :selected_value,
    seed_state: %{
      enabled: true,
      id: "state-dialog",
      status: "Dialog is awaiting a handoff decision.",
      selected_value: "awaiting decision"
    },
    support_notice:
      "The dialog shell stays explicit `custom:dialog` while the decision buttons own the action declarations.",
    subject_children: [
      %{
        position: 0,
        type: :text,
        slot: :body,
        bindings: [
          %{
            id: :dialog_summary_binding,
            metadata: %{owner: "body"},
            source: %{
              id: "state-dialog",
              resource: "ExampleState",
              field: :selected_value
            },
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :dialog_summary,
        children: [],
        props: %{
          content: "awaiting decision",
          class: "ashui-example-surface-copy"
        }
      },
      %{
        position: 0,
        type: :text,
        slot: :footer,
        bindings: [
          %{
            id: :dialog_status_binding,
            metadata: %{owner: "footer"},
            source: %{
              id: "state-dialog",
              resource: "ExampleState",
              field: :status
            },
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :dialog_status,
        children: [],
        props: %{
          content: "Dialog is awaiting a handoff decision.",
          class: "ashui-example-surface-meta"
        }
      },
      %{
        position: 0,
        type: :button,
        slot: :actions,
        key: :confirm_dialog_button,
        children: [],
        actions: [
          %{
            id: :action_confirm_dialog_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-dialog",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                enabled: %{"from" => "static", "value" => false},
                status: %{
                  "from" => "static",
                  "value" => "Dialog confirmed and dismissed from the nested action row."
                },
                selected_value: %{"from" => "static", "value" => "confirmed"}
              }
            }
          }
        ],
        props: %{
          label: "Confirm handoff",
          class: "ashui-example-primary-cta",
          variant: "secondary"
        }
      },
      %{
        position: 10,
        type: :button,
        slot: :actions,
        key: :cancel_dialog_button,
        children: [],
        actions: [
          %{
            id: :action_cancel_dialog_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-dialog",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                enabled: %{"from" => "static", "value" => false},
                status: %{
                  "from" => "static",
                  "value" => "Dialog cancelled and dismissed from the nested action row."
                },
                selected_value: %{"from" => "static", "value" => "cancelled"}
              }
            }
          }
        ],
        props: %{
          label: "Cancel",
          class: "ashui-example-secondary-cta",
          variant: "secondary"
        }
      }
    ],
    section: :overlay_layered_flows,
    subject_action: nil,
    subject_binding: %{
      id: :dialog_open,
      target: "open",
      field: :enabled,
      transform: %{}
    },
    subject_type: :"custom:dialog",
    notes: "Uses body, actions, and footer slots.",
    preview_title: "Dialog result",
    subject_props: %{
      description: "A composed dialog shell with nested confirm and cancel controls.",
      title: "Confirm handoff",
      class: "ashui-example-dialog-shell"
    }
  }
  @theme_css File.read!(Path.expand("../../assets/css/app.css", __DIR__))

  def app, do: :ash_ui_example_dialog
  def definition, do: @definition
  def title, do: @definition.title
  def theme_css, do: @theme_css
  def screen_name, do: @screen_name

  def ui_storage do
    [
      domain: AshUIExamples.Dialog.UiStorageDomain,
      resources: [
        screen: AshUIExamples.Dialog.UiScreen,
        element: AshUIExamples.Dialog.UiElement,
        binding: AshUIExamples.Dialog.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.Dialog.RuntimeDomain]

  def admin_user,
    do: %{active: true, id: "reviewer-dialog", name: "Example Reviewer", role: :admin}

  def operator_user,
    do: %{
      active: true,
      id: "operator-dialog",
      name: "Example Operator",
      role: :operator
    }

  def read_only_user,
    do: %{active: true, id: "viewer-dialog", name: "Example Viewer", role: :viewer}

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
        id: "state-dialog",
        status: "Dialog is awaiting a handoff decision.",
        selected_value: "awaiting decision"
      }
    )
  end

  def reset! do
    reset_resource!(AshUIExamples.Dialog.Runtime.ExampleState, AshUIExamples.Dialog.RuntimeDomain)
    reset_resource!(AshUIExamples.Dialog.UiBinding, AshUIExamples.Dialog.UiStorageDomain)
    reset_resource!(AshUIExamples.Dialog.UiElement, AshUIExamples.Dialog.UiStorageDomain)
    reset_resource!(AshUIExamples.Dialog.UiScreen, AshUIExamples.Dialog.UiStorageDomain)
    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.Dialog.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.Dialog.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.Dialog.Examples.DialogScreen,
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
        {Phoenix.PubSub, name: AshUIExamples.Dialog.PubSub},
        AshUIExamples.Dialog.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.Dialog.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    @resource_topic_prefix "ash_ui:resource:AshUIExamples:Dialog:Runtime:ExampleState"

    use Ash.Resource,
      domain: AshUIExamples.Dialog.RuntimeDomain,
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
      resource(AshUIExamples.Dialog.UiScreen)
      resource(AshUIExamples.Dialog.UiElement)
      resource(AshUIExamples.Dialog.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.Dialog.UiStorageDomain,
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
      has_many :elements, AshUIExamples.Dialog.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.Dialog.UiBinding do
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
      domain: AshUIExamples.Dialog.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.Dialog.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.Dialog.UiBinding do
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
      domain: AshUIExamples.Dialog.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.Dialog.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.Dialog.UiScreen do
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
      resource(AshUIExamples.Dialog.Examples.DialogScreen)
      resource(AshUIExamples.Dialog.Examples.DialogDemoPanelElement)
      resource(AshUIExamples.Dialog.Examples.DialogSubjectElement)
      resource(AshUIExamples.Dialog.Examples.DialogPreviewElement)
      resource(AshUIExamples.Dialog.Examples.DialogStoryTextElement)
      resource(AshUIExamples.Dialog.Examples.DialogSignalTextElement)
      resource(AshUIExamples.Dialog.Examples.DialogSupportNoticeElement)
      resource(AshUIExamples.Dialog.Examples.DialogDialogSummaryElement)
      resource(AshUIExamples.Dialog.Examples.DialogDialogStatusElement)
      resource(AshUIExamples.Dialog.Examples.DialogConfirmDialogButtonElement)
      resource(AshUIExamples.Dialog.Examples.DialogCancelDialogButtonElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.Dialog.AuthoringDomain,
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

  defmodule Examples.DialogDemoPanelElement do
    use AshUIExamples.Dialog.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.Dialog.Examples.DialogSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.Dialog.Examples.DialogPreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices, AshUIExamples.Dialog.Examples.DialogSupportNoticeElement do
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
      props(%{title: "Dialog Example", class: "ashui-example-panel"})
      metadata(%{id: "example-dialog-demo", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.DialogSubjectElement do
    use AshUIExamples.Dialog.ExampleElementBase

    relationships do
      has_many :dialog_summary_elements,
               AshUIExamples.Dialog.Examples.DialogDialogSummaryElement do
        destination_attribute(:parent_id)
      end

      has_many :dialog_status_elements, AshUIExamples.Dialog.Examples.DialogDialogStatusElement do
        destination_attribute(:parent_id)
      end

      has_many :confirm_dialog_button_elements,
               AshUIExamples.Dialog.Examples.DialogConfirmDialogButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :cancel_dialog_button_elements,
               AshUIExamples.Dialog.Examples.DialogCancelDialogButtonElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :dialog_summary_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :dialog_status_elements do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end

      relationship :confirm_dialog_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(0)
      end

      relationship :cancel_dialog_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:"custom:dialog")

      props(%{
        description: "A composed dialog shell with nested confirm and cancel controls.",
        title: "Confirm handoff",
        class: "ashui-example-dialog-shell"
      })

      metadata(%{id: "example-dialog-subject", section: "demo", slot: "body", position: 1})
    end

    ui_bindings do
      binding :dialog_open do
        source(%{resource: "ExampleState", field: :enabled, id: "state-dialog"})
        target("open")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "subject", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.DialogDialogSummaryElement do
    use AshUIExamples.Dialog.ExampleElementBase

    ui_element do
      type(:text)

      props(%{content: "awaiting decision", class: "ashui-example-surface-copy"})

      metadata(%{id: "dialog-summary", position: 0, slot: "body", section: "demo"})
    end

    ui_bindings do
      binding :dialog_summary_binding do
        source(%{id: "state-dialog", resource: "ExampleState", field: :selected_value})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "body"})
      end
    end
  end

  defmodule Examples.DialogDialogStatusElement do
    use AshUIExamples.Dialog.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content: "Dialog is awaiting a handoff decision.",
        class: "ashui-example-surface-meta"
      })

      metadata(%{id: "dialog-status", position: 0, slot: "footer", section: "demo"})
    end

    ui_bindings do
      binding :dialog_status_binding do
        source(%{id: "state-dialog", resource: "ExampleState", field: :status})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "footer"})
      end
    end
  end

  defmodule Examples.DialogConfirmDialogButtonElement do
    use AshUIExamples.Dialog.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Confirm handoff",
        class: "ashui-example-primary-cta",
        variant: "secondary"
      })

      metadata(%{id: "confirm-dialog-button", position: 0, slot: "actions", section: "demo"})
    end

    ui_actions do
      action :action_confirm_dialog_button do
        signal(:click)
        source(%{id: "state-dialog", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            enabled: %{"from" => "static", "value" => false},
            status: %{
              "from" => "static",
              "value" => "Dialog confirmed and dismissed from the nested action row."
            },
            selected_value: %{"from" => "static", "value" => "confirmed"}
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.DialogCancelDialogButtonElement do
    use AshUIExamples.Dialog.ExampleElementBase

    ui_element do
      type(:button)

      props(%{label: "Cancel", class: "ashui-example-secondary-cta", variant: "secondary"})

      metadata(%{id: "cancel-dialog-button", position: 10, slot: "actions", section: "demo"})
    end

    ui_actions do
      action :action_cancel_dialog_button do
        signal(:click)
        source(%{id: "state-dialog", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            enabled: %{"from" => "static", "value" => false},
            status: %{
              "from" => "static",
              "value" => "Dialog cancelled and dismissed from the nested action row."
            },
            selected_value: %{"from" => "static", "value" => "cancelled"}
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.DialogPreviewElement do
    use AshUIExamples.Dialog.ExampleElementBase

    ui_element do
      type(:stat)
      props(%{title: "Dialog result", value: "awaiting decision"})
      variants([:primary])
      metadata(%{id: "example-dialog-preview", section: "demo", slot: "body", position: 2})
    end

    ui_bindings do
      binding :preview_value do
        source(%{resource: "ExampleState", field: :selected_value, id: "state-dialog"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.DialogStoryTextElement do
    use AshUIExamples.Dialog.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: confirm or cancel the dialog and verify that the result lands in persisted runtime state rather than living only inside ephemeral shell markup.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "example-dialog-story", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.DialogSignalTextElement do
    use AshUIExamples.Dialog.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: nested button click -> ExampleState.selected_value and ExampleState.status -> dialog summary copy and preview stat.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-dialog-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.DialogSupportNoticeElement do
    use AshUIExamples.Dialog.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The dialog shell stays explicit `custom:dialog` while the decision buttons own the action declarations.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{id: "example-dialog-support-note", section: "demo", slot: "body", position: 3})
    end
  end

  defmodule Examples.DialogScreen do
    use Ash.Resource,
      domain: AshUIExamples.Dialog.AuthoringDomain,
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
      has_many :demo_panels, AshUIExamples.Dialog.Examples.DialogDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUIExamples.Dialog.Examples.DialogStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUIExamples.Dialog.Examples.DialogSignalTextElement do
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
        title: "Dialog Example",
        example_directory: "dialog",
        shell_id: "example-dialog-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.Dialog.seed!(opts)
    def reset!, do: AshUIExamples.Dialog.reset!()
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

    scope "/", AshUIExamples.Dialog.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_dialog

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
    plug(AshUIExamples.Dialog.Web.Router)
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

    alias AshUIExamples.Dialog.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.Dialog.seed!()

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.Dialog.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.Dialog.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUIExamples.Dialog.runtime_domains())
        |> Phoenix.Component.assign(:page_title, "Dialog Example")
        |> Phoenix.Component.assign(:example_directory, "dialog")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.Dialog.theme_css())

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/dialog", params),
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
        summary={"Meaningful Interaction Story: confirm or cancel the dialog and verify that the result lands in persisted runtime state rather than living only inside ephemeral shell markup."}
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
        AshUIExamples.Dialog.rendered_ui(socket.assigns)
      )
    end
  end
end
