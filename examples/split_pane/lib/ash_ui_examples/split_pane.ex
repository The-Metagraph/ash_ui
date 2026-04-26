defmodule AshUIExamples.SplitPane do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `split_pane` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.{DesktopUIAdapter, ElmUIAdapter, LiveUIAdapter}
  alias AshUI.Resource.Authority

  @directory "split_pane"
  @screen_name "example/split_pane"
  @definition %{
    directory: "split_pane",
    family: :display,
    title: "Split Pane Example",
    story_text:
      "Meaningful Interaction Story: move emphasis between split panes and confirm the active pane copy changes through nested public actions instead of screen-local imperative layout code.",
    signal_text:
      "Canonical Signal Preview: nested button click -> ExampleState.selected_value -> secondary pane copy, status text, and preview stat.",
    preview_field: :selected_value,
    seed_state: %{
      id: "state-split_pane",
      status: "Split-pane emphasis stays local to nested public controls.",
      selected_value: "details pane"
    },
    support_notice:
      "The `split_pane` example keeps pane emphasis and action ownership on related child resources instead of collapsing the whole layout into one screen fragment.",
    subject_children: [
      %{
        position: 0,
        type: :card,
        slot: :primary,
        key: :primary_review_panel,
        children: [
          %{
            position: 0,
            type: :text,
            key: :primary_review_panel_title,
            children: [],
            props: %{
              content: "Primary review panel",
              class: "ashui-example-layout-title"
            }
          },
          %{
            position: 10,
            type: :text,
            key: :primary_review_panel_detail,
            children: [],
            props: %{
              content:
                "The primary pane keeps the durable operational context visible at all times.",
              class: "ashui-example-layout-copy"
            }
          }
        ],
        props: %{class: "ashui-example-layout-card"}
      },
      %{
        position: 0,
        type: :text,
        slot: :secondary,
        bindings: [
          %{
            id: :secondary_focus_copy_binding,
            metadata: %{owner: "secondary"},
            source: %{
              id: "state-split_pane",
              resource: "ExampleState",
              field: :selected_value
            },
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :secondary_focus_copy,
        children: [],
        props: %{content: "details pane", class: "ashui-example-surface-copy"}
      },
      %{
        position: 10,
        type: :text,
        slot: :secondary,
        bindings: [
          %{
            id: :split_status_binding,
            metadata: %{owner: "secondary"},
            source: %{
              id: "state-split_pane",
              resource: "ExampleState",
              field: :status
            },
            target: "content",
            transform: %{},
            binding_type: :value
          }
        ],
        key: :split_status,
        children: [],
        props: %{
          content: "Split-pane emphasis stays local to nested public controls.",
          class: "ashui-example-surface-meta"
        }
      },
      %{
        position: 0,
        type: :button,
        slot: :actions,
        key: :details_pane_button,
        children: [],
        actions: [
          %{
            id: :select_details_pane,
            metadata: %{
              intent: "select_display_surface",
              success_message: "Selection updated"
            },
            signal: :click,
            source: %{
              id: "state-split_pane",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Details pane moved into focus."
                },
                selected_value: %{"from" => "static", "value" => "details pane"}
              }
            }
          }
        ],
        props: %{
          label: "Details pane",
          class: "ashui-example-command-button",
          variant: "secondary"
        }
      },
      %{
        position: 10,
        type: :button,
        slot: :actions,
        key: :handoff_pane_button,
        children: [],
        actions: [
          %{
            id: :select_handoff_pane,
            metadata: %{
              intent: "select_display_surface",
              success_message: "Selection updated"
            },
            signal: :click,
            source: %{
              id: "state-split_pane",
              resource: "ExampleState",
              action: "update"
            },
            target: "submit",
            transform: %{
              params: %{
                status: %{
                  "from" => "static",
                  "value" => "Handoff pane moved into focus."
                },
                selected_value: %{"from" => "static", "value" => "handoff pane"}
              }
            }
          }
        ],
        props: %{
          label: "Handoff pane",
          class: "ashui-example-command-button",
          variant: "secondary"
        }
      }
    ],
    section: :display_systems,
    subject_action: nil,
    subject_binding: nil,
    subject_type: :"custom:split_pane",
    notes: "Uses explicit primary, secondary, and actions slots.",
    preview_title: "Active pane",
    subject_props: %{
      description:
        "Primary and secondary panes stay in related child resources while footer actions switch the emphasized pane.",
      title: "Review split pane",
      class: "ashui-example-split-pane-shell"
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

  def app, do: :ash_ui_example_split_pane
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
      domain: AshUIExamples.SplitPane.UiStorageDomain,
      resources: [
        screen: AshUIExamples.SplitPane.UiScreen,
        element: AshUIExamples.SplitPane.UiElement,
        binding: AshUIExamples.SplitPane.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.SplitPane.RuntimeDomain]

  def current_user,
    do: %{
      active: true,
      id: "reviewer-split_pane",
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
        id: "state-split_pane",
        status: "Split-pane emphasis stays local to nested public controls.",
        selected_value: "details pane"
      }
    )
  end

  def reset! do
    reset_resource!(
      AshUIExamples.SplitPane.Runtime.ExampleState,
      AshUIExamples.SplitPane.RuntimeDomain
    )

    reset_resource!(AshUIExamples.SplitPane.UiBinding, AshUIExamples.SplitPane.UiStorageDomain)
    reset_resource!(AshUIExamples.SplitPane.UiElement, AshUIExamples.SplitPane.UiStorageDomain)
    reset_resource!(AshUIExamples.SplitPane.UiScreen, AshUIExamples.SplitPane.UiStorageDomain)
    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.SplitPane.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.SplitPane.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.SplitPane.Examples.SplitPaneScreen,
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
        {Phoenix.PubSub, name: AshUIExamples.SplitPane.PubSub},
        AshUIExamples.SplitPane.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.SplitPane.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    use Ash.Resource, domain: AshUIExamples.SplitPane.RuntimeDomain, data_layer: Ash.DataLayer.Ets

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
      resource(AshUIExamples.SplitPane.UiScreen)
      resource(AshUIExamples.SplitPane.UiElement)
      resource(AshUIExamples.SplitPane.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.SplitPane.UiStorageDomain,
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
      has_many :elements, AshUIExamples.SplitPane.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.SplitPane.UiBinding do
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
      domain: AshUIExamples.SplitPane.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.SplitPane.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.SplitPane.UiBinding do
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
      domain: AshUIExamples.SplitPane.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.SplitPane.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.SplitPane.UiScreen do
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
      resource(AshUIExamples.SplitPane.Examples.SplitPaneScreen)
      resource(AshUIExamples.SplitPane.Examples.SplitPaneDemoPanelElement)
      resource(AshUIExamples.SplitPane.Examples.SplitPaneSubjectElement)
      resource(AshUIExamples.SplitPane.Examples.SplitPanePreviewElement)
      resource(AshUIExamples.SplitPane.Examples.SplitPaneStoryTextElement)
      resource(AshUIExamples.SplitPane.Examples.SplitPaneSignalTextElement)
      resource(AshUIExamples.SplitPane.Examples.SplitPaneSupportNoticeElement)
      resource(AshUIExamples.SplitPane.Examples.SplitPanePrimaryReviewPanelElement)
      resource(AshUIExamples.SplitPane.Examples.SplitPanePrimaryReviewPanelTitleElement)
      resource(AshUIExamples.SplitPane.Examples.SplitPanePrimaryReviewPanelDetailElement)
      resource(AshUIExamples.SplitPane.Examples.SplitPaneSecondaryFocusCopyElement)
      resource(AshUIExamples.SplitPane.Examples.SplitPaneSplitStatusElement)
      resource(AshUIExamples.SplitPane.Examples.SplitPaneDetailsPaneButtonElement)
      resource(AshUIExamples.SplitPane.Examples.SplitPaneHandoffPaneButtonElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.SplitPane.AuthoringDomain,
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

  defmodule Examples.SplitPaneDemoPanelElement do
    use AshUIExamples.SplitPane.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.SplitPane.Examples.SplitPaneSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.SplitPane.Examples.SplitPanePreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices, AshUIExamples.SplitPane.Examples.SplitPaneSupportNoticeElement do
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
      props(%{title: "Split Pane Example", class: "ashui-example-panel"})
      metadata(%{id: "example-split_pane-demo", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.SplitPaneSubjectElement do
    use AshUIExamples.SplitPane.ExampleElementBase

    relationships do
      has_many :primary_review_panel_elements,
               AshUIExamples.SplitPane.Examples.SplitPanePrimaryReviewPanelElement do
        destination_attribute(:parent_id)
      end

      has_many :secondary_focus_copy_elements,
               AshUIExamples.SplitPane.Examples.SplitPaneSecondaryFocusCopyElement do
        destination_attribute(:parent_id)
      end

      has_many :split_status_elements,
               AshUIExamples.SplitPane.Examples.SplitPaneSplitStatusElement do
        destination_attribute(:parent_id)
      end

      has_many :details_pane_button_elements,
               AshUIExamples.SplitPane.Examples.SplitPaneDetailsPaneButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :handoff_pane_button_elements,
               AshUIExamples.SplitPane.Examples.SplitPaneHandoffPaneButtonElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :primary_review_panel_elements do
        kind(:child)
        slot(:primary)
        placement(:append)
        order(0)
      end

      relationship :secondary_focus_copy_elements do
        kind(:child)
        slot(:secondary)
        placement(:append)
        order(0)
      end

      relationship :split_status_elements do
        kind(:child)
        slot(:secondary)
        placement(:append)
        order(10)
      end

      relationship :details_pane_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(0)
      end

      relationship :handoff_pane_button_elements do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:"custom:split_pane")

      props(%{
        description:
          "Primary and secondary panes stay in related child resources while footer actions switch the emphasized pane.",
        title: "Review split pane",
        class: "ashui-example-split-pane-shell"
      })

      metadata(%{id: "example-split_pane-subject", section: "demo", slot: "body", position: 1})
    end
  end

  defmodule Examples.SplitPanePrimaryReviewPanelElement do
    use AshUIExamples.SplitPane.ExampleElementBase

    relationships do
      has_many :primary_review_panel_title_elements,
               AshUIExamples.SplitPane.Examples.SplitPanePrimaryReviewPanelTitleElement do
        destination_attribute(:parent_id)
      end

      has_many :primary_review_panel_detail_elements,
               AshUIExamples.SplitPane.Examples.SplitPanePrimaryReviewPanelDetailElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :primary_review_panel_title_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :primary_review_panel_detail_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:card)

      props(%{class: "ashui-example-layout-card"})

      metadata(%{id: "primary-review-panel", position: 0, slot: "primary", section: "demo"})
    end
  end

  defmodule Examples.SplitPaneSecondaryFocusCopyElement do
    use AshUIExamples.SplitPane.ExampleElementBase

    ui_element do
      type(:text)

      props(%{content: "details pane", class: "ashui-example-surface-copy"})

      metadata(%{id: "secondary-focus-copy", position: 0, slot: "secondary", section: "demo"})
    end

    ui_bindings do
      binding :secondary_focus_copy_binding do
        source(%{id: "state-split_pane", resource: "ExampleState", field: :selected_value})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "secondary"})
      end
    end
  end

  defmodule Examples.SplitPaneSplitStatusElement do
    use AshUIExamples.SplitPane.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content: "Split-pane emphasis stays local to nested public controls.",
        class: "ashui-example-surface-meta"
      })

      metadata(%{id: "split-status", position: 10, slot: "secondary", section: "demo"})
    end

    ui_bindings do
      binding :split_status_binding do
        source(%{id: "state-split_pane", resource: "ExampleState", field: :status})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "secondary"})
      end
    end
  end

  defmodule Examples.SplitPaneDetailsPaneButtonElement do
    use AshUIExamples.SplitPane.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Details pane",
        class: "ashui-example-command-button",
        variant: "secondary"
      })

      metadata(%{id: "details-pane-button", position: 0, slot: "actions", section: "demo"})
    end

    ui_actions do
      action :select_details_pane do
        signal(:click)
        source(%{id: "state-split_pane", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{"from" => "static", "value" => "Details pane moved into focus."},
            selected_value: %{"from" => "static", "value" => "details pane"}
          }
        })

        metadata(%{intent: "select_display_surface", success_message: "Selection updated"})
      end
    end
  end

  defmodule Examples.SplitPaneHandoffPaneButtonElement do
    use AshUIExamples.SplitPane.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Handoff pane",
        class: "ashui-example-command-button",
        variant: "secondary"
      })

      metadata(%{id: "handoff-pane-button", position: 10, slot: "actions", section: "demo"})
    end

    ui_actions do
      action :select_handoff_pane do
        signal(:click)
        source(%{id: "state-split_pane", resource: "ExampleState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{"from" => "static", "value" => "Handoff pane moved into focus."},
            selected_value: %{"from" => "static", "value" => "handoff pane"}
          }
        })

        metadata(%{intent: "select_display_surface", success_message: "Selection updated"})
      end
    end
  end

  defmodule Examples.SplitPanePrimaryReviewPanelTitleElement do
    use AshUIExamples.SplitPane.ExampleElementBase

    ui_element do
      type(:text)

      props(%{content: "Primary review panel", class: "ashui-example-layout-title"})

      metadata(%{id: "primary-review-panel-title", position: 0, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.SplitPanePrimaryReviewPanelDetailElement do
    use AshUIExamples.SplitPane.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content: "The primary pane keeps the durable operational context visible at all times.",
        class: "ashui-example-layout-copy"
      })

      metadata(%{
        id: "primary-review-panel-detail",
        position: 10,
        slot: "body",
        section: "demo"
      })
    end
  end

  defmodule Examples.SplitPanePreviewElement do
    use AshUIExamples.SplitPane.ExampleElementBase

    ui_element do
      type(:stat)
      props(%{title: "Active pane", value: "details pane"})
      variants([:primary])
      metadata(%{id: "example-split_pane-preview", section: "demo", slot: "body", position: 2})
    end

    ui_bindings do
      binding :preview_value do
        source(%{resource: "ExampleState", field: :selected_value, id: "state-split_pane"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.SplitPaneStoryTextElement do
    use AshUIExamples.SplitPane.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: move emphasis between split panes and confirm the active pane copy changes through nested public actions instead of screen-local imperative layout code.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "example-split_pane-story", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.SplitPaneSignalTextElement do
    use AshUIExamples.SplitPane.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: nested button click -> ExampleState.selected_value -> secondary pane copy, status text, and preview stat.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-split_pane-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.SplitPaneSupportNoticeElement do
    use AshUIExamples.SplitPane.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The `split_pane` example keeps pane emphasis and action ownership on related child resources instead of collapsing the whole layout into one screen fragment.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{
        id: "example-split_pane-support-note",
        section: "demo",
        slot: "body",
        position: 3
      })
    end
  end

  defmodule Examples.SplitPaneScreen do
    use Ash.Resource,
      domain: AshUIExamples.SplitPane.AuthoringDomain,
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
      has_many :demo_panels, AshUIExamples.SplitPane.Examples.SplitPaneDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUIExamples.SplitPane.Examples.SplitPaneStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUIExamples.SplitPane.Examples.SplitPaneSignalTextElement do
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
        title: "Split Pane Example",
        example_directory: "split_pane",
        shell_id: "example-split_pane-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.SplitPane.seed!(opts)
    def reset!, do: AshUIExamples.SplitPane.reset!()
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

    scope "/", AshUIExamples.SplitPane.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_split_pane

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
    plug(AshUIExamples.SplitPane.Web.Router)
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

    alias AshUIExamples.SplitPane.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.SplitPane.seed!()
      example_runtime = runtime_from_params(params)

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.SplitPane.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.SplitPane.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUIExamples.SplitPane.runtime_domains())
        |> Phoenix.Component.assign(:page_title, "Split Pane Example")
        |> Phoenix.Component.assign(:example_directory, "split_pane")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.SplitPane.theme_css())
        |> Phoenix.Component.assign(:example_runtime, example_runtime)
        |> Phoenix.Component.assign(
          :supported_runtimes,
          AshUIExamples.SplitPane.supported_runtimes()
        )

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/split_pane", params),
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
          AshUIExamples.SplitPane.supported_runtimes()
        end)
        |> Phoenix.Component.assign_new(:example_runtime, fn ->
          AshUIExamples.SplitPane.default_runtime()
        end)
        |> Phoenix.Component.assign_new(:rendered_runtime, fn ->
          %{
            content: assigns[:rendered_ui] || "",
            description:
              AshUIExamples.SplitPane.runtime_description(
                AshUIExamples.SplitPane.default_runtime()
              ),
            mode: :live_fragment,
            runtime: AshUIExamples.SplitPane.default_runtime()
          }
        end)

      ~H"""
      <ExampleShell.example_shell
        title={@page_title}
        directory={@example_directory}
        summary={"Meaningful Interaction Story: move emphasis between split panes and confirm the active pane copy changes through nested public actions instead of screen-local imperative layout code."}
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
        AshUIExamples.SplitPane.rendered_runtime(
          socket.assigns,
          socket.assigns[:example_runtime] || AshUIExamples.SplitPane.default_runtime()
        )

      socket
      |> Phoenix.Component.assign(:rendered_runtime, rendered_runtime)
      |> Phoenix.Component.assign(:rendered_ui, rendered_runtime.content)
    end

    defp runtime_from_params(params) do
      params["runtime"]
      |> fallback_runtime()
      |> AshUIExamples.SplitPane.normalize_runtime!()
    end

    defp fallback_runtime(nil), do: System.get_env("ASH_UI_EXAMPLE_RUNTIME")
    defp fallback_runtime(runtime), do: runtime
  end
end
