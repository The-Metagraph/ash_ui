# Spec Conformance Matrix

This document maps all requirements (REQ-*) to contracts, component specifications, and conformance scenarios (SCN-*).

## Matrix Format

The matrix provides complete traceability from:
- **Requirements** (REQ-*) - Normative statements in contracts
- **Contracts** - Documents containing requirements
- **Component Specs** - Detailed component specifications
- **Scenarios** (SCN-*) - Acceptance criteria tests

## Framework Control Plane

### REQ-RES-*: Resource Contract

| REQ | Description | Component Specs | Scenarios |
|---|---|---|---|
| REQ-RES-001 | Resource Definition | resources/ui_element.md, resources/ui_screen.md, resources/ui_binding.md | SCN-001, SCN-004, SCN-006 |
| REQ-RES-002 | Type Safety | resources/ui_element.md, resources/ui_binding.md | SCN-002 |
| REQ-RES-003 | Relationship Definition | resources/ui_element.md, resources/ui_screen.md, resources/ui_binding.md | SCN-003, SCN-005, SCN-053 |
| REQ-RES-004 | Action Definition | resources/ui_screen.md, resources/ui_binding.md | SCN-004, SCN-006 |
| REQ-RES-005 | Validation | compilation/README.md | SCN-042 |
| REQ-RES-006 | Authorization | contracts/authorization_contract.md | SCN-081, SCN-084 |
| REQ-RES-007 | Metadata | resources/ui_screen.md, resources/ui_element.md, resources/ui_binding.md | SCN-004, SCN-006, SCN-010 |
| REQ-RES-008 | Extensions | extension_contract.md | - |

### REQ-BIND-*: Binding Contract

| REQ | Description | Component Specs | Scenarios |
|---|---|---|---|
| REQ-BIND-001 | Binding Definition | resources/ui_binding.md | SCN-006 |
| REQ-BIND-002 | Binding Types | resources/ui_binding.md | SCN-007, SCN-008, SCN-009 |
| REQ-BIND-003 | Source Resolution | resources/ui_binding.md, compilation/README.md | SCN-010 |
| REQ-BIND-004 | Target Binding | resources/ui_binding.md | SCN-006 |
| REQ-BIND-005 | Transformation | planning/phase-03-data-binding-and-signal-mapping.md | SCN-011 |
| REQ-BIND-006 | Reactivity | planning/phase-04-runtime-and-liveview-integration.md | SCN-026 |
| REQ-BIND-007 | Bidirectional Updates | planning/phase-03-data-binding-and-signal-mapping.md | SCN-026 |
| REQ-BIND-008 | Action Execution | planning/phase-03-data-binding-and-signal-mapping.md, planning/phase-04-runtime-and-liveview-integration.md | SCN-009, SCN-027 |
| REQ-BIND-009 | Validation | compilation/README.md | SCN-042 |
| REQ-BIND-010 | Observability | contracts/observability_contract.md | SCN-101 |

### REQ-AUTH-*: Authorization Contract

| REQ | Description | Component Specs | Scenarios |
|---|---|---|---|
| REQ-AUTH-001 | Policy Definition | planning/phase-05-authorization-and-policy-enforcement.md | SCN-081, SCN-085, SCN-086 |
| REQ-AUTH-002 | Screen Authorization | planning/phase-05-authorization-and-policy-enforcement.md | SCN-081 |
| REQ-AUTH-003 | Action Authorization | planning/phase-05-authorization-and-policy-enforcement.md | SCN-082 |
| REQ-AUTH-004 | Field-Level Authorization | planning/phase-05-authorization-and-policy-enforcement.md | SCN-083 |
| REQ-AUTH-005 | Binding Authorization | planning/phase-05-authorization-and-policy-enforcement.md | SCN-084 |
| REQ-AUTH-006 | Resource Ownership | planning/phase-05-authorization-and-policy-enforcement.md | SCN-086 |
| REQ-AUTH-007 | Role-Based Access | planning/phase-05-authorization-and-policy-enforcement.md | SCN-085 |
| REQ-AUTH-008 | Authorization Context | planning/phase-05-authorization-and-policy-enforcement.md | SCN-087 |
| REQ-AUTH-009 | Error Handling | planning/phase-05-authorization-and-policy-enforcement.md | SCN-088 |
| REQ-AUTH-010 | Authorization Caching | planning/phase-05-authorization-and-policy-enforcement.md | SCN-089 |
| REQ-AUTH-011 | Audit Logging | framework/audit.md | - |
| REQ-AUTH-012 | Observability | contracts/observability_contract.md | - |

