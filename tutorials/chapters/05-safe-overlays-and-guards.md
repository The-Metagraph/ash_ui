# Chapter 5 - Safe Overlays and Guards

## Code For This Chapter

Checkpoint app: `tutorials/code/05-safe-overlays-and-guards/`

Previous checkpoint: `tutorials/code/04-operator-actions-and-forms/`

Supporting examples: `examples/alert_dialog`, `examples/context_menu`, `examples/dialog`, `examples/toast`

Chapter 4 gave operators real write workflows. Chapter 5 adds the safety layer
those workflows need. This chapter is about sensitive actions, confirmation
surfaces, and feedback that stays visible and traceable.

The checkpoint app at
[`tutorials/code/05-safe-overlays-and-guards/`](../code/05-safe-overlays-and-guards/)
builds directly on
[`tutorials/code/04-operator-actions-and-forms/`](../code/04-operator-actions-and-forms/)
and keeps the same services and incidents screens, but it extends the
incidents workspace with guard rails for destructive or high-risk actions.

## What You Are Building

By the end of Chapter 5, the incidents workspace can:

1. launch guarded actions from one context menu
2. preview the selected guard intent in persisted state
3. open the correct overlay surface for that guard
4. confirm or cancel the action without hidden host-only state
5. show toast feedback after the action completes

This chapter is where the tutorial starts to feel operationally responsible.

## Start With Guard State In The Runtime Resource

The central resource is still:

- `AshUITutorials.SafeOverlaysAndGuards.Runtime.WorkspaceState`

New guard-related fields include values like:

- `active_guard_action`
- `guard_title`
- `guard_summary`
- `guard_result`
- `overlay_open`
- `resolve_dialog_open`
- `restart_alert_open`
- `toast_visible`
- `toast_title`
- `toast_summary`

That is the correct architectural move. Overlay visibility and confirmation
context are part of the application state for this chapter. They are not just
animation toggles hiding in the LiveView host.

The two key actions are:

- `preview_guarded_action`
- `confirm_guarded_action`

Those actions turn the overlay system into a resource-backed workflow instead
of a collection of floating UI fragments.

## Keep The Existing Workflows And Add One New Panel

Chapter 5 still persists:

- `AshUITutorials.SafeOverlaysAndGuards.UiScreen`
- `AshUITutorials.SafeOverlaysAndGuards.UiElement`
- `AshUITutorials.SafeOverlaysAndGuards.UiBinding`

And it still exposes the same two screen roots:

- `AshUITutorials.SafeOverlaysAndGuards.Examples.ServicesScreen`
- `AshUITutorials.SafeOverlaysAndGuards.Examples.IncidentsScreen`

The new work is concentrated in one additional incidents-side panel:

- `AshUITutorials.SafeOverlaysAndGuards.Examples.GuardedActionsPanelElement`

This is a good tutorial pattern. Instead of rewriting the whole workspace, add
the new concern as one well-bounded authored surface.

## The Widget Plan For This Chapter

Chapter 5 adds the safety and feedback vocabulary:

| Widget | Where it goes | Why it belongs there |
|---|---|---|
| `custom:context_menu` | Launch surface for guarded operations | Groups risky actions in one explicit operator menu |
| `custom:overlay` | Generic guard surface | Fits lightweight confirmation flows such as silence and discard |
| `custom:dialog` | Resolve flow | Fits a primary confirmation with richer explanatory copy |
| `custom:alert_dialog` | Restart flow | Fits a higher-risk action that deserves stronger visual framing |
| `custom:toast` | Post-action feedback | Keeps the result visible until the operator dismisses it |
| `button` | Open, confirm, cancel, dismiss actions | Drives the whole guard cycle |
| `text` | Guard summaries and feedback copy | Explains why the action is risky and what just happened |

The message of the chapter is simple: sensitive operations deserve explicit UI
surfaces and explicit state transitions.

## Build The Guarded Actions Panel

The new panel is:

- `AshUITutorials.SafeOverlaysAndGuards.Examples.GuardedActionsPanelElement`

