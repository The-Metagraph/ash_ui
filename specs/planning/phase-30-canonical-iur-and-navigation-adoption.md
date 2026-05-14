# Phase 30 - Canonical IUR And Navigation Adoption

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces

- `UnifiedIUR.Element`, `UnifiedIUR.Element.Child`, and the upgraded Unified IUR normalization or validation API.
- `UnifiedUi.Signal`, `UnifiedIUR.Interaction`, and `UnifiedIUR.Interactions.Transport`.
- Ash UI screen/resource declarations that currently compile through `AshUI.Rendering.IURAdapter`.
- Runtime renderer adapters for Live, Elm, and desktop targets.
- `specs/contracts/canonical_navigation_contract.md`.

## Relevant Assumptions / Defaults

- ADR-0005 remains the resource authority baseline: Ash resources own screen composition and domain semantics.
- ADR-0006 defines the adoption target for canonical IUR structs and canonical navigation intent.
- The upgraded Unified package set is adopted as a compatible group, not package by package.
- Ash UI uses dependency declarations compatible with Ash, Spark, and Reactor already present in the application.
- Runtime navigation declarations remain symbolic. Host routes, URLs, router helpers, runtime modules, and stack identifiers are not canonical Ash UI input.

[ ] 30 Phase 30 - Canonical IUR And Navigation Adoption

This phase upgrades Ash UI to the upstream Unified canonical IUR and navigation model while preserving Ash resource authority. It replaces the legacy renderer-facing string map boundary with `%UnifiedIUR.Element{}` roots and introduces resource-authored semantic navigation declarations.

## [x] 30.1 Section - Package Boundary And Dependency Adoption

This section establishes the compatible dependency foundation required before any renderer or DSL behavior is switched to canonical navigation.

### [x] 30.1.1 Task - Upgrade The Unified Package Set

This task brings the local Unified package dependencies to a mutually compatible version that includes canonical navigation and struct-based IUR rendering.

- [x] 30.1.1.1 Subtask - Sync `unified_iur`, `unified_ui`, `live_ui`, `elm_ui`, and `desktop_ui` from the same compatible upstream package set.
- [x] 30.1.1.2 Subtask - Resolve Spark through Ash UI's dependency graph instead of introducing a vendored Spark copy that conflicts with Ash and Reactor.
- [x] 30.1.1.3 Subtask - Update `mix.exs`, `mix.lock`, and package application dependencies for newly required runtime dependencies.
- [x] 30.1.1.4 Subtask - Document runtime namespace changes such as `LiveUi`, `ElmUi`, and `DesktopUi` in developer-facing migration notes.

### [x] 30.1.2 Task - Add Package Compatibility Guardrails

This task prevents partial upgrades from mixing old renderer map contracts with new canonical navigation contracts.

- [x] 30.1.2.1 Subtask - Add compile-time or test-time assertions that the upgraded Unified IUR element struct and canonical interaction modules are available.
- [x] 30.1.2.2 Subtask - Add a dependency compatibility check that fails when runtime packages expect a different canonical element shape than Ash UI emits.
- [x] 30.1.2.3 Subtask - Record the supported package boundary in the canonical navigation contract and developer guide.

## [x] 30.2 Section - Canonical Struct IUR Conversion

This section moves Ash UI's renderer-facing output from legacy string-keyed maps to the upgraded `%UnifiedIUR.Element{}` canonical boundary.

### [x] 30.2.1 Task - Rewrite The IUR Adapter Output Shape

This task updates `AshUI.Rendering.IURAdapter` so Ash UI screens compile into canonical Unified IUR element structs.

- [x] 30.2.1.1 Subtask - Map screen roots into canonical element `type`, `kind`, `metadata`, `attributes`, and `children` fields.
- [x] 30.2.1.2 Subtask - Convert component props, style declarations, bindings, actions, and resource metadata into canonical attribute and metadata buckets.
- [x] 30.2.1.3 Subtask - Convert nested screen and element trees into the canonical child representation expected by the upgraded package set.
- [x] 30.2.1.4 Subtask - Preserve Ash resource identity, relationship context, and generated element identity in namespaced metadata.

### [x] 30.2.2 Task - Replace Legacy IUR Validation Calls

This task updates Ash UI validation to use the upgraded Unified IUR normalization or validation API.

- [x] 30.2.2.1 Subtask - Remove calls to removed legacy APIs such as `UnifiedIUR.validate/1`.
- [x] 30.2.2.2 Subtask - Normalize or validate `%UnifiedIUR.Element{}` output through the upgraded package API.
- [x] 30.2.2.3 Subtask - Return validation errors that include the affected resource, element id, and canonical field path.
- [x] 30.2.2.4 Subtask - Update existing phase integration tests that assert old map shapes to assert canonical struct output.

## [x] 30.3 Section - Resource-Authored Canonical Navigation Intent

This section gives Ash UI resources a host-independent way to declare navigation that compiles into Unified UI canonical interactions.

### [x] 30.3.1 Task - Extend Resource Navigation Declarations

This task adds or updates the resource DSL needed to express canonical navigation intent.