## Compilation Control Plane

### REQ-COMP-*: Compilation Contract

| REQ | Description | Component Specs | Scenarios |
|---|---|---|---|
| REQ-COMP-001 | Compilation Pipeline | compilation/README.md, planning/phase-06-compiler-and-dsl-integration.md | SCN-041, SCN-050, SCN-051, SCN-052 |
| REQ-COMP-002 | Schema Validation | compilation/README.md, planning/phase-06-compiler-and-dsl-integration.md | SCN-042 |
| REQ-COMP-003 | IUR Schema | compilation/README.md | SCN-043 |
| REQ-COMP-004 | Resource Resolution | compilation/README.md | SCN-044, SCN-053 |
| REQ-COMP-005 | Normalization | compilation/README.md | SCN-045 |
| REQ-COMP-006 | Optimization | compilation/optimizer.md | - |
| REQ-COMP-007 | Caching | compilation/README.md, planning/phase-06-compiler-and-dsl-integration.md | SCN-046, SCN-047, SCN-051 |
| REQ-COMP-008 | Error Reporting | compilation/README.md, planning/phase-06-compiler-and-dsl-integration.md | SCN-048, SCN-055 |
| REQ-COMP-009 | Incremental Compilation | planning/phase-06-compiler-and-dsl-integration.md | SCN-049 |
| REQ-COMP-010 | Observability | contracts/observability_contract.md | SCN-101 |

## Rendering Control Plane

### REQ-RENDER-*: Rendering Contract

| REQ | Description | Component Specs | Scenarios |
|---|---|---|---|
| REQ-RENDER-001 | Renderer Contract | rendering/README.md, planning/phase-07-renderer-package-integration.md | SCN-068 |
| REQ-RENDER-002 | LiveView Rendering | rendering/README.md, planning/phase-07-renderer-package-integration.md | SCN-061, SCN-054 |
| REQ-RENDER-003 | Elm-Backed Web Rendering | rendering/README.md, planning/phase-07-renderer-package-integration.md | SCN-062 |
| REQ-RENDER-003B | Desktop Rendering | rendering/README.md, planning/phase-07-renderer-package-integration.md | SCN-067 |
| REQ-RENDER-004 | Component Rendering | rendering/README.md | SCN-063 |
| REQ-RENDER-005 | Data Binding Rendering | rendering/README.md | SCN-064 |
| REQ-RENDER-006 | Error Handling | rendering/README.md, planning/phase-07-renderer-package-integration.md | SCN-066, SCN-069 |
| REQ-RENDER-007 | Layout Support | rendering/README.md | SCN-065, SCN-054 |
| REQ-RENDER-008 | Asset Management | rendering/README.md, planning/phase-07-renderer-package-integration.md | SCN-070, SCN-054, SCN-055 |
| REQ-RENDER-009 | Accessibility | rendering/a11y.md | - |
| REQ-RENDER-010 | Performance | rendering/performance.md | - |
| REQ-RENDER-011 | Extensibility | rendering/extensibility.md | - |
| REQ-RENDER-012 | Observability | contracts/observability_contract.md | SCN-101 |

## Navigation Control Plane

### REQ-NAV-*: Canonical Navigation And IUR Adoption Contract

