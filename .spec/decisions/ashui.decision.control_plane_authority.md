---
id: ashui.decision.control_plane_authority
status: accepted
date: 2026-04-19
affects:
  - ashui.architecture
  - ashui.runtime_authorization
  - ashui.rendering
  - ashui.governance
---

# Control Plane Authority

## Context

Ash UI spans framework authoring, compilation, runtime, rendering, and
governance concerns. Without explicit ownership boundaries, architectural drift
and duplicate behavior definitions become hard to detect.

## Decision

Keep explicit control-plane boundaries:

- framework/resource authoring owns schemas, DSL surface, and structural
  contracts
- compilation owns resource-graph traversal, lowering orchestration, and cache
  behavior
- runtime owns mount, update, lifecycle, and event routing
- rendering owns canonical conversion and adapter selection
- governance owns current-truth documentation and validation automation

Cross-plane behavior should be coordinated through documented contracts rather
than informal module reach-through.

## Consequences

Architectural disputes can be resolved against named boundaries instead of
implicit precedent. Changes that cross multiple planes should update the
relevant `.spec` subjects and, when durable, this ADR set.
