# Ash UI Architecture Execution Plan Index

This directory contains a phased implementation plan for executing the Ash UI architecture baseline aligned with the unified-ui ecosystem.

The plan aligns to:
- `rfcs/RFC-0002-ash-ui-unified-integration.md`
- `specs/topology.md`
- `specs/contracts/*`
- `specs/conformance/*`

## Phase Files
1. [Phase 1 - Core Ash Resource Integration](./phase-01-core-ash-resource-integration.md): implement Ash Resources for storing unified-ui DSL definitions with Ash actions and policies.
2. [Phase 2 - IUR Adapter and Canonical Conversion](./phase-02-iur-adapter-and-canonical-conversion.md): implement Ash IUR to canonical unified_iur conversion.
3. [Phase 3 - Data Binding and Signal Mapping](./phase-03-data-binding-and-signal-mapping.md): implement Ash resource data binding to unified-ui signals.
4. [Phase 4 - Runtime and LiveView Integration](./phase-04-runtime-and-liveview-integration.md): implement LiveView mount/unmount and screen lifecycle.
5. [Phase 5 - Authorization and Policy Enforcement](./phase-05-authorization-and-policy-enforcement.md): implement Ash policy integration for UI access control.
6. [Phase 6 - Compiler and DSL Integration](./phase-06-compiler-and-dsl-integration.md): integrate unified-ui compiler with Ash Resource loading.
7. [Phase 7 - Renderer Package Integration](./phase-07-renderer-package-integration.md): implement live_ui/elm_ui/desktop_ui package integration.
8. [Phase 8 - Governance Gates and Release Readiness](./phase-08-governance-gates-and-release-readiness.md): finalize CI gates, conformance tests, and rollout readiness.
9. [Phase 9 - Unified UI DSL Authority](./phase-09-unified-ui-dsl-authority.md): make upstream `unified_ui` the authoritative authoring DSL boundary.
10. [Phase 10 - Persisted DSL Migration](./phase-10-persisted-dsl-migration.md): migrate `Screen.unified_dsl` from Ash UI-owned builder maps to serialized upstream `unified_ui` documents.
11. [Phase 11 - Upstream Compiler Delegation](./phase-11-upstream-compiler-delegation.md): delegate DSL compilation to upstream `unified_ui` while preserving Ash bindings and runtime behavior.
12. [Phase 12 - Example, Tooling, and Conformance Migration](./phase-12-example-tooling-and-conformance-migration.md): move examples, docs, and governance to the upstream DSL model and close the gap.

## Shared Conventions
- Numbering:
  - Phases: `N`
  - Sections: `N.M`
  - Tasks: `N.M.K`
  - Subtasks: `N.M.K.L`
- Tracking:
  - Every phase, section, task, and subtask uses Markdown checkboxes (`[ ]`).
- Description requirement:
  - Every phase, section, and task starts with a short description paragraph.
- Integration-test requirement:
  - Each phase ends with a final integration-testing section.

## Shared Assumptions and Defaults
- Ash UI remains an Ash Framework integration layer for unified-ui
- UI definitions are stored as Ash Resources in the database
- unified-ui packages provide widgets, layouts, compilation, and rendering
- Ash policies control access to UI resources
- Data flows from Ash resources → Ash IUR → canonical IUR → renderer output
- Upstream `unified_ui` owns the authoring DSL and authoring compiler

## Status Note

The phase files are historical planning documents that track the implementation baseline captured in this repository. After the post-Phase-8 remediation work, the previously open Phase 1 DSL/lifecycle gap and Phase 7 renderer package gap were closed in-repo.

A major architecture gap remains open, however: the current implementation still uses `AshUI.DSL.Builder` as the effective authoring DSL instead of the upstream `unified_ui` extension and compiler. The new Phase 9-12 remediation track exists to close that gap and realign the implementation with the normative architecture.
