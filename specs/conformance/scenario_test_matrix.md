# Scenario Test Matrix

This document maps each conformance scenario (`SCN-*`) to the executable test files that validate it in the conformance harness.

## Matrix

| SCN | Scenario | Verified By |
|---|---|---|
| SCN-001 | Basic Element Resource Creation | test/ash_ui/resources/element_test.exs |
| SCN-002 | Element Type Validation | test/ash_ui/resources/element_test.exs |
| SCN-003 | Element Relationship Definition | test/ash_ui/relationship_integration_test.exs |
| SCN-004 | Screen Resource Creation | test/ash_ui/resources/screen_test.exs |
| SCN-005 | Screen Element Composition | test/ash_ui/relationship_integration_test.exs, test/ash_ui/phase_14_integration_test.exs |
| SCN-006 | Binding Resource Creation | test/ash_ui/resources/binding_test.exs |
| SCN-007 | Binding Value Type | test/ash_ui/runtime/binding_evaluator_test.exs, test/ash_ui/runtime/bidirectional_binding_test.exs |
| SCN-008 | Binding List Type | test/ash_ui/runtime/list_binding_test.exs |
| SCN-009 | Binding Action Type | test/ash_ui/runtime/action_binding_test.exs, test/ash_ui/liveview/phase_4_integration_test.exs |
| SCN-010 | Source Resolution | test/ash_ui/runtime/binding_evaluator_test.exs |
| SCN-011 | Binding Transformation | test/ash_ui/runtime/binding_evaluator_test.exs, test/ash_ui/runtime/bidirectional_binding_test.exs |
| SCN-021 | Screen Mount | test/ash_ui/liveview/phase_4_integration_test.exs |
| SCN-022 | Screen Unmount | test/ash_ui/liveview/phase_4_integration_test.exs |
| SCN-023 | Screen Update | test/ash_ui/liveview/phase_4_integration_test.exs |
| SCN-024 | Session Isolation | test/ash_ui/liveview/phase_4_integration_test.exs |
| SCN-025 | Concurrent Sessions | test/ash_ui/liveview/phase_4_integration_test.exs |
| SCN-026 | Screen Data Binding | test/ash_ui/liveview/phase_4_integration_test.exs, test/ash_ui/runtime/bidirectional_binding_test.exs, test/ash_ui/phase_15_integration_test.exs |
| SCN-027 | Screen Event Handling | test/ash_ui/liveview/phase_4_integration_test.exs, test/ash_ui/runtime/action_binding_test.exs, test/ash_ui/phase_15_integration_test.exs |
| SCN-041 | Resource Compilation | test/ash_ui/compiler/phase_6_integration_test.exs, test/ash_ui/phase_14_integration_test.exs, test/ash_ui/phase_15_integration_test.exs |
| SCN-042 | Schema Validation | test/ash_ui/compiler_test.exs, test/ash_ui/compiler/phase_6_integration_test.exs |
| SCN-043 | IUR Generation | test/ash_ui/compiler_test.exs |
| SCN-044 | Resource Resolution | test/ash_ui/compiler_test.exs |
| SCN-045 | Normalization | test/ash_ui/compiler_test.exs |
| SCN-046 | Compiler Cache | test/ash_ui/compiler_test.exs, test/ash_ui/compiler/phase_6_integration_test.exs |
| SCN-047 | Cache Invalidation | test/ash_ui/compiler_test.exs |
| SCN-048 | Compilation Error Reporting | test/ash_ui/compiler/phase_6_integration_test.exs, test/ash_ui/phase_14_integration_test.exs |
| SCN-049 | Incremental Compilation | test/ash_ui/compiler/phase_6_integration_test.exs |
| SCN-050 | Persisted Screen Authority Graph | test/ash_ui/phase_13_integration_test.exs |
| SCN-051 | Relational Compiler Delegation | test/ash_ui/compiler_test.exs, test/ash_ui/phase_11_integration_test.exs, test/ash_ui/phase_15_integration_test.exs |
| SCN-052 | Example Suite Resource-Authority Flows | test/ash_ui/phase_18_integration_test.exs, test/ash_ui/phase_19_integration_test.exs, test/ash_ui/phase_20_integration_test.exs, test/ash_ui/phase_22_integration_test.exs |
| SCN-053 | Relationship-Driven Composition Semantics | test/ash_ui/phase_14_integration_test.exs |
| SCN-054 | Shared Example Theme Shell and Review Surfaces | test/ash_ui/phase_17_integration_test.exs, test/ash_ui/phase_18_integration_test.exs, test/ash_ui/phase_19_integration_test.exs, test/ash_ui/phase_20_integration_test.exs, test/ash_ui/phase_22_integration_test.exs |
| SCN-055 | Example Suite Governance Drift Detection | test/ash_ui/phase_22_governance_test.exs, test/ash_ui/phase_22_integration_test.exs |
| SCN-061 | LiveView Rendering | test/ash_ui/rendering/phase_7_integration_test.exs |
| SCN-062 | Elm-Backed Web Rendering | test/ash_ui/rendering/phase_7_integration_test.exs |
| SCN-063 | Component Rendering | test/ash_ui/rendering/phase_7_integration_test.exs |
| SCN-064 | Binding Rendering | test/ash_ui/rendering/phase_7_integration_test.exs |
| SCN-065 | Layout Rendering | test/ash_ui/rendering/phase_7_integration_test.exs |
| SCN-066 | Error Rendering | test/ash_ui/rendering/phase_7_integration_test.exs |
| SCN-067 | Desktop Rendering | test/ash_ui/rendering/phase_7_integration_test.exs |
| SCN-068 | Renderer Selection | test/ash_ui/rendering/phase_7_integration_test.exs |
| SCN-069 | Renderer Fallback | test/ash_ui/rendering/phase_7_integration_test.exs |
| SCN-070 | Asset Management | test/ash_ui/rendering/phase_7_integration_test.exs |
| SCN-081 | Screen Mount Authorization | test/ash_ui/authorization/resource_authorizer_test.exs, test/ash_ui/authorization/phase_5_integration_test.exs |
| SCN-082 | Action Authorization | test/ash_ui/authorization/phase_5_integration_test.exs, test/ash_ui/runtime/action_binding_test.exs |
| SCN-083 | Field-Level Authorization | test/ash_ui/authorization/phase_5_integration_test.exs |
| SCN-084 | Binding Authorization | test/ash_ui/authorization/resource_authorizer_test.exs, test/ash_ui/authorization/phase_5_integration_test.exs |
| SCN-085 | Role-Based Access | test/ash_ui/authorization/phase_5_integration_test.exs |
| SCN-086 | Resource Ownership Enforcement | test/ash_ui/authorization/resource_authorizer_test.exs |
| SCN-087 | Authorization Context | test/ash_ui/authorization/resource_authorizer_test.exs, test/ash_ui/authorization/phase_5_integration_test.exs |
| SCN-088 | Authorization Error Handling | test/ash_ui/authorization/phase_5_integration_test.exs |
| SCN-089 | Authorization Caching | test/ash_ui/authorization/phase_5_integration_test.exs |
| SCN-101 | Event Emission | test/ash_ui/telemetry_test.exs |
| SCN-102 | Span Context | test/ash_ui/telemetry_test.exs |
| SCN-103 | Error Tracking | test/ash_ui/liveview/phase_4_integration_test.exs |
| SCN-104 | Performance Monitoring | test/ash_ui/telemetry_test.exs |
| SCN-105 | Session Observability | test/ash_ui/liveview/phase_4_integration_test.exs |
| SCN-106 | Data Privacy Redaction | test/ash_ui/telemetry_test.exs |
| SCN-121 | Extension Registration | test/ash_ui/compiler/phase_6_integration_test.exs |
| SCN-122 | Extension Compilation | test/ash_ui/compiler/phase_6_integration_test.exs |
| SCN-141 | Canonical Package And Element Boundary | test/ash_ui/phase_30_package_boundary_test.exs, test/ash_ui/rendering/iur_adapter_test.exs, test/ash_ui/phase_30_runtime_adapter_test.exs, test/ash_ui/phase_30_integration_test.exs |
| SCN-142 | Resource-Authored Navigation Intent | test/ash_ui/canonical_navigation_test.exs, test/ash_ui/phase_30_integration_test.exs |
| SCN-143 | Forbidden Host Runtime Navigation Fields | test/ash_ui/canonical_navigation_test.exs, test/ash_ui/phase_30_integration_test.exs |
| SCN-144 | Runtime Adapter Navigation Transport | test/ash_ui/phase_30_runtime_adapter_test.exs, test/ash_ui/phase_30_integration_test.exs |
| SCN-145 | Canonical Navigation Guide Coverage | test/ash_ui/phase_30_docs_conformance_test.exs |
| SCN-161 | Canonical Widget Catalog Boundary | test/ash_ui/phase_31_package_boundary_test.exs, test/ash_ui/phase_31_integration_test.exs |
| SCN-162 | Canonical Widget Admission And Aliases | test/ash_ui/phase_31_resource_admission_test.exs, test/ash_ui/phase_31_integration_test.exs |
| SCN-163 | Canonical Widget Conversion And Runtime Adapters | test/ash_ui/phase_31_canonical_conversion_test.exs, test/ash_ui/phase_31_runtime_adapter_test.exs, test/ash_ui/phase_31_integration_test.exs |
| SCN-164 | List Repeat Relationship Hydration | test/ash_ui/liveview/list_repeat_hydration_test.exs, test/ash_ui/phase_31_integration_test.exs |
| SCN-165 | Canonical Widget Guide And Example Coverage | test/ash_ui/phase_31_docs_conformance_test.exs |
| SCN-166 | Phase 31 Conformance And Drift Detection | test/ash_ui/phase_31_package_boundary_test.exs, test/ash_ui/phase_31_resource_admission_test.exs, test/ash_ui/phase_31_canonical_conversion_test.exs, test/ash_ui/phase_31_runtime_adapter_test.exs, test/ash_ui/liveview/list_repeat_hydration_test.exs, test/ash_ui/phase_31_docs_conformance_test.exs, test/ash_ui/phase_31_integration_test.exs |

## Notes

- Only files tagged with `@moduletag :conformance` should appear in this matrix.
- Scenario-to-test mappings are enforced by `test/ash_ui/conformance_traceability_test.exs`.
- The conformance report consumes this matrix to summarize executable scenario coverage.
- Phase 16 realigns the matrix around element-resource authority and relationship-driven composition.
- Phase 22 adds explicit example-suite runtime, theme-shell, and governance traceability.
- Phase 30 adds canonical IUR and navigation adoption traceability.
- Phase 31 adds canonical widget-component catalog adoption traceability.
