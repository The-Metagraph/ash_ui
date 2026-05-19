# Ash UI Architecture Execution Plan Index

This directory contains phased implementation plans for executing and
re-executing the Ash UI architecture baseline.

The active architectural baseline is defined by:
- `specs/topology.md`
- `specs/contracts/*`
- `specs/adr/ADR-0005-element-resource-authority-and-relational-screen-composition.md`
- `specs/adr/ADR-0006-canonical-iur-and-navigation-adoption.md`
- `specs/adr/ADR-0007-canonical-widget-components-adoption.md`
- `specs/adr/ADR-0008-canonical-rail-component-adoption.md`
- `specs/adr/ADR-0009-canonical-workflow-progress-status-component-adoption.md`

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
23. [Phase 23 - Tutorial Program Scaffold, Directory Contract, and Operations Control Center Baseline](./phase-23-tutorial-program-scaffold-directory-contract-and-operations-control-center-baseline.md): define the long-form tutorial structure under `tutorials/`, the maintained tutorial app, the per-chapter code checkpoints, and the first dashboard/workspace milestones.
24. [Phase 24 - Tutorial Filtering, Search, Forms, and Safe Operator Workflows](./phase-24-tutorial-filtering-search-forms-and-safe-operator-workflows.md): implement the tutorial chapters for filtering, search, operator forms, and guarded overlay flows.
25. [Phase 25 - Tutorial Runbooks, Attachments, and Live Diagnostics](./phase-25-tutorial-runbooks-attachments-and-live-diagnostics.md): implement the tutorial chapters for runbooks, attachments, rich detail views, and streaming operational diagnostics.
26. [Phase 26 - Tutorial Topology, Navigation, and Metrics Surfaces](./phase-26-tutorial-topology-navigation-and-metrics-surfaces.md): implement the tutorial chapters for service topology, navigation workspaces, and telemetry dashboards.
27. [Phase 27 - Tutorial Runtime Introspection and Permission-Aware Operations](./phase-27-tutorial-runtime-introspection-and-permission-aware-operations.md): implement the tutorial chapters for deeper runtime inspection and role-aware operational screens.
28. [Phase 28 - Tutorial Production Polish and Final Application Consolidation](./phase-28-tutorial-production-polish-and-final-application-consolidation.md): implement the final tutorial chapter, responsive and accessibility cleanup, and the maintained final tutorial-app surface.
29. [Phase 29 - Tutorial Publication, Governance, and End-to-End Validation](./phase-29-tutorial-publication-governance-and-end-to-end-validation.md): publish the tutorial as a maintained product surface with chapter-to-code validation, release readiness, and end-to-end proof.
30. [Phase 30 - Canonical IUR And Navigation Adoption](./phase-30-canonical-iur-and-navigation-adoption.md): adopt the upgraded Unified package set, `%UnifiedIUR.Element{}` renderer boundary, and resource-authored canonical navigation intent.
31. [Phase 31 - Canonical Widget Components Adoption](./phase-31-canonical-widget-components-adoption.md): adopt the expanded Unified UI widget-component catalog as first-class Ash UI resource-authored component input.
32. [Phase 32 - Canonical Rail Component Adoption](./phase-32-canonical-rail-component-adoption.md): adopt reusable canonical `right_rail` behavior across Unified UI, Unified IUR, runtime renderers, and Ash UI without admitting app-specific document rail vocabulary.
33. [Phase 33 - Canonical Workflow Progress And Status Component Adoption](./phase-33-canonical-workflow-progress-status-component-adoption.md): rebase PR #123 and adopt `workflow_progress_status_card` as reusable canonical `:workflow_progress_and_status` vocabulary.

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
- canonical renderer input remains `unified_iur`, with `%UnifiedIUR.Element{}`
  as the Phase 30 renderer-facing target
- canonical navigation is semantic intent and must not include host routes,
  URLs, router helpers, runtime modules, or modal stack identifiers
- canonical widget components use the Unified catalog names at renderer-facing
  boundaries, with `custom:*` reserved for non-catalog application extensions
- canonical rail behavior uses reusable `right_rail` vocabulary, with document
  rails composed as application-owned panel configurations
- canonical workflow progress and status behavior uses reusable
  `workflow_progress_status_card` vocabulary, with map-surface placement and host action
  names kept application-owned
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

Phases 17-22 are complete on the current implementation branch and establish
the mirrored `examples/` suite, its Ash-HQ-derived visual baseline, and the
supporting governance and release workflows.

Phases 23-29 describe the next line: build a long-form `tutorials/`
experience around one realistic Operations Control Center application, with a
maintained final app under `tutorials/` and one standalone checkpoint app per
chapter under `tutorials/code/`.

Phase 30 describes the canonical navigation adoption line introduced by
[ADR-0006](../adr/ADR-0006-canonical-iur-and-navigation-adoption.md). It
coordinates the upgraded Unified package boundary, struct-based canonical IUR
output, resource-authored navigation intent, runtime adapter realignment, and
end-to-end conformance coverage.

Phase 31 describes the canonical widget-component adoption line introduced by
[ADR-0007](../adr/ADR-0007-canonical-widget-components-adoption.md). It adopts
the expanded Unified component catalog through Ash resource admission,
canonical conversion, runtime adapter support, list-repeat composition, and
documentation/conformance coverage.

Phase 32 describes the canonical rail adoption line introduced by
[ADR-0008](../adr/ADR-0008-canonical-rail-component-adoption.md). It adopts a
reusable `right_rail` component through Unified UI DSL/compiler support,
Unified IUR constructor and validation support, Ash resource conversion,
runtime renderer handling, documentation, examples, and conformance coverage.

Phase 33 describes the canonical workflow progress and status adoption line
introduced by
[ADR-0009](../adr/ADR-0009-canonical-workflow-progress-status-component-adoption.md).
It rebases PR #123 and adopts `workflow_progress_status_card` through catalog and family
alignment, Unified IUR validation, Ash resource conversion, runtime renderer
handling, documentation, examples, and conformance coverage.
