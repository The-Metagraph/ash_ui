defmodule AshUITutorials.TopologyAndNavigation do
  @moduledoc """
  Standalone Chapter 8 checkpoint app for the Operations Control Center tutorial.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.{DesktopUIAdapter, ElmUIAdapter, LiveUIAdapter}
  alias AshUI.Resource.Authority
  alias AshUI.Tutorials.Phase23, as: TutorialBaseline

  @app :ash_ui_tutorial_topology_and_navigation
  @screen_names %{
    services: "tutorial/services-incidents/services",
    incidents: "tutorial/services-incidents/incidents"
  }
  @title "Operations Control Center"
  @summary "Standalone Chapter 8 checkpoint app: the earlier filters, workflows, runbook review, and seeded diagnostics remain intact while the services workspace now adds persisted topology navigation across menu, tabs, tree, viewport, split-pane, canvas, and scroll review surfaces."
  @story_text "Meaningful Interaction Story: operators can keep the same services shell, switch between service maps, dependency paths, and incident-scope reviews, then drill into gateway, search, or cluster tabs without abandoning the seeded runbook and diagnostics lanes already established in earlier chapters."
  @signal_text "Canonical Signal Preview: service filter change -> WorkspaceState.update(...) -> derived list/table props; topology menu/tab/canvas/scroll click -> WorkspaceState.update(...) -> tree model, viewport copy, canvas layer, scroll thumb, shared detail, and topology status; incident workflow action -> WorkspaceState.submit_operator_workflow(...) or preview_guarded_action()/confirm_guarded_action() -> persisted guard, toast, runbook, and diagnostics updates."
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
      domain: AshUITutorials.TopologyAndNavigation.UiStorageDomain,
      resources: [
        screen: AshUITutorials.TopologyAndNavigation.UiScreen,
        element: AshUITutorials.TopologyAndNavigation.UiElement,
        binding: AshUITutorials.TopologyAndNavigation.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUITutorials.TopologyAndNavigation.RuntimeDomain]

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

  defp gateway_runbook_context do
    %{
      runbook_focus: "Gateway latency mitigation",
      runbook_markdown: """
      # Gateway latency mitigation

      - Confirm the public edge error budget and current p95 latency.
      - Compare auth fan-out timings before restarting any lane.
      - Capture one evidence packet before changing the maintenance window.
      - Keep the rollback packet visible for incident commander review.
      """,
      runbook_status: "Runbook panel mounted with the latency mitigation guide.",
      attachment_filename: "gateway-latency-trace.png",
      attachment_support_notice:
        "Attachment capture is intentionally narrow here: the file input only echoes the selected filename, and the markdown and link surfaces remain explicit custom shells.",
      detail_title: "Gateway latency spike",
      detail_summary: "Runbook review is centered on ingress latency mitigation and the current evidence packet.",
      detail_status: "sev-1",
      status: "Runbook review is focused on the gateway latency mitigation guide."
    }
  end

  defp rollback_runbook_context do
    %{
      runbook_focus: "Rollback decision packet",
      runbook_markdown: """
      # Rollback decision packet

      ## Exit criteria

      - Confirm the canary error rate is stable for two consecutive checks.
      - Verify the maintenance window still covers traffic drain and restart time.
      - Attach the rollback packet name before notifying the search specialist.
      - Keep the deployment notes link available for external reviewers.
      """,
      runbook_status: "Runbook panel switched to the rollback decision packet.",
      attachment_filename: "rollback-decision-packet.md",
      attachment_support_notice:
        "The tutorial still does not ship binary upload transport. This checkpoint keeps artifact review honest by persisting only filenames, markdown copy, and explicit external references.",
      detail_title: "Rollback decision packet",
      detail_summary: "Runbook review now emphasizes rollback readiness, maintenance coverage, and the current evidence filename.",
      detail_status: "rollback-ready",
      status: "Runbook review switched to the rollback decision packet."
    }
  end

  defp gateway_diagnostics_context do
    %{
      diagnostics_mode: "gateway live tail",
      diagnostics_status_model: %{
        "label" => "Simulated live tail",
        "detail" => "Gateway diagnostics are refreshed from seeded snapshots inside the tutorial host.",
        "tone" => "warning"
      },
      diagnostics_feedback_model: %{
        "title" => "Transport note",
        "detail" => "The log, stream, and process surfaces stay explicit about using seeded snapshots instead of a hidden subscription transport.",
        "tone" => "warning"
      },
      diagnostics_log_entries: [
        %{"level" => "WARN", "message" => "gateway retry budget crossed the operator threshold", "timestamp" => "13:41:12"},
        %{"level" => "INFO", "message" => "rollback packet was linked into the incident workspace", "timestamp" => "13:41:20"},
        %{"level" => "INFO", "message" => "latency mitigation guide reloaded from persisted state", "timestamp" => "13:41:32"}
      ],
      diagnostics_stream_entries: [
        %{"label" => "gateway", "message" => "ingress queue hydration completed", "timestamp" => "13:41:08"},
        %{"label" => "gateway", "message" => "operator handoff packet published", "timestamp" => "13:41:22"},
        %{"label" => "gateway", "message" => "mitigation checklist advanced to rollback review", "timestamp" => "13:41:35"}
      ],
      diagnostics_process_model: %{
        "processes" => [
          %{"name" => "gateway_scheduler", "state" => "running", "meta" => "0 restarts"},
          %{"name" => "retry_worker", "state" => "running", "meta" => "1 restart"},
          %{"name" => "binding_refresh", "state" => "idle", "meta" => "0 restarts"}
        ],
        "summary" => "Gateway processes are steady, but the diagnostics lane remains an honest seeded snapshot."
      },
      diagnostics_status_copy: "Gateway diagnostics are live-shaped but still seeded snapshots; no websocket feed is implied by this checkpoint."
    }
  end

  defp search_snapshot_diagnostics_context do
    %{
      diagnostics_mode: "search lag snapshot",
      diagnostics_status_model: %{
        "label" => "Snapshot stale",
        "detail" => "The search-lag review surface is intentionally a captured snapshot from four minutes ago.",
        "tone" => "warning"
      },
      diagnostics_feedback_model: %{
        "title" => "Stale review window",
        "detail" => "This scenario demonstrates stale-data handling explicitly so the tutorial does not overclaim a fresh runtime transport.",
        "tone" => "warning"
      },
      diagnostics_log_entries: [
        %{"level" => "INFO", "message" => "replica lag snapshot captured for operator review", "timestamp" => "13:32:04"},
        %{"level" => "WARN", "message" => "backlog depth remains above the watch threshold", "timestamp" => "13:32:18"},
        %{"level" => "INFO", "message" => "promotion readiness packet archived", "timestamp" => "13:32:29"}
      ],
      diagnostics_stream_entries: [
        %{"label" => "search", "message" => "replica backlog snapshot stored", "timestamp" => "13:31:58"},
        %{"label" => "search", "message" => "lag review note attached to the incident", "timestamp" => "13:32:16"},
        %{"label" => "search", "message" => "fresh transport intentionally unavailable in this tutorial lane", "timestamp" => "13:32:24"}
      ],
      diagnostics_process_model: %{
        "processes" => [
          %{"name" => "replica_reader", "state" => "degraded", "meta" => "2 restarts"},
          %{"name" => "index_queue", "state" => "running", "meta" => "0 restarts"},
          %{"name" => "promotion_guard", "state" => "idle", "meta" => "0 restarts"}
        ],
        "summary" => "Search replication is under review, and the surface calls out that its data is intentionally stale."
      },
      diagnostics_status_copy: "Search diagnostics are snapshot-only in this tutorial step; the stale notice is part of the contract, not a temporary omission."
    }
  end

  defp retry_pressure_diagnostics_context do
    %{
      diagnostics_mode: "retry pressure snapshot",
      diagnostics_status_model: %{
        "label" => "Pressure",
        "detail" => "Worker restart pressure is rising and operator intervention is recommended.",
        "tone" => "danger"
      },
      diagnostics_feedback_model: %{
        "title" => "Action recommended",
        "detail" => "The process monitor and log viewer agree on restart pressure, but the surface still remains a seeded runtime model for tutorial clarity.",
        "tone" => "danger"
      },
      diagnostics_log_entries: [
        %{"level" => "ERROR", "message" => "retry worker exceeded the restart threshold for the last five minutes", "timestamp" => "13:48:03"},
        %{"level" => "WARN", "message" => "maintenance guard still open while restart pressure climbs", "timestamp" => "13:48:19"},
        %{"level" => "INFO", "message" => "operator escalation note synced into the incident review lane", "timestamp" => "13:48:31"}
      ],
      diagnostics_stream_entries: [
        %{"label" => "runtime", "message" => "queue worker restart count crossed 4", "timestamp" => "13:47:58"},
        %{"label" => "runtime", "message" => "escalation path promoted to incident commander review", "timestamp" => "13:48:12"},
        %{"label" => "runtime", "message" => "process pressure snapshot published", "timestamp" => "13:48:28"}
      ],
      diagnostics_process_model: %{
        "processes" => [
          %{"name" => "gateway_scheduler", "state" => "running", "meta" => "0 restarts"},
          %{"name" => "retry_worker", "state" => "degraded", "meta" => "4 restarts"},
          %{"name" => "binding_refresh", "state" => "running", "meta" => "2 restarts"}
        ],
        "summary" => "The retry worker is degraded, and the tutorial surfaces that pressure without pretending to be a direct supervisor tap."
      },
      diagnostics_status_copy: "Retry-pressure diagnostics are representative runtime snapshots; they are coordinated across the status, feedback, log, stream, and process surfaces."
    }
  end

  defp gateway_topology_context do
    %{
      topology_scope: "service topology",
      topology_tab_value: "gateway lane",
      topology_tree_model: [
        %{
          "label" => "API Gateway",
          "meta" => "degraded",
          "children" => [
            %{"label" => "Auth fan-out", "meta" => "monitoring"},
            %{"label" => "Billing retries", "meta" => "healthy"},
            %{"label" => "Search reads", "meta" => "watching"}
          ]
        }
      ],
      topology_viewport_focus: "gateway lane",
      topology_viewport_support_title: "Gateway dependency lane",
      topology_viewport_support_detail:
        "The viewport keeps the ingress lane, auth fan-out, and downstream recovery checkpoints readable even when the larger screen collapses into stacked panels on smaller layouts.",
      topology_canvas_layer: "traffic path",
      topology_canvas_board_copy:
        "Traffic enters through the API Gateway, fans into auth, then branches into billing and search paths that the on-call operator is reviewing together.",
      topology_canvas_legend: "Canvas review is focused on the gateway traffic path and the current operator handoff edges.",
      topology_scroll_focus: "commander lane",
      topology_scroll_status:
        "Scroll focus is aligned to the commander lane so the incident lead can keep the gateway path, handoff packet, and mitigation order visible.",
      topology_status_copy:
        "Topology review is centered on the API Gateway service map with the commander lane in focus."
    }
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
      |> Map.put_new(:overlay_open, false)
      |> Map.put_new(:resolve_dialog_open, false)
      |> Map.put_new(:restart_alert_open, false)
      |> Map.put_new(:active_guard_action, "")
      |> Map.put_new(:guard_title, "Guard rail")
      |> Map.put_new(:guard_summary, "Choose a guarded action from the context menu.")
      |> Map.put_new(:toast_visible, false)
      |> Map.put_new(:toast_title, "")
      |> Map.put_new(:toast_summary, "")
      |> Map.put_new(:toast_status, "idle")
      |> Map.put_new(:runbook_focus, gateway_runbook_context().runbook_focus)
      |> Map.put_new(:runbook_markdown, gateway_runbook_context().runbook_markdown)
      |> Map.put_new(:runbook_status, gateway_runbook_context().runbook_status)
      |> Map.put_new(:attachment_filename, gateway_runbook_context().attachment_filename)
      |> Map.put_new(:attachment_support_notice, gateway_runbook_context().attachment_support_notice)
      |> Map.put_new(:diagnostics_mode, gateway_diagnostics_context().diagnostics_mode)
      |> Map.put_new(:diagnostics_status_model, gateway_diagnostics_context().diagnostics_status_model)
      |> Map.put_new(:diagnostics_feedback_model, gateway_diagnostics_context().diagnostics_feedback_model)
      |> Map.put_new(:diagnostics_log_entries, gateway_diagnostics_context().diagnostics_log_entries)
      |> Map.put_new(:diagnostics_stream_entries, gateway_diagnostics_context().diagnostics_stream_entries)
      |> Map.put_new(:diagnostics_process_model, gateway_diagnostics_context().diagnostics_process_model)
      |> Map.put_new(:diagnostics_status_copy, gateway_diagnostics_context().diagnostics_status_copy)
      |> Map.put_new(:topology_scope, gateway_topology_context().topology_scope)
      |> Map.put_new(:topology_tab_value, gateway_topology_context().topology_tab_value)
      |> Map.put_new(:topology_tree_model, gateway_topology_context().topology_tree_model)
      |> Map.put_new(:topology_viewport_focus, gateway_topology_context().topology_viewport_focus)
      |> Map.put_new(:topology_viewport_support_title, gateway_topology_context().topology_viewport_support_title)
      |> Map.put_new(:topology_viewport_support_detail, gateway_topology_context().topology_viewport_support_detail)
      |> Map.put_new(:topology_canvas_layer, gateway_topology_context().topology_canvas_layer)
      |> Map.put_new(:topology_canvas_board_copy, gateway_topology_context().topology_canvas_board_copy)
      |> Map.put_new(:topology_canvas_legend, gateway_topology_context().topology_canvas_legend)
      |> Map.put_new(:topology_scroll_focus, gateway_topology_context().topology_scroll_focus)
      |> Map.put_new(:topology_scroll_status, gateway_topology_context().topology_scroll_status)
      |> Map.put_new(:topology_status_copy, gateway_topology_context().topology_status_copy)
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
      operator_view: "triage",
      runbook_focus: gateway_runbook_context().runbook_focus,
      runbook_markdown: gateway_runbook_context().runbook_markdown,
      runbook_status: gateway_runbook_context().runbook_status,
      attachment_filename: gateway_runbook_context().attachment_filename,
      attachment_support_notice: gateway_runbook_context().attachment_support_notice,
      diagnostics_mode: gateway_diagnostics_context().diagnostics_mode,
      diagnostics_status_model: gateway_diagnostics_context().diagnostics_status_model,
      diagnostics_feedback_model: gateway_diagnostics_context().diagnostics_feedback_model,
      diagnostics_log_entries: gateway_diagnostics_context().diagnostics_log_entries,
      diagnostics_stream_entries: gateway_diagnostics_context().diagnostics_stream_entries,
      diagnostics_process_model: gateway_diagnostics_context().diagnostics_process_model,
      diagnostics_status_copy: gateway_diagnostics_context().diagnostics_status_copy,
      topology_scope: gateway_topology_context().topology_scope,
      topology_tab_value: gateway_topology_context().topology_tab_value,
      topology_tree_model: gateway_topology_context().topology_tree_model,
      topology_viewport_focus: gateway_topology_context().topology_viewport_focus,
      topology_viewport_support_title: gateway_topology_context().topology_viewport_support_title,
      topology_viewport_support_detail: gateway_topology_context().topology_viewport_support_detail,
      topology_canvas_layer: gateway_topology_context().topology_canvas_layer,
      topology_canvas_board_copy: gateway_topology_context().topology_canvas_board_copy,
      topology_canvas_legend: gateway_topology_context().topology_canvas_legend,
      topology_scroll_focus: gateway_topology_context().topology_scroll_focus,
      topology_scroll_status: gateway_topology_context().topology_scroll_status,
      topology_status_copy: gateway_topology_context().topology_status_copy
    })
  end

  def reset! do
    reset_resource!(
      AshUITutorials.TopologyAndNavigation.Runtime.WorkspaceState,
      AshUITutorials.TopologyAndNavigation.RuntimeDomain
    )

    reset_resource!(
      AshUITutorials.TopologyAndNavigation.UiBinding,
      AshUITutorials.TopologyAndNavigation.UiStorageDomain
    )

    reset_resource!(
      AshUITutorials.TopologyAndNavigation.UiElement,
      AshUITutorials.TopologyAndNavigation.UiStorageDomain
    )

    reset_resource!(
      AshUITutorials.TopologyAndNavigation.UiScreen,
      AshUITutorials.TopologyAndNavigation.UiStorageDomain
    )

    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, authoring_actor())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUITutorials.TopologyAndNavigation.Runtime.WorkspaceState,
        seed_state(),
        domain: AshUITutorials.TopologyAndNavigation.RuntimeDomain,
        authorize?: false
      )

    {:ok, services_screen} =
      Authority.create(
        AshUITutorials.TopologyAndNavigation.Examples.ServicesScreen,
        actor: actor,
        name: screen_name(:services),
        ui_storage: ui_storage()
      )

    {:ok, incidents_screen} =
      Authority.create(
        AshUITutorials.TopologyAndNavigation.Examples.IncidentsScreen,
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
        {Phoenix.PubSub, name: AshUITutorials.TopologyAndNavigation.PubSub},
        AshUITutorials.TopologyAndNavigation.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUITutorials.TopologyAndNavigation.Runtime.WorkspaceState)
    end
  end

  defmodule Runtime.WorkspaceState do
    use Ash.Resource,
      domain: AshUITutorials.TopologyAndNavigation.RuntimeDomain,
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
      :overlay_open,
      :resolve_dialog_open,
      :restart_alert_open,
      :active_guard_action,
      :guard_title,
      :guard_summary,
      :toast_visible,
      :toast_title,
      :toast_summary,
      :toast_status,
      :runbook_focus,
      :runbook_markdown,
      :runbook_status,
      :attachment_filename,
      :attachment_support_notice,
      :diagnostics_mode,
      :diagnostics_status_model,
      :diagnostics_feedback_model,
      :diagnostics_log_entries,
      :diagnostics_stream_entries,
      :diagnostics_process_model,
      :diagnostics_status_copy,
      :topology_scope,
      :topology_tab_value,
      :topology_tree_model,
      :topology_viewport_focus,
      :topology_viewport_support_title,
      :topology_viewport_support_detail,
      :topology_canvas_layer,
      :topology_canvas_board_copy,
      :topology_canvas_legend,
      :topology_scroll_focus,
      :topology_scroll_status,
      :topology_status_copy,
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
      attribute :overlay_open, :boolean, default: false
      attribute :resolve_dialog_open, :boolean, default: false
      attribute :restart_alert_open, :boolean, default: false
      attribute :active_guard_action, :string, default: ""
      attribute :guard_title, :string, default: "Guard rail"
      attribute :guard_summary, :string, default: "Choose a guarded action from the context menu."
      attribute :toast_visible, :boolean, default: false
      attribute :toast_title, :string, default: ""
      attribute :toast_summary, :string, default: ""
      attribute :toast_status, :string, default: "idle"
      attribute :runbook_focus, :string, default: ""
      attribute :runbook_markdown, :string, default: ""
      attribute :runbook_status, :string, default: ""
      attribute :attachment_filename, :string, default: "No evidence packet selected"
      attribute :attachment_support_notice, :string, default: ""
      attribute :diagnostics_mode, :string, default: ""
      attribute :diagnostics_status_model, :map, default: %{}
      attribute :diagnostics_feedback_model, :map, default: %{}
      attribute :diagnostics_log_entries, {:array, :map}, default: []
      attribute :diagnostics_stream_entries, {:array, :map}, default: []
      attribute :diagnostics_process_model, :map, default: %{}
      attribute :diagnostics_status_copy, :string, default: ""
      attribute :topology_scope, :string, default: ""
      attribute :topology_tab_value, :string, default: ""
      attribute :topology_tree_model, {:array, :map}, default: []
      attribute :topology_viewport_focus, :string, default: ""
      attribute :topology_viewport_support_title, :string, default: ""
      attribute :topology_viewport_support_detail, :string, default: ""
      attribute :topology_canvas_layer, :string, default: ""
      attribute :topology_canvas_board_copy, :string, default: ""
      attribute :topology_canvas_legend, :string, default: ""
      attribute :topology_scroll_focus, :string, default: ""
      attribute :topology_scroll_status, :string, default: ""
      attribute :topology_status_copy, :string, default: ""
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

      update :preview_guarded_action do
        require_atomic? false
        accept([])

        argument :guard_intent, :string do
          allow_nil?(false)
        end

        change(before_action(fn changeset, _context -> preview_guarded_action(changeset) end))
      end

      update :confirm_guarded_action do
        require_atomic? false
        accept([])
        change(before_action(fn changeset, _context -> confirm_guarded_action(changeset) end))
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
      |> AshUITutorials.TopologyAndNavigation.hydrate_state()
      |> apply_hydrated_state(changeset)
    end

    defp submit_operator_workflow(changeset) do
      changeset = apply_argument_overrides(changeset)

      attrs =
        changeset
        |> state_attrs_from()
        |> apply_workflow_result(Ash.Changeset.get_argument(changeset, :workflow_intent))

      attrs
      |> AshUITutorials.TopologyAndNavigation.hydrate_state()
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

    defp preview_guarded_action(changeset) do
      attrs =
        changeset
        |> state_attrs_from()
        |> apply_guard_preview(Ash.Changeset.get_argument(changeset, :guard_intent))

      attrs
      |> AshUITutorials.TopologyAndNavigation.hydrate_state()
      |> apply_hydrated_state(changeset)
    end

    defp confirm_guarded_action(changeset) do
      attrs =
        changeset
        |> state_attrs_from()
        |> apply_guard_confirmation()

      attrs
      |> AshUITutorials.TopologyAndNavigation.hydrate_state()
      |> apply_hydrated_state(changeset)
    end

    defp apply_guard_preview(attrs, "resolve") do
      attrs
      |> close_guard_surfaces()
      |> Map.put(:resolve_dialog_open, true)
      |> Map.put(:active_guard_action, "resolve")
      |> Map.put(:guard_title, "Resolve incident")
      |> Map.put(:guard_summary, "Resolve is allowed only after the incident has been acknowledged through the operator workflow.")
      |> Map.put(:status, "Resolve guard opened for the current incident.")
    end

    defp apply_guard_preview(attrs, "restart") do
      attrs
      |> close_guard_surfaces()
      |> Map.put(:restart_alert_open, true)
      |> Map.put(:active_guard_action, "restart")
      |> Map.put(:guard_title, "Restart API Gateway")
      |> Map.put(:guard_summary, "Restart requires a scheduled maintenance window so operators can reason about the blast radius.")
      |> Map.put(:status, "Restart guard opened for API Gateway.")
    end

    defp apply_guard_preview(attrs, "silence") do
      attrs
      |> close_guard_surfaces()
      |> Map.put(:overlay_open, true)
      |> Map.put(:active_guard_action, "silence")
      |> Map.put(:guard_title, "Silence escalated alerts")
      |> Map.put(:guard_summary, "Silencing is allowed only when the incidents workspace is explicitly focused on escalated issues.")
      |> Map.put(:status, "Silence guard opened for the current incident window.")
    end

    defp apply_guard_preview(attrs, "discard_note") do
      attrs
      |> close_guard_surfaces()
      |> Map.put(:overlay_open, true)
      |> Map.put(:active_guard_action, "discard_note")
      |> Map.put(:guard_title, "Discard operator note")
      |> Map.put(:guard_summary, "Discarding note text is destructive. Confirm only if the current operator note should be removed.")
      |> Map.put(:status, "Discard-note guard opened for the operator workflow.")
    end

    defp apply_guard_preview(attrs, _other) do
      attrs
      |> close_guard_surfaces()
      |> Map.put(:guard_title, "Unknown guarded action")
      |> Map.put(:guard_summary, "Choose one of the authored guarded actions from the context menu.")
      |> Map.put(:status, "Unknown guarded action requested.")
    end

    defp apply_guard_confirmation(%{active_guard_action: "resolve"} = attrs) do
      primary_incident = Enum.find(attrs[:incident_catalog] || [], &(&1.id == "inc-1042"))

      if primary_incident && primary_incident.state == "acknowledged" do
        attrs
        |> Map.put(:incident_catalog, update_primary_incident(attrs[:incident_catalog], %{state: "resolved"}))
        |> Map.put(:detail_title, "Gateway latency spike")
        |> Map.put(:detail_summary, "Resolved after the acknowledgement workflow completed and operator review confirmed the mitigation.")
        |> Map.put(:detail_status, "resolved")
        |> Map.put(:status, "Incident resolved through the guarded confirmation flow.")
        |> guard_toast("Incident resolved", "The resolve dialog confirmed the incident close-out path.", "success")
        |> close_guard_surfaces()
      else
        blocked_guard(attrs, "Resolve blocked", "Acknowledge the incident before attempting to resolve it.")
      end
    end

    defp apply_guard_confirmation(%{active_guard_action: "restart"} = attrs) do
      if attrs[:maintenance_disabled] do
        blocked_guard(
          attrs,
          "Restart blocked",
          "Schedule a valid maintenance window before confirming a service restart."
        )
      else
        attrs
        |> Map.put(:service_catalog, update_primary_service(attrs[:service_catalog], %{status: "monitoring"}))
        |> Map.put(:detail_title, "API Gateway restart queued")
        |> Map.put(:detail_summary, "Restart confirmed behind the scheduled maintenance window. API Gateway status is now under close monitoring.")
        |> Map.put(:detail_status, "monitoring")
        |> Map.put(:status, "Restart confirmed for API Gateway.")
        |> guard_toast("Restart confirmed", "The maintenance window precondition passed, so the guarded restart action was accepted.", "success")
        |> close_guard_surfaces()
      end
    end

    defp apply_guard_confirmation(%{active_guard_action: "silence"} = attrs) do
      if attrs[:incident_escalated_only] do
        attrs
        |> Map.put(:status, "Escalated alerts silenced for the current incident window.")
        |> guard_toast("Alerts silenced", "The overlay accepted the silence action because the table was narrowed to escalated incidents.", "success")
        |> close_guard_surfaces()
      else
        blocked_guard(
          attrs,
          "Silence blocked",
          "Turn on the escalated-only incident filter before silencing alert traffic."
        )
      end
    end

    defp apply_guard_confirmation(%{active_guard_action: "discard_note"} = attrs) do
      if String.trim(to_string(attrs[:operator_note] || "")) == "" do
        blocked_guard(attrs, "Discard blocked", "There is no operator note to discard.")
      else
        attrs
        |> Map.put(:operator_note, "")
        |> Map.put(:status, "Operator note discarded after guarded confirmation.")
        |> Map.put(:form_feedback_title, "Operator note cleared")
        |> Map.put(:form_feedback_summary, "The destructive discard path cleared the note. Add a new note to re-enable acknowledge and assign actions.")
        |> Map.put(:form_feedback_status, "review")
        |> guard_toast("Operator note discarded", "The destructive note-clear action completed through the guarded overlay flow.", "success")
        |> close_guard_surfaces()
      end
    end

    defp apply_guard_confirmation(attrs) do
      blocked_guard(
        attrs,
        "Guard confirmation blocked",
        "Open one of the authored guarded actions before attempting a confirmation."
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

    defp guard_toast(attrs, title, summary, status) do
      attrs
      |> Map.put(:toast_visible, true)
      |> Map.put(:toast_title, title)
      |> Map.put(:toast_summary, summary)
      |> Map.put(:toast_status, status)
    end

    defp blocked_guard(attrs, title, summary) do
      attrs
      |> Map.put(:status, summary)
      |> guard_toast(title, summary, "blocked")
      |> close_guard_surfaces()
    end

    defp close_guard_surfaces(attrs) do
      attrs
      |> Map.put(:overlay_open, false)
      |> Map.put(:resolve_dialog_open, false)
      |> Map.put(:restart_alert_open, false)
      |> Map.put(:active_guard_action, "")
    end

    defp update_primary_incident(incidents, updates) do
      Enum.map(incidents || [], fn
        %{id: "inc-1042"} = incident -> Map.merge(incident, updates)
        incident -> incident
      end)
    end

    defp update_primary_service(services, updates) do
      Enum.map(services || [], fn
        %{id: "svc-api-gateway"} = service -> Map.merge(service, updates)
        service -> service
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
      resource(AshUITutorials.TopologyAndNavigation.UiScreen)
      resource(AshUITutorials.TopologyAndNavigation.UiElement)
      resource(AshUITutorials.TopologyAndNavigation.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUITutorials.TopologyAndNavigation.UiStorageDomain,
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
      has_many :elements, AshUITutorials.TopologyAndNavigation.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUITutorials.TopologyAndNavigation.UiBinding do
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
      domain: AshUITutorials.TopologyAndNavigation.UiStorageDomain,
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
      belongs_to :screen, AshUITutorials.TopologyAndNavigation.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUITutorials.TopologyAndNavigation.UiBinding do
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
      domain: AshUITutorials.TopologyAndNavigation.UiStorageDomain,
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
      belongs_to :element, AshUITutorials.TopologyAndNavigation.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUITutorials.TopologyAndNavigation.UiScreen do
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
      resource(AshUITutorials.TopologyAndNavigation.Examples.ServicesScreen)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ServicesWorkspacePanelElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.WorkspaceMenuElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ShowServicesButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ShowIncidentsButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ShowOperatorViewButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.WorkspaceSelectionSummaryElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.CommandPaletteElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.CommandPaletteInputElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.CommandFocusGatewayButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.CommandFocusIncidentButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.CommandOpenOperatorViewButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.CommandSummaryTextElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ServicesFiltersGroupElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ServicesQueryFieldElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ServicesQueryInputElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ServiceStatusFieldElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ServiceStatusSelectElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.IncludeHealthyFieldElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.IncludeHealthyCheckboxElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ServicesListElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyReviewPanelElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologySplitPaneElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyScopeMenuElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ShowServiceTopologyButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ShowDependencyTopologyButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ShowIncidentScopeTopologyButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyScopeSummaryElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyTabsElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.FocusGatewayTopologyTabButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.FocusSearchTopologyTabButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.FocusClusterTopologyTabButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyTabsStatusElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyTreeViewElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyViewportElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyViewportFocusCopyElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyViewportSupportPanelElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyViewportSupportTitleElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyViewportSupportDetailElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasTrafficPathButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasBlastRadiusButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasLayerElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasBoardCopyElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasLegendElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyScrollBarElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyCommanderScrollButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyInfrastructureScrollButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyHandoffScrollButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyScrollFocusCopyElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyScrollStatusElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.TopologyPanelStatusTextElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.SharedDetailCardElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.SharedDetailBadgeElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.SharedDetailTitleElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.SharedDetailSummaryElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ServicesStatusTextElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ServicesStoryTextElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ServicesSignalTextElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.IncidentsScreen)
      resource(AshUITutorials.TopologyAndNavigation.Examples.IncidentsWorkspacePanelElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.IncidentsFiltersGroupElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.IncidentSeverityFieldElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.IncidentSeverityRadioElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.IncidentEscalatedFieldElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.IncidentEscalatedSwitchElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.OperatorFormsPanelElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.OperatorWorkflowFormElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.NoteAndAssignmentGroupElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.OperatorNoteFieldElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.OperatorNoteInputElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.AssignmentTargetFieldElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.AssignmentTargetPickListElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.MaintenanceWindowGroupElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.MaintenanceDurationFieldElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.MaintenanceDurationInputElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.MaintenanceDateFieldElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.MaintenanceDateInputElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.MaintenanceTimeFieldElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.MaintenanceTimeInputElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.AcknowledgeIncidentButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.AssignIncidentButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ScheduleMaintenanceButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.FormFeedbackBadgeElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.FormFeedbackTitleElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.FormFeedbackSummaryElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.GuardedActionsPanelElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.GuardedActionsMenuElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.OpenResolveGuardButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.OpenRestartGuardButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.OpenSilenceGuardButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.OpenDiscardNoteGuardButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.GuardSummaryTextElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.GuardOverlayElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.GuardOverlayTitleTextElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.GuardOverlaySummaryTextElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ConfirmOverlayGuardButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.CancelGuardSurfaceButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ResolveGuardDialogElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ResolveGuardSummaryTextElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ConfirmResolveGuardButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.RestartGuardAlertElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.RestartGuardSummaryTextElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.ConfirmRestartGuardButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.GuardResultToastElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.GuardToastTitleTextElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.GuardToastSummaryTextElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.DismissGuardToastButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.IncidentsTableElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.RunbookReviewPanelElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.RunbookSplitPaneElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.RunbookFocusTitleElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.RunbookMarkdownViewerElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.LoadGatewayRunbookButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.LoadRollbackRunbookButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.AttachmentEvidenceCardElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.AttachmentPreviewTextElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.AttachmentFileFieldElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.AttachmentFileInputElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.AttachmentReferenceLinkElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.AttachmentImageElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.AttachmentSupportTextElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.RunbookStatusTextElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.LiveDiagnosticsPanelElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.LoadGatewayDiagnosticsButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.LoadSearchDiagnosticsButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.LoadPressureDiagnosticsButtonElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.DiagnosticsStatusElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.DiagnosticsInlineFeedbackElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.DiagnosticsLogViewerElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.DiagnosticsStreamWidgetElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.DiagnosticsProcessMonitorElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.DiagnosticsStatusTextElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.IncidentsStatusTextElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.IncidentsStoryTextElement)
      resource(AshUITutorials.TopologyAndNavigation.Examples.IncidentsSignalTextElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUITutorials.TopologyAndNavigation.AuthoringDomain,
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :menus, AshUITutorials.TopologyAndNavigation.Examples.WorkspaceMenuElement do
        destination_attribute(:parent_id)
      end

      has_many :command_palettes,
               AshUITutorials.TopologyAndNavigation.Examples.CommandPaletteElement do
        destination_attribute(:parent_id)
      end

      has_many :filter_groups,
               AshUITutorials.TopologyAndNavigation.Examples.ServicesFiltersGroupElement do
        destination_attribute(:parent_id)
      end

      has_many :service_lists, AshUITutorials.TopologyAndNavigation.Examples.ServicesListElement do
        destination_attribute(:parent_id)
      end

      has_many :topology_review_panels,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyReviewPanelElement do
        destination_attribute(:parent_id)
      end

      has_many :detail_cards, AshUITutorials.TopologyAndNavigation.Examples.SharedDetailCardElement do
        destination_attribute(:parent_id)
      end

      has_many :status_texts, AshUITutorials.TopologyAndNavigation.Examples.ServicesStatusTextElement do
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

      relationship :topology_review_panels do
        kind(:child)
        slot(:body)
        placement(:append)
        order(40)
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :services_buttons, AshUITutorials.TopologyAndNavigation.Examples.ShowServicesButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :incidents_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.ShowIncidentsButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :operator_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.ShowOperatorViewButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :selection_summaries,
               AshUITutorials.TopologyAndNavigation.Examples.WorkspaceSelectionSummaryElement do
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :search_inputs,
               AshUITutorials.TopologyAndNavigation.Examples.CommandPaletteInputElement do
        destination_attribute(:parent_id)
      end

      has_many :gateway_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.CommandFocusGatewayButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :incident_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.CommandFocusIncidentButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :operator_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.CommandOpenOperatorViewButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :summary_texts,
               AshUITutorials.TopologyAndNavigation.Examples.CommandSummaryTextElement do
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
            detail_summary: %{"from" => "static", "value" => "Operator review is now centered on the maintenance workflow and the guarded action surfaces introduced after the Chapter 4 forms."},
            detail_status: %{"from" => "static", "value" => "maintenance planner"},
            status: %{"from" => "static", "value" => "Command palette focused the maintenance planner workflow."}
          }
        })

        metadata(%{intent: "open_operator_view", success_message: "Maintenance planner preview loaded"})
      end
    end
  end

  defmodule Examples.CommandSummaryTextElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :query_fields,
               AshUITutorials.TopologyAndNavigation.Examples.ServicesQueryFieldElement do
        destination_attribute(:parent_id)
      end

      has_many :status_fields,
               AshUITutorials.TopologyAndNavigation.Examples.ServiceStatusFieldElement do
        destination_attribute(:parent_id)
      end

      has_many :healthy_fields,
               AshUITutorials.TopologyAndNavigation.Examples.IncludeHealthyFieldElement do
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :inputs,
               AshUITutorials.TopologyAndNavigation.Examples.ServicesQueryInputElement do
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :selects,
               AshUITutorials.TopologyAndNavigation.Examples.ServiceStatusSelectElement do
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :checkboxes,
               AshUITutorials.TopologyAndNavigation.Examples.IncludeHealthyCheckboxElement do
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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

  defmodule Examples.TopologyReviewPanelElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :split_panes, AshUITutorials.TopologyAndNavigation.Examples.TopologySplitPaneElement do
        destination_attribute(:parent_id)
      end

      has_many :status_texts,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyPanelStatusTextElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :split_panes do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :status_texts do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:card)

      props(%{
        title: "Topology review",
        class: "ashui-example-panel ashui-tutorial-workspace-panel ashui-tutorial-topology-panel"
      })

      metadata(%{id: "topology-review-panel", section: "demo", slot: "body", position: 40})
    end
  end

  defmodule Examples.TopologySplitPaneElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :scope_menus,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyScopeMenuElement do
        destination_attribute(:parent_id)
      end

      has_many :tabs, AshUITutorials.TopologyAndNavigation.Examples.TopologyTabsElement do
        destination_attribute(:parent_id)
      end

      has_many :tree_views,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyTreeViewElement do
        destination_attribute(:parent_id)
      end

      has_many :viewports,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyViewportElement do
        destination_attribute(:parent_id)
      end

      has_many :canvases,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasElement do
        destination_attribute(:parent_id)
      end

      has_many :scroll_bars,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyScrollBarElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :scope_menus do
        kind(:child)
        slot(:primary)
        placement(:append)
        order(0)
      end

      relationship :tabs do
        kind(:child)
        slot(:primary)
        placement(:append)
        order(10)
      end

      relationship :tree_views do
        kind(:child)
        slot(:primary)
        placement(:append)
        order(20)
      end

      relationship :viewports do
        kind(:child)
        slot(:secondary)
        placement(:append)
        order(0)
      end

      relationship :canvases do
        kind(:child)
        slot(:secondary)
        placement(:append)
        order(10)
      end

      relationship :scroll_bars do
        kind(:child)
        slot(:secondary)
        placement(:append)
        order(20)
      end
    end

    ui_element do
      type(:"custom:split_pane")

      props(%{
        title: "Topology split pane",
        description:
          "Keep service topology, dependency drill-downs, and large review surfaces visible in related panes instead of rebuilding a bespoke shell.",
        class: "ashui-tutorial-topology-split"
      })

      metadata(%{id: "topology-split-pane", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.TopologyScopeMenuElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :service_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.ShowServiceTopologyButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :dependency_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.ShowDependencyTopologyButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :incident_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.ShowIncidentScopeTopologyButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :scope_summaries,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyScopeSummaryElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :service_buttons do
        kind(:child)
        slot(:nav)
        placement(:append)
        order(0)
      end

      relationship :dependency_buttons do
        kind(:child)
        slot(:nav)
        placement(:append)
        order(10)
      end

      relationship :incident_buttons do
        kind(:child)
        slot(:nav)
        placement(:append)
        order(20)
      end

      relationship :scope_summaries do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:menu")

      props(%{
        title: "Topology scopes",
        description:
          "Use the authored menu to switch between service maps, dependency paths, and incident-scope drill-downs.",
        class: "ashui-tutorial-topology-menu"
      })

      metadata(%{id: "topology-scope-menu", section: "demo", slot: "primary", position: 0})
    end
  end

  defmodule Examples.ShowServiceTopologyButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)

      props(%{label: "Service map", class: "ashui-example-primary-cta", variant: "secondary"})

      metadata(%{id: "show-service-topology", section: "demo", slot: "nav", position: 0})
    end

    ui_actions do
      action :show_service_topology do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            selected_value: %{"from" => "static", "value" => "services"},
            topology_scope: %{"from" => "static", "value" => "service topology"},
            topology_tab_value: %{"from" => "static", "value" => "gateway lane"},
            topology_tree_model: %{
              "from" => "static",
              "value" => [
                %{
                  "label" => "API Gateway",
                  "meta" => "degraded",
                  "children" => [
                    %{"label" => "Auth fan-out", "meta" => "monitoring"},
                    %{"label" => "Billing retries", "meta" => "healthy"},
                    %{"label" => "Search reads", "meta" => "watching"}
                  ]
                }
              ]
            },
            topology_viewport_focus: %{"from" => "static", "value" => "gateway lane"},
            topology_viewport_support_title: %{"from" => "static", "value" => "Gateway dependency lane"},
            topology_viewport_support_detail: %{
              "from" => "static",
              "value" =>
                "The viewport keeps the ingress lane, auth fan-out, and downstream recovery checkpoints readable even when the larger screen collapses into stacked panels on smaller layouts."
            },
            topology_canvas_layer: %{"from" => "static", "value" => "traffic path"},
            topology_canvas_board_copy: %{
              "from" => "static",
              "value" =>
                "Traffic enters through the API Gateway, fans into auth, then branches into billing and search paths that the on-call operator is reviewing together."
            },
            topology_canvas_legend: %{
              "from" => "static",
              "value" =>
                "Canvas review is focused on the gateway traffic path and the current operator handoff edges."
            },
            topology_scroll_focus: %{"from" => "static", "value" => "commander lane"},
            topology_scroll_status: %{
              "from" => "static",
              "value" =>
                "Scroll focus is aligned to the commander lane so the incident lead can keep the gateway path, handoff packet, and mitigation order visible."
            },
            topology_status_copy: %{
              "from" => "static",
              "value" =>
                "Topology review is centered on the API Gateway service map with the commander lane in focus."
            },
            detail_title: %{"from" => "static", "value" => "API Gateway"},
            detail_summary: %{
              "from" => "static",
              "value" =>
                "Topology review is centered on the API Gateway ingress lane and the downstream dependencies currently affecting the incident."
            },
            detail_status: %{"from" => "static", "value" => "degraded"},
            status: %{"from" => "static", "value" => "Service topology review loaded for the API Gateway."}
          }
        })

        metadata(%{intent: "select_topology_scope", success_message: "Service topology loaded"})
      end
    end
  end

  defmodule Examples.ShowDependencyTopologyButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)

      props(%{label: "Dependency path", class: "ashui-example-secondary-cta", variant: "secondary"})

      metadata(%{id: "show-dependency-topology", section: "demo", slot: "nav", position: 10})
    end

    ui_actions do
      action :show_dependency_topology do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            selected_value: %{"from" => "static", "value" => "services"},
            topology_scope: %{"from" => "static", "value" => "dependency path"},
            topology_tab_value: %{"from" => "static", "value" => "search lane"},
            topology_tree_model: %{
              "from" => "static",
              "value" => [
                %{
                  "label" => "API Gateway",
                  "meta" => "entry",
                  "children" => [
                    %{
                      "label" => "Search",
                      "meta" => "watching",
                      "children" => [
                        %{"label" => "Replica lag snapshot", "meta" => "stale"},
                        %{"label" => "Queue depth review", "meta" => "rising"}
                      ]
                    },
                    %{"label" => "Billing", "meta" => "steady"}
                  ]
                }
              ]
            },
            topology_viewport_focus: %{"from" => "static", "value" => "search lane"},
            topology_viewport_support_title: %{"from" => "static", "value" => "Search dependency path"},
            topology_viewport_support_detail: %{
              "from" => "static",
              "value" =>
                "This drill-down keeps the lagging search dependency visible beside the larger topology shell so operators can compare structural risk and stale diagnostics together."
            },
            topology_canvas_layer: %{"from" => "static", "value" => "dependency depth"},
            topology_canvas_board_copy: %{
              "from" => "static",
              "value" =>
                "The review canvas emphasizes the narrow path from public ingress into the lagging search dependency and the queued mitigation checkpoints behind it."
            },
            topology_canvas_legend: %{
              "from" => "static",
              "value" =>
                "Canvas review is focused on search dependency depth and the queued replica recovery path."
            },
            topology_scroll_focus: %{"from" => "static", "value" => "infra lane"},
            topology_scroll_status: %{
              "from" => "static",
              "value" =>
                "Scroll focus is aligned to the infrastructure lane so platform reviewers can keep replica lag, queue depth, and promotion readiness visible."
            },
            topology_status_copy: %{
              "from" => "static",
              "value" =>
                "Topology review narrowed to the search dependency path with the infrastructure lane in focus."
            },
            detail_title: %{"from" => "static", "value" => "Search dependency path"},
            detail_summary: %{
              "from" => "static",
              "value" =>
                "Dependency review is highlighting the search lag lane and the queued promotion checks behind it."
            },
            detail_status: %{"from" => "static", "value" => "watching"},
            status: %{"from" => "static", "value" => "Dependency path review loaded for the search lane."}
          }
        })

        metadata(%{intent: "select_topology_scope", success_message: "Dependency path loaded"})
      end
    end
  end

  defmodule Examples.ShowIncidentScopeTopologyButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)

      props(%{label: "Incident scope", class: "ashui-example-secondary-cta", variant: "secondary"})

      metadata(%{id: "show-incident-scope-topology", section: "demo", slot: "nav", position: 20})
    end

    ui_actions do
      action :show_incident_scope_topology do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            selected_value: %{"from" => "static", "value" => "services"},
            topology_scope: %{"from" => "static", "value" => "incident scope"},
            topology_tab_value: %{"from" => "static", "value" => "core-east lane"},
            topology_tree_model: %{
              "from" => "static",
              "value" => [
                %{
                  "label" => "Gateway latency incident",
                  "meta" => "sev-1",
                  "children" => [
                    %{"label" => "Core East cluster", "meta" => "elevated"},
                    %{"label" => "Retry workers", "meta" => "pressure"},
                    %{"label" => "Operator handoff", "meta" => "active"}
                  ]
                }
              ]
            },
            topology_viewport_focus: %{"from" => "static", "value" => "core-east lane"},
            topology_viewport_support_title: %{"from" => "static", "value" => "Incident blast radius"},
            topology_viewport_support_detail: %{
              "from" => "static",
              "value" =>
                "The incident-scope view treats topology as an operator coordination surface: cluster, worker pressure, and handoff state stay readable in one drill-down story."
            },
            topology_canvas_layer: %{"from" => "static", "value" => "blast radius"},
            topology_canvas_board_copy: %{
              "from" => "static",
              "value" =>
                "The canvas shows the blast radius around the Core East cluster, the retry workers currently under pressure, and the handoff route to incident command."
            },
            topology_canvas_legend: %{
              "from" => "static",
              "value" =>
                "Canvas review is focused on the current incident blast radius across cluster and operator lanes."
            },
            topology_scroll_focus: %{"from" => "static", "value" => "handoff lane"},
            topology_scroll_status: %{
              "from" => "static",
              "value" =>
                "Scroll focus is aligned to the handoff lane so the commander, platform manager, and maintenance planner can review the same incident scope."
            },
            topology_status_copy: %{
              "from" => "static",
              "value" =>
                "Topology review switched to the incident-scope drill-down with the handoff lane in focus."
            },
            detail_title: %{"from" => "static", "value" => "Gateway latency incident scope"},
            detail_summary: %{
              "from" => "static",
              "value" =>
                "Scope review is highlighting the Core East cluster, retry-worker pressure, and the current operator handoff route."
            },
            detail_status: %{"from" => "static", "value" => "sev-1"},
            status: %{"from" => "static", "value" => "Incident-scope topology review loaded for the active sev-1 lane."}
          }
        })

        metadata(%{intent: "select_topology_scope", success_message: "Incident scope loaded"})
      end
    end
  end

  defmodule Examples.TopologyScopeSummaryElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "service topology", class: "ashui-example-surface-copy ashui-example-menu-summary"})
      metadata(%{id: "topology-scope-summary", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :topology_scope do
        source(%{resource: "WorkspaceState", field: :topology_scope, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "topology_scope"})
      end
    end
  end

  defmodule Examples.TopologyTabsElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :gateway_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.FocusGatewayTopologyTabButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :search_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.FocusSearchTopologyTabButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :cluster_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.FocusClusterTopologyTabButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :status_texts,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyTabsStatusElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :gateway_buttons do
        kind(:child)
        slot(:nav)
        placement(:append)
        order(0)
      end

      relationship :search_buttons do
        kind(:child)
        slot(:nav)
        placement(:append)
        order(10)
      end

      relationship :cluster_buttons do
        kind(:child)
        slot(:nav)
        placement(:append)
        order(20)
      end

      relationship :status_texts do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:tabs")

      props(%{
        title: "Drill-down tabs",
        description:
          "Tabs keep gateway, search, and cluster drill-downs explicit without discarding the larger topology panel.",
        class: "ashui-tutorial-topology-tabs"
      })

      metadata(%{id: "topology-tabs", section: "demo", slot: "primary", position: 10})
    end
  end

  defmodule Examples.FocusGatewayTopologyTabButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Gateway", class: "ashui-example-nav-button", variant: "secondary"})
      metadata(%{id: "focus-gateway-topology-tab", section: "demo", slot: "nav", position: 0})
    end

    ui_actions do
      action :focus_gateway_topology_tab do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            topology_tab_value: %{"from" => "static", "value" => "gateway lane"},
            topology_viewport_focus: %{"from" => "static", "value" => "gateway lane"},
            topology_viewport_support_title: %{"from" => "static", "value" => "Gateway dependency lane"},
            topology_viewport_support_detail: %{
              "from" => "static",
              "value" =>
                "Gateway review keeps ingress, auth fan-out, and mitigation checkpoints visible even when the split pane stacks on smaller screens."
            },
            topology_status_copy: %{
              "from" => "static",
              "value" =>
                "Topology tab focus returned to the gateway lane."
            },
            detail_title: %{"from" => "static", "value" => "API Gateway"},
            detail_summary: %{
              "from" => "static",
              "value" =>
                "Gateway drill-down is back in focus so the operator can compare ingress pressure and downstream dependency state."
            },
            detail_status: %{"from" => "static", "value" => "degraded"},
            status: %{"from" => "static", "value" => "Gateway drill-down tab selected."}
          }
        })

        metadata(%{intent: "select_topology_tab", success_message: "Gateway topology tab loaded"})
      end
    end
  end

  defmodule Examples.FocusSearchTopologyTabButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Search", class: "ashui-example-nav-button", variant: "secondary"})
      metadata(%{id: "focus-search-topology-tab", section: "demo", slot: "nav", position: 10})
    end

    ui_actions do
      action :focus_search_topology_tab do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            topology_tab_value: %{"from" => "static", "value" => "search lane"},
            topology_viewport_focus: %{"from" => "static", "value" => "search lane"},
            topology_viewport_support_title: %{"from" => "static", "value" => "Search dependency path"},
            topology_viewport_support_detail: %{
              "from" => "static",
              "value" =>
                "Search drill-down keeps the stale replica snapshot and queue-depth story visible beside the broader topology shell."
            },
            topology_status_copy: %{
              "from" => "static",
              "value" =>
                "Topology tab focus moved to the search lane."
            },
            detail_title: %{"from" => "static", "value" => "Search"},
            detail_summary: %{
              "from" => "static",
              "value" =>
                "Search drill-down is in focus so operators can weigh queue depth and replica lag against the broader service map."
            },
            detail_status: %{"from" => "static", "value" => "watching"},
            status: %{"from" => "static", "value" => "Search drill-down tab selected."}
          }
        })

        metadata(%{intent: "select_topology_tab", success_message: "Search topology tab loaded"})
      end
    end
  end

  defmodule Examples.FocusClusterTopologyTabButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Core East", class: "ashui-example-nav-button", variant: "secondary"})
      metadata(%{id: "focus-cluster-topology-tab", section: "demo", slot: "nav", position: 20})
    end

    ui_actions do
      action :focus_cluster_topology_tab do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            topology_tab_value: %{"from" => "static", "value" => "core-east lane"},
            topology_viewport_focus: %{"from" => "static", "value" => "core-east lane"},
            topology_viewport_support_title: %{"from" => "static", "value" => "Core East cluster review"},
            topology_viewport_support_detail: %{
              "from" => "static",
              "value" =>
                "Cluster drill-down keeps regional load, retry pressure, and incident coordination visible when the review shifts from service lanes to infrastructure scope."
            },
            topology_status_copy: %{
              "from" => "static",
              "value" =>
                "Topology tab focus moved to the Core East cluster lane."
            },
            detail_title: %{"from" => "static", "value" => "Core East cluster"},
            detail_summary: %{
              "from" => "static",
              "value" =>
                "Cluster drill-down is in focus so the operator can compare regional load with the sev-1 blast radius."
            },
            detail_status: %{"from" => "static", "value" => "elevated"},
            status: %{"from" => "static", "value" => "Core East drill-down tab selected."}
          }
        })

        metadata(%{intent: "select_topology_tab", success_message: "Cluster topology tab loaded"})
      end
    end
  end

  defmodule Examples.TopologyTabsStatusElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "gateway lane", class: "ashui-example-surface-copy ashui-example-tabs-panel"})
      metadata(%{id: "topology-tabs-status", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :topology_tab_value do
        source(%{resource: "WorkspaceState", field: :topology_tab_value, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "topology_tab_value"})
      end
    end
  end

  defmodule Examples.TopologyTreeViewElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:"custom:tree_view")

      props(%{
        title: "Dependency tree",
        description: "The tree stays explicit about the active structural review path and its seeded drill-down nodes.",
        class: "ashui-tutorial-topology-tree"
      })

      metadata(%{id: "topology-tree-view", section: "demo", slot: "primary", position: 20})
    end

    ui_bindings do
      binding :topology_tree_model do
        source(%{resource: "WorkspaceState", field: :topology_tree_model, id: "tutorial-services-incidents-state"})
        target("model")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "topology_tree"})
      end
    end
  end

  defmodule Examples.TopologyViewportElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :focus_copy_elements,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyViewportFocusCopyElement do
        destination_attribute(:parent_id)
      end

      has_many :support_panels,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyViewportSupportPanelElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :focus_copy_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :support_panels do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:"custom:viewport")

      props(%{
        title: "Topology viewport",
        description:
          "The viewport keeps the active drill-down lane readable while the supporting note explains how the same surface behaves on smaller screens.",
        class: "ashui-tutorial-topology-viewport"
      })

      metadata(%{id: "topology-viewport", section: "demo", slot: "secondary", position: 0})
    end
  end

  defmodule Examples.TopologyViewportFocusCopyElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "gateway lane", class: "ashui-example-surface-copy"})
      metadata(%{id: "topology-viewport-focus", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :topology_viewport_focus do
        source(%{resource: "WorkspaceState", field: :topology_viewport_focus, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "topology_viewport_focus"})
      end
    end
  end

  defmodule Examples.TopologyViewportSupportPanelElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :titles,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyViewportSupportTitleElement do
        destination_attribute(:parent_id)
      end

      has_many :details,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyViewportSupportDetailElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :titles do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :details do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:card)
      props(%{class: "ashui-example-layout-card"})
      metadata(%{id: "topology-viewport-support-panel", section: "demo", slot: "body", position: 10})
    end
  end

  defmodule Examples.TopologyViewportSupportTitleElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "Gateway dependency lane", class: "ashui-tutorial-detail-title"})
      metadata(%{id: "topology-viewport-support-title", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :topology_viewport_support_title do
        source(%{resource: "WorkspaceState", field: :topology_viewport_support_title, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "topology_viewport_support_title"})
      end
    end
  end

  defmodule Examples.TopologyViewportSupportDetailElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-muted-copy"})
      metadata(%{id: "topology-viewport-support-detail", section: "demo", slot: "body", position: 10})
    end

    ui_bindings do
      binding :topology_viewport_support_detail do
        source(%{resource: "WorkspaceState", field: :topology_viewport_support_detail, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "topology_viewport_support_detail"})
      end
    end
  end

  defmodule Examples.TopologyCanvasElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :traffic_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasTrafficPathButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :blast_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasBlastRadiusButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :layer_elements,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasLayerElement do
        destination_attribute(:parent_id)
      end

      has_many :board_copy_elements,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasBoardCopyElement do
        destination_attribute(:parent_id)
      end

      has_many :legend_elements,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasLegendElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :traffic_buttons do
        kind(:child)
        slot(:toolbar)
        placement(:append)
        order(0)
      end

      relationship :blast_buttons do
        kind(:child)
        slot(:toolbar)
        placement(:append)
        order(10)
      end

      relationship :layer_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :board_copy_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :legend_elements do
        kind(:child)
        slot(:legend)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:canvas")

      props(%{
        title: "Topology canvas",
        description:
          "The canvas keeps the board and legend explicit while nested public controls switch the active topology layer.",
        class: "ashui-tutorial-topology-canvas"
      })

      metadata(%{id: "topology-canvas", section: "demo", slot: "secondary", position: 10})
    end
  end

  defmodule Examples.TopologyCanvasTrafficPathButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Traffic path", class: "ashui-example-command-button", variant: "secondary"})
      metadata(%{id: "topology-canvas-traffic-path", section: "demo", slot: "toolbar", position: 0})
    end

    ui_actions do
      action :focus_topology_traffic_path do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            topology_canvas_layer: %{"from" => "static", "value" => "traffic path"},
            topology_canvas_board_copy: %{
              "from" => "static",
              "value" =>
                "The review canvas is following the primary traffic path from ingress through auth and into the downstream service lanes."
            },
            topology_canvas_legend: %{
              "from" => "static",
              "value" => "Canvas review returned to the traffic path layer."
            },
            topology_status_copy: %{"from" => "static", "value" => "Topology canvas is focused on the traffic path layer."},
            status: %{"from" => "static", "value" => "Topology canvas switched to the traffic path layer."}
          }
        })

        metadata(%{intent: "select_topology_canvas_layer", success_message: "Traffic path layer loaded"})
      end
    end
  end

  defmodule Examples.TopologyCanvasBlastRadiusButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Blast radius", class: "ashui-example-command-button", variant: "secondary"})
      metadata(%{id: "topology-canvas-blast-radius", section: "demo", slot: "toolbar", position: 10})
    end

    ui_actions do
      action :focus_topology_blast_radius do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            topology_canvas_layer: %{"from" => "static", "value" => "blast radius"},
            topology_canvas_board_copy: %{
              "from" => "static",
              "value" =>
                "The review canvas is now emphasizing cluster impact, worker pressure, and the operator handoff ring around the current incident."
            },
            topology_canvas_legend: %{
              "from" => "static",
              "value" => "Canvas review switched to the incident blast-radius layer."
            },
            topology_status_copy: %{"from" => "static", "value" => "Topology canvas is focused on the incident blast-radius layer."},
            status: %{"from" => "static", "value" => "Topology canvas switched to the blast-radius layer."}
          }
        })

        metadata(%{intent: "select_topology_canvas_layer", success_message: "Blast radius layer loaded"})
      end
    end
  end

  defmodule Examples.TopologyCanvasLayerElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "traffic path", class: "ashui-example-surface-copy"})
      metadata(%{id: "topology-canvas-layer", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :topology_canvas_layer do
        source(%{resource: "WorkspaceState", field: :topology_canvas_layer, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "topology_canvas_layer"})
      end
    end
  end

  defmodule Examples.TopologyCanvasBoardCopyElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-example-surface-meta"})
      metadata(%{id: "topology-canvas-board-copy", section: "demo", slot: "body", position: 10})
    end

    ui_bindings do
      binding :topology_canvas_board_copy do
        source(%{resource: "WorkspaceState", field: :topology_canvas_board_copy, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "topology_canvas_board_copy"})
      end
    end
  end

  defmodule Examples.TopologyCanvasLegendElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-example-surface-meta"})
      metadata(%{id: "topology-canvas-legend", section: "demo", slot: "legend", position: 0})
    end

    ui_bindings do
      binding :topology_canvas_legend do
        source(%{resource: "WorkspaceState", field: :topology_canvas_legend, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "topology_canvas_legend"})
      end
    end
  end

  defmodule Examples.TopologyScrollBarElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :focus_copy_elements,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyScrollFocusCopyElement do
        destination_attribute(:parent_id)
      end

      has_many :commander_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyCommanderScrollButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :infrastructure_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyInfrastructureScrollButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :handoff_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyHandoffScrollButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :status_texts,
               AshUITutorials.TopologyAndNavigation.Examples.TopologyScrollStatusElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :focus_copy_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :commander_buttons do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :infrastructure_buttons do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end

      relationship :handoff_buttons do
        kind(:child)
        slot(:body)
        placement(:append)
        order(30)
      end

      relationship :status_texts do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:scroll_bar")

      props(%{
        title: "Review lane scroll",
        description:
          "The scroll surface keeps the active operator lane explicit while the same shell can collapse into stacked content on smaller screens.",
        class: "ashui-tutorial-topology-scroll",
        thumb_label: "commander lane"
      })

      metadata(%{id: "topology-scroll-bar", section: "demo", slot: "secondary", position: 20})
    end

    ui_bindings do
      binding :topology_scroll_focus do
        source(%{resource: "WorkspaceState", field: :topology_scroll_focus, id: "tutorial-services-incidents-state"})
        target("thumb_label")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "topology_scroll_focus"})
      end
    end
  end

  defmodule Examples.TopologyCommanderScrollButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Commander lane", class: "ashui-example-nav-button", variant: "secondary"})
      metadata(%{id: "topology-commander-scroll", section: "demo", slot: "body", position: 10})
    end

    ui_actions do
      action :focus_commander_scroll_lane do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            topology_scroll_focus: %{"from" => "static", "value" => "commander lane"},
            topology_scroll_status: %{
              "from" => "static",
              "value" =>
                "Scroll focus returned to the commander lane so the incident lead can keep the traffic path and handoff packet visible."
            },
            topology_status_copy: %{"from" => "static", "value" => "Review lane focus returned to the commander lane."},
            status: %{"from" => "static", "value" => "Topology review lane switched to the commander lane."}
          }
        })

        metadata(%{intent: "select_topology_scroll_lane", success_message: "Commander lane loaded"})
      end
    end
  end

  defmodule Examples.TopologyInfrastructureScrollButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Infra lane", class: "ashui-example-nav-button", variant: "secondary"})
      metadata(%{id: "topology-infrastructure-scroll", section: "demo", slot: "body", position: 20})
    end

    ui_actions do
      action :focus_infrastructure_scroll_lane do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            topology_scroll_focus: %{"from" => "static", "value" => "infra lane"},
            topology_scroll_status: %{
              "from" => "static",
              "value" =>
                "Scroll focus moved to the infrastructure lane so queue depth, cluster pressure, and replica readiness stay grouped together."
            },
            topology_status_copy: %{"from" => "static", "value" => "Review lane focus moved to the infrastructure lane."},
            status: %{"from" => "static", "value" => "Topology review lane switched to the infrastructure lane."}
          }
        })

        metadata(%{intent: "select_topology_scroll_lane", success_message: "Infrastructure lane loaded"})
      end
    end
  end

  defmodule Examples.TopologyHandoffScrollButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Handoff lane", class: "ashui-example-nav-button", variant: "secondary"})
      metadata(%{id: "topology-handoff-scroll", section: "demo", slot: "body", position: 30})
    end

    ui_actions do
      action :focus_handoff_scroll_lane do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            topology_scroll_focus: %{"from" => "static", "value" => "handoff lane"},
            topology_scroll_status: %{
              "from" => "static",
              "value" =>
                "Scroll focus moved to the handoff lane so incident command, platform review, and maintenance coordination stay visible together."
            },
            topology_status_copy: %{"from" => "static", "value" => "Review lane focus moved to the handoff lane."},
            status: %{"from" => "static", "value" => "Topology review lane switched to the handoff lane."}
          }
        })

        metadata(%{intent: "select_topology_scroll_lane", success_message: "Handoff lane loaded"})
      end
    end
  end

  defmodule Examples.TopologyScrollFocusCopyElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "commander lane", class: "ashui-example-surface-copy"})
      metadata(%{id: "topology-scroll-focus-copy", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :topology_scroll_focus do
        source(%{resource: "WorkspaceState", field: :topology_scroll_focus, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "topology_scroll_focus_copy"})
      end
    end
  end

  defmodule Examples.TopologyScrollStatusElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-example-surface-meta"})
      metadata(%{id: "topology-scroll-status", section: "demo", slot: "footer", position: 0})
    end

    ui_bindings do
      binding :topology_scroll_status do
        source(%{resource: "WorkspaceState", field: :topology_scroll_status, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "topology_scroll_status"})
      end
    end
  end

  defmodule Examples.TopologyPanelStatusTextElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-muted-copy"})
      metadata(%{id: "topology-panel-status", section: "demo", slot: "footer", position: 0})
    end

    ui_bindings do
      binding :topology_status_copy do
        source(%{resource: "WorkspaceState", field: :topology_status_copy, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "topology_status_copy"})
      end
    end
  end

  defmodule Examples.SharedDetailCardElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :badges, AshUITutorials.TopologyAndNavigation.Examples.SharedDetailBadgeElement do
        destination_attribute(:parent_id)
      end

      has_many :titles, AshUITutorials.TopologyAndNavigation.Examples.SharedDetailTitleElement do
        destination_attribute(:parent_id)
      end

      has_many :summaries, AshUITutorials.TopologyAndNavigation.Examples.SharedDetailSummaryElement do
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: persist a service query, narrow the status filter, then open the topology panel to move between service maps, dependency paths, incident scope, drill-down tabs, canvas layers, and review lanes without rebuilding the shared shell by hand.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "services-story-text", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.ServicesSignalTextElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: change -> WorkspaceState.service_query/service_status_filter/include_healthy; topology click -> WorkspaceState.topology_scope/topology_tab_value/topology_tree_model/topology_canvas_layer/topology_scroll_focus/detail/status; hydrate -> filtered services list, topology panel, and shared detail card.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "services-signal-text", section: "signal_preview", slot: "body", position: 20})
    end
  end

  defmodule Examples.IncidentsWorkspacePanelElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :menus, AshUITutorials.TopologyAndNavigation.Examples.WorkspaceMenuElement do
        destination_attribute(:parent_id)
      end

      has_many :filter_groups,
               AshUITutorials.TopologyAndNavigation.Examples.IncidentsFiltersGroupElement do
        destination_attribute(:parent_id)
      end

      has_many :operator_form_panels,
               AshUITutorials.TopologyAndNavigation.Examples.OperatorFormsPanelElement do
        destination_attribute(:parent_id)
      end

      has_many :guarded_action_panels,
               AshUITutorials.TopologyAndNavigation.Examples.GuardedActionsPanelElement do
        destination_attribute(:parent_id)
      end

      has_many :incident_tables,
               AshUITutorials.TopologyAndNavigation.Examples.IncidentsTableElement do
        destination_attribute(:parent_id)
      end

      has_many :runbook_review_panels,
               AshUITutorials.TopologyAndNavigation.Examples.RunbookReviewPanelElement do
        destination_attribute(:parent_id)
      end

      has_many :topology_and_navigation_panels,
               AshUITutorials.TopologyAndNavigation.Examples.LiveDiagnosticsPanelElement do
        destination_attribute(:parent_id)
      end

      has_many :detail_cards, AshUITutorials.TopologyAndNavigation.Examples.SharedDetailCardElement do
        destination_attribute(:parent_id)
      end

      has_many :status_texts, AshUITutorials.TopologyAndNavigation.Examples.IncidentsStatusTextElement do
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

      relationship :guarded_action_panels do
        kind(:child)
        slot(:body)
        placement(:append)
        order(30)
      end

      relationship :incident_tables do
        kind(:child)
        slot(:body)
        placement(:append)
        order(40)
      end

      relationship :runbook_review_panels do
        kind(:child)
        slot(:body)
        placement(:append)
        order(50)
      end

      relationship :topology_and_navigation_panels do
        kind(:child)
        slot(:body)
        placement(:append)
        order(60)
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :severity_fields,
               AshUITutorials.TopologyAndNavigation.Examples.IncidentSeverityFieldElement do
        destination_attribute(:parent_id)
      end

      has_many :escalated_fields,
               AshUITutorials.TopologyAndNavigation.Examples.IncidentEscalatedFieldElement do
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :radios,
               AshUITutorials.TopologyAndNavigation.Examples.IncidentSeverityRadioElement do
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :switches,
               AshUITutorials.TopologyAndNavigation.Examples.IncidentEscalatedSwitchElement do
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :forms, AshUITutorials.TopologyAndNavigation.Examples.OperatorWorkflowFormElement do
        destination_attribute(:parent_id)
      end

      has_many :feedback_badges,
               AshUITutorials.TopologyAndNavigation.Examples.FormFeedbackBadgeElement do
        destination_attribute(:parent_id)
      end

      has_many :feedback_titles,
               AshUITutorials.TopologyAndNavigation.Examples.FormFeedbackTitleElement do
        destination_attribute(:parent_id)
      end

      has_many :feedback_summaries,
               AshUITutorials.TopologyAndNavigation.Examples.FormFeedbackSummaryElement do
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :note_groups,
               AshUITutorials.TopologyAndNavigation.Examples.NoteAndAssignmentGroupElement do
        destination_attribute(:parent_id)
      end

      has_many :maintenance_groups,
               AshUITutorials.TopologyAndNavigation.Examples.MaintenanceWindowGroupElement do
        destination_attribute(:parent_id)
      end

      has_many :acknowledge_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.AcknowledgeIncidentButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :assign_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.AssignIncidentButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :maintenance_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.ScheduleMaintenanceButtonElement do
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :note_fields,
               AshUITutorials.TopologyAndNavigation.Examples.OperatorNoteFieldElement do
        destination_attribute(:parent_id)
      end

      has_many :assignment_fields,
               AshUITutorials.TopologyAndNavigation.Examples.AssignmentTargetFieldElement do
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :inputs,
               AshUITutorials.TopologyAndNavigation.Examples.OperatorNoteInputElement do
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :pick_lists,
               AshUITutorials.TopologyAndNavigation.Examples.AssignmentTargetPickListElement do
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :duration_fields,
               AshUITutorials.TopologyAndNavigation.Examples.MaintenanceDurationFieldElement do
        destination_attribute(:parent_id)
      end

      has_many :date_fields,
               AshUITutorials.TopologyAndNavigation.Examples.MaintenanceDateFieldElement do
        destination_attribute(:parent_id)
      end

      has_many :time_fields,
               AshUITutorials.TopologyAndNavigation.Examples.MaintenanceTimeFieldElement do
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :inputs,
               AshUITutorials.TopologyAndNavigation.Examples.MaintenanceDurationInputElement do
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :inputs,
               AshUITutorials.TopologyAndNavigation.Examples.MaintenanceDateInputElement do
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :inputs,
               AshUITutorials.TopologyAndNavigation.Examples.MaintenanceTimeInputElement do
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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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

  defmodule Examples.GuardedActionsPanelElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :menus, AshUITutorials.TopologyAndNavigation.Examples.GuardedActionsMenuElement do
        destination_attribute(:parent_id)
      end

      has_many :overlays, AshUITutorials.TopologyAndNavigation.Examples.GuardOverlayElement do
        destination_attribute(:parent_id)
      end

      has_many :dialogs, AshUITutorials.TopologyAndNavigation.Examples.ResolveGuardDialogElement do
        destination_attribute(:parent_id)
      end

      has_many :alerts, AshUITutorials.TopologyAndNavigation.Examples.RestartGuardAlertElement do
        destination_attribute(:parent_id)
      end

      has_many :toasts, AshUITutorials.TopologyAndNavigation.Examples.GuardResultToastElement do
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

      relationship :overlays do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :dialogs do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end

      relationship :alerts do
        kind(:child)
        slot(:body)
        placement(:append)
        order(30)
      end

      relationship :toasts do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:card)

      props(%{
        title: "Guarded actions",
        class: "ashui-example-panel ashui-tutorial-workspace-panel"
      })

      metadata(%{id: "guarded-actions-panel", section: "demo", slot: "body", position: 30})
    end
  end

  defmodule Examples.GuardedActionsMenuElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :resolve_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.OpenResolveGuardButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :restart_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.OpenRestartGuardButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :silence_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.OpenSilenceGuardButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :discard_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.OpenDiscardNoteGuardButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :summary_texts,
               AshUITutorials.TopologyAndNavigation.Examples.GuardSummaryTextElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :resolve_buttons do
        kind(:child)
        slot(:menu)
        placement(:append)
        order(0)
      end

      relationship :restart_buttons do
        kind(:child)
        slot(:menu)
        placement(:append)
        order(10)
      end

      relationship :silence_buttons do
        kind(:child)
        slot(:menu)
        placement(:append)
        order(20)
      end

      relationship :discard_buttons do
        kind(:child)
        slot(:menu)
        placement(:append)
        order(30)
      end

      relationship :summary_texts do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:context_menu")

      props(%{
        title: "Operator guard rails",
        description: "Open the authored resolve, restart, silence, and discard-note confirmations from one persisted context surface.",
        open: true,
        class: "ashui-example-menu-surface"
      })

      metadata(%{id: "guarded-actions-menu", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.OpenResolveGuardButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Resolve incident", class: "ashui-example-primary-cta", variant: "secondary"})
      metadata(%{id: "open-resolve-guard", section: "demo", slot: "menu", position: 0})
    end

    ui_actions do
      action :open_resolve_guard do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "preview_guarded_action"})
        target("submit")
        transform(%{params: %{guard_intent: %{"from" => "static", "value" => "resolve"}}})
        metadata(%{intent: "preview_resolve_guard", success_message: "Resolve guard opened"})
      end
    end
  end

  defmodule Examples.OpenRestartGuardButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Restart API Gateway", class: "ashui-example-secondary-cta", variant: "secondary"})
      metadata(%{id: "open-restart-guard", section: "demo", slot: "menu", position: 10})
    end

    ui_actions do
      action :open_restart_guard do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "preview_guarded_action"})
        target("submit")
        transform(%{params: %{guard_intent: %{"from" => "static", "value" => "restart"}}})
        metadata(%{intent: "preview_restart_guard", success_message: "Restart guard opened"})
      end
    end
  end

  defmodule Examples.OpenSilenceGuardButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Silence escalated alerts", class: "ashui-example-secondary-cta", variant: "secondary"})
      metadata(%{id: "open-silence-guard", section: "demo", slot: "menu", position: 20})
    end

    ui_actions do
      action :open_silence_guard do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "preview_guarded_action"})
        target("submit")
        transform(%{params: %{guard_intent: %{"from" => "static", "value" => "silence"}}})
        metadata(%{intent: "preview_silence_guard", success_message: "Silence guard opened"})
      end
    end
  end

  defmodule Examples.OpenDiscardNoteGuardButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Discard operator note", class: "ashui-example-secondary-cta", variant: "secondary"})
      metadata(%{id: "open-discard-note-guard", section: "demo", slot: "menu", position: 30})
    end

    ui_actions do
      action :open_discard_note_guard do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "preview_guarded_action"})
        target("submit")
        transform(%{params: %{guard_intent: %{"from" => "static", "value" => "discard_note"}}})
        metadata(%{intent: "preview_discard_note_guard", success_message: "Discard-note guard opened"})
      end
    end
  end

  defmodule Examples.GuardSummaryTextElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-muted-copy"})
      metadata(%{id: "guard-summary-text", section: "demo", slot: "footer", position: 0})
    end

    ui_bindings do
      binding :guard_summary do
        source(%{resource: "WorkspaceState", field: :guard_summary, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "guard_summary"})
      end
    end
  end

  defmodule Examples.GuardOverlayElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :title_texts,
               AshUITutorials.TopologyAndNavigation.Examples.GuardOverlayTitleTextElement do
        destination_attribute(:parent_id)
      end

      has_many :summary_texts,
               AshUITutorials.TopologyAndNavigation.Examples.GuardOverlaySummaryTextElement do
        destination_attribute(:parent_id)
      end

      has_many :confirm_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.ConfirmOverlayGuardButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :cancel_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.CancelGuardSurfaceButtonElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :title_texts do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :summary_texts do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :confirm_buttons do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(0)
      end

      relationship :cancel_buttons do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:"custom:overlay")

      props(%{
        title: "Guarded operator action",
        description: "Review the persisted precondition summary before confirming the overlay action.",
        open: false,
        class: "ashui-example-panel"
      })

      metadata(%{id: "guard-overlay", section: "demo", slot: "body", position: 10})
    end

    ui_bindings do
      binding :overlay_open do
        source(%{resource: "WorkspaceState", field: :overlay_open, id: "tutorial-services-incidents-state"})
        target("open")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "guard_overlay"})
      end
    end
  end

  defmodule Examples.GuardOverlayTitleTextElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-detail-title"})
      metadata(%{id: "guard-overlay-title", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :guard_title do
        source(%{resource: "WorkspaceState", field: :guard_title, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "guard_overlay_title"})
      end
    end
  end

  defmodule Examples.GuardOverlaySummaryTextElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-muted-copy"})
      metadata(%{id: "guard-overlay-summary", section: "demo", slot: "body", position: 10})
    end

    ui_bindings do
      binding :guard_summary do
        source(%{resource: "WorkspaceState", field: :guard_summary, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "guard_overlay_summary"})
      end
    end
  end

  defmodule Examples.ConfirmOverlayGuardButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Confirm overlay action", class: "ashui-example-primary-cta", variant: "primary"})
      metadata(%{id: "confirm-overlay-guard", section: "demo", slot: "actions", position: 0})
    end

    ui_actions do
      action :confirm_overlay_guard do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "confirm_guarded_action"})
        target("submit")
        transform(%{params: %{}})
        metadata(%{intent: "confirm_overlay_guard", success_message: "Overlay guard confirmed"})
      end
    end
  end

  defmodule Examples.CancelGuardSurfaceButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Cancel", class: "ashui-example-secondary-cta", variant: "secondary"})
      metadata(%{id: "cancel-guard-surface", section: "demo", slot: "actions", position: 10})
    end

    ui_actions do
      action :cancel_guard_surface do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            overlay_open: %{"from" => "static", "value" => false},
            resolve_dialog_open: %{"from" => "static", "value" => false},
            restart_alert_open: %{"from" => "static", "value" => false},
            active_guard_action: %{"from" => "static", "value" => ""}
          }
        })

        metadata(%{intent: "cancel_guard_surface", success_message: "Guard surface closed"})
      end
    end
  end

  defmodule Examples.ResolveGuardDialogElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :summary_texts,
               AshUITutorials.TopologyAndNavigation.Examples.ResolveGuardSummaryTextElement do
        destination_attribute(:parent_id)
      end

      has_many :confirm_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.ConfirmResolveGuardButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :cancel_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.CancelGuardSurfaceButtonElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :summary_texts do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :confirm_buttons do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(0)
      end

      relationship :cancel_buttons do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:"custom:dialog")

      props(%{
        title: "Resolve incident",
        description: "Confirm the close-out path only after the acknowledgement workflow has been completed.",
        open: false,
        class: "ashui-example-panel"
      })

      metadata(%{id: "resolve-guard-dialog", section: "demo", slot: "body", position: 20})
    end

    ui_bindings do
      binding :resolve_dialog_open do
        source(%{resource: "WorkspaceState", field: :resolve_dialog_open, id: "tutorial-services-incidents-state"})
        target("open")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "resolve_guard_dialog"})
      end
    end
  end

  defmodule Examples.ResolveGuardSummaryTextElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-muted-copy"})
      metadata(%{id: "resolve-guard-summary", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :guard_summary do
        source(%{resource: "WorkspaceState", field: :guard_summary, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "resolve_guard_summary"})
      end
    end
  end

  defmodule Examples.ConfirmResolveGuardButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Resolve incident", class: "ashui-example-primary-cta", variant: "primary"})
      metadata(%{id: "confirm-resolve-guard", section: "demo", slot: "actions", position: 0})
    end

    ui_actions do
      action :confirm_resolve_guard do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "confirm_guarded_action"})
        target("submit")
        transform(%{params: %{}})
        metadata(%{intent: "confirm_resolve_guard", success_message: "Resolve guard confirmed"})
      end
    end
  end

  defmodule Examples.RestartGuardAlertElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :summary_texts,
               AshUITutorials.TopologyAndNavigation.Examples.RestartGuardSummaryTextElement do
        destination_attribute(:parent_id)
      end

      has_many :confirm_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.ConfirmRestartGuardButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :cancel_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.CancelGuardSurfaceButtonElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :summary_texts do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :confirm_buttons do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(0)
      end

      relationship :cancel_buttons do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:"custom:alert_dialog")

      props(%{
        title: "Restart API Gateway",
        description: "Confirm the restart only after the maintenance planner has produced a valid window.",
        open: false,
        class: "ashui-example-panel"
      })

      metadata(%{id: "restart-guard-alert", section: "demo", slot: "body", position: 30})
    end

    ui_bindings do
      binding :restart_alert_open do
        source(%{resource: "WorkspaceState", field: :restart_alert_open, id: "tutorial-services-incidents-state"})
        target("open")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "restart_guard_alert"})
      end
    end
  end

  defmodule Examples.RestartGuardSummaryTextElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-muted-copy"})
      metadata(%{id: "restart-guard-summary", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :guard_summary do
        source(%{resource: "WorkspaceState", field: :guard_summary, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "restart_guard_summary"})
      end
    end
  end

  defmodule Examples.ConfirmRestartGuardButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Restart service", class: "ashui-example-primary-cta", variant: "primary"})
      metadata(%{id: "confirm-restart-guard", section: "demo", slot: "actions", position: 0})
    end

    ui_actions do
      action :confirm_restart_guard do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "confirm_guarded_action"})
        target("submit")
        transform(%{params: %{}})
        metadata(%{intent: "confirm_restart_guard", success_message: "Restart guard confirmed"})
      end
    end
  end

  defmodule Examples.GuardResultToastElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :title_texts,
               AshUITutorials.TopologyAndNavigation.Examples.GuardToastTitleTextElement do
        destination_attribute(:parent_id)
      end

      has_many :summary_texts,
               AshUITutorials.TopologyAndNavigation.Examples.GuardToastSummaryTextElement do
        destination_attribute(:parent_id)
      end

      has_many :dismiss_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.DismissGuardToastButtonElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :title_texts do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :summary_texts do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end

      relationship :dismiss_buttons do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:"custom:toast")

      props(%{
        title: "Guard feedback",
        description: "The latest guarded workflow outcome remains visible until the operator dismisses it.",
        visible: false,
        class: "ashui-example-panel"
      })

      metadata(%{id: "guard-result-toast", section: "demo", slot: "footer", position: 0})
    end

    ui_bindings do
      binding :toast_visible do
        source(%{resource: "WorkspaceState", field: :toast_visible, id: "tutorial-services-incidents-state"})
        target("visible")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "guard_result_toast"})
      end
    end
  end

  defmodule Examples.GuardToastTitleTextElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-detail-title"})
      metadata(%{id: "guard-toast-title", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :toast_title do
        source(%{resource: "WorkspaceState", field: :toast_title, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "guard_toast_title"})
      end
    end
  end

  defmodule Examples.GuardToastSummaryTextElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-muted-copy"})
      metadata(%{id: "guard-toast-summary", section: "demo", slot: "footer", position: 0})
    end

    ui_bindings do
      binding :toast_summary do
        source(%{resource: "WorkspaceState", field: :toast_summary, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "guard_toast_summary"})
      end
    end
  end

  defmodule Examples.DismissGuardToastButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Dismiss toast", class: "ashui-example-secondary-cta", variant: "secondary"})
      metadata(%{id: "dismiss-guard-toast", section: "demo", slot: "actions", position: 0})
    end

    ui_actions do
      action :dismiss_guard_toast do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            toast_visible: %{"from" => "static", "value" => false},
            toast_title: %{"from" => "static", "value" => ""},
            toast_summary: %{"from" => "static", "value" => ""},
            toast_status: %{"from" => "static", "value" => "idle"}
          }
        })

        metadata(%{intent: "dismiss_guard_toast", success_message: "Toast dismissed"})
      end
    end
  end

  defmodule Examples.IncidentsTableElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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

  defmodule Examples.RunbookReviewPanelElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :split_panes,
               AshUITutorials.TopologyAndNavigation.Examples.RunbookSplitPaneElement do
        destination_attribute(:parent_id)
      end

      has_many :status_texts,
               AshUITutorials.TopologyAndNavigation.Examples.RunbookStatusTextElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :split_panes do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :status_texts do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:card)

      props(%{
        title: "Runbooks and attachments",
        class: "ashui-example-panel ashui-tutorial-workspace-panel"
      })

      metadata(%{id: "runbook-review-panel", section: "demo", slot: "body", position: 50})
    end
  end

  defmodule Examples.RunbookSplitPaneElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :focus_titles,
               AshUITutorials.TopologyAndNavigation.Examples.RunbookFocusTitleElement do
        destination_attribute(:parent_id)
      end

      has_many :markdown_viewers,
               AshUITutorials.TopologyAndNavigation.Examples.RunbookMarkdownViewerElement do
        destination_attribute(:parent_id)
      end

      has_many :evidence_cards,
               AshUITutorials.TopologyAndNavigation.Examples.AttachmentEvidenceCardElement do
        destination_attribute(:parent_id)
      end

      has_many :gateway_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.LoadGatewayRunbookButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :rollback_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.LoadRollbackRunbookButtonElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :focus_titles do
        kind(:child)
        slot(:primary)
        placement(:append)
        order(0)
      end

      relationship :markdown_viewers do
        kind(:child)
        slot(:primary)
        placement(:append)
        order(10)
      end

      relationship :evidence_cards do
        kind(:child)
        slot(:secondary)
        placement(:append)
        order(0)
      end

      relationship :gateway_buttons do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(0)
      end

      relationship :rollback_buttons do
        kind(:child)
        slot(:actions)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:"custom:split_pane")

      props(%{
        title: "Incident guide review",
        description: "Keep the active runbook copy beside the currently referenced attachment surfaces.",
        class: "ashui-example-split-pane-shell"
      })

      metadata(%{id: "runbook-split-pane", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.RunbookFocusTitleElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-detail-title"})
      metadata(%{id: "runbook-focus-title", section: "demo", slot: "primary", position: 0})
    end

    ui_bindings do
      binding :runbook_focus do
        source(%{resource: "WorkspaceState", field: :runbook_focus, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "runbook_focus"})
      end
    end
  end

  defmodule Examples.RunbookMarkdownViewerElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:"custom:markdown_viewer")

      props(%{
        title: "Active guide",
        description: "Authored markdown remains explicit while the tutorial stores the active guide inside shared runtime state.",
        class: "ashui-example-markdown-shell"
      })

      metadata(%{id: "runbook-markdown-viewer", section: "demo", slot: "primary", position: 10})
    end

    ui_bindings do
      binding :runbook_markdown do
        source(%{resource: "WorkspaceState", field: :runbook_markdown, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "runbook_markdown"})
      end
    end
  end

  defmodule Examples.LoadGatewayRunbookButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Gateway guide", class: "ashui-example-primary-cta", variant: "secondary"})
      metadata(%{id: "load-gateway-runbook", section: "demo", slot: "actions", position: 0})
    end

    ui_actions do
      action :load_gateway_runbook do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            selected_value: %{"from" => "static", "value" => "incidents"},
            runbook_focus: %{"from" => "static", "value" => "Gateway latency mitigation"},
            runbook_markdown: %{
              "from" => "static",
              "value" =>
                "# Gateway latency mitigation\n\n- Confirm the public edge error budget and current p95 latency.\n- Compare auth fan-out timings before restarting any lane.\n- Capture one evidence packet before changing the maintenance window.\n- Keep the rollback packet visible for incident commander review.\n"
            },
            runbook_status: %{"from" => "static", "value" => "Runbook panel mounted with the latency mitigation guide."},
            attachment_filename: %{"from" => "static", "value" => "gateway-latency-trace.png"},
            attachment_support_notice: %{
              "from" => "static",
              "value" =>
                "Attachment capture is intentionally narrow here: the file input only echoes the selected filename, and the markdown and link surfaces remain explicit custom shells."
            },
            detail_title: %{"from" => "static", "value" => "Gateway latency spike"},
            detail_summary: %{
              "from" => "static",
              "value" => "Runbook review is centered on ingress latency mitigation and the current evidence packet."
            },
            detail_status: %{"from" => "static", "value" => "sev-1"},
            status: %{
              "from" => "static",
              "value" => "Runbook review is focused on the gateway latency mitigation guide."
            }
          }
        })

        metadata(%{intent: "load_runbook", success_message: "Gateway runbook loaded"})
      end
    end
  end

  defmodule Examples.LoadRollbackRunbookButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Rollback packet", class: "ashui-example-secondary-cta", variant: "secondary"})
      metadata(%{id: "load-rollback-runbook", section: "demo", slot: "actions", position: 10})
    end

    ui_actions do
      action :load_rollback_runbook do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            selected_value: %{"from" => "static", "value" => "incidents"},
            runbook_focus: %{"from" => "static", "value" => "Rollback decision packet"},
            runbook_markdown: %{
              "from" => "static",
              "value" =>
                "# Rollback decision packet\n\n## Exit criteria\n\n- Confirm the canary error rate is stable for two consecutive checks.\n- Verify the maintenance window still covers traffic drain and restart time.\n- Attach the rollback packet name before notifying the search specialist.\n- Keep the deployment notes link available for external reviewers.\n"
            },
            runbook_status: %{"from" => "static", "value" => "Runbook panel switched to the rollback decision packet."},
            attachment_filename: %{"from" => "static", "value" => "rollback-decision-packet.md"},
            attachment_support_notice: %{
              "from" => "static",
              "value" =>
                "The tutorial still does not ship binary upload transport. This checkpoint keeps artifact review honest by persisting only filenames, markdown copy, and explicit external references."
            },
            detail_title: %{"from" => "static", "value" => "Rollback decision packet"},
            detail_summary: %{
              "from" => "static",
              "value" =>
                "Runbook review now emphasizes rollback readiness, maintenance coverage, and the current evidence filename."
            },
            detail_status: %{"from" => "static", "value" => "rollback-ready"},
            status: %{"from" => "static", "value" => "Runbook review switched to the rollback decision packet."}
          }
        })

        metadata(%{intent: "load_runbook", success_message: "Rollback packet loaded"})
      end
    end
  end

  defmodule Examples.AttachmentEvidenceCardElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :preview_texts,
               AshUITutorials.TopologyAndNavigation.Examples.AttachmentPreviewTextElement do
        destination_attribute(:parent_id)
      end

      has_many :file_fields,
               AshUITutorials.TopologyAndNavigation.Examples.AttachmentFileFieldElement do
        destination_attribute(:parent_id)
      end

      has_many :reference_links,
               AshUITutorials.TopologyAndNavigation.Examples.AttachmentReferenceLinkElement do
        destination_attribute(:parent_id)
      end

      has_many :images, AshUITutorials.TopologyAndNavigation.Examples.AttachmentImageElement do
        destination_attribute(:parent_id)
      end

      has_many :support_texts,
               AshUITutorials.TopologyAndNavigation.Examples.AttachmentSupportTextElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :preview_texts do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :file_fields do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :reference_links do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end

      relationship :images do
        kind(:child)
        slot(:body)
        placement(:append)
        order(30)
      end

      relationship :support_texts do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:card)

      props(%{
        title: "Artifacts and evidence",
        class: "ashui-example-layout-card"
      })

      metadata(%{id: "attachment-evidence-card", section: "demo", slot: "secondary", position: 0})
    end
  end

  defmodule Examples.AttachmentPreviewTextElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-detail-copy"})
      metadata(%{id: "attachment-preview-text", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :attachment_filename do
        source(%{resource: "WorkspaceState", field: :attachment_filename, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{"function" => "format", "args" => ["Current evidence packet: {value}"]})
        metadata(%{owner: "attachment_filename"})
      end
    end
  end

  defmodule Examples.AttachmentFileFieldElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :inputs,
               AshUITutorials.TopologyAndNavigation.Examples.AttachmentFileInputElement do
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
        label: "Evidence filename",
        name: "attachment_filename",
        help: "The tutorial records the selected filename only; no binary upload transport is implemented here.",
        class: "ashui-example-form-field"
      })

      metadata(%{id: "attachment-file-field", section: "demo", slot: "body", position: 10})
    end
  end

  defmodule Examples.AttachmentFileInputElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:input)

      props(%{
        name: "attachment_filename",
        type: "file",
        class: "ashui-example-input"
      })

      metadata(%{id: "attachment-file-input", section: "demo", slot: "body", position: 0})
    end

    ui_bindings do
      binding :attachment_filename do
        source(%{resource: "WorkspaceState", field: :attachment_filename, id: "tutorial-services-incidents-state"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "attachment_filename", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.AttachmentReferenceLinkElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:"custom:link")

      props(%{
        label: "Open deployment notes reference",
        target: "_blank",
        rel: "noreferrer",
        class: "ashui-example-link",
        href: "https://www.ash-hq.org/"
      })

      metadata(%{id: "attachment-reference-link", section: "demo", slot: "body", position: 20})
    end
  end

  defmodule Examples.AttachmentImageElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:image)

      props(%{
        alt: "Illustrative evidence packet preview",
        class: "ashui-example-image",
        src: "https://www.ash-hq.org/images/og-image.png"
      })

      metadata(%{id: "attachment-image", section: "demo", slot: "body", position: 30})
    end
  end

  defmodule Examples.AttachmentSupportTextElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-muted-copy"})
      metadata(%{id: "attachment-support-text", section: "demo", slot: "footer", position: 0})
    end

    ui_bindings do
      binding :attachment_support_notice do
        source(%{resource: "WorkspaceState", field: :attachment_support_notice, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "attachment_support_notice"})
      end
    end
  end

  defmodule Examples.RunbookStatusTextElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-muted-copy"})
      metadata(%{id: "runbook-status-text", section: "demo", slot: "footer", position: 0})
    end

    ui_bindings do
      binding :runbook_status do
        source(%{resource: "WorkspaceState", field: :runbook_status, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "runbook_status"})
      end
    end
  end

  defmodule Examples.LiveDiagnosticsPanelElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    relationships do
      has_many :gateway_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.LoadGatewayDiagnosticsButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :search_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.LoadSearchDiagnosticsButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :pressure_buttons,
               AshUITutorials.TopologyAndNavigation.Examples.LoadPressureDiagnosticsButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :status_surfaces,
               AshUITutorials.TopologyAndNavigation.Examples.DiagnosticsStatusElement do
        destination_attribute(:parent_id)
      end

      has_many :feedback_surfaces,
               AshUITutorials.TopologyAndNavigation.Examples.DiagnosticsInlineFeedbackElement do
        destination_attribute(:parent_id)
      end

      has_many :log_viewers,
               AshUITutorials.TopologyAndNavigation.Examples.DiagnosticsLogViewerElement do
        destination_attribute(:parent_id)
      end

      has_many :stream_widgets,
               AshUITutorials.TopologyAndNavigation.Examples.DiagnosticsStreamWidgetElement do
        destination_attribute(:parent_id)
      end

      has_many :process_monitors,
               AshUITutorials.TopologyAndNavigation.Examples.DiagnosticsProcessMonitorElement do
        destination_attribute(:parent_id)
      end

      has_many :status_texts,
               AshUITutorials.TopologyAndNavigation.Examples.DiagnosticsStatusTextElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :gateway_buttons do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :search_buttons do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :pressure_buttons do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end

      relationship :status_surfaces do
        kind(:child)
        slot(:body)
        placement(:append)
        order(30)
      end

      relationship :feedback_surfaces do
        kind(:child)
        slot(:body)
        placement(:append)
        order(40)
      end

      relationship :log_viewers do
        kind(:child)
        slot(:body)
        placement(:append)
        order(50)
      end

      relationship :stream_widgets do
        kind(:child)
        slot(:body)
        placement(:append)
        order(60)
      end

      relationship :process_monitors do
        kind(:child)
        slot(:body)
        placement(:append)
        order(70)
      end

      relationship :status_texts do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:card)

      props(%{
        title: "Live diagnostics",
        class: "ashui-example-panel ashui-tutorial-workspace-panel"
      })

      metadata(%{id: "topology-navigation-panel", section: "demo", slot: "body", position: 60})
    end
  end

  defmodule Examples.LoadGatewayDiagnosticsButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Gateway live tail", class: "ashui-example-primary-cta", variant: "secondary"})
      metadata(%{id: "load-gateway-diagnostics", section: "demo", slot: "body", position: 0})
    end

    ui_actions do
      action :load_gateway_diagnostics do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            selected_value: %{"from" => "static", "value" => "incidents"},
            diagnostics_mode: %{"from" => "static", "value" => "gateway live tail"},
            diagnostics_status_model: %{
              "from" => "static",
              "value" => %{
                "label" => "Simulated live tail",
                "detail" => "Gateway diagnostics are refreshed from seeded snapshots inside the tutorial host.",
                "tone" => "warning"
              }
            },
            diagnostics_feedback_model: %{
              "from" => "static",
              "value" => %{
                "title" => "Transport note",
                "detail" => "The log, stream, and process surfaces stay explicit about using seeded snapshots instead of a hidden subscription transport.",
                "tone" => "warning"
              }
            },
            diagnostics_log_entries: %{
              "from" => "static",
              "value" => [
                %{"level" => "WARN", "message" => "gateway retry budget crossed the operator threshold", "timestamp" => "13:41:12"},
                %{"level" => "INFO", "message" => "rollback packet was linked into the incident workspace", "timestamp" => "13:41:20"},
                %{"level" => "INFO", "message" => "latency mitigation guide reloaded from persisted state", "timestamp" => "13:41:32"}
              ]
            },
            diagnostics_stream_entries: %{
              "from" => "static",
              "value" => [
                %{"label" => "gateway", "message" => "ingress queue hydration completed", "timestamp" => "13:41:08"},
                %{"label" => "gateway", "message" => "operator handoff packet published", "timestamp" => "13:41:22"},
                %{"label" => "gateway", "message" => "mitigation checklist advanced to rollback review", "timestamp" => "13:41:35"}
              ]
            },
            diagnostics_process_model: %{
              "from" => "static",
              "value" => %{
                "processes" => [
                  %{"name" => "gateway_scheduler", "state" => "running", "meta" => "0 restarts"},
                  %{"name" => "retry_worker", "state" => "running", "meta" => "1 restart"},
                  %{"name" => "binding_refresh", "state" => "idle", "meta" => "0 restarts"}
                ],
                "summary" => "Gateway processes are steady, but the diagnostics lane remains an honest seeded snapshot."
              }
            },
            diagnostics_status_copy: %{
              "from" => "static",
              "value" => "Gateway diagnostics are live-shaped but still seeded snapshots; no websocket feed is implied by this checkpoint."
            },
            detail_title: %{"from" => "static", "value" => "Gateway topology and navigation"},
            detail_summary: %{
              "from" => "static",
              "value" => "Diagnostics review is centered on the gateway tail, live-shaped transport copy, and the current process snapshot."
            },
            detail_status: %{"from" => "static", "value" => "diagnostics"},
            status: %{"from" => "static", "value" => "Gateway diagnostics scenario loaded into the incidents workspace."}
          }
        })

        metadata(%{intent: "load_diagnostics", success_message: "Gateway diagnostics loaded"})
      end
    end
  end

  defmodule Examples.LoadSearchDiagnosticsButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Search stale snapshot", class: "ashui-example-secondary-cta", variant: "secondary"})
      metadata(%{id: "load-search-diagnostics", section: "demo", slot: "body", position: 10})
    end

    ui_actions do
      action :load_search_diagnostics do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            selected_value: %{"from" => "static", "value" => "incidents"},
            diagnostics_mode: %{"from" => "static", "value" => "search lag snapshot"},
            diagnostics_status_model: %{
              "from" => "static",
              "value" => %{
                "label" => "Snapshot stale",
                "detail" => "The search-lag review surface is intentionally a captured snapshot from four minutes ago.",
                "tone" => "warning"
              }
            },
            diagnostics_feedback_model: %{
              "from" => "static",
              "value" => %{
                "title" => "Stale review window",
                "detail" => "This scenario demonstrates stale-data handling explicitly so the tutorial does not overclaim a fresh runtime transport.",
                "tone" => "warning"
              }
            },
            diagnostics_log_entries: %{
              "from" => "static",
              "value" => [
                %{"level" => "INFO", "message" => "replica lag snapshot captured for operator review", "timestamp" => "13:32:04"},
                %{"level" => "WARN", "message" => "backlog depth remains above the watch threshold", "timestamp" => "13:32:18"},
                %{"level" => "INFO", "message" => "promotion readiness packet archived", "timestamp" => "13:32:29"}
              ]
            },
            diagnostics_stream_entries: %{
              "from" => "static",
              "value" => [
                %{"label" => "search", "message" => "replica backlog snapshot stored", "timestamp" => "13:31:58"},
                %{"label" => "search", "message" => "lag review note attached to the incident", "timestamp" => "13:32:16"},
                %{"label" => "search", "message" => "fresh transport intentionally unavailable in this tutorial lane", "timestamp" => "13:32:24"}
              ]
            },
            diagnostics_process_model: %{
              "from" => "static",
              "value" => %{
                "processes" => [
                  %{"name" => "replica_reader", "state" => "degraded", "meta" => "2 restarts"},
                  %{"name" => "index_queue", "state" => "running", "meta" => "0 restarts"},
                  %{"name" => "promotion_guard", "state" => "idle", "meta" => "0 restarts"}
                ],
                "summary" => "Search replication is under review, and the surface calls out that its data is intentionally stale."
              }
            },
            diagnostics_status_copy: %{
              "from" => "static",
              "value" => "Search diagnostics are snapshot-only in this tutorial step; the stale notice is part of the contract, not a temporary omission."
            },
            detail_title: %{"from" => "static", "value" => "Search lag diagnostics"},
            detail_summary: %{
              "from" => "static",
              "value" => "Diagnostics review is centered on one stale search snapshot so the support limits remain explicit."
            },
            detail_status: %{"from" => "static", "value" => "stale"},
            status: %{"from" => "static", "value" => "Search stale-snapshot diagnostics loaded into the incidents workspace."}
          }
        })

        metadata(%{intent: "load_diagnostics", success_message: "Search diagnostics loaded"})
      end
    end
  end

  defmodule Examples.LoadPressureDiagnosticsButtonElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Retry pressure", class: "ashui-example-secondary-cta", variant: "secondary"})
      metadata(%{id: "load-pressure-diagnostics", section: "demo", slot: "body", position: 20})
    end

    ui_actions do
      action :load_pressure_diagnostics do
        signal(:click)
        source(%{id: "tutorial-services-incidents-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            selected_value: %{"from" => "static", "value" => "incidents"},
            diagnostics_mode: %{"from" => "static", "value" => "retry pressure snapshot"},
            diagnostics_status_model: %{
              "from" => "static",
              "value" => %{
                "label" => "Pressure",
                "detail" => "Worker restart pressure is rising and operator intervention is recommended.",
                "tone" => "danger"
              }
            },
            diagnostics_feedback_model: %{
              "from" => "static",
              "value" => %{
                "title" => "Action recommended",
                "detail" => "The process monitor and log viewer agree on restart pressure, but the surface still remains a seeded runtime model for tutorial clarity.",
                "tone" => "danger"
              }
            },
            diagnostics_log_entries: %{
              "from" => "static",
              "value" => [
                %{"level" => "ERROR", "message" => "retry worker exceeded the restart threshold for the last five minutes", "timestamp" => "13:48:03"},
                %{"level" => "WARN", "message" => "maintenance guard still open while restart pressure climbs", "timestamp" => "13:48:19"},
                %{"level" => "INFO", "message" => "operator escalation note synced into the incident review lane", "timestamp" => "13:48:31"}
              ]
            },
            diagnostics_stream_entries: %{
              "from" => "static",
              "value" => [
                %{"label" => "runtime", "message" => "queue worker restart count crossed 4", "timestamp" => "13:47:58"},
                %{"label" => "runtime", "message" => "escalation path promoted to incident commander review", "timestamp" => "13:48:12"},
                %{"label" => "runtime", "message" => "process pressure snapshot published", "timestamp" => "13:48:28"}
              ]
            },
            diagnostics_process_model: %{
              "from" => "static",
              "value" => %{
                "processes" => [
                  %{"name" => "gateway_scheduler", "state" => "running", "meta" => "0 restarts"},
                  %{"name" => "retry_worker", "state" => "degraded", "meta" => "4 restarts"},
                  %{"name" => "binding_refresh", "state" => "running", "meta" => "2 restarts"}
                ],
                "summary" => "The retry worker is degraded, and the tutorial surfaces that pressure without pretending to be a direct supervisor tap."
              }
            },
            diagnostics_status_copy: %{
              "from" => "static",
              "value" => "Retry-pressure diagnostics are representative runtime snapshots; they are coordinated across the status, feedback, log, stream, and process surfaces."
            },
            detail_title: %{"from" => "static", "value" => "Retry pressure diagnostics"},
            detail_summary: %{
              "from" => "static",
              "value" => "Diagnostics review is centered on restart pressure, coordinated surface warnings, and the seeded process monitor model."
            },
            detail_status: %{"from" => "static", "value" => "pressure"},
            status: %{"from" => "static", "value" => "Retry-pressure diagnostics loaded into the incidents workspace."}
          }
        })

        metadata(%{intent: "load_diagnostics", success_message: "Pressure diagnostics loaded"})
      end
    end
  end

  defmodule Examples.DiagnosticsStatusElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:"custom:status")

      props(%{
        title: "Diagnostic readiness",
        description: "Make freshness and risk visible before operators trust the live-looking surfaces below.",
        class: "ashui-example-status-shell"
      })

      metadata(%{id: "diagnostics-status", section: "demo", slot: "body", position: 30})
    end

    ui_bindings do
      binding :diagnostics_status_model do
        source(%{resource: "WorkspaceState", field: :diagnostics_status_model, id: "tutorial-services-incidents-state"})
        target("model")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "diagnostics_status"})
      end
    end
  end

  defmodule Examples.DiagnosticsInlineFeedbackElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:"custom:inline_feedback")

      props(%{
        title: "Diagnostic support note",
        description: "Explain whether this diagnostic view is fresh, stale, or intentionally simulated.",
        class: "ashui-example-inline-feedback-shell"
      })

      metadata(%{id: "diagnostics-inline-feedback", section: "demo", slot: "body", position: 40})
    end

    ui_bindings do
      binding :diagnostics_feedback_model do
        source(%{resource: "WorkspaceState", field: :diagnostics_feedback_model, id: "tutorial-services-incidents-state"})
        target("model")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "diagnostics_feedback"})
      end
    end
  end

  defmodule Examples.DiagnosticsLogViewerElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:"custom:log_viewer")

      props(%{
        title: "Diagnostic log tail",
        description: "Representative runtime rows for the active diagnostics scenario.",
        class: "ashui-example-log-shell"
      })

      metadata(%{id: "diagnostics-log-viewer", section: "demo", slot: "body", position: 50})
    end

    ui_bindings do
      binding :diagnostics_log_entries do
        source(%{resource: "WorkspaceState", field: :diagnostics_log_entries, id: "tutorial-services-incidents-state"})
        target("entries")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "diagnostics_log_entries"})
      end
    end
  end

  defmodule Examples.DiagnosticsStreamWidgetElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:"custom:stream_widget")

      props(%{
        title: "Activity stream",
        description: "Seeded feed entries aligned with the currently selected diagnostics story.",
        class: "ashui-example-stream-widget-shell"
      })

      metadata(%{id: "diagnostics-stream-widget", section: "demo", slot: "body", position: 60})
    end

    ui_bindings do
      binding :diagnostics_stream_entries do
        source(%{resource: "WorkspaceState", field: :diagnostics_stream_entries, id: "tutorial-services-incidents-state"})
        target("entries")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "diagnostics_stream_entries"})
      end
    end
  end

  defmodule Examples.DiagnosticsProcessMonitorElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:"custom:process_monitor")

      props(%{
        title: "Process monitor",
        description: "Representative runtime process state for the active diagnostics scenario.",
        class: "ashui-example-process-monitor-shell"
      })

      metadata(%{id: "diagnostics-process-monitor", section: "demo", slot: "body", position: 70})
    end

    ui_bindings do
      binding :diagnostics_process_model do
        source(%{resource: "WorkspaceState", field: :diagnostics_process_model, id: "tutorial-services-incidents-state"})
        target("model")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "diagnostics_process_model"})
      end
    end
  end

  defmodule Examples.DiagnosticsStatusTextElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-muted-copy"})
      metadata(%{id: "diagnostics-status-text", section: "demo", slot: "footer", position: 0})
    end

    ui_bindings do
      binding :diagnostics_status_copy do
        source(%{resource: "WorkspaceState", field: :diagnostics_status_copy, id: "tutorial-services-incidents-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "diagnostics_status_copy"})
      end
    end
  end

  defmodule Examples.IncidentsStatusTextElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

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
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: narrow the incident table, then acknowledge, assign, or schedule maintenance before resolving, restarting, silencing, or discarding through authored guard surfaces while the same shared state record also drives runbook markdown, evidence filenames, explicit attachment references, and live-shaped diagnostics with honest freshness notices.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "incidents-story-text", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.IncidentsSignalTextElement do
    use AshUITutorials.TopologyAndNavigation.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: filter change -> WorkspaceState.incident_severity_filter/incident_escalated_only -> hydrated incidents table; file-input change -> WorkspaceState.attachment_filename -> filename echo; form action click -> WorkspaceState.submit_operator_workflow(...) -> incident catalog, disabled flags, and feedback copy; guard click -> WorkspaceState.preview_guarded_action(...) / confirm_guarded_action() -> overlay visibility, toast state, shared detail, and runbook context; diagnostics click -> WorkspaceState.update(...) -> status, inline feedback, log rows, stream entries, and process snapshot.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "incidents-signal-text", section: "signal_preview", slot: "body", position: 20})
    end
  end

  defmodule Examples.ServicesScreen do
    use Ash.Resource,
      domain: AshUITutorials.TopologyAndNavigation.AuthoringDomain,
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
      has_many :panels, AshUITutorials.TopologyAndNavigation.Examples.ServicesWorkspacePanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUITutorials.TopologyAndNavigation.Examples.ServicesStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUITutorials.TopologyAndNavigation.Examples.ServicesSignalTextElement do
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
        tutorial_directory: "08-topology-and-navigation",
        shell_id: "topology-navigation-services-shell"
      })
    end
  end

  defmodule Examples.IncidentsScreen do
    use Ash.Resource,
      domain: AshUITutorials.TopologyAndNavigation.AuthoringDomain,
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
      has_many :panels, AshUITutorials.TopologyAndNavigation.Examples.IncidentsWorkspacePanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUITutorials.TopologyAndNavigation.Examples.IncidentsStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUITutorials.TopologyAndNavigation.Examples.IncidentsSignalTextElement do
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
        tutorial_directory: "08-topology-and-navigation",
        shell_id: "topology-navigation-incidents-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUITutorials.TopologyAndNavigation.seed!(opts)
    def reset!, do: AshUITutorials.TopologyAndNavigation.reset!()
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

    scope "/", AshUITutorials.TopologyAndNavigation.Web do
      pipe_through(:browser)
      live("/", ServicesLive)
      live("/incidents", IncidentsLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_tutorial_topology_and_navigation

    @session_options [
      store: :cookie,
      key: "_ash_ui_tutorial_topology_and_navigation_key",
      signing_salt: "ashuitut23b"
    ]

    socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

    plug(Plug.RequestId)
    plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])
    plug(Plug.Session, @session_options)
    plug(AshUITutorials.TopologyAndNavigation.Web.Router)
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

    alias AshUITutorials.TopologyAndNavigation.Web.Components.TutorialShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      AshUITutorials.TopologyAndNavigation.seed!()
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
        |> Phoenix.Component.assign(:current_user, AshUITutorials.TopologyAndNavigation.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUITutorials.TopologyAndNavigation.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUITutorials.TopologyAndNavigation.runtime_domains())
        |> Phoenix.Component.assign(:page_title, AshUITutorials.TopologyAndNavigation.title())
        |> Phoenix.Component.assign(:theme_css, AshUITutorials.TopologyAndNavigation.theme_css())
        |> Phoenix.Component.assign(:example_runtime, example_runtime)
        |> Phoenix.Component.assign(:supported_runtimes, AshUITutorials.TopologyAndNavigation.supported_runtimes())
        |> Phoenix.Component.assign(:active_page, Atom.to_string(screen_kind))

      with {:ok, socket} <- Integration.mount_ui_screen(socket, AshUITutorials.TopologyAndNavigation.screen_name(screen_kind), params),
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
        |> Phoenix.Component.assign_new(:supported_runtimes, fn -> AshUITutorials.TopologyAndNavigation.supported_runtimes() end)
        |> Phoenix.Component.assign_new(:example_runtime, fn -> AshUITutorials.TopologyAndNavigation.default_runtime() end)
        |> Phoenix.Component.assign_new(:rendered_runtime, fn ->
          %{
            content: assigns[:rendered_ui] || "",
            description: AshUITutorials.TopologyAndNavigation.runtime_description(AshUITutorials.TopologyAndNavigation.default_runtime()),
            mode: :live_fragment,
            runtime: AshUITutorials.TopologyAndNavigation.default_runtime()
          }
        end)

      ~H"""
      <TutorialShell.tutorial_shell title={@page_title} summary={AshUITutorials.TopologyAndNavigation.summary()} theme_css={@theme_css} active_page={@active_page}>
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
              <iframe class="ashui-tutorial-runtime-frame" sandbox="allow-same-origin" srcdoc={@rendered_runtime.content} title={"topology-navigation-#{@rendered_runtime.runtime}"} />
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
        AshUITutorials.TopologyAndNavigation.rendered_runtime(
          socket.assigns,
          socket.assigns[:example_runtime] || AshUITutorials.TopologyAndNavigation.default_runtime()
        )

      socket
      |> Phoenix.Component.assign(:rendered_runtime, rendered_runtime)
      |> Phoenix.Component.assign(:rendered_ui, rendered_runtime.content)
    end

    defp runtime_from_params(params) do
      params["runtime"]
      |> fallback_runtime()
      |> AshUITutorials.TopologyAndNavigation.normalize_runtime!()
    end

    defp fallback_runtime(nil), do: System.get_env("ASH_UI_EXAMPLE_RUNTIME")
    defp fallback_runtime(runtime), do: runtime
  end

  defmodule Web.IncidentsLive do
    use Phoenix.LiveView

    alias AshUITutorials.TopologyAndNavigation.Web.Components.TutorialShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      AshUITutorials.TopologyAndNavigation.seed!()
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
        |> Phoenix.Component.assign(:current_user, AshUITutorials.TopologyAndNavigation.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUITutorials.TopologyAndNavigation.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUITutorials.TopologyAndNavigation.runtime_domains())
        |> Phoenix.Component.assign(:page_title, AshUITutorials.TopologyAndNavigation.title())
        |> Phoenix.Component.assign(:theme_css, AshUITutorials.TopologyAndNavigation.theme_css())
        |> Phoenix.Component.assign(:example_runtime, example_runtime)
        |> Phoenix.Component.assign(:supported_runtimes, AshUITutorials.TopologyAndNavigation.supported_runtimes())
        |> Phoenix.Component.assign(:active_page, Atom.to_string(screen_kind))

      with {:ok, socket} <- Integration.mount_ui_screen(socket, AshUITutorials.TopologyAndNavigation.screen_name(screen_kind), params),
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
        |> Phoenix.Component.assign_new(:supported_runtimes, fn -> AshUITutorials.TopologyAndNavigation.supported_runtimes() end)
        |> Phoenix.Component.assign_new(:example_runtime, fn -> AshUITutorials.TopologyAndNavigation.default_runtime() end)
        |> Phoenix.Component.assign_new(:rendered_runtime, fn ->
          %{
            content: assigns[:rendered_ui] || "",
            description: AshUITutorials.TopologyAndNavigation.runtime_description(AshUITutorials.TopologyAndNavigation.default_runtime()),
            mode: :live_fragment,
            runtime: AshUITutorials.TopologyAndNavigation.default_runtime()
          }
        end)

      ~H"""
      <TutorialShell.tutorial_shell title={@page_title} summary={AshUITutorials.TopologyAndNavigation.summary()} theme_css={@theme_css} active_page={@active_page}>
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
              <iframe class="ashui-tutorial-runtime-frame" sandbox="allow-same-origin" srcdoc={@rendered_runtime.content} title={"topology-navigation-#{@rendered_runtime.runtime}"} />
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
        AshUITutorials.TopologyAndNavigation.rendered_runtime(
          socket.assigns,
          socket.assigns[:example_runtime] || AshUITutorials.TopologyAndNavigation.default_runtime()
        )

      socket
      |> Phoenix.Component.assign(:rendered_runtime, rendered_runtime)
      |> Phoenix.Component.assign(:rendered_ui, rendered_runtime.content)
    end

    defp runtime_from_params(params) do
      params["runtime"]
      |> fallback_runtime()
      |> AshUITutorials.TopologyAndNavigation.normalize_runtime!()
    end

    defp fallback_runtime(nil), do: System.get_env("ASH_UI_EXAMPLE_RUNTIME")
    defp fallback_runtime(runtime), do: runtime
  end
end
