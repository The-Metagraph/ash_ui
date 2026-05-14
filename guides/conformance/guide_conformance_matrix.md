# Guide Conformance Matrix

This document tracks conformance of guides against specifications and scenarios.

## Matrix Format

| Guide ID | Title | Requirements | Scenarios | Status | Last Reviewed |
|---|---|---|---|---|---|
| UG-0001 | Getting Started with AshUI | REQ-RES-001, REQ-SCREEN-001, REQ-COMP-001, REQ-RENDER-001 | SCN-004, SCN-021, SCN-041, SCN-061 | Active | 2026-04-23 |
| UG-0002 | Authoring Screens, Elements, and Relationships | REQ-RES-001, REQ-RES-003, REQ-RES-004, REQ-SCREEN-003 | SCN-001, SCN-003, SCN-004, SCN-005 | Active | 2026-04-23 |
| UG-0003 | Widget Types, Styling, Properties, and Signals | REQ-RES-002, REQ-BIND-002, REQ-BIND-008, REQ-RENDER-002 | SCN-002, SCN-009, SCN-061, SCN-101 | Active | 2026-05-14 |
| UG-0004 | Bindings, Actions, and Forms | REQ-BIND-001, REQ-BIND-002, REQ-BIND-003, REQ-BIND-007, REQ-BIND-008, REQ-BIND-010, REQ-NAV-004, REQ-NAV-005, REQ-NAV-006, REQ-NAV-007 | SCN-006, SCN-007, SCN-009, SCN-010, SCN-011, SCN-021, SCN-142, SCN-143, SCN-145 | Active | 2026-05-14 |
| UG-0005 | LiveView Runtime and Rendering | REQ-SCREEN-002, REQ-COMP-001, REQ-RENDER-001, REQ-RENDER-002, REQ-NAV-008, REQ-NAV-009 | SCN-021, SCN-041, SCN-061, SCN-101, SCN-144 | Active | 2026-05-14 |
| UG-0006 | Authorization and Runtime Safety | REQ-AUTH-002, REQ-AUTH-003, REQ-AUTH-005, REQ-AUTH-007, REQ-AUTH-009, REQ-AUTH-012 | SCN-021, SCN-081, SCN-082, SCN-084, SCN-085, SCN-101 | Active | 2026-04-23 |
| UG-0007 | Data Surfaces and Composition Patterns | REQ-SCREEN-003, REQ-BIND-002, REQ-BIND-007, REQ-RENDER-002 | SCN-005, SCN-008, SCN-011, SCN-061 | Active | 2026-04-23 |
| UG-0008 | Migration from Older AshUI Models | REQ-RES-001, REQ-COMP-001, REQ-RENDER-001, REQ-AUTH-002 | SCN-004, SCN-041, SCN-061, SCN-081 | Active | 2026-04-23 |
| DG-0001 | Architecture and Control Planes | REQ-FRAMEWORK-001, REQ-COMP-001, REQ-RENDER-001, REQ-AUTH-002, REQ-OBS-001 | SCN-041, SCN-061, SCN-081, SCN-101 | Active | 2026-04-23 |
| DG-0002 | Storage, Resource Authority, and Configuration | REQ-RES-001, REQ-RES-003, REQ-SCREEN-003, REQ-BIND-003 | SCN-001, SCN-003, SCN-004, SCN-005, SCN-010 | Active | 2026-04-23 |
| DG-0003 | Compiler, Canonical IUR, Styling, and Renderers | REQ-COMP-001, REQ-RENDER-001, REQ-RENDER-002, REQ-BIND-002, REQ-NAV-001, REQ-NAV-002, REQ-NAV-003, REQ-NAV-008, REQ-NAV-009, REQ-NAV-010 | SCN-041, SCN-061, SCN-101, SCN-141, SCN-144, SCN-145 | Active | 2026-05-14 |
| DG-0004 | Runtime, Bindings, and Authorization | REQ-SCREEN-002, REQ-BIND-007, REQ-BIND-010, REQ-AUTH-002, REQ-AUTH-005 | SCN-021, SCN-011, SCN-081, SCN-082, SCN-084 | Active | 2026-04-23 |
| DG-0005 | Testing, Conformance, and Governance | REQ-COMP-001, REQ-BIND-010, REQ-RENDER-012, REQ-AUTH-012, REQ-OBS-001 | SCN-041, SCN-061, SCN-081, SCN-101 | Active | 2026-04-23 |
| DG-0006 | Contribution and Release Workflow | REQ-FRAMEWORK-001, REQ-COMP-001, REQ-OBS-001 | SCN-041, SCN-061, SCN-101 | Active | 2026-04-23 |

