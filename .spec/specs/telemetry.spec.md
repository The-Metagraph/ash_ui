# Telemetry

Canonical telemetry emission, in-memory metrics, and dashboard definitions for Ash UI.

## Intent

Define the observability contract that Ash UI ships today for screen, binding, compilation, rendering, authorization, and migration flows.

```spec-meta
id: ash_ui.telemetry
kind: workflow
status: active
summary: Canonical telemetry catalog, metrics aggregation, dashboard snapshots, and metadata hygiene for Ash UI events.
surface:
  - specs/contracts/observability_contract.md
  - lib/ash_ui/telemetry.ex
  - priv/monitoring/dashboards/screen_performance.json
  - priv/monitoring/dashboards/error_rate.json
  - priv/monitoring/dashboards/authorization_failures.json
  - priv/monitoring/dashboards/renderer_usage.json
```

## Requirements

```spec-requirements
- id: ash_ui.telemetry.event_catalog
  statement: Ash UI telemetry shall define canonical ash_ui event names and metadata contracts across authoring, screen, binding, compilation, render, and authorization flows.
  priority: must
  stability: stable
- id: ash_ui.telemetry.metrics_snapshot
  statement: Default telemetry handlers shall maintain in-memory counters and dashboard-friendly snapshots for screen performance, error rate, authorization failures, and renderer usage.
  priority: must
  stability: stable
- id: ash_ui.telemetry.metadata_hygiene
  statement: Telemetry emission shall preserve trace and span metadata while redacting configured sensitive metadata keys before handlers receive the event payload.
  priority: must
  stability: evolving
```

## Verification

```spec-verification
- kind: command
  target: mix test test/ash_ui/telemetry_test.exs
  execute: true
  covers:
    - ash_ui.telemetry.event_catalog
    - ash_ui.telemetry.metrics_snapshot
    - ash_ui.telemetry.metadata_hygiene
```
