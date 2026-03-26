# Phase 13 - Element Resource Authority

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- `lib/ash_ui/resource/dsl.ex`
- `lib/ash_ui/resource/dsl/element.ex`
- `lib/ash_ui/resource/dsl/binding.ex`
- `lib/ash_ui/resource/dsl/screen.ex`
- `lib/ash_ui/authoring/*`
- `lib/ash_ui/resources/validations/*`
- upstream `unified_ui` embedded constructs

## Relevant Assumptions / Defaults
- Ash resources are the authoritative UI authoring units
- element resources are the primary UI building blocks
- no backward compatibility is required for monolithic screen-document
  authority

[ ] 13 Phase 13 - Element Resource Authority
  Restore Ash resources plus the `AshUI` extension as the primary UI authoring
  surface and remove document-first authority from element definition flows.

  [x] 13.1 Section - Replace Document-First Authoring APIs
    Rebuild the authoring boundary around resource DSL extensions instead of
    `AshUI.Authoring.Document` and persisted screen-document wrappers.

    [x] 13.1.1 Task - Rebuild the `AshUI` resource extension surface
    Make `AshUI.Resource.DSL.*` the primary code path for element-first
    authoring.

      [x] 13.1.1.1 Subtask - Expand `lib/ash_ui/resource/dsl/element.ex` to own element DSL, binding, and action sections
      [x] 13.1.1.2 Subtask - Expand `lib/ash_ui/resource/dsl/binding.ex` to validate element-local and screen-local binding declarations
      [x] 13.1.1.3 Subtask - Expand `lib/ash_ui/resource/dsl/screen.ex` only for screen-level composition metadata and screen-scoped bindings
      [x] 13.1.1.4 Subtask - Add compile-time validation in `lib/ash_ui/resources/validations/*` for invalid DSL, signal, and action declarations

    [x] 13.1.2 Task - Remove `AshUI.Authoring` as the primary authoring boundary
    Delete or rewrite the APIs that currently turn authored screens into
    monolithic persisted documents.

      [x] 13.1.2.1 Subtask - Remove `lib/ash_ui/authoring/document.ex` as a required runtime authority path
      [x] 13.1.2.2 Subtask - Remove or rewrite `lib/ash_ui/authoring/screen.ex` so it no longer persists whole-screen authored documents as the preferred path
      [x] 13.1.2.3 Subtask - Remove or rewrite `lib/ash_ui/authoring/legacy_builder.ex` and `lib/ash_ui/authoring/migrator.ex` without compatibility shims
      [x] 13.1.2.4 Subtask - Add tests proving resource-local authoring works without `AshUI.Authoring.*`

  [x] 13.2 Section - Binding And Action Locality
    Move interaction semantics back onto the owning element resource.

    [x] 13.2.1 Task - Bindings belong to the owning element resource
    Align runtime behavior with bindings declared next to the element that
    consumes the signal.

      [x] 13.2.1.1 Subtask - Define element-local value/list/action binding DSL on the element resource
      [x] 13.2.1.2 Subtask - Define the small set of allowed screen-scoped binding exception cases
      [x] 13.2.1.3 Subtask - Validate target and signal compatibility before runtime compilation
      [x] 13.2.1.4 Subtask - Add tests for invalid locality, invalid target ownership, and invalid screen-scoped fallbacks

    [x] 13.2.2 Task - Actions belong to the owning signal source
    Keep interaction actions declared on the resource that exposes the relevant
    signal.

      [x] 13.2.2.1 Subtask - Define optional action declarations for clickable, editable, togglable, and submit-capable elements
      [x] 13.2.2.2 Subtask - Map those declarations to Ash action execution semantics in the runtime layer
      [x] 13.2.2.3 Subtask - Reject action declarations that do not match the element's supported signals
      [x] 13.2.2.4 Subtask - Add end-to-end tests for valid and invalid signal-to-action ownership

  [x] 13.3 Section - Hard Cutover Of The Superseded Model
    Remove the requirement to preserve the monolithic authored-screen path.

    [x] 13.3.1 Task - Remove the superseded document-first APIs outright
    Make the hard break concrete in the implementation plan.

      [x] 13.3.1.1 Subtask - Identify all public and internal APIs that only exist for screen-document-authority authoring
      [x] 13.3.1.2 Subtask - Delete or rewrite those APIs without compatibility aliases
      [x] 13.3.1.3 Subtask - Replace them with resource-local entry points and module docs
      [x] 13.3.1.4 Subtask - Add release notes and governance checks documenting the hard cut

  [ ] 13.4 Section - Phase 13 Integration Tests
    Validate that element resources are once again the authoritative authoring
    units.

    [ ] 13.4.1 Task - Resource-first authoring scenarios
    Verify the code now accepts element-resource-first authoring without the old
    document bridge.

      [ ] 13.4.1.1 Subtask - Verify an element resource with embedded DSL compiles as the authoritative source
      [ ] 13.4.1.2 Subtask - Verify element-local bindings and actions survive compilation and runtime hydration
      [ ] 13.4.1.3 Subtask - Verify invalid signal/action declarations fail clearly at compile time
      [ ] 13.4.1.4 Subtask - Verify `AshUI.Authoring.*`-style screen-document-first flows are rejected or removed
