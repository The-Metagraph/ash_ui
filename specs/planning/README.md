# Ash UI Architecture Execution Plan Index

This directory contains phased implementation plans for executing and
re-executing the Ash UI architecture baseline.

The active architectural baseline is defined by:
- `specs/topology.md`
- `specs/contracts/*`
- `specs/adr/ADR-0005-element-resource-authority-and-relational-screen-composition.md`

## Phase Files
1. [Phase 1 - Core Ash Resource Integration](./phase-01-core-ash-resource-integration.md): implement Ash Resources for storing unified-ui DSL definitions with Ash actions and policies.
2. [Phase 2 - IUR Adapter and Canonical Conversion](./phase-02-iur-adapter-and-canonical-conversion.md): implement Ash IUR to canonical unified_iur conversion.
3. [Phase 3 - Data Binding and Signal Mapping](./phase-03-data-binding-and-signal-mapping.md): implement Ash resource data binding to unified-ui signals.
4. [Phase 4 - Runtime and LiveView Integration](./phase-04-runtime-and-liveview-integration.md): implement LiveView mount/unmount and screen lifecycle.
5. [Phase 5 - Authorization and Policy Enforcement](./phase-05-authorization-and-policy-enforcement.md): implement Ash policy integration for UI access control.
6. [Phase 6 - Compiler and DSL Integration](./phase-06-compiler-and-dsl-integration.md): historical compiler integration phase.
7. [Phase 7 - Renderer Package Integration](./phase-07-renderer-package-integration.md): implement live_ui/elm_ui/desktop_ui package integration.
8. [Phase 8 - Governance Gates and Release Readiness](./phase-08-governance-gates-and-release-readiness.md): finalize CI gates, conformance tests, and rollout readiness.
9. [Phase 9 - Unified UI DSL Authority](./phase-09-unified-ui-dsl-authority.md): historical phase that elevated upstream `unified_ui` to top-level authoring authority.
10. [Phase 10 - Persisted DSL Migration](./phase-10-persisted-dsl-migration.md): historical migration into screen-document authority.
11. [Phase 11 - Upstream Compiler Delegation](./phase-11-upstream-compiler-delegation.md): historical compiler delegation phase under the superseded model.
12. [Phase 12 - Example, Tooling, and Conformance Migration](./phase-12-example-tooling-and-conformance-migration.md): historical docs/example migration under the superseded model.
13. [Phase 13 - Element Resource Authority](./phase-13-element-resource-authority.md): restore Ash resources plus the `AshUI` extension as the primary authoring units.
14. [Phase 14 - Relational Screen Composition](./phase-14-relational-screen-composition.md): restore screen composition through Ash relationships while retaining optional inline DSL.
15. [Phase 15 - Compiler And Runtime Graph Realignment](./phase-15-compiler-and-runtime-graph-realignment.md): rebuild compilation and hydration around the screen/element resource graph.
16. [Phase 16 - Example, Guide, And Conformance Realignment](./phase-16-example-guide-and-conformance-realignment.md): move examples, docs, and governance back to the resource-first model.

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

## Shared Assumptions And Defaults
- Ash UI is an Ash-resource-native UI framework
- screen and element resources using the `AshUI` extension are the authoritative
  authoring surface
- relationships are the primary composition mechanism
- direct DSL composition is still allowed at the screen boundary where useful
- upstream `unified_ui` provides embedded widget/layout/theming DSL constructs
  and lowering semantics
- canonical renderer input remains `unified_iur`
- no backward-compatibility requirement applies to the superseded monolithic
  screen-document authority model

## Status Note

Phases 9-12 are now historical implementation records, not the current target
state. They captured a detour that elevated monolithic screen documents and
upstream top-level DSL authority over the Ash resource graph.

[ADR-0005](../adr/ADR-0005-element-resource-authority-and-relational-screen-composition.md)
supersedes that direction and reopens the architecture as a new remediation
line in Phases 13-16.

That remediation line is now complete on the current implementation branch:
Phases 13-16 restore element-resource authority, relational composition,
graph-derived compilation/runtime behavior, and public example/governance
alignment.
