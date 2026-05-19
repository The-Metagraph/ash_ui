# Phase 33 - Canonical Workflow Progress And Status Component Adoption

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces

- `UnifiedUi.WidgetComponents`, `UnifiedUi.Dsl.Entities.WidgetComponents`, and
  the Unified UI compiler pipeline.
- `UnifiedIUR.Widgets.Components`, `UnifiedIUR.Element`,
  `UnifiedIUR.Normalize`, and `UnifiedIUR.Validate`.
- `AshUI.DSL.Storage`, `AshUI.Resource.DSL.Element`, and
  `AshUI.Resources.Validations.Authoring`.
- `AshUI.Compiler`, `AshUI.Rendering.IURAdapter`, and
  `AshUI.LiveView.IURHydration`.
- Runtime renderer adapters for Live, Elm, and desktop targets.
- `specs/contracts/canonical_workflow_progress_status_component_contract.md`.
- PR #123 implementation branch
  `claude/widget-repo-progress-card-wave-3-7-b`.

## Relevant Assumptions / Defaults

- ADR-0005 remains the resource-authority baseline: Ash resources own screen
  composition and domain semantics.
- ADR-0006 remains the canonical IUR and navigation baseline: renderer-facing
  roots are `%UnifiedIUR.Element{}`.
- ADR-0007 remains the canonical widget-component catalog baseline.
- ADR-0008 remains the canonical rail component package-boundary baseline.
- ADR-0009 defines `repo_progress_card` as reusable canonical
  `:workflow_progress_and_status` vocabulary.
- `repo_progress_card` is canonical; map-surface placement, audit labels, and
  host action names are application-owned.
- Concrete CSS, grid placement, colors, and runtime event names belong to hosts
  or renderers, not canonical IUR.
- Phase 33 should be implemented section by section, with one scoped commit per
  completed section and one PR at the end.

[ ] 33 Phase 33 - Canonical Workflow Progress And Status Component Adoption

This phase rebases PR #123 onto current main and turns `repo_progress_card` into
a complete canonical workflow progress and status component. It resolves the
existing merge conflicts, removes unrelated branch drift, aligns package family
metadata, adds structured repository/dependency/action validation, keeps
interactions host independent, wires runtime rendering and fallback behavior,
and closes with documentation and conformance coverage.

## [x] 33.1 Section - Rebase And Scope Hygiene

This section makes PR #123 usable as an implementation base without carrying
stale registry conflicts or unrelated wave changes.

### [x] 33.1.1 Task - Rebase The PR Branch Onto Current Main

This task updates the implementation branch and resolves conflicts against the
current canonical component registry.

- [x] 33.1.1.1 Subtask - Fetch current `main` and PR #123 head.
- [x] 33.1.1.2 Subtask - Create a Phase 33 implementation branch from current
  `main`.
- [x] 33.1.1.3 Subtask - Replay the PR #123 changes onto the Phase 33 branch.
- [x] 33.1.1.4 Subtask - Resolve conflicts in
  `packages/live_ui/lib/live_ui/renderer.ex` and
  `packages/live_ui/lib/live_ui/widgets.ex` against the current registry shape.

### [x] 33.1.2 Task - Remove Unrelated Branch Drift

This task keeps the final PR focused on `repo_progress_card`.

- [x] 33.1.2.1 Subtask - Remove unrelated `diff_banner` changes from
  `packages/unified_iur/lib/unified_iur/widgets/feedback.ex`.
- [x] 33.1.2.2 Subtask - Drop any generated `_build`, dependency, report, or
  tool-version noise.
- [x] 33.1.2.3 Subtask - Confirm the branch diff only touches canonical
  workflow progress and status adoption files.
- [x] 33.1.2.4 Subtask - Commit the clean rebase and scope baseline.

## [x] 33.2 Section - Canonical Decision And Family Boundary

This section makes the component a first-class canonical
`:workflow_progress_and_status` kind before runtime rendering is treated as
supported.

### [x] 33.2.1 Task - Align Package Catalog Metadata

This task records the canonical kind and family consistently across packages.

- [x] 33.2.1.1 Subtask - Add `repo_progress_card` to the Unified UI catalog with
  family `:workflow_progress_and_status`.
- [x] 33.2.1.2 Subtask - Add `repo_progress_card` to Unified IUR component kind
  metadata under the same family.
- [x] 33.2.1.3 Subtask - Remove `:workflow` and `:workflow_summary` family
  experiments from the implementation branch.
- [x] 33.2.1.4 Subtask - Ensure Live UI widget metadata reports the same family.

### [x] 33.2.2 Task - Add Package Boundary Guardrails

This task prevents kind and family drift during future catalog updates.

- [x] 33.2.2.1 Subtask - Add package-boundary tests for
  `repo_progress_card` catalog membership.
