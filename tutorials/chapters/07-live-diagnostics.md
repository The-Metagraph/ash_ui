# Chapter 7 - Live Diagnostics

## Code For This Chapter

Checkpoint app: `tutorials/code/07-live-diagnostics/`

Previous checkpoint: `tutorials/code/06-runbooks-and-attachments/`

Supporting examples: `examples/log_viewer`, `examples/process_monitor`, `examples/status`, `examples/stream_widget`

Chapter 6 gave operators guidance and evidence review. Chapter 7 adds the first
live-shaped diagnostic lane. This chapter is about giving the incidents
workspace more urgency without pretending to have a production streaming system
when the code does not.

The checkpoint app at
[`tutorials/code/07-live-diagnostics/`](../code/07-live-diagnostics/)
builds directly on
[`tutorials/code/06-runbooks-and-attachments/`](../code/06-runbooks-and-attachments/)
and extends the incidents workspace with a diagnostics panel built entirely
from persisted screen and element resources.

## What You Are Building

By the end of Chapter 7, the incidents workspace can:

1. load one of several diagnostic scenarios
2. surface freshness and risk through a status widget
3. explain support limits through inline feedback
4. render representative logs, activity stream entries, and process state
5. keep the whole diagnostics story synchronized through one runtime record

The key teaching goal is credibility. The surfaces can look operationally rich,
but the tutorial text and widget copy should stay honest about what is seeded,
stale, or simulated.

## Start With Diagnostics Models In Runtime State

The central resource is:

- `AshUITutorials.LiveDiagnostics.Runtime.WorkspaceState`

Important diagnostics fields include:

- `diagnostics_mode`
- `diagnostics_status_model`
- `diagnostics_feedback_model`
- `diagnostics_log_entries`
- `diagnostics_stream_entries`
- `diagnostics_process_model`
- `diagnostics_status_copy`

That is the correct place for them. The current diagnostic scenario is
application state. The widgets should bind to that state rather than inventing
their own partial versions of it.

Each scenario button updates a whole diagnostics snapshot at once, which keeps
the panel coherent instead of turning into a pile of unrelated demo surfaces.

## Keep The Same Screen Structure

Chapter 7 still persists:

- `AshUITutorials.LiveDiagnostics.UiScreen`
- `AshUITutorials.LiveDiagnostics.UiElement`
- `AshUITutorials.LiveDiagnostics.UiBinding`

And it still uses the same screen roots:

- `AshUITutorials.LiveDiagnostics.Examples.ServicesScreen`
- `AshUITutorials.LiveDiagnostics.Examples.IncidentsScreen`

That continuity matters. Diagnostics are not a separate mini-app. They are a
new layer in the same incidents workspace.

## The Widget Plan For This Chapter

Chapter 7 adds the first live-shaped operational widgets:

| Widget | Where it goes | Why it belongs there |
|---|---|---|
| `custom:status` | Top of the diagnostics panel | Makes freshness and risk visible before the operator trusts the data |
| `custom:inline_feedback` | Under the status widget | Explains whether the data is simulated, stale, or under pressure |
| `custom:log_viewer` | Main diagnostics body | Fits representative log rows naturally |
| `custom:stream_widget` | Main diagnostics body | Fits activity feed events and operator-facing stream messages |
| `custom:process_monitor` | Main diagnostics body | Fits one seeded runtime-process snapshot |
| `button` | Scenario selectors | Lets the operator choose the diagnostics story to load |
| `text` | Panel status copy | Keeps the support boundary explicit |

These widgets are powerful, so the prose needs to do extra work to keep them
honest.

## Build The Diagnostics Panel

The new panel is:

- `AshUITutorials.LiveDiagnostics.Examples.LiveDiagnosticsPanelElement`

It contains:

- `AshUITutorials.LiveDiagnostics.Examples.LoadGatewayDiagnosticsButtonElement`
- `AshUITutorials.LiveDiagnostics.Examples.LoadSearchDiagnosticsButtonElement`
- `AshUITutorials.LiveDiagnostics.Examples.LoadPressureDiagnosticsButtonElement`
- `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsStatusElement`
- `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsInlineFeedbackElement`
- `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsLogViewerElement`
- `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsStreamWidgetElement`
- `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsProcessMonitorElement`
- `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsStatusTextElement`

This panel is a good example of authored sequencing:

1. choose the scenario
2. show readiness and support notes
3. show the deeper diagnostic surfaces
4. reinforce the current state in the footer

## Use Buttons To Load Coherent Diagnostic Scenarios

The three authored selectors are:

- `AshUITutorials.LiveDiagnostics.Examples.LoadGatewayDiagnosticsButtonElement`
- `AshUITutorials.LiveDiagnostics.Examples.LoadSearchDiagnosticsButtonElement`
- `AshUITutorials.LiveDiagnostics.Examples.LoadPressureDiagnosticsButtonElement`

