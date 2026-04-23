# Rendering

Canonical IUR conversion, renderer discovery, runtime selection, and adapter-backed output generation.

## Intent

Define how Ash UI turns compiled IUR into renderer-facing canonical data and how it selects and invokes liveview, elm, and desktop renderers.

```spec-meta
id: ash_ui.rendering
kind: workflow
status: active
summary: Canonical IUR conversion plus renderer registry, selection, and adapter-backed output generation.
surface:
  - README.md
  - guides/user/UG-0001-getting-started.md
  - guides/user/UG-0003-widget-types-properties-and-signals.md
  - guides/user/UG-0005-liveview-runtime-and-rendering.md
  - guides/user/UG-0007-data-surfaces-and-composition-patterns.md
  - guides/developer/DG-0003-compiler-canonical-iur-and-renderers.md
  - specs/contracts/rendering_contract.md
  - lib/ash_ui/rendering/conversion_error.ex
  - lib/ash_ui/rendering/iur_adapter.ex
  - lib/ash_ui/rendering/validation.ex
  - lib/ash_ui/rendering/live_ui_adapter.ex
  - lib/ash_ui/rendering/elm_ui_adapter.ex
  - lib/ash_ui/rendering/desktop_ui_adapter.ex
  - lib/ash_ui/rendering/registry.ex
  - lib/ash_ui/rendering/selector.ex
```

## Requirements

```spec-requirements
- id: ash_ui.rendering.canonical_conversion
  statement: AshUI.Rendering.IURAdapter shall validate internal IUR, convert it into canonical screen and widget structures, and report structured conversion errors without leaking Ash-owned child metadata into renderer-facing nodes.
  priority: must
  stability: stable
- id: ash_ui.rendering.registry_and_fallback_modes
  statement: The renderer registry shall distinguish external package availability from adapter fallback renderability and expose the resolved module and mode for each renderer type.
  priority: must
  stability: stable
- id: ash_ui.rendering.selection_and_output_adapters
  statement: Rendering selection and adapter modules shall choose renderers from request and config context and render canonical screens into LiveView, Elm, and desktop outputs with renderer-specific configuration hooks.
  priority: must
  stability: evolving
```

## Verification

```spec-verification
- kind: command
  target: mix test test/ash_ui/rendering/iur_adapter_test.exs test/ash_ui/rendering/registry_test.exs test/ash_ui/rendering/selector_test.exs
  execute: true
  covers:
    - ash_ui.rendering.canonical_conversion
    - ash_ui.rendering.registry_and_fallback_modes
    - ash_ui.rendering.selection_and_output_adapters
- kind: command
  target: mix test test/ash_ui/rendering/live_ui_adapter_test.exs test/ash_ui/rendering/elm_ui_adapter_test.exs test/ash_ui/rendering/desktop_ui_adapter_test.exs
  execute: true
  covers:
    - ash_ui.rendering.canonical_conversion
    - ash_ui.rendering.selection_and_output_adapters
- kind: command
  target: mix test test/ash_ui/rendering/phase_7_integration_test.exs
  execute: true
  covers:
    - ash_ui.rendering.canonical_conversion
    - ash_ui.rendering.registry_and_fallback_modes
    - ash_ui.rendering.selection_and_output_adapters
```
