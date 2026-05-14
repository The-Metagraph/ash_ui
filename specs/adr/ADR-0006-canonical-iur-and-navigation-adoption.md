# ADR-0006: Canonical IUR And Navigation Adoption

## Status

**Accepted**

Implementation is planned in Phase 30. Until that phase is complete, ADR-0005 remains the active runtime baseline for shipped Ash UI behavior.

## Context

Ash UI currently treats Ash resources and relationship graphs as the authority for screen composition, with Unified UI constructs embedded into those resources. That ownership model was established by ADR-0005.

The upstream Unified UI package set has introduced a newer canonical model:

1. Canonical IUR is represented as `%UnifiedIUR.Element{}` structs with typed `type`, `kind`, `metadata`, `attributes`, and `children` fields.
2. Navigation is represented as canonical interaction intent instead of host routes, URLs, router helpers, runtime module names, or modal stack identifiers.
3. Runtime packages consume canonical element structs and use the `LiveUi`, `ElmUi`, and `DesktopUi` module namespaces.
4. The previous `UnifiedIUR.validate/1` boundary is no longer the right validation surface for the upgraded package set.

Ash UI still emits the older string-keyed canonical map shape in several rendering paths. A package upgrade alone is therefore insufficient: adoption requires a coordinated contract migration across dependency boundaries, IUR conversion, resource-authored navigation declarations, renderer adapters, guides, and tests.

## Decision

### 1. Adopt Unified IUR Structs As The Canonical Rendering Boundary

Ash UI will adopt `%UnifiedIUR.Element{}` as the canonical output passed to runtime renderers.

Intermediate Ash UI compilation stages may keep private transitional shapes where useful, but the renderer-facing canonical boundary must be the upgraded Unified IUR struct model. Legacy string-keyed maps are migration input only and must not remain the public renderer contract after Phase 30.

### 2. Preserve Ash Resource Authority

ADR-0005 remains in force. Ash resources own the application graph, screen composition, relationships, policies, and domain semantics.

Unified UI owns reusable construct semantics, canonical IUR element types, canonical interaction definitions, and renderer-facing transport contracts. Ash UI adapts resource-authored intent into those canonical forms.

### 3. Adopt Canonical Navigation Intent

Ash UI resources will declare navigation through semantic intent that compiles into Unified UI canonical navigation interactions.

The supported canonical actions are:

- `:navigate_to`
- `:replace_with`
- `:go_back`
- `:go_forward`
- `:open_modal`
- `:close_modal`

Targets remain symbolic and host independent. Ash UI must reject navigation declarations that depend on host runtime details such as route paths, URLs, router helpers, runtime modules, stack identifiers, modal stack identifiers, or framework-specific navigation primitives.

### 4. Treat Modal Navigation As Symbolic Stack Intent

Opening a modal declares a symbolic modal target and payload. Closing a modal declares either the topmost modal or a named symbolic modal target.

Canonical modal navigation must not expose runtime stack references, modal stack identifiers, or host-managed stack internals.

### 5. Upgrade Package Boundaries As A Compatible Set

Ash UI will upgrade the local Unified package set as a coordinated dependency change. `unified_iur`, `unified_ui`, and runtime packages must be compatible with each other before Ash UI switches its canonical boundary.

Ash UI will use dependency declarations compatible with its existing Ash/Spark dependency graph. It must not introduce a vendored Spark copy that conflicts with Ash UI's runtime dependency surface.

### 6. Update Runtime Adapter Contracts

Runtime adapters must be updated to the upgraded package contracts and module namespaces. Renderer adapters must consume `%UnifiedIUR.Element{}` roots and return runtime-specific artifacts without assuming the legacy map shape.

### 7. Make Conformance Testable

Canonical navigation adoption must be covered by spec requirements, contract tests, and phase integration tests. The implementation is not complete until package compatibility, struct IUR validation, resource-authored navigation, modal semantics, forbidden-field rejection, and runtime renderer consumption are covered together.

## Consequences

### Positive

- Ash UI aligns with the upstream canonical Unified UI and Unified IUR model.
- Navigation declarations become portable across LiveView, Elm, desktop, and future runtimes.
- Resource-authored UI remains host independent and easier to inspect in generated specs.
- Renderer adapters receive a stronger typed boundary than string-keyed maps.

### Negative

- This is a cross-cutting migration that cannot be safely completed by only updating `mix.exs`.
- Existing tests that assert old map shapes will need to move to struct-aware assertions.
- Runtime adapter modules, renderer dispatch, and package namespaces need coordinated updates.
- Existing examples and guides that imply route/path navigation need revision.

### Required Follow-Through

- Create and maintain a canonical navigation contract under `specs/contracts/`.
- Add `.spec` coverage for canonical navigation adoption.
- Implement Phase 30 before treating the upgraded package set as the shipped baseline.
- Update user and developer guides once the resource DSL and renderer boundary are implemented.

## Related

- [ADR-0005: Element Resource Authority And Relational Screen Composition](./ADR-0005-element-resource-authority-and-relational-screen-composition.md)
- [Canonical Navigation And IUR Adoption Contract](../contracts/canonical_navigation_contract.md)
- [Phase 30 - Canonical IUR And Navigation Adoption](../planning/phase-30-canonical-iur-and-navigation-adoption.md)

## References

- `UnifiedUi.Signal` canonical navigation helpers and actions
- `UnifiedIUR.Interaction`
- `UnifiedIUR.Interactions.Transport`
- `UnifiedIUR.Element`
