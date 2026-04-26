defmodule AshUITutorials.ServicesAndIncidents do
  @moduledoc """
  Chapter 2 checkpoint app for the Operations Control Center tutorial.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.{DesktopUIAdapter, ElmUIAdapter, LiveUIAdapter}
  alias AshUI.Resource.Authority
  alias AshUI.Tutorials.Phase23, as: TutorialBaseline

  @app :ash_ui_tutorial_services_and_incidents
  @screen_names %{
    services: "tutorial/services-incidents/services",
    incidents: "tutorial/services-incidents/incidents"
  }
  @title "Operations Control Center - Services and Incidents"
  @summary "Add the first real operator workspace through separate services and incidents screens backed by one shared runtime state."
  @story_text "Meaningful Interaction Story: move between the services list and incidents table, trigger a focus action, and confirm the shared detail card updates through the runtime state resource instead of isolated host markup."
  @signal_text "Canonical Signal Preview: button click -> WorkspaceState.update(selected_value, detail_title, detail_summary, detail_status, status) -> hydrated list/table and detail shell across both screens."
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
      "Default runtime: renders the live_ui fragment through the tutorial's Phoenix LiveView host.",
    "elm_ui" =>
      "Alternate runtime: renders the canonical IUR through elm_ui and previews the generated document inside the same host shell.",
    "desktop_ui" =>
      "Alternate runtime: renders the canonical IUR to desktop_ui instructions and previews the generated payload inside the same host shell."
  }

  def app, do: @app
  def title, do: @title
  def summary, do: @summary
  def story_text, do: @story_text
  def signal_text, do: @signal_text
  def theme_css, do: @theme_css
  def default_runtime, do: @default_runtime
  def supported_runtimes, do: @supported_runtimes
  def screen_name(kind), do: Map.fetch!(@screen_names, kind)

  def runtime_description(runtime),
    do: runtime |> normalize_runtime!() |> then(&Map.fetch!(@runtime_descriptions, &1))

  def ui_storage do
    [
      domain: AshUITutorials.ServicesAndIncidents.UiStorageDomain,
      resources: [
        screen: AshUITutorials.ServicesAndIncidents.UiScreen,
        element: AshUITutorials.ServicesAndIncidents.UiElement,
        binding: AshUITutorials.ServicesAndIncidents.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUITutorials.ServicesAndIncidents.RuntimeDomain]

  def actor_profile(role) do
    Enum.find(TutorialBaseline.actor_profiles(), &(&1.role == role))
  end

  def current_user, do: actor_profile(:on_call_operator)

  def seed_state do
    fixtures = TutorialBaseline.seed_fixtures()
    first_service = hd(fixtures.services)
    first_incident = hd(fixtures.incidents)

    %{
      id: "tutorial-services-incidents-state",
      status: "Services screen mounted with the seeded service-health view.",
      current_value: "services workspace",
      selected_value: "services",
      detail_title: first_service.name,
      detail_summary: first_service.summary,
      detail_status: first_service.status,
      services:
        Enum.map(fixtures.services, fn service ->
          %{
            "title" => service.name,
            "summary" => service.summary,
            "meta" => "#{service.status} • #{service.tier}"
          }
        end),
      incidents:
        Enum.map(fixtures.incidents, fn incident ->
          %{
            "title" => incident.title,
            "severity" => incident.severity,
            "state" => incident.state,
            "service" =>
              fixtures.services
              |> Enum.find(&(&1.id == incident.service_id))
              |> Map.fetch!(:name)
          }
        end),
      services_status_copy: "Services are grouped by health and tier for first-pass review.",
      incidents_status_copy: "Active incidents are tracked in a tabular review surface.",
      incident_focus_title: first_incident.title,
      incident_focus_summary: first_incident.summary
    }
  end

  def reset! do
    reset_resource!(AshUITutorials.ServicesAndIncidents.Runtime.WorkspaceState, AshUITutorials.ServicesAndIncidents.RuntimeDomain)
    reset_resource!(AshUITutorials.ServicesAndIncidents.UiBinding, AshUITutorials.ServicesAndIncidents.UiStorageDomain)
    reset_resource!(AshUITutorials.ServicesAndIncidents.UiElement, AshUITutorials.ServicesAndIncidents.UiStorageDomain)
    reset_resource!(AshUITutorials.ServicesAndIncidents.UiScreen, AshUITutorials.ServicesAndIncidents.UiStorageDomain)
    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUITutorials.ServicesAndIncidents.Runtime.WorkspaceState,
        seed_state(),
        domain: AshUITutorials.ServicesAndIncidents.RuntimeDomain,
        authorize?: false
      )

    {:ok, services_screen} =
      Authority.create(
        AshUITutorials.ServicesAndIncidents.Examples.ServicesScreen,
        actor: actor,
        name: screen_name(:services),
        ui_storage: ui_storage()
      )

    {:ok, incidents_screen} =
      Authority.create(
        AshUITutorials.ServicesAndIncidents.Examples.IncidentsScreen,
        actor: actor,
        name: screen_name(:incidents),
        ui_storage: ui_storage()
      )

    %{
      actor: actor,
      services_screen: services_screen,
      incidents_screen: incidents_screen,
      ui_storage: ui_storage()
    }
  end

  def build_socket(extra_assigns \\ %{}) do
    %Phoenix.LiveView.Socket{
      assigns:
        Map.merge(
          %{
            __changed__: %{},
            flash: %{},
            current_user: current_user(),
            ash_ui_storage: ui_storage(),
            ash_ui_domains: runtime_domains()
          },
          extra_assigns
        )
    }
  end

  def mount_seeded!(screen_kind \\ :services, opts \\ []) do
    seeded = seed!(opts)

    socket =
      build_socket(%{
        current_user: seeded.actor,
        ash_ui_storage: seeded.ui_storage,
        ash_ui_domains: runtime_domains()
      })

    {:ok, mounted_socket} = Integration.mount_ui_screen(socket, screen_name(screen_kind), %{})
    {:ok, mounted_socket} = EventHandler.wire_handlers(mounted_socket)

    Map.put(seeded, :socket, mounted_socket)
    |> Map.put(:screen_name, screen_name(screen_kind))
  end

  def rendered_ui(assigns) do
    assigns
    |> rendered_runtime()
    |> then(& &1.content)
  end

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

  def normalize_runtime(nil), do: {:ok, @default_runtime}

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

        %{content: markup, description: runtime_description(runtime), mode: :live_fragment, runtime: runtime}

      "elm_ui" ->
        {:ok, html_document} = ElmUIAdapter.render(iur, title: title())
        %{content: html_document, description: runtime_description(runtime), mode: :html_document, runtime: runtime}

      "desktop_ui" ->
        {:ok, instructions} = DesktopUIAdapter.render(iur, window_title: title())
        %{content: Jason.encode!(instructions, pretty: true), description: runtime_description(runtime), mode: :desktop_instructions, runtime: runtime}
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
        {Phoenix.PubSub, name: AshUITutorials.ServicesAndIncidents.PubSub},
        AshUITutorials.ServicesAndIncidents.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUITutorials.ServicesAndIncidents.Runtime.WorkspaceState)
    end
  end

  defmodule Runtime.WorkspaceState do
    use Ash.Resource,
      domain: AshUITutorials.ServicesAndIncidents.RuntimeDomain,
      authorizers: [Ash.Policy.Authorizer],
      data_layer: Ash.DataLayer.Ets

    ets do
      private?(true)
    end

    attributes do
      attribute :id, :string do
        primary_key?(true)
        allow_nil?(false)
      end

      attribute :status, :string, default: "Services screen mounted with the seeded service-health view."
      attribute :current_value, :string, default: "services workspace"
      attribute :selected_value, :string, default: "services"
      attribute :detail_title, :string, default: ""
      attribute :detail_summary, :string, default: ""
      attribute :detail_status, :string, default: ""
      attribute :services, {:array, :map}, default: []
      attribute :incidents, {:array, :map}, default: []
      attribute :services_status_copy, :string, default: ""
      attribute :incidents_status_copy, :string, default: ""
      attribute :incident_focus_title, :string, default: ""
      attribute :incident_focus_summary, :string, default: ""
    end

    actions do
      defaults([:read, :destroy])

      create :create do
        primary?(true)
        accept([:id, :status, :current_value, :selected_value, :detail_title, :detail_summary, :detail_status, :services, :incidents, :services_status_copy, :incidents_status_copy, :incident_focus_title, :incident_focus_summary])
      end

      update :update do
        primary?(true)
        accept([:status, :current_value, :selected_value, :detail_title, :detail_summary, :detail_status, :services, :incidents, :services_status_copy, :incidents_status_copy, :incident_focus_title, :incident_focus_summary])
      end
    end

    policies do
      bypass actor_attribute_equals(:role, :admin) do
        authorize_if(always())
      end

      policy action_type(:read) do
        authorize_if(actor_attribute_equals(:active, true))
      end

      policy action([:create, :update, :destroy]) do
        authorize_if(actor_attribute_equals(:role, :on_call_operator))
      end
    end
  end

  defmodule UiStorageDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUITutorials.ServicesAndIncidents.UiScreen)
      resource(AshUITutorials.ServicesAndIncidents.UiElement)
      resource(AshUITutorials.ServicesAndIncidents.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUITutorials.ServicesAndIncidents.UiStorageDomain,
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
      has_many :elements, AshUITutorials.ServicesAndIncidents.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUITutorials.ServicesAndIncidents.UiBinding do
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
      domain: AshUITutorials.ServicesAndIncidents.UiStorageDomain,
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
      belongs_to :screen, AshUITutorials.ServicesAndIncidents.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUITutorials.ServicesAndIncidents.UiBinding do
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
      domain: AshUITutorials.ServicesAndIncidents.UiStorageDomain,
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
      belongs_to :element, AshUITutorials.ServicesAndIncidents.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUITutorials.ServicesAndIncidents.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end
    end

    actions do
      defaults([:read, :destroy])

      create :create do
        primary?(true)
        accept([:source, :target, :binding_type, :transform, :element_id, :screen_id, :metadata, :active, :version])
      end

      update :update do
        primary?(true)
        accept([:source, :target, :binding_type, :transform, :element_id, :screen_id, :metadata, :active])
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
      resource(AshUITutorials.ServicesAndIncidents.Examples.ServicesScreen)
      resource(AshUITutorials.ServicesAndIncidents.Examples.ServicesPanelElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.ServicesTabsElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.ServicesTabButtonElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.IncidentsTabButtonElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.ServicesActivePanelElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.ServicesListElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.ServicesActionRowElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.FocusGatewayButtonElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.FocusBillingButtonElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.ServicesDetailCardElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.DetailBadgeElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.DetailTitleElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.DetailSummaryElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.ServicesStatusTextElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.ServicesStoryTextElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.ServicesSignalTextElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.IncidentsScreen)
      resource(AshUITutorials.ServicesAndIncidents.Examples.IncidentsPanelElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.IncidentsTabsElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.IncidentsActivePanelElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.IncidentsTableElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.IncidentsActionRowElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.FocusGatewayLatencyButtonElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.FocusSearchLagButtonElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.IncidentsDetailCardElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.IncidentsStatusTextElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.IncidentsStoryTextElement)
      resource(AshUITutorials.ServicesAndIncidents.Examples.IncidentsSignalTextElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUITutorials.ServicesAndIncidents.AuthoringDomain,
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

  defmodule Examples.ServicesPanelElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    relationships do
      has_many :services_tabs, AshUITutorials.ServicesAndIncidents.Examples.ServicesTabsElement do
        destination_attribute(:parent_id)
      end

      has_many :services_lists, AshUITutorials.ServicesAndIncidents.Examples.ServicesListElement do
        destination_attribute(:parent_id)
      end

      has_many :action_rows, AshUITutorials.ServicesAndIncidents.Examples.ServicesActionRowElement do
        destination_attribute(:parent_id)
      end

      has_many :detail_cards, AshUITutorials.ServicesAndIncidents.Examples.ServicesDetailCardElement do
        destination_attribute(:parent_id)
      end

      has_many :status_texts, AshUITutorials.ServicesAndIncidents.Examples.ServicesStatusTextElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :services_tabs do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :services_lists do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :action_rows do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(0)
      end

      relationship :detail_cards do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end

      relationship :status_texts do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:card)
      props(%{title: "Services workspace", class: "ashui-example-panel ashui-tutorial-workspace-panel"})
      metadata(%{id: "services-workspace-panel", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.ServicesTabsElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    relationships do
      has_many :services_tab_buttons,
               AshUITutorials.ServicesAndIncidents.Examples.ServicesTabButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :incidents_tab_buttons,
               AshUITutorials.ServicesAndIncidents.Examples.IncidentsTabButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :active_panels,
               AshUITutorials.ServicesAndIncidents.Examples.ServicesActivePanelElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :services_tab_buttons do
        kind(:child)
        slot(:nav)
        placement(:append)
        order(0)
      end

      relationship :incidents_tab_buttons do
        kind(:child)
        slot(:nav)
        placement(:append)
        order(10)
      end

      relationship :active_panels do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:tabs")
      props(%{
        description: "Tab state stays visible while services and incidents live on separate screens.",
        title: "Workspace focus",
        class: "ashui-example-tabs-shell"
      })

      metadata(%{id: "services-tabs", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.ServicesTabButtonElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Services", class: "ashui-example-primary-cta", variant: "secondary"})
      metadata(%{id: "services-tab-button", section: "demo", slot: "nav", position: 0})
    end

    ui_actions do
      action :show_services do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")
        transform(%{
          params: %{
            selected_value: %{"from" => "static", "value" => "services"},
            status: %{"from" => "static", "value" => "Services screen mounted with the seeded service-health view."},
            current_value: %{"from" => "static", "value" => "services workspace"},
            detail_title: %{"from" => "static", "value" => "API Gateway"},
            detail_summary: %{"from" => "static", "value" => "Ingress service handling public traffic and auth fan-out."},
            detail_status: %{"from" => "static", "value" => "degraded"}
          }
        })

        metadata(%{intent: "select_workspace", success_message: "Services focus restored"})
      end
    end
  end

  defmodule Examples.IncidentsTabButtonElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Incidents", class: "ashui-example-secondary-cta", variant: "secondary"})
      metadata(%{id: "incidents-tab-button", section: "demo", slot: "nav", position: 10})
    end

    ui_actions do
      action :show_incidents do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")
        transform(%{
          params: %{
            selected_value: %{"from" => "static", "value" => "incidents"},
            status: %{"from" => "static", "value" => "Incidents screen is ready for active issue review."},
            current_value: %{"from" => "static", "value" => "incidents workspace"},
            detail_title: %{"from" => "static", "value" => "Gateway latency spike"},
            detail_summary: %{"from" => "static", "value" => "Tail latency exceeded SLA for external requests in the last 12 minutes."},
            detail_status: %{"from" => "static", "value" => "sev-1"}
          }
        })

        metadata(%{intent: "select_workspace", success_message: "Incident focus loaded"})
      end
    end
  end

  defmodule Examples.ServicesActivePanelElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "services", class: "ashui-tutorial-tabs-panel ashui-tutorial-muted-copy"})
      metadata(%{id: "services-active-panel", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :selected_value do
        source(%{resource: "WorkspaceState", field: :selected_value, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "active_panel"})
      end
    end
  end

  defmodule Examples.ServicesListElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    ui_element do
      type(:list)

      props(%{
        title: "Tracked services",
        description: "Services are grouped by health and tier for rapid review.",
        class: "ashui-example-list-surface",
        empty_text: "No services are loaded."
      })

      metadata(%{id: "services-list", section: "demo", slot: "body", position: 10})
    end

    ui_bindings do
      binding :services_items do
        source(%{resource: "WorkspaceState", field: :services, id: "tutorial-services-incidents-state"})
        target("items")
        binding_type(:list)
        transform(%{})
        metadata(%{owner: "services_list"})
      end
    end
  end

  defmodule Examples.ServicesActionRowElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    relationships do
      has_many :gateway_focus_buttons,
               AshUITutorials.ServicesAndIncidents.Examples.FocusGatewayButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :billing_focus_buttons,
               AshUITutorials.ServicesAndIncidents.Examples.FocusBillingButtonElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :gateway_focus_buttons do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :billing_focus_buttons do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:row)
      props(%{class: "ashui-tutorial-toolbar", spacing: 12})
      metadata(%{id: "services-toolbar", section: "demo", slot: "actions", position: 0})
    end
  end

  defmodule Examples.FocusGatewayButtonElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Focus API Gateway", class: "ashui-example-primary-cta", variant: "primary"})
      metadata(%{id: "focus-gateway", section: "demo", slot: "body", position: 0})
    end

    ui_actions do
      action :focus_gateway do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")
        transform(%{
          params: %{
            detail_title: %{"from" => "static", "value" => "API Gateway"},
            detail_summary: %{"from" => "static", "value" => "Ingress service handling public traffic and auth fan-out."},
            detail_status: %{"from" => "static", "value" => "degraded"},
            status: %{"from" => "static", "value" => "Service detail focused on API Gateway."}
          }
        })

        metadata(%{intent: "focus_service", success_message: "Gateway detail loaded"})
      end
    end
  end

  defmodule Examples.FocusBillingButtonElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Focus Billing", class: "ashui-example-secondary-cta", variant: "secondary"})
      metadata(%{id: "focus-billing", section: "demo", slot: "body", position: 10})
    end

    ui_actions do
      action :focus_billing do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")
        transform(%{
          params: %{
            detail_title: %{"from" => "static", "value" => "Billing"},
            detail_summary: %{"from" => "static", "value" => "Invoice, subscription, and retry orchestration."},
            detail_status: %{"from" => "static", "value" => "healthy"},
            status: %{"from" => "static", "value" => "Service detail focused on Billing."}
          }
        })

        metadata(%{intent: "focus_service", success_message: "Billing detail loaded"})
      end
    end
  end

  defmodule Examples.ServicesDetailCardElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    relationships do
      has_many :detail_badges, AshUITutorials.ServicesAndIncidents.Examples.DetailBadgeElement do
        destination_attribute(:parent_id)
      end

      has_many :detail_titles, AshUITutorials.ServicesAndIncidents.Examples.DetailTitleElement do
        destination_attribute(:parent_id)
      end

      has_many :detail_summaries, AshUITutorials.ServicesAndIncidents.Examples.DetailSummaryElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :detail_badges do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :detail_titles do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :detail_summaries do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end
    end

    ui_element do
      type(:card)
      props(%{class: "ashui-tutorial-detail-card", title: "Focused detail"})
      metadata(%{id: "services-detail-card", section: "demo", slot: "footer", position: 0})
    end
  end

  defmodule Examples.DetailBadgeElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    ui_element do
      type(:badge)
      props(%{content: "degraded", class: "ashui-tutorial-status-pill"})
      metadata(%{id: "detail-badge", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :detail_status do
        source(%{resource: "WorkspaceState", field: :detail_status, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "detail_status"})
      end
    end
  end

  defmodule Examples.DetailTitleElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "API Gateway", class: "ashui-tutorial-detail-title"})
      metadata(%{id: "detail-title", section: "demo", slot: "body", position: 10})
    end

    ui_bindings do
      binding :detail_title do
        source(%{resource: "WorkspaceState", field: :detail_title, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "detail_title"})
      end
    end
  end

  defmodule Examples.DetailSummaryElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-detail-copy"})
      metadata(%{id: "detail-summary", section: "demo", slot: "body", position: 20})
    end

    ui_bindings do
      binding :detail_summary do
        source(%{resource: "WorkspaceState", field: :detail_summary, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "detail_summary"})
      end
    end
  end

  defmodule Examples.ServicesStatusTextElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "Services are grouped by health and tier for first-pass review.", class: "ashui-tutorial-muted-copy"})
      metadata(%{id: "services-status-text", section: "demo", slot: "footer", position: 10})
    end

    ui_bindings do
      binding :status do
        source(%{resource: "WorkspaceState", field: :status, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "status"})
      end
    end
  end

  defmodule Examples.ServicesStoryTextElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    ui_element do
      type(:text)
      props(%{
        content:
          "Meaningful Interaction Story: move between the services list and incidents table, trigger a focus action, and confirm the shared detail card updates through the runtime state resource instead of isolated host markup.",
        class: "ashui-example-code-surface"
      })
      metadata(%{id: "services-story-text", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.ServicesSignalTextElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    ui_element do
      type(:text)
      props(%{
        content:
          "Canonical Signal Preview: button click -> WorkspaceState.update(selected_value, detail_title, detail_summary, detail_status, status) -> hydrated list/table and detail shell across both screens.",
        class: "ashui-example-code-surface"
      })
      metadata(%{id: "services-signal-text", section: "signal_preview", slot: "body", position: 20})
    end
  end

  defmodule Examples.IncidentsPanelElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    relationships do
      has_many :incidents_tabs,
               AshUITutorials.ServicesAndIncidents.Examples.IncidentsTabsElement do
        destination_attribute(:parent_id)
      end

      has_many :incidents_tables,
               AshUITutorials.ServicesAndIncidents.Examples.IncidentsTableElement do
        destination_attribute(:parent_id)
      end

      has_many :action_rows,
               AshUITutorials.ServicesAndIncidents.Examples.IncidentsActionRowElement do
        destination_attribute(:parent_id)
      end

      has_many :detail_cards,
               AshUITutorials.ServicesAndIncidents.Examples.IncidentsDetailCardElement do
        destination_attribute(:parent_id)
      end

      has_many :status_texts,
               AshUITutorials.ServicesAndIncidents.Examples.IncidentsStatusTextElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :incidents_tabs do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :incidents_tables do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :action_rows do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(0)
      end

      relationship :detail_cards do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end

      relationship :status_texts do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:card)
      props(%{title: "Incidents workspace", class: "ashui-example-panel ashui-tutorial-workspace-panel"})
      metadata(%{id: "incidents-workspace-panel", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.IncidentsTabsElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    relationships do
      has_many :services_tab_buttons,
               AshUITutorials.ServicesAndIncidents.Examples.ServicesTabButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :incidents_tab_buttons,
               AshUITutorials.ServicesAndIncidents.Examples.IncidentsTabButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :active_panels,
               AshUITutorials.ServicesAndIncidents.Examples.IncidentsActivePanelElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :services_tab_buttons do
        kind(:child)
        slot(:nav)
        placement(:append)
        order(0)
      end

      relationship :incidents_tab_buttons do
        kind(:child)
        slot(:nav)
        placement(:append)
        order(10)
      end

      relationship :active_panels do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:tabs")
      props(%{
        description: "The incidents screen keeps its own table while sharing detail state with the services view.",
        title: "Workspace focus",
        class: "ashui-example-tabs-shell"
      })

      metadata(%{id: "incidents-tabs", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.IncidentsActivePanelElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "incidents", class: "ashui-tutorial-tabs-panel ashui-tutorial-muted-copy"})
      metadata(%{id: "incidents-active-panel", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :selected_value do
        source(%{resource: "WorkspaceState", field: :selected_value, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "active_panel"})
      end
    end
  end

  defmodule Examples.IncidentsTableElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    ui_element do
      type(:table)
      props(%{
        title: "Active incidents",
        description: "Incident rows stay distinct from the services view while sharing the same runtime state.",
        columns: [
          %{"key" => "title", "label" => "Incident"},
          %{"key" => "severity", "label" => "Severity"},
          %{"key" => "service", "label" => "Service"},
          %{"key" => "state", "label" => "State"}
        ],
        class: "ashui-example-table-surface"
      })
      metadata(%{id: "incidents-table", section: "demo", slot: "body", position: 10})
    end

    ui_bindings do
      binding :incidents_items do
        source(%{resource: "WorkspaceState", field: :incidents, id: "tutorial-services-incidents-state"})
        target("items")
        binding_type(:list)
        transform(%{})
        metadata(%{owner: "incidents_table"})
      end
    end
  end

  defmodule Examples.IncidentsActionRowElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    relationships do
      has_many :gateway_latency_buttons,
               AshUITutorials.ServicesAndIncidents.Examples.FocusGatewayLatencyButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :search_lag_buttons,
               AshUITutorials.ServicesAndIncidents.Examples.FocusSearchLagButtonElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :gateway_latency_buttons do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :search_lag_buttons do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:row)
      props(%{class: "ashui-tutorial-toolbar", spacing: 12})
      metadata(%{id: "incidents-toolbar", section: "demo", slot: "actions", position: 0})
    end
  end

  defmodule Examples.FocusGatewayLatencyButtonElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Focus Gateway Latency", class: "ashui-example-primary-cta", variant: "primary"})
      metadata(%{id: "focus-gateway-latency", section: "demo", slot: "body", position: 0})
    end

    ui_actions do
      action :focus_gateway_latency do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")
        transform(%{
          params: %{
            detail_title: %{"from" => "static", "value" => "Gateway latency spike"},
            detail_summary: %{"from" => "static", "value" => "Tail latency exceeded SLA for external requests in the last 12 minutes."},
            detail_status: %{"from" => "static", "value" => "sev-1"},
            status: %{"from" => "static", "value" => "Incident detail focused on Gateway latency spike."}
          }
        })

        metadata(%{intent: "focus_incident", success_message: "Gateway incident loaded"})
      end
    end
  end

  defmodule Examples.FocusSearchLagButtonElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Focus Search Lag", class: "ashui-example-secondary-cta", variant: "secondary"})
      metadata(%{id: "focus-search-lag", section: "demo", slot: "body", position: 10})
    end

    ui_actions do
      action :focus_search_lag do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")
        transform(%{
          params: %{
            detail_title: %{"from" => "static", "value" => "Search replica lag"},
            detail_summary: %{"from" => "static", "value" => "Replica lag is elevated but recovery is trending in the right direction."},
            detail_status: %{"from" => "static", "value" => "sev-2"},
            status: %{"from" => "static", "value" => "Incident detail focused on Search replica lag."}
          }
        })

        metadata(%{intent: "focus_incident", success_message: "Search incident loaded"})
      end
    end
  end

  defmodule Examples.IncidentsDetailCardElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    relationships do
      has_many :detail_badges, AshUITutorials.ServicesAndIncidents.Examples.DetailBadgeElement do
        destination_attribute(:parent_id)
      end

      has_many :detail_titles, AshUITutorials.ServicesAndIncidents.Examples.DetailTitleElement do
        destination_attribute(:parent_id)
      end

      has_many :detail_summaries, AshUITutorials.ServicesAndIncidents.Examples.DetailSummaryElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :detail_badges do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :detail_titles do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :detail_summaries do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end
    end

    ui_element do
      type(:card)
      props(%{class: "ashui-tutorial-detail-card", title: "Incident detail"})
      metadata(%{id: "incidents-detail-card", section: "demo", slot: "footer", position: 0})
    end
  end

  defmodule Examples.IncidentsStatusTextElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "Active incidents are tracked in a tabular review surface.", class: "ashui-tutorial-muted-copy"})
      metadata(%{id: "incidents-status-text", section: "demo", slot: "footer", position: 10})
    end

    ui_bindings do
      binding :status do
        source(%{resource: "WorkspaceState", field: :status, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "status"})
      end
    end
  end

  defmodule Examples.IncidentsStoryTextElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    ui_element do
      type(:text)
      props(%{
        content:
          "Meaningful Interaction Story: move between the services list and incidents table, trigger a focus action, and confirm the shared detail card updates through the runtime state resource instead of isolated host markup.",
        class: "ashui-example-code-surface"
      })
      metadata(%{id: "incidents-story-text", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.IncidentsSignalTextElement do
    use AshUITutorials.ServicesAndIncidents.ExampleElementBase

    ui_element do
      type(:text)
      props(%{
        content:
          "Canonical Signal Preview: button click -> WorkspaceState.update(selected_value, detail_title, detail_summary, detail_status, status) -> hydrated list/table and detail shell across both screens.",
        class: "ashui-example-code-surface"
      })
      metadata(%{id: "incidents-signal-text", section: "signal_preview", slot: "body", position: 20})
    end
  end

  defmodule Examples.ServicesScreen do
    use Ash.Resource,
      domain: AshUITutorials.ServicesAndIncidents.AuthoringDomain,
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
      has_many :panels, AshUITutorials.ServicesAndIncidents.Examples.ServicesPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUITutorials.ServicesAndIncidents.Examples.ServicesStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUITutorials.ServicesAndIncidents.Examples.ServicesSignalTextElement do
        destination_attribute(:screen_id)
      end
    end

    ui_relationships do
      relationship :panels do
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
      metadata(%{title: "Services workspace", tutorial_directory: "02-services-and-incidents", shell_id: "tutorial-services-shell"})
    end
  end

  defmodule Examples.IncidentsScreen do
    use Ash.Resource,
      domain: AshUITutorials.ServicesAndIncidents.AuthoringDomain,
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
      has_many :panels, AshUITutorials.ServicesAndIncidents.Examples.IncidentsPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUITutorials.ServicesAndIncidents.Examples.IncidentsStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUITutorials.ServicesAndIncidents.Examples.IncidentsSignalTextElement do
        destination_attribute(:screen_id)
      end
    end

    ui_relationships do
      relationship :panels do
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
      route("/incidents")
      metadata(%{title: "Incidents workspace", tutorial_directory: "02-services-and-incidents", shell_id: "tutorial-incidents-shell"})
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUITutorials.ServicesAndIncidents.seed!(opts)
    def reset!, do: AshUITutorials.ServicesAndIncidents.reset!()
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

    scope "/", AshUITutorials.ServicesAndIncidents.Web do
      pipe_through(:browser)
      live("/", ServicesLive)
      live("/incidents", IncidentsLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_tutorial_services_and_incidents

    @session_options [
      store: :cookie,
      key: "_ash_ui_tutorial_services_and_incidents_key",
      signing_salt: "ashuitut23b"
    ]

    socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

    plug(Plug.RequestId)
    plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])
    plug(Plug.Session, @session_options)
    plug(AshUITutorials.ServicesAndIncidents.Web.Router)
  end

  defmodule Web.Components.TutorialShell do
    use Phoenix.Component

    attr(:title, :string, required: true)
    attr(:summary, :string, required: true)
    attr(:theme_css, :string, required: true)
    attr(:active_page, :string, required: true)
    slot(:inner_block, required: true)

    def tutorial_shell(assigns) do
      ~H"""
      <style><%= Phoenix.HTML.raw(@theme_css) %></style>
      <main class="ashui-example-shell">
        <header class="ashui-tutorial-shell-header">
          <p class="ashui-tutorial-shell-kicker">Ash UI Tutorial</p>
          <h1 class="ashui-tutorial-shell-title"><%= @title %></h1>
          <p class="ashui-tutorial-shell-summary"><%= @summary %></p>
          <nav class="ashui-tutorial-nav">
            <a href="/" class={["ashui-tutorial-nav-link", @active_page == "services" && "is-active"]}>Services</a>
            <a href="/incidents" class={["ashui-tutorial-nav-link", @active_page == "incidents" && "is-active"]}>Incidents</a>
          </nav>
        </header>
        <section class="ashui-tutorial-live-surface">
          <%= render_slot(@inner_block) %>
        </section>
      </main>
      """
    end
  end

  defmodule Web.ServicesLive do
    use Phoenix.LiveView

    alias AshUITutorials.ServicesAndIncidents.Web.Components.TutorialShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      AshUITutorials.ServicesAndIncidents.seed!()
      mount_screen(socket, params, :services)
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
      render_workspace(assigns, "services")
    end

    defp mount_screen(socket, params, screen_kind) do
      example_runtime = runtime_from_params(params)

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUITutorials.ServicesAndIncidents.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUITutorials.ServicesAndIncidents.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUITutorials.ServicesAndIncidents.runtime_domains())
        |> Phoenix.Component.assign(:page_title, AshUITutorials.ServicesAndIncidents.title())
        |> Phoenix.Component.assign(:theme_css, AshUITutorials.ServicesAndIncidents.theme_css())
        |> Phoenix.Component.assign(:example_runtime, example_runtime)
        |> Phoenix.Component.assign(:supported_runtimes, AshUITutorials.ServicesAndIncidents.supported_runtimes())
        |> Phoenix.Component.assign(:active_page, Atom.to_string(screen_kind))

      with {:ok, socket} <- Integration.mount_ui_screen(socket, AshUITutorials.ServicesAndIncidents.screen_name(screen_kind), params),
           {:ok, socket} <- EventHandler.wire_handlers(socket) do
        {:ok, refresh_rendered_ui(socket)}
      else
        {:error, reason} ->
          {:ok, Phoenix.Component.assign(socket, :rendered_ui, "Mount failed: #{inspect(reason)}")}
      end
    end

    defp render_workspace(assigns, active_page) do
      assigns =
        assigns
        |> Phoenix.Component.assign(:active_page, active_page)
        |> Phoenix.Component.assign_new(:supported_runtimes, fn -> AshUITutorials.ServicesAndIncidents.supported_runtimes() end)
        |> Phoenix.Component.assign_new(:example_runtime, fn -> AshUITutorials.ServicesAndIncidents.default_runtime() end)
        |> Phoenix.Component.assign_new(:rendered_runtime, fn ->
          %{
            content: assigns[:rendered_ui] || "",
            description: AshUITutorials.ServicesAndIncidents.runtime_description(AshUITutorials.ServicesAndIncidents.default_runtime()),
            mode: :live_fragment,
            runtime: AshUITutorials.ServicesAndIncidents.default_runtime()
          }
        end)

      ~H"""
      <TutorialShell.tutorial_shell title={@page_title} summary={AshUITutorials.ServicesAndIncidents.summary()} theme_css={@theme_css} active_page={@active_page}>
        <section class="ashui-example-panel ashui-tutorial-runtime-panel">
          <div>
            <h2>Runtime preview: <%= @rendered_runtime.runtime %></h2>
            <p class="ashui-tutorial-muted-copy"><%= @rendered_runtime.description %></p>
          </div>
          <div class="ashui-tutorial-runtime-actions">
            <%= for runtime <- @supported_runtimes do %>
              <code class="ashui-tutorial-runtime-command">mix example.start <%= runtime %></code>
            <% end %>
          </div>
        </section>
        <section class="ashui-tutorial-runtime-view">
          <%= case @rendered_runtime.mode do %>
            <% :html_document -> %>
              <iframe class="ashui-tutorial-runtime-frame" sandbox="allow-same-origin" srcdoc={@rendered_runtime.content} title={"services-and-incidents-#{@rendered_runtime.runtime}"} />
            <% :desktop_instructions -> %>
              <pre class="ashui-tutorial-runtime-pre"><%= @rendered_runtime.content %></pre>
            <% :live_fragment -> %>
              <%= Phoenix.HTML.raw(@rendered_runtime.content) %>
          <% end %>
        </section>
      </TutorialShell.tutorial_shell>
      """
    end

    defp refresh_rendered_ui(socket) do
      rendered_runtime =
        AshUITutorials.ServicesAndIncidents.rendered_runtime(
          socket.assigns,
          socket.assigns[:example_runtime] || AshUITutorials.ServicesAndIncidents.default_runtime()
        )

      socket
      |> Phoenix.Component.assign(:rendered_runtime, rendered_runtime)
      |> Phoenix.Component.assign(:rendered_ui, rendered_runtime.content)
    end

    defp runtime_from_params(params) do
      params["runtime"]
      |> fallback_runtime()
      |> AshUITutorials.ServicesAndIncidents.normalize_runtime!()
    end

    defp fallback_runtime(nil), do: System.get_env("ASH_UI_EXAMPLE_RUNTIME")
    defp fallback_runtime(runtime), do: runtime
  end

  defmodule Web.IncidentsLive do
    use Phoenix.LiveView

    alias AshUITutorials.ServicesAndIncidents.Web.Components.TutorialShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      AshUITutorials.ServicesAndIncidents.seed!()
      mount_screen(socket, params, :incidents)
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
      render_workspace(assigns, "incidents")
    end

    defp mount_screen(socket, params, screen_kind) do
      example_runtime = runtime_from_params(params)

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUITutorials.ServicesAndIncidents.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUITutorials.ServicesAndIncidents.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUITutorials.ServicesAndIncidents.runtime_domains())
        |> Phoenix.Component.assign(:page_title, AshUITutorials.ServicesAndIncidents.title())
        |> Phoenix.Component.assign(:theme_css, AshUITutorials.ServicesAndIncidents.theme_css())
        |> Phoenix.Component.assign(:example_runtime, example_runtime)
        |> Phoenix.Component.assign(:supported_runtimes, AshUITutorials.ServicesAndIncidents.supported_runtimes())
        |> Phoenix.Component.assign(:active_page, Atom.to_string(screen_kind))

      with {:ok, socket} <- Integration.mount_ui_screen(socket, AshUITutorials.ServicesAndIncidents.screen_name(screen_kind), params),
           {:ok, socket} <- EventHandler.wire_handlers(socket) do
        {:ok, refresh_rendered_ui(socket)}
      else
        {:error, reason} ->
          {:ok, Phoenix.Component.assign(socket, :rendered_ui, "Mount failed: #{inspect(reason)}")}
      end
    end

    defp render_workspace(assigns, active_page) do
      assigns =
        assigns
        |> Phoenix.Component.assign(:active_page, active_page)
        |> Phoenix.Component.assign_new(:supported_runtimes, fn -> AshUITutorials.ServicesAndIncidents.supported_runtimes() end)
        |> Phoenix.Component.assign_new(:example_runtime, fn -> AshUITutorials.ServicesAndIncidents.default_runtime() end)
        |> Phoenix.Component.assign_new(:rendered_runtime, fn ->
          %{
            content: assigns[:rendered_ui] || "",
            description: AshUITutorials.ServicesAndIncidents.runtime_description(AshUITutorials.ServicesAndIncidents.default_runtime()),
            mode: :live_fragment,
            runtime: AshUITutorials.ServicesAndIncidents.default_runtime()
          }
        end)

      ~H"""
      <TutorialShell.tutorial_shell title={@page_title} summary={AshUITutorials.ServicesAndIncidents.summary()} theme_css={@theme_css} active_page={@active_page}>
        <section class="ashui-example-panel ashui-tutorial-runtime-panel">
          <div>
            <h2>Runtime preview: <%= @rendered_runtime.runtime %></h2>
            <p class="ashui-tutorial-muted-copy"><%= @rendered_runtime.description %></p>
          </div>
          <div class="ashui-tutorial-runtime-actions">
            <%= for runtime <- @supported_runtimes do %>
              <code class="ashui-tutorial-runtime-command">mix example.start <%= runtime %></code>
            <% end %>
          </div>
        </section>
        <section class="ashui-tutorial-runtime-view">
          <%= case @rendered_runtime.mode do %>
            <% :html_document -> %>
              <iframe class="ashui-tutorial-runtime-frame" sandbox="allow-same-origin" srcdoc={@rendered_runtime.content} title={"services-and-incidents-#{@rendered_runtime.runtime}"} />
            <% :desktop_instructions -> %>
              <pre class="ashui-tutorial-runtime-pre"><%= @rendered_runtime.content %></pre>
            <% :live_fragment -> %>
              <%= Phoenix.HTML.raw(@rendered_runtime.content) %>
          <% end %>
        </section>
      </TutorialShell.tutorial_shell>
      """
    end

    defp refresh_rendered_ui(socket) do
      rendered_runtime =
        AshUITutorials.ServicesAndIncidents.rendered_runtime(
          socket.assigns,
          socket.assigns[:example_runtime] || AshUITutorials.ServicesAndIncidents.default_runtime()
        )

      socket
      |> Phoenix.Component.assign(:rendered_runtime, rendered_runtime)
      |> Phoenix.Component.assign(:rendered_ui, rendered_runtime.content)
    end

    defp runtime_from_params(params) do
      params["runtime"]
      |> fallback_runtime()
      |> AshUITutorials.ServicesAndIncidents.normalize_runtime!()
    end

    defp fallback_runtime(nil), do: System.get_env("ASH_UI_EXAMPLE_RUNTIME")
    defp fallback_runtime(runtime), do: runtime
  end
end
