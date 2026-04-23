# Compiler

Compilation from persisted Ash UI screens into the internal IUR with caching and authoritative graph regeneration.

## Intent

Define the current compiler boundary for resource-authority screens, including IUR assembly, binding extraction, and cache behavior.

```spec-meta
id: ash_ui.compiler
kind: workflow
status: active
summary: Compiles persisted screens into AshUI.Compilation.IUR while preserving the authoritative resource graph and cache semantics.
surface:
  - README.md
  - guides/user/UG-0001-getting-started.md
  - guides/user/UG-0002-authoring-screens-elements-and-relationships.md
  - guides/user/UG-0005-liveview-runtime-and-rendering.md
  - guides/developer/DG-0003-compiler-canonical-iur-and-renderers.md
  - specs/contracts/compilation_contract.md
  - lib/ash_ui/compiler.ex
  - lib/ash_ui/compilation/iur.ex
  - lib/ash_ui/compiler/extensions.ex
  - lib/ash_ui/compiler/incremental.ex
```

## Requirements

```spec-requirements
- id: ash_ui.compiler.resource_authority_compilation
  statement: The compiler shall compile persisted screen records and supported resource-authority payloads into valid AshUI.Compilation.IUR output using the current authoritative screen and element resource graph.
  priority: must
  stability: stable
- id: ash_ui.compiler.widget_and_binding_extraction
  statement: Compilation shall preserve authored widget hierarchy, screen overrides, and binding metadata in the resulting IUR.
  priority: must
  stability: stable
- id: ash_ui.compiler.cache_and_invalidations
  statement: Compiler caching shall reuse unchanged authoritative graphs, ignore serialized snapshot drift, expose cache stats, and invalidate when screen versions or screen-level overrides change.
  priority: must
  stability: evolving
```

## Verification

```spec-verification
- kind: command
  target: mix test test/ash_ui/compiler_test.exs
  execute: true
  covers:
    - ash_ui.compiler.resource_authority_compilation
    - ash_ui.compiler.widget_and_binding_extraction
    - ash_ui.compiler.cache_and_invalidations
- kind: command
  target: mix test test/ash_ui/compiler/extensions_test.exs test/ash_ui/compiler/incremental_test.exs test/ash_ui/compiler/relationship_semantics_test.exs
  execute: true
  covers:
    - ash_ui.compiler.resource_authority_compilation
    - ash_ui.compiler.widget_and_binding_extraction
    - ash_ui.compiler.cache_and_invalidations
- kind: command
  target: mix test test/ash_ui/compiler/phase_6_integration_test.exs
  execute: true
  covers:
    - ash_ui.compiler.resource_authority_compilation
    - ash_ui.compiler.widget_and_binding_extraction
    - ash_ui.compiler.cache_and_invalidations
- kind: command
  target: mix test test/ash_ui/phase_11_integration_test.exs
  execute: true
  covers:
    - ash_ui.compiler.resource_authority_compilation
    - ash_ui.compiler.widget_and_binding_extraction
    - ash_ui.compiler.cache_and_invalidations
- kind: command
  target: mix test test/ash_ui/phase_15_integration_test.exs
  execute: true
  covers:
    - ash_ui.compiler.resource_authority_compilation
    - ash_ui.compiler.widget_and_binding_extraction
    - ash_ui.compiler.cache_and_invalidations
```
