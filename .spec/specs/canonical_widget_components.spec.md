# Canonical Widget Components Adoption Spec

## spec-meta

- id: `ash_ui.canonical_widget_components`
- status: `active`
- owner: `AshUI.Rendering`
- source-of-truth:
  - `specs/adr/ADR-0007-canonical-widget-components-adoption.md`
  - `specs/contracts/canonical_widget_components_contract.md`
  - `specs/planning/phase-31-canonical-widget-components-adoption.md`
  - `guides/user/UG-0003-widget-types-properties-and-signals.md`
  - `guides/user/UG-0005-liveview-runtime-and-rendering.md`
  - `guides/developer/DG-0003-compiler-canonical-iur-and-renderers.md`
- related:
  - `ash_ui.rendering`
  - `ash_ui.compiler`
  - `ash_ui.storage`
  - `ash_ui.canonical_navigation`

## intent

Ash UI must adopt the expanded Unified UI canonical widget-component catalog as first-class resource-authored component input without weakening Ash resource authority or turning cataloged components into `custom:*` escape hatches.

## surfaces

- `packages/unified_iur`
- `packages/unified_ui`
- `packages/live_ui`
- `packages/elm_ui`
- `packages/desktop_ui`
- `lib/ash_ui/dsl/storage.ex`
- `lib/ash_ui/resource/dsl/element.ex`
- `lib/ash_ui/resource/dsl/relationship.ex`
- `lib/ash_ui/resources/validations/authoring.ex`
- `lib/ash_ui/rendering/iur_adapter.ex`
- `lib/ash_ui/rendering/live_ui_adapter.ex`
- `lib/ash_ui/rendering/elm_ui_adapter.ex`
- `lib/ash_ui/rendering/desktop_ui_adapter.ex`
- `lib/ash_ui/liveview/iur_hydration.ex`
- `specs/contracts/canonical_widget_components_contract.md`

## requirements

### ash_ui.canonical_widget_components.catalog_alignment

Ash UI tracks the Unified package widget-component catalog as the authoritative canonical component vocabulary.

Required behavior:

- Supported canonical kinds match `UnifiedUi.WidgetComponents.kinds/0`.
- Supported aliases match `UnifiedUi.WidgetComponents.aliases/0`.
- `thread_card` is a first-class `row_and_artifact` component, not a
  content-identity component or baseline navigation primitive.
- Drift is caught by package-boundary tests before release.

### ash_ui.canonical_widget_components.authoring_admission

Ash UI resource and persisted DSL validation admits every cataloged canonical component kind while preserving invalid-kind rejection.

Required behavior:

- Element resources can declare cataloged component kinds.
- Persisted DSL payloads validate cataloged component kinds.
- Existing non-component widgets, layouts, and `custom:*` extension widgets remain supported.

### ash_ui.canonical_widget_components.alias_normalization

Ash UI accepts compatibility aliases only at authoring boundaries and emits canonical names downstream.

Required behavior:

- `phoenix_form` normalizes to `runtime_form_shell`.
- `repeat` and `ui_relationship_repeat` normalize to `list_repeat`.
- Renderer-facing canonical IUR never emits those aliases as component kinds.

### ash_ui.canonical_widget_components.canonical_conversion

Ash UI converts cataloged components into valid `%UnifiedIUR.Element{}` nodes with canonical kind and attribute namespaces.

Required behavior:

- Component attributes match Unified IUR component contracts.
- Ash metadata remains namespaced and separate from renderer-owned attributes.
- Canonical output validates through the upgraded Unified IUR validation APIs.

### ash_ui.canonical_widget_components.renderer_support

Ash UI runtime adapters preserve canonical component identity through Live, Elm, and desktop rendering paths.

Required behavior:

- Native runtime renderers receive canonical component nodes when available.
- Adapter fallback rendering keeps canonical kind identity visible.
- Unsupported components produce structured diagnostics instead of silent coercion.

### ash_ui.canonical_widget_components.list_repeat

Ash UI supports canonical `list_repeat` as relationship-driven composition behavior.

Required behavior:

- Repeat declarations remain tied to Ash resource relationships and list bindings.
- Row-scoped bindings can hydrate repeated templates.
- Canonical repeat intent is preserved where renderer validation supports it.

### ash_ui.canonical_widget_components.documentation

Ash UI documents the canonical widget-component catalog, aliases, fallback behavior, and extension boundary.

Required behavior:

- User guides list supported component names and aliases.
- Developer guides describe catalog ownership, validation, and renderer fallback responsibilities.
- Examples use canonical names for cataloged components instead of `custom:*`.

## verification

### planned-tests

- `mix test test/ash_ui/phase_31_package_boundary_test.exs`
- `mix test test/ash_ui/dsl/storage_test.exs test/ash_ui/resource/widget_components_test.exs`
- `mix test test/ash_ui/rendering/widget_components_iur_adapter_test.exs`
- `mix test test/ash_ui/rendering/widget_components_renderer_test.exs`
- `mix test test/ash_ui/liveview/list_repeat_hydration_test.exs`
- `mix test test/ash_ui/phase_31_integration_test.exs`
- `bash ./scripts/validate_specs_governance.sh`
- `bash ./scripts/validate_guides_governance.sh`

### conformance-checks

- Ash UI's supported component catalog matches Unified UI.
- All cataloged kinds and aliases are admitted at resource and persisted DSL boundaries.
- Alias input emits canonical kinds.
- Canonical component output validates through Unified IUR.
- Runtime adapters preserve, render, or diagnose component kinds.
- List-repeat behavior remains resource-authority and relationship-owned.
- User and developer guides explain the catalog and extension boundary.
