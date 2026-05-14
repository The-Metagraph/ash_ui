# ADR-0007: Canonical Widget Components Adoption

## Status

**Accepted**

Planned for Phase 31. ADR-0005 remains the active resource-authority baseline and ADR-0006 remains the canonical IUR/navigation boundary baseline.

## Context

Ash UI adopted the upgraded Unified IUR struct boundary and canonical navigation model in Phase 30. That work moved renderer-facing output to `%UnifiedIUR.Element{}` and kept Ash resources as the authoritative application graph.

The sibling Unified package set now exposes an expanded canonical widget-component catalog through:

- `UnifiedUi.WidgetComponents`
- `UnifiedUi.Dsl.Entities.WidgetComponents`
- `UnifiedIUR.Widgets.Components`

That catalog includes content, identity, disclosure, form, composer, row, artifact, workflow, progress, layer shell, callout, redline, code, and list-repeat components. Ash UI currently only admits and renders a narrow subset of that expanded catalog. Most of the new canonical kinds are not yet accepted as first-class Ash UI element types, are not normalized from compatibility aliases, and do not have explicit resource-authority, canonical conversion, fallback rendering, guide, or conformance coverage.

Without an Ash UI adoption line, consumers must either keep using `custom:*` escape hatches or author directly against Unified UI package internals. Both options weaken Ash UI's resource-first model and make parity with the upstream canonical catalog hard to test.

## Decision

### 1. Adopt The Unified Widget-Component Catalog As Ash UI's Canonical Component Vocabulary

Ash UI will adopt the expanded canonical widget-component catalog exposed by the Unified package set.

The canonical Ash UI names are the Unified names:

- `inline_rich_text_heading`
- `disclosure`
- `runtime_form_shell`
- `kicker`
- `avatar`
- `presence_dot`
- `segmented_button_group`
- `list_item_multi_column`
- `artifact_row`
- `sticky_frosted_header`
- `pipeline_stepper_horizontal`
- `segmented_progress_bar`
- `workflow_stage_list_vertical`
- `meter_thin`
- `slide_over_panel`
- `event_callout`
- `redline_inline`
- `code_block_syntax_highlighted`
- `chat_composer`
- `list_repeat`

Ash UI will treat upstream compatibility aliases as migration or convenience input only. In particular, `phoenix_form` normalizes to `runtime_form_shell`, and `repeat` or `ui_relationship_repeat` normalize to `list_repeat`.

### 2. Preserve Ash Resource Authority

ADR-0005 remains in force. Ash screen and element resources own resource identity, relationships, policies, bindings, actions, and runtime graph semantics.

Unified UI and Unified IUR own the portable component vocabulary, canonical component attributes, validation rules, and renderer-facing semantics. Ash UI adapts resource-authored intent into those canonical forms without making upstream package internals the authoring authority.

### 3. Prefer Canonical Kinds Over `custom:*` For Cataloged Components

Cataloged widget components must compile to canonical component kinds, not `custom:*` strings. `custom:*` remains available for application-owned extensions that are outside the Unified canonical catalog.

Ash UI may preserve legacy custom examples during migration, but new cataloged component work must use canonical kinds and attributes.

### 4. Use Upstream Constructors And Validators Where Practical

Ash UI should use `UnifiedIUR.Widgets.Components` constructors or equivalent attribute shapes where practical. Validation must stay aligned with `UnifiedIUR.Validate` and the component-specific contracts in the Unified package set.

Ash UI-specific metadata must remain namespaced under Ash-owned metadata keys and must not leak into renderer-owned component attributes.

### 5. Treat List Repeat As Composition Behavior

`list_repeat` is a composition behavior, not a visual widget. Ash UI will map relationship-driven repeat declarations and row-scoped bindings to canonical `list_repeat` metadata while preserving Ash relationship authority.

Runtime hydration may expand repeated children for renderers that require concrete children, but the canonical declaration should preserve the repeat intent where the target renderer and validation boundary support it.

### 6. Align Runtime Rendering Without Duplicating Ownership

Runtime renderer packages own native rendering of canonical component kinds. Ash UI adapter fallback rendering may provide portable, semantic output where needed, but fallback output must preserve canonical kind identity, use semantic attributes, escape user text, and avoid literal visual tokens that should belong to themes.

Unsupported component behavior must fail with structured diagnostics or a documented fallback, not silent kind loss.

### 7. Make Adoption Testable

The adoption is not complete until Ash UI proves:

- every canonical widget component is admitted by the resource and persisted DSL paths,
- aliases normalize to canonical kinds,
- canonical IUR output validates,
- Live, Elm, and desktop adapter paths preserve or render the component contract,
- list repeat behavior works with relationship-owned row templates,
- guides and examples describe the catalog and extension boundary.

## Consequences

### Positive

- Ash UI aligns with the expanded Unified UI component vocabulary.
- Consumers can use canonical component names without bypassing Ash resource authority.
- Renderer-facing output becomes easier to validate against upstream package contracts.
- `custom:*` remains focused on true application extensions instead of filling catalog gaps.
- The prior PR 79-98 widget work has a durable adoption path even though the old PRs are closed.

### Negative

- The work spans DSL admission, validators, compiler conversion, runtime hydration, renderers, guides, and tests.
- Several components have richer contracts than older simple widgets, especially `runtime_form_shell`, `chat_composer`, `redline_inline`, `code_block_syntax_highlighted`, and `list_repeat`.
- Renderer packages may not all have native feature parity on day one, so fallback and unsupported diagnostics must be explicit.
- Existing custom examples may need migration to canonical kinds.

### Required Follow-Through

- Create and maintain a canonical widget-components contract under `specs/contracts/`.
- Add `.spec` coverage for the widget-component adoption line.
- Implement Phase 31 before treating the expanded component catalog as supported Ash UI authoring input.
- Update user and developer guides once admission, canonical conversion, and runtime support are implemented.

## Related

- [ADR-0005: Element Resource Authority And Relational Screen Composition](./ADR-0005-element-resource-authority-and-relational-screen-composition.md)
- [ADR-0006: Canonical IUR And Navigation Adoption](./ADR-0006-canonical-iur-and-navigation-adoption.md)
- [Canonical Widget Components Adoption Contract](../contracts/canonical_widget_components_contract.md)
- [Phase 31 - Canonical Widget Components Adoption](../planning/phase-31-canonical-widget-components-adoption.md)

## References

- `UnifiedUi.WidgetComponents`
- `UnifiedUi.Dsl.Entities.WidgetComponents`
- `UnifiedIUR.Widgets.Components`
- `UnifiedIUR.Validate`
