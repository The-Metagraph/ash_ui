# Binding Runtime

Typed binding declarations and the runtime paths that evaluate, write, update, and execute them.

## Intent

Define the supported binding shapes and the runtime behavior for value, list, and action flows in Ash UI.

```spec-meta
id: ash_ui.bindings
kind: workflow
status: active
summary: Typed binding declarations, runtime evaluation, bidirectional writes, collection updates, and action execution.
surface:
  - guides/user/UG-0003-widget-types-properties-and-signals.md
  - guides/user/UG-0004-bindings-actions-and-forms.md
  - specs/contracts/binding_contract.md
  - lib/ash_ui/binding/actions.ex
  - lib/ash_ui/dsl/binding.ex
  - lib/ash_ui/resources/binding.ex
  - lib/ash_ui/resources/validations/binding_source.ex
  - lib/ash_ui/runtime/resource_access.ex
  - lib/ash_ui/runtime/binding_evaluator.ex
  - lib/ash_ui/runtime/bidirectional_binding.ex
  - lib/ash_ui/runtime/list_binding.ex
  - lib/ash_ui/runtime/action_binding.ex
```

## Requirements

```spec-requirements
- id: ash_ui.bindings.typed_source_contract
  statement: Bindings shall support validated :value, :list, and :action declarations through compile-time helper DSLs, structured source maps, targets, and persisted binding records.
  priority: must
  stability: stable
- id: ash_ui.bindings.runtime_resolution_and_transforms
  statement: Binding evaluation shall resolve field, relationship, and action sources against Ash resources through actor-aware runtime resource access and apply supported transformation helpers to the resolved value.
  priority: must
  stability: evolving
- id: ash_ui.bindings.runtime_update_flows
  statement: The binding runtime shall support sanitized bidirectional writes, paginated list loading and change handling, and mapped action execution including element-declared actions normalized through the action-binding path.
  priority: must
  stability: evolving
```

## Verification

```spec-verification
- kind: command
  target: mix test test/ash_ui/resources/binding_test.exs test/ash_ui/runtime/binding_evaluator_test.exs
  execute: true
  covers:
    - ash_ui.bindings.typed_source_contract
    - ash_ui.bindings.runtime_resolution_and_transforms
- kind: command
  target: mix test test/ash_ui/runtime/bidirectional_binding_test.exs test/ash_ui/runtime/list_binding_test.exs test/ash_ui/runtime/action_binding_test.exs
  execute: true
  covers:
    - ash_ui.bindings.runtime_resolution_and_transforms
    - ash_ui.bindings.runtime_update_flows
- kind: command
  target: mix test test/ash_ui/phase_13_integration_test.exs
  execute: true
  covers:
    - ash_ui.bindings.runtime_resolution_and_transforms
    - ash_ui.bindings.runtime_update_flows
```
