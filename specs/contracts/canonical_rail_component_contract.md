# Canonical Rail Component Contract

Back to index: [README](../README.md)

## Purpose

This contract defines the requirements for adopting a reusable canonical rail component across the Unified package set, runtime renderers, and Ash UI.

It applies to Phase 32 and builds on the Phase 30 `%UnifiedIUR.Element{}` boundary and the Phase 31 canonical widget-component adoption line. It does not replace Ash resource authority.

## Control Plane Ownership

- `AshUI.Resource` owns resource-authored rail placement, relationships, panel content, bindings, actions, authorization, and policies.
- `AshUI.Compiler` owns graph-derived IUR assembly from persisted Ash UI resources.
- `AshUI.Rendering` owns conversion from Ash UI IUR into canonical Unified IUR rail elements.
- `AshUI.LiveView` and `AshUI.Runtime` own runtime hydration, event bridging, and host integration.
- Unified UI and Unified IUR own the canonical `right_rail` name, attribute contract, validation, and renderer-facing semantics.
- Runtime packages own native rail rendering and host-specific event transport.

## Canonical Scope

Ash UI MUST adopt this canonical widget component when Phase 32 lands:

| Canonical kind | Family | Compatibility aliases |
| --- | --- | --- |
| `right_rail` | layer shell and callout | - |

Application-specific names such as `doc_right_rail` are not canonical aliases. They may exist as application-local wrapper modules, example names, or resource compositions that emit canonical `right_rail` output.

## Canonical Attribute Shape

The canonical rail attributes MUST be renderer independent and grouped under a rail-specific namespace.

Required canonical concepts:

- `rail.id`: stable rail identity within the screen.
- `rail.side`: semantic side, initially `:right`.
- `rail.panels`: ordered panel descriptors.
- `rail.active_panel`: selected panel id.
- `rail.collapsed?`: optional collapsed state.
- `rail.collapsible?`: whether the rail exposes collapse behavior.
- `rail.interactions.panel_select`: semantic panel-selection interaction.
- `rail.interactions.collapse_change`: semantic collapse-change interaction.

Panel descriptors SHOULD support:

- `id`
- `label`
- `icon`
- `badge`
- `disabled?`
- `metadata`
- `empty_state`
- `content_slot`

Concrete CSS values, sticky offsets, pixel widths, routes, helper names, LiveView event strings, runtime modules, and host stack identifiers MUST NOT be part of the canonical attribute contract.

## Requirements

### REQ-RAIL-001 - Generic Canonical Name

Ash UI MUST treat `right_rail` as the canonical component kind for reusable rail behavior.

Acceptance criteria:

- `doc_right_rail` is not admitted as a canonical package kind.
- Document-specific rail behavior composes to `right_rail`.
- Renderer-facing canonical IUR emits `kind: :right_rail` for this component.

### REQ-RAIL-002 - Catalog And Family Alignment

Unified and Ash package metadata MUST agree that `right_rail` belongs to the layer shell and callout family.

Acceptance criteria:

- `UnifiedUi.WidgetComponents` reports `right_rail` in the layer shell and callout family.
- Unified IUR component metadata uses the same family.
- Live UI widget metadata and registry discovery use the same family.
- Package-boundary tests fail on family drift.

### REQ-RAIL-003 - Unified UI Authoring Path

Unified UI MUST expose a first-class DSL and compiler path for `right_rail`.

Acceptance criteria:

- `UnifiedUi.Dsl.Entities.WidgetComponents` defines the rail entity.
- The Unified UI compiler lowers DSL-authored rail declarations into canonical IUR attributes.
- Invalid panel declarations fail before renderer dispatch.

### REQ-RAIL-004 - Unified IUR Constructor And Validation

Unified IUR MUST provide constructor and validation support for the canonical rail shape.

Acceptance criteria:

- `UnifiedIUR.Widgets.Components.right_rail/1` builds a canonical `%UnifiedIUR.Element{}`.
- `UnifiedIUR.Validate.element/1` validates required rail and panel fields.
- Validation rejects an active panel that is absent from `rail.panels`.
- Validation rejects renderer-specific event strings as canonical interaction definitions.

### REQ-RAIL-005 - Ash Resource Admission

Ash UI MUST admit `right_rail` through resource-first and persisted DSL authoring paths.

Acceptance criteria:

- `AshUI.Resource.DSL.Element` accepts `right_rail`.
- persisted DSL validation accepts `right_rail`.
- invalid rail-like custom names are rejected unless explicitly authored as `custom:*`.
- authoring errors identify the affected resource or element.

### REQ-RAIL-006 - Ash Canonical Conversion

Ash UI MUST convert resource-authored rail declarations into the canonical `right_rail` attribute shape.