- [x] 33.2.2.2 Subtask - Add package-boundary tests for
  `:workflow_progress_and_status` family consistency.
- [x] 33.2.2.3 Subtask - Fail tests if Live UI registers the component under
  `:workflow`, `:operational`, or another family.
- [x] 33.2.2.4 Subtask - Commit catalog and package-boundary alignment.

## [x] 33.3 Section - Unified UI Authoring And Compiler Support

This section makes the component available through Unified UI surfaces without
depending on application map-surface vocabulary.

### [x] 33.3.1 Task - Add Or Confirm Unified UI Authoring Shape

This task exposes reusable repository workflow card metadata through Unified UI.

- [x] 33.3.1.1 Subtask - Define catalog docs for repository identity, progress,
  status counts, activity, dependencies, and optional actions.
- [x] 33.3.1.2 Subtask - Add a DSL entity when the current Unified UI component
  pattern requires one.
- [x] 33.3.1.3 Subtask - Reject route, URL, helper, runtime module, concrete CSS,
  and LiveView event fields at the authoring boundary.
- [x] 33.3.1.4 Subtask - Add Unified UI compiler tests for DSL-authored cards
  when DSL support is present.

### [x] 33.3.2 Task - Lower Cards Into Canonical IUR

This task ensures Unified UI-authored cards lower to the same canonical shape as
Ash-authored cards.

- [x] 33.3.2.1 Subtask - Lower repository identity into `attributes.repo`.
- [x] 33.3.2.2 Subtask - Lower progress, count, activity, dependency, and action
  data as structured values.
- [x] 33.3.2.3 Subtask - Preserve optional semantic interactions without host
  event strings.
- [x] 33.3.2.4 Subtask - Commit Unified UI authoring and compiler support.

## [x] 33.4 Section - Unified IUR Constructor And Validation

This section gives `repo_progress_card` a stable renderer-facing constructor and
structured validation contract.

### [x] 33.4.1 Task - Implement The Canonical Constructor

This task builds canonical `%UnifiedIUR.Element{}` values for valid repository
card declarations.

- [x] 33.4.1.1 Subtask - Implement
  `UnifiedIUR.Widgets.Components.repo_progress_card/1`.
- [x] 33.4.1.2 Subtask - Include `attributes.component.family:
  :workflow_progress_and_status`.
- [x] 33.4.1.3 Subtask - Normalize repository identity, progress, counts,
  activity, dependencies, and optional actions consistently.
- [x] 33.4.1.4 Subtask - Add positive constructor tests for minimal and full
  card declarations.

### [x] 33.4.2 Task - Validate Repository Card Contracts

This task makes invalid repository cards fail before renderer dispatch.

- [x] 33.4.2.1 Subtask - Validate required repository identity and progress
  bounds.
- [x] 33.4.2.2 Subtask - Validate status count maps and optional activity
  metadata.
- [x] 33.4.2.3 Subtask - Validate dependency edge descriptors and preserve
  ordering.
- [x] 33.4.2.4 Subtask - Validate open, focus, and dependency interactions as
  semantic canonical interactions.
- [x] 33.4.2.5 Subtask - Add negative tests for missing identity, invalid
  progress, malformed dependencies, nil action sentinels, and LiveView event
  leakage.
- [x] 33.4.2.6 Subtask - Commit Unified IUR constructor and validation support.

## [ ] 33.5 Section - Ash UI Resource Admission And Canonical Conversion

This section admits resource-authored cards and maps them into canonical Unified
IUR without bypassing Ash resource authority.

### [ ] 33.5.1 Task - Admit Resource And Persisted DSL Cards

This task updates Ash UI authoring validation to accept `repo_progress_card`
while preserving the `custom:*` extension boundary.

- [ ] 33.5.1.1 Subtask - Update `AshUI.DSL.Storage.valid_widget_type?/1` to
  admit `repo_progress_card`.
- [ ] 33.5.1.2 Subtask - Update resource authoring validation paths for
  `repo_progress_card`.
- [ ] 33.5.1.3 Subtask - Reject app-specific repository card names unless they
  are explicitly authored as `custom:*`.
- [ ] 33.5.1.4 Subtask - Add authoring tests for valid cards, invalid cards, and
  custom extension boundaries.

### [ ] 33.5.2 Task - Map Ash Card Props Into Canonical Attributes

This task updates `AshUI.Rendering.IURAdapter` so resource cards emit valid
canonical elements.

- [ ] 33.5.2.1 Subtask - Map resource card props into `attributes.repo`.
- [ ] 33.5.2.2 Subtask - Preserve Ash resource identity, relationship context,
  bindings, actions, and policies under Ash-owned metadata.
- [ ] 33.5.2.3 Subtask - Prevent unknown props from overwriting canonical
  `component` or `repo` namespaces.
- [ ] 33.5.2.4 Subtask - Add adapter tests that validate resource-authored card
  output through Unified IUR.
