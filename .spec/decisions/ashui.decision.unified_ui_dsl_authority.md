---
id: ashui.decision.unified_ui_dsl_authority
status: superseded
date: 2026-04-19
superseded_by: ashui.decision.element_resource_authority
affects:
  - ashui.architecture
  - ashui.resource_authoring
  - ashui.runtime_authorization
---

# Unified UI DSL Top-Level Authority

## Context

Ash UI previously explored a direction where upstream `unified_ui` became the
top-level persisted authoring authority and Ash UI behaved more like a runtime
wrapper around monolithic screen documents.

## Decision

That direction is superseded. Upstream `unified_ui` still owns embedded widget,
layout, theming, and lowering semantics, but it does not replace the Ash
resource graph as Ash UI's top-level authoring model.

## Consequences

Historical references to screen-document-first authority remain part of the
decision record only. Current code, docs, and governance should align with the
resource-first model defined by `ashui.decision.element_resource_authority`.