| REQ | Description | Component Specs | Scenarios |
|---|---|---|---|
| REQ-NAV-001 | Coordinated Package Adoption | contracts/canonical_navigation_contract.md, planning/phase-30-canonical-iur-and-navigation-adoption.md | SCN-141 |
| REQ-NAV-002 | Canonical Element Rendering Boundary | contracts/canonical_navigation_contract.md, planning/phase-30-canonical-iur-and-navigation-adoption.md | SCN-141 |
| REQ-NAV-003 | Canonical Validation Surface | contracts/canonical_navigation_contract.md, planning/phase-30-canonical-iur-and-navigation-adoption.md | SCN-141 |
| REQ-NAV-004 | Resource-Authored Navigation Intent | contracts/canonical_navigation_contract.md, planning/phase-30-canonical-iur-and-navigation-adoption.md | SCN-142 |
| REQ-NAV-005 | Supported Canonical Navigation Actions | contracts/canonical_navigation_contract.md, planning/phase-30-canonical-iur-and-navigation-adoption.md | SCN-142 |
| REQ-NAV-006 | Host Runtime Field Rejection | contracts/canonical_navigation_contract.md, planning/phase-30-canonical-iur-and-navigation-adoption.md | SCN-143 |
| REQ-NAV-007 | Modal Stack Semantics | contracts/canonical_navigation_contract.md, planning/phase-30-canonical-iur-and-navigation-adoption.md | SCN-143 |
| REQ-NAV-008 | Runtime Adapter Contract Alignment | contracts/canonical_navigation_contract.md, planning/phase-30-canonical-iur-and-navigation-adoption.md | SCN-144 |
| REQ-NAV-009 | Interaction Transport Preservation | contracts/canonical_navigation_contract.md, planning/phase-30-canonical-iur-and-navigation-adoption.md | SCN-144 |
| REQ-NAV-010 | Documentation And Migration Guidance | contracts/canonical_navigation_contract.md, guides/user/UG-0004-bindings-actions-and-forms.md, guides/user/UG-0005-liveview-runtime-and-rendering.md, guides/developer/DG-0003-compiler-canonical-iur-and-renderers.md | SCN-145 |

## Widget Component Control Plane

### REQ-WIDGET-*: Canonical Widget Components Adoption Contract

| REQ | Description | Component Specs | Scenarios |
|---|---|---|---|
| REQ-WIDGET-001 | Authoritative Catalog Source | contracts/canonical_widget_components_contract.md, planning/phase-31-canonical-widget-components-adoption.md | SCN-161 |
| REQ-WIDGET-002 | Resource And Persisted DSL Admission | contracts/canonical_widget_components_contract.md, planning/phase-31-canonical-widget-components-adoption.md | SCN-162 |
| REQ-WIDGET-003 | Alias Normalization | contracts/canonical_widget_components_contract.md, guides/user/UG-0008-migration-from-older-ash-ui-models.md | SCN-162 |
| REQ-WIDGET-004 | Canonical Attribute Mapping | contracts/canonical_widget_components_contract.md, guides/developer/DG-0003-compiler-canonical-iur-and-renderers.md | SCN-163 |
| REQ-WIDGET-005 | Component Validation | contracts/canonical_widget_components_contract.md, planning/phase-31-canonical-widget-components-adoption.md | SCN-163 |
| REQ-WIDGET-006 | Renderer Adapter Preservation | contracts/canonical_widget_components_contract.md, guides/developer/DG-0003-compiler-canonical-iur-and-renderers.md | SCN-163 |
| REQ-WIDGET-007 | Semantic Fallback Rendering | contracts/canonical_widget_components_contract.md, guides/developer/DG-0003-compiler-canonical-iur-and-renderers.md | SCN-163 |
| REQ-WIDGET-008 | List Repeat Composition | contracts/canonical_widget_components_contract.md, examples/canonical_widget_components.md | SCN-164 |
| REQ-WIDGET-009 | Documentation And Examples | contracts/canonical_widget_components_contract.md, guides/user/UG-0003-widget-types-properties-and-signals.md, guides/user/UG-0008-migration-from-older-ash-ui-models.md, guides/developer/DG-0003-compiler-canonical-iur-and-renderers.md, examples/canonical_widget_components.md | SCN-165 |
| REQ-WIDGET-010 | Conformance And Drift Detection | contracts/canonical_widget_components_contract.md, planning/phase-31-canonical-widget-components-adoption.md | SCN-166 |

