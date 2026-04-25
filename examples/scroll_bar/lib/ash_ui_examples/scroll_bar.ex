defmodule AshUIExamples.ScrollBar do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `scroll_bar` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.LiveUIAdapter
  alias AshUI.Resource.Authority

  @directory "scroll_bar"
  @screen_name "example/scroll_bar"
  @definition %{
    directory: "scroll_bar",
    family: :display,
    title: "Scroll Bar Example",
    section: :display_systems,
    subject_type: :"custom:scroll_bar",
    subject_props: %{
      description:
        "Nested public buttons shift the focused lane while the outer custom shell owns the larger scroll-track surface only.",
      title: "Lane scroll",
      class: "ashui-example-scroll-bar-shell",
      thumb_label: "queue lane"
    },
    story_text:
      "Meaningful Interaction Story: change the scroll focus through nested public buttons and confirm the thumb label plus status copy update without turning `scroll_bar` into an admitted public widget.",
    signal_text:
      "Canonical Signal Preview: nested button click -> ExampleState.selected_value -> thumb label binding, body copy, and preview stat.",
    seed_state: %{
      id: "state-scroll_bar",
      status: "Scroll focus stays local to nested public controls.",
      selected_value: "queue lane"
    },
    preview_field: :selected_value,
    preview_title: "Thumb focus",
    subject_binding: %{
      id: :scroll_thumb_focus,
      target: "thumb_label",
      field: :selected_value,
      transform: %{}
    },
    subject_action: nil,
    subject_children: [
      %{
        position: 0,
        type: :text,
        slot: :body,
        bindings: [
          %{
            id: :scroll_focus_copy_binding,
            metadata: %{owner: "body"},
            source: %{
              id: "state-scroll_bar",
              resource: "ExampleState",
              field: :selected_value
            },
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :scroll_focus_copy,
        children: [],
        props: %{class: "ashui-example-surface-copy", content: "queue lane"}
      },
      %{
        position: 10,
        type: :button,
        slot: :body,
        key: :queue_scroll_button,
        children: [],
        props: %{
          label: "Queue lane",
          class: "ashui-example-nav-button",
          variant: "secondary"
        },
        actions: [
          %{
            id: :focus_queue_thumb,
            metadata: %{
              intent: "select_display_surface",
              success_message: "Selection updated"
            },
            signal: :click,
            source: %{
              id: "state-scroll_bar",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Queue lane aligned with the scroll thumb."
                },
                selected_value: %{"from" => "static", "value" => "queue lane"}
              }
            }
          }
        ]
      },
      %{
        position: 20,
        type: :button,
        slot: :body,
        key: :escalations_scroll_button,
        children: [],
        props: %{
          label: "Escalations lane",
          class: "ashui-example-nav-button",
          variant: "secondary"
        },
        actions: [
          %{
            id: :focus_escalations_thumb,
            metadata: %{
              intent: "select_display_surface",
              success_message: "Selection updated"
            },
            signal: :click,
            source: %{
              id: "state-scroll_bar",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Escalations lane aligned with the scroll thumb."
                },
                selected_value: %{
                  "from" => "static",
                  "value" => "escalations lane"
                }
              }
            }
          }
        ]
      },
      %{
        position: 30,
        type: :button,
        slot: :body,
        key: :handoff_scroll_button,
        children: [],
        props: %{
          label: "Handoff lane",
          class: "ashui-example-nav-button",
          variant: "secondary"
        },
        actions: [
          %{
            id: :focus_handoff_thumb,
            metadata: %{
              intent: "select_display_surface",
              success_message: "Selection updated"
            },
            signal: :click,
            source: %{
              id: "state-scroll_bar",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Handoff lane aligned with the scroll thumb."
                },
                selected_value: %{"from" => "static", "value" => "handoff lane"}
              }
            }
          }
        ]
      },
      %{
        position: 0,
        type: :text,
        slot: :footer,
        bindings: [
          %{
            id: :scroll_status_binding,
            metadata: %{owner: "footer"},
            source: %{
              id: "state-scroll_bar",
              resource: "ExampleState",
              field: :status
            },
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :scroll_status,
        children: [],
        props: %{
          class: "ashui-example-surface-meta",
          content: "Scroll focus stays local to nested public controls."
        }
      }
    ],
    support_notice:
      "The `scroll_bar` example keeps focus changes on nested public buttons while the thumb itself is driven through a subject-level binding.",
    notes: "Uses an explicit custom shell with a bound thumb label."
  }
  @theme_css File.read!(Path.expand("../../assets/css/app.css", __DIR__))

  def app, do: :ash_ui_example_scroll_bar
  def definition, do: @definition
  def title, do: @definition.title
  def theme_css, do: @theme_css
  def screen_name, do: @screen_name

  def ui_storage do
    [
      domain: AshUIExamples.ScrollBar.UiStorageDomain,
      resources: [
        screen: AshUIExamples.ScrollBar.UiScreen,
        element: AshUIExamples.ScrollBar.UiElement,
        binding: AshUIExamples.ScrollBar.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.ScrollBar.RuntimeDomain]

  def current_user,
    do: %{
      active: true,
      id: "reviewer-scroll_bar",
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
        notes: ""
      },
      %{
        id: "state-scroll_bar",
        status: "Scroll focus stays local to nested public controls.",
        selected_value: "queue lane"
      }
    )
  end

  def reset! do
    reset_resource!(
      AshUIExamples.ScrollBar.Runtime.ExampleState,
      AshUIExamples.ScrollBar.RuntimeDomain
    )

    reset_resource!(AshUIExamples.ScrollBar.UiBinding, AshUIExamples.ScrollBar.UiStorageDomain)
    reset_resource!(AshUIExamples.ScrollBar.UiElement, AshUIExamples.ScrollBar.UiStorageDomain)
    reset_resource!(AshUIExamples.ScrollBar.UiScreen, AshUIExamples.ScrollBar.UiStorageDomain)
    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.ScrollBar.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.ScrollBar.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.ScrollBar.Examples.ScrollBarScreen,
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
        {Phoenix.PubSub, name: AshUIExamples.ScrollBar.PubSub},
        AshUIExamples.ScrollBar.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.ScrollBar.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    use Ash.Resource, domain: AshUIExamples.ScrollBar.RuntimeDomain, data_layer: Ash.DataLayer.Ets

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
          :notes
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
          :notes
        ])
      end
    end
  end

  defmodule UiStorageDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.ScrollBar.UiScreen)
      resource(AshUIExamples.ScrollBar.UiElement)
      resource(AshUIExamples.ScrollBar.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.ScrollBar.UiStorageDomain,
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
      has_many :elements, AshUIExamples.ScrollBar.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.ScrollBar.UiBinding do
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
      domain: AshUIExamples.ScrollBar.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.ScrollBar.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.ScrollBar.UiBinding do
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
      domain: AshUIExamples.ScrollBar.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.ScrollBar.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.ScrollBar.UiScreen do
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
      resource(AshUIExamples.ScrollBar.Examples.ScrollBarScreen)
      resource(AshUIExamples.ScrollBar.Examples.ScrollBarDemoPanelElement)
      resource(AshUIExamples.ScrollBar.Examples.ScrollBarSubjectElement)
      resource(AshUIExamples.ScrollBar.Examples.ScrollBarPreviewElement)
      resource(AshUIExamples.ScrollBar.Examples.ScrollBarStoryTextElement)
      resource(AshUIExamples.ScrollBar.Examples.ScrollBarSignalTextElement)
      resource(AshUIExamples.ScrollBar.Examples.ScrollBarSupportNoticeElement)
      resource(AshUIExamples.ScrollBar.Examples.ScrollBarScrollFocusCopyElement)
      resource(AshUIExamples.ScrollBar.Examples.ScrollBarQueueScrollButtonElement)
      resource(AshUIExamples.ScrollBar.Examples.ScrollBarEscalationsScrollButtonElement)
      resource(AshUIExamples.ScrollBar.Examples.ScrollBarHandoffScrollButtonElement)
      resource(AshUIExamples.ScrollBar.Examples.ScrollBarScrollStatusElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.ScrollBar.AuthoringDomain,
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

  defmodule Examples.ScrollBarDemoPanelElement do
    use AshUIExamples.ScrollBar.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.ScrollBar.Examples.ScrollBarSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.ScrollBar.Examples.ScrollBarPreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices, AshUIExamples.ScrollBar.Examples.ScrollBarSupportNoticeElement do
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
      props(%{title: "Scroll Bar Example", class: "ashui-example-panel"})
      metadata(%{id: "example-scroll_bar-demo", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.ScrollBarSubjectElement do
    use AshUIExamples.ScrollBar.ExampleElementBase

    relationships do
      has_many :scroll_focus_copy_elements,
               AshUIExamples.ScrollBar.Examples.ScrollBarScrollFocusCopyElement do
        destination_attribute(:parent_id)
      end

      has_many :queue_scroll_button_elements,
               AshUIExamples.ScrollBar.Examples.ScrollBarQueueScrollButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :escalations_scroll_button_elements,
               AshUIExamples.ScrollBar.Examples.ScrollBarEscalationsScrollButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :handoff_scroll_button_elements,
               AshUIExamples.ScrollBar.Examples.ScrollBarHandoffScrollButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :scroll_status_elements,
               AshUIExamples.ScrollBar.Examples.ScrollBarScrollStatusElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :scroll_focus_copy_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :queue_scroll_button_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :escalations_scroll_button_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end

      relationship :handoff_scroll_button_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(30)
      end

      relationship :scroll_status_elements do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:scroll_bar")

      props(%{
        description:
          "Nested public buttons shift the focused lane while the outer custom shell owns the larger scroll-track surface only.",
        title: "Lane scroll",
        class: "ashui-example-scroll-bar-shell",
        thumb_label: "queue lane"
      })

      metadata(%{id: "example-scroll_bar-subject", section: "demo", slot: "body", position: 1})
    end

    ui_bindings do
      binding :scroll_thumb_focus do
        source(%{resource: "ExampleState", field: :selected_value, id: "state-scroll_bar"})
        target("thumb_label")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "subject", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.ScrollBarScrollFocusCopyElement do
    use AshUIExamples.ScrollBar.ExampleElementBase

    ui_element do
      type(:text)

      props(%{class: "ashui-example-surface-copy", content: "queue lane"})

      metadata(%{id: "scroll-focus-copy", position: 0, slot: "body", section: "demo"})
    end

    ui_bindings do
      binding :scroll_focus_copy_binding do
        source(%{id: "state-scroll_bar", resource: "ExampleState", field: :selected_value})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "body"})
      end
    end
  end

  defmodule Examples.ScrollBarQueueScrollButtonElement do
    use AshUIExamples.ScrollBar.ExampleElementBase

    ui_element do
      type(:button)

      props(%{label: "Queue lane", class: "ashui-example-nav-button", variant: "secondary"})

      metadata(%{id: "queue-scroll-button", position: 10, slot: "body", section: "demo"})
    end

    ui_actions do
      action :focus_queue_thumb do
        signal(:click)
        source(%{id: "state-scroll_bar", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Queue lane aligned with the scroll thumb."
            },
            selected_value: %{"from" => "static", "value" => "queue lane"}
          }
        })

        metadata(%{intent: "select_display_surface", success_message: "Selection updated"})
      end
    end
  end

  defmodule Examples.ScrollBarEscalationsScrollButtonElement do
    use AshUIExamples.ScrollBar.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Escalations lane",
        class: "ashui-example-nav-button",
        variant: "secondary"
      })

      metadata(%{id: "escalations-scroll-button", position: 20, slot: "body", section: "demo"})
    end

    ui_actions do
      action :focus_escalations_thumb do
        signal(:click)
        source(%{id: "state-scroll_bar", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Escalations lane aligned with the scroll thumb."
            },
            selected_value: %{"from" => "static", "value" => "escalations lane"}
          }
        })

        metadata(%{intent: "select_display_surface", success_message: "Selection updated"})
      end
    end
  end

  defmodule Examples.ScrollBarHandoffScrollButtonElement do
    use AshUIExamples.ScrollBar.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Handoff lane",
        class: "ashui-example-nav-button",
        variant: "secondary"
      })

      metadata(%{id: "handoff-scroll-button", position: 30, slot: "body", section: "demo"})
    end

    ui_actions do
      action :focus_handoff_thumb do
        signal(:click)
        source(%{id: "state-scroll_bar", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Handoff lane aligned with the scroll thumb."
            },
            selected_value: %{"from" => "static", "value" => "handoff lane"}
          }
        })

        metadata(%{intent: "select_display_surface", success_message: "Selection updated"})
      end
    end
  end

  defmodule Examples.ScrollBarScrollStatusElement do
    use AshUIExamples.ScrollBar.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        class: "ashui-example-surface-meta",
        content: "Scroll focus stays local to nested public controls."
      })

      metadata(%{id: "scroll-status", position: 0, slot: "footer", section: "demo"})
    end

    ui_bindings do
      binding :scroll_status_binding do
        source(%{id: "state-scroll_bar", resource: "ExampleState", field: :status})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "footer"})
      end
    end
  end

  defmodule Examples.ScrollBarPreviewElement do
    use AshUIExamples.ScrollBar.ExampleElementBase

    ui_element do
      type(:stat)
      props(%{title: "Thumb focus", value: "queue lane"})
      variants([:primary])
      metadata(%{id: "example-scroll_bar-preview", section: "demo", slot: "body", position: 2})
    end

    ui_bindings do
      binding :preview_value do
        source(%{resource: "ExampleState", field: :selected_value, id: "state-scroll_bar"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.ScrollBarStoryTextElement do
    use AshUIExamples.ScrollBar.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: change the scroll focus through nested public buttons and confirm the thumb label plus status copy update without turning `scroll_bar` into an admitted public widget.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "example-scroll_bar-story", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.ScrollBarSignalTextElement do
    use AshUIExamples.ScrollBar.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: nested button click -> ExampleState.selected_value -> thumb label binding, body copy, and preview stat.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-scroll_bar-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.ScrollBarSupportNoticeElement do
    use AshUIExamples.ScrollBar.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The `scroll_bar` example keeps focus changes on nested public buttons while the thumb itself is driven through a subject-level binding.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{
        id: "example-scroll_bar-support-note",
        section: "demo",
        slot: "body",
        position: 3
      })
    end
  end

  defmodule Examples.ScrollBarScreen do
    use Ash.Resource,
      domain: AshUIExamples.ScrollBar.AuthoringDomain,
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
      has_many :demo_panels, AshUIExamples.ScrollBar.Examples.ScrollBarDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUIExamples.ScrollBar.Examples.ScrollBarStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUIExamples.ScrollBar.Examples.ScrollBarSignalTextElement do
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
        title: "Scroll Bar Example",
        example_directory: "scroll_bar",
        shell_id: "example-scroll_bar-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.ScrollBar.seed!(opts)
    def reset!, do: AshUIExamples.ScrollBar.reset!()
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

    scope "/", AshUIExamples.ScrollBar.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_scroll_bar

    @session_options [
      store: :cookie,
      key: "_ash_ui_example_key",
      signing_salt: "ashuiph19"
    ]

    socket("/live", Phoenix.LiveView.Socket,
      websocket: [connect_info: [session: @session_options]]
    )

    plug(Plug.RequestId)
    plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])
    plug(Plug.Session, @session_options)
    plug(AshUIExamples.ScrollBar.Web.Router)
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

    alias AshUIExamples.ScrollBar.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.ScrollBar.seed!()

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.ScrollBar.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.ScrollBar.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUIExamples.ScrollBar.runtime_domains())
        |> Phoenix.Component.assign(:page_title, "Scroll Bar Example")
        |> Phoenix.Component.assign(:example_directory, "scroll_bar")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.ScrollBar.theme_css())

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/scroll_bar", params),
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
        summary={"Meaningful Interaction Story: change the scroll focus through nested public buttons and confirm the thumb label plus status copy update without turning `scroll_bar` into an admitted public widget."}
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
        AshUIExamples.ScrollBar.rendered_ui(socket.assigns)
      )
    end
  end
end
