# Phase 31 - Canonical Widget Components Adoption

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces

- `UnifiedUi.WidgetComponents`, `UnifiedUi.Dsl.Entities.WidgetComponents`, and the upstream component catalog.
- `UnifiedIUR.Widgets.Components`, `UnifiedIUR.Element`, `UnifiedIUR.Normalize`, and `UnifiedIUR.Validate`.
- `AshUI.DSL.Storage`, `AshUI.Resource.DSL.Element`, and `AshUI.Resources.Validations.Authoring`.
- `AshUI.Compiler`, `AshUI.Rendering.IURAdapter`, and `AshUI.LiveView.IURHydration`.
- Runtime renderer adapters for Live, Elm, and desktop targets.
- `specs/contracts/canonical_widget_components_contract.md`.

## Relevant Assumptions / Defaults

- ADR-0005 remains the resource-authority baseline: Ash resources own screen composition and domain semantics.
- ADR-0006 remains the canonical IUR and navigation baseline: renderer-facing roots are `%UnifiedIUR.Element{}`.
- ADR-0007 defines the adoption target for canonical widget components.
- Cataloged components compile to canonical kinds, not `custom:*`.
- `custom:*` remains available for application-owned extensions that are outside the Unified catalog.
- Runtime packages own native rendering; Ash UI fallback rendering is compatibility support, not component semantic ownership.

[ ] 31 Phase 31 - Canonical Widget Components Adoption

This phase adopts the expanded Unified UI widget-component catalog as first-class Ash UI authoring input while preserving resource authority. It adds catalog drift detection, admission and alias normalization, canonical conversion, renderer fallback behavior, list-repeat composition, documentation, and end-to-end conformance.

## [x] 31.1 Section - Catalog Boundary And Drift Detection

This section establishes the canonical component catalog as a package boundary before Ash UI admits the new component kinds.

### [x] 31.1.1 Task - Mirror The Unified Component Catalog

This task records the component kinds, aliases, and families Ash UI must support from the upgraded Unified package set.

- [x] 31.1.1.1 Subtask - Add an Ash UI catalog helper or fixture that reads or mirrors `UnifiedUi.WidgetComponents.kinds/0`, aliases, and family metadata.
- [x] 31.1.1.2 Subtask - Include every canonical kind listed in `REQ-WIDGET-001` through `REQ-WIDGET-010`.
- [x] 31.1.1.3 Subtask - Mark `phoenix_form`, `repeat`, and `ui_relationship_repeat` as compatibility aliases.
- [x] 31.1.1.4 Subtask - Keep `inline_rich_text_heading` in the catalog as already-supported component coverage.

### [x] 31.1.2 Task - Add Package Boundary Tests

This task prevents partial adoption or silent drift between Ash UI and the Unified package catalog.

- [x] 31.1.2.1 Subtask - Add a package-boundary test comparing Ash UI's supported component set to `UnifiedUi.WidgetComponents.kinds/0`.
- [x] 31.1.2.2 Subtask - Add alias tests for `UnifiedUi.WidgetComponents.aliases/0` against Ash UI alias normalization.
- [x] 31.1.2.3 Subtask - Add an explicit exclusion mechanism if Ash UI intentionally delays any upstream component.
- [x] 31.1.2.4 Subtask - Fail package-boundary tests when a new upstream component appears without an Ash UI adoption decision.

## [x] 31.2 Section - Resource And Persisted DSL Admission

This section admits canonical widget components into Ash UI's resource-first authoring and persisted payload validation paths.

### [x] 31.2.1 Task - Extend Widget Type Admission

This task updates persisted DSL and resource validation so cataloged component kinds are valid element types.

- [x] 31.2.1.1 Subtask - Update `AshUI.DSL.Storage.valid_widget_type?/1` to admit all canonical widget-component kinds.
- [x] 31.2.1.2 Subtask - Update `AshUI.Resources.Validations.Authoring.validate_element_definition!/1` paths if they require component-specific admission.
- [x] 31.2.1.3 Subtask - Ensure invalid component names still fail validation.
- [x] 31.2.1.4 Subtask - Preserve support for existing non-component widgets, layouts, and `custom:*` extensions.

