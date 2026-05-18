# Phase 32 - Canonical Rail Component Adoption

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces

- `UnifiedUi.WidgetComponents`, `UnifiedUi.Dsl.Entities.WidgetComponents`, and the Unified UI compiler pipeline.
- `UnifiedIUR.Widgets.Components`, `UnifiedIUR.Element`, `UnifiedIUR.Normalize`, and `UnifiedIUR.Validate`.
- `AshUI.DSL.Storage`, `AshUI.Resource.DSL.Element`, and `AshUI.Resources.Validations.Authoring`.
- `AshUI.Compiler`, `AshUI.Rendering.IURAdapter`, and `AshUI.LiveView.IURHydration`.
- Runtime renderer adapters for Live, Elm, and desktop targets.
- `specs/contracts/canonical_rail_component_contract.md`.

## Relevant Assumptions / Defaults

- ADR-0005 remains the resource-authority baseline: Ash resources own screen composition and domain semantics.
- ADR-0006 remains the canonical IUR and navigation baseline: renderer-facing roots are `%UnifiedIUR.Element{}`.
- ADR-0007 remains the canonical widget-component catalog baseline.
- ADR-0008 defines `right_rail` as the reusable canonical rail component.
- Application-specific names such as `doc_right_rail` are composition names, not canonical package vocabulary.
- Concrete CSS, sticky offsets, pixel widths, colors, and runtime event names belong to hosts or renderers, not canonical IUR.

[x] 32 Phase 32 - Canonical Rail Component Adoption

This phase adopts a reusable canonical `right_rail` component across Unified UI, Unified IUR, runtime renderers, and Ash UI while preserving resource authority. It replaces document-specific rail vocabulary with generic rail panels, semantic interactions, named content slots, package-boundary validation, renderer support, documentation, examples, and conformance coverage.

## [x] 32.1 Section - Canonical Decision And Catalog Boundary

This section establishes the rail as a reusable canonical component before any runtime implementation is treated as supported.

### [x] 32.1.1 Task - Define The Canonical Rail Vocabulary

This task records the canonical name, family, and app-specific extension boundary.

- [x] 32.1.1.1 Subtask - Add `right_rail` to the Unified component catalog as the canonical kind.
- [x] 32.1.1.2 Subtask - Assign `right_rail` to the layer shell and callout family.
- [x] 32.1.1.3 Subtask - Keep `doc_right_rail` out of the canonical alias set.
- [x] 32.1.1.4 Subtask - Document that document rails compose domain panels on top of canonical `right_rail`.

### [x] 32.1.2 Task - Add Package Boundary Guardrails

This task prevents partial or inconsistent rail adoption across packages.

- [x] 32.1.2.1 Subtask - Add package-boundary tests for catalog membership.
- [x] 32.1.2.2 Subtask - Add package-boundary tests for family metadata consistency.
- [x] 32.1.2.3 Subtask - Fail conformance when a renderer registers `right_rail` under a different family.
- [x] 32.1.2.4 Subtask - Add an explicit unsupported-runtime diagnostic expectation for renderers without native rail support.

## [x] 32.2 Section - Unified UI DSL And Compiler Support

This section makes `right_rail` authorable through the Unified UI DSL without relying on application-specific component names.

### [x] 32.2.1 Task - Add The DSL Entity

This task adds a first-class `right_rail` DSL entity to the Unified UI component entity set.

- [x] 32.2.1.1 Subtask - Define rail options for id, side, panels, active panel, collapse state, and semantic layout intent.
- [x] 32.2.1.2 Subtask - Define panel descriptor options for id, label, icon, badge, disabled state, metadata, empty state, and content slot.
- [x] 32.2.1.3 Subtask - Reject renderer-specific event strings, CSS values, routes, helpers, and runtime modules in DSL options.
- [x] 32.2.1.4 Subtask - Add DSL documentation examples using generic panel names.

### [x] 32.2.2 Task - Lower DSL Rails Into Canonical IUR

This task updates the Unified UI compiler to produce the canonical rail attribute shape.