- [x] 30.3.1.1 Subtask - Support semantic declarations for local destination, screen transition, replacement, history, modal open, and modal close navigation.
- [x] 30.3.1.2 Subtask - Support resource action references, payload mappings, and binding references without route, path, URL, helper, or runtime module fields.
- [x] 30.3.1.3 Subtask - Validate canonical navigation actions against `:navigate_to`, `:replace_with`, `:go_back`, `:go_forward`, `:open_modal`, and `:close_modal`.
- [x] 30.3.1.4 Subtask - Reject forbidden host and runtime fields during DSL validation or canonical compilation.

### [x] 30.3.2 Task - Compile Navigation Into Canonical Interactions

This task converts resource-authored navigation declarations into Unified UI interaction and transport structures.

- [x] 30.3.2.1 Subtask - Compile local destination navigation without leaking host route state.
- [x] 30.3.2.2 Subtask - Compile screen transition and replacement navigation as symbolic targets.
- [x] 30.3.2.3 Subtask - Compile history navigation as host-executed canonical intent.
- [x] 30.3.2.4 Subtask - Compile modal open and close navigation as symbolic stack intent without runtime stack identifiers.
- [x] 30.3.2.5 Subtask - Attach canonical interactions to the correct element or screen metadata for runtime transport.

## [x] 30.4 Section - Runtime And Renderer Adapter Realignment

This section updates runtime integration so Live, Elm, and desktop renderers consume canonical elements and execute symbolic navigation intent.

### [x] 30.4.1 Task - Update Renderer Adapter Dispatch

This task aligns Ash UI renderer dispatch with the upgraded runtime package APIs and namespaces.

- [x] 30.4.1.1 Subtask - Update Live renderer integration to the upgraded `LiveUi` API.
- [x] 30.4.1.2 Subtask - Update Elm renderer integration to the upgraded `ElmUi` API.
- [x] 30.4.1.3 Subtask - Update desktop renderer integration to the upgraded `DesktopUi` API.
- [x] 30.4.1.4 Subtask - Remove assumptions that runtime renderers receive string-keyed map roots.

### [x] 30.4.2 Task - Preserve Navigation Transport Through Runtime Execution

This task ensures canonical navigation remains semantic until a host runtime resolves it.

- [x] 30.4.2.1 Subtask - Pass canonical navigation interactions and Ash metadata through runtime transport.
- [x] 30.4.2.2 Subtask - Resolve symbolic screen and modal targets through Ash UI's application graph at runtime boundaries.
- [x] 30.4.2.3 Subtask - Ensure host runtimes execute history and modal close intent without requiring authored host route fields.
- [x] 30.4.2.4 Subtask - Add adapter-level errors for unresolved symbolic targets.

## [x] 30.5 Section - Documentation, Conformance, And Migration

This section updates user-facing and developer-facing material so canonical navigation can be adopted consistently.

### [x] 30.5.1 Task - Update Guides And Examples

This task documents how users and developers should author, inspect, and extend canonical navigation.

- [x] 30.5.1.1 Subtask - Add user guide coverage for resource-authored navigation intent and supported canonical actions.
- [x] 30.5.1.2 Subtask - Add developer guide coverage for package boundaries, struct IUR output, validation, and runtime adapter expectations.
- [x] 30.5.1.3 Subtask - Update examples to use symbolic navigation declarations instead of route, path, URL, helper, or runtime module fields.
- [x] 30.5.1.4 Subtask - Document migration notes for old renderer map assumptions and old runtime module names.

### [x] 30.5.2 Task - Add Spec And Contract Conformance Coverage

This task makes the canonical navigation adoption requirements traceable from specs through tests.

- [x] 30.5.2.1 Subtask - Link `REQ-NAV-*` requirements into the spec conformance matrix.
- [x] 30.5.2.2 Subtask - Add contract tests for canonical element output and navigation action compilation.
- [x] 30.5.2.3 Subtask - Add negative tests for forbidden host and runtime fields.
- [x] 30.5.2.4 Subtask - Add migration tests proving legacy map output is not accepted at the upgraded renderer boundary.

## [ ] 30.6 Section - Phase 30 Integration Tests

This final section proves the package upgrade, canonical IUR conversion, navigation DSL, and runtime adapters work together as one adoption path.

### [ ] 30.6.1 Task - Run End-To-End Canonical IUR And Navigation Scenarios

This task validates Phase 30 as a complete integration rather than isolated package or adapter changes.

- [ ] 30.6.1.1 Subtask - Verify the upgraded Unified package set compiles under Ash UI with the resolved Spark dependency.
- [ ] 30.6.1.2 Subtask - Verify a resource-authored screen compiles into a valid `%UnifiedIUR.Element{}` root.
- [ ] 30.6.1.3 Subtask - Verify local destination navigation compiles and transports as canonical intent.
- [ ] 30.6.1.4 Subtask - Verify screen transition, replacement, back, and forward navigation compile and transport as canonical intent.
- [ ] 30.6.1.5 Subtask - Verify modal open and close navigation compile without runtime stack identifiers.
- [ ] 30.6.1.6 Subtask - Verify Live, Elm, and desktop runtime adapters consume canonical element roots.
- [ ] 30.6.1.7 Subtask - Verify forbidden host route, URL, helper, runtime module, and modal stack fields are rejected.
