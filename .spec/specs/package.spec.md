# Ash UI Package

High-level package contract for Ash UI.

```spec-meta
id: ash_ui.package
kind: package
status: active
summary: Ash UI provides resource-first UI authoring on Ash plus compilation and runtime integration surfaces.
surface:
  - README.md
  - guides/developer/DG-0001-architecture-and-control-planes.md
  - mix.exs
  - lib/ash_ui.ex
  - lib/ash_ui/application.ex
  - lib/ash_ui/authoring.ex
  - lib/ash_ui/compiler.ex
```

## Requirements

```spec-requirements
- id: ash_ui.package.bootstrap_contract
  statement: The package shall provide resource-first UI authoring on Ash along with compilation and runtime integration surfaces for Ash UI applications.
  priority: must
  stability: evolving
```

## Verification

```spec-verification
- kind: source_file
  target: README.md
  covers:
    - ash_ui.package.bootstrap_contract
- kind: source_file
  target: lib/ash_ui.ex
  covers:
    - ash_ui.package.bootstrap_contract
```
