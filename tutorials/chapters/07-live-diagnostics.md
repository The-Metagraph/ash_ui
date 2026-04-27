# Chapter 7 - Live Diagnostics

## Code For This Chapter

Checkpoint app: `tutorials/code/07-live-diagnostics/`

Previous checkpoint: `tutorials/code/06-runbooks-and-attachments/`

Supporting examples: `examples/log_viewer`, `examples/process_monitor`, `examples/status`, `examples/stream_widget`

This chapter extends the runbook-review workspace from
[`tutorials/code/06-runbooks-and-attachments/`](../code/06-runbooks-and-attachments/)
with the first live-shaped diagnostic surfaces.

## What You Build

The checkpoint app at
[`tutorials/code/07-live-diagnostics/`](../code/07-live-diagnostics/)
keeps the same two authoritative screens from Chapter 6 and extends the
incidents workspace with a persisted diagnostics panel.

That panel uses:

- `custom:status` to surface freshness and risk before operators trust the
  diagnostics lane
- `custom:inline_feedback` to explain whether a feed is simulated, stale, or
  under pressure
- `custom:log_viewer` for representative runtime rows
- `custom:stream_widget` for a seeded activity feed
- `custom:process_monitor` for one runtime model snapshot

The key design constraint in this chapter is credibility: the diagnostics can
look live, but the tutorial must stay explicit about what is seeded,
representative, or stale instead of implying a production subscription
transport or a hidden supervisor tap.

## Modules and Resources Introduced

- Main checkpoint module:
  [`AshUITutorials.LiveDiagnostics`](../code/07-live-diagnostics/lib/ash_ui_tutorials/live_diagnostics.ex)
- Runtime state resource:
  `AshUITutorials.LiveDiagnostics.Runtime.WorkspaceState`
- Persisted UI resources:
  `AshUITutorials.LiveDiagnostics.UiScreen`,
  `AshUITutorials.LiveDiagnostics.UiElement`, and
  `AshUITutorials.LiveDiagnostics.UiBinding`
- Existing authoritative screen builders:
  `AshUITutorials.LiveDiagnostics.Examples.ServicesScreen` and
  `AshUITutorials.LiveDiagnostics.Examples.IncidentsScreen`
- New authored diagnostics surfaces:
  `AshUITutorials.LiveDiagnostics.Examples.LiveDiagnosticsPanelElement`,
  `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsStatusElement`,
  `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsInlineFeedbackElement`,
  `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsLogViewerElement`,
  `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsStreamWidgetElement`, and
  `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsProcessMonitorElement`
- New authored diagnostics selectors:
  `AshUITutorials.LiveDiagnostics.Examples.LoadGatewayDiagnosticsButtonElement`,
  `AshUITutorials.LiveDiagnostics.Examples.LoadSearchDiagnosticsButtonElement`,
  and `AshUITutorials.LiveDiagnostics.Examples.LoadPressureDiagnosticsButtonElement`
- LiveView hosts:
  `AshUITutorials.LiveDiagnostics.Web.ServicesLive` and
  `AshUITutorials.LiveDiagnostics.Web.IncidentsLive`

The diagnostics path is still centered on
`AshUITutorials.LiveDiagnostics.Runtime.WorkspaceState.update`. Each authored
button swaps one coherent diagnostics scenario across status, inline feedback,
logs, stream entries, process state, shared detail copy, and the explicit
freshness note in one resource-backed write.

## Run The Checkpoint

From
[`tutorials/code/07-live-diagnostics/`](../code/07-live-diagnostics/):

```bash
mix deps.get
mix example.start
```

The default command starts `live_ui` through the Phoenix LiveView host at
`http://127.0.0.1:5000/`. Visit `/` for the services workspace and
`/incidents` for the incidents workspace with the diagnostics panel active.

Alternate runtime previews are still available:

```bash
mix example.start elm_ui
mix example.start desktop_ui
```

Those modes keep the same authoritative screen graph and the same explicit
transport limits, so later chapters can add larger topology and metrics
surfaces without rewriting the Chapter 7 diagnostics contract.
