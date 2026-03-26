# Resource Contract (REQ-RES-*)

This contract defines the normative requirements for Ash UI resource
definitions.

## Purpose

Ash UI is a resource-native UI framework. The authoritative UI authoring units
are Ash resources that opt into the `AshUI` extension.

The core model is:

- screen resources define top-level UI boundaries
- element resources define the primary UI building blocks
- binding declarations live with the relevant screen or element resource
- resource relationships define UI composition

Built-in storage resources such as `AshUI.Resources.Screen`,
`AshUI.Resources.Element`, and `AshUI.Resources.Binding` may still exist as
implementation support, but they are not the primary authoring authority.

## Control Plane

**Owner**: `AshUI.Framework`

## Dependencies

- Ash Framework
- Ash-compatible data layer implementation
- upstream `unified_ui` DSL constructs for embedded element/screen fragments

## Requirements

### REQ-RES-001: Resource-Native Authoring

All normative UI authoring units MUST be Ash resources using the `AshUI`
extension.

**Acceptance Criteria**:
- AC-001: Screen and element authoring begins with `use Ash.Resource`
- AC-002: Authoring resources opt into the `AshUI` extension or equivalent
  first-class Ash UI DSL boundary
- AC-003: The UI authoring contract is expressed on resource modules, not only
  inside persisted screen documents
- AC-004: Built-in `AshUI.Resources.*` modules are documented as implementation
  support when used, not as the sole authoring model

### REQ-RES-002: Element DSL Ownership

Element resources MUST be able to declare their own element DSL fragment through
the `AshUI` extension.

**Acceptance Criteria**:
- AC-001: Element resources can declare renderer-facing widget semantics
- AC-002: Element-level theming and styling can be declared through embedded
  `unified_ui` constructs
- AC-003: Element DSL definitions are validated at the resource boundary
- AC-004: Element DSL is attached to the relevant element resource instead of
  only being embedded in a monolithic screen document

### REQ-RES-003: Binding And Action Locality

Bindings and interaction actions SHOULD be declared on the resource that owns
the relevant UI element or screen behavior.

**Acceptance Criteria**:
- AC-001: Element resources can declare bindings relevant to that element
- AC-002: Element resources can declare the relevant interaction actions for the
  signals they expose
- AC-003: Screen resources can declare screen-scoped bindings when no single
  element owns the behavior
- AC-004: The contract does not require all bindings and actions to be authored
  in a detached global screen document

### REQ-RES-004: Relationship-Driven Composition

Resource relationships MUST express UI composition and nesting.

**Acceptance Criteria**:
- AC-001: Screen resources define relationships to their primary child element
  resources
- AC-002: Element resources can define relationships to child or companion
  element resources
- AC-003: Ordering and placement semantics are expressible alongside
  relationships
- AC-004: Compilation consumes a resource graph, not just a serialized document

### REQ-RES-005: Screen-Level Inline Composition

Screens MUST support direct DSL composition for cases where introducing another
element resource is unnecessary.

**Acceptance Criteria**:
- AC-001: Screen resources can include direct DSL fragments or composition glue
- AC-002: Inline composition is subordinate to the related element resource
  graph
- AC-003: Inline composition does not replace relationship-driven composition as
  the primary model
- AC-004: Inline composition uses the same widget/layout/theming semantics as
  element resources

### REQ-RES-006: Type Safety

Authoring resources MUST keep Ash-side attributes, relationships, and UI
extension sections type-safe and validated.

**Acceptance Criteria**:
- AC-001: Persisted attributes declare explicit Ash types
- AC-002: Extension fields and options are validated before compilation
- AC-003: Relationship metadata is validated together with UI composition rules
- AC-004: Invalid authoring data returns descriptive Ash or compiler errors

### REQ-RES-007: Authorization Boundary

Authoring resources and runtime operations MUST participate in the authorization
model.

**Acceptance Criteria**:
- AC-001: Screen and element access is not implicitly unrestricted in production
  flows
- AC-002: Binding and action execution honors authorization context
- AC-003: The active enforcement path is documented
- AC-004: Authorization failures are observable

### REQ-RES-008: Versioning And Change Tracking

Authoring resources MUST expose the metadata needed for dependency tracking,
incremental recompilation, and cache invalidation.

**Acceptance Criteria**:
- AC-001: Authoring resources expose stable identity
- AC-002: Version or update metadata is available for recompilation decisions
- AC-003: Relationship changes are trackable
- AC-004: UI extension changes can invalidate compiled output

## Resource Types

### UI.Element

Normative form: an application-defined Ash resource using the `AshUI`
extension.

**Owns**:
- element DSL fragment
- optional element-local bindings
- optional signal-linked actions
- relationships to child or companion elements

### UI.Screen

Normative form: an application-defined Ash resource using the `AshUI`
extension.

**Owns**:
- route and screen metadata
- primary composition relationships to element resources
- optional inline DSL fragments for glue/layout composition
- top-level lifecycle and mount boundary

### UI.Binding

Normative form: binding declarations authored on the relevant screen or element
resource through the `AshUI` extension.

**Implementation Note**:
Standalone `Binding` resources may still exist for persistence, admin tooling,
or runtime materialization, but they are not the primary authoring authority.

## Traceability

| Requirement | ADR | Component Spec | Scenarios |
|---|---|---|---|
| REQ-RES-001 | ADR-0001, ADR-0005 | resources/ui_element.md, resources/ui_screen.md | SCN-001, SCN-004 |
| REQ-RES-002 | ADR-0005 | resources/ui_element.md | SCN-002, SCN-011 |
| REQ-RES-003 | ADR-0005 | resources/ui_binding.md | SCN-006, SCN-007, SCN-009 |
| REQ-RES-004 | ADR-0005 | resources/ui_element.md, resources/ui_screen.md | SCN-003, SCN-005 |
| REQ-RES-005 | ADR-0005 | resources/ui_screen.md | SCN-004, SCN-012 |
| REQ-RES-006 | ADR-0001 | resources/ui_element.md, resources/ui_screen.md, resources/ui_binding.md | SCN-002, SCN-042 |
| REQ-RES-007 | ADR-0001 | authorization_contract.md | SCN-081, SCN-084 |
| REQ-RES-008 | ADR-0001, ADR-0005 | compilation_contract.md | SCN-010 |

## Conformance

See [spec_conformance_matrix.md](../conformance/spec_conformance_matrix.md)
for the current coverage baseline.

## Related Specifications

- [topology.md](../topology.md)
- [screen_contract.md](screen_contract.md)
- [binding_contract.md](binding_contract.md)
- [../resources/README.md](../resources/README.md)
- [../adr/ADR-0005-element-resource-authority-and-relational-screen-composition.md](../adr/ADR-0005-element-resource-authority-and-relational-screen-composition.md)