- [x] 32.2.2.1 Subtask - Lower rail options into `attributes.rail`.
- [x] 32.2.2.2 Subtask - Lower panel descriptors into ordered canonical panel metadata.
- [x] 32.2.2.3 Subtask - Lower panel body declarations into canonical children or named slots.
- [x] 32.2.2.4 Subtask - Add compiler tests proving DSL rails do not fall through to generic element lowering.

## [x] 32.3 Section - Unified IUR Constructor And Validation

This section gives the canonical rail a stable renderer-facing constructor and validation contract.

### [x] 32.3.1 Task - Add The Rail Constructor

This task adds a constructor that builds a canonical `%UnifiedIUR.Element{}` for `right_rail`.

- [x] 32.3.1.1 Subtask - Implement `UnifiedIUR.Widgets.Components.right_rail/1`.
- [x] 32.3.1.2 Subtask - Include `attributes.component.family: :layer_shell_and_callout`.
- [x] 32.3.1.3 Subtask - Normalize panel ids and active panel values consistently.
- [x] 32.3.1.4 Subtask - Add positive constructor tests for minimal and full rail declarations.

### [x] 32.3.2 Task - Validate Rail Contracts

This task makes invalid rail payloads fail before renderer dispatch.

- [x] 32.3.2.1 Subtask - Validate required rail id, side, panel list, and active panel membership.
- [x] 32.3.2.2 Subtask - Validate panel descriptor ids, labels, disabled states, badges, and content slots.
- [x] 32.3.2.3 Subtask - Validate panel selection and collapse interactions as semantic canonical interactions.
- [x] 32.3.2.4 Subtask - Add negative tests for missing panels, invalid active panel, duplicate panel ids, and LiveView event-string leakage.

## [x] 32.4 Section - Ash UI Resource Admission And Canonical Conversion

This section admits resource-authored rails and maps them into canonical Unified IUR without bypassing Ash resource authority.

### [x] 32.4.1 Task - Admit Resource And Persisted DSL Rails

This task updates Ash UI authoring validation to accept `right_rail` while rejecting accidental app-specific canonical names.

- [x] 32.4.1.1 Subtask - Update `AshUI.DSL.Storage.valid_widget_type?/1` to admit `right_rail`.
- [x] 32.4.1.2 Subtask - Update resource authoring validation paths for `right_rail`.
- [x] 32.4.1.3 Subtask - Reject `doc_right_rail` unless it is explicitly authored as an application `custom:*` extension.
- [x] 32.4.1.4 Subtask - Add authoring tests for valid rails, invalid rails, and custom extension boundaries.

### [x] 32.4.2 Task - Map Ash Rail Props Into Canonical Attributes

This task updates `AshUI.Rendering.IURAdapter` so resource rails emit valid canonical rail elements.

- [x] 32.4.2.1 Subtask - Map resource rail props into `attributes.rail`.
- [x] 32.4.2.2 Subtask - Preserve Ash resource identity, relationship context, bindings, and policies under Ash-owned metadata.
- [x] 32.4.2.3 Subtask - Prevent unknown props from overwriting canonical `component` or `rail` namespaces.
- [x] 32.4.2.4 Subtask - Add adapter tests that normalize and validate resource-authored rail output through Unified IUR.

## [x] 32.5 Section - Slots, Children, And Semantic Interactions

This section ensures rail panel content and interactions survive the canonical renderer boundary.

### [x] 32.5.1 Task - Preserve Panel Content Slots

This task maps resource-authored panel bodies into canonical children or named slots.

- [x] 32.5.1.1 Subtask - Define the canonical slot key convention for panel body content.
- [x] 32.5.1.2 Subtask - Preserve panel content order within each slot.
- [x] 32.5.1.3 Subtask - Render fallback panel bodies through the standard child rendering path.
- [x] 32.5.1.4 Subtask - Add tests that fail if any runtime renderer drops rail children.

### [x] 32.5.2 Task - Add Semantic Rail Interactions

This task separates panel selection and collapse into host-independent interactions.

- [x] 32.5.2.1 Subtask - Define the panel-selection interaction payload.
- [x] 32.5.2.2 Subtask - Define the collapse-change interaction payload.
- [x] 32.5.2.3 Subtask - Translate semantic interactions to LiveView events inside Live UI only.
- [x] 32.5.2.4 Subtask - Add tests proving canonical output does not contain raw `phx-*` event names or LiveView event strings.

