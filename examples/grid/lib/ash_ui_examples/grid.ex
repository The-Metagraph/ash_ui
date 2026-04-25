defmodule AshUIExamples.Grid do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `grid` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.LiveUIAdapter
  alias AshUI.Resource.Authority

  @directory "grid"
  @screen_name "example/grid"
  @definition %{
    directory: "grid",
    family: :layout,
    title: "Grid Example",
    story_text:
      "Meaningful Interaction Story: review the multi-tile structure and confirm the grid example keeps tile ordering, spacing, and grouping in related element resources.",
    signal_text:
      "Canonical Signal Preview: relationship order + grid props -> rendered tile matrix inside the maintained grid widget.",
    preview_field: :status,
    seed_state: %{
      id: "state-grid",
      status: "Grid tiles preserved through child relationships and explicit column props."
    },
    support_notice:
      "The `grid` example keeps tile order and grouping in the resource graph so the compiler output still makes the authored structure visible.",
    subject_children: [
      %{
        position: 0,
        type: :card,
        key: :queue_tile,
        children: [
          %{
            position: 0,
            type: :text,
            key: :queue_tile_title,
            children: [],
            props: %{content: "Queue tile", class: "ashui-example-layout-title"}
          },
          %{
            position: 10,
            type: :text,
            key: :queue_tile_detail,
            children: [],
            props: %{
              content: "Tile one anchors the highest-priority lane.",
              class: "ashui-example-layout-copy"
            }
          }
        ],
        props: %{class: "ashui-example-layout-card"}
      },
      %{
        position: 10,
        type: :card,
        key: :trend_tile,
        children: [
          %{
            position: 0,
            type: :text,
            key: :trend_tile_title,
            children: [],
            props: %{content: "Trend tile", class: "ashui-example-layout-title"}
          },
          %{
            position: 10,
            type: :text,
            key: :trend_tile_detail,
            children: [],
            props: %{
              content: "Tile two keeps a paired metric adjacent to the queue.",
              class: "ashui-example-layout-copy"
            }
          }
        ],
        props: %{class: "ashui-example-layout-card"}
      },
      %{
        position: 20,
        type: :card,
        key: :sla_tile,
        children: [
          %{
            position: 0,
            type: :text,
            key: :sla_tile_title,
            children: [],
            props: %{content: "SLA tile", class: "ashui-example-layout-title"}
          },
          %{
            position: 10,
            type: :text,
            key: :sla_tile_detail,
            children: [],
            props: %{
              content: "Tile three starts the lower row with service commitment context.",
              class: "ashui-example-layout-copy"
            }
          }
        ],
        props: %{class: "ashui-example-layout-card"}
      },
      %{
        position: 30,
        type: :card,
        key: :handoff_tile,
        children: [
          %{
            position: 0,
            type: :text,
            key: :handoff_tile_title,
            children: [],
            props: %{content: "Handoff tile", class: "ashui-example-layout-title"}
          },
          %{
            position: 10,
            type: :text,
            key: :handoff_tile_detail,
            children: [],
            props: %{
              content: "Tile four closes the grid with a follow-up handoff panel.",
              class: "ashui-example-layout-copy"
            }
          }
        ],
        props: %{class: "ashui-example-layout-card"}
      }
    ],
    section: :layout_navigation,
    subject_action: nil,
    subject_binding: nil,
    subject_type: :grid,
    notes: "Uses the maintained public `grid` widget directly.",
    preview_title: "Composition note",
    subject_props: %{columns: 2, class: "ashui-example-grid-layout", spacing: 18}
  }
  @theme_css File.read!(Path.expand("../../assets/css/app.css", __DIR__))

  def app, do: :ash_ui_example_grid
  def definition, do: @definition
  def title, do: @definition.title
  def theme_css, do: @theme_css
  def screen_name, do: @screen_name

  def ui_storage do
    [
      domain: AshUIExamples.Grid.UiStorageDomain,
      resources: [
        screen: AshUIExamples.Grid.UiScreen,
        element: AshUIExamples.Grid.UiElement,
        binding: AshUIExamples.Grid.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.Grid.RuntimeDomain]

  def current_user,
    do: %{active: true, id: "reviewer-grid", name: "Example Reviewer", role: :admin}

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
        id: "state-grid",
        status: "Grid tiles preserved through child relationships and explicit column props."
      }
    )
  end

  def reset! do
    reset_resource!(AshUIExamples.Grid.Runtime.ExampleState, AshUIExamples.Grid.RuntimeDomain)
    reset_resource!(AshUIExamples.Grid.UiBinding, AshUIExamples.Grid.UiStorageDomain)
    reset_resource!(AshUIExamples.Grid.UiElement, AshUIExamples.Grid.UiStorageDomain)
    reset_resource!(AshUIExamples.Grid.UiScreen, AshUIExamples.Grid.UiStorageDomain)
    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.Grid.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.Grid.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.Grid.Examples.GridScreen,
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
        {Phoenix.PubSub, name: AshUIExamples.Grid.PubSub},
        AshUIExamples.Grid.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.Grid.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    use Ash.Resource, domain: AshUIExamples.Grid.RuntimeDomain, data_layer: Ash.DataLayer.Ets

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
      resource(AshUIExamples.Grid.UiScreen)
      resource(AshUIExamples.Grid.UiElement)
      resource(AshUIExamples.Grid.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.Grid.UiStorageDomain,
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
      has_many :elements, AshUIExamples.Grid.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.Grid.UiBinding do
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
      domain: AshUIExamples.Grid.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.Grid.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.Grid.UiBinding do
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
      domain: AshUIExamples.Grid.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.Grid.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.Grid.UiScreen do
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
      resource(AshUIExamples.Grid.Examples.GridScreen)
      resource(AshUIExamples.Grid.Examples.GridDemoPanelElement)
      resource(AshUIExamples.Grid.Examples.GridSubjectElement)
      resource(AshUIExamples.Grid.Examples.GridPreviewElement)
      resource(AshUIExamples.Grid.Examples.GridStoryTextElement)
      resource(AshUIExamples.Grid.Examples.GridSignalTextElement)
      resource(AshUIExamples.Grid.Examples.GridSupportNoticeElement)
      resource(AshUIExamples.Grid.Examples.GridQueueTileElement)
      resource(AshUIExamples.Grid.Examples.GridQueueTileTitleElement)
      resource(AshUIExamples.Grid.Examples.GridQueueTileDetailElement)
      resource(AshUIExamples.Grid.Examples.GridTrendTileElement)
      resource(AshUIExamples.Grid.Examples.GridTrendTileTitleElement)
      resource(AshUIExamples.Grid.Examples.GridTrendTileDetailElement)
      resource(AshUIExamples.Grid.Examples.GridSlaTileElement)
      resource(AshUIExamples.Grid.Examples.GridSlaTileTitleElement)
      resource(AshUIExamples.Grid.Examples.GridSlaTileDetailElement)
      resource(AshUIExamples.Grid.Examples.GridHandoffTileElement)
      resource(AshUIExamples.Grid.Examples.GridHandoffTileTitleElement)
      resource(AshUIExamples.Grid.Examples.GridHandoffTileDetailElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.Grid.AuthoringDomain,
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

  defmodule Examples.GridDemoPanelElement do
    use AshUIExamples.Grid.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.Grid.Examples.GridSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.Grid.Examples.GridPreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices, AshUIExamples.Grid.Examples.GridSupportNoticeElement do
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
      props(%{title: "Grid Example", class: "ashui-example-panel"})
      metadata(%{id: "example-grid-demo", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.GridSubjectElement do
    use AshUIExamples.Grid.ExampleElementBase

    relationships do
      has_many :queue_tile_elements, AshUIExamples.Grid.Examples.GridQueueTileElement do
        destination_attribute(:parent_id)
      end

      has_many :trend_tile_elements, AshUIExamples.Grid.Examples.GridTrendTileElement do
        destination_attribute(:parent_id)
      end

      has_many :sla_tile_elements, AshUIExamples.Grid.Examples.GridSlaTileElement do
        destination_attribute(:parent_id)
      end

      has_many :handoff_tile_elements, AshUIExamples.Grid.Examples.GridHandoffTileElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :queue_tile_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :trend_tile_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :sla_tile_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end

      relationship :handoff_tile_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(30)
      end
    end

    ui_element do
      type(:grid)
      props(%{columns: 2, class: "ashui-example-grid-layout", spacing: 18})
      metadata(%{id: "example-grid-subject", section: "demo", slot: "body", position: 1})
    end
  end

  defmodule Examples.GridQueueTileElement do
    use AshUIExamples.Grid.ExampleElementBase

    relationships do
      has_many :queue_tile_title_elements,
               AshUIExamples.Grid.Examples.GridQueueTileTitleElement do
        destination_attribute(:parent_id)
      end

      has_many :queue_tile_detail_elements,
               AshUIExamples.Grid.Examples.GridQueueTileDetailElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :queue_tile_title_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :queue_tile_detail_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:card)

      props(%{class: "ashui-example-layout-card"})

      metadata(%{id: "queue-tile", position: 0, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.GridTrendTileElement do
    use AshUIExamples.Grid.ExampleElementBase

    relationships do
      has_many :trend_tile_title_elements,
               AshUIExamples.Grid.Examples.GridTrendTileTitleElement do
        destination_attribute(:parent_id)
      end

      has_many :trend_tile_detail_elements,
               AshUIExamples.Grid.Examples.GridTrendTileDetailElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :trend_tile_title_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :trend_tile_detail_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:card)

      props(%{class: "ashui-example-layout-card"})

      metadata(%{id: "trend-tile", position: 10, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.GridSlaTileElement do
    use AshUIExamples.Grid.ExampleElementBase

    relationships do
      has_many :sla_tile_title_elements, AshUIExamples.Grid.Examples.GridSlaTileTitleElement do
        destination_attribute(:parent_id)
      end

      has_many :sla_tile_detail_elements, AshUIExamples.Grid.Examples.GridSlaTileDetailElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :sla_tile_title_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :sla_tile_detail_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:card)

      props(%{class: "ashui-example-layout-card"})

      metadata(%{id: "sla-tile", position: 20, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.GridHandoffTileElement do
    use AshUIExamples.Grid.ExampleElementBase

    relationships do
      has_many :handoff_tile_title_elements,
               AshUIExamples.Grid.Examples.GridHandoffTileTitleElement do
        destination_attribute(:parent_id)
      end

      has_many :handoff_tile_detail_elements,
               AshUIExamples.Grid.Examples.GridHandoffTileDetailElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :handoff_tile_title_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :handoff_tile_detail_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:card)

      props(%{class: "ashui-example-layout-card"})

      metadata(%{id: "handoff-tile", position: 30, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.GridQueueTileTitleElement do
    use AshUIExamples.Grid.ExampleElementBase

    ui_element do
      type(:text)

      props(%{content: "Queue tile", class: "ashui-example-layout-title"})

      metadata(%{id: "queue-tile-title", position: 0, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.GridQueueTileDetailElement do
    use AshUIExamples.Grid.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content: "Tile one anchors the highest-priority lane.",
        class: "ashui-example-layout-copy"
      })

      metadata(%{id: "queue-tile-detail", position: 10, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.GridTrendTileTitleElement do
    use AshUIExamples.Grid.ExampleElementBase

    ui_element do
      type(:text)

      props(%{content: "Trend tile", class: "ashui-example-layout-title"})

      metadata(%{id: "trend-tile-title", position: 0, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.GridTrendTileDetailElement do
    use AshUIExamples.Grid.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content: "Tile two keeps a paired metric adjacent to the queue.",
        class: "ashui-example-layout-copy"
      })

      metadata(%{id: "trend-tile-detail", position: 10, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.GridSlaTileTitleElement do
    use AshUIExamples.Grid.ExampleElementBase

    ui_element do
      type(:text)

      props(%{content: "SLA tile", class: "ashui-example-layout-title"})

      metadata(%{id: "sla-tile-title", position: 0, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.GridSlaTileDetailElement do
    use AshUIExamples.Grid.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content: "Tile three starts the lower row with service commitment context.",
        class: "ashui-example-layout-copy"
      })

      metadata(%{id: "sla-tile-detail", position: 10, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.GridHandoffTileTitleElement do
    use AshUIExamples.Grid.ExampleElementBase

    ui_element do
      type(:text)

      props(%{content: "Handoff tile", class: "ashui-example-layout-title"})

      metadata(%{id: "handoff-tile-title", position: 0, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.GridHandoffTileDetailElement do
    use AshUIExamples.Grid.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content: "Tile four closes the grid with a follow-up handoff panel.",
        class: "ashui-example-layout-copy"
      })

      metadata(%{id: "handoff-tile-detail", position: 10, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.GridPreviewElement do
    use AshUIExamples.Grid.ExampleElementBase

    ui_element do
      type(:stat)

      props(%{
        title: "Composition note",
        value: "Grid tiles preserved through child relationships and explicit column props."
      })

      variants([:primary])
      metadata(%{id: "example-grid-preview", section: "demo", slot: "body", position: 2})
    end

    ui_bindings do
      binding :preview_value do
        source(%{resource: "ExampleState", field: :status, id: "state-grid"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.GridStoryTextElement do
    use AshUIExamples.Grid.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: review the multi-tile structure and confirm the grid example keeps tile ordering, spacing, and grouping in related element resources.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "example-grid-story", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.GridSignalTextElement do
    use AshUIExamples.Grid.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: relationship order + grid props -> rendered tile matrix inside the maintained grid widget.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-grid-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.GridSupportNoticeElement do
    use AshUIExamples.Grid.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The `grid` example keeps tile order and grouping in the resource graph so the compiler output still makes the authored structure visible.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{id: "example-grid-support-note", section: "demo", slot: "body", position: 3})
    end
  end

  defmodule Examples.GridScreen do
    use Ash.Resource,
      domain: AshUIExamples.Grid.AuthoringDomain,
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
      has_many :demo_panels, AshUIExamples.Grid.Examples.GridDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUIExamples.Grid.Examples.GridStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUIExamples.Grid.Examples.GridSignalTextElement do
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
        title: "Grid Example",
        example_directory: "grid",
        shell_id: "example-grid-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.Grid.seed!(opts)
    def reset!, do: AshUIExamples.Grid.reset!()
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

    scope "/", AshUIExamples.Grid.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_grid

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
    plug(AshUIExamples.Grid.Web.Router)
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

    alias AshUIExamples.Grid.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.Grid.seed!()

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.Grid.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.Grid.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUIExamples.Grid.runtime_domains())
        |> Phoenix.Component.assign(:page_title, "Grid Example")
        |> Phoenix.Component.assign(:example_directory, "grid")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.Grid.theme_css())

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/grid", params),
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
        summary={"Meaningful Interaction Story: review the multi-tile structure and confirm the grid example keeps tile ordering, spacing, and grouping in related element resources."}
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
        AshUIExamples.Grid.rendered_ui(socket.assigns)
      )
    end
  end
end
