# Authorization

Shared policy helpers, resource policy checks, and runtime authorization enforcement for Ash UI.

## Intent

Define how Ash UI authorizes screen, element, binding, and action access across both Ash resource policies and runtime LiveView flows.

```spec-meta
id: ash_ui.authorization
kind: policy
status: active
summary: Shared policy helpers, resource policy enforcement, and runtime authorization with structured failures and caching.
surface:
  - guides/user/UG-0006-authorization-and-runtime-safety.md
  - guides/developer/DG-0004-runtime-bindings-and-authorization.md
  - specs/contracts/authorization_contract.md
  - lib/ash_ui/authorization/checks/screen_access.ex
  - lib/ash_ui/authorization/checks/element_access.ex
  - lib/ash_ui/authorization/checks/binding_access.ex
  - lib/ash_ui/authorization/policies.ex
  - lib/ash_ui/authorization/screen_policy.ex
  - lib/ash_ui/authorization/element_policy.ex
  - lib/ash_ui/authorization/binding_policy.ex
  - lib/ash_ui/authorization/runtime.ex
  - lib/ash_ui/authorization/policy_dsl.ex
  - lib/ash_ui/authorization/error.ex
  - lib/ash_ui/authorization/subject.ex
```

## Requirements

```spec-requirements
- id: ash_ui.authorization.policy_helpers
  statement: Shared authorization helpers and policy DSL functions shall evaluate user activity, roles, ownership, visibility, resource access, and binding source access for Ash UI resources.
  priority: must
  stability: stable
- id: ash_ui.authorization.resource_policy_enforcement
  statement: Screen, element, and binding resources shall enforce read and manage access through Ash policy checks using owner, public, role, and admin semantics.
  priority: must
  stability: stable
- id: ash_ui.authorization.runtime_checks_and_cache
  statement: Runtime authorization shall gate screen mounts, actions, and binding reads or writes, return structured forbidden reasons, and cache policy decisions by user, resource, and action.
  priority: must
  stability: evolving
```

## Verification

```spec-verification
- kind: command
  target: mix test test/ash_ui/authorization/policies_test.exs test/ash_ui/authorization/resource_policies_test.exs test/ash_ui/authorization/policy_dsl_test.exs
  execute: true
  covers:
    - ash_ui.authorization.policy_helpers
    - ash_ui.authorization.resource_policy_enforcement
- kind: command
  target: mix test test/ash_ui/authorization/resource_authorizer_test.exs test/ash_ui/authorization/runtime_test.exs test/ash_ui/authorization/error_test.exs
  execute: true
  covers:
    - ash_ui.authorization.resource_policy_enforcement
    - ash_ui.authorization.runtime_checks_and_cache
- kind: command
  target: mix test test/ash_ui/authorization/phase_5_integration_test.exs
  execute: true
  covers:
    - ash_ui.authorization.policy_helpers
    - ash_ui.authorization.resource_policy_enforcement
    - ash_ui.authorization.runtime_checks_and_cache
```