## [x] 32.6 Section - Runtime Renderer Support

This section wires the rail into runtime renderers without making native availability equivalent to canonical support.

### [x] 32.6.1 Task - Add Live UI Native Rail Rendering

This task implements the native Live UI rail component and registry integration.

- [x] 32.6.1.1 Subtask - Add `LiveUi.Widgets.RightRail` with layer shell and callout family metadata.
- [x] 32.6.1.2 Subtask - Register the rail in Live UI widget discovery.
- [x] 32.6.1.3 Subtask - Render panel controls, selected state, collapse state, empty states, and named slots.
- [x] 32.6.1.4 Subtask - Pass through global attrs, accessibility attrs, style hooks, and semantic interaction attrs.

### [x] 32.6.2 Task - Preserve Or Diagnose Non-Live Runtime Rails

This task keeps Elm and desktop behavior explicit until native rail rendering exists.

- [x] 32.6.2.1 Subtask - Add Elm adapter preservation or structured unsupported-component diagnostics for `right_rail`.
- [x] 32.6.2.2 Subtask - Add desktop adapter preservation or structured unsupported-component diagnostics for `right_rail`.
- [x] 32.6.2.3 Subtask - Include renderer name, component kind, and element id in diagnostics.
- [x] 32.6.2.4 Subtask - Add tests proving unsupported rails are not silently coerced to `custom:*` or generic nodes.

## [x] 32.7 Section - Documentation, Examples, And Migration Guidance

This section teaches users and reviewers how to use the reusable rail without reintroducing app-specific canonical vocabulary.

### [x] 32.7.1 Task - Update User And Developer Guides

This task documents authoring, package ownership, renderer behavior, and extension boundaries.

- [x] 32.7.1.1 Subtask - Add user guide coverage for `right_rail` panels, active panel state, collapse behavior, and slots.
- [x] 32.7.1.2 Subtask - Add developer guide coverage for package boundaries, validation, canonical attributes, and renderer support.
- [x] 32.7.1.3 Subtask - Document concrete layout and theme ownership by renderers and host applications.
- [x] 32.7.1.4 Subtask - Document why document rails compose `right_rail` instead of becoming `doc_right_rail`.

### [x] 32.7.2 Task - Add Rail Examples

This task provides reviewable examples that prove the component is reusable.

- [x] 32.7.2.1 Subtask - Add a generic inspector rail example.
- [x] 32.7.2.2 Subtask - Add a document-oriented rail composition that emits canonical `right_rail`.
- [x] 32.7.2.3 Subtask - Add an example with disabled panels, badges, empty states, and slotted content.
- [x] 32.7.2.4 Subtask - Add a canonical signal preview showing panel selection and collapse interactions.

## [x] 32.8 Section - Phase 32 Integration Tests

This final section proves canonical rail adoption works as one package-spanning path instead of a standalone Live UI widget.

### [x] 32.8.1 Task - Run End-To-End Rail Adoption Scenarios

This task validates Phase 32 across catalog, DSL, constructor, validation, Ash conversion, runtime rendering, docs, examples, and governance.

- [x] 32.8.1.1 Subtask - Verify `right_rail` catalog and family metadata match across packages.
- [x] 32.8.1.2 Subtask - Verify Unified UI DSL rails compile into valid `%UnifiedIUR.Element{}` output.
- [x] 32.8.1.3 Subtask - Verify Unified IUR rejects invalid rail, panel, slot, and interaction shapes.
- [x] 32.8.1.4 Subtask - Verify Ash resource-authored rails compile into valid canonical rail output.
- [x] 32.8.1.5 Subtask - Verify Live UI renders native rails with attrs, interactions, and slots preserved.
- [x] 32.8.1.6 Subtask - Verify Elm and desktop adapters preserve or diagnose rails explicitly.
- [x] 32.8.1.7 Subtask - Verify docs and examples cover generic rail composition and the `doc_right_rail` boundary.
- [x] 32.8.1.8 Subtask - Run the targeted Phase 32 suite and governance validation before marking the phase complete.
