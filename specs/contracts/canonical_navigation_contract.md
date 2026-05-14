# Canonical Navigation And IUR Adoption Contract

Back to index: [README](../README.md)

## Purpose

This contract defines the Ash UI requirements for adopting the upgraded Unified UI canonical navigation model and `%UnifiedIUR.Element{}` rendering boundary.

It applies to Phase 30 and supersedes the legacy string-keyed renderer boundary for any upgraded runtime path.

## Control Plane Ownership

- `AshUI.Resource` owns resource-authored UI declarations and semantic navigation intent.
- `AshUI.Rendering` owns conversion from Ash UI screen/resource state into canonical Unified IUR elements.
- `AshUI.Runtime` owns runtime adapter dispatch and host execution of canonical interactions.
- Unified UI and Unified IUR own canonical construct, interaction, transport, and element semantics.

## Requirements

### REQ-NAV-001 - Coordinated Package Adoption

Ash UI MUST upgrade `unified_iur`, `unified_ui`, `live_ui`, `elm_ui`, and `desktop_ui` as a compatible package set when adopting canonical navigation.

Acceptance criteria:

- The upgraded packages compile together under Ash UI's dependency graph.
- Ash UI uses a Spark dependency declaration compatible with Ash and Reactor.
- The implementation records any package namespace changes in developer documentation.
- Partial upgrades that mix old renderer map contracts with new canonical navigation contracts are rejected by tests or validation.

### REQ-NAV-002 - Canonical Element Rendering Boundary

Ash UI MUST pass `%UnifiedIUR.Element{}` roots to upgraded runtime renderers.

Acceptance criteria:

- Screen roots expose canonical `type`, `kind`, `metadata`, `attributes`, and `children`.
- Children use the canonical Unified IUR child representation expected by the upgraded package set.
- Resource identity, relationship context, and Ash metadata are preserved in namespaced metadata.
- Legacy string-keyed maps are not accepted as the renderer-facing output after Phase 30.

### REQ-NAV-003 - Canonical Validation Surface

Ash UI MUST validate canonical IUR using the validation or normalization API provided by the upgraded Unified IUR package.

Acceptance criteria:

- Calls to removed legacy APIs such as `UnifiedIUR.validate/1` are eliminated.
- Validation failures include enough resource and element context to diagnose the authored declaration.
- Integration tests cover both valid canonical output and at least one invalid canonical output.

### REQ-NAV-004 - Resource-Authored Navigation Intent

Ash UI resources MUST declare navigation as semantic intent that can be compiled into canonical Unified UI interactions.

Acceptance criteria:

- Resources can declare local destination navigation.
- Resources can declare screen transition navigation.
- Resources can declare replace transition navigation.
- Resources can declare history navigation.
- Resources can declare modal open and close navigation.
- Navigation declarations can reference resource actions and payload bindings without embedding host runtime details.

### REQ-NAV-005 - Supported Canonical Navigation Actions

Ash UI MUST support the canonical action set recognized by the upgraded Unified UI package.

Acceptance criteria:

- `:navigate_to` is supported for symbolic screen or local destination movement.
- `:replace_with` is supported for symbolic replacement navigation.
- `:go_back` is supported for host history back intent.
- `:go_forward` is supported for host history forward intent.
- `:open_modal` is supported for symbolic modal targets.
- `:close_modal` is supported for topmost or named symbolic modal targets.

### REQ-NAV-006 - Host Runtime Field Rejection

Ash UI MUST reject navigation declarations that encode host runtime details.

Forbidden fields include:

- `route`
- `path`
- `url`
- `uri`
- `router`
- `helper`
- `live_action`
- `module`
- `runtime_module`
- `stack_id`
- `modal_stack_id`
- `runtime_stack`
- `runtime_stack_id`
- `stack_ref`

Acceptance criteria:

- Invalid declarations fail during resource DSL validation or canonical compilation.
- Error messages identify the forbidden field and the affected resource declaration.
- Integration tests cover at least one forbidden route/path field and one forbidden modal stack field.

### REQ-NAV-007 - Modal Stack Semantics

Ash UI MUST compile modal navigation as symbolic stack intent rather than runtime stack manipulation.

Acceptance criteria:

- `:open_modal` compiles a symbolic modal target and payload.
- `:close_modal` closes the topmost modal when no target is supplied.
- `:close_modal` can close a named symbolic modal when a target is supplied.
- Runtime stack identifiers never appear in canonical output.

### REQ-NAV-008 - Runtime Adapter Contract Alignment

Ash UI runtime adapters MUST align with the upgraded runtime package namespaces and renderer contracts.

Acceptance criteria:

- Live runtime integration targets the upgraded `LiveUi` API.
- Elm runtime integration targets the upgraded `ElmUi` API.
- Desktop runtime integration targets the upgraded `DesktopUi` API.
- Adapter tests prove that each runtime path consumes `%UnifiedIUR.Element{}` inputs.

### REQ-NAV-009 - Interaction Transport Preservation

Ash UI MUST preserve canonical navigation interactions through transport without losing Ash resource context.

Acceptance criteria:

- Canonical interaction payloads retain source element identity.
- Payload mappings preserve resource field/action binding references.
- Runtime transport can resolve symbolic targets through Ash UI's application graph.
- Host execution receives canonical intent plus Ash metadata, not host-authored route strings.

### REQ-NAV-010 - Documentation And Migration Guidance

Ash UI MUST document canonical navigation for both users and developers.

Acceptance criteria:

- User guides explain how resources declare navigation intent.
- Developer guides explain package boundaries, canonical element output, validation, and runtime adapter expectations.
- Migration notes identify legacy map assumptions and old runtime module names.
- Examples avoid route/path/url fields in canonical navigation declarations.

## Traceability

| Requirement | Source | Planned Implementation |
| --- | --- | --- |
| REQ-NAV-001 | ADR-0006 | Phase 30.1 |
| REQ-NAV-002 | ADR-0006 | Phase 30.2 |
| REQ-NAV-003 | ADR-0006 | Phase 30.2 |
| REQ-NAV-004 | ADR-0006 | Phase 30.3 |
| REQ-NAV-005 | ADR-0006 | Phase 30.3 |
| REQ-NAV-006 | ADR-0006 | Phase 30.3, Phase 30.6 |
| REQ-NAV-007 | ADR-0006 | Phase 30.3, Phase 30.6 |
| REQ-NAV-008 | ADR-0006 | Phase 30.4 |
| REQ-NAV-009 | ADR-0006 | Phase 30.4 |
| REQ-NAV-010 | ADR-0006 | Phase 30.5 |

## Conformance

The Phase 30 integration test section is the acceptance gate for this contract.
Conformance scenarios `SCN-141` through `SCN-145` map the `REQ-NAV-*`
requirements into executable tests and guide coverage checks.

## Related

- [ADR-0006: Canonical IUR And Navigation Adoption](../adr/ADR-0006-canonical-iur-and-navigation-adoption.md)
- [Phase 30 - Canonical IUR And Navigation Adoption](../planning/phase-30-canonical-iur-and-navigation-adoption.md)
- [Rendering Contract](./rendering_contract.md)
- [Binding Contract](./binding_contract.md)
