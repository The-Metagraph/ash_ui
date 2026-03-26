# Screen Contract (REQ-SCREEN-*)

This contract defines the normative requirements for screen resources and
screen runtime behavior in Ash UI.

## Purpose

Screens are top-level Ash resources that define mount boundaries, routes, and
composition roots. A screen composes primarily through relationships to element
resources, while still allowing direct inline DSL composition for glue and
layout scaffolding.

Screens are not normatively defined as monolithic persisted screen documents.

## Control Plane

**Owner**: `AshUI.Runtime`

## Dependencies

- REQ-RES-*: resource-native authoring
- REQ-COMP-*: compilation contracts
- REQ-BIND-*: binding semantics

## Requirements

### REQ-SCREEN-001: Screen Resource Definition

All screens MUST be represented as Ash resources using the `AshUI` extension.

**Acceptance Criteria**:
- AC-001: Screens use `Ash.Resource`
- AC-002: Screens expose route and screen metadata
- AC-003: Screens provide an `AshUI` extension boundary for composition
- AC-004: Screens are not modeled only as opaque serialized screen blobs

### REQ-SCREEN-002: Relationship-First Composition

Screens MUST compose primarily through related element resources.

**Acceptance Criteria**:
- AC-001: A screen can reference primary child elements through Ash
  relationships
- AC-002: Relationship traversal order and placement semantics are defined
- AC-003: Removing or changing a related element changes the compiled screen
  graph
- AC-004: Compiler inputs include the related element graph

### REQ-SCREEN-003: Direct DSL Composition

Screens MUST support direct inline DSL composition where another element
resource would be unnecessary.

**Acceptance Criteria**:
- AC-001: Screens can embed direct widget/layout fragments
- AC-002: Inline fragments use the same upstream `unified_ui` construct
  semantics as element resources
- AC-003: Inline fragments do not replace relationship-driven composition as
  the primary model
- AC-004: Inline fragments compose cleanly with related element resources

### REQ-SCREEN-004: Lifecycle Management

Screens MUST implement a runtime lifecycle through LiveView integration and
screen state management.

**Lifecycle States**:
1. loaded
2. mounting
3. mounted
4. updating
5. unmounting
6. unmounted

**Acceptance Criteria**:
- AC-001: Screens mount through `AshUI.LiveView.Integration`
- AC-002: Runtime cleanup occurs on disconnect or explicit unmount paths
- AC-003: Invalid lifecycle transitions are handled safely
- AC-004: Lifecycle events emit telemetry

### REQ-SCREEN-005: Screen-Scoped Bindings

Screens MUST support bindings that belong to the screen as a whole rather than
to a single element.

**Acceptance Criteria**:
- AC-001: Screen-scoped bindings can be declared in the screen authoring surface
- AC-002: Element-local and screen-local bindings can coexist
- AC-003: Runtime binding evaluation preserves screen scope
- AC-004: Screen-scoped failures surface clearly

### REQ-SCREEN-006: Routing

Routable screens MUST define a stable route path.

**Acceptance Criteria**:
- AC-001: Routed screens define `route`
- AC-002: Route identifiers are unique where routing is enabled
- AC-003: Route params are available to mount logic
- AC-004: Missing routes are handled explicitly by the application

### REQ-SCREEN-007: Session Isolation

Mounted screens MUST maintain isolated state per LiveView session.

**Acceptance Criteria**:
- AC-001: Each LiveView session has independent screen state
- AC-002: Session changes do not leak across connections
- AC-003: Disconnect cleanup releases screen-specific state
- AC-004: Concurrent sessions are supported

### REQ-SCREEN-008: Event Handling

Screens MUST route user events through the runtime event handler boundary.

**Acceptance Criteria**:
- AC-001: Event targets can be matched to element-local or screen-local bindings
- AC-002: Unknown events fail safely
- AC-003: Event errors do not crash the LiveView session
- AC-004: Successful events can trigger re-render paths

### REQ-SCREEN-009: Authorization

Screens MUST enforce authorization before protected mount and update flows
continue.

**Acceptance Criteria**:
- AC-001: Mount checks actor access before compilation
- AC-002: Unauthorized mounts return a safe runtime response
- AC-003: Binding and action authorization integrate with the mounted screen
  context
- AC-004: Authorization failures are observable

### REQ-SCREEN-010: Validation

Screens MUST validate authoring configuration before use.

**Acceptance Criteria**:
- AC-001: Invalid screen definitions fail fast
- AC-002: Invalid relationship composition surfaces clear errors
- AC-003: Invalid inline DSL fragments are rejected before compilation
- AC-004: Broken screen/element/binding relationships surface clear errors

## Traceability

| Requirement | Component Spec | Scenarios |
|---|---|---|
| REQ-SCREEN-001 | resources/ui_screen.md | SCN-004 |
| REQ-SCREEN-002 | resources/ui_screen.md, resources/ui_element.md | SCN-005, SCN-013 |
| REQ-SCREEN-003 | resources/ui_screen.md | SCN-012 |
| REQ-SCREEN-004 | phase-04-runtime-and-liveview-integration.md | SCN-021, SCN-022, SCN-023 |
| REQ-SCREEN-005 | resources/ui_binding.md | SCN-006, SCN-014 |
| REQ-SCREEN-006 | resources/ui_screen.md | SCN-004 |
| REQ-SCREEN-007 | phase-04-runtime-and-liveview-integration.md | SCN-024, SCN-025 |
| REQ-SCREEN-008 | phase-04-runtime-and-liveview-integration.md | SCN-021 |
| REQ-SCREEN-009 | authorization_contract.md | SCN-081 |
| REQ-SCREEN-010 | compilation_contract.md | SCN-042 |

## Conformance

See [spec_conformance_matrix.md](../conformance/spec_conformance_matrix.md)
for the current scenario coverage baseline.

## Related Specifications

- [resource_contract.md](resource_contract.md)
- [binding_contract.md](binding_contract.md)
- [../resources/ui_screen.md](../resources/ui_screen.md)
- [../adr/ADR-0005-element-resource-authority-and-relational-screen-composition.md](../adr/ADR-0005-element-resource-authority-and-relational-screen-composition.md)