### [x] 31.2.2 Task - Normalize Compatibility Aliases

This task keeps migration-friendly aliases at the authoring boundary while emitting canonical component names downstream.

- [x] 31.2.2.1 Subtask - Normalize `phoenix_form` to `runtime_form_shell`.
- [x] 31.2.2.2 Subtask - Normalize `repeat` and `ui_relationship_repeat` to `list_repeat`.
- [x] 31.2.2.3 Subtask - Add diagnostics that identify the alias and canonical replacement.
- [x] 31.2.2.4 Subtask - Add tests proving aliases never appear as renderer-facing canonical kinds.

## [x] 31.3 Section - Canonical Conversion And Validation

This section maps Ash UI component props and metadata into the canonical Unified IUR component shapes.

### [x] 31.3.1 Task - Map Component Attributes

This task updates `AshUI.Rendering.IURAdapter` so each component family compiles to the correct canonical attribute namespace.

- [x] 31.3.1.1 Subtask - Map content identity and disclosure components: `inline_rich_text_heading`, `disclosure`, `kicker`, `avatar`, and `presence_dot`.
- [x] 31.3.1.2 Subtask - Map form control and composer components: `runtime_form_shell`, `segmented_button_group`, and `chat_composer`.
- [x] 31.3.1.3 Subtask - Map row and artifact components: `list_item_multi_column` and `artifact_row`.
- [x] 31.3.1.4 Subtask - Map workflow progress and status components: `pipeline_stepper_horizontal`, `segmented_progress_bar`, `workflow_stage_list_vertical`, and `meter_thin`.
- [x] 31.3.1.5 Subtask - Map layer shell and callout components: `sticky_frosted_header`, `slide_over_panel`, and `event_callout`.
- [x] 31.3.1.6 Subtask - Map redline and code components: `redline_inline` and `code_block_syntax_highlighted`.

### [x] 31.3.2 Task - Validate Canonical Component Output

This task proves Ash UI's canonical output matches the upgraded Unified IUR component contracts.

- [x] 31.3.2.1 Subtask - Add canonical conversion tests for each component family.
- [x] 31.3.2.2 Subtask - Run component outputs through `UnifiedIUR.Normalize.element/1` and `UnifiedIUR.Validate.element/1`.
- [x] 31.3.2.3 Subtask - Add negative validation coverage for required shapes on redline, code, slide-over, meter, segmented control, and repeat components.
- [x] 31.3.2.4 Subtask - Preserve Ash resource identity and relationship metadata under Ash-owned metadata keys only.

## [x] 31.4 Section - Runtime Renderer Adapter Support

This section ensures canonical component identity survives Live, Elm, and desktop rendering paths.

### [x] 31.4.1 Task - Preserve Native Renderer Dispatch

This task routes canonical component nodes to runtime packages without losing kind identity.

- [x] 31.4.1.1 Subtask - Verify Live renderer dispatch accepts `%UnifiedIUR.Element{}` component nodes.
- [x] 31.4.1.2 Subtask - Verify Elm renderer dispatch accepts `%UnifiedIUR.Element{}` component nodes.
- [x] 31.4.1.3 Subtask - Verify desktop renderer dispatch accepts `%UnifiedIUR.Element{}` component nodes.
- [x] 31.4.1.4 Subtask - Add structured unsupported-component diagnostics for runtime packages that lack a native component renderer.

### [x] 31.4.2 Task - Add Semantic Fallback Rendering

This task adds adapter fallback output for components where Ash UI needs compatibility rendering.

- [x] 31.4.2.1 Subtask - Add safe fallback rendering for content, identity, disclosure, row, artifact, callout, redline, code, and progress components.
- [x] 31.4.2.2 Subtask - Preserve accessibility labels, roles, selected states, open states, and progress values.
- [x] 31.4.2.3 Subtask - Escape user-provided text and token content in fallback renderers.
- [x] 31.4.2.4 Subtask - Avoid literal colors, font families, and theme-owned values in fallback output.

