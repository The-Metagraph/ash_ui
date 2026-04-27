# Chapter 9 - Metrics and Capacity

## Code For This Chapter

Checkpoint app: `tutorials/code/09-metrics-and-capacity/`

Previous checkpoint: `tutorials/code/08-topology-and-navigation/`

Supporting examples: `examples/bar_chart`, `examples/cluster_dashboard`, `examples/gauge`, `examples/line_chart`

This chapter extends the topology-enabled services workspace from
[`tutorials/code/08-topology-and-navigation/`](../code/08-topology-and-navigation/)
with the first telemetry and capacity-review surfaces.

## What You Build

The checkpoint app at
[`tutorials/code/09-metrics-and-capacity/`](../code/09-metrics-and-capacity/)
keeps the same two authoritative screens from Chapter 8 and extends the
services workspace with a persisted metrics-review panel.

That panel uses:

- `custom:cluster_dashboard` to summarize regional health, active alerts, and
  current operator context in one surface
- `custom:progress` for sampled mitigation or recovery completion
- `custom:gauge` for one bounded capacity signal
- `custom:sparkline` for a short directional trend
- `custom:bar_chart` and `custom:line_chart` for categorical comparison and
  longer trend review

The key design constraint in this chapter is honesty about telemetry. The
tutorial is allowed to show dashboards and charts, but it must stay explicit
about which values are seeded, sampled, or derived from the shared fixtures
instead of implying a live metrics pipeline that the code does not actually
provide.

## Modules and Resources Introduced

- Main checkpoint module:
  [`AshUITutorials.MetricsAndCapacity`](../code/09-metrics-and-capacity/lib/ash_ui_tutorials/metrics_and_capacity.ex)
- Runtime state resource:
  `AshUITutorials.MetricsAndCapacity.Runtime.WorkspaceState`
- Persisted UI resources:
  `AshUITutorials.MetricsAndCapacity.UiScreen`,
  `AshUITutorials.MetricsAndCapacity.UiElement`, and
  `AshUITutorials.MetricsAndCapacity.UiBinding`
- Existing authoritative screen builders:
  `AshUITutorials.MetricsAndCapacity.Examples.ServicesScreen` and
  `AshUITutorials.MetricsAndCapacity.Examples.IncidentsScreen`
- New authored metrics shell resources:
  `AshUITutorials.MetricsAndCapacity.Examples.MetricsReviewPanelElement` and
  `AshUITutorials.MetricsAndCapacity.Examples.MetricsClusterDashboardElement`
- New authored metrics selectors:
  `AshUITutorials.MetricsAndCapacity.Examples.LoadGatewayMetricsButtonElement`,
  `AshUITutorials.MetricsAndCapacity.Examples.LoadSearchMetricsButtonElement`,
  and `AshUITutorials.MetricsAndCapacity.Examples.LoadFleetMetricsButtonElement`
- New authored metric surfaces:
  `AshUITutorials.MetricsAndCapacity.Examples.MetricsProgressElement`,
  `AshUITutorials.MetricsAndCapacity.Examples.MetricsGaugeElement`,
  `AshUITutorials.MetricsAndCapacity.Examples.MetricsSparklineElement`,
  `AshUITutorials.MetricsAndCapacity.Examples.MetricsBarChartElement`, and
  `AshUITutorials.MetricsAndCapacity.Examples.MetricsLineChartElement`
- New authored telemetry disclosure resources:
  `AshUITutorials.MetricsAndCapacity.Examples.MetricsDashboardFooterElement`,
  `AshUITutorials.MetricsAndCapacity.Examples.MetricsSupportNoticeElement`,
  and `AshUITutorials.MetricsAndCapacity.Examples.MetricsPanelStatusTextElement`
- LiveView hosts:
  `AshUITutorials.MetricsAndCapacity.Web.ServicesLive` and
  `AshUITutorials.MetricsAndCapacity.Web.IncidentsLive`

The metrics path still centers on
`AshUITutorials.MetricsAndCapacity.Runtime.WorkspaceState.update`. One authored
button swaps the cluster dashboard model, progress/gauge models, sparkline,
bar-chart, and line-chart series together so the services workspace tells one
coherent operational story instead of drifting into disconnected chart demos.

## Run The Checkpoint

From
[`tutorials/code/09-metrics-and-capacity/`](../code/09-metrics-and-capacity/):

```bash
mix deps.get
mix example.start
```

The default command starts `live_ui` through the Phoenix LiveView host at
`http://127.0.0.1:5000/`. Visit `/` for the services workspace with the
topology and metrics panels active and `/incidents` for the incidents workspace
that still includes the Chapter 7 runbook and diagnostics surfaces.

Alternate runtime previews are still available:

```bash
mix example.start elm_ui
mix example.start desktop_ui
```

Those modes keep the same authoritative screen graph and the same explicit
telemetry-disclosure contract, so later chapters can add runtime introspection
without rewriting the metrics and capacity model introduced here.
