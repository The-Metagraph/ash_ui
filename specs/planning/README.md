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
16. [Phase 16 - Example, Guide, And Conformance Realignment](./phase-16-example-guide-and-conformance-realignment.md): realign public docs, governance, and conformance after removing the checked-in flagship example.
17. [Phase 17 - Ash UI Example Suite Scaffold, Catalog Crosswalk, and Ash HQ Theme Baseline](./phase-17-ash-ui-example-suite-scaffold-catalog-crosswalk-and-ash-hq-theme-baseline.md): define the mirrored example-suite catalog, the resource-authority app template, and the shared Ash HQ-inspired theme baseline.
18. [Phase 18 - Foundational Content, Form, and Input Example Apps](./phase-18-foundational-content-form-and-input-example-apps.md): implement the baseline Ash UI examples for foundational content, form scaffolding, and input controls through resource-first screen and element modules.
19. [Phase 19 - Layout, Navigation, and Display Example Apps](./phase-19-layout-navigation-and-display-example-apps.md): implement the layout, navigation, and display-system examples together with any public widget-vocabulary expansions they require.
20. [Phase 20 - Overlay, Data, Feedback, Chart, and Operational Example Apps](./phase-20-overlay-data-feedback-chart-and-operational-example-apps.md): implement the higher-complexity overlay, data-surface, feedback, chart, and operational examples.
21. [Phase 21 - Example Suite Tooling, Catalog, and Validation Workflow](./phase-21-example-suite-tooling-catalog-and-validation-workflow.md): implement suite discovery, launcher, validation, and governance workflows for the Ash UI example catalog.
22. [Phase 22 - Documentation, Governance, and Full Suite Integration](./phase-22-documentation-governance-and-full-suite-integration.md): finish the public docs, release gates, and full-suite integration coverage for the Ash UI example suite.

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

Phases 13-15 are complete on the current implementation branch and restore
element-resource authority, relational composition, and graph-derived
compilation/runtime behavior.

Phase 16 is partially complete. The checked-in flagship example has been
removed and the public example surface is now intentionally empty, but the
remaining public-surface integration coverage and closeout tracking in that
phase are still open.

Phases 17-22 describe the proposed next line after that reset: rebuild a full
`examples/` suite that mirrors the sibling `unified_ui` catalog through Ash UI
resource-authority screens and element resources, using the current
`ash-hq.org` visual language as the shared style baseline.