## Status Definitions

| Status | Description |
|---|---|
| Draft | Guide being written |
| Review | Guide under review |
| Active | Guide published and current |
| Deprecated | Guide outdated but kept for reference |
| Retired | Guide removed |

## Coverage by Guide Type

### User Guides (UG-*)

| Guide ID | Title | REQ Coverage | SCN Coverage | Status |
|---|---|---|---|---|
| UG-0001 | Getting Started with AshUI | 4 | 4 | Active |
| UG-0002 | Authoring Screens, Elements, and Relationships | 4 | 4 | Active |
| UG-0003 | Widget Types, Styling, Properties, and Signals | 4 | 4 | Active |
| UG-0004 | Bindings, Actions, and Forms | 10 | 9 | Active |
| UG-0005 | LiveView Runtime and Rendering | 6 | 5 | Active |
| UG-0006 | Authorization and Runtime Safety | 6 | 6 | Active |
| UG-0007 | Data Surfaces and Composition Patterns | 4 | 4 | Active |
| UG-0008 | Migration from Older AshUI Models | 4 | 4 | Active |

### Developer Guides (DG-*)

| Guide ID | Title | REQ Coverage | SCN Coverage | Status |
|---|---|---|---|---|
| DG-0001 | Architecture and Control Planes | 5 | 4 | Active |
| DG-0002 | Storage, Resource Authority, and Configuration | 4 | 5 | Active |
| DG-0003 | Compiler, Canonical IUR, Styling, and Renderers | 10 | 6 | Active |
| DG-0004 | Runtime, Bindings, and Authorization | 5 | 5 | Active |
| DG-0005 | Testing, Conformance, and Governance | 5 | 4 | Active |
| DG-0006 | Contribution and Release Workflow | 3 | 3 | Active |

## Key Coverage by Requirement Family

### Resource and screen authoring

| Requirement family | Guides |
|---|---|
| REQ-RES-* | UG-0001, UG-0002, UG-0003, UG-0008 |
| REQ-SCREEN-* | UG-0001, UG-0002, UG-0005, UG-0007 |

### Binding and interaction

| Requirement family | Guides |
|---|---|
| REQ-BIND-* | UG-0003, UG-0004, UG-0007 |
| REQ-NAV-* | UG-0004, UG-0005, DG-0003 |

### Runtime, rendering, authorization

| Requirement family | Guides |
|---|---|
| REQ-COMP-* | UG-0001, UG-0005, UG-0008 |
| REQ-RENDER-* | UG-0001, UG-0003, UG-0005, UG-0007, UG-0008 |
| REQ-AUTH-* | UG-0006, UG-0008 |

## Needed Guides

### High Priority

1. **DG-0007**: Extension Development
2. **DG-0008**: Internal Caching and Performance
3. **UG-0009**: Custom Widgets and Renderer Extension

### Medium Priority

4. **UG-0010**: Performance and Observability
5. **DG-0009**: Telemetry and Operational Diagnostics
6. **UG-0010**: Performance and Observability

## Related Documents

- [../contracts/guide_contract.md](../contracts/guide_contract.md)
- [../contracts/guide_traceability_contract.md](../contracts/guide_traceability_contract.md)
- [../../specs/conformance/spec_conformance_matrix.md](../../specs/conformance/spec_conformance_matrix.md)