It contains five surface types:

- `AshUITutorials.SafeOverlaysAndGuards.Examples.GuardedActionsMenuElement`
- `AshUITutorials.SafeOverlaysAndGuards.Examples.GuardOverlayElement`
- `AshUITutorials.SafeOverlaysAndGuards.Examples.ResolveGuardDialogElement`
- `AshUITutorials.SafeOverlaysAndGuards.Examples.RestartGuardAlertElement`
- `AshUITutorials.SafeOverlaysAndGuards.Examples.GuardResultToastElement`

This is worth noticing. The panel is not one overlay. It is a small family of
authored surfaces that all bind back into the same runtime state record.

## Use The Context Menu As The Launcher

The entry point is:

- `AshUITutorials.SafeOverlaysAndGuards.Examples.GuardedActionsMenuElement`

It uses `custom:context_menu` and contains:

- `AshUITutorials.SafeOverlaysAndGuards.Examples.OpenResolveGuardButtonElement`
- `AshUITutorials.SafeOverlaysAndGuards.Examples.OpenRestartGuardButtonElement`
- `AshUITutorials.SafeOverlaysAndGuards.Examples.OpenSilenceGuardButtonElement`
- `AshUITutorials.SafeOverlaysAndGuards.Examples.OpenDiscardNoteGuardButtonElement`
- `AshUITutorials.SafeOverlaysAndGuards.Examples.GuardSummaryTextElement`

That design is friendly to operators and friendly to the architecture:

1. operators get one obvious place to find guarded actions
2. the runtime resource gets one explicit entry path for guard intent

## Model Different Guard Surfaces Deliberately

Chapter 5 does not flatten every confirmation into one generic widget.
Instead it uses the right surface for the job:

- `AshUITutorials.SafeOverlaysAndGuards.Examples.GuardOverlayElement` for generic overlay confirmations
- `AshUITutorials.SafeOverlaysAndGuards.Examples.ResolveGuardDialogElement` for resolve confirmation
- `AshUITutorials.SafeOverlaysAndGuards.Examples.RestartGuardAlertElement` for restart confirmation

Each one binds its `open` flag back to runtime state:

- `overlay_open`
- `resolve_dialog_open`
- `restart_alert_open`

That means the visibility model is explicit, portable, and testable.

## Keep Confirm And Cancel Paths Resource-Backed

The confirm actions flow through:

- `AshUITutorials.SafeOverlaysAndGuards.Examples.ConfirmOverlayGuardButtonElement`
- `AshUITutorials.SafeOverlaysAndGuards.Examples.ConfirmResolveGuardButtonElement`
- `AshUITutorials.SafeOverlaysAndGuards.Examples.ConfirmRestartGuardButtonElement`

All of them call:

- `confirm_guarded_action`

The cancel path stays equally explicit through:

- `AshUITutorials.SafeOverlaysAndGuards.Examples.CancelGuardSurfaceButtonElement`

This is good discipline. Cancellation is part of the state story too. It should
clear the active guard state and close the right surface in a visible,
resource-backed way.

## Add Toast Feedback That Stays Visible

After confirmation, the feedback surface is:

- `AshUITutorials.SafeOverlaysAndGuards.Examples.GuardResultToastElement`

It uses `custom:toast` and contains:

- `AshUITutorials.SafeOverlaysAndGuards.Examples.GuardToastTitleTextElement`
- `AshUITutorials.SafeOverlaysAndGuards.Examples.GuardToastSummaryTextElement`
- `AshUITutorials.SafeOverlaysAndGuards.Examples.DismissGuardToastButtonElement`

This is a strong user-facing choice. The operator gets durable feedback instead
of a fleeting event that disappears before it can be reviewed.

It is also a strong architecture choice. Toast state still lives in the runtime
resource and still rehydrates through bindings.

## Let The Incidents Screen Grow In Layers

By this point, the incidents workspace now contains several layers:

1. filters
2. the incidents table
3. operator forms
4. guarded actions
5. shared detail and status copy

