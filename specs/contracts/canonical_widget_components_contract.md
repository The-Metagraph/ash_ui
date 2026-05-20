# Canonical Widget Components Adoption Contract

Back to index: [README](../README.md)

## Purpose

This contract defines the Ash UI requirements for adopting the expanded canonical widget-component catalog from the Unified UI package set.

It applies to Phase 31 and builds on the Phase 30 `%UnifiedIUR.Element{}` renderer boundary. It does not replace Ash resource authority.

## Control Plane Ownership

- `AshUI.Resource` owns resource-authored UI declarations, relationships, bindings, actions, and policies.
- `AshUI.Compiler` owns graph-derived IUR assembly from persisted Ash UI resources.
- `AshUI.Rendering` owns conversion from Ash UI IUR into canonical Unified IUR component elements.
- `AshUI.LiveView` and `AshUI.Runtime` own runtime hydration, event bridging, and host integration.
- Unified UI and Unified IUR own canonical component names, component attribute contracts, validation, and renderer-facing semantics.

## Catalog Scope

Ash UI MUST adopt these canonical widget-component kinds:

| Canonical kind | Family | Compatibility aliases |
| --- | --- | --- |
| `inline_rich_text_heading` | content identity and disclosure | - |
| `disclosure` | content identity and disclosure | - |
| `runtime_form_shell` | form control and composer | `phoenix_form` |
| `kicker` | content identity and disclosure | - |
| `avatar` | content identity and disclosure | - |
| `presence_dot` | content identity and disclosure | - |
| `segmented_button_group` | form control and composer | - |
| `list_item_multi_column` | row and artifact | - |
| `artifact_row` | row and artifact | - |
| `thread_card` | row and artifact | - |
| `sticky_frosted_header` | layer shell and callout | - |
| `pipeline_stepper_horizontal` | workflow progress and status | - |
| `segmented_progress_bar` | workflow progress and status | - |
| `workflow_stage_list_vertical` | workflow progress and status | - |
| `meter_thin` | workflow progress and status | - |
| `slide_over_panel` | layer shell and callout | - |
| `event_callout` | layer shell and callout | - |
| `composer_query_preview` | layer shell and callout | - |
| `redline_inline` | redline and code | - |
| `code_block_syntax_highlighted` | redline and code | - |
| `chat_composer` | form control and composer | - |
| `list_repeat` | composition behavior | `repeat`, `ui_relationship_repeat` |

## Requirements

### REQ-WIDGET-001 - Authoritative Catalog Source

Ash UI MUST treat the Unified package widget-component catalog as the authoritative canonical component vocabulary.

Acceptance criteria:

- Ash UI reads or mirrors the canonical kind set from the upgraded Unified package set.
- Newly cataloged component kinds are not implemented as unrelated Ash-only names.
- Compatibility aliases normalize to canonical names before canonical IUR output.
- Tests fail when Ash UI's supported component set drifts from the Unified catalog without an explicit exclusion.

### REQ-WIDGET-002 - Resource And Persisted DSL Admission

Ash UI MUST admit every cataloged canonical widget component through its resource-first authoring and persisted DSL validation paths.

Acceptance criteria:

- `AshUI.Resource.DSL.Element` accepts each canonical kind.
- `AshUI.DSL.Storage.valid_widget_type?/1` accepts each canonical kind and supported alias.
- Invalid component kinds continue to fail validation.
- Existing supported non-component widgets and `custom:*` extensions remain valid.

### REQ-WIDGET-003 - Alias Normalization

Ash UI MUST normalize compatibility aliases before renderer-facing output.

Acceptance criteria:

- `phoenix_form` compiles to `runtime_form_shell`.
- `repeat` and `ui_relationship_repeat` compile to `list_repeat`.
- Diagnostics mention both the alias and the canonical replacement.
- Aliases are documented as compatibility input, not canonical authoring names.

### REQ-WIDGET-004 - Canonical Attribute Mapping

Ash UI MUST map component props into the canonical attribute namespaces expected by Unified IUR.

Acceptance criteria:

- Component attributes match `UnifiedIUR.Widgets.Components` constructor output where practical.
- Component family metadata is preserved when required by the upstream contract.
- Ash-owned resource metadata stays under Ash-owned metadata keys.
- Unknown passthrough props do not overwrite canonical namespaces.

### REQ-WIDGET-005 - Component Validation

Ash UI MUST validate canonical component output against the upgraded Unified IUR validation surface.

