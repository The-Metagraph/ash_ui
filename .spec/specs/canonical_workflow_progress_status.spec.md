# Canonical Workflow Progress And Status Component Spec

## spec-meta

- id: `ash_ui.canonical_workflow_progress_status`
- status: `active`
- owner: `AshUI.Rendering`
- decisions:
  - `.spec/decisions/ADR-0009-canonical-workflow-progress-status-component.md`
- source-of-truth:
  - `specs/adr/ADR-0009-canonical-workflow-progress-status-component-adoption.md`
  - `specs/contracts/canonical_workflow_progress_status_component_contract.md`
  - `specs/planning/phase-33-canonical-workflow-progress-status-component-adoption.md`
- related:
  - `ash_ui.canonical_widget_components`
  - `ash_ui.rendering`
  - `ash_ui.compiler`
  - `ash_ui.canonical_navigation`
  - `ash_ui.conformance`

## intent

Ash UI must adopt `repo_progress_card` as a reusable canonical
`:workflow_progress_and_status` component only when the complete Unified UI,
Unified IUR, runtime renderer, Ash rendering, validation, and conformance path is
aligned. The canonical component may describe repository workflow status, but it
must not encode application-specific map-surface behavior or LiveView transport
details.

## surfaces

- `packages/unified_iur`
- `packages/unified_ui`
- `packages/live_ui`
- `packages/elm_ui`
- `packages/desktop_ui`
- `lib/ash_ui/dsl/storage.ex`
- `lib/ash_ui/resource/dsl/element.ex`
- `lib/ash_ui/resources/validations/authoring.ex`
- `lib/ash_ui/rendering/iur_adapter.ex`
- `lib/ash_ui/rendering/live_ui_adapter.ex`
- `lib/ash_ui/rendering/elm_ui_adapter.ex`
- `lib/ash_ui/rendering/desktop_ui_adapter.ex`
- `lib/ash_ui/liveview/iur_hydration.ex`
- `specs/contracts/canonical_workflow_progress_status_component_contract.md`

## requirements

### ash_ui.canonical_workflow_progress_status.generic_kind

Ash UI adopts `repo_progress_card` as the canonical reusable repository workflow
status component kind and keeps app-specific map surface vocabulary out of the
shared package catalog.

Required behavior:

- `repo_progress_card` is the renderer-facing canonical kind.
- map-surface audit labels, placement names, and application action names are
  not canonical component fields.
- application-specific repository cards may wrap or compose the canonical
  component without extending the package catalog.

### ash_ui.canonical_workflow_progress_status.family_alignment

Unified UI, Unified IUR, Live UI, and Ash UI agree that `repo_progress_card`
belongs to `:workflow_progress_and_status`.

Required behavior:

- no `:workflow` or `:workflow_summary` family is introduced for this component.
- package-boundary tests fail on kind or family drift.
- Live UI registry metadata matches Unified UI and Unified IUR metadata.

### ash_ui.canonical_workflow_progress_status.canonical_shape

`repo_progress_card` declarations compile into host-independent canonical
attributes for repository identity, progress, status counts, dependency edges,
activity metadata, and optional actions.

Required behavior:

- repository identity fields are stable and renderer independent.
- progress values are bounded and accessible.
- counts and activity values are structured data, not formatted display text.
- dependency edges are ordered descriptors, not comma-joined canonical strings.
- unavailable actions are omitted; present actions may carry semantic visibility
  policy.

### ash_ui.canonical_workflow_progress_status.semantic_interactions

Repository card interactions remain semantic and host independent.

Required behavior:

- open, focus, dependency navigation, and dependency selection interactions use
  structured canonical interactions.
- canonical output excludes raw `phx-*` attributes, LiveView event names, route
  helpers, runtime modules, and URL/path fields.
- renderers translate semantic interactions to their host event transport.

### ash_ui.canonical_workflow_progress_status.resource_authority

Ash resource declarations own repository card composition, bindings, actions,
and policies.

Required behavior:

- resource-authored cards compile through `AshUI.Rendering.IURAdapter`.
- Ash metadata remains namespaced and cannot overwrite canonical component or
  repository namespaces.
- bindings and actions remain actor-aware and policy-mediated where applicable.

### ash_ui.canonical_workflow_progress_status.runtime_support

Runtime adapters render, preserve, or diagnose `repo_progress_card` without
losing canonical identity.

Required behavior:

- Live UI renders the component natively and registers it in widget discovery.
- Elm and desktop adapters preserve the canonical kind or return structured
  unsupported-component diagnostics until native support exists.
- fallback rendering preserves accessibility, progress state, dependency
  ordering, optional actions, and canonical kind identity.

### ash_ui.canonical_workflow_progress_status.rebase_scope

The PR #123 implementation path must be rebased and scope-cleaned before it is
used as the basis for Phase 33.

Required behavior:

- current main is the rebase base.
- conflicts in Live UI renderer and widget registry files are resolved against
  the current canonical component registry.
- unrelated `diff_banner` or cross-wave changes are removed from the branch.
- each Phase 33 section can be committed independently and reviewed as part of a
  single PR.

## verification

### planned-tests

- `mix test test/ash_ui/phase_33_package_boundary_test.exs`
- `mix test packages/unified_iur/test/unified_iur/widgets/repo_progress_card_test.exs`
- `mix test packages/unified_ui/test/unified_ui/repo_progress_card_compiler_test.exs`
- `mix test packages/live_ui/test/live_ui/repo_progress_card_test.exs packages/live_ui/test/live_ui/renderer_test.exs`
- `mix test test/ash_ui/rendering/iur_adapter_test.exs test/ash_ui/rendering/live_ui_adapter_test.exs`
- `mix test test/ash_ui/phase_33_integration_test.exs`
- `bash ./scripts/validate_specs_governance.sh`
- `bash ./scripts/validate_guides_governance.sh`

### conformance-checks

- `repo_progress_card` catalog and family metadata match across packages.
- Unified IUR validates required repository identity, progress, counts,
  dependency edge, action, and interaction fields.
- Ash resource-authored cards emit valid canonical `%UnifiedIUR.Element{}`
  output.
- Live UI renders native cards without hardcoded canonical `phx-*` leakage.
- Elm and desktop adapters preserve or diagnose the component explicitly.
- docs and examples explain reusable workflow status composition and the
  application-specific map-surface boundary.
