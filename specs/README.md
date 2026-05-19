# Ash UI Specifications

This directory contains the normative specifications for the Ash UI framework. All specifications are organized by control plane and include contracts, architecture decision records (ADRs), component specifications, and conformance requirements.

Current architecture note: the normative target is that Ash resources using the
`AshUI` extension are the authoritative UI authoring surface. Screen resources
compose primarily through related element resources, while upstream
`unified_ui` provides the embedded widget/layout/theming DSL constructs and
lowering semantics used inside those resources. This baseline is defined by
[ADR-0005](./adr/ADR-0005-element-resource-authority-and-relational-screen-composition.md)
and the remediation phases in [planning/README.md](./planning/README.md).
[ADR-0006](./adr/ADR-0006-canonical-iur-and-navigation-adoption.md) defines
the planned adoption target for upgraded Unified IUR structs and canonical
navigation intent. [ADR-0007](./adr/ADR-0007-canonical-widget-components-adoption.md)
defines the planned adoption target for the expanded Unified UI canonical
widget-component catalog. [ADR-0008](./adr/ADR-0008-canonical-rail-component-adoption.md)
defines the planned adoption target for the reusable canonical rail component.
[ADR-0009](./adr/ADR-0009-canonical-workflow-progress-status-component-adoption.md)
defines the planned adoption target for the reusable canonical workflow progress
and status component.

## Directory Structure

```
specs/
├── topology.md                    # Canonical topology (supervision, services, ownership)
├── contracts/                     # Normative requirement families (REQ-*)
├── adr/                           # Architecture Decision Records (ADR-XXXX)
├── core/                          # Core component specs
├── resources/                     # Resource specs (UI.Element, UI.Screen, etc.)
├── compilation/                   # Compiler specs
├── rendering/                     # Renderer specs
└── conformance/                   # Conformance matrices and scenario catalogs
```

## Control Planes

| Control Plane | Scope | Example Components |
|---|---|---|
| **Framework Control Plane** | Ash Framework integration, Resource definitions | UI.Element, UI.Screen, UI.Binding specs |
| **Compilation Control Plane** | Resource → IUR compilation | Compiler, validation, normalization |
| **Rendering Control Plane** | live_ui/elm_ui/desktop_ui output | Renderer adapters, presentation layer |
| **Runtime Control Plane** | Session management, lifecycle | LiveView mount/unmount, event handling |
| **Extension Control Plane** | Custom widgets, plugins | Extension registry, admission |

## Requirement Families

| REQ Family | Purpose | Contract File |
|---|---|---|
| `REQ-RES-*` | Ash Resource definitions | `contracts/resource_contract.md` |
| `REQ-SCREEN-*` | UI.Screen lifecycle | `contracts/screen_contract.md` |
| `REQ-BIND-*` | UI.Binding semantics | `contracts/binding_contract.md` |
| `REQ-COMP-*` | Resource → IUR compilation | `contracts/compilation_contract.md` |
| `REQ-RENDER-*` | live_ui/elm_ui output | `contracts/rendering_contract.md` |
| `REQ-NAV-*` | Canonical navigation and IUR adoption | `contracts/canonical_navigation_contract.md` |
| `REQ-WIDGET-*` | Canonical widget-component catalog adoption | `contracts/canonical_widget_components_contract.md` |
| `REQ-RAIL-*` | Canonical rail component adoption | `contracts/canonical_rail_component_contract.md` |
| `REQ-WFPS-*` | Canonical workflow progress and status component adoption | `contracts/canonical_workflow_progress_status_component_contract.md` |
| `REQ-AUTH-*` | Ash Policy integration | `contracts/authorization_contract.md` |
| `REQ-OBS-*` | Telemetry, events | `contracts/observability_contract.md` |
| `REQ-EXT-*` | Extensions, plugins | `contracts/extension_contract.md` |

## Governance

All specifications must:

1. **Traceability**: Each requirement (REQ-*) must trace to RFCs, ADRs, and acceptance criteria
2. **Conformance**: Each requirement must have corresponding scenario tests (SCN-*)
3. **Validation**: Pass `./scripts/validate_specs_governance.sh` before commit
4. **Ownership**: Each spec must have a designated control plane owner

## Conformance

See [conformance/spec_conformance_matrix.md](conformance/spec_conformance_matrix.md) for the complete mapping of requirements to scenarios and component specs.

## Navigation

- [Topology](topology.md) - System architecture and supervision boundaries
- [Contracts](contracts/) - Normative requirement definitions
- [ADRs](adr/) - Architecture decision records
- [Resources](resources/) - UI.Element, UI.Screen, UI.Binding specifications
- [Compilation](compilation/) - Resource → IUR compiler specifications
- [Rendering](rendering/) - live_ui/elm_ui renderer specifications
- [Conformance](conformance/) - Scenario catalog and conformance matrices
- [Planning](planning/README.md) - implementation and remediation phase plans