### REQ-RAIL-*: Canonical Rail Component Contract

| REQ | Description | Component Specs | Scenarios |
|---|---|---|---|
| REQ-RAIL-001 | Generic Canonical Name | contracts/canonical_rail_component_contract.md, planning/phase-32-canonical-rail-component-adoption.md | SCN-171 |
| REQ-RAIL-002 | Catalog And Family Alignment | contracts/canonical_rail_component_contract.md, planning/phase-32-canonical-rail-component-adoption.md | SCN-171 |
| REQ-RAIL-003 | Unified UI Authoring Path | contracts/canonical_rail_component_contract.md, planning/phase-32-canonical-rail-component-adoption.md | SCN-172 |
| REQ-RAIL-004 | Unified IUR Constructor And Validation | contracts/canonical_rail_component_contract.md, planning/phase-32-canonical-rail-component-adoption.md | SCN-172, SCN-173 |
| REQ-RAIL-005 | Ash Resource Admission | contracts/canonical_rail_component_contract.md, planning/phase-32-canonical-rail-component-adoption.md | SCN-173 |
| REQ-RAIL-006 | Ash Canonical Conversion | contracts/canonical_rail_component_contract.md, planning/phase-32-canonical-rail-component-adoption.md | SCN-173 |
| REQ-RAIL-007 | Slot And Child Preservation | contracts/canonical_rail_component_contract.md, planning/phase-32-canonical-rail-component-adoption.md | SCN-172, SCN-174 |
| REQ-RAIL-008 | Semantic Interactions | contracts/canonical_rail_component_contract.md, planning/phase-32-canonical-rail-component-adoption.md | SCN-172, SCN-174 |
| REQ-RAIL-009 | Runtime Renderer Support | contracts/canonical_rail_component_contract.md, planning/phase-32-canonical-rail-component-adoption.md | SCN-174 |
| REQ-RAIL-010 | Theme And Layout Boundary | contracts/canonical_rail_component_contract.md, planning/phase-32-canonical-rail-component-adoption.md, guides/developer/DG-0003-compiler-canonical-iur-and-renderers.md | SCN-174 |
| REQ-RAIL-011 | Documentation And Examples | contracts/canonical_rail_component_contract.md, guides/user/UG-0003-widget-types-properties-and-signals.md, guides/user/UG-0006-advanced-composition.md, guides/developer/DG-0003-compiler-canonical-iur-and-renderers.md, examples/canonical_widget_components.md | SCN-175 |
| REQ-RAIL-012 | Conformance And Drift Detection | contracts/canonical_rail_component_contract.md, planning/phase-32-canonical-rail-component-adoption.md | SCN-176 |

### REQ-WFPS-*: Canonical Workflow Progress And Status Component Contract

