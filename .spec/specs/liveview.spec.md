# LiveView Runtime

Mount, event, hydration, subscription, and lifecycle behavior for Ash UI screens in Phoenix LiveView.

## Intent

Define the shipped LiveView integration layer that loads screens, hydrates bindings, handles user events, and reacts to Ash resource updates.

```spec-meta
id: ash_ui.liveview
kind: workflow
status: active
summary: LiveView screen mounting, event routing, binding hydration, reactive updates, and lifecycle hooks.
surface:
  - guides/user/UG-0001-getting-started.md
  - guides/user/UG-0004-bindings-actions-and-forms.md
  - guides/user/UG-0005-liveview-runtime-and-rendering.md
  - guides/user/UG-0006-authorization-and-runtime-safety.md
  - guides/developer/DG-0004-runtime-bindings-and-authorization.md
  - lib/ash_ui/notifications.ex
  - lib/ash_ui/liveview/binding_runtime.ex
  - lib/ash_ui/liveview/error_handler.ex
  - lib/ash_ui/liveview/liveview_integration.ex
  - lib/ash_ui/liveview/event_handler.ex
  - lib/ash_ui/liveview/update_integration.ex
  - lib/ash_ui/liveview/hooks.ex
  - lib/ash_ui/liveview/iur_hydration.ex
  - lib/ash_ui/liveview/lifecycle.ex
```

## Requirements

```spec-requirements
- id: ash_ui.liveview.mount_and_hydration
  statement: LiveView integration shall load screens by id or name, authorize the mount, compile to canonical IUR, evaluate bindings, and hydrate the current binding state onto the compiled tree.
  priority: must
  stability: stable
- id: ash_ui.liveview.event_routing
  statement: LiveView event handling shall parse change, click, and submit events, route them to the correct binding or action path, and enforce owning element identity for element-local bindings and declared actions.
  priority: must
  stability: evolving
- id: ash_ui.liveview.error_handling_and_recovery
  statement: LiveView runtime helpers shall handle compilation, binding, action, authorization, and unexpected runtime failures without crashing the session, assign user-facing error state, and expose recovery hints when appropriate.
  priority: must
  stability: evolving
- id: ash_ui.liveview.reactive_updates_and_hooks
  statement: LiveView hooks and update integration shall initialize Ash UI assigns, register and execute callbacks, subscribe to Ash notifications, handle resource changes, and clean up session state on unmount.
  priority: must
  stability: evolving
```

## Verification

```spec-verification
- kind: command
  target: mix test test/ash_ui/liveview/liveview_integration_test.exs test/ash_ui/liveview/iur_hydration_test.exs
  execute: true
  covers:
    - ash_ui.liveview.mount_and_hydration
- kind: command
  target: mix test test/ash_ui/liveview/event_handler_test.exs test/ash_ui/liveview/update_integration_test.exs test/ash_ui/liveview/hooks_test.exs test/ash_ui/liveview/lifecycle_test.exs
  execute: true
  covers:
    - ash_ui.liveview.event_routing
    - ash_ui.liveview.reactive_updates_and_hooks
- kind: command
  target: mix test test/ash_ui/liveview/error_handler_test.exs test/ash_ui/liveview/phase_4_integration_test.exs
  execute: true
  covers:
    - ash_ui.liveview.mount_and_hydration
    - ash_ui.liveview.event_routing
    - ash_ui.liveview.error_handling_and_recovery
    - ash_ui.liveview.reactive_updates_and_hooks
- kind: command
  target: mix test test/ash_ui/phase_15_integration_test.exs
  execute: true
  covers:
    - ash_ui.liveview.mount_and_hydration
    - ash_ui.liveview.event_routing
    - ash_ui.liveview.reactive_updates_and_hooks
```
