# Legacy Migration

Deterministic migration from legacy builder payloads and the current hard cut that keeps runtime compilation on resource-authority screens.

## Intent

Define the migration-only path for builder-authored screens without re-opening the legacy format as a supported runtime compiler input.

```spec-meta
id: ash_ui.legacy_migration
kind: workflow
status: active
summary: Dry-run and persisted migration helpers for legacy builder DSL plus the current compiler hard cut and legacy-use signaling.
surface:
  - guides/user/UG-0008-migration-from-older-ash-ui-models.md
  - specs/planning/phase-10-persisted-dsl-migration.md
  - lib/ash_ui/authoring/document.ex
  - lib/ash_ui/authoring/migrator.ex
  - lib/ash_ui/authoring/legacy_builder.ex
  - lib/ash_ui/dsl/builder.ex
```

## Requirements

```spec-requirements
- id: ash_ui.legacy_migration.builder_helpers_emit_legacy_dsl
  statement: AshUI.DSL.Builder shall continue to produce deterministic legacy unified_dsl maps with widget defaults and signal shorthands so migration tooling can ingest historical builder-authored screens.
  priority: must
  stability: stable
- id: ash_ui.legacy_migration.dry_run_and_document
  statement: The migrator shall inspect legacy builder payloads, report unsupported widgets, and wrap supported payloads into deterministic Phase 10 authoring documents and screen attrs without mutating the authored input.
  priority: must
  stability: stable
- id: ash_ui.legacy_migration.legacy_builder_signal
  statement: Legacy builder usage shall emit the canonical legacy-authoring telemetry signal and publish explicit removal criteria so builder-first authoring remains migration-only.
  priority: should
  stability: stable
- id: ash_ui.legacy_migration.current_compiler_cutoff
  statement: The current compiler shall reject migrated Phase 10 unified_ui documents as active runtime compiler input so resource-authority screens remain the supported compilation boundary.
  priority: must
  stability: stable
```

## Verification

```spec-verification
- kind: command
  target: mix test test/ash_ui/dsl/builder_test.exs test/ash_ui/dsl/builder_legacy_test.exs
  execute: true
  covers:
    - ash_ui.legacy_migration.builder_helpers_emit_legacy_dsl
    - ash_ui.legacy_migration.legacy_builder_signal
- kind: command
  target: mix test test/ash_ui/authoring/migrator_test.exs test/ash_ui/dsl/builder_legacy_test.exs
  execute: true
  covers:
    - ash_ui.legacy_migration.builder_helpers_emit_legacy_dsl
    - ash_ui.legacy_migration.dry_run_and_document
    - ash_ui.legacy_migration.legacy_builder_signal
    - ash_ui.legacy_migration.current_compiler_cutoff
- kind: command
  target: mix test test/ash_ui/phase_10_integration_test.exs
  execute: true
  covers:
    - ash_ui.legacy_migration.dry_run_and_document
    - ash_ui.legacy_migration.current_compiler_cutoff
```
