# Operations Control Center Baseline

This document defines the shared Phase 23 baseline for the tutorial
application. The later tutorial checkpoints build on this exact domain,
actor, theme, and seed contract instead of inventing a new story each time.

## Domain Resources

- `Service`
  Represents one operator-facing system or dependency. In the tutorial
  baseline, a service belongs to one cluster and can have many incidents and
  deployments.
- `Incident`
  Represents an active or recent issue tied to one service and one primary
  operator owner.
- `Cluster`
  Represents an infrastructure grouping for services and deployments.
- `Deployment`
  Represents a rollout or maintenance event that operators can review beside
  incidents and service status.
- `Runbook`
  Represents operator guidance tied to a service or incident.
- `Operator`
  Represents the active actor and ownership context used by role-aware
  chapters later in the series.

## Actor Profiles

- `admin`
  Full platform access, including policy overrides and destructive flows.
- `on_call_operator`
  Primary operator for incident triage, assignment, and maintenance actions.
- `viewer`
  Read-only observer who can inspect dashboards but cannot mutate state.

## Shared Theme Contract

The tutorial reuses the Ash HQ visual baseline already defined by:

- `examples/ash_hq_theme_baseline.md`
- `examples/ash_hq_theme_tokens.css`

Checkpoint apps vendor their own CSS locally, but that local CSS should stay
aligned with the same dark-slate shell, glass panels, warm red/orange
gradients, and rounded call-to-action treatments.

The tutorial differs from the example suite mainly in composition scale:
multiple widgets appear together on one operational workspace instead of one
primary widget being isolated per app.

## Seed Fixtures

The baseline tutorial seed data includes:

- services for `API Gateway`, `Billing`, and `Search`
- incidents for a gateway latency spike and a search replica lag event
- clusters for `Core East` and `Edge West`
- deployments for a paused gateway rollout and a completed billing rollout
- runbooks for latency and replica-lag response
- metrics for latency, retry rate, and replica lag
- logs for gateway and search review
- topology nodes that connect the gateway to billing and search

These fixtures are intentionally stable across checkpoints so each later
chapter can add new UI behavior without changing the underlying operational
story.