Acceptance criteria:

- `AshUI.Rendering.IURAdapter` maps rail props into the canonical rail namespace.
- Ash-owned metadata stays under Ash-owned metadata keys.
- unknown props cannot overwrite canonical `rail` or `component` metadata.
- converted rail output validates through Unified IUR.

### REQ-RAIL-007 - Slot And Child Preservation

Rail panel content MUST be preserved through canonical children or named slots.

Acceptance criteria:

- each panel can reference a stable content slot.
- renderer dispatch maps canonical slot content into the native rail component.
- fallback rendering preserves panel body children.
- no renderer path silently drops rail children.

### REQ-RAIL-008 - Semantic Interactions

Rail interactions MUST be semantic and host independent.

Acceptance criteria:

- panel selection uses a structured canonical interaction.
- collapse changes use a separate structured canonical interaction.
- LiveView event names are generated or translated inside Live UI, not stored as canonical attributes.
- interaction payloads preserve source rail id and selected panel id.

### REQ-RAIL-009 - Runtime Renderer Support

Runtime renderers MUST either render `right_rail` natively or preserve it with structured diagnostics.

Acceptance criteria:

- Live UI renders the rail natively and registers it in widget discovery.
- Elm and desktop renderers preserve the canonical kind or return structured unsupported-component diagnostics until native support exists.
- unsupported diagnostics include renderer name, component kind, and element id.
- fallback behavior keeps canonical kind identity visible.

### REQ-RAIL-010 - Theme And Layout Boundary

The canonical rail MUST avoid host-owned concrete layout and theme values.

Acceptance criteria:

- concrete widths, sticky offsets, CSS classes, colors, and breakpoints are renderer/theme concerns.
- canonical attributes may express semantic width intent or density.
- renderer docs describe default layout behavior without making it a canonical requirement.

### REQ-RAIL-011 - Documentation And Examples

Ash UI MUST document the rail as a reusable canonical component and show document rail composition as an example, not as the canonical kind.

Acceptance criteria:

- user guides describe how to author `right_rail`.
- developer guides describe the package boundary, validation, slots, and runtime support.
- examples include at least one document-oriented composition that emits `right_rail`.
- docs explain why `doc_right_rail` is application composition rather than canonical vocabulary.

### REQ-RAIL-012 - Conformance And Drift Detection

Ash UI MUST add conformance coverage for the complete rail adoption path.

Acceptance criteria:

- package-boundary tests compare catalog and family metadata.
- constructor and validation tests cover valid and invalid rail shapes.
- Unified UI compiler tests cover DSL-authored rail output.
- Ash UI adapter tests cover resource-authored canonical conversion.
- renderer tests cover native Live UI rendering, slot preservation, semantic interactions, and unsupported-runtime diagnostics.

## Traceability

| Requirement | Source | Planned Implementation |
| --- | --- | --- |
| REQ-RAIL-001 | ADR-0008 | Phase 32.1 |
| REQ-RAIL-002 | ADR-0008 | Phase 32.1 |
| REQ-RAIL-003 | ADR-0008 | Phase 32.2 |
| REQ-RAIL-004 | ADR-0008 | Phase 32.3 |
| REQ-RAIL-005 | ADR-0008 | Phase 32.4 |
| REQ-RAIL-006 | ADR-0008 | Phase 32.4 |
| REQ-RAIL-007 | ADR-0008 | Phase 32.5 |
| REQ-RAIL-008 | ADR-0008 | Phase 32.5 |
| REQ-RAIL-009 | ADR-0008 | Phase 32.6 |
| REQ-RAIL-010 | ADR-0008 | Phase 32.6 |
| REQ-RAIL-011 | ADR-0008 | Phase 32.7 |
| REQ-RAIL-012 | ADR-0008 | Phase 32.8 |

## Conformance

The Phase 32 integration test section is the acceptance gate for this contract. Conformance is complete when package-boundary, DSL, constructor, validation, Ash conversion, renderer, documentation, example, and end-to-end tests named in Phase 32 are implemented and passing.

## Related

- [ADR-0008: Canonical Rail Component Adoption](../adr/ADR-0008-canonical-rail-component-adoption.md)
- [ADR-0007: Canonical Widget Components Adoption](../adr/ADR-0007-canonical-widget-components-adoption.md)
- [ADR-0006: Canonical IUR And Navigation Adoption](../adr/ADR-0006-canonical-iur-and-navigation-adoption.md)
- [Phase 32 - Canonical Rail Component Adoption](../planning/phase-32-canonical-rail-component-adoption.md)
- [Canonical Widget Components Adoption Contract](./canonical_widget_components_contract.md)
- [Rendering Contract](./rendering_contract.md)