Acceptance criteria:

- Valid component examples pass `UnifiedIUR.Normalize.element/1` and `UnifiedIUR.Validate.element/1`.
- Invalid component payloads produce structured errors with resource and element context.
- Redline, code, slide-over, meter, segmented control, and list-repeat contracts get negative coverage for their required shapes.

### REQ-WIDGET-006 - Renderer Adapter Preservation

Ash UI MUST preserve canonical component identity across Live, Elm, and desktop adapter paths.

Acceptance criteria:

- Runtime adapters pass `%UnifiedIUR.Element{}` component nodes to native renderers when available.
- Adapter fallback rendering keeps the canonical kind visible in markup or structured output.
- Unsupported component diagnostics include renderer name, component kind, and element id.
- Renderer adapters do not silently coerce cataloged components to `custom:*`.

### REQ-WIDGET-007 - Semantic Fallback Rendering

Ash UI fallback rendering SHOULD provide semantic, safe output for cataloged components where native renderer support is missing.

Acceptance criteria:

- Fallback output escapes user-provided text.
- Fallback output avoids literal colors, font families, and theme-owned tokens.
- Accessibility labels, roles, selected states, open states, and progress values are preserved.
- Components with children render children through the standard canonical child path.

### REQ-WIDGET-008 - List Repeat Composition

Ash UI MUST support canonical `list_repeat` as relationship-driven composition behavior.

Acceptance criteria:

- Relationship declarations can identify a list binding used for repeated row data.
- Row-scoped bindings can project row fields into the repeated template.
- Canonical output preserves `list_repeat` metadata where supported.
- Hydration can expand repeat templates into concrete children for renderers that require expanded trees.
- Repeat behavior remains limited to resource-authority relationships and does not introduce a parallel screen-document authoring model.

### REQ-WIDGET-009 - Documentation And Examples

Ash UI MUST document canonical widget components for users and developers.

Acceptance criteria:

- User guides list the supported canonical component kinds and aliases.
- Developer guides explain catalog ownership, attribute mapping, renderer fallback behavior, and extension boundaries.
- Examples use canonical names for cataloged components instead of `custom:*`.
- Migration notes explain when to replace old custom widget names with canonical component names.

### REQ-WIDGET-010 - Conformance And Drift Detection

Ash UI MUST add conformance coverage that catches catalog, validation, and renderer drift.

Acceptance criteria:

- A package-boundary test compares Ash UI admission against `UnifiedUi.WidgetComponents.kinds/0`.
- Conversion tests assert canonical `%UnifiedIUR.Element{}` output for every component family.
- Runtime adapter tests cover Live, Elm, and desktop handling for representative components.
- Integration tests cover an end-to-end resource-authored screen using at least one component from each family.

## Traceability

| Requirement | Source | Planned Implementation |
| --- | --- | --- |
| REQ-WIDGET-001 | ADR-0007 | Phase 31.1 |
| REQ-WIDGET-002 | ADR-0007 | Phase 31.2 |
| REQ-WIDGET-003 | ADR-0007 | Phase 31.2 |
| REQ-WIDGET-004 | ADR-0007 | Phase 31.3 |
| REQ-WIDGET-005 | ADR-0007 | Phase 31.3, Phase 31.7 |
| REQ-WIDGET-006 | ADR-0007 | Phase 31.4 |
| REQ-WIDGET-007 | ADR-0007 | Phase 31.4 |
| REQ-WIDGET-008 | ADR-0007 | Phase 31.5 |
| REQ-WIDGET-009 | ADR-0007 | Phase 31.6 |
| REQ-WIDGET-010 | ADR-0007 | Phase 31.7 |

## Conformance

The Phase 31 integration test section is the acceptance gate for this contract. Conformance is complete when the package-boundary, admission, canonical conversion, renderer adapter, list-repeat, guide, and end-to-end tests named in Phase 31 are implemented and passing.

## Related

- [ADR-0007: Canonical Widget Components Adoption](../adr/ADR-0007-canonical-widget-components-adoption.md)
- [ADR-0006: Canonical IUR And Navigation Adoption](../adr/ADR-0006-canonical-iur-and-navigation-adoption.md)
- [Phase 31 - Canonical Widget Components Adoption](../planning/phase-31-canonical-widget-components-adoption.md)
- [Rendering Contract](./rendering_contract.md)
- [Compilation Contract](./compilation_contract.md)
- [Resource Contract](./resource_contract.md)
