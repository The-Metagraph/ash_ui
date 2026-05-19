# Canonical Workflow Progress And Status Component Contract

Back to index: [README](../README.md)

## Purpose

This contract defines the requirements for adopting `repo_progress_card` as a
reusable canonical workflow progress and status component across the Unified
package set, runtime renderers, and Ash UI.

It applies to Phase 33 and builds on the Phase 30 `%UnifiedIUR.Element{}`
boundary, the Phase 31 canonical widget-component catalog, and the Phase 32
canonical component package-boundary pattern. It does not replace Ash resource
authority.

## Control Plane Ownership

- `AshUI.Resource` owns resource-authored card placement, relationships,
  bindings, actions, authorization, and policies.
- `AshUI.Compiler` owns graph-derived IUR assembly from persisted Ash UI
  resources.
- `AshUI.Rendering` owns conversion from Ash UI IUR into canonical Unified IUR
  `repo_progress_card` elements.
- `AshUI.LiveView` and `AshUI.Runtime` own runtime hydration, event bridging,
  and host integration.
- Unified UI and Unified IUR own the canonical `repo_progress_card` name,
  family metadata, attribute contract, validation, and renderer-facing
  semantics.
- Runtime packages own native card rendering and host-specific event transport.

## Canonical Scope

Ash UI MUST adopt this canonical widget component when Phase 33 lands:

| Canonical kind | Family | Compatibility aliases |
| --- | --- | --- |
| `repo_progress_card` | workflow progress and status | - |

Application-specific names, map-surface audit labels, placement handles, and
host action names are not canonical aliases. They may exist as application-local
wrapper modules, example names, or resource compositions that emit canonical
`repo_progress_card` output.

## Canonical Attribute Shape

The canonical card attributes MUST be renderer independent and grouped under a
repository-specific namespace.

Required canonical concepts:

- `repo.id`: stable repository or work-unit identity within the screen.
- `repo.name`: display name.
- `repo.path`: optional repository path or locator text.
- `repo.progress`: numeric progress from 0 through 100.
- `repo.status_counts`: structured active, blocked, done, failed, or custom
  counts.
- `repo.activity`: optional recent activity metadata.
- `repo.dependencies.depends_on`: ordered dependency edge descriptors.
- `repo.dependencies.depended_by`: ordered reverse dependency edge descriptors.
- `repo.actions.open`: optional semantic open action.
- `repo.interactions.focus`: optional semantic focus interaction.
- `repo.interactions.dependency_select`: optional semantic dependency
  interaction.

Dependency edge descriptors SHOULD support:

- `id`
- `label`
- `state`
- `direction`
- `metadata`
- `interaction`

Concrete CSS values, color tokens, grid placement, map-surface identifiers,
LiveView event strings, `phx-*` attributes, routes, URL/path navigation, helper
names, runtime modules, and host stack identifiers MUST NOT be part of the
canonical attribute contract.

## Requirements

### REQ-WFPS-001 - Canonical Name And Scope

Ash UI MUST treat `repo_progress_card` as the canonical component kind for
reusable repository workflow progress and status behavior.

Acceptance criteria:

- renderer-facing canonical IUR emits `kind: :repo_progress_card`;
- map-surface-specific names are not admitted as canonical package aliases;
- application-specific cards compose or wrap the canonical component instead of
  changing the package catalog.

### REQ-WFPS-002 - Catalog And Family Alignment

Unified and Ash package metadata MUST agree that `repo_progress_card` belongs to
the workflow progress and status family.

Acceptance criteria:

- `UnifiedUi.WidgetComponents` reports `repo_progress_card` in
  `:workflow_progress_and_status`;
- Unified IUR component metadata uses the same family;
- Live UI widget metadata and registry discovery use the same family;
- no implementation path introduces `:workflow` or `:workflow_summary` for this
  component;
- package-boundary tests fail on family drift.

### REQ-WFPS-003 - Unified UI Authoring Path

Unified UI MUST expose catalog metadata and, when DSL authoring is present, a
first-class DSL/compiler path for `repo_progress_card`.

Acceptance criteria:

- the catalog entry documents the component family and summary;
- any DSL entity lowers to canonical `repo` attributes;
- invalid repository progress or dependency declarations fail before renderer
  dispatch;
- DSL examples avoid app-specific map-surface language.

### REQ-WFPS-004 - Unified IUR Constructor And Validation

Unified IUR MUST provide constructor and validation support for the canonical
card shape.

Acceptance criteria:

- `UnifiedIUR.Widgets.Components.repo_progress_card/1` builds a canonical
  `%UnifiedIUR.Element{}`;
- `UnifiedIUR.Validate.element/1` validates required repository identity,
  progress bounds, status count shapes, dependency edge descriptors, and
  optional action shapes;
- validation rejects renderer-specific event strings as canonical interactions;
- validation returns structured diagnostics instead of relying only on
  constructor exceptions.

### REQ-WFPS-005 - Ash Resource Admission

Ash UI MUST admit `repo_progress_card` through resource-first and persisted DSL
authoring paths.

Acceptance criteria:

- `AshUI.Resource.DSL.Element` accepts `repo_progress_card`;
- persisted DSL validation accepts `repo_progress_card`;
- invalid app-specific names are rejected unless explicitly authored as
  `custom:*`;
- authoring errors identify the affected resource or element.

