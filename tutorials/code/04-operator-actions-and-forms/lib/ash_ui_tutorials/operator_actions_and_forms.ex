defmodule AshUITutorials.OperatorActionsAndForms do
  @moduledoc """
  Standalone Chapter 4 checkpoint for the Operations Control Center tutorial.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.{DesktopUIAdapter, ElmUIAdapter, LiveUIAdapter}
  alias AshUI.Resource.Authority
  alias AshUI.Tutorials.Phase23, as: TutorialBaseline

  @app :ash_ui_tutorial_operator_actions_and_forms
  @screen_names %{
    services: "tutorial/services-incidents/services",
    incidents: "tutorial/services-incidents/incidents"
  }
  @title "Operator Actions and Forms Checkpoint"
  @summary "Standalone Chapter 4 checkpoint with persisted filters, command navigation, and the first resource-backed operator write workflows."
  @story_text "Meaningful Interaction Story: filter services, narrow incidents, then acknowledge, assign, or schedule maintenance through authored form resources that write back into the shared workspace state."
  @signal_text "Canonical Signal Preview: input change -> WorkspaceState.update(...) -> derived list/table props; action click -> WorkspaceState.submit_operator_workflow(workflow_intent, operator_note, assignment_target, maintenance window fields) -> feedback, disabled states, and shared detail updates."
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
      domain: AshUITutorials.OperatorActionsAndForms.UiStorageDomain,
      resources: [
        screen: AshUITutorials.OperatorActionsAndForms.UiScreen,
        element: AshUITutorials.OperatorActionsAndForms.UiElement,
        binding: AshUITutorials.OperatorActionsAndForms.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUITutorials.OperatorActionsAndForms.RuntimeDomain]

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
      |> Map.put_new(:operator_note, "")
      |> Map.put_new(:assignment_target, "incident-commander")
      |> Map.put_new(:maintenance_duration_minutes, nil)
      |> Map.put_new(:maintenance_date, "")
      |> Map.put_new(:maintenance_time, "")
      |> Map.put_new(:acknowledge_disabled, true)
      |> Map.put_new(:assign_disabled, true)
      |> Map.put_new(:maintenance_disabled, true)
      |> Map.put_new(:form_feedback_title, "Operator workflows are idle")
      |> Map.put_new(:form_feedback_summary, "Add a note, choose an assignment target, or schedule a maintenance window.")
      |> Map.put_new(:form_feedback_status, "idle")
      |> Map.update(:maintenance_duration_minutes, nil, &normalize_duration/1)

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
    |> Map.put(:acknowledge_disabled, acknowledge_disabled?(attrs))
    |> Map.put(:assign_disabled, assign_disabled?(attrs))
    |> Map.put(:maintenance_disabled, maintenance_disabled?(attrs))
    |> ensure_detail_fields(visible_services, visible_incidents)
    |> ensure_status()
    |> ensure_form_feedback()
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
      AshUITutorials.OperatorActionsAndForms.Runtime.WorkspaceState,
      AshUITutorials.OperatorActionsAndForms.RuntimeDomain
    )

    reset_resource!(
      AshUITutorials.OperatorActionsAndForms.UiBinding,
      AshUITutorials.OperatorActionsAndForms.UiStorageDomain
    )

    reset_resource!(
      AshUITutorials.OperatorActionsAndForms.UiElement,
      AshUITutorials.OperatorActionsAndForms.UiStorageDomain
    )

    reset_resource!(
      AshUITutorials.OperatorActionsAndForms.UiScreen,
      AshUITutorials.OperatorActionsAndForms.UiStorageDomain
    )

    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, authoring_actor())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUITutorials.OperatorActionsAndForms.Runtime.WorkspaceState,
        seed_state(),
        domain: AshUITutorials.OperatorActionsAndForms.RuntimeDomain,
        authorize?: false
      )

    {:ok, services_screen} =
      Authority.create(
        AshUITutorials.OperatorActionsAndForms.Examples.ServicesScreen,
        actor: actor,
        name: screen_name(:services),
        ui_storage: ui_storage()
      )

    {:ok, incidents_screen} =
      Authority.create(
        AshUITutorials.OperatorActionsAndForms.Examples.IncidentsScreen,
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

  defp acknowledge_disabled?(attrs) do
    attrs[:operator_note]
    |> trimmed()
    |> String.length()
    |> Kernel.<(12)
  end

  defp assign_disabled?(attrs) do
    trimmed(attrs[:operator_note]) == "" || blank?(attrs[:assignment_target])
  end

  defp maintenance_disabled?(attrs) do
    duration = normalize_duration(attrs[:maintenance_duration_minutes])

    is_nil(duration) || duration < 15 || blank?(attrs[:maintenance_date]) || blank?(attrs[:maintenance_time])
  end

  defp ensure_form_feedback(%{form_feedback_title: title, form_feedback_summary: summary, form_feedback_status: status} = attrs)
       when title not in [nil, ""] and summary not in [nil, ""] and status not in [nil, ""] do
    attrs
  end

  defp ensure_form_feedback(attrs) do
    attrs
    |> Map.put(:form_feedback_title, "Operator workflows are idle")
    |> Map.put(:form_feedback_summary, "Add a note, choose an assignment target, or schedule a maintenance window.")
    |> Map.put(:form_feedback_status, "idle")
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

  defp normalize_duration(value) when value in [nil, ""], do: nil
  defp normalize_duration(value) when is_integer(value), do: value

  defp normalize_duration(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {duration, ""} -> duration
      _other -> nil
    end
  end

  defp normalize_duration(_value), do: nil

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
  defp blank?(value) when value in [nil, ""], do: true
  defp blank?(_value), do: false

  defp trimmed(value) when is_binary(value), do: String.trim(value)
  defp trimmed(value) when is_integer(value), do: Integer.to_string(value)
  defp trimmed(value) when is_nil(value), do: ""
  defp trimmed(value), do: value |> to_string() |> String.trim()

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
        {Phoenix.PubSub, name: AshUITutorials.OperatorActionsAndForms.PubSub},
        AshUITutorials.OperatorActionsAndForms.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUITutorials.OperatorActionsAndForms.Runtime.WorkspaceState)
    end
  end

  defmodule Runtime.WorkspaceState do
    use Ash.Resource,
      domain: AshUITutorials.OperatorActionsAndForms.RuntimeDomain,
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
      :operator_note,
      :assignment_target,
      :maintenance_duration_minutes,
      :maintenance_date,
      :maintenance_time,
      :acknowledge_disabled,
      :assign_disabled,
      :maintenance_disabled,
      :form_feedback_title,
      :form_feedback_summary,
      :form_feedback_status,
      :services_status_copy,
      :incidents_status_copy
    ]

    @form_fields [
      :operator_note,
      :assignment_target,
      :maintenance_duration_minutes,
      :maintenance_date,
      :maintenance_time
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
      attribute :operator_note, :string, default: ""
      attribute :assignment_target, :string, default: "incident-commander"
      attribute :maintenance_duration_minutes, :integer
      attribute :maintenance_date, :string, default: ""
      attribute :maintenance_time, :string, default: ""
      attribute :acknowledge_disabled, :boolean, default: true
      attribute :assign_disabled, :boolean, default: true
      attribute :maintenance_disabled, :boolean, default: true
      attribute :form_feedback_title, :string, default: "Operator workflows are idle"
      attribute :form_feedback_summary, :string, default: "Add a note, choose an assignment target, or schedule a maintenance window."
      attribute :form_feedback_status, :string, default: "idle"
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

      update :submit_operator_workflow do
        require_atomic? false
        accept(@form_fields)

        argument :workflow_intent, :string do
          allow_nil?(false)
        end

        argument :operator_note, :string
        argument :assignment_target, :string
        argument :maintenance_duration_minutes, :integer
        argument :maintenance_date, :string
        argument :maintenance_time, :string

        change(before_action(fn changeset, _context -> submit_operator_workflow(changeset) end))
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
      changeset
      |> state_attrs_from()
      |> AshUITutorials.OperatorActionsAndForms.hydrate_state()
      |> apply_hydrated_state(changeset)
    end

    defp submit_operator_workflow(changeset) do
      changeset = apply_argument_overrides(changeset)

      attrs =
        changeset
        |> state_attrs_from()
        |> apply_workflow_result(Ash.Changeset.get_argument(changeset, :workflow_intent))

      attrs
      |> AshUITutorials.OperatorActionsAndForms.hydrate_state()
      |> apply_hydrated_state(changeset)
    end

    defp apply_argument_overrides(changeset) do
      Enum.reduce(@form_fields, changeset, fn field, acc ->
        case Ash.Changeset.get_argument(acc, field) do
          nil -> acc
          value -> Ash.Changeset.force_change_attribute(acc, field, value)
        end
      end)
    end

    defp apply_workflow_result(attrs, "acknowledge") do
      note = attrs[:operator_note] |> to_string() |> String.trim()

      if String.length(note) < 12 do
        blocked_feedback(
          attrs,
          "Acknowledge blocked",
          "Add at least 12 characters of operator context before acknowledging the incident."
        )
      else
        attrs
        |> Map.put(:incident_catalog, update_primary_incident(attrs[:incident_catalog], %{state: "acknowledged"}))
        |> Map.put(:selected_value, "operator")
        |> Map.put(:operator_view, "acknowledgements")
        |> Map.put(:detail_title, "Gateway latency spike")
        |> Map.put(:detail_summary, "Acknowledged with operator note: #{note}")
        |> Map.put(:detail_status, "acknowledged")
        |> Map.put(:status, "Incident acknowledged through the resource-backed operator workflow.")
        |> Map.put(:form_feedback_title, "Incident acknowledged")
        |> Map.put(:form_feedback_summary, "Stored the operator note and moved the shared workspace into the acknowledgement review mode.")
        |> Map.put(:form_feedback_status, "success")
      end
    end

    defp apply_workflow_result(attrs, "assign") do
      note = attrs[:operator_note] |> to_string() |> String.trim()
      assignment_target = assignment_label(attrs[:assignment_target])

      if note == "" || assignment_target == "Unassigned" do
        blocked_feedback(
          attrs,
          "Assignment blocked",
          "Add a handoff note and choose an assignment target before moving incident ownership."
        )
      else
        attrs
        |> Map.put(
          :incident_catalog,
          update_primary_incident(attrs[:incident_catalog], %{owner: assignment_target, state: "handoff"})
        )
        |> Map.put(:selected_value, "operator")
        |> Map.put(:operator_view, "handoff review")
        |> Map.put(:detail_title, "Gateway latency spike")
        |> Map.put(:detail_summary, "Assigned to #{assignment_target} with handoff note: #{note}")
        |> Map.put(:detail_status, "handoff")
        |> Map.put(:status, "Incident ownership moved to #{assignment_target}.")
        |> Map.put(:form_feedback_title, "Assignment recorded")
        |> Map.put(:form_feedback_summary, "The operator handoff is now tracked in the shared incident catalog and detail view.")
        |> Map.put(:form_feedback_status, "success")
      end
    end

    defp apply_workflow_result(attrs, "maintenance") do
      duration = normalize_duration(attrs[:maintenance_duration_minutes])
      maintenance_date = attrs[:maintenance_date] |> to_string() |> String.trim()
      maintenance_time = attrs[:maintenance_time] |> to_string() |> String.trim()

      if is_nil(duration) || duration < 15 || maintenance_date == "" || maintenance_time == "" do
        blocked_feedback(
          attrs,
          "Maintenance window blocked",
          "Provide a duration of at least 15 minutes plus a date and time before scheduling maintenance."
        )
      else
        window_label = "#{maintenance_date} #{maintenance_time} for #{duration} minutes"

        attrs
        |> Map.put(:selected_value, "operator")
        |> Map.put(:operator_view, "maintenance planner")
        |> Map.put(:detail_title, "Gateway maintenance window")
        |> Map.put(:detail_summary, "Scheduled #{window_label} for the API Gateway recovery workflow.")
        |> Map.put(:detail_status, "scheduled")
        |> Map.put(:status, "Maintenance window scheduled for API Gateway.")
        |> Map.put(:form_feedback_title, "Maintenance window scheduled")
        |> Map.put(:form_feedback_summary, "The operator planner now tracks #{window_label} as the active maintenance target.")
        |> Map.put(:form_feedback_status, "success")
      end
    end

    defp apply_workflow_result(attrs, _other) do
      blocked_feedback(
        attrs,
        "Unknown operator action",
        "Choose one of the authored acknowledge, assign, or maintenance actions."
      )
    end

    defp blocked_feedback(attrs, title, summary) do
      attrs
      |> Map.put(:selected_value, "operator")
      |> Map.put(:status, summary)
      |> Map.put(:form_feedback_title, title)
      |> Map.put(:form_feedback_summary, summary)
      |> Map.put(:form_feedback_status, "blocked")
    end

    defp update_primary_incident(incidents, updates) do
      Enum.map(incidents || [], fn
        %{id: "inc-1042"} = incident -> Map.merge(incident, updates)
        incident -> incident
      end)
    end

    defp assignment_label("incident-commander"), do: "Incident Commander"
    defp assignment_label("search-specialist"), do: "Search Specialist"
    defp assignment_label("platform-manager"), do: "Platform Manager"
    defp assignment_label(nil), do: "Unassigned"
    defp assignment_label(""), do: "Unassigned"
    defp assignment_label(other), do: other

    defp normalize_duration(value) when value in [nil, ""], do: nil
    defp normalize_duration(value) when is_integer(value), do: value

    defp normalize_duration(value) when is_binary(value) do
      case Integer.parse(String.trim(value)) do
        {duration, ""} -> duration
        _other -> nil
      end
    end

    defp normalize_duration(_value), do: nil

    defp state_attrs_from(changeset) do
      [:id | @mutable_fields]
      |> Enum.reduce(%{}, fn field, acc ->
        Map.put(acc, field, Ash.Changeset.get_attribute(changeset, field))
      end)
    end

    defp apply_hydrated_state(hydrated, changeset) do
      Enum.reduce(@mutable_fields, changeset, fn field, acc ->
        Ash.Changeset.force_change_attribute(acc, field, Map.get(hydrated, field))
      end)
    end
  end

  defmodule UiStorageDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUITutorials.OperatorActionsAndForms.UiScreen)
      resource(AshUITutorials.OperatorActionsAndForms.UiElement)
      resource(AshUITutorials.OperatorActionsAndForms.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUITutorials.OperatorActionsAndForms.UiStorageDomain,
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
      has_many :elements, AshUITutorials.OperatorActionsAndForms.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUITutorials.OperatorActionsAndForms.UiBinding do
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
      domain: AshUITutorials.OperatorActionsAndForms.UiStorageDomain,
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
      belongs_to :screen, AshUITutorials.OperatorActionsAndForms.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUITutorials.OperatorActionsAndForms.UiBinding do
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
      domain: AshUITutorials.OperatorActionsAndForms.UiStorageDomain,
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
      belongs_to :element, AshUITutorials.OperatorActionsAndForms.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUITutorials.OperatorActionsAndForms.UiScreen do
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
      resource(AshUITutorials.OperatorActionsAndForms.Examples.ServicesScreen)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.ServicesWorkspacePanelElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.WorkspaceMenuElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.ShowServicesButtonElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.ShowIncidentsButtonElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.ShowOperatorViewButtonElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.WorkspaceSelectionSummaryElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.CommandPaletteElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.CommandPaletteInputElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.CommandFocusGatewayButtonElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.CommandFocusIncidentButtonElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.CommandOpenOperatorViewButtonElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.CommandSummaryTextElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.ServicesFiltersGroupElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.ServicesQueryFieldElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.ServicesQueryInputElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.ServiceStatusFieldElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.ServiceStatusSelectElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.IncludeHealthyFieldElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.IncludeHealthyCheckboxElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.ServicesListElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.SharedDetailCardElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.SharedDetailBadgeElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.SharedDetailTitleElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.SharedDetailSummaryElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.ServicesStatusTextElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.ServicesStoryTextElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.ServicesSignalTextElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.IncidentsScreen)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.IncidentsWorkspacePanelElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.IncidentsFiltersGroupElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.IncidentSeverityFieldElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.IncidentSeverityRadioElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.IncidentEscalatedFieldElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.IncidentEscalatedSwitchElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.OperatorFormsPanelElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.OperatorWorkflowFormElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.NoteAndAssignmentGroupElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.OperatorNoteFieldElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.OperatorNoteInputElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.AssignmentTargetFieldElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.AssignmentTargetPickListElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceWindowGroupElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceDurationFieldElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceDurationInputElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceDateFieldElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceDateInputElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceTimeFieldElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceTimeInputElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.AcknowledgeIncidentButtonElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.AssignIncidentButtonElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.ScheduleMaintenanceButtonElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.FormFeedbackBadgeElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.FormFeedbackTitleElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.FormFeedbackSummaryElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.IncidentsTableElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.IncidentsStatusTextElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.IncidentsStoryTextElement)
      resource(AshUITutorials.OperatorActionsAndForms.Examples.IncidentsSignalTextElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUITutorials.OperatorActionsAndForms.AuthoringDomain,
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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :menus, AshUITutorials.OperatorActionsAndForms.Examples.WorkspaceMenuElement do
        destination_attribute(:parent_id)
      end

      has_many :command_palettes,
               AshUITutorials.OperatorActionsAndForms.Examples.CommandPaletteElement do
        destination_attribute(:parent_id)
      end

      has_many :filter_groups,
               AshUITutorials.OperatorActionsAndForms.Examples.ServicesFiltersGroupElement do
        destination_attribute(:parent_id)
      end

      has_many :service_lists, AshUITutorials.OperatorActionsAndForms.Examples.ServicesListElement do
        destination_attribute(:parent_id)
      end

      has_many :detail_cards, AshUITutorials.OperatorActionsAndForms.Examples.SharedDetailCardElement do
        destination_attribute(:parent_id)
      end

      has_many :status_texts, AshUITutorials.OperatorActionsAndForms.Examples.ServicesStatusTextElement do
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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :services_buttons, AshUITutorials.OperatorActionsAndForms.Examples.ShowServicesButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :incidents_buttons,
               AshUITutorials.OperatorActionsAndForms.Examples.ShowIncidentsButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :operator_buttons,
               AshUITutorials.OperatorActionsAndForms.Examples.ShowOperatorViewButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :selection_summaries,
               AshUITutorials.OperatorActionsAndForms.Examples.WorkspaceSelectionSummaryElement do
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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
            detail_summary: %{"from" => "static", "value" => "The operator view now contains the first write workflows for acknowledgements, assignments, and maintenance planning."},
            detail_status: %{"from" => "static", "value" => "triage"},
            status: %{"from" => "static", "value" => "Quick jump opened the operator actions workspace."}
          }
        })

        metadata(%{intent: "select_operator_view", success_message: "Operator view preview loaded"})
      end
    end
  end

  defmodule Examples.WorkspaceSelectionSummaryElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :search_inputs,
               AshUITutorials.OperatorActionsAndForms.Examples.CommandPaletteInputElement do
        destination_attribute(:parent_id)
      end

      has_many :gateway_buttons,
               AshUITutorials.OperatorActionsAndForms.Examples.CommandFocusGatewayButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :incident_buttons,
               AshUITutorials.OperatorActionsAndForms.Examples.CommandFocusIncidentButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :operator_buttons,
               AshUITutorials.OperatorActionsAndForms.Examples.CommandOpenOperatorViewButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :summary_texts,
               AshUITutorials.OperatorActionsAndForms.Examples.CommandSummaryTextElement do
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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
            detail_summary: %{"from" => "static", "value" => "Operator review is now centered on the maintenance workflow backed by the authored Chapter 4 form resources."},
            detail_status: %{"from" => "static", "value" => "maintenance planner"},
            status: %{"from" => "static", "value" => "Command palette focused the maintenance planner workflow."}
          }
        })

        metadata(%{intent: "open_operator_view", success_message: "Maintenance planner preview loaded"})
      end
    end
  end

  defmodule Examples.CommandSummaryTextElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :query_fields,
               AshUITutorials.OperatorActionsAndForms.Examples.ServicesQueryFieldElement do
        destination_attribute(:parent_id)
      end

      has_many :status_fields,
               AshUITutorials.OperatorActionsAndForms.Examples.ServiceStatusFieldElement do
        destination_attribute(:parent_id)
      end

      has_many :healthy_fields,
               AshUITutorials.OperatorActionsAndForms.Examples.IncludeHealthyFieldElement do
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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :inputs,
               AshUITutorials.OperatorActionsAndForms.Examples.ServicesQueryInputElement do
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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :selects,
               AshUITutorials.OperatorActionsAndForms.Examples.ServiceStatusSelectElement do
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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :checkboxes,
               AshUITutorials.OperatorActionsAndForms.Examples.IncludeHealthyCheckboxElement do
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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :badges, AshUITutorials.OperatorActionsAndForms.Examples.SharedDetailBadgeElement do
        destination_attribute(:parent_id)
      end

      has_many :titles, AshUITutorials.OperatorActionsAndForms.Examples.SharedDetailTitleElement do
        destination_attribute(:parent_id)
      end

      has_many :summaries, AshUITutorials.OperatorActionsAndForms.Examples.SharedDetailSummaryElement do
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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :menus, AshUITutorials.OperatorActionsAndForms.Examples.WorkspaceMenuElement do
        destination_attribute(:parent_id)
      end

      has_many :filter_groups,
               AshUITutorials.OperatorActionsAndForms.Examples.IncidentsFiltersGroupElement do
        destination_attribute(:parent_id)
      end

      has_many :operator_form_panels,
               AshUITutorials.OperatorActionsAndForms.Examples.OperatorFormsPanelElement do
        destination_attribute(:parent_id)
      end

      has_many :incident_tables,
               AshUITutorials.OperatorActionsAndForms.Examples.IncidentsTableElement do
        destination_attribute(:parent_id)
      end

      has_many :detail_cards, AshUITutorials.OperatorActionsAndForms.Examples.SharedDetailCardElement do
        destination_attribute(:parent_id)
      end

      has_many :status_texts, AshUITutorials.OperatorActionsAndForms.Examples.IncidentsStatusTextElement do
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

      relationship :operator_form_panels do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end

      relationship :incident_tables do
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
      props(%{title: "Incidents workspace", class: "ashui-example-panel ashui-tutorial-workspace-panel"})
      metadata(%{id: "incidents-workspace-panel", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.IncidentsFiltersGroupElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :severity_fields,
               AshUITutorials.OperatorActionsAndForms.Examples.IncidentSeverityFieldElement do
        destination_attribute(:parent_id)
      end

      has_many :escalated_fields,
               AshUITutorials.OperatorActionsAndForms.Examples.IncidentEscalatedFieldElement do
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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :radios,
               AshUITutorials.OperatorActionsAndForms.Examples.IncidentSeverityRadioElement do
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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :switches,
               AshUITutorials.OperatorActionsAndForms.Examples.IncidentEscalatedSwitchElement do
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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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

  defmodule Examples.OperatorFormsPanelElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :forms, AshUITutorials.OperatorActionsAndForms.Examples.OperatorWorkflowFormElement do
        destination_attribute(:parent_id)
      end

      has_many :feedback_badges,
               AshUITutorials.OperatorActionsAndForms.Examples.FormFeedbackBadgeElement do
        destination_attribute(:parent_id)
      end

      has_many :feedback_titles,
               AshUITutorials.OperatorActionsAndForms.Examples.FormFeedbackTitleElement do
        destination_attribute(:parent_id)
      end

      has_many :feedback_summaries,
               AshUITutorials.OperatorActionsAndForms.Examples.FormFeedbackSummaryElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :forms do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :feedback_badges do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end

      relationship :feedback_titles do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(10)
      end

      relationship :feedback_summaries do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(20)
      end
    end

    ui_element do
      type(:card)

      props(%{
        title: "Operator actions",
        class: "ashui-example-panel ashui-tutorial-workspace-panel"
      })

      metadata(%{id: "operator-forms-panel", section: "demo", slot: "body", position: 20})
    end
  end

  defmodule Examples.OperatorWorkflowFormElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :note_groups,
               AshUITutorials.OperatorActionsAndForms.Examples.NoteAndAssignmentGroupElement do
        destination_attribute(:parent_id)
      end

      has_many :maintenance_groups,
               AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceWindowGroupElement do
        destination_attribute(:parent_id)
      end

      has_many :acknowledge_buttons,
               AshUITutorials.OperatorActionsAndForms.Examples.AcknowledgeIncidentButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :assign_buttons,
               AshUITutorials.OperatorActionsAndForms.Examples.AssignIncidentButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :maintenance_buttons,
               AshUITutorials.OperatorActionsAndForms.Examples.ScheduleMaintenanceButtonElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :note_groups do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :maintenance_groups do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :acknowledge_buttons do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end

      relationship :assign_buttons do
        kind(:child)
        slot(:body)
        placement(:append)
        order(30)
      end

      relationship :maintenance_buttons do
        kind(:child)
        slot(:body)
        placement(:append)
        order(40)
      end
    end

    ui_element do
      type(:form_builder)
      props(%{class: "ashui-example-form"})
      metadata(%{id: "operator-workflow-form", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.NoteAndAssignmentGroupElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :note_fields,
               AshUITutorials.OperatorActionsAndForms.Examples.OperatorNoteFieldElement do
        destination_attribute(:parent_id)
      end

      has_many :assignment_fields,
               AshUITutorials.OperatorActionsAndForms.Examples.AssignmentTargetFieldElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :note_fields do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :assignment_fields do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:"custom:field_group")

      props(%{
        title: "Acknowledge and assign",
        description: "Keep the operator note and assignment choice inside the shared runtime resource before triggering a write workflow.",
        class: "ashui-example-form"
      })

      metadata(%{id: "note-assignment-group", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.OperatorNoteFieldElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :inputs,
               AshUITutorials.OperatorActionsAndForms.Examples.OperatorNoteInputElement do
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
        label: "Operator note",
        name: "operator_note",
        help: "At least 12 characters are required before the acknowledge action becomes available.",
        class: "ashui-example-form-field"
      })

      metadata(%{id: "operator-note-field", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.OperatorNoteInputElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    ui_element do
      type(:input)

      props(%{
        name: "operator_note",
        type: "text",
        value: "",
        placeholder: "Document mitigation or handoff context",
        class: "ashui-example-input"
      })

      metadata(%{id: "operator-note-input", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :operator_note do
        source(%{resource: "WorkspaceState", field: :operator_note, id: "tutorial-services-incidents-state"})
        target("operator_note")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "operator_note", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.AssignmentTargetFieldElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :pick_lists,
               AshUITutorials.OperatorActionsAndForms.Examples.AssignmentTargetPickListElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :pick_lists do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:form_field)

      props(%{
        label: "Assignment target",
        name: "assignment_target",
        help: "Use the promoted pick-list surface to choose the next incident owner.",
        class: "ashui-example-form-field"
      })

      metadata(%{id: "assignment-target-field", section: "demo", slot: "body", position: 10})
    end
  end

  defmodule Examples.AssignmentTargetPickListElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    ui_element do
      type(:"custom:pick_list")

      props(%{
        name: "assignment_target",
        value: "incident-commander",
        options: [
          {"Incident Commander", "incident-commander"},
          {"Search Specialist", "search-specialist"},
          {"Platform Manager", "platform-manager"}
        ],
        class: "ashui-example-pick-list"
      })

      metadata(%{id: "assignment-target-pick-list", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :assignment_target do
        source(%{resource: "WorkspaceState", field: :assignment_target, id: "tutorial-services-incidents-state"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "assignment_target", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.MaintenanceWindowGroupElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :duration_fields,
               AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceDurationFieldElement do
        destination_attribute(:parent_id)
      end

      has_many :date_fields,
               AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceDateFieldElement do
        destination_attribute(:parent_id)
      end

      has_many :time_fields,
               AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceTimeFieldElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :duration_fields do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :date_fields do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :time_fields do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end
    end

    ui_element do
      type(:"custom:field_group")

      props(%{
        title: "Maintenance window",
        description: "Schedule the operator maintenance workflow with dedicated numeric, date, and time inputs.",
        class: "ashui-example-form"
      })

      metadata(%{id: "maintenance-window-group", section: "demo", slot: "body", position: 10})
    end
  end

  defmodule Examples.MaintenanceDurationFieldElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :inputs,
               AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceDurationInputElement do
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
        label: "Duration (minutes)",
        name: "maintenance_duration_minutes",
        help: "At least 15 minutes are required before scheduling.",
        class: "ashui-example-form-field"
      })

      metadata(%{id: "maintenance-duration-field", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.MaintenanceDurationInputElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    ui_element do
      type(:input)

      props(%{
        name: "maintenance_duration_minutes",
        type: "number",
        value: "",
        placeholder: "30",
        class: "ashui-example-input"
      })

      metadata(%{id: "maintenance-duration-input", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :maintenance_duration_minutes do
        source(%{resource: "WorkspaceState", field: :maintenance_duration_minutes, id: "tutorial-services-incidents-state"})
        target("maintenance_duration_minutes")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "maintenance_duration_minutes", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.MaintenanceDateFieldElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :inputs,
               AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceDateInputElement do
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
        label: "Start date",
        name: "maintenance_date",
        help: "Choose the maintenance date from the authored date input.",
        class: "ashui-example-form-field"
      })

      metadata(%{id: "maintenance-date-field", section: "demo", slot: "body", position: 10})
    end
  end

  defmodule Examples.MaintenanceDateInputElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    ui_element do
      type(:input)

      props(%{
        name: "maintenance_date",
        type: "date",
        value: "",
        class: "ashui-example-input"
      })

      metadata(%{id: "maintenance-date-input", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :maintenance_date do
        source(%{resource: "WorkspaceState", field: :maintenance_date, id: "tutorial-services-incidents-state"})
        target("maintenance_date")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "maintenance_date", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.MaintenanceTimeFieldElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    relationships do
      has_many :inputs,
               AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceTimeInputElement do
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
        label: "Start time",
        name: "maintenance_time",
        help: "Choose the maintenance start time from the authored time input.",
        class: "ashui-example-form-field"
      })

      metadata(%{id: "maintenance-time-field", section: "demo", slot: "body", position: 20})
    end
  end

  defmodule Examples.MaintenanceTimeInputElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    ui_element do
      type(:input)

      props(%{
        name: "maintenance_time",
        type: "time",
        value: "",
        class: "ashui-example-input"
      })

      metadata(%{id: "maintenance-time-input", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :maintenance_time do
        source(%{resource: "WorkspaceState", field: :maintenance_time, id: "tutorial-services-incidents-state"})
        target("maintenance_time")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "maintenance_time", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.AcknowledgeIncidentButtonElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Acknowledge incident",
        class: "ashui-example-primary-cta",
        variant: "primary"
      })

      metadata(%{id: "acknowledge-incident-button", section: "demo", slot: "body", position: 20})
    end

    ui_bindings do
      binding :acknowledge_disabled do
        source(%{resource: "WorkspaceState", field: :acknowledge_disabled, id: "tutorial-services-incidents-state"})
        target("disabled")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "acknowledge_button"})
      end
    end

    ui_actions do
      action :acknowledge_incident do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "submit_operator_workflow"})
        target("submit")

        transform(%{
          params: %{
            workflow_intent: %{"from" => "static", "value" => "acknowledge"},
            operator_note: %{"from" => "binding", "key" => "operator_note"}
          }
        })

        metadata(%{intent: "acknowledge_incident", success_message: "Acknowledge workflow executed"})
      end
    end
  end

  defmodule Examples.AssignIncidentButtonElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Assign incident",
        class: "ashui-example-secondary-cta",
        variant: "secondary"
      })

      metadata(%{id: "assign-incident-button", section: "demo", slot: "body", position: 30})
    end

    ui_bindings do
      binding :assign_disabled do
        source(%{resource: "WorkspaceState", field: :assign_disabled, id: "tutorial-services-incidents-state"})
        target("disabled")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "assign_button"})
      end
    end

    ui_actions do
      action :assign_incident do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "submit_operator_workflow"})
        target("submit")

        transform(%{
          params: %{
            workflow_intent: %{"from" => "static", "value" => "assign"},
            operator_note: %{"from" => "binding", "key" => "operator_note"},
            assignment_target: %{"from" => "binding", "key" => "value"}
          }
        })

        metadata(%{intent: "assign_incident", success_message: "Assignment workflow executed"})
      end
    end
  end

  defmodule Examples.ScheduleMaintenanceButtonElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Schedule maintenance",
        class: "ashui-example-secondary-cta",
        variant: "secondary"
      })

      metadata(%{id: "schedule-maintenance-button", section: "demo", slot: "body", position: 40})
    end

    ui_bindings do
      binding :maintenance_disabled do
        source(%{resource: "WorkspaceState", field: :maintenance_disabled, id: "tutorial-services-incidents-state"})
        target("disabled")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "maintenance_button"})
      end
    end

    ui_actions do
      action :schedule_maintenance do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "submit_operator_workflow"})
        target("submit")

        transform(%{
          params: %{
            workflow_intent: %{"from" => "static", "value" => "maintenance"},
            operator_note: %{"from" => "binding", "key" => "operator_note"},
            maintenance_duration_minutes: %{"from" => "binding", "key" => "maintenance_duration_minutes"},
            maintenance_date: %{"from" => "binding", "key" => "maintenance_date"},
            maintenance_time: %{"from" => "binding", "key" => "maintenance_time"}
          }
        })

        metadata(%{intent: "schedule_maintenance", success_message: "Maintenance workflow executed"})
      end
    end
  end

  defmodule Examples.FormFeedbackBadgeElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    ui_element do
      type(:badge)
      props(%{content: "idle", class: "ashui-tutorial-status-pill"})
      metadata(%{id: "form-feedback-badge", section: "demo", slot: "footer", position: 0})
    end

    ui_bindings do
      binding :form_feedback_status do
        source(%{resource: "WorkspaceState", field: :form_feedback_status, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "form_feedback_status"})
      end
    end
  end

  defmodule Examples.FormFeedbackTitleElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-detail-title"})
      metadata(%{id: "form-feedback-title", section: "demo", slot: "footer", position: 10})
    end

    ui_bindings do
      binding :form_feedback_title do
        source(%{resource: "WorkspaceState", field: :form_feedback_title, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "form_feedback_title"})
      end
    end
  end

  defmodule Examples.FormFeedbackSummaryElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-muted-copy"})
      metadata(%{id: "form-feedback-summary", section: "demo", slot: "footer", position: 20})
    end

    ui_bindings do
      binding :form_feedback_summary do
        source(%{resource: "WorkspaceState", field: :form_feedback_summary, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "form_feedback_summary"})
      end
    end
  end

  defmodule Examples.IncidentsTableElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

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
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: narrow the incident table, then acknowledge, assign, or schedule maintenance through the authored operator form so the same shared state record drives filters, writes, feedback, and detail.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "incidents-story-text", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.IncidentsSignalTextElement do
    use AshUITutorials.OperatorActionsAndForms.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: filter change -> WorkspaceState.incident_severity_filter/incident_escalated_only -> hydrated incidents table; action click -> WorkspaceState.submit_operator_workflow(...) -> incident catalog, disabled flags, feedback copy, and shared detail.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "incidents-signal-text", section: "signal_preview", slot: "body", position: 20})
    end
  end

  defmodule Examples.ServicesScreen do
    use Ash.Resource,
      domain: AshUITutorials.OperatorActionsAndForms.AuthoringDomain,
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
      has_many :panels, AshUITutorials.OperatorActionsAndForms.Examples.ServicesWorkspacePanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUITutorials.OperatorActionsAndForms.Examples.ServicesStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUITutorials.OperatorActionsAndForms.Examples.ServicesSignalTextElement do
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
        tutorial_directory: "04-operator-actions-and-forms",
        shell_id: "operations-control-center-services-shell"
      })
    end
  end

  defmodule Examples.IncidentsScreen do
    use Ash.Resource,
      domain: AshUITutorials.OperatorActionsAndForms.AuthoringDomain,
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
      has_many :panels, AshUITutorials.OperatorActionsAndForms.Examples.IncidentsWorkspacePanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUITutorials.OperatorActionsAndForms.Examples.IncidentsStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUITutorials.OperatorActionsAndForms.Examples.IncidentsSignalTextElement do
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
        tutorial_directory: "04-operator-actions-and-forms",
        shell_id: "operations-control-center-incidents-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUITutorials.OperatorActionsAndForms.seed!(opts)
    def reset!, do: AshUITutorials.OperatorActionsAndForms.reset!()
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

    scope "/", AshUITutorials.OperatorActionsAndForms.Web do
      pipe_through(:browser)
      live("/", ServicesLive)
      live("/incidents", IncidentsLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_tutorial_operator_actions_and_forms

    @session_options [
      store: :cookie,
      key: "_ash_ui_tutorial_operator_actions_and_forms_key",
      signing_salt: "ashuitut23b"
    ]

    socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

    plug(Plug.RequestId)
    plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])
    plug(Plug.Session, @session_options)
    plug(AshUITutorials.OperatorActionsAndForms.Web.Router)
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

    alias AshUITutorials.OperatorActionsAndForms.Web.Components.TutorialShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      AshUITutorials.OperatorActionsAndForms.seed!()
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
        |> Phoenix.Component.assign(:current_user, AshUITutorials.OperatorActionsAndForms.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUITutorials.OperatorActionsAndForms.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUITutorials.OperatorActionsAndForms.runtime_domains())
        |> Phoenix.Component.assign(:page_title, AshUITutorials.OperatorActionsAndForms.title())
        |> Phoenix.Component.assign(:theme_css, AshUITutorials.OperatorActionsAndForms.theme_css())
        |> Phoenix.Component.assign(:example_runtime, example_runtime)
        |> Phoenix.Component.assign(:supported_runtimes, AshUITutorials.OperatorActionsAndForms.supported_runtimes())
        |> Phoenix.Component.assign(:active_page, Atom.to_string(screen_kind))

      with {:ok, socket} <- Integration.mount_ui_screen(socket, AshUITutorials.OperatorActionsAndForms.screen_name(screen_kind), params),
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
        |> Phoenix.Component.assign_new(:supported_runtimes, fn -> AshUITutorials.OperatorActionsAndForms.supported_runtimes() end)
        |> Phoenix.Component.assign_new(:example_runtime, fn -> AshUITutorials.OperatorActionsAndForms.default_runtime() end)
        |> Phoenix.Component.assign_new(:rendered_runtime, fn ->
          %{
            content: assigns[:rendered_ui] || "",
            description: AshUITutorials.OperatorActionsAndForms.runtime_description(AshUITutorials.OperatorActionsAndForms.default_runtime()),
            mode: :live_fragment,
            runtime: AshUITutorials.OperatorActionsAndForms.default_runtime()
          }
        end)

      ~H"""
      <TutorialShell.tutorial_shell title={@page_title} summary={AshUITutorials.OperatorActionsAndForms.summary()} theme_css={@theme_css} active_page={@active_page}>
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
        AshUITutorials.OperatorActionsAndForms.rendered_runtime(
          socket.assigns,
          socket.assigns[:example_runtime] || AshUITutorials.OperatorActionsAndForms.default_runtime()
        )

      socket
      |> Phoenix.Component.assign(:rendered_runtime, rendered_runtime)
      |> Phoenix.Component.assign(:rendered_ui, rendered_runtime.content)
    end

    defp runtime_from_params(params) do
      params["runtime"]
      |> fallback_runtime()
      |> AshUITutorials.OperatorActionsAndForms.normalize_runtime!()
    end

    defp fallback_runtime(nil), do: System.get_env("ASH_UI_EXAMPLE_RUNTIME")
    defp fallback_runtime(runtime), do: runtime
  end

  defmodule Web.IncidentsLive do
    use Phoenix.LiveView

    alias AshUITutorials.OperatorActionsAndForms.Web.Components.TutorialShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      AshUITutorials.OperatorActionsAndForms.seed!()
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
        |> Phoenix.Component.assign(:current_user, AshUITutorials.OperatorActionsAndForms.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUITutorials.OperatorActionsAndForms.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUITutorials.OperatorActionsAndForms.runtime_domains())
        |> Phoenix.Component.assign(:page_title, AshUITutorials.OperatorActionsAndForms.title())
        |> Phoenix.Component.assign(:theme_css, AshUITutorials.OperatorActionsAndForms.theme_css())
        |> Phoenix.Component.assign(:example_runtime, example_runtime)
        |> Phoenix.Component.assign(:supported_runtimes, AshUITutorials.OperatorActionsAndForms.supported_runtimes())
        |> Phoenix.Component.assign(:active_page, Atom.to_string(screen_kind))

      with {:ok, socket} <- Integration.mount_ui_screen(socket, AshUITutorials.OperatorActionsAndForms.screen_name(screen_kind), params),
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
        |> Phoenix.Component.assign_new(:supported_runtimes, fn -> AshUITutorials.OperatorActionsAndForms.supported_runtimes() end)
        |> Phoenix.Component.assign_new(:example_runtime, fn -> AshUITutorials.OperatorActionsAndForms.default_runtime() end)
        |> Phoenix.Component.assign_new(:rendered_runtime, fn ->
          %{
            content: assigns[:rendered_ui] || "",
            description: AshUITutorials.OperatorActionsAndForms.runtime_description(AshUITutorials.OperatorActionsAndForms.default_runtime()),
            mode: :live_fragment,
            runtime: AshUITutorials.OperatorActionsAndForms.default_runtime()
          }
        end)

      ~H"""
      <TutorialShell.tutorial_shell title={@page_title} summary={AshUITutorials.OperatorActionsAndForms.summary()} theme_css={@theme_css} active_page={@active_page}>
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
        AshUITutorials.OperatorActionsAndForms.rendered_runtime(
          socket.assigns,
          socket.assigns[:example_runtime] || AshUITutorials.OperatorActionsAndForms.default_runtime()
        )

      socket
      |> Phoenix.Component.assign(:rendered_runtime, rendered_runtime)
      |> Phoenix.Component.assign(:rendered_ui, rendered_runtime.content)
    end

    defp runtime_from_params(params) do
      params["runtime"]
      |> fallback_runtime()
      |> AshUITutorials.OperatorActionsAndForms.normalize_runtime!()
    end

    defp fallback_runtime(nil), do: System.get_env("ASH_UI_EXAMPLE_RUNTIME")
    defp fallback_runtime(runtime), do: runtime
  end
end
