# Runtime, Bindings, And Authorization

Ash UI mounts persisted screens into LiveView, evaluates bindings, routes
events, and enforces authorization at runtime.

## Intent

Capture the runtime contract that turns the authored resource graph into mounted
screen state and protected interaction flows.

```spec-meta
id: ashui.runtime_authorization
kind: service
status: active
summary: LiveView integration loads screens, authorizes access, compiles canonical output, evaluates bindings, routes events, and emits runtime telemetry.
surface:
  - lib/ash_ui/liveview/*.ex
  - lib/ash_ui/runtime/*.ex
  - lib/ash_ui/authorization/*.ex
  - guides/user/UG-0003-data-binding.md
  - guides/user/UG-0004-authorization.md
decisions:
  - ashui.decision.control_plane_authority
  - ashui.decision.element_resource_authority
```

## Requirements

```spec-requirements
- id: ashui.runtime_authorization.mount_flow
  statement: LiveView integration shall load the target screen, authorize access, compile canonical output, evaluate bindings, assign screen state, and wire update subscriptions during mount.
  priority: must
  stability: stable
- id: ashui.runtime_authorization.binding_execution
  statement: Runtime binding helpers shall support value reads, list reads, bidirectional updates, and action execution against Ash-side sources.
  priority: must
  stability: stable
- id: ashui.runtime_authorization.runtime_authorization
  statement: Runtime authorization shall gate screen mount, action execution, binding reads, and binding writes and shall return safe forbidden outcomes rather than silently proceeding.
  priority: must
  stability: stable
- id: ashui.runtime_authorization.telemetry
  statement: Runtime mount, authorization, binding, and rendering flows shall emit telemetry events through the shared AshUI telemetry surface.
  priority: should
  stability: stable
```

## Scenarios

```spec-scenarios
- id: ashui.runtime_authorization.authorized_mount
  given:
    - a current user is present in LiveView assigns
    - a persisted screen record exists and the actor is allowed to mount it
  when:
    - AshUI.LiveView.Integration.mount_ui_screen/3 is invoked
  then:
    - the screen is authorized, compiled, hydrated, and assigned to the socket
  covers:
    - ashui.runtime_authorization.mount_flow
    - ashui.runtime_authorization.runtime_authorization
- id: ashui.runtime_authorization.binding_action_flow
  given:
    - a screen contains compiled bindings and actions
  when:
    - a user changes a value or triggers an action event
  then:
    - binding helpers resolve source data, write back when allowed, and surface action results safely
  covers:
    - ashui.runtime_authorization.binding_execution
    - ashui.runtime_authorization.runtime_authorization
    - ashui.runtime_authorization.telemetry
```

## Verification

```spec-verification
- kind: command
  target: >-
    rg -n "mount_ui_screen|authorize_screen|evaluate_bindings|sync_binding_subscriptions|Telemetry" lib/ash_ui/liveview/liveview_integration.ex lib/ash_ui/liveview/update_integration.ex lib/ash_ui/liveview/event_handler.ex
  covers:
    - ashui.runtime_authorization.mount_flow
    - ashui.runtime_authorization.telemetry
    - ashui.runtime_authorization.authorized_mount
- kind: command
  target: >-
    rg -n "check_mount_authorization|check_action_authorization|check_read_access|check_write_access|cache_policy_check" lib/ash_ui/authorization/runtime.ex guides/user/UG-0004-authorization.md
  covers:
    - ashui.runtime_authorization.runtime_authorization
    - ashui.runtime_authorization.authorized_mount
    - ashui.runtime_authorization.binding_action_flow
- kind: command
  target: >-
    rg -n "BindingEvaluator|BidirectionalBinding|ActionBinding|ListBinding|handle_value_change|handle_action_event" lib/ash_ui/runtime lib/ash_ui/liveview guides/user/UG-0003-data-binding.md
  covers:
    - ashui.runtime_authorization.binding_execution
    - ashui.runtime_authorization.binding_action_flow
- kind: command
  target: mix test test/ash_ui/liveview/phase_4_integration_test.exs test/ash_ui/runtime/action_binding_test.exs test/ash_ui/authorization/phase_5_integration_test.exs test/ash_ui/telemetry_test.exs
  covers:
    - ashui.runtime_authorization.mount_flow
    - ashui.runtime_authorization.binding_execution
    - ashui.runtime_authorization.runtime_authorization
    - ashui.runtime_authorization.telemetry
    - ashui.runtime_authorization.authorized_mount
    - ashui.runtime_authorization.binding_action_flow
```
