# Canonical Rail Component Adoption Spec

## spec-meta

- id: `ash_ui.canonical_rail_component`
- status: `active`
- owner: `AshUI.Rendering`
- source-of-truth:
  - `specs/adr/ADR-0008-canonical-rail-component-adoption.md`
  - `specs/contracts/canonical_rail_component_contract.md`
  - `specs/planning/phase-32-canonical-rail-component-adoption.md`
  - `guides/user/UG-0003-widget-types-properties-and-signals.md`
  - `guides/user/UG-0005-liveview-runtime-and-rendering.md`
  - `guides/developer/DG-0003-compiler-canonical-iur-and-renderers.md`
- related:
  - `ash_ui.canonical_widget_components`
  - `ash_ui.rendering`
  - `ash_ui.compiler`
  - `ash_ui.canonical_navigation`

## intent

Ash UI must adopt a reusable canonical `right_rail` component without admitting application-specific document rail semantics into the shared package vocabulary.

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
- `specs/contracts/canonical_rail_component_contract.md`

## requirements

### ash_ui.canonical_rail_component.generic_kind

Ash UI adopts `right_rail` as the canonical reusable rail component kind and keeps document-specific rail names application-owned.

Required behavior:

- `right_rail` is the renderer-facing canonical kind.
- `doc_right_rail` is not admitted as canonical package vocabulary.
- document rail examples compose domain-specific panels on top of `right_rail`.

### ash_ui.canonical_rail_component.package_boundary

Unified UI, Unified IUR, runtime packages, and Ash UI agree on rail catalog membership, family metadata, constructor shape, validation, and renderer dispatch.

Required behavior:

- `right_rail` belongs to the layer shell and callout family across package metadata.
- package-boundary tests fail on kind or family drift.
- the rail has Unified UI DSL, compiler, Unified IUR constructor, and validation support before Ash UI marks it supported.

### ash_ui.canonical_rail_component.canonical_shape

Rail declarations compile into host-independent canonical attributes with ordered panels, selected panel state, collapse state, semantic interactions, and named panel content slots.

Required behavior:

- panel descriptors are ordered and stable.
- `active_panel` must reference a declared panel.
- panel selection and collapse use structured semantic interactions.
- renderer-specific event names and concrete CSS values are excluded from canonical attributes.

### ash_ui.canonical_rail_component.resource_authority

Ash resource declarations own rail composition, child content, bindings, actions, and policies.

Required behavior:

- resource-authored rails compile through `AshUI.Rendering.IURAdapter`.
- Ash metadata remains namespaced and separate from canonical rail attributes.
- rail panel bodies are preserved through canonical children or named slots.
- renderer paths do not silently drop rail content.

### ash_ui.canonical_rail_component.runtime_support

Runtime adapters render, preserve, or diagnose canonical rails without losing canonical identity.

Required behavior:

- Live UI renders `right_rail` natively and registers it in widget discovery.
- Elm and desktop adapters preserve `right_rail` or return structured unsupported-component diagnostics until native support exists.
- fallback output preserves accessibility, selected state, collapse state, and children.

### ash_ui.canonical_rail_component.documentation

Ash UI documents the reusable rail contract and the boundary between canonical rail behavior and application-specific document rails.

Required behavior:

- user guides describe `right_rail` authoring.
- developer guides describe package ownership, validation, slots, interactions, and renderer responsibilities.
- examples show a document-oriented rail composition that emits canonical `right_rail`.

## verification

### planned-tests

- `mix test test/ash_ui/phase_32_package_boundary_test.exs`
- `mix test test/ash_ui/resource/right_rail_test.exs test/ash_ui/dsl/storage_test.exs`
- `mix test test/ash_ui/rendering/right_rail_iur_adapter_test.exs`
- `mix test test/ash_ui/rendering/right_rail_renderer_test.exs`
- `mix test packages/unified_iur/test/unified_iur/widgets/right_rail_test.exs`
- `mix test packages/unified_ui/test/unified_ui/right_rail_compiler_test.exs`
- `mix test packages/live_ui/test/live_ui/right_rail_test.exs`
- `mix test test/ash_ui/phase_32_integration_test.exs`
- `bash ./scripts/validate_specs_governance.sh`
- `bash ./scripts/validate_guides_governance.sh`

### conformance-checks

- `right_rail` catalog and family metadata match across packages.
- Unified UI DSL-authored rails compile into valid Unified IUR.
- Unified IUR validates required rail, panel, slot, and interaction fields.
- Ash resource-authored rails emit canonical `%UnifiedIUR.Element{}` output.
- Live UI renders native rails without dropping attrs, interactions, or slots.
- Elm and desktop adapters preserve or diagnose rails explicitly.
- docs and examples explain reusable rail composition and reject app-specific canonical names.
