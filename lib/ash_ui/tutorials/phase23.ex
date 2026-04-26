defmodule AshUI.Tutorials.Phase23 do
  @moduledoc """
  Shared baseline data for the Phase 23 Operations Control Center tutorial.

  The tutorial checkpoints depend on one believable domain, one shared visual
  contract, and one stable seeded dataset so later chapters can add behavior
  without rewriting the story every time.
  """

  alias AshUI.Tutorials

  @domain_resources [
    %{
      name: "Service",
      purpose: "Represents one operator-facing system or dependency.",
      relationships: ["belongs_to cluster", "has_many incidents", "has_many deployments"]
    },
    %{
      name: "Incident",
      purpose: "Represents an active or recent operational issue tied to a service.",
      relationships: ["belongs_to service", "belongs_to operator", "has_many runbooks"]
    },
    %{
      name: "Cluster",
      purpose: "Represents an infrastructure boundary that groups services and deployments.",
      relationships: ["has_many services", "has_many deployments"]
    },
    %{
      name: "Deployment",
      purpose: "Represents a service rollout or maintenance event visible to operators.",
      relationships: ["belongs_to service", "belongs_to cluster"]
    },
    %{
      name: "Runbook",
      purpose: "Represents operator guidance attached to one service or incident.",
      relationships: ["belongs_to service", "belongs_to incident"]
    },
    %{
      name: "Operator",
      purpose: "Represents the current actor and ownership context for changes.",
      relationships: ["has_many incidents", "has_many deployments"]
    }
  ]

  @actor_profiles [
    %{
      id: "admin-jules",
      name: "Jules Admin",
      role: :admin,
      active: true,
      summary: "Full platform access, including policy overrides and destructive flows."
    },
    %{
      id: "on-call-maya",
      name: "Maya On-Call",
      role: :on_call_operator,
      active: true,
      summary: "Primary operator for incident triage, assignments, and maintenance actions."
    },
    %{
      id: "viewer-ren",
      name: "Ren Viewer",
      role: :viewer,
      active: true,
      summary: "Read-only observer who can review dashboards but cannot mutate incident state."
    }
  ]

  @seed_fixtures %{
    services: [
      %{
        id: "svc-api-gateway",
        name: "API Gateway",
        status: "degraded",
        tier: "tier-1",
        cluster_id: "cluster-core-east",
        summary: "Ingress service handling public traffic and auth fan-out."
      },
      %{
        id: "svc-billing",
        name: "Billing",
        status: "healthy",
        tier: "tier-1",
        cluster_id: "cluster-core-east",
        summary: "Invoice, subscription, and retry orchestration."
      },
      %{
        id: "svc-search",
        name: "Search",
        status: "monitoring",
        tier: "tier-2",
        cluster_id: "cluster-edge-west",
        summary: "Query and indexing service with read-heavy traffic."
      }
    ],
    incidents: [
      %{
        id: "inc-1042",
        title: "Gateway latency spike",
        severity: "sev-1",
        service_id: "svc-api-gateway",
        state: "investigating",
        owner_id: "on-call-maya",
        summary: "Tail latency exceeded SLA for external requests in the last 12 minutes."
      },
      %{
        id: "inc-1045",
        title: "Search replica lag",
        severity: "sev-2",
        service_id: "svc-search",
        state: "watching",
        owner_id: "viewer-ren",
        summary: "Replica lag is elevated but recovery is trending in the right direction."
      }
    ],
    clusters: [
      %{
        id: "cluster-core-east",
        name: "Core East",
        status: "elevated",
        summary: "Primary write cluster for core services."
      },
      %{
        id: "cluster-edge-west",
        name: "Edge West",
        status: "steady",
        summary: "Regional edge cluster handling search and cache traffic."
      }
    ],
    deployments: [
      %{
        id: "dep-8821",
        service_id: "svc-api-gateway",
        version: "2026.04.23.2",
        state: "paused",
        summary: "Paused after latency regression was detected."
      },
      %{
        id: "dep-8824",
        service_id: "svc-billing",
        version: "2026.04.24.1",
        state: "completed",
        summary: "Completed successfully with retry tuning updates."
      }
    ],
    runbooks: [
      %{
        id: "runbook-gateway-latency",
        service_id: "svc-api-gateway",
        title: "Gateway latency mitigation",
        summary: "Triage flow for rising ingress latency and auth dependency pressure."
      },
      %{
        id: "runbook-search-lag",
        service_id: "svc-search",
        title: "Search lag response",
        summary: "Review queue depth, replication health, and replica promotion readiness."
      }
    ],
    metrics: [
      %{
        service_id: "svc-api-gateway",
        key: "p95_latency_ms",
        value: 382,
        trend: "rising"
      },
      %{
        service_id: "svc-billing",
        key: "job_retry_rate",
        value: 0.04,
        trend: "steady"
      },
      %{
        service_id: "svc-search",
        key: "replica_lag_seconds",
        value: 14,
        trend: "recovering"
      }
    ],
    logs: [
      %{
        service_id: "svc-api-gateway",
        level: "warn",
        message: "edge timeout budget reached for auth fan-out",
        occurred_at: "2026-04-26T12:18:00Z"
      },
      %{
        service_id: "svc-search",
        level: "info",
        message: "replica catch-up job completed one backlog shard",
        occurred_at: "2026-04-26T12:19:30Z"
      }
    ],
    topology: [
      %{
        id: "top-api-gateway",
        parent_id: nil,
        title: "API Gateway",
        detail: "Routes public traffic into auth and service edges."
      },
      %{
        id: "top-billing",
        parent_id: "top-api-gateway",
        title: "Billing",
        detail: "Downstream retry and invoice processing."
      },
      %{
        id: "top-search",
        parent_id: "top-api-gateway",
        title: "Search",
        detail: "Read-heavy dependency for user-facing discovery."
      }
    ]
  }

  @theme_contract %{
    source_doc: "examples/ash_hq_theme_baseline.md",
    source_css: "examples/ash_hq_theme_tokens.css",
    local_copy_rule:
      "Tutorial checkpoint apps vendor their own CSS locally but stay aligned with the Ash HQ palette, grid backdrop, glass panel, and pill CTA baseline.",
    required_tokens: [
      "--ashui-example-bg-base",
      "--ashui-example-accent",
      "--ashui-example-primary-gradient"
    ],
    required_shell_classes: [
      ".ashui-example-shell",
      ".ashui-example-panel",
      ".ashui-example-primary-cta"
    ]
  }

  @required_baseline_markers [
    "## Domain Resources",
    "## Actor Profiles",
    "## Shared Theme Contract",
    "## Seed Fixtures",
    "`Service`",
    "`Incident`",
    "`Cluster`",
    "`Deployment`",
    "`Runbook`",
    "`Operator`",
    "`admin`",
    "`on_call_operator`",
    "`viewer`",
    "examples/ash_hq_theme_baseline.md",
    "examples/ash_hq_theme_tokens.css"
  ]
  @implemented_checkpoint_numbers [1, 2]
  @required_project_files [
    "README.md",
    "mix.exs",
    "mix.lock",
    "config/config.exs",
    "config/dev.exs",
    "assets/css/app.css"
  ]
  @chapter_source_paths %{
    1 => "tutorials/code/01-project-shell/lib/ash_ui_tutorials/project_shell.ex",
    2 => "tutorials/code/02-services-and-incidents/lib/ash_ui_tutorials/services_and_incidents.ex"
  }
  @chapter_modules %{
    1 => AshUITutorials.ProjectShell,
    2 => AshUITutorials.ServicesAndIncidents
  }
  @chapter_mix_project_modules %{
    1 => AshUITutorials.ProjectShell.MixProject,
    2 => AshUITutorials.ServicesAndIncidents.MixProject
  }
  @chapter_artifact_markers %{
    1 => [
      "../code/01-project-shell/lib/ash_ui_tutorials/project_shell.ex",
      "AshUITutorials.ProjectShell.Runtime.WorkspaceState",
      "AshUITutorials.ProjectShell.UiScreen",
      "AshUITutorials.ProjectShell.UiElement",
      "AshUITutorials.ProjectShell.UiBinding",
      "AshUITutorials.ProjectShell.Examples.HomeScreen",
      "AshUITutorials.ProjectShell.Web.HomeLive"
    ],
    2 => [
      "../code/02-services-and-incidents/lib/ash_ui_tutorials/services_and_incidents.ex",
      "AshUITutorials.ServicesAndIncidents.Runtime.WorkspaceState",
      "AshUITutorials.ServicesAndIncidents.UiScreen",
      "AshUITutorials.ServicesAndIncidents.UiElement",
      "AshUITutorials.ServicesAndIncidents.UiBinding",
      "AshUITutorials.ServicesAndIncidents.Examples.ServicesScreen",
      "AshUITutorials.ServicesAndIncidents.Examples.IncidentsScreen",
      "AshUITutorials.ServicesAndIncidents.Web.ServicesLive",
      "AshUITutorials.ServicesAndIncidents.Web.IncidentsLive"
    ]
  }
  @authoritative_source_markers [
    "Authority.create(",
    "use AshUI.Resource.DSL.Screen",
    "use AshUI.Resource.DSL.Element"
  ]
  @forbidden_source_markers [
    "AshUI.DSL.Builder",
    "screen-document",
    "screen document",
    "builder-first"
  ]
  @final_app_source_path "tutorials/operations_control_center/lib/ash_ui_tutorials/operations_control_center.ex"
  @final_app_module AshUITutorials.OperationsControlCenter
  @final_mix_project_module AshUITutorials.OperationsControlCenter.MixProject

  @doc """
  Returns the shared Phase 23 domain-resource baseline.
  """
  @spec domain_resources() :: [map()]
  def domain_resources, do: @domain_resources

  @doc """
  Returns the shared actor profiles used throughout the tutorial.
  """
  @spec actor_profiles() :: [map()]
  def actor_profiles, do: @actor_profiles

  @doc """
  Returns the shared seed fixtures used by the tutorial checkpoints.
  """
  @spec seed_fixtures() :: map()
  def seed_fixtures, do: @seed_fixtures

  @doc """
  Returns the shared tutorial theme contract derived from the Ash HQ baseline.
  """
  @spec theme_contract() :: map()
  def theme_contract, do: @theme_contract

  @doc """
  Returns the implemented checkpoint numbers for Phase 23.
  """
  @spec implemented_checkpoint_numbers() :: [pos_integer()]
  def implemented_checkpoint_numbers, do: @implemented_checkpoint_numbers

  @doc """
  Returns the required file set for Phase 23 tutorial projects.
  """
  @spec required_project_files() :: [String.t()]
  def required_project_files, do: @required_project_files

  @doc """
  Returns the absolute project path for one implemented checkpoint.
  """
  @spec chapter_project_path(pos_integer()) :: String.t()
  def chapter_project_path(number) do
    number
    |> Tutorials.chapter!()
    |> Map.fetch!("code_path")
    |> Path.expand(repo_root())
  end

  @doc """
  Returns the absolute source path for one implemented checkpoint module.
  """
  @spec chapter_source_path(pos_integer()) :: String.t()
  def chapter_source_path(number) do
    @chapter_source_paths
    |> Map.fetch!(number)
    |> Path.expand(repo_root())
  end

  @doc """
  Returns the root tutorial module for one implemented checkpoint.
  """
  @spec chapter_module(pos_integer()) :: module()
  def chapter_module(number), do: Map.fetch!(@chapter_modules, number)

  @doc """
  Returns the Mix project module for one implemented checkpoint.
  """
  @spec chapter_mix_project_module(pos_integer()) :: module()
  def chapter_mix_project_module(number), do: Map.fetch!(@chapter_mix_project_modules, number)

  @doc """
  Returns the absolute maintained final-app path.
  """
  @spec final_app_path() :: String.t()
  def final_app_path do
    Tutorials.final_app_path()
  end

  @doc """
  Returns the absolute maintained final-app source path.
  """
  @spec final_app_source_path() :: String.t()
  def final_app_source_path do
    Path.expand(@final_app_source_path, repo_root())
  end

  @doc """
  Returns the maintained final-app root module.
  """
  @spec final_app_module() :: module()
  def final_app_module, do: @final_app_module

  @doc """
  Returns the maintained final-app Mix project module.
  """
  @spec final_mix_project_module() :: module()
  def final_mix_project_module, do: @final_mix_project_module

  @doc """
  Returns the baseline document path for the tutorial domain and theme contract.
  """
  @spec baseline_doc_path() :: String.t()
  def baseline_doc_path do
    Path.expand("../../../tutorials/operations_control_center_baseline.md", __DIR__)
  end

  @doc """
  Validates that the checked-in baseline document still exposes the required sections and identifiers.
  """
  @spec validate_baseline_doc() :: :ok | {:error, term()}
  def validate_baseline_doc do
    body = File.read!(baseline_doc_path())
    missing_markers = Enum.reject(@required_baseline_markers, &String.contains?(body, &1))

    if missing_markers == [] do
      :ok
    else
      {:error, {:tutorial_baseline_drift, %{missing_markers: missing_markers}}}
    end
  end

  @doc """
  Validates the required Phase 23 project structure for implemented checkpoints and the final app.
  """
  @spec validate_project_structure() :: :ok | {:error, term()}
  def validate_project_structure do
    issues =
      project_targets()
      |> Enum.flat_map(fn {label, root_path} ->
        Enum.reject(@required_project_files, &File.exists?(Path.join(root_path, &1)))
        |> Enum.map(fn missing_file ->
          %{target: label, root_path: root_path, missing_file: missing_file}
        end)
      end)

    if issues == [] do
      :ok
    else
      {:error, {:tutorial_project_drift, issues}}
    end
  end

  @doc """
  Validates that the implemented chapter docs reference the exact code artifacts introduced in each checkpoint.
  """
  @spec validate_implemented_chapter_artifacts() :: :ok | {:error, term()}
  def validate_implemented_chapter_artifacts do
    issues =
      @chapter_artifact_markers
      |> Enum.flat_map(fn {number, markers} ->
        chapter = Tutorials.chapter!(number)
        body = File.read!(Path.expand(chapter["chapter_path"], repo_root()))

        Enum.reject(markers, &String.contains?(body, &1))
        |> Enum.map(fn missing_marker ->
          %{chapter: chapter["slug"], missing_marker: missing_marker}
        end)
      end)

    if issues == [] do
      :ok
    else
      {:error, {:tutorial_artifact_reference_drift, issues}}
    end
  end

  @doc """
  Validates that the Chapter 2 checkpoint and final app compile from authoritative screen and element resources.
  """
  @spec validate_authoritative_resource_sources() :: :ok | {:error, term()}
  def validate_authoritative_resource_sources do
    issues =
      [
        {:chapter_2, chapter_source_path(2)},
        {:final_app, final_app_source_path()}
      ]
      |> Enum.flat_map(fn {label, source_path} ->
        body = File.read!(source_path)

        missing_required =
          Enum.reject(@authoritative_source_markers, &String.contains?(body, &1))
          |> Enum.map(fn missing_marker ->
            %{target: label, source_path: source_path, kind: :missing_required, marker: missing_marker}
          end)

        forbidden_present =
          Enum.filter(@forbidden_source_markers, &String.contains?(body, &1))
          |> Enum.map(fn forbidden_marker ->
            %{target: label, source_path: source_path, kind: :forbidden_marker, marker: forbidden_marker}
          end)

        missing_required ++ forbidden_present
      end)

    if issues == [] do
      :ok
    else
      {:error, {:tutorial_authority_drift, issues}}
    end
  end

  defp project_targets do
    checkpoint_targets =
      Enum.map(@implemented_checkpoint_numbers, fn number ->
        {"chapter_#{number}", chapter_project_path(number)}
      end)

    checkpoint_targets ++ [{"final_app", final_app_path()}]
  end

  defp repo_root do
    Path.expand("../../..", __DIR__)
  end
end