## [x] 31.5 Section - List Repeat Composition Behavior

This section adopts canonical `list_repeat` without introducing a parallel non-resource authoring model.

### [x] 31.5.1 Task - Add Relationship Repeat Declarations

This task lets Ash resource relationships declare repeated row composition through a list binding.

- [x] 31.5.1.1 Subtask - Extend `ui_relationships` to declare the list binding used for repeat composition.
- [x] 31.5.1.2 Subtask - Validate repeat declarations against `has_many` relationships and `:list` bindings.
- [x] 31.5.1.3 Subtask - Reject repeat declarations on unsupported relationship shapes.
- [x] 31.5.1.4 Subtask - Encode repeat metadata in the resource authority payload.

### [x] 31.5.2 Task - Hydrate Row-Scoped Repeat Templates

This task connects row data to repeated child templates while preserving canonical repeat intent.

- [x] 31.5.2.1 Subtask - Support row-scoped binding sources for repeated templates.
- [x] 31.5.2.2 Subtask - Project row fields into repeated child props during hydration.
- [x] 31.5.2.3 Subtask - Preserve canonical `list_repeat` metadata where renderer validation supports it.
- [x] 31.5.2.4 Subtask - Expand repeat templates into concrete children for fallback renderers that require concrete trees.

## [x] 31.6 Section - Documentation, Examples, And Migration Guidance

This section updates public docs and examples so users know when to use canonical components versus custom extensions.

### [x] 31.6.1 Task - Update User And Developer Guides

This task documents the supported catalog and the adoption boundary.

- [x] 31.6.1.1 Subtask - Add user guide coverage for canonical widget-component names, families, and aliases.
- [x] 31.6.1.2 Subtask - Add developer guide coverage for catalog ownership, canonical attributes, validation, and fallback rendering.
- [x] 31.6.1.3 Subtask - Document `custom:*` as an extension boundary for non-catalog application widgets.
- [x] 31.6.1.4 Subtask - Document migration from `phoenix_form`, `repeat`, `ui_relationship_repeat`, and older custom component names to canonical kinds.

### [x] 31.6.2 Task - Add Component Examples

This task gives each component family at least one resource-authored example surface.

- [x] 31.6.2.1 Subtask - Add examples for content identity and disclosure components.
- [x] 31.6.2.2 Subtask - Add examples for form control, composer, row, and artifact components.
- [x] 31.6.2.3 Subtask - Add examples for workflow, progress, layer, callout, redline, and code components.
- [x] 31.6.2.4 Subtask - Add a list-repeat example using relationship-owned row templates.

## [ ] 31.7 Section - Phase 31 Integration Tests

This final section proves canonical widget components work as one adoption path across package catalog, resource admission, canonical conversion, runtime rendering, docs, and examples.

### [ ] 31.7.1 Task - Run End-To-End Component Adoption Scenarios

This task validates Phase 31 as a complete integration instead of isolated component render clauses.

- [ ] 31.7.1.1 Subtask - Verify the Ash UI supported component catalog matches `UnifiedUi.WidgetComponents`.
- [ ] 31.7.1.2 Subtask - Verify every canonical component kind and alias is admitted at the resource and persisted DSL boundaries.
- [ ] 31.7.1.3 Subtask - Verify every component family compiles into valid `%UnifiedIUR.Element{}` output.
- [ ] 31.7.1.4 Subtask - Verify Live, Elm, and desktop adapter paths preserve or render representative component families.
- [ ] 31.7.1.5 Subtask - Verify list-repeat declarations compile and hydrate through relationship-owned templates.
- [ ] 31.7.1.6 Subtask - Verify docs and examples cover the catalog, aliases, fallback behavior, and extension boundary.
- [ ] 31.7.1.7 Subtask - Run the targeted Phase 31 suite and governance validation before marking the phase complete.
