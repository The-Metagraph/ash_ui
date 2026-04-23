# Storage And Resources

Configurable Ash storage and the shipped persistence resources that back Ash UI screens, elements, and bindings.

## Intent

Define the runtime storage boundary that Ash UI uses for CRUD, compilation input, binding lookup, and persisted screen payload validation.

```spec-meta
id: ash_ui.storage
kind: workflow
status: active
summary: Configurable UI storage boundary with default Screen, Element, and Binding resources plus write-time validation.
surface:
  - guides/user/UG-0001-getting-started.md
  - guides/user/UG-0002-authoring-screens-elements-and-relationships.md
  - guides/developer/DG-0002-storage-resource-authority-and-configuration.md
  - specs/contracts/resource_contract.md
  - lib/ash_ui/config.ex
  - lib/ash_ui/data.ex
  - lib/ash_ui/dsl/storage.ex
  - lib/ash_ui/domain.ex
  - lib/ash_ui/repo.ex
  - lib/ash_ui/resources/screen.ex
  - lib/ash_ui/resources/element.ex
  - lib/ash_ui/resources/binding.ex
  - lib/ash_ui/resources/validations/unified_dsl.ex
  - lib/ash_ui/resources/validations/binding_source.ex
```

## Requirements

```spec-requirements
- id: ash_ui.storage.configurable_ui_storage
  statement: Ash UI shall resolve screen, element, binding, repo, and runtime-domain access through configurable UI storage settings instead of hard-coding one persistence boundary.
  priority: must
  stability: stable
- id: ash_ui.storage.default_persistence_resources
  statement: The package shall ship default Screen, Element, and Binding resources with versioned CRUD, screen/element/binding relationships, and cascade behavior for owned children.
  priority: must
  stability: stable
- id: ash_ui.storage.write_time_validation
  statement: Screen unified_dsl writes and binding source writes shall be validated against the supported persisted payload and binding-source contracts before storage.
  priority: must
  stability: stable
```

## Verification

```spec-verification
- kind: command
  target: mix test test/ash_ui/pluggable_ui_storage_test.exs test/ash_ui/resources/screen_test.exs
  execute: true
  covers:
    - ash_ui.storage.configurable_ui_storage
    - ash_ui.storage.default_persistence_resources
    - ash_ui.storage.write_time_validation
- kind: command
  target: mix test test/ash_ui/resources/element_test.exs test/ash_ui/resources/binding_test.exs
  execute: true
  covers:
    - ash_ui.storage.default_persistence_resources
    - ash_ui.storage.write_time_validation
- kind: command
  target: mix test test/ash_ui/dsl/storage_test.exs
  execute: true
  covers:
    - ash_ui.storage.write_time_validation
```
