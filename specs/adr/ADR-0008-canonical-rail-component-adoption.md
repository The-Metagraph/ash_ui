# ADR-0008: Canonical Rail Component Adoption

## Status

**Accepted**

Planned for Phase 32. ADR-0005 remains the active resource-authority baseline, ADR-0006 remains the canonical IUR/navigation boundary baseline, and ADR-0007 remains the canonical widget-component catalog baseline.

## Context

Ash UI now treats Unified widget components as first-class canonical vocabulary. Recent rail-style UI work needs a persistent side panel with selectable panels, collapse behavior, badges, empty states, and slotted content. A document-specific rail can be useful in an application, but making that exact shape canonical would leak application language, tab names, document identifiers, placeholder copy, and LiveView event names into the shared package set.

The existing architecture requires canonical components to stay reusable, semantic, renderer independent, and resource-authority friendly. A rail component must therefore be defined as a generic shell or panel primitive that applications can compose into document rails, inspector rails, source rails, activity rails, or assistant rails without changing the canonical contract.

## Decision

### 1. Adopt A Generic Canonical Rail Component

Ash UI will adopt a reusable canonical `right_rail` component as the shared rail vocabulary.

The canonical component represents a side rail with panel descriptors, selected panel state, optional collapse state, semantic interactions, and named panel content slots. Application-specific names such as `doc_right_rail` are not canonical component kinds.

Applications may build a document rail by composing `right_rail` with domain-specific panel descriptors and content. That composition remains application-owned unless and until a separate reusable canonical contract is accepted.

### 2. Keep The Rail In The Layer Shell And Callout Family

The rail belongs to the `:layer_shell_and_callout` component family because it is a shell surface adjacent to primary content. The family assignment must be consistent across:

- `UnifiedUi.WidgetComponents`
- `UnifiedUi.Dsl.Entities.WidgetComponents`
- `UnifiedUi.Compiler`
- `UnifiedIUR.Widgets.Components`
- `UnifiedIUR.Validate`
- runtime renderer metadata and registries
- Ash UI canonical conversion and renderer adapters

The implementation must not classify the rail as navigation unless a future ADR redefines the canonical family model.

### 3. Use Semantic Panel And Collapse Interactions

The canonical contract must expose semantic interactions for panel selection and collapse changes. It must not encode LiveView event strings, routes, paths, helper names, runtime modules, or renderer-specific event transports.

Runtime packages may translate those semantic interactions into host events internally, but the renderer-facing IUR remains canonical and host independent.

### 4. Preserve Resource Authority And Slot Composition

Ash screen and element resources remain the authoring authority for rail placement, child content, bindings, actions, and policies.

The rail may describe panels through canonical attributes, but panel bodies must be supplied through canonical children or named slots so application content is not hardcoded into the component implementation. Renderers must not silently drop rail children.

### 5. Keep Concrete Layout And Theme Choices Host-Owned

The canonical rail may expose semantic layout intent such as side, placement, density, width intent, and collapsibility. Concrete pixel widths, sticky positioning CSS, breakpoints, colors, typography, and shell treatment belong to renderer packages, themes, or host applications.

### 6. Require Complete Package-Boundary Adoption

The rail is not supported until the full package path is implemented:

- Unified UI catalog entry, DSL entity, and compiler lowering
- Unified IUR constructor, normalization, and validation
- Live UI native rendering and registry metadata
- Elm and desktop preservation or structured unsupported diagnostics
- Ash UI authoring admission, canonical conversion, adapter rendering, and tests
- documentation, examples, and conformance coverage

Partial adoption that only adds a Live UI component or constructor is not enough.

## Consequences

### Positive

- Rail behavior becomes reusable across document, inspector, activity, assistant, source, and operational side-panel surfaces.
- The canonical package vocabulary avoids app-specific labels and identifiers.
- Renderer packages can implement native rail UX while preserving one portable component contract.
- Ash UI keeps relationships, bindings, actions, policies, and slot content under resource authority.

### Negative

- Existing document-rail code must be generalized or wrapped as application composition.
- The rail cannot land as a narrow Live UI component only; it needs coordinated package work.
- Semantic interaction and named-slot support require more validation and renderer coverage than a static panel.
- Some runtimes may initially preserve or diagnose the rail instead of rendering full native behavior.

### Required Follow-Through

- Add and maintain a canonical rail component contract under `specs/contracts/`.
- Add `.spec` coverage for the canonical rail adoption line.
- Implement Phase 32 before treating `right_rail` as supported Ash UI authoring input.
- Update user and developer guides after the package boundary, renderer support, and Ash UI adapter path are implemented.

## Related

- [ADR-0005: Element Resource Authority And Relational Screen Composition](./ADR-0005-element-resource-authority-and-relational-screen-composition.md)
- [ADR-0006: Canonical IUR And Navigation Adoption](./ADR-0006-canonical-iur-and-navigation-adoption.md)
- [ADR-0007: Canonical Widget Components Adoption](./ADR-0007-canonical-widget-components-adoption.md)
- [Canonical Rail Component Contract](../contracts/canonical_rail_component_contract.md)
- [Phase 32 - Canonical Rail Component Adoption](../planning/phase-32-canonical-rail-component-adoption.md)

## References

- `UnifiedUi.WidgetComponents`
- `UnifiedUi.Dsl.Entities.WidgetComponents`
- `UnifiedIUR.Widgets.Components`
- `UnifiedIUR.Validate`
- `AshUI.Rendering.IURAdapter`
- runtime renderer widget registries
