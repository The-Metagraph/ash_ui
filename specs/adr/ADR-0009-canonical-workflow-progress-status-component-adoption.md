# ADR-0009: Canonical Workflow Progress And Status Component Adoption

## Status

**Accepted**

Planned for Phase 33. ADR-0005 remains the active resource-authority baseline,
ADR-0006 remains the canonical IUR/navigation boundary baseline, ADR-0007
remains the canonical widget-component catalog baseline, and ADR-0008 remains
the canonical rail component baseline.

## Context

PR #123 proposes `repo_progress_card` as a repository progress, blocker,
activity, and dependency summary widget. The PR is currently draft and
conflicting with main. It also mixes useful canonical package work with
implementation details that do not belong in the renderer-facing contract:
LiveView event strings, application action names, map-surface language,
inconsistent family metadata, and unrelated cross-wave changes.

Ash UI can use this work, but only if the component is adopted as a reusable
canonical workflow progress and status component rather than as an application
surface transplant. The implementation must pass through Unified UI, Unified
IUR, runtime renderers, Ash conversion, validation, documentation, and
conformance as one package-spanning feature.

## Decision

### 1. Adopt `repo_progress_card` As A Canonical Component

Ash UI will adopt `repo_progress_card` as the canonical kind for reusable
repository workflow progress and status cards.

The canonical component represents a repository-like work unit with identity,
path or locator metadata, progress state, active or blocked counts, recent
activity, dependency edges, and optional semantic actions. It does not represent
an application-specific map card, grid tile, audit finding, or host placement.

### 2. Keep The Component In `:workflow_progress_and_status`

`repo_progress_card` belongs to the existing `:workflow_progress_and_status`
component family. The implementation must not introduce `:workflow` or
`:workflow_summary` as package families for this component.

Family assignment must be consistent across:

- `UnifiedUi.WidgetComponents`;
- Unified UI DSL/compiler metadata when a DSL entity exists;
- `UnifiedIUR.Widgets.Components`;
- `UnifiedIUR.Validate`;
- Live UI widget metadata and registries;
- Ash UI canonical conversion and renderer adapters.

### 3. Use Structured Canonical Attributes

The component must expose structured canonical attributes for repository
identity, progress, status counts, dependency edges, activity state, and optional
actions.

Dependency data is canonical as ordered edge descriptors, not comma-joined
display text. Renderers may choose chips, lists, compact text, or other native
presentation, but the canonical input remains queryable and validation-friendly.

### 4. Keep Interactions Semantic

Open, focus, dependency navigation, and dependency selection behavior must use
semantic canonical interactions.

Canonical attributes must not contain `phx-*` fields, LiveView event names,
routes, URL/path navigation, router helpers, runtime modules, or application
action atoms such as map-surface-specific focus events. Runtime packages may
translate semantic interactions into host events internally.

Unavailable actions are omitted from the canonical action map. A present action
may carry a semantic visibility policy, but `nil` is not a visibility state.

### 5. Preserve Resource Authority

Ash screen and element resources remain the authority for composition, bindings,
actions, authorization, and policies. `repo_progress_card` may be authored as a
canonical component, but resource-derived metadata must stay in Ash-owned
namespaces and must not overwrite canonical `component` or `repo` attributes.

### 6. Require Complete Package-Boundary Adoption

The component is not supported until the full package path is implemented:

- Unified UI catalog metadata and optional DSL/compiler support;
- Unified IUR constructor, normalization, and validation;
- Live UI native rendering and registry metadata;
- Elm and desktop preservation or structured unsupported diagnostics;
- Ash UI authoring admission, canonical conversion, fallback rendering, and
  tests;
- documentation, examples, and governance coverage.

Partial adoption that only adds a Live UI component or constructor is not enough.

## Consequences

### Positive

- Repository workflow status cards become reusable across operational,
  dependency, codebase health, and release coordination surfaces.
- Package metadata remains aligned with the existing canonical family model.
- Dependency edges and actions remain portable and testable instead of being
  locked to one renderer.
- PR #123 can be salvaged through a defined rebase and cleanup path.

### Negative

- The PR branch needs manual conflict resolution against the current canonical
  component registry.
- The component contract is stricter than the current Stage-4 implementation.
- Some renderers may initially preserve or diagnose the component instead of
  rendering a full native card.
- Application-specific map behavior must move to app composition or wrapper
  code.

### Required Follow-Through

- Add and maintain a canonical workflow progress and status component contract
  under `specs/contracts/`.
- Add `.spec` coverage for the canonical adoption line.
- Implement Phase 33 before treating `repo_progress_card` as supported Ash UI
  authoring input.
- Remove unrelated cross-wave changes from the PR #123 implementation branch.

## Related

- [ADR-0005: Element Resource Authority And Relational Screen Composition](./ADR-0005-element-resource-authority-and-relational-screen-composition.md)
- [ADR-0006: Canonical IUR And Navigation Adoption](./ADR-0006-canonical-iur-and-navigation-adoption.md)
- [ADR-0007: Canonical Widget Components Adoption](./ADR-0007-canonical-widget-components-adoption.md)
- [ADR-0008: Canonical Rail Component Adoption](./ADR-0008-canonical-rail-component-adoption.md)
- [Canonical Workflow Progress And Status Component Contract](../contracts/canonical_workflow_progress_status_component_contract.md)
- [Phase 33 - Canonical Workflow Progress And Status Component Adoption](../planning/phase-33-canonical-workflow-progress-status-component-adoption.md)

## References

- PR #123: `https://github.com/The-Metagraph/ash_ui/pull/123`
- `UnifiedUi.WidgetComponents`
- `UnifiedIUR.Widgets.Components`
- `UnifiedIUR.Validate`
- `AshUI.Rendering.IURAdapter`
- runtime renderer widget registries
