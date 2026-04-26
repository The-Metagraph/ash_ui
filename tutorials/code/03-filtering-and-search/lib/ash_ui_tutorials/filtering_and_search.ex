defmodule AshUITutorials.FilteringAndSearch do
  @moduledoc """
  Standalone Chapter 3 checkpoint for the Operations Control Center tutorial.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.{DesktopUIAdapter, ElmUIAdapter, LiveUIAdapter}
  alias AshUI.Resource.Authority
  alias AshUI.Tutorials.Phase23, as: TutorialBaseline

  @app :ash_ui_tutorial_filtering_and_search
  @screen_names %{
    services: "tutorial/services-incidents/services",
    incidents: "tutorial/services-incidents/incidents"
  }
  @title "Filtering and Search Checkpoint"
  @summary "Standalone Chapter 3 checkpoint with persisted filters, quick search, and command navigation layered onto the shared services and incidents workspace."
  @story_text "Meaningful Interaction Story: filter services, narrow incidents, and use quick-jump commands to move the shared detail focus without falling back to host-only screen state."
  @signal_text "Canonical Signal Preview: input change -> WorkspaceState.update(service_query, service_status_filter, include_healthy, incident_severity_filter, incident_escalated_only, command_query) -> derived list/table props and shared workspace detail."
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
      domain: AshUITutorials.FilteringAndSearch.UiStorageDomain,
      resources: [
        screen: AshUITutorials.FilteringAndSearch.UiScreen,
        element: AshUITutorials.FilteringAndSearch.UiElement,
        binding: AshUITutorials.FilteringAndSearch.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUITutorials.FilteringAndSearch.RuntimeDomain]

  def actor_profile(role) do
    Enum.find(TutorialBaseline.actor_profiles(), &(&1.role == role))
  end

  def current_user, do: actor_profile(:on_call_operator)
  def authoring_actor, do: actor_profile(:admin)

  def service_catalog do
    TutorialBaseline.seed_fixtures().services
  end

  def incident_catalog do
    service_names =
      service_catalog()
      |> Map.new(&{&1.id, &1.name})

    TutorialBaseline.seed_fixtures().incidents
    |> Enum.map(fn incident ->
      %{
        id: incident.id,
        title: incident.title,
        severity: incident.severity,
        state: incident.state,
        owner: operator_label(incident.owner_id),
        service: Map.get(service_names, incident.service_id, incident.service_id),
        summary: incident.summary
      }
    end)
  end

  def hydrate_state(attrs) do
    attrs =
      attrs
      |> normalize_keys()
      |> Map.put_new(:service_catalog, service_catalog())
      |> Map.put_new(:incident_catalog, incident_catalog())
      |> Map.put_new(:selected_value, "services")
      |> Map.put_new(:service_query, "")
      |> Map.put_new(:service_status_filter, "all")
      |> Map.put_new(:include_healthy, true)
      |> Map.put_new(:incident_severity_filter, "all")
      |> Map.put_new(:incident_escalated_only, false)
      |> Map.put_new(:command_query, "")
      |> Map.put_new(:operator_view, "triage")

    visible_services =
      attrs
      |> Map.fetch!(:service_catalog)
      |> filter_services(
        Map.fetch!(attrs, :service_query),
        Map.fetch!(attrs, :service_status_filter),
        Map.fetch!(attrs, :include_healthy)
      )

    visible_incidents =
      attrs
      |> Map.fetch!(:incident_catalog)
      |> filter_incidents(
        Map.fetch!(attrs, :incident_severity_filter),
        Map.fetch!(attrs, :incident_escalated_only)
      )

    attrs
    |> Map.put(:services, visible_services)
    |> Map.put(:incidents, visible_incidents)
    |> Map.put(:current_value, workspace_label(attrs))
    |> Map.put(:services_status_copy, services_status_copy(attrs, visible_services))
    |> Map.put(:incidents_status_copy, incidents_status_copy(attrs, visible_incidents))
    |> Map.put(:command_summary, command_summary(attrs))
    |> ensure_detail_fields(visible_services, visible_incidents)
    |> ensure_status()
  end

  def seed_state do
    first_service = hd(service_catalog())

    hydrate_state(%{
      id: "tutorial-services-incidents-state",
      status: "Filtering workspace seeded. Adjust the controls to narrow the operational review surface.",
      selected_value: "services",
      detail_title: first_service.name,
      detail_summary: first_service.summary,
      detail_status: first_service.status,
      service_catalog: service_catalog(),
      incident_catalog: incident_catalog(),
      service_query: "",
      service_status_filter: "all",
      include_healthy: true,
      incident_severity_filter: "all",
      incident_escalated_only: false,
      command_query: "",
      operator_view: "triage"
    })
  end

  def reset! do
    reset_resource!(
      AshUITutorials.FilteringAndSearch.Runtime.WorkspaceState,
      AshUITutorials.FilteringAndSearch.RuntimeDomain
    )

    reset_resource!(
      AshUITutorials.FilteringAndSearch.UiBinding,
      AshUITutorials.FilteringAndSearch.UiStorageDomain
    )

    reset_resource!(
      AshUITutorials.FilteringAndSearch.UiElement,
      AshUITutorials.FilteringAndSearch.UiStorageDomain
    )

    reset_resource!(
      AshUITutorials.FilteringAndSearch.UiScreen,
      AshUITutorials.FilteringAndSearch.UiStorageDomain
    )

    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, authoring_actor())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUITutorials.FilteringAndSearch.Runtime.WorkspaceState,
        seed_state(),
        domain: AshUITutorials.FilteringAndSearch.RuntimeDomain,
        authorize?: false
      )

    {:ok, services_screen} =
      Authority.create(
        AshUITutorials.FilteringAndSearch.Examples.ServicesScreen,
        actor: actor,
        name: screen_name(:services),
        ui_storage: ui_storage()
      )

    {:ok, incidents_screen} =
      Authority.create(
        AshUITutorials.FilteringAndSearch.Examples.IncidentsScreen,
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

  defp normalize_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      Map.put(acc, normalize_key(key), value)
    end)
  end

  defp normalize_key(key) when is_atom(key), do: key

  defp normalize_key(key) when is_binary(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> key
    end
  end

  defp workspace_label(%{selected_value: "incidents"}), do: "incidents workspace"
  defp workspace_label(%{selected_value: "operator", operator_view: operator_view}), do: "#{operator_view} operator view"
  defp workspace_label(_attrs), do: "services workspace"

  defp services_status_copy(attrs, visible_services) do
    query = blank_to_phrase(attrs[:service_query], "all services")
    filter = attrs[:service_status_filter]
    include_healthy = attrs[:include_healthy]

    "#{length(visible_services)} services match #{query}; status filter=#{filter}, include healthy=#{include_healthy}."
  end

  defp incidents_status_copy(attrs, visible_incidents) do
    severity = attrs[:incident_severity_filter]
    escalated_only = attrs[:incident_escalated_only]

    "#{length(visible_incidents)} incidents remain in review; severity filter=#{severity}, escalated only=#{escalated_only}."
  end

  defp command_summary(attrs) do
    query = blank_to_phrase(attrs[:command_query], "no palette query")
    "#{workspace_label(attrs)} is active; command query=#{query}; operator focus=#{attrs[:operator_view]}."
  end

  defp blank_to_phrase(value, fallback) when value in [nil, ""], do: fallback
  defp blank_to_phrase(value, _fallback), do: inspect(value)

  defp ensure_detail_fields(attrs, visible_services, visible_incidents) do
    if present?(attrs[:detail_title]) do
      attrs
    else
      detail =
        case attrs[:selected_value] do
          "incidents" ->
            detail_from_incident(List.first(visible_incidents))

          "operator" ->
            %{
              detail_title: "Operator workflows",
              detail_summary: "Use the shared menu and command actions to move between triage, handoff, and maintenance planning views.",
              detail_status: attrs[:operator_view]
            }

          _other ->
            detail_from_service(List.first(visible_services))
        end

      Map.merge(attrs, detail)
    end
  end

  defp ensure_status(%{status: status} = attrs) when status not in [nil, ""], do: attrs

  defp ensure_status(attrs) do
    Map.put(attrs, :status, "Filtering workspace seeded. Adjust the controls to narrow the operational review surface.")
  end

  defp detail_from_service(nil) do
    %{
      detail_title: "No matching service",
      detail_summary: "Adjust the service filters to restore at least one service candidate.",
      detail_status: "empty"
    }
  end

  defp detail_from_service(service) do
    %{
      detail_title: service["title"],
      detail_summary: service["summary"],
      detail_status: extract_status_label(service["meta"])
    }
  end

  defp detail_from_incident(nil) do
    %{
      detail_title: "No matching incident",
      detail_summary: "Relax the incident filters to restore the active issue table.",
      detail_status: "empty"
    }
  end

  defp detail_from_incident(incident) do
    %{
      detail_title: incident["title"],
      detail_summary: "#{incident["service"]} • #{incident["state"]} • owner #{incident["owner"]}",
      detail_status: incident["severity"]
    }
  end

  defp extract_status_label(meta) when is_binary(meta) do
    meta
    |> String.split(" • ", parts: 2)
    |> List.first()
  end

  defp extract_status_label(_other), do: "review"

  defp filter_services(services, query, status_filter, include_healthy) do
    query = normalize_filter(query)
    status_filter = normalize_filter(status_filter)

    services
    |> Enum.filter(fn service ->
      query_match =
        query == "" ||
          String.contains?(String.downcase(service.name), query) ||
          String.contains?(String.downcase(service.summary), query)

      status_match = status_filter in ["", "all"] || String.downcase(service.status) == status_filter
      health_match = include_healthy || service.status != "healthy"
      query_match and status_match and health_match
    end)
    |> Enum.map(fn service ->
      %{
        "title" => service.name,
        "summary" => service.summary,
        "meta" => "#{service.status} • #{service.tier}"
      }
    end)
  end

  defp filter_incidents(incidents, severity_filter, escalated_only) do
    severity_filter = normalize_filter(severity_filter)

    incidents
    |> Enum.filter(fn incident ->
      severity_match =
        severity_filter in ["", "all"] || String.downcase(incident.severity) == severity_filter

      escalation_match = !escalated_only || incident.severity in ["sev-1", "sev-2"]
      severity_match and escalation_match
    end)
    |> Enum.map(fn incident ->
      %{
        "title" => incident.title,
        "severity" => incident.severity,
        "service" => incident.service,
        "state" => incident.state,
        "owner" => incident.owner
      }
    end)
  end

  defp normalize_filter(value) when value in [nil, false], do: ""
  defp normalize_filter(value) when is_boolean(value), do: value

  defp normalize_filter(value) do
    value
    |> to_string()
    |> String.trim()
    |> String.downcase()
  end

  defp present?(value) when value in [nil, ""], do: false
  defp present?(_value), do: true

  defp operator_label(operator_id) do
    case Enum.find(TutorialBaseline.actor_profiles(), &(&1.id == operator_id)) do
      %{name: name} -> name
      _other -> operator_id
    end
  end

  defmodule Application do
    use Elixir.Application

    def start(_type, _args) do
      children = [
        {Phoenix.PubSub, name: AshUITutorials.FilteringAndSearch.PubSub},
        AshUITutorials.FilteringAndSearch.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUITutorials.FilteringAndSearch.Runtime.WorkspaceState)
    end
  end

  defmodule Runtime.WorkspaceState do
    use Ash.Resource,
      domain: AshUITutorials.FilteringAndSearch.RuntimeDomain,
      authorizers: [Ash.Policy.Authorizer],
      data_layer: Ash.DataLayer.Ets

    @mutable_fields [
      :status,
      :current_value,
      :selected_value,
      :detail_title,
      :detail_summary,
      :detail_status,
      :service_catalog,
      :incident_catalog,
      :services,
      :incidents,
      :service_query,
      :service_status_filter,
      :include_healthy,
      :incident_severity_filter,
      :incident_escalated_only,
      :command_query,
      :command_summary,
      :operator_view,
      :services_status_copy,
      :incidents_status_copy
    ]

    ets do
      private?(true)
    end

    attributes do
      attribute :id, :string do
        primary_key?(true)
        allow_nil?(false)
      end

      attribute :status, :string, default: "Filtering workspace seeded. Adjust the controls to narrow the operational review surface."
      attribute :current_value, :string, default: "services workspace"
      attribute :selected_value, :string, default: "services"
      attribute :detail_title, :string, default: ""
      attribute :detail_summary, :string, default: ""
      attribute :detail_status, :string, default: ""
      attribute :service_catalog, {:array, :map}, default: []
      attribute :incident_catalog, {:array, :map}, default: []
      attribute :services, {:array, :map}, default: []
      attribute :incidents, {:array, :map}, default: []
      attribute :service_query, :string, default: ""
      attribute :service_status_filter, :string, default: "all"
      attribute :include_healthy, :boolean, default: true
      attribute :incident_severity_filter, :string, default: "all"
      attribute :incident_escalated_only, :boolean, default: false
      attribute :command_query, :string, default: ""
      attribute :command_summary, :string, default: ""
      attribute :operator_view, :string, default: "triage"
      attribute :services_status_copy, :string, default: ""
      attribute :incidents_status_copy, :string, default: ""
    end

    actions do
      defaults([:read, :destroy])

      create :create do
        primary?(true)
        accept([:id | @mutable_fields])
        change(before_action(fn changeset, _context -> hydrate_changeset(changeset) end))
      end

      update :update do
        primary?(true)
        accept(@mutable_fields)
        require_atomic? false
        change(before_action(fn changeset, _context -> hydrate_changeset(changeset) end))
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

    defp hydrate_changeset(changeset) do
      attrs =
        [:id | @mutable_fields]
        |> Enum.reduce(%{}, fn field, acc ->
          Map.put(acc, field, Ash.Changeset.get_attribute(changeset, field))
        end)

      hydrated = AshUITutorials.FilteringAndSearch.hydrate_state(attrs)

      Enum.reduce(@mutable_fields, changeset, fn field, acc ->
        Ash.Changeset.force_change_attribute(acc, field, Map.get(hydrated, field))
      end)
    end
  end

  defmodule UiStorageDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUITutorials.FilteringAndSearch.UiScreen)
      resource(AshUITutorials.FilteringAndSearch.UiElement)
      resource(AshUITutorials.FilteringAndSearch.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUITutorials.FilteringAndSearch.UiStorageDomain,
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
      has_many :elements, AshUITutorials.FilteringAndSearch.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUITutorials.FilteringAndSearch.UiBinding do
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
      domain: AshUITutorials.FilteringAndSearch.UiStorageDomain,
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
      belongs_to :screen, AshUITutorials.FilteringAndSearch.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUITutorials.FilteringAndSearch.UiBinding do
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
      domain: AshUITutorials.FilteringAndSearch.UiStorageDomain,
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
      belongs_to :element, AshUITutorials.FilteringAndSearch.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUITutorials.FilteringAndSearch.UiScreen do
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
      resource(AshUITutorials.FilteringAndSearch.Examples.ServicesScreen)
      resource(AshUITutorials.FilteringAndSearch.Examples.ServicesWorkspacePanelElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.WorkspaceMenuElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.ShowServicesButtonElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.ShowIncidentsButtonElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.ShowOperatorViewButtonElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.WorkspaceSelectionSummaryElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.CommandPaletteElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.CommandPaletteInputElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.CommandFocusGatewayButtonElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.CommandFocusIncidentButtonElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.CommandOpenOperatorViewButtonElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.CommandSummaryTextElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.ServicesFiltersGroupElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.ServicesQueryFieldElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.ServicesQueryInputElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.ServiceStatusFieldElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.ServiceStatusSelectElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.IncludeHealthyFieldElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.IncludeHealthyCheckboxElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.ServicesListElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.SharedDetailCardElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.SharedDetailBadgeElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.SharedDetailTitleElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.SharedDetailSummaryElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.ServicesStatusTextElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.ServicesStoryTextElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.ServicesSignalTextElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.IncidentsScreen)
      resource(AshUITutorials.FilteringAndSearch.Examples.IncidentsWorkspacePanelElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.IncidentsFiltersGroupElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.IncidentSeverityFieldElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.IncidentSeverityRadioElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.IncidentEscalatedFieldElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.IncidentEscalatedSwitchElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.IncidentsTableElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.IncidentsStatusTextElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.IncidentsStoryTextElement)
      resource(AshUITutorials.FilteringAndSearch.Examples.IncidentsSignalTextElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUITutorials.FilteringAndSearch.AuthoringDomain,
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

  defmodule Examples.ServicesWorkspacePanelElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    relationships do
      has_many :menus, AshUITutorials.FilteringAndSearch.Examples.WorkspaceMenuElement do
        destination_attribute(:parent_id)
      end

      has_many :command_palettes,
               AshUITutorials.FilteringAndSearch.Examples.CommandPaletteElement do
        destination_attribute(:parent_id)
      end

      has_many :filter_groups,
               AshUITutorials.FilteringAndSearch.Examples.ServicesFiltersGroupElement do
        destination_attribute(:parent_id)
      end

      has_many :service_lists, AshUITutorials.FilteringAndSearch.Examples.ServicesListElement do
        destination_attribute(:parent_id)
      end

      has_many :detail_cards, AshUITutorials.FilteringAndSearch.Examples.SharedDetailCardElement do
        destination_attribute(:parent_id)
      end

      has_many :status_texts, AshUITutorials.FilteringAndSearch.Examples.ServicesStatusTextElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :menus do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :command_palettes do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :filter_groups do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end

      relationship :service_lists do
        kind(:child)
        slot(:body)
        placement(:append)
        order(30)
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

  defmodule Examples.WorkspaceMenuElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    relationships do
      has_many :services_buttons, AshUITutorials.FilteringAndSearch.Examples.ShowServicesButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :incidents_buttons,
               AshUITutorials.FilteringAndSearch.Examples.ShowIncidentsButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :operator_buttons,
               AshUITutorials.FilteringAndSearch.Examples.ShowOperatorViewButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :selection_summaries,
               AshUITutorials.FilteringAndSearch.Examples.WorkspaceSelectionSummaryElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :services_buttons do
        kind(:child)
        slot(:nav)
        placement(:append)
        order(0)
      end

      relationship :incidents_buttons do
        kind(:child)
        slot(:nav)
        placement(:append)
        order(10)
      end

      relationship :operator_buttons do
        kind(:child)
        slot(:nav)
        placement(:append)
        order(20)
      end

      relationship :selection_summaries do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:menu")

      props(%{
        title: "Quick jumps",
        description: "Move the shared workspace focus between services, incidents, and operator review modes.",
        class: "ashui-example-menu-surface"
      })

      metadata(%{id: "workspace-menu", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.ShowServicesButtonElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Services view", class: "ashui-example-primary-cta", variant: "secondary"})
      metadata(%{id: "show-services-workspace", section: "demo", slot: "nav", position: 0})
    end

    ui_actions do
      action :show_services_workspace do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            selected_value: %{"from" => "static", "value" => "services"},
            detail_title: %{"from" => "static", "value" => "API Gateway"},
            detail_summary: %{"from" => "static", "value" => "Ingress service handling public traffic and auth fan-out."},
            detail_status: %{"from" => "static", "value" => "degraded"},
            status: %{"from" => "static", "value" => "Quick jump restored the services workspace."}
          }
        })

        metadata(%{intent: "select_workspace", success_message: "Services workspace loaded"})
      end
    end
  end

  defmodule Examples.ShowIncidentsButtonElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Incidents view", class: "ashui-example-secondary-cta", variant: "secondary"})
      metadata(%{id: "show-incidents-workspace", section: "demo", slot: "nav", position: 10})
    end

    ui_actions do
      action :show_incidents_workspace do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            selected_value: %{"from" => "static", "value" => "incidents"},
            detail_title: %{"from" => "static", "value" => "Gateway latency spike"},
            detail_summary: %{"from" => "static", "value" => "Tail latency exceeded SLA for external requests in the last 12 minutes."},
            detail_status: %{"from" => "static", "value" => "sev-1"},
            status: %{"from" => "static", "value" => "Quick jump switched the detail card to incident review."}
          }
        })

        metadata(%{intent: "select_workspace", success_message: "Incidents workspace loaded"})
      end
    end
  end

  defmodule Examples.ShowOperatorViewButtonElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Operator view", class: "ashui-example-secondary-cta", variant: "secondary"})
      metadata(%{id: "show-operator-view", section: "demo", slot: "nav", position: 20})
    end

    ui_actions do
      action :show_operator_view do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            selected_value: %{"from" => "static", "value" => "operator"},
            operator_view: %{"from" => "static", "value" => "triage"},
            detail_title: %{"from" => "static", "value" => "Operator workflows"},
            detail_summary: %{"from" => "static", "value" => "The operator view is ready for maintenance planning and incident handoff work introduced in later chapters."},
            detail_status: %{"from" => "static", "value" => "triage"},
            status: %{"from" => "static", "value" => "Quick jump opened the operator workflow preview."}
          }
        })

        metadata(%{intent: "select_operator_view", success_message: "Operator view preview loaded"})
      end
    end
  end

  defmodule Examples.WorkspaceSelectionSummaryElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "services workspace", class: "ashui-tutorial-muted-copy"})
      metadata(%{id: "workspace-selection-summary", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :current_value do
        source(%{resource: "WorkspaceState", field: :current_value, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "workspace_summary"})
      end
    end
  end

  defmodule Examples.CommandPaletteElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    relationships do
      has_many :search_inputs,
               AshUITutorials.FilteringAndSearch.Examples.CommandPaletteInputElement do
        destination_attribute(:parent_id)
      end

      has_many :gateway_buttons,
               AshUITutorials.FilteringAndSearch.Examples.CommandFocusGatewayButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :incident_buttons,
               AshUITutorials.FilteringAndSearch.Examples.CommandFocusIncidentButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :operator_buttons,
               AshUITutorials.FilteringAndSearch.Examples.CommandOpenOperatorViewButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :summary_texts,
               AshUITutorials.FilteringAndSearch.Examples.CommandSummaryTextElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :search_inputs do
        kind(:child)
        slot(:search)
        placement(:append)
        order(0)
      end

      relationship :gateway_buttons do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :incident_buttons do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :operator_buttons do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end

      relationship :summary_texts do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:command_palette")

      props(%{
        title: "Command palette",
        description: "Persist the search term, then use explicit commands to narrow services, incidents, or operator focus.",
        class: "ashui-example-command-palette"
      })

      metadata(%{id: "workspace-command-palette", section: "demo", slot: "body", position: 10})
    end
  end

  defmodule Examples.CommandPaletteInputElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:input)

      props(%{
        name: "command_query",
        type: "text",
        value: "",
        placeholder: "Filter commands by intent",
        class: "ashui-example-input"
      })

      metadata(%{id: "workspace-command-query", section: "demo", slot: "search", position: 0})
    end

    ui_bindings do
      binding :command_query do
        source(%{resource: "WorkspaceState", field: :command_query, id: "tutorial-services-incidents-state"})
        target("command_query")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "command_query", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.CommandFocusGatewayButtonElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Focus API Gateway", class: "ashui-example-primary-cta", variant: "primary"})
      metadata(%{id: "command-focus-gateway", section: "demo", slot: "body", position: 0})
    end

    ui_actions do
      action :focus_gateway do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            selected_value: %{"from" => "static", "value" => "services"},
            service_query: %{"from" => "static", "value" => "gateway"},
            detail_title: %{"from" => "static", "value" => "API Gateway"},
            detail_summary: %{"from" => "static", "value" => "Ingress service handling public traffic and auth fan-out."},
            detail_status: %{"from" => "static", "value" => "degraded"},
            status: %{"from" => "static", "value" => "Command palette narrowed the services review to API Gateway."}
          }
        })

        metadata(%{intent: "focus_service", success_message: "Gateway command applied"})
      end
    end
  end

  defmodule Examples.CommandFocusIncidentButtonElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Focus Sev-1 incidents", class: "ashui-example-secondary-cta", variant: "secondary"})
      metadata(%{id: "command-focus-incidents", section: "demo", slot: "body", position: 10})
    end

    ui_actions do
      action :focus_sev_one_incidents do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            selected_value: %{"from" => "static", "value" => "incidents"},
            incident_severity_filter: %{"from" => "static", "value" => "sev-1"},
            detail_title: %{"from" => "static", "value" => "Gateway latency spike"},
            detail_summary: %{"from" => "static", "value" => "Tail latency exceeded SLA for external requests in the last 12 minutes."},
            detail_status: %{"from" => "static", "value" => "sev-1"},
            status: %{"from" => "static", "value" => "Command palette narrowed the incident table to sev-1 review."}
          }
        })

        metadata(%{intent: "focus_incidents", success_message: "Sev-1 incident command applied"})
      end
    end
  end

  defmodule Examples.CommandOpenOperatorViewButtonElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Open maintenance planner", class: "ashui-example-secondary-cta", variant: "secondary"})
      metadata(%{id: "command-open-operator-view", section: "demo", slot: "body", position: 20})
    end

    ui_actions do
      action :open_maintenance_planner do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            selected_value: %{"from" => "static", "value" => "operator"},
            operator_view: %{"from" => "static", "value" => "maintenance planner"},
            detail_title: %{"from" => "static", "value" => "Maintenance planner"},
            detail_summary: %{"from" => "static", "value" => "Operator review is now centered on the maintenance workflow that Chapter 4 turns into a real form."},
            detail_status: %{"from" => "static", "value" => "maintenance planner"},
            status: %{"from" => "static", "value" => "Command palette staged the maintenance planner operator view."}
          }
        })

        metadata(%{intent: "open_operator_view", success_message: "Maintenance planner preview loaded"})
      end
    end
  end

  defmodule Examples.CommandSummaryTextElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-muted-copy"})
      metadata(%{id: "command-summary", section: "demo", slot: "footer", position: 0})
    end

    ui_bindings do
      binding :command_summary do
        source(%{resource: "WorkspaceState", field: :command_summary, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "command_summary"})
      end
    end
  end

  defmodule Examples.ServicesFiltersGroupElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    relationships do
      has_many :query_fields,
               AshUITutorials.FilteringAndSearch.Examples.ServicesQueryFieldElement do
        destination_attribute(:parent_id)
      end

      has_many :status_fields,
               AshUITutorials.FilteringAndSearch.Examples.ServiceStatusFieldElement do
        destination_attribute(:parent_id)
      end

      has_many :healthy_fields,
               AshUITutorials.FilteringAndSearch.Examples.IncludeHealthyFieldElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :query_fields do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :status_fields do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :healthy_fields do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end
    end

    ui_element do
      type(:"custom:field_group")

      props(%{
        title: "Service filters",
        description: "Persist the query and health controls in the shared workspace state resource.",
        class: "ashui-example-form"
      })

      metadata(%{id: "services-filter-group", section: "demo", slot: "body", position: 20})
    end
  end

  defmodule Examples.ServicesQueryFieldElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    relationships do
      has_many :inputs,
               AshUITutorials.FilteringAndSearch.Examples.ServicesQueryInputElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :inputs do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:form_field)

      props(%{
        label: "Service search",
        name: "service_query",
        help: "Narrow the services list by name or summary.",
        class: "ashui-example-form-field"
      })

      metadata(%{id: "services-query-field", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.ServicesQueryInputElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:input)

      props(%{
        name: "service_query",
        type: "text",
        value: "",
        placeholder: "gateway, billing, search",
        class: "ashui-example-input"
      })

      metadata(%{id: "services-query-input", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :service_query do
        source(%{resource: "WorkspaceState", field: :service_query, id: "tutorial-services-incidents-state"})
        target("service_query")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "service_query", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.ServiceStatusFieldElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    relationships do
      has_many :selects,
               AshUITutorials.FilteringAndSearch.Examples.ServiceStatusSelectElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :selects do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:form_field)

      props(%{
        label: "Status filter",
        name: "service_status_filter",
        help: "Keep all services or narrow to one health state.",
        class: "ashui-example-form-field"
      })

      metadata(%{id: "service-status-field", section: "demo", slot: "body", position: 10})
    end
  end

  defmodule Examples.ServiceStatusSelectElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:select)

      props(%{
        name: "service_status_filter",
        value: "all",
        options: [{"All", "all"}, {"Degraded", "degraded"}, {"Healthy", "healthy"}, {"Monitoring", "monitoring"}],
        class: "ashui-example-select"
      })

      metadata(%{id: "service-status-select", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :service_status_filter do
        source(%{resource: "WorkspaceState", field: :service_status_filter, id: "tutorial-services-incidents-state"})
        target("service_status_filter")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "service_status_filter", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.IncludeHealthyFieldElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    relationships do
      has_many :checkboxes,
               AshUITutorials.FilteringAndSearch.Examples.IncludeHealthyCheckboxElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :checkboxes do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:form_field)

      props(%{
        label: "Include healthy services",
        name: "include_healthy",
        help: "Turn this off to focus the service list on problem candidates.",
        class: "ashui-example-form-field"
      })

      metadata(%{id: "include-healthy-field", section: "demo", slot: "body", position: 20})
    end
  end

  defmodule Examples.IncludeHealthyCheckboxElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:checkbox)
      props(%{name: "include_healthy", checked: true, class: "ashui-example-checkbox"})
      metadata(%{id: "include-healthy-checkbox", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :include_healthy do
        source(%{resource: "WorkspaceState", field: :include_healthy, id: "tutorial-services-incidents-state"})
        target("include_healthy")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "include_healthy", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.ServicesListElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:list)

      props(%{
        title: "Filtered services",
        description: "Services are grouped by query and health state.",
        class: "ashui-example-list-surface",
        empty_text: "No services match the current filters."
      })

      metadata(%{id: "services-list", section: "demo", slot: "body", position: 30})
    end

    ui_bindings do
      binding :services_items do
        source(%{resource: "WorkspaceState", field: :services, id: "tutorial-services-incidents-state"})
        target("items")
        binding_type(:list)
        transform(%{})
        metadata(%{owner: "services_list"})
      end

      binding :services_description do
        source(%{resource: "WorkspaceState", field: :services_status_copy, id: "tutorial-services-incidents-state"})
        target("description")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "services_list"})
      end
    end
  end

  defmodule Examples.SharedDetailCardElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    relationships do
      has_many :badges, AshUITutorials.FilteringAndSearch.Examples.SharedDetailBadgeElement do
        destination_attribute(:parent_id)
      end

      has_many :titles, AshUITutorials.FilteringAndSearch.Examples.SharedDetailTitleElement do
        destination_attribute(:parent_id)
      end

      has_many :summaries, AshUITutorials.FilteringAndSearch.Examples.SharedDetailSummaryElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :badges do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :titles do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :summaries do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end
    end

    ui_element do
      type(:card)
      props(%{class: "ashui-tutorial-detail-card", title: "Shared detail"})
      metadata(%{id: "shared-detail-card", section: "demo", slot: "footer", position: 0})
    end
  end

  defmodule Examples.SharedDetailBadgeElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:badge)
      props(%{content: "review", class: "ashui-tutorial-status-pill"})
      metadata(%{id: "shared-detail-badge", section: "demo", slot: "body", position: 0})
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

  defmodule Examples.SharedDetailTitleElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-detail-title"})
      metadata(%{id: "shared-detail-title", section: "demo", slot: "body", position: 10})
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

  defmodule Examples.SharedDetailSummaryElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-detail-copy"})
      metadata(%{id: "shared-detail-summary", section: "demo", slot: "body", position: 20})
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
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-muted-copy"})
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
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: persist a service query, narrow the status filter, and then use the command palette to move the shared detail focus without rebuilding the host shell by hand.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "services-story-text", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.ServicesSignalTextElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: change -> WorkspaceState.service_query/service_status_filter/include_healthy; click -> WorkspaceState.selected_value/detail/status; hydrate -> filtered services list and shared detail card.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "services-signal-text", section: "signal_preview", slot: "body", position: 20})
    end
  end

  defmodule Examples.IncidentsWorkspacePanelElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    relationships do
      has_many :menus, AshUITutorials.FilteringAndSearch.Examples.WorkspaceMenuElement do
        destination_attribute(:parent_id)
      end

      has_many :filter_groups,
               AshUITutorials.FilteringAndSearch.Examples.IncidentsFiltersGroupElement do
        destination_attribute(:parent_id)
      end

      has_many :incident_tables,
               AshUITutorials.FilteringAndSearch.Examples.IncidentsTableElement do
        destination_attribute(:parent_id)
      end

      has_many :detail_cards, AshUITutorials.FilteringAndSearch.Examples.SharedDetailCardElement do
        destination_attribute(:parent_id)
      end

      has_many :status_texts, AshUITutorials.FilteringAndSearch.Examples.IncidentsStatusTextElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :menus do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :filter_groups do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :incident_tables do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
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

  defmodule Examples.IncidentsFiltersGroupElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    relationships do
      has_many :severity_fields,
               AshUITutorials.FilteringAndSearch.Examples.IncidentSeverityFieldElement do
        destination_attribute(:parent_id)
      end

      has_many :escalated_fields,
               AshUITutorials.FilteringAndSearch.Examples.IncidentEscalatedFieldElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :severity_fields do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :escalated_fields do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:"custom:field_group")

      props(%{
        title: "Incident filters",
        description: "Drive the table through persisted severity and escalation controls.",
        class: "ashui-example-form"
      })

      metadata(%{id: "incidents-filter-group", section: "demo", slot: "body", position: 10})
    end
  end

  defmodule Examples.IncidentSeverityFieldElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    relationships do
      has_many :radios,
               AshUITutorials.FilteringAndSearch.Examples.IncidentSeverityRadioElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :radios do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:form_field)

      props(%{
        label: "Severity focus",
        name: "incident_severity_filter",
        help: "Switch between all incidents and one severity band.",
        class: "ashui-example-form-field"
      })

      metadata(%{id: "incident-severity-field", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.IncidentSeverityRadioElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:radio)

      props(%{
        name: "incident_severity_filter",
        value: "all",
        options: [{"All", "all"}, {"Sev-1", "sev-1"}, {"Sev-2", "sev-2"}],
        class: "ashui-example-radio-group"
      })

      metadata(%{id: "incident-severity-radio", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :incident_severity_filter do
        source(%{resource: "WorkspaceState", field: :incident_severity_filter, id: "tutorial-services-incidents-state"})
        target("incident_severity_filter")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "incident_severity_filter", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.IncidentEscalatedFieldElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    relationships do
      has_many :switches,
               AshUITutorials.FilteringAndSearch.Examples.IncidentEscalatedSwitchElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :switches do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:form_field)

      props(%{
        label: "Escalated only",
        name: "incident_escalated_only",
        help: "Flip this on to focus the table on sev-1 and sev-2 review.",
        class: "ashui-example-form-field"
      })

      metadata(%{id: "incident-escalated-field", section: "demo", slot: "body", position: 10})
    end
  end

  defmodule Examples.IncidentEscalatedSwitchElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:switch)
      props(%{label: "Escalated only", checked: false, class: "ashui-example-toggle"})
      metadata(%{id: "incident-escalated-switch", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :incident_escalated_only do
        source(%{resource: "WorkspaceState", field: :incident_escalated_only, id: "tutorial-services-incidents-state"})
        target("incident_escalated_only")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "incident_escalated_only", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.IncidentsTableElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:table)

      props(%{
        title: "Filtered incidents",
        description: "Incident rows move with the severity and escalation controls.",
        columns: [
          %{"key" => "title", "label" => "Incident"},
          %{"key" => "severity", "label" => "Severity"},
          %{"key" => "service", "label" => "Service"},
          %{"key" => "state", "label" => "State"},
          %{"key" => "owner", "label" => "Owner"}
        ],
        class: "ashui-example-table-surface"
      })

      metadata(%{id: "incidents-table", section: "demo", slot: "body", position: 20})
    end

    ui_bindings do
      binding :incidents_items do
        source(%{resource: "WorkspaceState", field: :incidents, id: "tutorial-services-incidents-state"})
        target("items")
        binding_type(:list)
        transform(%{})
        metadata(%{owner: "incidents_table"})
      end

      binding :incidents_description do
        source(%{resource: "WorkspaceState", field: :incidents_status_copy, id: "tutorial-services-incidents-state"})
        target("description")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "incidents_table"})
      end
    end
  end

  defmodule Examples.IncidentsStatusTextElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-muted-copy"})
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
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: narrow the incident table through the persisted severity radio group and escalation toggle, then confirm the same shared detail card can still pivot through quick-jump actions.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "incidents-story-text", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.IncidentsSignalTextElement do
    use AshUITutorials.FilteringAndSearch.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: change -> WorkspaceState.incident_severity_filter/incident_escalated_only -> hydrated incidents table; quick jump click -> shared detail and workspace status.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "incidents-signal-text", section: "signal_preview", slot: "body", position: 20})
    end
  end

  defmodule Examples.ServicesScreen do
    use Ash.Resource,
      domain: AshUITutorials.FilteringAndSearch.AuthoringDomain,
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
      has_many :panels, AshUITutorials.FilteringAndSearch.Examples.ServicesWorkspacePanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUITutorials.FilteringAndSearch.Examples.ServicesStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUITutorials.FilteringAndSearch.Examples.ServicesSignalTextElement do
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

      metadata(%{
        title: "Services workspace",
        tutorial_directory: "03-filtering-and-search",
        shell_id: "operations-control-center-services-shell"
      })
    end
  end

  defmodule Examples.IncidentsScreen do
    use Ash.Resource,
      domain: AshUITutorials.FilteringAndSearch.AuthoringDomain,
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
      has_many :panels, AshUITutorials.FilteringAndSearch.Examples.IncidentsWorkspacePanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUITutorials.FilteringAndSearch.Examples.IncidentsStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUITutorials.FilteringAndSearch.Examples.IncidentsSignalTextElement do
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

      metadata(%{
        title: "Incidents workspace",
        tutorial_directory: "03-filtering-and-search",
        shell_id: "operations-control-center-incidents-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUITutorials.FilteringAndSearch.seed!(opts)
    def reset!, do: AshUITutorials.FilteringAndSearch.reset!()
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

    scope "/", AshUITutorials.FilteringAndSearch.Web do
      pipe_through(:browser)
      live("/", ServicesLive)
      live("/incidents", IncidentsLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_tutorial_filtering_and_search

    @session_options [
      store: :cookie,
      key: "_ash_ui_tutorial_filtering_and_search_key",
      signing_salt: "ashuitut23b"
    ]

    socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

    plug(Plug.RequestId)
    plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])
    plug(Plug.Session, @session_options)
    plug(AshUITutorials.FilteringAndSearch.Web.Router)
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

    alias AshUITutorials.FilteringAndSearch.Web.Components.TutorialShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      AshUITutorials.FilteringAndSearch.seed!()
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
        |> Phoenix.Component.assign(:current_user, AshUITutorials.FilteringAndSearch.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUITutorials.FilteringAndSearch.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUITutorials.FilteringAndSearch.runtime_domains())
        |> Phoenix.Component.assign(:page_title, AshUITutorials.FilteringAndSearch.title())
        |> Phoenix.Component.assign(:theme_css, AshUITutorials.FilteringAndSearch.theme_css())
        |> Phoenix.Component.assign(:example_runtime, example_runtime)
        |> Phoenix.Component.assign(:supported_runtimes, AshUITutorials.FilteringAndSearch.supported_runtimes())
        |> Phoenix.Component.assign(:active_page, Atom.to_string(screen_kind))

      with {:ok, socket} <- Integration.mount_ui_screen(socket, AshUITutorials.FilteringAndSearch.screen_name(screen_kind), params),
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
        |> Phoenix.Component.assign_new(:supported_runtimes, fn -> AshUITutorials.FilteringAndSearch.supported_runtimes() end)
        |> Phoenix.Component.assign_new(:example_runtime, fn -> AshUITutorials.FilteringAndSearch.default_runtime() end)
        |> Phoenix.Component.assign_new(:rendered_runtime, fn ->
          %{
            content: assigns[:rendered_ui] || "",
            description: AshUITutorials.FilteringAndSearch.runtime_description(AshUITutorials.FilteringAndSearch.default_runtime()),
            mode: :live_fragment,
            runtime: AshUITutorials.FilteringAndSearch.default_runtime()
          }
        end)

      ~H"""
      <TutorialShell.tutorial_shell title={@page_title} summary={AshUITutorials.FilteringAndSearch.summary()} theme_css={@theme_css} active_page={@active_page}>
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
              <iframe class="ashui-tutorial-runtime-frame" sandbox="allow-same-origin" srcdoc={@rendered_runtime.content} title={"operations-control-center-#{@rendered_runtime.runtime}"} />
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
        AshUITutorials.FilteringAndSearch.rendered_runtime(
          socket.assigns,
          socket.assigns[:example_runtime] || AshUITutorials.FilteringAndSearch.default_runtime()
        )

      socket
      |> Phoenix.Component.assign(:rendered_runtime, rendered_runtime)
      |> Phoenix.Component.assign(:rendered_ui, rendered_runtime.content)
    end

    defp runtime_from_params(params) do
      params["runtime"]
      |> fallback_runtime()
      |> AshUITutorials.FilteringAndSearch.normalize_runtime!()
    end

    defp fallback_runtime(nil), do: System.get_env("ASH_UI_EXAMPLE_RUNTIME")
    defp fallback_runtime(runtime), do: runtime
  end

  defmodule Web.IncidentsLive do
    use Phoenix.LiveView

    alias AshUITutorials.FilteringAndSearch.Web.Components.TutorialShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      AshUITutorials.FilteringAndSearch.seed!()
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
        |> Phoenix.Component.assign(:current_user, AshUITutorials.FilteringAndSearch.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUITutorials.FilteringAndSearch.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUITutorials.FilteringAndSearch.runtime_domains())
        |> Phoenix.Component.assign(:page_title, AshUITutorials.FilteringAndSearch.title())
        |> Phoenix.Component.assign(:theme_css, AshUITutorials.FilteringAndSearch.theme_css())
        |> Phoenix.Component.assign(:example_runtime, example_runtime)
        |> Phoenix.Component.assign(:supported_runtimes, AshUITutorials.FilteringAndSearch.supported_runtimes())
        |> Phoenix.Component.assign(:active_page, Atom.to_string(screen_kind))

      with {:ok, socket} <- Integration.mount_ui_screen(socket, AshUITutorials.FilteringAndSearch.screen_name(screen_kind), params),
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
        |> Phoenix.Component.assign_new(:supported_runtimes, fn -> AshUITutorials.FilteringAndSearch.supported_runtimes() end)
        |> Phoenix.Component.assign_new(:example_runtime, fn -> AshUITutorials.FilteringAndSearch.default_runtime() end)
        |> Phoenix.Component.assign_new(:rendered_runtime, fn ->
          %{
            content: assigns[:rendered_ui] || "",
            description: AshUITutorials.FilteringAndSearch.runtime_description(AshUITutorials.FilteringAndSearch.default_runtime()),
            mode: :live_fragment,
            runtime: AshUITutorials.FilteringAndSearch.default_runtime()
          }
        end)

      ~H"""
      <TutorialShell.tutorial_shell title={@page_title} summary={AshUITutorials.FilteringAndSearch.summary()} theme_css={@theme_css} active_page={@active_page}>
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
              <iframe class="ashui-tutorial-runtime-frame" sandbox="allow-same-origin" srcdoc={@rendered_runtime.content} title={"operations-control-center-#{@rendered_runtime.runtime}"} />
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
        AshUITutorials.FilteringAndSearch.rendered_runtime(
          socket.assigns,
          socket.assigns[:example_runtime] || AshUITutorials.FilteringAndSearch.default_runtime()
        )

      socket
      |> Phoenix.Component.assign(:rendered_runtime, rendered_runtime)
      |> Phoenix.Component.assign(:rendered_ui, rendered_runtime.content)
    end

    defp runtime_from_params(params) do
      params["runtime"]
      |> fallback_runtime()
      |> AshUITutorials.FilteringAndSearch.normalize_runtime!()
    end

    defp fallback_runtime(nil), do: System.get_env("ASH_UI_EXAMPLE_RUNTIME")
    defp fallback_runtime(runtime), do: runtime
  end
end
