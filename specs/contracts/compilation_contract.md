# Compilation Contract (REQ-COMP-*)

This contract defines the normative requirements for resource-graph compilation
in Ash UI.

## Purpose

Ash UI compiles screen resources and related element resources into an
intermediate representation, then converts that result into canonical
`unified_iur` for renderer packages.

The authoritative top-level authoring model is the Ash resource graph. Upstream
`unified_ui` provides the embedded widget/layout/theming DSL constructs and
lowering semantics used inside those resources.

## Control Plane

**Owner**: `AshUI.Compilation`

## Dependencies

- REQ-RES-*: source resource definitions
- REQ-BIND-*: binding and action declarations
- `unified_ui` - embedded DSL construct semantics and fragment lowering
- `unified_iur` - canonical intermediate representation format

## Requirements

### REQ-COMP-001: Compilation Pipeline

Resources MUST be compiled through a defined pipeline of stages.

**Compilation Stages**:
1. **Load Screen Root** - resolve the mounted screen resource
2. **Traverse Resource Graph** - resolve related element resources and ordering
3. **Collect Authoring Fragments** - load element DSL, inline screen DSL,
   bindings, and action declarations
4. **Lower Embedded DSL** - invoke upstream `unified_ui` semantics for the
   embedded fragments
5. **Assemble IUR** - build the Ash UI intermediate representation
6. **Normalize / Optimize / Cache** - stabilize output and store compiled result

**Acceptance Criteria**:
- AC-001: All stages execute in order
- AC-002: Each stage produces valid output for the next
- AC-003: Pipeline failures produce clear error messages
- AC-004: Relationship traversal is part of compilation, not an afterthought
- AC-005: Upstream `unified_ui` is used to lower embedded DSL fragments, not to
  replace the resource graph as the top-level authoring model

### REQ-COMP-002: Graph Resolution

Compilation MUST resolve the screen and element relationship graph.

**Acceptance Criteria**:
- AC-001: Related elements are resolved through Ash relationships
- AC-002: Missing or broken relationships produce errors
- AC-003: Ordering and placement metadata are honored
- AC-004: Cycles and illegal composition graphs are detected

### REQ-COMP-003: Embedded DSL Validation

Embedded screen and element DSL fragments MUST be validated before IUR
generation.

**Acceptance Criteria**:
- AC-001: Invalid embedded DSL produces compilation errors
- AC-002: Errors identify the owning resource and fragment
- AC-003: Validation completes before IUR generation
- AC-004: Element signal capabilities are available to binding/action validation

### REQ-COMP-004: Binding And Action Extraction

Compilation MUST extract bindings and interaction actions from the relevant
screen and element resources.

**Acceptance Criteria**:
- AC-001: Element-local bindings compile with the owning element
- AC-002: Screen-scoped bindings compile with the screen root
- AC-003: Interaction actions remain associated with the owning signal source
- AC-004: The compiler does not require a detached monolithic binding document

### REQ-COMP-005: IUR Schema

The intermediate representation MUST remain convertible to canonical
`unified_iur`.

**Acceptance Criteria**:
- AC-001: Ash UI IUR is convertible to canonical `unified_iur`
- AC-002: IUR is serializable
- AC-003: IUR preserves resource identity and composition context
- AC-004: Any Ash UI-owned runtime annotations remain namespaced
- AC-005: Resource-graph-derived composition survives canonical conversion

### REQ-COMP-006: Normalization

Compilation MUST normalize equivalent resource graphs into stable output.

**Acceptance Criteria**:
- AC-001: Equivalent graphs produce identical IUR
- AC-002: Normalization is deterministic
- AC-003: Normalization preserves semantic meaning
- AC-004: Inline screen fragments and related element resources normalize
  together

### REQ-COMP-007: Caching

Compilation MUST cache compiled output for performance.

**Cache Keys**:
- screen resource identity/version
- related element resource identity/version set
- embedded DSL hash
- binding/action declaration hash
- compilation options

**Acceptance Criteria**:
- AC-001: Cache hits skip redundant work
- AC-002: Cache invalidates when graph members change
- AC-003: Cache can be cleared
- AC-004: Relationship changes invalidate dependent outputs

### REQ-COMP-008: Error Reporting

Compilation errors MUST be clear and actionable.

**Acceptance Criteria**:
- AC-001: Errors include the owning screen or element resource
- AC-002: Errors include the stage where the failure occurred
- AC-003: Multiple graph errors can be reported together
- AC-004: Warnings are distinguished from errors

### REQ-COMP-009: Incremental Compilation

Compilation SHOULD support incremental updates across the resource graph.

**Acceptance Criteria**:
- AC-001: Changed resources trigger recompilation
- AC-002: Unchanged resources use cached output
- AC-003: Dependency tracking follows relationships and embedded DSL references
- AC-004: Dependency cycles are detected

### REQ-COMP-010: Observability

Compilation MUST emit telemetry events.

**Acceptance Criteria**:
- AC-001: Events include screen identity
- AC-002: Events include affected element identities where relevant
- AC-003: Events include duration and stage information
- AC-004: Events follow the shared telemetry schema

## Traceability

| Requirement | Component Spec | Scenarios |
|---|---|---|
| REQ-COMP-001 | compilation/compiler.md | SCN-041 |
| REQ-COMP-002 | resources/ui_screen.md, resources/ui_element.md | SCN-013 |
| REQ-COMP-003 | compilation/validator.md | SCN-042 |
| REQ-COMP-004 | resources/ui_binding.md | SCN-006, SCN-015 |
| REQ-COMP-005 | rendering_contract.md | SCN-043 |
| REQ-COMP-006 | compilation/normalizer.md | SCN-044 |
| REQ-COMP-007 | compilation/cache.md | SCN-045 |
| REQ-COMP-008 | compilation/validator.md | SCN-042 |
| REQ-COMP-009 | compilation/cache.md | SCN-046 |
| REQ-COMP-010 | observability_contract.md | SCN-105 |

## Conformance

See [spec_conformance_matrix.md](../conformance/spec_conformance_matrix.md)
for the current scenario coverage baseline.

## Related Specifications

- [resource_contract.md](resource_contract.md)
- [binding_contract.md](binding_contract.md)
- [topology.md](../topology.md)
- [../adr/ADR-0005-element-resource-authority-and-relational-screen-composition.md](../adr/ADR-0005-element-resource-authority-and-relational-screen-composition.md)
