defmodule AshUI.Tutorials.Phase23 do
  @moduledoc """
  Shared baseline data for the Phase 23 Operations Control Center tutorial.

  The tutorial checkpoints depend on one believable domain, one shared visual
  contract, and one stable seeded dataset so later chapters can add behavior
  without rewriting the story every time.
  """

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
      summary: "Full platform access, including policy overrides and destructive flows."
    },
    %{
      id: "on-call-maya",
      name: "Maya On-Call",
      role: :on_call_operator,
      summary: "Primary operator for incident triage, assignments, and maintenance actions."
    },
    %{
      id: "viewer-ren",
      name: "Ren Viewer",
      role: :viewer,
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
end