Each one updates an entire scenario:

- status model
- feedback model
- log entries
- stream entries
- process model
- detail card state
- status copy

That is important. Operators do not think in isolated widgets. They think in
scenarios. The runtime resource should express the same thing.

## Make Freshness Visible First

Two surfaces set the tone for the whole diagnostics panel:

- `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsStatusElement`
- `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsInlineFeedbackElement`

Use `custom:status` to answer "how much should I trust this view?" and use
`custom:inline_feedback` to answer "why does this view look this way?".

This is one of the most useful habits in the tutorial so far. Whenever a
surface could overclaim freshness or certainty, put the support note in the
UI, not just in the chapter prose.

## Build The Deeper Diagnostics Surfaces

Once trust and support are framed correctly, the deeper widgets can do their
job:

- `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsLogViewerElement`
- `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsStreamWidgetElement`
- `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsProcessMonitorElement`

Each one binds to a different runtime field:

- log rows
- stream entries
- process model

That keeps the diagnostics lane expressive without requiring each widget to
invent its own local state or hidden fetch path.

## Keep The Incidents Workspace Coherent

By Chapter 7, the incidents workspace now contains:

1. filters
2. table review
3. operator forms
4. guard flows
5. runbooks and evidence
6. diagnostics

That sounds large, but the authored panel boundaries keep the screen readable.
The diagnostics panel does not replace the runbook panel or the form panel. It
adds one more operational lane to the same resource-authored screen.

The services screen still exists and still uses the shared shell, but the
incidents screen is now clearly the deepest operator workspace in the tutorial.

## Persist And Mount The Diagnostics-Enabled Screens

The persistence flow remains stable:

- `AshUITutorials.LiveDiagnostics.seed!/1` creates the runtime record
- authority persists `AshUITutorials.LiveDiagnostics.Examples.ServicesScreen`
- authority persists `AshUITutorials.LiveDiagnostics.Examples.IncidentsScreen`

The hosts remain:

- `AshUITutorials.LiveDiagnostics.Web.ServicesLive`
- `AshUITutorials.LiveDiagnostics.Web.IncidentsLive`

That consistency is one of the strengths of the tutorial. The UI becomes richer
without forcing a new hosting model.

## Modules And Resources You Will Touch

Keep these names in view while reading the checkpoint code:

- source file: [`../code/07-live-diagnostics/lib/ash_ui_tutorials/live_diagnostics.ex`](../code/07-live-diagnostics/lib/ash_ui_tutorials/live_diagnostics.ex)
- main checkpoint module: `AshUITutorials.LiveDiagnostics`
- runtime state resource: `AshUITutorials.LiveDiagnostics.Runtime.WorkspaceState`
- persisted UI resources: `AshUITutorials.LiveDiagnostics.UiScreen`, `AshUITutorials.LiveDiagnostics.UiElement`, `AshUITutorials.LiveDiagnostics.UiBinding`
- authoritative screen builders: `AshUITutorials.LiveDiagnostics.Examples.ServicesScreen`, `AshUITutorials.LiveDiagnostics.Examples.IncidentsScreen`
- diagnostics surfaces: `AshUITutorials.LiveDiagnostics.Examples.LiveDiagnosticsPanelElement`, `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsStatusElement`, `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsInlineFeedbackElement`, `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsLogViewerElement`, `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsStreamWidgetElement`, `AshUITutorials.LiveDiagnostics.Examples.DiagnosticsProcessMonitorElement`
- diagnostics selectors: `AshUITutorials.LiveDiagnostics.Examples.LoadGatewayDiagnosticsButtonElement`, `AshUITutorials.LiveDiagnostics.Examples.LoadSearchDiagnosticsButtonElement`, `AshUITutorials.LiveDiagnostics.Examples.LoadPressureDiagnosticsButtonElement`
- LiveView hosts: `AshUITutorials.LiveDiagnostics.Web.ServicesLive`, `AshUITutorials.LiveDiagnostics.Web.IncidentsLive`

## Run The Checkpoint

From
[`tutorials/code/07-live-diagnostics/`](../code/07-live-diagnostics/):

```bash
mix deps.get
mix example.start
```

The default command starts `live_ui` through the Phoenix LiveView host at
`http://127.0.0.1:5000/`.

Use:

- `/` for the services workspace
- `/incidents` for the incidents workspace with diagnostics enabled

Alternate runtime previews remain available:

```bash
mix example.start elm_ui
mix example.start desktop_ui
```

They all consume the same authoritative screen graph and diagnostics state.

## What To Carry Into Chapter 8

Chapter 7 proves that live-shaped surfaces can still be honest and
resource-backed.

Chapter 8 shifts back to the services side and adds structural review: topology,
navigation, larger visual surfaces, and the first real multi-pane service map
experience.
