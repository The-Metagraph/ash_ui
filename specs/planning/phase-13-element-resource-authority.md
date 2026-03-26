# Phase 13 - Element Resource Authority

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- `AshUI` resource extension boundary
- element resource modules
- binding and interaction action declarations
- upstream `unified_ui` embedded constructs

## Relevant Assumptions / Defaults
- Ash resources are the authoritative UI authoring units
- element resources are the primary UI building blocks
- no backward compatibility is required for monolithic screen-document
  authority

[ ] 13 Phase 13 - Element Resource Authority
  Restore Ash resources plus the `AshUI` extension as the primary UI authoring
  surface and remove document-first authority from element definition flows.

  [ ] 13.1 Section - AshUI Extension Boundary
    Define the authoritative authoring surface on element resources.

    [ ] 13.1.1 Task - Define element resource extension sections
    Establish the normative `AshUI` extension surface for element resources.

      [ ] 13.1.1.1 Subtask - Define the element DSL section carried by an element resource
      [ ] 13.1.1.2 Subtask - Define how element-local bindings are declared on that resource
      [ ] 13.1.1.3 Subtask - Define how signal-relevant interaction actions are optionally declared
      [ ] 13.1.1.4 Subtask - Document validation rules for those extension sections

    [ ] 13.1.2 Task - Remove element-authority ambiguity
    Ensure the repo no longer treats detached screen documents as the primary
    source of element semantics.

      [ ] 13.1.2.1 Subtask - Remove or deprecate spec language that assigns primary element authority to `Screen.unified_dsl`
      [ ] 13.1.2.2 Subtask - Reclassify detached `AshUI.Resources.Element` storage as an implementation detail if retained
      [ ] 13.1.2.3 Subtask - Ensure public examples stop presenting monolithic screen authorship as the preferred model
      [ ] 13.1.2.4 Subtask - Add explicit tests for element-resource-first authoring

  [ ] 13.2 Section - Binding And Action Locality
    Move interaction semantics back onto the owning element resource.

    [ ] 13.2.1 Task - Bindings belong to the owning element
    Align binding authorship with the element that consumes the signal.

      [ ] 13.2.1.1 Subtask - Define element-local value/list/action binding declarations
      [ ] 13.2.1.2 Subtask - Define the allowed screen-scoped exception cases
      [ ] 13.2.1.3 Subtask - Validate target/signal compatibility at the element boundary
      [ ] 13.2.1.4 Subtask - Add conformance scenarios for invalid locality and signal misuse

    [ ] 13.2.2 Task - Actions belong to the owning signal source
    Keep element interaction actions close to the element that exposes them.

      [ ] 13.2.2.1 Subtask - Define optional action declarations for clickable, editable, or submit-capable elements
      [ ] 13.2.2.2 Subtask - Map action declarations to Ash action execution semantics
      [ ] 13.2.2.3 Subtask - Validate unsupported action declarations against element capabilities
      [ ] 13.2.2.4 Subtask - Add integration coverage for valid and invalid action locality

  [ ] 13.3 Section - Hard Cutover Of The Superseded Model
    Remove the requirement to preserve the monolithic authored-screen path.

    [ ] 13.3.1 Task - Define the hard break
    Make the removal of the superseded authority model explicit.

      [ ] 13.3.1.1 Subtask - Identify the APIs that only exist to support document-first element authority
      [ ] 13.3.1.2 Subtask - Mark those APIs as removable without compatibility shims
      [ ] 13.3.1.3 Subtask - Define replacement APIs in terms of resource-local authoring
      [ ] 13.3.1.4 Subtask - Add release notes and governance checks for the hard cut

  [ ] 13.4 Section - Phase 13 Integration Tests
    Validate that element resources are once again the authoritative authoring
    units.

    [ ] 13.4.1 Task - Resource-first authoring scenarios
    Verify the extension boundary on element resources works end to end.

      [ ] 13.4.1.1 Subtask - Verify an element resource with embedded DSL compiles as the authoritative source
      [ ] 13.4.1.2 Subtask - Verify element-local bindings survive compilation and runtime hydration
      [ ] 13.4.1.3 Subtask - Verify invalid signal/action declarations fail clearly
      [ ] 13.4.1.4 Subtask - Verify document-first element authority paths are rejected or removed
