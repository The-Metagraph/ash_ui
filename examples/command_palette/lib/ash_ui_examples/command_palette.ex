defmodule AshUIExamples.CommandPalette do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `command_palette` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.LiveUIAdapter
  alias AshUI.Resource.Authority

  @directory "command_palette"
  @screen_name "example/command_palette"
  @definition %{
    directory: "command_palette",
    family: :navigation,
    title: "Command Palette Example",
    story_text:
      "Meaningful Interaction Story: change the query and execute a command to confirm the example keeps both the input and the actions on nested public child resources while the shell remains explicit.",
    signal_text:
      "Canonical Signal Preview: input change -> ExampleState.current_value; nested button click -> ExampleState.submitted_value and ExampleState.status.",
    preview_field: :submitted_value,
    seed_state: %{
      id: "state-command_palette",
      status: "Command execution stays local to nested public controls.",
      submitted_value: "triage alerts",
      current_value: "open alerts"
    },
    support_notice:
      "The `command_palette` example keeps query changes and command execution on nested public input/button resources instead of claiming a public palette widget.",
    subject_children: [
      %{
        position: 0,
        type: :input,
        slot: :search,
        bindings: [
          %{
            id: :palette_query,
            metadata: %{owner: "input", owner_signal: "change"},
            source: %{
              id: "state-command_palette",
              resource: "ExampleState",
              field: :current_value
            },
            target: "query",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :palette_query_input,
        children: [],
        props: %{
          name: "query",
          type: "text",
          value: "open alerts",
          placeholder: "Search commands",
          class: "ashui-example-input"
        }
      },
      %{
        position: 0,
        type: :button,
        slot: :body,
        key: :triage_command_button,
        children: [],
        actions: [
          %{
            id: :run_triage_command,
            metadata: %{
              intent: "run_command",
              success_message: "Command executed"
            },
            signal: :click,
            source: %{
              id: "state-command_palette",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Triage command executed."
                },
                submitted_value: %{"from" => "binding", "key" => "query"}
              }
            }
          }
        ],
        props: %{
          label: "Run triage",
          class: "ashui-example-command-button",
          variant: "primary"
        }
      },
      %{
        position: 10,
        type: :button,
        slot: :body,
        key: :handoff_command_button,
        children: [],
        actions: [
          %{
            id: :run_handoff_command,
            metadata: %{
              intent: "run_command",
              success_message: "Command executed"
            },
            signal: :click,
            source: %{
              id: "state-command_palette",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Handoff command executed."
                },
                submitted_value: %{"from" => "binding", "key" => "query"}
              }
            }
          }
        ],
        props: %{
          label: "Prepare handoff",
          class: "ashui-example-command-button",
          variant: "primary"
        }
      },
      %{
        position: 0,
        type: :text,
        slot: :footer,
        bindings: [
          %{
            id: :command_palette_result,
            metadata: %{owner: "footer"},
            source: %{
              id: "state-command_palette",
              resource: "ExampleState",
              field: :submitted_value
            },
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :command_result,
        children: [],
        props: %{content: "triage alerts", class: "ashui-example-surface-meta"}
      }
    ],
    section: :layout_navigation,
    subject_action: nil,
    subject_binding: nil,
    subject_type: :"custom:command_palette",
    notes: "Uses a dedicated example-only custom shell with nested public controls.",
    preview_title: "Last command run",
    subject_props: %{
      description:
        "Search input and command actions stay public children inside an explicit custom palette shell.",
      title: "Command palette",
      class: "ashui-example-command-palette-shell"
    }
  }
  @theme_css File.read!(Path.expand("../../assets/css/app.css", __DIR__))

  def app, do: :ash_ui_example_command_palette
  def definition, do: @definition
  def title, do: @definition.title
  def theme_css, do: @theme_css
  def screen_name, do: @screen_name

  def ui_storage do
    [
      domain: AshUIExamples.CommandPalette.UiStorageDomain,
      resources: [
        screen: AshUIExamples.CommandPalette.UiScreen,
        element: AshUIExamples.CommandPalette.UiElement,
        binding: AshUIExamples.CommandPalette.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.CommandPalette.RuntimeDomain]

  def current_user,
    do: %{
      active: true,
      id: "reviewer-command_palette",
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
        id: "state-command_palette",
        status: "Command execution stays local to nested public controls.",
        submitted_value: "triage alerts",
        current_value: "open alerts"
      }
    )
  end

  def reset! do
    reset_resource!(
      AshUIExamples.CommandPalette.Runtime.ExampleState,
      AshUIExamples.CommandPalette.RuntimeDomain
    )

    reset_resource!(
      AshUIExamples.CommandPalette.UiBinding,
      AshUIExamples.CommandPalette.UiStorageDomain
    )

    reset_resource!(
      AshUIExamples.CommandPalette.UiElement,
      AshUIExamples.CommandPalette.UiStorageDomain
    )

    reset_resource!(
      AshUIExamples.CommandPalette.UiScreen,
      AshUIExamples.CommandPalette.UiStorageDomain
    )

    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.CommandPalette.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.CommandPalette.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.CommandPalette.Examples.CommandPaletteScreen,
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
        {Phoenix.PubSub, name: AshUIExamples.CommandPalette.PubSub},
        AshUIExamples.CommandPalette.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.CommandPalette.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    use Ash.Resource,
      domain: AshUIExamples.CommandPalette.RuntimeDomain,
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
      resource(AshUIExamples.CommandPalette.UiScreen)
      resource(AshUIExamples.CommandPalette.UiElement)
      resource(AshUIExamples.CommandPalette.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.CommandPalette.UiStorageDomain,
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
      has_many :elements, AshUIExamples.CommandPalette.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.CommandPalette.UiBinding do
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
      domain: AshUIExamples.CommandPalette.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.CommandPalette.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.CommandPalette.UiBinding do
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
      domain: AshUIExamples.CommandPalette.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.CommandPalette.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.CommandPalette.UiScreen do
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
      resource(AshUIExamples.CommandPalette.Examples.CommandPaletteScreen)
      resource(AshUIExamples.CommandPalette.Examples.CommandPaletteDemoPanelElement)
      resource(AshUIExamples.CommandPalette.Examples.CommandPaletteSubjectElement)
      resource(AshUIExamples.CommandPalette.Examples.CommandPalettePreviewElement)
      resource(AshUIExamples.CommandPalette.Examples.CommandPaletteStoryTextElement)
      resource(AshUIExamples.CommandPalette.Examples.CommandPaletteSignalTextElement)
      resource(AshUIExamples.CommandPalette.Examples.CommandPaletteSupportNoticeElement)
      resource(AshUIExamples.CommandPalette.Examples.CommandPalettePaletteQueryInputElement)
      resource(AshUIExamples.CommandPalette.Examples.CommandPaletteTriageCommandButtonElement)
      resource(AshUIExamples.CommandPalette.Examples.CommandPaletteHandoffCommandButtonElement)
      resource(AshUIExamples.CommandPalette.Examples.CommandPaletteCommandResultElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.CommandPalette.AuthoringDomain,
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

  defmodule Examples.CommandPaletteDemoPanelElement do
    use AshUIExamples.CommandPalette.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.CommandPalette.Examples.CommandPaletteSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.CommandPalette.Examples.CommandPalettePreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices,
               AshUIExamples.CommandPalette.Examples.CommandPaletteSupportNoticeElement do
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
      props(%{title: "Command Palette Example", class: "ashui-example-panel"})
      metadata(%{id: "example-command_palette-demo", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.CommandPaletteSubjectElement do
    use AshUIExamples.CommandPalette.ExampleElementBase

    relationships do
      has_many :palette_query_input_elements,
               AshUIExamples.CommandPalette.Examples.CommandPalettePaletteQueryInputElement do
        destination_attribute(:parent_id)
      end

      has_many :triage_command_button_elements,
               AshUIExamples.CommandPalette.Examples.CommandPaletteTriageCommandButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :handoff_command_button_elements,
               AshUIExamples.CommandPalette.Examples.CommandPaletteHandoffCommandButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :command_result_elements,
               AshUIExamples.CommandPalette.Examples.CommandPaletteCommandResultElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :palette_query_input_elements do
        kind(:child)
        slot(:search)
        placement(:append)
        order(0)
      end

      relationship :triage_command_button_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :handoff_command_button_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :command_result_elements do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:command_palette")

      props(%{
        description:
          "Search input and command actions stay public children inside an explicit custom palette shell.",
        title: "Command palette",
        class: "ashui-example-command-palette-shell"
      })

      metadata(%{
        id: "example-command_palette-subject",
        section: "demo",
        slot: "body",
        position: 1
      })
    end
  end

  defmodule Examples.CommandPalettePaletteQueryInputElement do
    use AshUIExamples.CommandPalette.ExampleElementBase

    ui_element do
      type(:input)

      props(%{
        name: "query",
        type: "text",
        value: "open alerts",
        placeholder: "Search commands",
        class: "ashui-example-input"
      })

      metadata(%{id: "palette-query-input", position: 0, slot: "search", section: "demo"})
    end

    ui_bindings do
      binding :palette_query do
        source(%{id: "state-command_palette", resource: "ExampleState", field: :current_value})
        target("query")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "input", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.CommandPaletteTriageCommandButtonElement do
    use AshUIExamples.CommandPalette.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Run triage",
        class: "ashui-example-command-button",
        variant: "primary"
      })

      metadata(%{id: "triage-command-button", position: 0, slot: "body", section: "demo"})
    end

    ui_actions do
      action :run_triage_command do
        signal(:click)
        source(%{id: "state-command_palette", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{"from" => "static", "value" => "Triage command executed."},
            submitted_value: %{"from" => "binding", "key" => "query"}
          }
        })

        metadata(%{intent: "run_command", success_message: "Command executed"})
      end
    end
  end

  defmodule Examples.CommandPaletteHandoffCommandButtonElement do
    use AshUIExamples.CommandPalette.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Prepare handoff",
        class: "ashui-example-command-button",
        variant: "primary"
      })

      metadata(%{id: "handoff-command-button", position: 10, slot: "body", section: "demo"})
    end

    ui_actions do
      action :run_handoff_command do
        signal(:click)
        source(%{id: "state-command_palette", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{"from" => "static", "value" => "Handoff command executed."},
            submitted_value: %{"from" => "binding", "key" => "query"}
          }
        })

        metadata(%{intent: "run_command", success_message: "Command executed"})
      end
    end
  end

  defmodule Examples.CommandPaletteCommandResultElement do
    use AshUIExamples.CommandPalette.ExampleElementBase

    ui_element do
      type(:text)

      props(%{content: "triage alerts", class: "ashui-example-surface-meta"})

      metadata(%{id: "command-result", position: 0, slot: "footer", section: "demo"})
    end

    ui_bindings do
      binding :command_palette_result do
        source(%{
          id: "state-command_palette",
          resource: "ExampleState",
          field: :submitted_value
        })

        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "footer"})
      end
    end
  end

  defmodule Examples.CommandPalettePreviewElement do
    use AshUIExamples.CommandPalette.ExampleElementBase

    ui_element do
      type(:stat)
      props(%{title: "Last command run", value: "triage alerts"})
      variants([:primary])

      metadata(%{
        id: "example-command_palette-preview",
        section: "demo",
        slot: "body",
        position: 2
      })
    end

    ui_bindings do
      binding :preview_value do
        source(%{resource: "ExampleState", field: :submitted_value, id: "state-command_palette"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.CommandPaletteStoryTextElement do
    use AshUIExamples.CommandPalette.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: change the query and execute a command to confirm the example keeps both the input and the actions on nested public child resources while the shell remains explicit.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-command_palette-story",
        section: "story",
        slot: "body",
        position: 10
      })
    end
  end

  defmodule Examples.CommandPaletteSignalTextElement do
    use AshUIExamples.CommandPalette.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: input change -> ExampleState.current_value; nested button click -> ExampleState.submitted_value and ExampleState.status.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-command_palette-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.CommandPaletteSupportNoticeElement do
    use AshUIExamples.CommandPalette.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The `command_palette` example keeps query changes and command execution on nested public input/button resources instead of claiming a public palette widget.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{
        id: "example-command_palette-support-note",
        section: "demo",
        slot: "body",
        position: 3
      })
    end
  end

  defmodule Examples.CommandPaletteScreen do
    use Ash.Resource,
      domain: AshUIExamples.CommandPalette.AuthoringDomain,
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
               AshUIExamples.CommandPalette.Examples.CommandPaletteDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts,
               AshUIExamples.CommandPalette.Examples.CommandPaletteStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts,
               AshUIExamples.CommandPalette.Examples.CommandPaletteSignalTextElement do
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
        title: "Command Palette Example",
        example_directory: "command_palette",
        shell_id: "example-command_palette-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.CommandPalette.seed!(opts)
    def reset!, do: AshUIExamples.CommandPalette.reset!()
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

    scope "/", AshUIExamples.CommandPalette.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_command_palette

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
    plug(AshUIExamples.CommandPalette.Web.Router)
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

    alias AshUIExamples.CommandPalette.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.CommandPalette.seed!()

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.CommandPalette.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.CommandPalette.ui_storage())
        |> Phoenix.Component.assign(
          :ash_ui_domains,
          AshUIExamples.CommandPalette.runtime_domains()
        )
        |> Phoenix.Component.assign(:page_title, "Command Palette Example")
        |> Phoenix.Component.assign(:example_directory, "command_palette")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.CommandPalette.theme_css())

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/command_palette", params),
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
        summary={"Meaningful Interaction Story: change the query and execute a command to confirm the example keeps both the input and the actions on nested public child resources while the shell remains explicit."}
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
        AshUIExamples.CommandPalette.rendered_ui(socket.assigns)
      )
    end
  end
end
