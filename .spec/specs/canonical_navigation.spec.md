# Canonical Navigation Adoption Spec

## spec-meta

- id: `ash_ui.canonical_navigation`
- status: `active`
- owner: `AshUI.Rendering`
- source-of-truth:
  - `specs/adr/ADR-0006-canonical-iur-and-navigation-adoption.md`
  - `specs/contracts/canonical_navigation_contract.md`
  - `specs/planning/phase-30-canonical-iur-and-navigation-adoption.md`
  - `guides/user/UG-0004-bindings-actions-and-forms.md`
  - `guides/user/UG-0005-liveview-runtime-and-rendering.md`
  - `guides/developer/DG-0003-compiler-canonical-iur-and-renderers.md`
- related:
  - `ash_ui.rendering`
  - `ash_ui.signals`
  - `ash_ui.bindings`

## intent

Ash UI must adopt the upgraded Unified UI canonical navigation model without weakening resource authority or leaking host runtime details into canonical declarations.

## surfaces

- `packages/unified_iur`
- `packages/unified_ui`
- `packages/live_ui`
- `packages/elm_ui`
- `packages/desktop_ui`
- `lib/ash_ui/rendering/iur_adapter.ex`
- `lib/ash_ui/runtime`
- `lib/ash_ui/resources`
- `guides/user/UG-0004-bindings-actions-and-forms.md`
- `guides/user/UG-0005-liveview-runtime-and-rendering.md`
- `guides/developer/DG-0003-compiler-canonical-iur-and-renderers.md`
- `specs/contracts/canonical_navigation_contract.md`

## requirements

### ash_ui.canonical_navigation.package_adoption

Ash UI upgrades Unified package dependencies as a compatible set before enabling canonical navigation as the shipped renderer path.

Required behavior:

- `unified_iur`, `unified_ui`, and runtime packages compile together.
- Spark dependency resolution remains compatible with Ash UI.
- Runtime adapter namespaces match the upgraded packages.

### ash_ui.canonical_navigation.struct_iur_boundary

Ash UI emits `%UnifiedIUR.Element{}` roots at the renderer-facing canonical boundary.

Required behavior:

- Screen roots expose canonical `type`, `kind`, `metadata`, `attributes`, and `children`.
- Ash resource identity and relationship context are preserved in metadata.
- Legacy string-keyed maps are rejected after the migration boundary.

### ash_ui.canonical_navigation.resource_authored_intent

Ash UI resources declare navigation as semantic intent that compiles into canonical Unified UI interactions.

Required behavior:

- Local destination, screen transition, replacement, history, modal open, and modal close intents are supported.
- Payloads and bindings remain symbolic and resource-oriented.
- Resource declarations do not include host runtime execution details.

### ash_ui.canonical_navigation.forbidden_host_fields

Canonical navigation declarations reject host route, URL, helper, runtime module, and stack reference fields.

Required behavior:

- Forbidden fields fail validation before runtime execution.
- Validation errors identify the field and resource declaration.
- Modal stack internals are never emitted in canonical output.

### ash_ui.canonical_navigation.runtime_transport

Runtime adapters preserve canonical interaction intent while resolving symbolic targets through the Ash UI graph.

Required behavior:

- Live, Elm, and desktop adapters consume `%UnifiedIUR.Element{}` inputs.
- Runtime transport receives canonical navigation actions and Ash metadata.
- Host execution is responsible for resolving symbolic navigation, not for authoring canonical intent.

## verification

### planned-tests

- `mix test test/ash_ui/rendering/iur_adapter_test.exs`
- `mix test test/ash_ui/phase_30_package_boundary_test.exs`
- `mix test test/ash_ui/canonical_navigation_test.exs`
- `mix test test/ash_ui/phase_30_runtime_adapter_test.exs`
- `mix test test/ash_ui/phase_30_integration_test.exs`
- `mix test test/ash_ui/phase_30_docs_conformance_test.exs`
- `bash ./scripts/validate_guides_governance.sh`

### conformance-checks

- Canonical package set compiles under Ash UI.
- `%UnifiedIUR.Element{}` output validates through the upgraded Unified IUR API.
- Forbidden navigation fields are rejected.
- Modal open and close navigation remain symbolic.
- Live, Elm, and desktop runtime adapters consume canonical elements.
- User and developer guides explain resource-authored navigation and the
  canonical renderer/runtime boundary.