| REQ | Description | Component Specs | Scenarios |
|---|---|---|---|
| REQ-WFPS-001 | Canonical Name And Scope | contracts/canonical_workflow_progress_status_component_contract.md, planning/phase-33-canonical-workflow-progress-status-component-adoption.md | SCN-181 |
| REQ-WFPS-002 | Catalog And Family Alignment | contracts/canonical_workflow_progress_status_component_contract.md, planning/phase-33-canonical-workflow-progress-status-component-adoption.md | SCN-181 |
| REQ-WFPS-003 | Unified UI Authoring Path | contracts/canonical_workflow_progress_status_component_contract.md, planning/phase-33-canonical-workflow-progress-status-component-adoption.md | SCN-182 |
| REQ-WFPS-004 | Unified IUR Constructor And Validation | contracts/canonical_workflow_progress_status_component_contract.md, planning/phase-33-canonical-workflow-progress-status-component-adoption.md | SCN-182, SCN-183 |
| REQ-WFPS-005 | Ash Resource Admission | contracts/canonical_workflow_progress_status_component_contract.md, planning/phase-33-canonical-workflow-progress-status-component-adoption.md | SCN-183 |
| REQ-WFPS-006 | Ash Canonical Conversion | contracts/canonical_workflow_progress_status_component_contract.md, planning/phase-33-canonical-workflow-progress-status-component-adoption.md | SCN-183 |
| REQ-WFPS-007 | Dependency Edge Semantics | contracts/canonical_workflow_progress_status_component_contract.md, planning/phase-33-canonical-workflow-progress-status-component-adoption.md | SCN-182, SCN-184 |
| REQ-WFPS-008 | Semantic Actions And Interactions | contracts/canonical_workflow_progress_status_component_contract.md, planning/phase-33-canonical-workflow-progress-status-component-adoption.md | SCN-182, SCN-184 |
| REQ-WFPS-009 | Runtime Renderer Support | contracts/canonical_workflow_progress_status_component_contract.md, planning/phase-33-canonical-workflow-progress-status-component-adoption.md | SCN-184 |
| REQ-WFPS-010 | Theme And Layout Boundary | contracts/canonical_workflow_progress_status_component_contract.md, planning/phase-33-canonical-workflow-progress-status-component-adoption.md, guides/developer/DG-0003-compiler-canonical-iur-and-renderers.md | SCN-184, SCN-185 |
| REQ-WFPS-011 | PR Rebase And Scope Hygiene | contracts/canonical_workflow_progress_status_component_contract.md, planning/phase-33-canonical-workflow-progress-status-component-adoption.md | SCN-186 |
| REQ-WFPS-012 | Documentation And Conformance | contracts/canonical_workflow_progress_status_component_contract.md, guides/user/UG-0003-widget-types-properties-and-signals.md, guides/developer/DG-0003-compiler-canonical-iur-and-renderers.md, examples/canonical_widget_components.md | SCN-185, SCN-186 |

## Runtime Control Plane

### REQ-SCREEN-*: Screen Contract

| REQ | Description | Component Specs | Scenarios |
|---|---|---|---|
| REQ-SCREEN-001 | Screen Definition | resources/ui_screen.md | SCN-004, SCN-050, SCN-052 |
| REQ-SCREEN-002 | Lifecycle Management | planning/phase-04-runtime-and-liveview-integration.md | SCN-021, SCN-022, SCN-023 |
| REQ-SCREEN-003 | Element Composition | resources/ui_screen.md | SCN-005, SCN-053 |
| REQ-SCREEN-004 | Data Binding | resources/ui_binding.md, planning/phase-04-runtime-and-liveview-integration.md | SCN-026 |
| REQ-SCREEN-005 | Routing | resources/ui_screen.md | SCN-004 |
| REQ-SCREEN-006 | Session Isolation | planning/phase-04-runtime-and-liveview-integration.md | SCN-024, SCN-025 |
| REQ-SCREEN-007 | Event Handling | planning/phase-04-runtime-and-liveview-integration.md | SCN-027 |
| REQ-SCREEN-008 | Authorization | contracts/authorization_contract.md | SCN-081 |
| REQ-SCREEN-009 | Validation | compilation/README.md | SCN-042 |
| REQ-SCREEN-010 | Observability | contracts/observability_contract.md | SCN-105 |

## Extension Control Plane

### REQ-EXT-*: Extension Contract

