# Chapter 5 - Safe Overlays and Guards

## Code For This Chapter

Checkpoint app: `tutorials/code/05-safe-overlays-and-guards/`

Previous checkpoint: `tutorials/code/04-operator-actions-and-forms/`

Supporting examples: `examples/alert_dialog`, `examples/context_menu`, `examples/dialog`, `examples/toast`

This chapter is reserved for confirmation dialogs, guarded actions, and
operator feedback flows.
This chapter adds the first destructive and safety-critical interaction layer to
the operator workspace from
[`tutorials/code/04-operator-actions-and-forms/`](../code/04-operator-actions-and-forms/).

## What You Build

The checkpoint app at
[`tutorials/code/05-safe-overlays-and-guards/`](../code/05-safe-overlays-and-guards/)
keeps the same two authoritative screens from Chapter 4 and extends the
incidents workspace with a persisted guard-rail panel.

That panel uses:

- `custom:context_menu` as the authored launcher for sensitive operations
- `custom:overlay` for the silence and discard-note confirmations
- `custom:dialog` for the resolve flow
- `custom:alert_dialog` for the restart flow
- `custom:toast` for explicit post-action feedback

The key design constraint in this chapter is that guard visibility, intent,
preconditions, and feedback all stay traceable to persisted tutorial state.
The host LiveView still renders the screen, but it does not invent invisible
overlay state on the side.

## Modules and Resources Introduced

- Main checkpoint module:
  [`AshUITutorials.SafeOverlaysAndGuards`](../code/05-safe-overlays-and-guards/lib/ash_ui_tutorials/safe_overlays_and_guards.ex)
- Runtime state resource:
  `AshUITutorials.SafeOverlaysAndGuards.Runtime.WorkspaceState`
- Persisted UI resources:
  `AshUITutorials.SafeOverlaysAndGuards.UiScreen`,
  `AshUITutorials.SafeOverlaysAndGuards.UiElement`, and
  `AshUITutorials.SafeOverlaysAndGuards.UiBinding`
- Existing authoritative screen builders:
  `AshUITutorials.SafeOverlaysAndGuards.Examples.ServicesScreen` and
  `AshUITutorials.SafeOverlaysAndGuards.Examples.IncidentsScreen`
- New authored guard surfaces:
  `AshUITutorials.SafeOverlaysAndGuards.Examples.GuardedActionsPanelElement`,
  `AshUITutorials.SafeOverlaysAndGuards.Examples.GuardedActionsMenuElement`,
  `AshUITutorials.SafeOverlaysAndGuards.Examples.GuardOverlayElement`,
  `AshUITutorials.SafeOverlaysAndGuards.Examples.ResolveGuardDialogElement`,
  and `AshUITutorials.SafeOverlaysAndGuards.Examples.RestartGuardAlertElement`
- New authored confirmation triggers:
  `AshUITutorials.SafeOverlaysAndGuards.Examples.OpenResolveGuardButtonElement`,
  `AshUITutorials.SafeOverlaysAndGuards.Examples.OpenRestartGuardButtonElement`,
  `AshUITutorials.SafeOverlaysAndGuards.Examples.OpenSilenceGuardButtonElement`,
  `AshUITutorials.SafeOverlaysAndGuards.Examples.OpenDiscardNoteGuardButtonElement`,
  and `AshUITutorials.SafeOverlaysAndGuards.Examples.DismissGuardToastButtonElement`
- LiveView hosts:
  `AshUITutorials.SafeOverlaysAndGuards.Web.ServicesLive` and
  `AshUITutorials.SafeOverlaysAndGuards.Web.IncidentsLive`

The confirmation path is centered on
`AshUITutorials.SafeOverlaysAndGuards.Runtime.WorkspaceState.preview_guarded_action/1`
and `confirm_guarded_action/1`. The preview action records the chosen guard
intent and opens the correct overlay shell. The confirm action rechecks the
relevant precondition, rewrites the shared incident or service state, and emits
toast feedback without leaving the resource-first model.

## Run The Checkpoint

From
[`tutorials/code/05-safe-overlays-and-guards/`](../code/05-safe-overlays-and-guards/):

```bash
mix deps.get
mix example.start
```

The default command starts `live_ui` through the Phoenix LiveView host at
`http://127.0.0.1:5000/`. Visit `/` for the services workspace and
`/incidents` for the incidents workspace with the guard panel active.

Alternate runtime previews are still available:

```bash
mix example.start elm_ui
mix example.start desktop_ui
```

Those modes keep the same authoritative screen graph and the same guard-state
resource path, so later chapters can compare runtimes without rewriting the
overlay contract introduced here.