- [ ] 33.5.2.5 Subtask - Commit Ash resource admission and canonical conversion.

## [ ] 33.6 Section - Runtime Renderer Support

This section wires native and fallback rendering without making host transport
part of the canonical contract.

### [ ] 33.6.1 Task - Add Live UI Native Card Rendering

This task implements the native Live UI component and registry integration.

- [ ] 33.6.1.1 Subtask - Add `LiveUi.Widgets.RepoProgressCard` with
  `:workflow_progress_and_status` family metadata.
- [ ] 33.6.1.2 Subtask - Register the card in Live UI widget discovery using the
  current family module pattern.
- [ ] 33.6.1.3 Subtask - Render progress, counts, dependencies, activity,
  optional actions, accessibility labels, and global attrs.
- [ ] 33.6.1.4 Subtask - Translate semantic interactions into LiveView events
  inside Live UI without storing raw `phx-*` fields in canonical data.

### [ ] 33.6.2 Task - Preserve Or Diagnose Non-Live Runtime Cards

This task keeps Elm and desktop behavior explicit until native card rendering
exists there.

- [ ] 33.6.2.1 Subtask - Add Elm adapter preservation or structured
  unsupported-component diagnostics for `repo_progress_card`.
- [ ] 33.6.2.2 Subtask - Add desktop adapter preservation or structured
  unsupported-component diagnostics for `repo_progress_card`.
- [ ] 33.6.2.3 Subtask - Include renderer name, component kind, and element id in
  diagnostics.
- [ ] 33.6.2.4 Subtask - Add tests proving unsupported cards are not silently
  coerced to `custom:*` or generic nodes.
- [ ] 33.6.2.5 Subtask - Commit runtime renderer support.

## [ ] 33.7 Section - Documentation, Examples, And Migration Guidance

This section teaches users and reviewers how to use the reusable component
without reintroducing app-specific canonical vocabulary.

### [ ] 33.7.1 Task - Update User And Developer Guides

This task documents authoring, package ownership, renderer behavior, and
extension boundaries.

- [ ] 33.7.1.1 Subtask - Add user guide coverage for `repo_progress_card`
  identity, progress, status counts, dependencies, actions, and interactions.
- [ ] 33.7.1.2 Subtask - Add developer guide coverage for package boundaries,
  validation, canonical attributes, and renderer support.
- [ ] 33.7.1.3 Subtask - Document concrete layout and theme ownership by
  renderers and host applications.
- [ ] 33.7.1.4 Subtask - Document why map-surface placement and host action names
  are application composition rather than canonical vocabulary.

### [ ] 33.7.2 Task - Add Reviewable Examples

This task provides proof that the component is reusable outside a single map
surface.

- [ ] 33.7.2.1 Subtask - Add a compact repository health example.
- [ ] 33.7.2.2 Subtask - Add a dependency-focused example with `depends_on` and
  `depended_by` edges.
- [ ] 33.7.2.3 Subtask - Add an example with optional open action and dependency
  interactions.
- [ ] 33.7.2.4 Subtask - Add a canonical signal preview showing open, focus, and
  dependency interactions.
- [ ] 33.7.2.5 Subtask - Commit docs, examples, and migration guidance.

## [ ] 33.8 Section - Phase 33 Integration Tests And PR Closeout

This final section proves canonical workflow progress and status adoption works
as one package-spanning path instead of a standalone Live UI widget.

### [ ] 33.8.1 Task - Run End-To-End Card Adoption Scenarios

This task validates Phase 33 across rebase hygiene, catalog, DSL, constructor,
validation, Ash conversion, runtime rendering, docs, examples, and governance.

- [ ] 33.8.1.1 Subtask - Verify `repo_progress_card` catalog and family metadata
  match across packages.
- [ ] 33.8.1.2 Subtask - Verify Unified UI-authored cards compile into valid
  `%UnifiedIUR.Element{}` output where DSL support is present.
- [ ] 33.8.1.3 Subtask - Verify Unified IUR rejects invalid identity, progress,
  dependency, action, and interaction shapes.
- [ ] 33.8.1.4 Subtask - Verify Ash resource-authored cards compile into valid
  canonical output.
- [ ] 33.8.1.5 Subtask - Verify Live UI renders native cards with attrs,
  accessibility, dependencies, and interactions preserved.
- [ ] 33.8.1.6 Subtask - Verify Elm and desktop adapters preserve or diagnose
  cards explicitly.
- [ ] 33.8.1.7 Subtask - Verify docs and examples cover reusable workflow status
  composition and the app-specific map-surface boundary.
- [ ] 33.8.1.8 Subtask - Run the targeted Phase 33 suite and governance
  validation before opening the final PR.
- [ ] 33.8.1.9 Subtask - Commit integration coverage and PR closeout notes.
