defmodule AshUIExamples.Canvas do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `canvas` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.LiveUIAdapter
  alias AshUI.Resource.Authority

  @directory "canvas"
  @screen_name "example/canvas"
  @definition %{
    directory: "canvas",
    family: :display,
    title: "Canvas Example",
    section: :display_systems,
    subject_type: :"custom:canvas",
    subject_props: %{
      description:
        "Toolbar controls and legend copy stay in related child resources while the board remains an explicit custom display surface.",
      title: "Response canvas",
      class: "ashui-example-canvas-shell"
    },
    story_text:
      "Meaningful Interaction Story: switch the active layer from the toolbar and confirm the board plus legend update through nested public controls while the canvas shell remains explicit.",
    signal_text:
      "Canonical Signal Preview: nested button click -> ExampleState.selected_value -> canvas board copy, legend status, and preview stat.",
    seed_state: %{
      id: "state-canvas",
      status: "Canvas layer selection stays local to nested public controls.",
      selected_value: "incident map"
    },
    preview_field: :selected_value,
    preview_title: "Active layer",
    subject_binding: nil,
    subject_action: nil,
    subject_children: [
      %{
        position: 0,
        type: :button,
        slot: :toolbar,
        key: :incident_map_button,
        children: [],
        props: %{
          label: "Incident map",
          class: "ashui-example-command-button",
          variant: "secondary"
        },
        actions: [
          %{
            id: :select_incident_map_layer,
            metadata: %{
              intent: "select_display_surface",
              success_message: "Selection updated"
            },
            signal: :click,
            source: %{
              id: "state-canvas",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Incident map layer selected on the canvas."
                },
                selected_value: %{"from" => "static", "value" => "incident map"}
              }
            }
          }
        ]
      },
      %{
        position: 10,
        type: :button,
        slot: :toolbar,
        key: :handoff_path_button,
        children: [],
        props: %{
          label: "Handoff path",
          class: "ashui-example-command-button",
          variant: "secondary"
        },
        actions: [
          %{
            id: :select_handoff_path_layer,
            metadata: %{
              intent: "select_display_surface",
              success_message: "Selection updated"
            },
            signal: :click,
            source: %{
              id: "state-canvas",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Handoff path layer selected on the canvas."
                },
                selected_value: %{"from" => "static", "value" => "handoff path"}
              }
            }
          }
        ]
      },
      %{
        position: 0,
        type: :text,
        slot: :body,
        bindings: [
          %{
            id: :canvas_active_layer_binding,
            metadata: %{owner: "body"},
            source: %{
              id: "state-canvas",
              resource: "ExampleState",
              field: :selected_value
            },
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :canvas_active_layer,
        children: [],
        props: %{class: "ashui-example-surface-copy", content: "incident map"}
      },
      %{
        position: 10,
        type: :text,
        slot: :body,
        key: :canvas_board_copy,
        children: [],
        props: %{
          class: "ashui-example-surface-meta",
          content:
            "The board stays intentionally sparse so the authored layer relationship remains readable."
        }
      },
      %{
        position: 0,
        type: :text,
        slot: :legend,
        bindings: [
          %{
            id: :canvas_status_binding,
            metadata: %{owner: "legend"},
            source: %{
              id: "state-canvas",
              resource: "ExampleState",
              field: :status
            },
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :canvas_status,
        children: [],
        props: %{
          class: "ashui-example-surface-meta",
          content: "Canvas layer selection stays local to nested public controls."
        }
      }
    ],
    support_notice:
      "The `canvas` example keeps toolbar controls and legend updates on related child resources while the board remains an explicit `custom:canvas` surface.",
    notes: "Uses explicit toolbar, body, and legend slots."
  }
  @theme_css File.read!(Path.expand("../../assets/css/app.css", __DIR__))

  def app, do: :ash_ui_example_canvas
  def definition, do: @definition
  def title, do: @definition.title
  def theme_css, do: @theme_css
  def screen_name, do: @screen_name

  def ui_storage do
    [
      domain: AshUIExamples.Canvas.UiStorageDomain,
      resources: [
        screen: AshUIExamples.Canvas.UiScreen,
        element: AshUIExamples.Canvas.UiElement,
        binding: AshUIExamples.Canvas.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.Canvas.RuntimeDomain]

  def current_user,
    do: %{active: true, id: "reviewer-canvas", name: "Example Reviewer", role: :admin}

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
        id: "state-canvas",
        status: "Canvas layer selection stays local to nested public controls.",
        selected_value: "incident map"
      }
    )
  end

  def reset! do
    reset_resource!(AshUIExamples.Canvas.Runtime.ExampleState, AshUIExamples.Canvas.RuntimeDomain)
    reset_resource!(AshUIExamples.Canvas.UiBinding, AshUIExamples.Canvas.UiStorageDomain)
    reset_resource!(AshUIExamples.Canvas.UiElement, AshUIExamples.Canvas.UiStorageDomain)
    reset_resource!(AshUIExamples.Canvas.UiScreen, AshUIExamples.Canvas.UiStorageDomain)
    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.Canvas.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.Canvas.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.Canvas.Examples.CanvasScreen,
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
        {Phoenix.PubSub, name: AshUIExamples.Canvas.PubSub},
        AshUIExamples.Canvas.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.Canvas.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    use Ash.Resource, domain: AshUIExamples.Canvas.RuntimeDomain, data_layer: Ash.DataLayer.Ets

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
      resource(AshUIExamples.Canvas.UiScreen)
      resource(AshUIExamples.Canvas.UiElement)
      resource(AshUIExamples.Canvas.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.Canvas.UiStorageDomain,
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
      has_many :elements, AshUIExamples.Canvas.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.Canvas.UiBinding do
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
      domain: AshUIExamples.Canvas.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.Canvas.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.Canvas.UiBinding do
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
      domain: AshUIExamples.Canvas.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.Canvas.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.Canvas.UiScreen do
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
      resource(AshUIExamples.Canvas.Examples.CanvasScreen)
      resource(AshUIExamples.Canvas.Examples.CanvasDemoPanelElement)
      resource(AshUIExamples.Canvas.Examples.CanvasSubjectElement)
      resource(AshUIExamples.Canvas.Examples.CanvasPreviewElement)
      resource(AshUIExamples.Canvas.Examples.CanvasStoryTextElement)
      resource(AshUIExamples.Canvas.Examples.CanvasSignalTextElement)
      resource(AshUIExamples.Canvas.Examples.CanvasSupportNoticeElement)
      resource(AshUIExamples.Canvas.Examples.CanvasIncidentMapButtonElement)
      resource(AshUIExamples.Canvas.Examples.CanvasHandoffPathButtonElement)
      resource(AshUIExamples.Canvas.Examples.CanvasCanvasActiveLayerElement)
      resource(AshUIExamples.Canvas.Examples.CanvasCanvasBoardCopyElement)
      resource(AshUIExamples.Canvas.Examples.CanvasCanvasStatusElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.Canvas.AuthoringDomain,
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

  defmodule Examples.CanvasDemoPanelElement do
    use AshUIExamples.Canvas.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.Canvas.Examples.CanvasSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.Canvas.Examples.CanvasPreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices, AshUIExamples.Canvas.Examples.CanvasSupportNoticeElement do
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
      props(%{title: "Canvas Example", class: "ashui-example-panel"})
      metadata(%{id: "example-canvas-demo", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.CanvasSubjectElement do
    use AshUIExamples.Canvas.ExampleElementBase

    relationships do
      has_many :incident_map_button_elements,
               AshUIExamples.Canvas.Examples.CanvasIncidentMapButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :handoff_path_button_elements,
               AshUIExamples.Canvas.Examples.CanvasHandoffPathButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :canvas_active_layer_elements,
               AshUIExamples.Canvas.Examples.CanvasCanvasActiveLayerElement do
        destination_attribute(:parent_id)
      end

      has_many :canvas_board_copy_elements,
               AshUIExamples.Canvas.Examples.CanvasCanvasBoardCopyElement do
        destination_attribute(:parent_id)
      end

      has_many :canvas_status_elements, AshUIExamples.Canvas.Examples.CanvasCanvasStatusElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :incident_map_button_elements do
        kind(:child)
        slot(:toolbar)
        placement(:append)
        order(0)
      end

      relationship :handoff_path_button_elements do
        kind(:child)
        slot(:toolbar)
        placement(:append)
        order(10)
      end

      relationship :canvas_active_layer_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :canvas_board_copy_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :canvas_status_elements do
        kind(:child)
        slot(:legend)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:canvas")

      props(%{
        description:
          "Toolbar controls and legend copy stay in related child resources while the board remains an explicit custom display surface.",
        title: "Response canvas",
        class: "ashui-example-canvas-shell"
      })

      metadata(%{id: "example-canvas-subject", section: "demo", slot: "body", position: 1})
    end
  end

  defmodule Examples.CanvasIncidentMapButtonElement do
    use AshUIExamples.Canvas.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Incident map",
        class: "ashui-example-command-button",
        variant: "secondary"
      })

      metadata(%{id: "incident-map-button", position: 0, slot: "toolbar", section: "demo"})
    end

    ui_actions do
      action :select_incident_map_layer do
        signal(:click)
        source(%{id: "state-canvas", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Incident map layer selected on the canvas."
            },
            selected_value: %{"from" => "static", "value" => "incident map"}
          }
        })

        metadata(%{intent: "select_display_surface", success_message: "Selection updated"})
      end
    end
  end

  defmodule Examples.CanvasHandoffPathButtonElement do
    use AshUIExamples.Canvas.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Handoff path",
        class: "ashui-example-command-button",
        variant: "secondary"
      })

      metadata(%{id: "handoff-path-button", position: 10, slot: "toolbar", section: "demo"})
    end

    ui_actions do
      action :select_handoff_path_layer do
        signal(:click)
        source(%{id: "state-canvas", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Handoff path layer selected on the canvas."
            },
            selected_value: %{"from" => "static", "value" => "handoff path"}
          }
        })

        metadata(%{intent: "select_display_surface", success_message: "Selection updated"})
      end
    end
  end

  defmodule Examples.CanvasCanvasActiveLayerElement do
    use AshUIExamples.Canvas.ExampleElementBase

    ui_element do
      type(:text)

      props(%{class: "ashui-example-surface-copy", content: "incident map"})

      metadata(%{id: "canvas-active-layer", position: 0, slot: "body", section: "demo"})
    end

    ui_bindings do
      binding :canvas_active_layer_binding do
        source(%{id: "state-canvas", resource: "ExampleState", field: :selected_value})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "body"})
      end
    end
  end

  defmodule Examples.CanvasCanvasBoardCopyElement do
    use AshUIExamples.Canvas.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        class: "ashui-example-surface-meta",
        content:
          "The board stays intentionally sparse so the authored layer relationship remains readable."
      })

      metadata(%{id: "canvas-board-copy", position: 10, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.CanvasCanvasStatusElement do
    use AshUIExamples.Canvas.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        class: "ashui-example-surface-meta",
        content: "Canvas layer selection stays local to nested public controls."
      })

      metadata(%{id: "canvas-status", position: 0, slot: "legend", section: "demo"})
    end

    ui_bindings do
      binding :canvas_status_binding do
        source(%{id: "state-canvas", resource: "ExampleState", field: :status})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "legend"})
      end
    end
  end

  defmodule Examples.CanvasPreviewElement do
    use AshUIExamples.Canvas.ExampleElementBase

    ui_element do
      type(:stat)
      props(%{title: "Active layer", value: "incident map"})
      variants([:primary])
      metadata(%{id: "example-canvas-preview", section: "demo", slot: "body", position: 2})
    end

    ui_bindings do
      binding :preview_value do
        source(%{resource: "ExampleState", field: :selected_value, id: "state-canvas"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.CanvasStoryTextElement do
    use AshUIExamples.Canvas.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: switch the active layer from the toolbar and confirm the board plus legend update through nested public controls while the canvas shell remains explicit.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "example-canvas-story", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.CanvasSignalTextElement do
    use AshUIExamples.Canvas.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: nested button click -> ExampleState.selected_value -> canvas board copy, legend status, and preview stat.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-canvas-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.CanvasSupportNoticeElement do
    use AshUIExamples.Canvas.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The `canvas` example keeps toolbar controls and legend updates on related child resources while the board remains an explicit `custom:canvas` surface.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{id: "example-canvas-support-note", section: "demo", slot: "body", position: 3})
    end
  end

  defmodule Examples.CanvasScreen do
    use Ash.Resource,
      domain: AshUIExamples.Canvas.AuthoringDomain,
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
      has_many :demo_panels, AshUIExamples.Canvas.Examples.CanvasDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUIExamples.Canvas.Examples.CanvasStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUIExamples.Canvas.Examples.CanvasSignalTextElement do
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
        title: "Canvas Example",
        example_directory: "canvas",
        shell_id: "example-canvas-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.Canvas.seed!(opts)
    def reset!, do: AshUIExamples.Canvas.reset!()
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

    scope "/", AshUIExamples.Canvas.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_canvas

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
    plug(AshUIExamples.Canvas.Web.Router)
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

    alias AshUIExamples.Canvas.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.Canvas.seed!()

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.Canvas.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.Canvas.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUIExamples.Canvas.runtime_domains())
        |> Phoenix.Component.assign(:page_title, "Canvas Example")
        |> Phoenix.Component.assign(:example_directory, "canvas")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.Canvas.theme_css())

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/canvas", params),
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
        summary={"Meaningful Interaction Story: switch the active layer from the toolbar and confirm the board plus legend update through nested public controls while the canvas shell remains explicit."}
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
        AshUIExamples.Canvas.rendered_ui(socket.assigns)
      )
    end
  end
end
