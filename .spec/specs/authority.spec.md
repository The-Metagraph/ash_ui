# Resource Authority

Resource-local Ash UI DSL, introspection, and persisted resource-authority payload generation.

## Intent

Capture how screen and element resources become the authored source of truth and how Ash UI serializes that authority graph into persisted screen state.

```spec-meta
id: ash_ui.authority
kind: workflow
status: active
summary: Resource-local DSL definitions, introspection helpers, and resource-authority payload generation for screens and elements.
surface:
  - README.md
  - guides/user/UG-0001-getting-started.md
  - guides/user/UG-0002-authoring-screens-elements-and-relationships.md
  - guides/developer/DG-0002-storage-resource-authority-and-configuration.md
  - specs/contracts/resource_contract.md
  - lib/ash_ui/authoring/extensions.ex
  - lib/ash_ui/dsl/screen.ex
  - lib/ash_ui/dsl/element.ex
  - lib/ash_ui/resource/dsl.ex
  - lib/ash_ui/resource/dsl/helpers.ex
  - lib/ash_ui/resource/authority.ex
  - lib/ash_ui/resource/info.ex
  - lib/ash_ui/resource/dsl/screen.ex
  - lib/ash_ui/resource/dsl/element.ex
  - lib/ash_ui/resource/dsl/binding.ex
  - lib/ash_ui/resource/dsl/relationship.ex
  - lib/ash_ui/resources/validations/authoring.ex
```

## Requirements

```spec-requirements
- id: ash_ui.authority.resource_local_authority
  statement: Screen and element resources shall expose validated compile-time definitions, bindings, actions, and relationship semantics through the supported AshUI.Resource.DSL.* surface plus the lightweight AshUI.DSL.* attribute helpers and AshUI.Resource.Info.
  priority: must
  stability: stable
- id: ash_ui.authority.persisted_screen_payload
  statement: AshUI.Resource.Authority shall derive versioned persisted screen attrs and payloads from authoritative screen resource modules rather than requiring applications to hand-author unified_dsl snapshots.
  priority: must
  stability: stable
- id: ash_ui.authority.relationship_driven_graph
  statement: Resource-authority payload generation shall preserve relationship-driven composition order, kind, slot, placement, screen-scoped bindings, and inline screen fragments.
  priority: must
  stability: evolving
```

## Verification

```spec-verification
- kind: command
  target: mix test test/ash_ui/resource/authority_test.exs test/ash_ui/resource/locality_test.exs
  execute: true
  covers:
    - ash_ui.authority.resource_local_authority
    - ash_ui.authority.persisted_screen_payload
    - ash_ui.authority.relationship_driven_graph
- kind: command
  target: mix test test/ash_ui/dsl_integration_test.exs test/ash_ui/relationship_integration_test.exs
  execute: true
  covers:
    - ash_ui.authority.resource_local_authority
    - ash_ui.authority.relationship_driven_graph
- kind: command
  target: mix test test/ash_ui/phase_13_integration_test.exs test/ash_ui/phase_14_integration_test.exs
  execute: true
  covers:
    - ash_ui.authority.resource_local_authority
    - ash_ui.authority.persisted_screen_payload
    - ash_ui.authority.relationship_driven_graph
- kind: command
  target: mix test test/ash_ui/phase_9_integration_test.exs
  execute: true
  covers:
    - ash_ui.authority.resource_local_authority
    - ash_ui.authority.persisted_screen_payload
```
