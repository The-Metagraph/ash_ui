defmodule AshUIExamples.Row do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `row` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.LiveUIAdapter
  alias AshUI.Resource.Authority

  @directory "row"
  @screen_name "example/row"
  @definition %{
    directory: "row",
    family: :layout,
    title: "Row Example",
    story_text:
      "Meaningful Interaction Story: review the horizontal lane sequence and confirm the row example compiles its order from related child resources rather than one inline screen fragment.",
    signal_text:
      "Canonical Signal Preview: relationship order -> compiler composition -> rendered lane sequence inside the maintained row widget.",
    preview_field: :status,
    seed_state: %{
      id: "state-row",
      status: "Row ordering preserved through child relationships."
    },
    support_notice:
      "The `row` example treats nested element relationships as the primary composition path rather than relying on an inline screen body.",
    subject_children: [
      %{
        position: 0,
        type: :card,
        key: :primary_lane,
        children: [
          %{
            position: 0,
            type: :text,
            key: :primary_lane_title,
            children: [],
            props: %{content: "Primary lane", class: "ashui-example-layout-title"}
          },
          %{
            position: 10,
            type: :text,
            key: :primary_lane_detail,
            children: [],
            props: %{
              content: "Relationship order 1 keeps the triage lane left-most.",
              class: "ashui-example-layout-copy"
            }
          }
        ],
        props: %{class: "ashui-example-layout-card"}
      },
      %{
        position: 10,
        type: :card,
        key: :inspector_lane,
        children: [
          %{
            position: 0,
            type: :text,
            key: :inspector_lane_title,
            children: [],
            props: %{
              content: "Inspector lane",
              class: "ashui-example-layout-title"
            }
          },
          %{
            position: 10,
            type: :text,
            key: :inspector_lane_detail,
            children: [],
            props: %{
              content: "Relationship order 2 keeps detail review in the middle.",
              class: "ashui-example-layout-copy"
            }
          }
        ],
        props: %{class: "ashui-example-layout-card"}
      },
      %{
        position: 20,
        type: :card,
        key: :action_lane,
        children: [
          %{
            position: 0,
            type: :text,
            key: :action_lane_title,
            children: [],
            props: %{content: "Action lane", class: "ashui-example-layout-title"}
          },
          %{
            position: 10,
            type: :text,
            key: :action_lane_detail,
            children: [],
            props: %{
              content: "Relationship order 3 reserves the closing lane for follow-up work.",
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
    subject_type: :row,
    notes: "Uses the maintained public `row` widget directly.",
    preview_title: "Composition note",
    subject_props: %{class: "ashui-example-row-layout", spacing: 18}
  }
  @theme_css File.read!(Path.expand("../../assets/css/app.css", __DIR__))

  def app, do: :ash_ui_example_row
  def definition, do: @definition
  def title, do: @definition.title
  def theme_css, do: @theme_css
  def screen_name, do: @screen_name

  def ui_storage do
    [
      domain: AshUIExamples.Row.UiStorageDomain,
      resources: [
        screen: AshUIExamples.Row.UiScreen,
        element: AshUIExamples.Row.UiElement,
        binding: AshUIExamples.Row.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.Row.RuntimeDomain]

  def current_user,
    do: %{active: true, id: "reviewer-row", name: "Example Reviewer", role: :admin}

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
        id: "state-row",
        status: "Row ordering preserved through child relationships."
      }
    )
  end

  def reset! do
    reset_resource!(AshUIExamples.Row.Runtime.ExampleState, AshUIExamples.Row.RuntimeDomain)
    reset_resource!(AshUIExamples.Row.UiBinding, AshUIExamples.Row.UiStorageDomain)
    reset_resource!(AshUIExamples.Row.UiElement, AshUIExamples.Row.UiStorageDomain)
    reset_resource!(AshUIExamples.Row.UiScreen, AshUIExamples.Row.UiStorageDomain)
    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.Row.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.Row.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.Row.Examples.RowScreen,
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
        {Phoenix.PubSub, name: AshUIExamples.Row.PubSub},
        AshUIExamples.Row.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.Row.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    use Ash.Resource, domain: AshUIExamples.Row.RuntimeDomain, data_layer: Ash.DataLayer.Ets

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
      resource(AshUIExamples.Row.UiScreen)
      resource(AshUIExamples.Row.UiElement)
      resource(AshUIExamples.Row.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.Row.UiStorageDomain,
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
      has_many :elements, AshUIExamples.Row.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.Row.UiBinding do
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
      domain: AshUIExamples.Row.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.Row.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.Row.UiBinding do
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
      domain: AshUIExamples.Row.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.Row.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.Row.UiScreen do
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
      resource(AshUIExamples.Row.Examples.RowScreen)
      resource(AshUIExamples.Row.Examples.RowDemoPanelElement)
      resource(AshUIExamples.Row.Examples.RowSubjectElement)
      resource(AshUIExamples.Row.Examples.RowPreviewElement)
      resource(AshUIExamples.Row.Examples.RowStoryTextElement)
      resource(AshUIExamples.Row.Examples.RowSignalTextElement)
      resource(AshUIExamples.Row.Examples.RowSupportNoticeElement)
      resource(AshUIExamples.Row.Examples.RowPrimaryLaneElement)
      resource(AshUIExamples.Row.Examples.RowPrimaryLaneTitleElement)
      resource(AshUIExamples.Row.Examples.RowPrimaryLaneDetailElement)
      resource(AshUIExamples.Row.Examples.RowInspectorLaneElement)
      resource(AshUIExamples.Row.Examples.RowInspectorLaneTitleElement)
      resource(AshUIExamples.Row.Examples.RowInspectorLaneDetailElement)
      resource(AshUIExamples.Row.Examples.RowActionLaneElement)
      resource(AshUIExamples.Row.Examples.RowActionLaneTitleElement)
      resource(AshUIExamples.Row.Examples.RowActionLaneDetailElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.Row.AuthoringDomain,
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

  defmodule Examples.RowDemoPanelElement do
    use AshUIExamples.Row.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.Row.Examples.RowSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.Row.Examples.RowPreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices, AshUIExamples.Row.Examples.RowSupportNoticeElement do
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
      props(%{title: "Row Example", class: "ashui-example-panel"})
      metadata(%{id: "example-row-demo", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.RowSubjectElement do
    use AshUIExamples.Row.ExampleElementBase

    relationships do
      has_many :primary_lane_elements, AshUIExamples.Row.Examples.RowPrimaryLaneElement do
        destination_attribute(:parent_id)
      end

      has_many :inspector_lane_elements, AshUIExamples.Row.Examples.RowInspectorLaneElement do
        destination_attribute(:parent_id)
      end

      has_many :action_lane_elements, AshUIExamples.Row.Examples.RowActionLaneElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :primary_lane_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :inspector_lane_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :action_lane_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end
    end

    ui_element do
      type(:row)
      props(%{class: "ashui-example-row-layout", spacing: 18})
      metadata(%{id: "example-row-subject", section: "demo", slot: "body", position: 1})
    end
  end

  defmodule Examples.RowPrimaryLaneElement do
    use AshUIExamples.Row.ExampleElementBase

    relationships do
      has_many :primary_lane_title_elements,
               AshUIExamples.Row.Examples.RowPrimaryLaneTitleElement do
        destination_attribute(:parent_id)
      end

      has_many :primary_lane_detail_elements,
               AshUIExamples.Row.Examples.RowPrimaryLaneDetailElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :primary_lane_title_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :primary_lane_detail_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:card)

      props(%{class: "ashui-example-layout-card"})

      metadata(%{id: "primary-lane", position: 0, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.RowInspectorLaneElement do
    use AshUIExamples.Row.ExampleElementBase

    relationships do
      has_many :inspector_lane_title_elements,
               AshUIExamples.Row.Examples.RowInspectorLaneTitleElement do
        destination_attribute(:parent_id)
      end

      has_many :inspector_lane_detail_elements,
               AshUIExamples.Row.Examples.RowInspectorLaneDetailElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :inspector_lane_title_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :inspector_lane_detail_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:card)

      props(%{class: "ashui-example-layout-card"})

      metadata(%{id: "inspector-lane", position: 10, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.RowActionLaneElement do
    use AshUIExamples.Row.ExampleElementBase

    relationships do
      has_many :action_lane_title_elements,
               AshUIExamples.Row.Examples.RowActionLaneTitleElement do
        destination_attribute(:parent_id)
      end

      has_many :action_lane_detail_elements,
               AshUIExamples.Row.Examples.RowActionLaneDetailElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :action_lane_title_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :action_lane_detail_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:card)

      props(%{class: "ashui-example-layout-card"})

      metadata(%{id: "action-lane", position: 20, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.RowPrimaryLaneTitleElement do
    use AshUIExamples.Row.ExampleElementBase

    ui_element do
      type(:text)

      props(%{content: "Primary lane", class: "ashui-example-layout-title"})

      metadata(%{id: "primary-lane-title", position: 0, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.RowPrimaryLaneDetailElement do
    use AshUIExamples.Row.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content: "Relationship order 1 keeps the triage lane left-most.",
        class: "ashui-example-layout-copy"
      })

      metadata(%{id: "primary-lane-detail", position: 10, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.RowInspectorLaneTitleElement do
    use AshUIExamples.Row.ExampleElementBase

    ui_element do
      type(:text)

      props(%{content: "Inspector lane", class: "ashui-example-layout-title"})

      metadata(%{id: "inspector-lane-title", position: 0, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.RowInspectorLaneDetailElement do
    use AshUIExamples.Row.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content: "Relationship order 2 keeps detail review in the middle.",
        class: "ashui-example-layout-copy"
      })

      metadata(%{id: "inspector-lane-detail", position: 10, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.RowActionLaneTitleElement do
    use AshUIExamples.Row.ExampleElementBase

    ui_element do
      type(:text)

      props(%{content: "Action lane", class: "ashui-example-layout-title"})

      metadata(%{id: "action-lane-title", position: 0, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.RowActionLaneDetailElement do
    use AshUIExamples.Row.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content: "Relationship order 3 reserves the closing lane for follow-up work.",
        class: "ashui-example-layout-copy"
      })

      metadata(%{id: "action-lane-detail", position: 10, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.RowPreviewElement do
    use AshUIExamples.Row.ExampleElementBase

    ui_element do
      type(:stat)

      props(%{
        title: "Composition note",
        value: "Row ordering preserved through child relationships."
      })

      variants([:primary])
      metadata(%{id: "example-row-preview", section: "demo", slot: "body", position: 2})
    end

    ui_bindings do
      binding :preview_value do
        source(%{resource: "ExampleState", field: :status, id: "state-row"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.RowStoryTextElement do
    use AshUIExamples.Row.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: review the horizontal lane sequence and confirm the row example compiles its order from related child resources rather than one inline screen fragment.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "example-row-story", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.RowSignalTextElement do
    use AshUIExamples.Row.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: relationship order -> compiler composition -> rendered lane sequence inside the maintained row widget.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-row-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.RowSupportNoticeElement do
    use AshUIExamples.Row.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The `row` example treats nested element relationships as the primary composition path rather than relying on an inline screen body.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{id: "example-row-support-note", section: "demo", slot: "body", position: 3})
    end
  end

  defmodule Examples.RowScreen do
    use Ash.Resource,
      domain: AshUIExamples.Row.AuthoringDomain,
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
      has_many :demo_panels, AshUIExamples.Row.Examples.RowDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUIExamples.Row.Examples.RowStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUIExamples.Row.Examples.RowSignalTextElement do
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
      metadata(%{title: "Row Example", example_directory: "row", shell_id: "example-row-shell"})
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.Row.seed!(opts)
    def reset!, do: AshUIExamples.Row.reset!()
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

    scope "/", AshUIExamples.Row.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_row

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
    plug(AshUIExamples.Row.Web.Router)
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

    alias AshUIExamples.Row.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.Row.seed!()

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.Row.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.Row.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUIExamples.Row.runtime_domains())
        |> Phoenix.Component.assign(:page_title, "Row Example")
        |> Phoenix.Component.assign(:example_directory, "row")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.Row.theme_css())

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/row", params),
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
        summary={"Meaningful Interaction Story: review the horizontal lane sequence and confirm the row example compiles its order from related child resources rather than one inline screen fragment."}
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
        AshUIExamples.Row.rendered_ui(socket.assigns)
      )
    end
  end
end