### REQ-WFPS-006 - Ash Canonical Conversion

Ash UI MUST convert resource-authored repository card declarations into the
canonical `repo_progress_card` attribute shape.

Acceptance criteria:

- `AshUI.Rendering.IURAdapter` maps card props into `attributes.repo`;
- Ash-owned metadata stays under Ash-owned metadata keys;
- unknown props cannot overwrite canonical `component` or `repo` metadata;
- converted card output validates through Unified IUR.

### REQ-WFPS-007 - Dependency Edge Semantics

Repository dependencies MUST remain structured and ordered at the canonical
boundary.

Acceptance criteria:

- `depends_on` and `depended_by` canonical values are lists of edge descriptors;
- dependency names are not comma-joined canonical text;
- each dependency edge may include an optional semantic interaction;
- dependency ordering is preserved through renderer fallback output.

### REQ-WFPS-008 - Semantic Actions And Interactions

Repository card actions and interactions MUST be semantic and host independent.

Acceptance criteria:

- open, focus, and dependency interactions are structured canonical
  interactions;
- unavailable actions are omitted rather than represented by `nil`;
- present actions may carry semantic visibility policy;
- LiveView event names are generated or translated inside Live UI, not stored as
  canonical attributes.

### REQ-WFPS-009 - Runtime Renderer Support

Runtime renderers MUST either render `repo_progress_card` natively or preserve
it with structured diagnostics.

Acceptance criteria:

- Live UI renders the card natively and registers it in widget discovery;
- Elm and desktop renderers preserve the canonical kind or return structured
  unsupported-component diagnostics until native support exists;
- unsupported diagnostics include renderer name, component kind, and element id;
- fallback behavior keeps canonical kind identity visible.

### REQ-WFPS-010 - Theme And Layout Boundary

The canonical card MUST avoid host-owned concrete layout and theme values.

Acceptance criteria:

- concrete grid placement, CSS classes, colors, spacing, and breakpoints are
  renderer/theme concerns;
- canonical attributes may express semantic density or priority only when
  reusable across hosts;
- renderer docs describe default card behavior without making it a canonical
  requirement.

### REQ-WFPS-011 - PR Rebase And Scope Hygiene

The PR #123 implementation branch MUST be rebased and scope-cleaned before it
becomes the Phase 33 implementation branch.

Acceptance criteria:

- the branch is rebased on current `main`;
- conflicts in Live UI renderer and widget registry files are resolved against
  the current canonical component registry;
- unrelated `diff_banner` or cross-wave changes are removed;
- each Phase 33 section can be reviewed as a scoped commit in a single PR.

### REQ-WFPS-012 - Documentation And Conformance

Ash UI MUST document the card as reusable canonical workflow status vocabulary
and add conformance coverage for the complete adoption path.

Acceptance criteria:

- user guides describe resource authoring and canonical repository card fields;
- developer guides describe package ownership, validation, interactions, and
  renderer responsibilities;
- package-boundary tests compare catalog and family metadata;
- constructor, validation, Ash conversion, renderer, documentation, and
  end-to-end tests prove the full adoption path.

## Traceability

| Requirement | Source | Planned Implementation |
| --- | --- | --- |
| REQ-WFPS-001 | ADR-0009 | Phase 33.1, Phase 33.2 |
| REQ-WFPS-002 | ADR-0009 | Phase 33.2 |
| REQ-WFPS-003 | ADR-0009 | Phase 33.3 |
| REQ-WFPS-004 | ADR-0009 | Phase 33.4 |
| REQ-WFPS-005 | ADR-0009 | Phase 33.5 |
| REQ-WFPS-006 | ADR-0009 | Phase 33.5 |
| REQ-WFPS-007 | ADR-0009 | Phase 33.4, Phase 33.6 |
| REQ-WFPS-008 | ADR-0009 | Phase 33.4, Phase 33.6 |
| REQ-WFPS-009 | ADR-0009 | Phase 33.6 |
| REQ-WFPS-010 | ADR-0009 | Phase 33.6, Phase 33.7 |
| REQ-WFPS-011 | ADR-0009 | Phase 33.1 |
| REQ-WFPS-012 | ADR-0009 | Phase 33.7, Phase 33.8 |

## Conformance

The Phase 33 integration test section is the acceptance gate for this contract.
Conformance is complete when rebase hygiene, package-boundary, DSL/catalog,
constructor, validation, Ash conversion, renderer, documentation, example, and
end-to-end tests named in Phase 33 are implemented and passing.

## Related

- [ADR-0009: Canonical Workflow Progress And Status Component Adoption](../adr/ADR-0009-canonical-workflow-progress-status-component-adoption.md)
- [ADR-0008: Canonical Rail Component Adoption](../adr/ADR-0008-canonical-rail-component-adoption.md)
- [ADR-0007: Canonical Widget Components Adoption](../adr/ADR-0007-canonical-widget-components-adoption.md)
- [ADR-0006: Canonical IUR And Navigation Adoption](../adr/ADR-0006-canonical-iur-and-navigation-adoption.md)
- [Phase 33 - Canonical Workflow Progress And Status Component Adoption](../planning/phase-33-canonical-workflow-progress-status-component-adoption.md)
- [Canonical Widget Components Adoption Contract](./canonical_widget_components_contract.md)
- [Rendering Contract](./rendering_contract.md)
