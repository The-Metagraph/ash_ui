# Chapter 9 - Metrics and Capacity

## Code For This Chapter

Checkpoint app: `tutorials/code/09-metrics-and-capacity/`

Previous checkpoint: `tutorials/code/08-topology-and-navigation/`

Supporting examples: `examples/bar_chart`, `examples/cluster_dashboard`, `examples/gauge`, `examples/line_chart`

Chapter 8 gave the services workspace a structural review layer. Chapter 9 adds
telemetry and capacity review on top of that same workspace. The key challenge
in this chapter is not just rendering charts. It is rendering them honestly.

The checkpoint app at
[`tutorials/code/09-metrics-and-capacity/`](../code/09-metrics-and-capacity/)
builds directly on
[`tutorials/code/08-topology-and-navigation/`](../code/08-topology-and-navigation/)
and extends the services workspace with a persisted metrics review panel.

## What You Are Building

By the end of Chapter 9, the services workspace can:

1. load one of several coherent metric stories
2. summarize service and regional posture through a cluster dashboard
3. show progress and gauge models for operational completion and capacity
4. show short and long trends through sparkline and line-chart surfaces
5. explain the sampled nature of the telemetry right in the UI

This chapter is about making metrics useful without turning the tutorial into a
dishonest fake monitoring product.

## Start With Metrics Models In Runtime State

The central resource is:

- `AshUITutorials.MetricsAndCapacity.Runtime.WorkspaceState`

Important new metrics fields include:

- `metrics_focus`
- `metrics_dashboard_model`
- `metrics_dashboard_status`
- `progress_metric`
- `gauge_metric`
- `sparkline_series`
- `bar_chart_series`
- `line_chart_series`
- `metrics_support_notice`
- `metrics_status_copy`

These belong in runtime state because the active metric story is not local chart
state. It is part of the operator’s current review context.

Chapter 9 deliberately loads complete stories. A button does not just change a
single chart. It swaps a dashboard model, progress model, gauge model, trend
series, support notice, and shared detail context together.

## Keep The Existing Screen Structure

Chapter 9 still persists:

- `AshUITutorials.MetricsAndCapacity.UiScreen`
- `AshUITutorials.MetricsAndCapacity.UiElement`
- `AshUITutorials.MetricsAndCapacity.UiBinding`

And it still keeps explicit screen roots:

- `AshUITutorials.MetricsAndCapacity.Examples.ServicesScreen`
- `AshUITutorials.MetricsAndCapacity.Examples.IncidentsScreen`

The incidents screen mostly carries forward the earlier operational workflow
stack. The services screen is where the new metrics layer lands.

## The Widget Plan For This Chapter

Chapter 9 adds the telemetry review vocabulary:

| Widget | Where it goes | Why it belongs there |
|---|---|---|
| `custom:cluster_dashboard` | Top of the metrics panel | Summarizes regional posture, alert context, and operator focus in one surface |
| `custom:progress` | Metrics body | Fits completion-style operational progress cleanly |
| `custom:gauge` | Metrics body | Fits one bounded capacity or saturation signal |
| `custom:sparkline` | Metrics body | Fits one short directional trend |
| `custom:bar_chart` | Metrics body | Fits categorical comparison across services or regions |
| `custom:line_chart` | Metrics body | Fits a longer sampled trend line |
| `button` | Snapshot selectors | Switches between coherent metrics stories |
| `text` | Support notice and status copy | Keeps derivation and sampling limits visible |

This chapter works best when the charts are part of one story, not when they
look like a random gallery.

## Build The Metrics Review Panel

The new services-side panel is:

- `AshUITutorials.MetricsAndCapacity.Examples.MetricsReviewPanelElement`

It contains:

- `AshUITutorials.MetricsAndCapacity.Examples.MetricsClusterDashboardElement`
- `AshUITutorials.MetricsAndCapacity.Examples.MetricsProgressElement`
- `AshUITutorials.MetricsAndCapacity.Examples.MetricsGaugeElement`
- `AshUITutorials.MetricsAndCapacity.Examples.MetricsSparklineElement`
- `AshUITutorials.MetricsAndCapacity.Examples.MetricsBarChartElement`
- `AshUITutorials.MetricsAndCapacity.Examples.MetricsLineChartElement`
- `AshUITutorials.MetricsAndCapacity.Examples.MetricsSupportNoticeElement`
- `AshUITutorials.MetricsAndCapacity.Examples.MetricsPanelStatusTextElement`

That ordering is useful:

1. show the top-level dashboard summary
2. step down into increasingly specific metric surfaces
3. keep the sampling caveat and active status visible in the footer

## Use The Cluster Dashboard As The Story Header

The lead widget is:

- `AshUITutorials.MetricsAndCapacity.Examples.MetricsClusterDashboardElement`

It uses `custom:cluster_dashboard` and contains the snapshot selectors:

- `AshUITutorials.MetricsAndCapacity.Examples.LoadGatewayMetricsButtonElement`
- `AshUITutorials.MetricsAndCapacity.Examples.LoadSearchMetricsButtonElement`
- `AshUITutorials.MetricsAndCapacity.Examples.LoadFleetMetricsButtonElement`
- `AshUITutorials.MetricsAndCapacity.Examples.MetricsDashboardFooterElement`

This is the right way to start the panel because the operator needs one
high-level posture before reading the supporting charts.

## Load Coherent Metrics Stories

The three authored selectors correspond to three different review stories:

1. gateway saturation
2. search recovery
3. fleet capacity

Each selector updates:

- the cluster dashboard model
- the dashboard footer
- the progress model
- the gauge model
- sparkline, bar-chart, and line-chart series
- the support notice
- the shared detail card
- the status text