| REQ | Description | Component Specs | Scenarios |
|---|---|---|---|
| REQ-EXT-001 | Extension Definition | planning/phase-06-compiler-and-dsl-integration.md | SCN-121 |
| REQ-EXT-002 | Extension Admission | planning/phase-06-compiler-and-dsl-integration.md | SCN-122 |
| REQ-EXT-003 | Extension Lifecycle | planning/phase-06-compiler-and-dsl-integration.md | SCN-122 |
| REQ-EXT-004 | Extension Isolation | extension/sandbox.md | - |
| REQ-EXT-005 | Extension Registry | planning/phase-06-compiler-and-dsl-integration.md | SCN-121 |
| REQ-EXT-006 | Extension Observability | observability_contract.md | - |

## Observability (Cross-Cutting)

### REQ-OBS-*: Observability Contract

| REQ | Description | Component Specs | Scenarios |
|---|---|---|---|
| REQ-OBS-001 | Event Schema | contracts/observability_contract.md | SCN-101 |
| REQ-OBS-002 | Event Categories | contracts/observability_contract.md | SCN-101 |
| REQ-OBS-003 | Span Context | contracts/observability_contract.md | SCN-102 |
| REQ-OBS-004 | Metrics | contracts/observability_contract.md | SCN-104 |
| REQ-OBS-005 | Logging | observability/logging.md | - |
| REQ-OBS-006 | Error Tracking | contracts/observability_contract.md | SCN-103 |
| REQ-OBS-007 | Performance Monitoring | contracts/observability_contract.md | SCN-104 |
| REQ-OBS-008 | Session Observability | contracts/observability_contract.md | SCN-105 |
| REQ-OBS-009 | Custom Events | observability/custom.md | - |
| REQ-OBS-010 | Event Handlers | contracts/observability_contract.md | SCN-101 |
| REQ-OBS-011 | Sampling | observability/sampling.md | - |
| REQ-OBS-012 | Data Privacy | contracts/observability_contract.md | SCN-106 |

## Coverage Summary

| Control Plane | Total REQ | With Spec | With SCN | Coverage |
|---|---|---|---|---|
| Framework | 30 | 28 | 25 | 83% |
| Compilation | 10 | 9 | 9 | 90% |
| Rendering | 12 | 9 | 9 | 75% |
| Navigation | 10 | 10 | 10 | 100% |
| Widget Components | 10 | 10 | 10 | 100% |
| Rail Component | 12 | 12 | 12 | 100% |
| Workflow Progress And Status | 12 | 12 | 12 | 100% |
| Runtime | 10 | 10 | 10 | 100% |
| Extension | 6 | 4 | 4 | 67% |
| Observability | 12 | 9 | 8 | 67% |
| **TOTAL** | **124** | **113** | **109** | **88%** |

## Coverage Milestones

### Foundation Baseline
- Target: 40% coverage
- Status: surpassed
- Focus delivered: core resources, compilation, LiveView rendering

### Complete Framework Target
- Target: 70% coverage
- Status: surpassed
- Focus delivered: real runtime bindings, authorization, renderer selection and fallback

### Production Target
- Target: 90% coverage
- Remaining work: accessibility, audit logging, extension isolation, custom events, sampling

## Related Specifications

- [scenario_catalog.md](scenario_catalog.md) - Full scenario definitions
- [scenario_test_matrix.md](scenario_test_matrix.md) - Executable scenario-to-test traceability
- [../contracts/*.md](../contracts/) - All contract documents

## Notes

- Coverage reflects explicit traceability from requirement -> scenario -> conformance-tagged test file
- Rows marked with `-` indicate intentionally uncovered or still-undocumented areas
- The scenario test matrix is enforced by `test/ash_ui/conformance_traceability_test.exs`
- Phase 16 adds explicit traceability for element-resource authority and relationship-driven composition
- Phase 22 adds explicit traceability for the maintained example suite, shared theme shell, and governance gates
- Phase 30 adds explicit traceability for canonical IUR structs and resource-authored navigation intent
- Phase 32 adds explicit traceability for canonical rail component adoption
- Phase 33 adds explicit traceability for canonical workflow progress and status component adoption
- Coverage percentages should be updated whenever scenarios or conformance-tagged tests change
