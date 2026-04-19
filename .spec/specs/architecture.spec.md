# Ash UI Architecture

Ash UI is organized around explicit control planes and a resource-graph-driven
screen lifecycle.

## Intent

Capture the current architectural boundary between resource authoring,
compilation, runtime, rendering, and governance.

```spec-meta
id: ashui.architecture
kind: architecture
status: active
summary: Control-plane architecture where the resource graph is authoritative, compilation traverses relationships, and renderers consume canonical output.
surface:
  - README.md
  - guides/developer/DG-0001-architecture-overview.md
  - lib/ash_ui/resource/authority.ex
  - lib/ash_ui/compiler.ex
  - lib/ash_ui/liveview/liveview_integration.ex
decisions:
  - ashui.decision.control_plane_authority
  - ashui.decision.unified_ui_dsl_authority
  - ashui.decision.element_resource_authority
```

## Requirements

```spec-requirements
- id: ashui.architecture.control_planes
  statement: Ash UI shall preserve explicit framework, compilation, runtime, rendering, and governance boundaries rather than collapsing ownership into one module or one persisted document model.
  priority: must
  stability: stable
- id: ashui.architecture.relationship_graph
  statement: Screen compilation shall traverse the screen and element relationship graph as a first-class input rather than treating relationships as a secondary projection of a monolithic screen document.
  priority: must
  stability: stable
- id: ashui.architecture.inline_screen_glue
  statement: Screen-level inline fragments may exist for glue and layout scaffolding, but they shall remain subordinate to relationship-driven element composition.
  priority: should
  stability: stable
- id: ashui.architecture.current_truth_over_detour
  statement: Current architecture docs and governance shall treat the earlier screen-document-first direction as superseded historical context rather than as the active model.
  priority: must
  stability: stable
```

## Scenarios

```spec-scenarios
- id: ashui.architecture.screen_mount_flow
  given:
    - a persisted screen record exists for a screen resource module
    - the screen composes related element resources through Ash relationships
  when:
    - Ash UI mounts and compiles the screen
  then:
    - the compiler traverses the resource graph
    - runtime state is assigned from canonical output
    - renderer adapters receive canonical data instead of a monolithic screen document
  covers:
    - ashui.architecture.control_planes
    - ashui.architecture.relationship_graph
    - ashui.architecture.inline_screen_glue
```

## Verification

```spec-verification
- kind: command
  target: >-
    rg -n "control-plane|resource graph|relationship-driven|inline fragment|screen-document" README.md guides/developer/DG-0001-architecture-overview.md
  covers:
    - ashui.architecture.control_planes
    - ashui.architecture.relationship_graph
    - ashui.architecture.inline_screen_glue
    - ashui.architecture.current_truth_over_detour
    - ashui.architecture.screen_mount_flow
- kind: command
  target: >-
    rg -n "relationship-driven|resource-authority|current screen/element resource graph" lib/ash_ui/resource/authority.ex lib/ash_ui/compiler.ex lib/ash_ui/liveview/liveview_integration.ex
  covers:
    - ashui.architecture.control_planes
    - ashui.architecture.relationship_graph
    - ashui.architecture.screen_mount_flow
- kind: command
  target: mix test test/ash_ui/phase_14_integration_test.exs test/ash_ui/phase_15_integration_test.exs
  covers:
    - ashui.architecture.relationship_graph
    - ashui.architecture.screen_mount_flow
```