That is exactly how a tutorial should model charts. The charts are not floating
visuals. They are different views of one active operational story.

## Build The Supporting Metric Surfaces

Once the dashboard headline is in place, the supporting widgets follow:

- `AshUITutorials.MetricsAndCapacity.Examples.MetricsProgressElement`
- `AshUITutorials.MetricsAndCapacity.Examples.MetricsGaugeElement`
- `AshUITutorials.MetricsAndCapacity.Examples.MetricsSparklineElement`
- `AshUITutorials.MetricsAndCapacity.Examples.MetricsBarChartElement`
- `AshUITutorials.MetricsAndCapacity.Examples.MetricsLineChartElement`

Each one binds to a separate runtime field:

- `progress_metric`
- `gauge_metric`
- `sparkline_series`
- `bar_chart_series`
- `line_chart_series`

This separation keeps the panel readable and the state model explicit. Each
widget knows what data shape it expects, but the runtime resource still owns the
overall story.

## Keep Telemetry Honesty In The UI

Two surfaces are especially important in this chapter:

- `AshUITutorials.MetricsAndCapacity.Examples.MetricsSupportNoticeElement`
- `AshUITutorials.MetricsAndCapacity.Examples.MetricsPanelStatusTextElement`

Use them to say plainly that the values are sampled tutorial data shaped from
the shared fixtures, not a live telemetry feed.

That honesty is part of the product design, not an apologetic footnote. The
operator should understand what the dashboard means and what it does not mean.

## Let The Services Workspace Grow Without Losing Coherence

By Chapter 9, the services workspace now contains:

1. menu and command surfaces
2. filters
3. the services list
4. shared detail
5. topology review
6. metrics and capacity review

That is a lot of information, so the panel structure matters. Metrics are added
as their own authored surface family instead of being scattered inside the
topology shell.

The incidents screen continues carrying the deeper workflow stack from earlier
chapters, which is another sign that the tutorial is still building one
application, not disconnected demos.

## Persist And Mount The Metrics-Enabled Screens

The persistence flow stays familiar:

- `AshUITutorials.MetricsAndCapacity.seed!/1` creates the runtime record
- authority persists `AshUITutorials.MetricsAndCapacity.Examples.ServicesScreen`
- authority persists `AshUITutorials.MetricsAndCapacity.Examples.IncidentsScreen`

The hosts remain:

- `AshUITutorials.MetricsAndCapacity.Web.ServicesLive`
- `AshUITutorials.MetricsAndCapacity.Web.IncidentsLive`

That stability keeps the tutorial approachable even as the screen surfaces get
denser.

## Modules And Resources You Will Touch

Keep these names in view while exploring the checkpoint:

- source file: [`../code/09-metrics-and-capacity/lib/ash_ui_tutorials/metrics_and_capacity.ex`](../code/09-metrics-and-capacity/lib/ash_ui_tutorials/metrics_and_capacity.ex)
- main checkpoint module: `AshUITutorials.MetricsAndCapacity`
- runtime state resource: `AshUITutorials.MetricsAndCapacity.Runtime.WorkspaceState`
- persisted UI resources: `AshUITutorials.MetricsAndCapacity.UiScreen`, `AshUITutorials.MetricsAndCapacity.UiElement`, `AshUITutorials.MetricsAndCapacity.UiBinding`
- authoritative screen builders: `AshUITutorials.MetricsAndCapacity.Examples.ServicesScreen`, `AshUITutorials.MetricsAndCapacity.Examples.IncidentsScreen`
- metrics shell resources: `AshUITutorials.MetricsAndCapacity.Examples.MetricsReviewPanelElement`, `AshUITutorials.MetricsAndCapacity.Examples.MetricsClusterDashboardElement`
- snapshot selectors: `AshUITutorials.MetricsAndCapacity.Examples.LoadGatewayMetricsButtonElement`, `AshUITutorials.MetricsAndCapacity.Examples.LoadSearchMetricsButtonElement`, `AshUITutorials.MetricsAndCapacity.Examples.LoadFleetMetricsButtonElement`
- metric surfaces: `AshUITutorials.MetricsAndCapacity.Examples.MetricsProgressElement`, `AshUITutorials.MetricsAndCapacity.Examples.MetricsGaugeElement`, `AshUITutorials.MetricsAndCapacity.Examples.MetricsSparklineElement`, `AshUITutorials.MetricsAndCapacity.Examples.MetricsBarChartElement`, `AshUITutorials.MetricsAndCapacity.Examples.MetricsLineChartElement`
- LiveView hosts: `AshUITutorials.MetricsAndCapacity.Web.ServicesLive`, `AshUITutorials.MetricsAndCapacity.Web.IncidentsLive`

## Run The Checkpoint

From
[`tutorials/code/09-metrics-and-capacity/`](../code/09-metrics-and-capacity/):

```bash
mix deps.get
mix example.start
```

The default command starts `live_ui` through the Phoenix LiveView host at
`http://127.0.0.1:5000/`.

Use:

- `/` for the services workspace with topology and metrics enabled
- `/incidents` for the incidents workspace carrying forward the Chapter 7 stack

Alternate runtime previews remain available:

```bash
mix example.start elm_ui
mix example.start desktop_ui
```

They all render the same authored screens and sampled metrics state.

## What To Carry Forward

Chapter 9 closes the currently implemented tutorial line with an important
pattern: large data-rich surfaces still work best when they are modeled as one
coherent story in runtime state and then broken into authored widgets through
screen resources.

The later planned chapters can build on this by adding deeper runtime
introspection, role-aware behavior, and final production polish without
changing that foundation.
