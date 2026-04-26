defmodule AshUIExamples.Viewport do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `viewport` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.{DesktopUIAdapter, ElmUIAdapter, LiveUIAdapter}
  alias AshUI.Resource.Authority

  @directory "viewport"
  @screen_name "example/viewport"
  @definition %{
    directory: "viewport",
    family: :display,
    title: "Viewport Example",
    story_text:
      "Meaningful Interaction Story: change the focused lane from the viewport aside and confirm the larger display surface updates through nested public controls rather than a monolithic screen authority fragment.",
    signal_text:
      "Canonical Signal Preview: nested button click -> ExampleState.selected_value -> viewport body copy, footer status, and preview stat.",
    preview_field: :selected_value,
    seed_state: %{
      id: "state-viewport",
      status: "Viewport focus stays local to nested public controls.",
      selected_value: "queue lane"
    },
    support_notice:
      "The `viewport` example remains an explicit `custom:viewport` surface; the focus controls live on related child resources in the aside.",
    subject_children: [
      %{
        position: 0,
        type: :text,
        slot: :body,
        bindings: [
          %{
            id: :viewport_focus_copy_binding,
            metadata: %{owner: "body"},
            source: %{
              id: "state-viewport",
              resource: "ExampleState",
              field: :selected_value
            },
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :viewport_focus_copy,
        children: [],
        props: %{content: "queue lane", class: "ashui-example-surface-copy"}
      },
      %{
        position: 10,
        type: :card,
        slot: :body,
        key: :viewport_support_panel,
        children: [
          %{
            position: 0,
            type: :text,
            key: :viewport_support_panel_title,
            children: [],
            props: %{
              content: "Viewport support panel",
              class: "ashui-example-layout-title"
            }
          },
          %{
            position: 10,
            type: :text,
            key: :viewport_support_panel_detail,
            children: [],
            props: %{
              content:
                "The body keeps the current lane visible while adjacent controls stay in related child resources.",
              class: "ashui-example-layout-copy"
            }
          }
        ],
        props: %{class: "ashui-example-layout-card"}
      },
      %{
        position: 0,
        type: :button,
        slot: :aside,
        key: :queue_viewport_button,
        children: [],
        actions: [
          %{
            id: :focus_queue_lane,
            metadata: %{
              intent: "select_display_surface",
              success_message: "Selection updated"
            },
            signal: :click,
            source: %{
              id: "state-viewport",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Queue lane focused in the viewport."
                },
                selected_value: %{"from" => "static", "value" => "queue lane"}
              }
            }
          }
        ],
        props: %{
          label: "Queue lane",
          class: "ashui-example-nav-button",
          variant: "secondary"
        }
      },
      %{
        position: 10,
        type: :button,
        slot: :aside,
        key: :timeline_viewport_button,
        children: [],
        actions: [
          %{
            id: :focus_timeline_lane,
            metadata: %{
              intent: "select_display_surface",
              success_message: "Selection updated"
            },
            signal: :click,
            source: %{
              id: "state-viewport",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Timeline lane focused in the viewport."
                },
                selected_value: %{"from" => "static", "value" => "timeline lane"}
              }
            }
          }
        ],
        props: %{
          label: "Timeline lane",
          class: "ashui-example-nav-button",
          variant: "secondary"
        }
      },
      %{
        position: 20,
        type: :button,
        slot: :aside,
        key: :handoff_viewport_button,
        children: [],
        actions: [
          %{
            id: :focus_handoff_lane,
            metadata: %{
              intent: "select_display_surface",
              success_message: "Selection updated"
            },
            signal: :click,
            source: %{
              id: "state-viewport",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Handoff lane focused in the viewport."
                },
                selected_value: %{"from" => "static", "value" => "handoff lane"}
              }
            }
          }
        ],
        props: %{
          label: "Handoff lane",
          class: "ashui-example-nav-button",
          variant: "secondary"
        }
      },
      %{
        position: 0,
        type: :text,
        slot: :footer,
        bindings: [
          %{
            id: :viewport_status_binding,
            metadata: %{owner: "footer"},
            source: %{
              id: "state-viewport",
              resource: "ExampleState",
              field: :status
            },
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :viewport_status,
        children: [],
        props: %{
          content: "Viewport focus stays local to nested public controls.",
          class: "ashui-example-surface-meta"
        }
      }
    ],
    section: :display_systems,
    subject_action: nil,
    subject_binding: nil,
    subject_type: :"custom:viewport",
    notes: "Uses a dedicated example-only custom shell with bound body and footer text.",
    preview_title: "Focused lane",
    subject_props: %{
      description:
        "Nested public buttons in the aside move viewport focus while the larger shell stays explicit.",
      title: "Operations viewport",
      class: "ashui-example-viewport-shell"
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

  def app, do: :ash_ui_example_viewport
  def default_runtime, do: @default_runtime
  def definition, do: @definition

  def runtime_description(runtime),
    do: runtime |> normalize_runtime!() |> then(&Map.fetch!(@runtime_descriptions, &1))

  def supported_runtimes, do: @supported_runtimes
  def title, do: @definition.title
  def theme_css, do: @theme_css
  def screen_name, do: @screen_name

  def ui_storage do
    [
      domain: AshUIExamples.Viewport.UiStorageDomain,
      resources: [
        screen: AshUIExamples.Viewport.UiScreen,
        element: AshUIExamples.Viewport.UiElement,
        binding: AshUIExamples.Viewport.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.Viewport.RuntimeDomain]

  def current_user,
    do: %{active: true, id: "reviewer-viewport", name: "Example Reviewer", role: :admin}

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
        id: "state-viewport",
        status: "Viewport focus stays local to nested public controls.",
        selected_value: "queue lane"
      }
    )
  end

  def reset! do
    reset_resource!(
      AshUIExamples.Viewport.Runtime.ExampleState,
      AshUIExamples.Viewport.RuntimeDomain
    )

    reset_resource!(AshUIExamples.Viewport.UiBinding, AshUIExamples.Viewport.UiStorageDomain)
    reset_resource!(AshUIExamples.Viewport.UiElement, AshUIExamples.Viewport.UiStorageDomain)
    reset_resource!(AshUIExamples.Viewport.UiScreen, AshUIExamples.Viewport.UiStorageDomain)
    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.Viewport.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.Viewport.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.Viewport.Examples.ViewportScreen,
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
        {Phoenix.PubSub, name: AshUIExamples.Viewport.PubSub},
        AshUIExamples.Viewport.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.Viewport.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    use Ash.Resource, domain: AshUIExamples.Viewport.RuntimeDomain, data_layer: Ash.DataLayer.Ets

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
      resource(AshUIExamples.Viewport.UiScreen)
      resource(AshUIExamples.Viewport.UiElement)
      resource(AshUIExamples.Viewport.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.Viewport.UiStorageDomain,
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
      has_many :elements, AshUIExamples.Viewport.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.Viewport.UiBinding do
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
      domain: AshUIExamples.Viewport.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.Viewport.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.Viewport.UiBinding do
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
      domain: AshUIExamples.Viewport.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.Viewport.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.Viewport.UiScreen do
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
      resource(AshUIExamples.Viewport.Examples.ViewportScreen)
      resource(AshUIExamples.Viewport.Examples.ViewportDemoPanelElement)
      resource(AshUIExamples.Viewport.Examples.ViewportSubjectElement)
      resource(AshUIExamples.Viewport.Examples.ViewportPreviewElement)
      resource(AshUIExamples.Viewport.Examples.ViewportStoryTextElement)
      resource(AshUIExamples.Viewport.Examples.ViewportSignalTextElement)
      resource(AshUIExamples.Viewport.Examples.ViewportSupportNoticeElement)
      resource(AshUIExamples.Viewport.Examples.ViewportViewportFocusCopyElement)
      resource(AshUIExamples.Viewport.Examples.ViewportViewportSupportPanelElement)
      resource(AshUIExamples.Viewport.Examples.ViewportViewportSupportPanelTitleElement)
      resource(AshUIExamples.Viewport.Examples.ViewportViewportSupportPanelDetailElement)
      resource(AshUIExamples.Viewport.Examples.ViewportQueueViewportButtonElement)
      resource(AshUIExamples.Viewport.Examples.ViewportTimelineViewportButtonElement)
      resource(AshUIExamples.Viewport.Examples.ViewportHandoffViewportButtonElement)
      resource(AshUIExamples.Viewport.Examples.ViewportViewportStatusElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.Viewport.AuthoringDomain,
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

  defmodule Examples.ViewportDemoPanelElement do
    use AshUIExamples.Viewport.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.Viewport.Examples.ViewportSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.Viewport.Examples.ViewportPreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices, AshUIExamples.Viewport.Examples.ViewportSupportNoticeElement do
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
      props(%{title: "Viewport Example", class: "ashui-example-panel"})
      metadata(%{id: "example-viewport-demo", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.ViewportSubjectElement do
    use AshUIExamples.Viewport.ExampleElementBase

    relationships do
      has_many :viewport_focus_copy_elements,
               AshUIExamples.Viewport.Examples.ViewportViewportFocusCopyElement do
        destination_attribute(:parent_id)
      end

      has_many :viewport_support_panel_elements,
               AshUIExamples.Viewport.Examples.ViewportViewportSupportPanelElement do
        destination_attribute(:parent_id)
      end

      has_many :queue_viewport_button_elements,
               AshUIExamples.Viewport.Examples.ViewportQueueViewportButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :timeline_viewport_button_elements,
               AshUIExamples.Viewport.Examples.ViewportTimelineViewportButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :handoff_viewport_button_elements,
               AshUIExamples.Viewport.Examples.ViewportHandoffViewportButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :viewport_status_elements,
               AshUIExamples.Viewport.Examples.ViewportViewportStatusElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :viewport_focus_copy_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :viewport_support_panel_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :queue_viewport_button_elements do
        kind(:child)
        slot(:aside)
        placement(:append)
        order(0)
      end

      relationship :timeline_viewport_button_elements do
        kind(:child)
        slot(:aside)
        placement(:append)
        order(10)
      end

      relationship :handoff_viewport_button_elements do
        kind(:child)
        slot(:aside)
        placement(:append)
        order(20)
      end

      relationship :viewport_status_elements do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:viewport")

      props(%{
        description:
          "Nested public buttons in the aside move viewport focus while the larger shell stays explicit.",
        title: "Operations viewport",
        class: "ashui-example-viewport-shell"
      })

      metadata(%{id: "example-viewport-subject", section: "demo", slot: "body", position: 1})
    end
  end

  defmodule Examples.ViewportViewportFocusCopyElement do
    use AshUIExamples.Viewport.ExampleElementBase

    ui_element do
      type(:text)

      props(%{content: "queue lane", class: "ashui-example-surface-copy"})

      metadata(%{id: "viewport-focus-copy", position: 0, slot: "body", section: "demo"})
    end

    ui_bindings do
      binding :viewport_focus_copy_binding do
        source(%{id: "state-viewport", resource: "ExampleState", field: :selected_value})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "body"})
      end
    end
  end

  defmodule Examples.ViewportViewportSupportPanelElement do
    use AshUIExamples.Viewport.ExampleElementBase

    relationships do
      has_many :viewport_support_panel_title_elements,
               AshUIExamples.Viewport.Examples.ViewportViewportSupportPanelTitleElement do
        destination_attribute(:parent_id)
      end

      has_many :viewport_support_panel_detail_elements,
               AshUIExamples.Viewport.Examples.ViewportViewportSupportPanelDetailElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :viewport_support_panel_title_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :viewport_support_panel_detail_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:card)

      props(%{class: "ashui-example-layout-card"})

      metadata(%{id: "viewport-support-panel", position: 10, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.ViewportQueueViewportButtonElement do
    use AshUIExamples.Viewport.ExampleElementBase

    ui_element do
      type(:button)

      props(%{label: "Queue lane", class: "ashui-example-nav-button", variant: "secondary"})

      metadata(%{id: "queue-viewport-button", position: 0, slot: "aside", section: "demo"})
    end

    ui_actions do
      action :focus_queue_lane do
        signal(:click)
        source(%{id: "state-viewport", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Queue lane focused in the viewport."
            },
            selected_value: %{"from" => "static", "value" => "queue lane"}
          }
        })

        metadata(%{intent: "select_display_surface", success_message: "Selection updated"})
      end
    end
  end

  defmodule Examples.ViewportTimelineViewportButtonElement do
    use AshUIExamples.Viewport.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Timeline lane",
        class: "ashui-example-nav-button",
        variant: "secondary"
      })

      metadata(%{id: "timeline-viewport-button", position: 10, slot: "aside", section: "demo"})
    end

    ui_actions do
      action :focus_timeline_lane do
        signal(:click)
        source(%{id: "state-viewport", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Timeline lane focused in the viewport."
            },
            selected_value: %{"from" => "static", "value" => "timeline lane"}
          }
        })

        metadata(%{intent: "select_display_surface", success_message: "Selection updated"})
      end
    end
  end

  defmodule Examples.ViewportHandoffViewportButtonElement do
    use AshUIExamples.Viewport.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Handoff lane",
        class: "ashui-example-nav-button",
        variant: "secondary"
      })

      metadata(%{id: "handoff-viewport-button", position: 20, slot: "aside", section: "demo"})
    end

    ui_actions do
      action :focus_handoff_lane do
        signal(:click)
        source(%{id: "state-viewport", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Handoff lane focused in the viewport."
            },
            selected_value: %{"from" => "static", "value" => "handoff lane"}
          }
        })

        metadata(%{intent: "select_display_surface", success_message: "Selection updated"})
      end
    end
  end

  defmodule Examples.ViewportViewportStatusElement do
    use AshUIExamples.Viewport.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content: "Viewport focus stays local to nested public controls.",
        class: "ashui-example-surface-meta"
      })

      metadata(%{id: "viewport-status", position: 0, slot: "footer", section: "demo"})
    end

    ui_bindings do
      binding :viewport_status_binding do
        source(%{id: "state-viewport", resource: "ExampleState", field: :status})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "footer"})
      end
    end
  end

  defmodule Examples.ViewportViewportSupportPanelTitleElement do
    use AshUIExamples.Viewport.ExampleElementBase

    ui_element do
      type(:text)

      props(%{content: "Viewport support panel", class: "ashui-example-layout-title"})

      metadata(%{
        id: "viewport-support-panel-title",
        position: 0,
        slot: "body",
        section: "demo"
      })
    end
  end

  defmodule Examples.ViewportViewportSupportPanelDetailElement do
    use AshUIExamples.Viewport.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The body keeps the current lane visible while adjacent controls stay in related child resources.",
        class: "ashui-example-layout-copy"
      })

      metadata(%{
        id: "viewport-support-panel-detail",
        position: 10,
        slot: "body",
        section: "demo"
      })
    end
  end

  defmodule Examples.ViewportPreviewElement do
    use AshUIExamples.Viewport.ExampleElementBase

    ui_element do
      type(:stat)
      props(%{title: "Focused lane", value: "queue lane"})
      variants([:primary])
      metadata(%{id: "example-viewport-preview", section: "demo", slot: "body", position: 2})
    end

    ui_bindings do
      binding :preview_value do
        source(%{resource: "ExampleState", field: :selected_value, id: "state-viewport"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.ViewportStoryTextElement do
    use AshUIExamples.Viewport.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: change the focused lane from the viewport aside and confirm the larger display surface updates through nested public controls rather than a monolithic screen authority fragment.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "example-viewport-story", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.ViewportSignalTextElement do
    use AshUIExamples.Viewport.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: nested button click -> ExampleState.selected_value -> viewport body copy, footer status, and preview stat.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-viewport-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.ViewportSupportNoticeElement do
    use AshUIExamples.Viewport.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The `viewport` example remains an explicit `custom:viewport` surface; the focus controls live on related child resources in the aside.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{id: "example-viewport-support-note", section: "demo", slot: "body", position: 3})
    end
  end

  defmodule Examples.ViewportScreen do
    use Ash.Resource,
      domain: AshUIExamples.Viewport.AuthoringDomain,
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
      has_many :demo_panels, AshUIExamples.Viewport.Examples.ViewportDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUIExamples.Viewport.Examples.ViewportStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUIExamples.Viewport.Examples.ViewportSignalTextElement do
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
        title: "Viewport Example",
        example_directory: "viewport",
        shell_id: "example-viewport-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.Viewport.seed!(opts)
    def reset!, do: AshUIExamples.Viewport.reset!()
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

    scope "/", AshUIExamples.Viewport.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_viewport

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
    plug(AshUIExamples.Viewport.Web.Router)
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

    alias AshUIExamples.Viewport.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.Viewport.seed!()
      example_runtime = runtime_from_params(params)

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.Viewport.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.Viewport.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUIExamples.Viewport.runtime_domains())
        |> Phoenix.Component.assign(:page_title, "Viewport Example")
        |> Phoenix.Component.assign(:example_directory, "viewport")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.Viewport.theme_css())
        |> Phoenix.Component.assign(:example_runtime, example_runtime)
        |> Phoenix.Component.assign(
          :supported_runtimes,
          AshUIExamples.Viewport.supported_runtimes()
        )

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/viewport", params),
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
          AshUIExamples.Viewport.supported_runtimes()
        end)
        |> Phoenix.Component.assign_new(:example_runtime, fn ->
          AshUIExamples.Viewport.default_runtime()
        end)
        |> Phoenix.Component.assign_new(:rendered_runtime, fn ->
          %{
            content: assigns[:rendered_ui] || "",
            description:
              AshUIExamples.Viewport.runtime_description(AshUIExamples.Viewport.default_runtime()),
            mode: :live_fragment,
            runtime: AshUIExamples.Viewport.default_runtime()
          }
        end)

      ~H"""
      <ExampleShell.example_shell
        title={@page_title}
        directory={@example_directory}
        summary={"Meaningful Interaction Story: change the focused lane from the viewport aside and confirm the larger display surface updates through nested public controls rather than a monolithic screen authority fragment."}
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
        AshUIExamples.Viewport.rendered_runtime(
          socket.assigns,
          socket.assigns[:example_runtime] || AshUIExamples.Viewport.default_runtime()
        )

      socket
      |> Phoenix.Component.assign(:rendered_runtime, rendered_runtime)
      |> Phoenix.Component.assign(:rendered_ui, rendered_runtime.content)
    end

    defp runtime_from_params(params) do
      params["runtime"]
      |> fallback_runtime()
      |> AshUIExamples.Viewport.normalize_runtime!()
    end

    defp fallback_runtime(nil), do: System.get_env("ASH_UI_EXAMPLE_RUNTIME")
    defp fallback_runtime(runtime), do: runtime
  end
end