That is exactly why the chapter needed careful structure. The new panel is
added as another authored surface instead of tangling the existing ones.

The services screen remains available, but the incidents screen is now a proper
workflow environment rather than a simple review page.

## Persist And Mount The Guarded Version

The persistence story still stays familiar:

- `AshUITutorials.SafeOverlaysAndGuards.seed!/1` creates the runtime record
- authority persists `AshUITutorials.SafeOverlaysAndGuards.Examples.ServicesScreen`
- authority persists `AshUITutorials.SafeOverlaysAndGuards.Examples.IncidentsScreen`

The hosts remain:

- `AshUITutorials.SafeOverlaysAndGuards.Web.ServicesLive`
- `AshUITutorials.SafeOverlaysAndGuards.Web.IncidentsLive`

That consistency is valuable. The chapter adds complicated user behavior, but
the hosting model still stays calm and predictable.

## Modules And Resources You Will Touch

Keep these names close while you read the checkpoint:

- source file: [`../code/05-safe-overlays-and-guards/lib/ash_ui_tutorials/safe_overlays_and_guards.ex`](../code/05-safe-overlays-and-guards/lib/ash_ui_tutorials/safe_overlays_and_guards.ex)
- main checkpoint module: `AshUITutorials.SafeOverlaysAndGuards`
- runtime state resource: `AshUITutorials.SafeOverlaysAndGuards.Runtime.WorkspaceState`
- persisted UI resources: `AshUITutorials.SafeOverlaysAndGuards.UiScreen`, `AshUITutorials.SafeOverlaysAndGuards.UiElement`, `AshUITutorials.SafeOverlaysAndGuards.UiBinding`
- authoritative screen builders: `AshUITutorials.SafeOverlaysAndGuards.Examples.ServicesScreen`, `AshUITutorials.SafeOverlaysAndGuards.Examples.IncidentsScreen`
- guard surfaces: `AshUITutorials.SafeOverlaysAndGuards.Examples.GuardedActionsPanelElement`, `AshUITutorials.SafeOverlaysAndGuards.Examples.GuardedActionsMenuElement`, `AshUITutorials.SafeOverlaysAndGuards.Examples.GuardOverlayElement`, `AshUITutorials.SafeOverlaysAndGuards.Examples.ResolveGuardDialogElement`, `AshUITutorials.SafeOverlaysAndGuards.Examples.RestartGuardAlertElement`
- guard triggers: `AshUITutorials.SafeOverlaysAndGuards.Examples.OpenResolveGuardButtonElement`, `AshUITutorials.SafeOverlaysAndGuards.Examples.OpenRestartGuardButtonElement`, `AshUITutorials.SafeOverlaysAndGuards.Examples.OpenSilenceGuardButtonElement`, `AshUITutorials.SafeOverlaysAndGuards.Examples.OpenDiscardNoteGuardButtonElement`, `AshUITutorials.SafeOverlaysAndGuards.Examples.DismissGuardToastButtonElement`
- LiveView hosts: `AshUITutorials.SafeOverlaysAndGuards.Web.ServicesLive`, `AshUITutorials.SafeOverlaysAndGuards.Web.IncidentsLive`

## Run The Checkpoint

From
[`tutorials/code/05-safe-overlays-and-guards/`](../code/05-safe-overlays-and-guards/):

```bash
mix deps.get
mix example.start
```

The default command starts `live_ui` through the Phoenix LiveView host at
`http://127.0.0.1:5000/`.

Use:

- `/` for the services workspace
- `/incidents` for the incidents workspace with the guard panel

Alternate runtime previews remain available:

```bash
mix example.start elm_ui
mix example.start desktop_ui
```

They all rely on the same authoritative screen graph and guard-state model.

## What To Carry Into Chapter 6

Chapter 5 proves that overlays and confirmations can live inside the same
resource-backed architecture as forms, filters, and shared detail state.

Chapter 6 keeps those guarded flows intact, but it adds a new kind of operator
surface: runbooks and attachment review that sit beside the live incident work.
