---
id: ashui.decision.element_resource_authority
status: accepted
date: 2026-04-19
affects:
  - ashui.package
  - ashui.architecture
  - ashui.resource_authoring
  - ashui.runtime_authorization
  - ashui.rendering
  - ashui.governance
---

# Element Resource Authority And Relationship-Driven Composition

## Context

Ash UI's core value is Ash-native UI composition. When authoring authority
drifts into detached screen documents, bindings and actions move away from the
elements that own them, relationships lose architectural meaning, and screens
become monoliths.

## Decision

Keep Ash resources that use `AshUI.Resource.DSL.*` as the authoritative UI
authoring units. Element resources own their local DSL, bindings, and actions.
Screen resources remain the mount boundary and composition root, but they should
compose primarily through Ash relationships plus `ui_relationships`, using
inline fragments only as subordinate glue.

Persisted `Screen.unified_dsl` payloads remain storage snapshots generated from
the authority graph; they are not the primary source of truth.

## Consequences

Code, guides, examples, governance scripts, and release checks should describe
the resource-first architecture directly. Historical document-first flows may
persist only as migration or compatibility artifacts, not as the preferred
public model.
