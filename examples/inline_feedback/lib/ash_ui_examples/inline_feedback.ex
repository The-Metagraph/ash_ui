defmodule AshUIExamples.InlineFeedback do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `inline_feedback` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.LiveUIAdapter
  alias AshUI.Resource.Authority

  @directory "inline_feedback"
  @screen_name "example/inline_feedback"
  @definition %{
    directory: "inline_feedback",
    family: :feedback_chart,
    title: "Inline Feedback Example",
    story_text:
      "Meaningful Interaction Story: switch the advisory message and confirm the inline feedback surface updates its visible tone and message from persisted runtime data.",
    signal_text:
      "Canonical Signal Preview: nested button click -> ExampleState.metric -> bound feedback model plus preview tone.",
    preview_field: :current_value,
    seed_state: %{
      id: "state-inline_feedback",
      status: "Inline feedback mounted with the recovery-ready note.",
      current_value: "success",
      metric: %{
        "detail" => "The recovery checklist is complete and ready if the rollout degrades.",
        "title" => "Rollback ready",
        "tone" => "success"
      }
    },
    support_notice:
      "The `inline_feedback` example uses a custom surface to keep tone-box styling and semantics example-scoped.",
    subject_children: [
      %{
        position: 0,
        type: :button,
        slot: :actions,
        key: :load_success_feedback_button,
        children: [],
        actions: [
          %{
            id: :action_load_success_feedback_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-inline_feedback",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Inline feedback mounted with the recovery-ready note."
                },
                current_value: %{"from" => "static", "value" => "success"},
                metric: %{
                  "from" => "static",
                  "value" => %{
                    "detail" =>
                      "The recovery checklist is complete and ready if the rollout degrades.",
                    "title" => "Rollback ready",
                    "tone" => "success"
                  }
                }
              }
            }
          }
        ],
        props: %{
          label: "Recovery ready",
          class: "ashui-example-primary-cta",
          variant: "secondary"
        }
      },
      %{
        position: 10,
        type: :button,
        slot: :actions,
        key: :load_warning_feedback_button,
        children: [],
        actions: [
          %{
            id: :action_load_warning_feedback_button,
            metadata: %{
              intent: "update_example_state",
              success_message: "Layered state updated"
            },
            signal: :click,
            source: %{
              id: "state-inline_feedback",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Inline feedback switched to the review-risk note."
                },
                current_value: %{"from" => "static", "value" => "warning"},
                metric: %{
                  "from" => "static",
                  "value" => %{
                    "detail" =>
                      "The current release should stay under review until retries return to baseline.",
                    "title" => "Review risk",
                    "tone" => "warning"
                  }
                }
              }
            }
          }
        ],
        props: %{
          label: "Review risk",
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
            id: :inline_feedback_footer_binding,
            metadata: %{owner: "footer"},
            source: %{
              id: "state-inline_feedback",
              resource: "ExampleState",
              field: :status
            },
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :inline_feedback_footer,
        children: [],
        props: %{
          content: "Inline feedback mounted with the recovery-ready note.",
          class: "ashui-example-surface-meta"
        }
      }
    ],
    section: :feedback_charts,
    subject_action: nil,
    subject_binding: %{
      id: :inline_feedback_metric,
      target: "model",
      field: :metric,
      transform: %{},
      binding_type: :value
    },
    subject_type: :"custom:inline_feedback",
    notes: "Binds one advisory model map into the feedback shell.",
    preview_title: "Tone",
    subject_props: %{
      description: "A compact inline advisory surface for operator-visible guidance.",
      title: "Recovery note",
      class: "ashui-example-inline-feedback-shell"
    }
  }
  @theme_css File.read!(Path.expand("../../assets/css/app.css", __DIR__))

  def app, do: :ash_ui_example_inline_feedback
  def definition, do: @definition
  def title, do: @definition.title
  def theme_css, do: @theme_css
  def screen_name, do: @screen_name

  def ui_storage do
    [
      domain: AshUIExamples.InlineFeedback.UiStorageDomain,
      resources: [
        screen: AshUIExamples.InlineFeedback.UiScreen,
        element: AshUIExamples.InlineFeedback.UiElement,
        binding: AshUIExamples.InlineFeedback.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.InlineFeedback.RuntimeDomain]

  def admin_user,
    do: %{
      active: true,
      id: "reviewer-inline_feedback",
      name: "Example Reviewer",
      role: :admin
    }

  def operator_user,
    do: %{
      active: true,
      id: "operator-inline_feedback",
      name: "Example Operator",
      role: :operator
    }

  def read_only_user,
    do: %{
      active: true,
      id: "viewer-inline_feedback",
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
        id: "state-inline_feedback",
        status: "Inline feedback mounted with the recovery-ready note.",
        current_value: "success",
        metric: %{
          "detail" => "The recovery checklist is complete and ready if the rollout degrades.",
          "title" => "Rollback ready",
          "tone" => "success"
        }
      }
    )
  end

  def reset! do
    reset_resource!(
      AshUIExamples.InlineFeedback.Runtime.ExampleState,
      AshUIExamples.InlineFeedback.RuntimeDomain
    )

    reset_resource!(
      AshUIExamples.InlineFeedback.UiBinding,
      AshUIExamples.InlineFeedback.UiStorageDomain
    )

    reset_resource!(
      AshUIExamples.InlineFeedback.UiElement,
      AshUIExamples.InlineFeedback.UiStorageDomain
    )

    reset_resource!(
      AshUIExamples.InlineFeedback.UiScreen,
      AshUIExamples.InlineFeedback.UiStorageDomain
    )

    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.InlineFeedback.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.InlineFeedback.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.InlineFeedback.Examples.InlineFeedbackScreen,
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
        {Phoenix.PubSub, name: AshUIExamples.InlineFeedback.PubSub},
        AshUIExamples.InlineFeedback.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.InlineFeedback.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    @resource_topic_prefix "ash_ui:resource:AshUIExamples:InlineFeedback:Runtime:ExampleState"

    use Ash.Resource,
      domain: AshUIExamples.InlineFeedback.RuntimeDomain,
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
      resource(AshUIExamples.InlineFeedback.UiScreen)
      resource(AshUIExamples.InlineFeedback.UiElement)
      resource(AshUIExamples.InlineFeedback.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.InlineFeedback.UiStorageDomain,
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
      has_many :elements, AshUIExamples.InlineFeedback.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.InlineFeedback.UiBinding do
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
      domain: AshUIExamples.InlineFeedback.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.InlineFeedback.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.InlineFeedback.UiBinding do
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
      domain: AshUIExamples.InlineFeedback.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.InlineFeedback.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.InlineFeedback.UiScreen do
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
      resource(AshUIExamples.InlineFeedback.Examples.InlineFeedbackScreen)
      resource(AshUIExamples.InlineFeedback.Examples.InlineFeedbackDemoPanelElement)
      resource(AshUIExamples.InlineFeedback.Examples.InlineFeedbackSubjectElement)
      resource(AshUIExamples.InlineFeedback.Examples.InlineFeedbackPreviewElement)
      resource(AshUIExamples.InlineFeedback.Examples.InlineFeedbackStoryTextElement)
      resource(AshUIExamples.InlineFeedback.Examples.InlineFeedbackSignalTextElement)
      resource(AshUIExamples.InlineFeedback.Examples.InlineFeedbackSupportNoticeElement)

      resource(
        AshUIExamples.InlineFeedback.Examples.InlineFeedbackLoadSuccessFeedbackButtonElement
      )

      resource(
        AshUIExamples.InlineFeedback.Examples.InlineFeedbackLoadWarningFeedbackButtonElement
      )

      resource(AshUIExamples.InlineFeedback.Examples.InlineFeedbackInlineFeedbackFooterElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.InlineFeedback.AuthoringDomain,
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

  defmodule Examples.InlineFeedbackDemoPanelElement do
    use AshUIExamples.InlineFeedback.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.InlineFeedback.Examples.InlineFeedbackSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.InlineFeedback.Examples.InlineFeedbackPreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices,
               AshUIExamples.InlineFeedback.Examples.InlineFeedbackSupportNoticeElement do
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
      props(%{title: "Inline Feedback Example", class: "ashui-example-panel"})
      metadata(%{id: "example-inline_feedback-demo", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.InlineFeedbackSubjectElement do
    use AshUIExamples.InlineFeedback.ExampleElementBase

    relationships do
      has_many :load_success_feedback_button_elements,
               AshUIExamples.InlineFeedback.Examples.InlineFeedbackLoadSuccessFeedbackButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :load_warning_feedback_button_elements,
               AshUIExamples.InlineFeedback.Examples.InlineFeedbackLoadWarningFeedbackButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :inline_feedback_footer_elements,
               AshUIExamples.InlineFeedback.Examples.InlineFeedbackInlineFeedbackFooterElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :load_success_feedback_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(0)
      end

      relationship :load_warning_feedback_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(10)
      end

      relationship :inline_feedback_footer_elements do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:inline_feedback")

      props(%{
        description: "A compact inline advisory surface for operator-visible guidance.",
        title: "Recovery note",
        class: "ashui-example-inline-feedback-shell"
      })

      metadata(%{
        id: "example-inline_feedback-subject",
        section: "demo",
        slot: "body",
        position: 1
      })
    end

    ui_bindings do
      binding :inline_feedback_metric do
        source(%{resource: "ExampleState", field: :metric, id: "state-inline_feedback"})
        target("model")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "subject", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.InlineFeedbackLoadSuccessFeedbackButtonElement do
    use AshUIExamples.InlineFeedback.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Recovery ready",
        class: "ashui-example-primary-cta",
        variant: "secondary"
      })

      metadata(%{
        id: "load-success-feedback-button",
        position: 0,
        slot: "actions",
        section: "demo"
      })
    end

    ui_actions do
      action :action_load_success_feedback_button do
        signal(:click)
        source(%{id: "state-inline_feedback", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Inline feedback mounted with the recovery-ready note."
            },
            current_value: %{"from" => "static", "value" => "success"},
            metric: %{
              "from" => "static",
              "value" => %{
                "detail" =>
                  "The recovery checklist is complete and ready if the rollout degrades.",
                "title" => "Rollback ready",
                "tone" => "success"
              }
            }
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.InlineFeedbackLoadWarningFeedbackButtonElement do
    use AshUIExamples.InlineFeedback.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Review risk",
        class: "ashui-example-secondary-cta",
        variant: "secondary"
      })

      metadata(%{
        id: "load-warning-feedback-button",
        position: 10,
        slot: "actions",
        section: "demo"
      })
    end

    ui_actions do
      action :action_load_warning_feedback_button do
        signal(:click)
        source(%{id: "state-inline_feedback", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Inline feedback switched to the review-risk note."
            },
            current_value: %{"from" => "static", "value" => "warning"},
            metric: %{
              "from" => "static",
              "value" => %{
                "detail" =>
                  "The current release should stay under review until retries return to baseline.",
                "title" => "Review risk",
                "tone" => "warning"
              }
            }
          }
        })

        metadata(%{intent: "update_example_state", success_message: "Layered state updated"})
      end
    end
  end

  defmodule Examples.InlineFeedbackInlineFeedbackFooterElement do
    use AshUIExamples.InlineFeedback.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content: "Inline feedback mounted with the recovery-ready note.",
        class: "ashui-example-surface-meta"
      })

      metadata(%{id: "inline-feedback-footer", position: 0, slot: "footer", section: "demo"})
    end

    ui_bindings do
      binding :inline_feedback_footer_binding do
        source(%{id: "state-inline_feedback", resource: "ExampleState", field: :status})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "footer"})
      end
    end
  end

  defmodule Examples.InlineFeedbackPreviewElement do
    use AshUIExamples.InlineFeedback.ExampleElementBase

    ui_element do
      type(:stat)
      props(%{title: "Tone", value: "success"})
      variants([:primary])

      metadata(%{
        id: "example-inline_feedback-preview",
        section: "demo",
        slot: "body",
        position: 2
      })
    end

    ui_bindings do
      binding :preview_value do
        source(%{resource: "ExampleState", field: :current_value, id: "state-inline_feedback"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.InlineFeedbackStoryTextElement do
    use AshUIExamples.InlineFeedback.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: switch the advisory message and confirm the inline feedback surface updates its visible tone and message from persisted runtime data.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-inline_feedback-story",
        section: "story",
        slot: "body",
        position: 10
      })
    end
  end

  defmodule Examples.InlineFeedbackSignalTextElement do
    use AshUIExamples.InlineFeedback.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: nested button click -> ExampleState.metric -> bound feedback model plus preview tone.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-inline_feedback-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.InlineFeedbackSupportNoticeElement do
    use AshUIExamples.InlineFeedback.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The `inline_feedback` example uses a custom surface to keep tone-box styling and semantics example-scoped.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{
        id: "example-inline_feedback-support-note",
        section: "demo",
        slot: "body",
        position: 3
      })
    end
  end

  defmodule Examples.InlineFeedbackScreen do
    use Ash.Resource,
      domain: AshUIExamples.InlineFeedback.AuthoringDomain,
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
               AshUIExamples.InlineFeedback.Examples.InlineFeedbackDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts,
               AshUIExamples.InlineFeedback.Examples.InlineFeedbackStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts,
               AshUIExamples.InlineFeedback.Examples.InlineFeedbackSignalTextElement do
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
        title: "Inline Feedback Example",
        example_directory: "inline_feedback",
        shell_id: "example-inline_feedback-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.InlineFeedback.seed!(opts)
    def reset!, do: AshUIExamples.InlineFeedback.reset!()
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

    scope "/", AshUIExamples.InlineFeedback.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_inline_feedback

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
    plug(AshUIExamples.InlineFeedback.Web.Router)
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

    alias AshUIExamples.InlineFeedback.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.InlineFeedback.seed!()

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.InlineFeedback.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.InlineFeedback.ui_storage())
        |> Phoenix.Component.assign(
          :ash_ui_domains,
          AshUIExamples.InlineFeedback.runtime_domains()
        )
        |> Phoenix.Component.assign(:page_title, "Inline Feedback Example")
        |> Phoenix.Component.assign(:example_directory, "inline_feedback")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.InlineFeedback.theme_css())

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/inline_feedback", params),
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
        summary={"Meaningful Interaction Story: switch the advisory message and confirm the inline feedback surface updates its visible tone and message from persisted runtime data."}
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
        AshUIExamples.InlineFeedback.rendered_ui(socket.assigns)
      )
    end
  end
end
