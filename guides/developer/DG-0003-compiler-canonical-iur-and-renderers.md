# DG-0003: Compiler, Canonical IUR, and Renderers

---
id: DG-0003
title: Compiler, Canonical IUR, and Renderers
audience: Framework Developers
status: Active
owners: Ash UI Team
last_reviewed: 2026-04-23
next_review: 2026-10-23
related_reqs: [REQ-COMP-001, REQ-RENDER-001, REQ-RENDER-002, REQ-BIND-002]
related_scns: [SCN-041, SCN-061, SCN-101]
related_guides: [DG-0001, DG-0002, DG-0004, UG-0003, UG-0005]
diagram_required: true
---

## Overview

This guide explains how AshUI compiles persisted screens into internal IUR,
converts that IUR into canonical renderer-facing data, and selects renderer
adapters. It is the guide to read before changing widget lowering, cache
behavior, canonical conversion, or adapter output.

## Prerequisites

Before reading this guide, you should:

- Have read [DG-0001](./DG-0001-architecture-and-control-planes.md).
- Understand the storage and authority boundary from [DG-0002](./DG-0002-storage-resource-authority-and-configuration.md).
- Know the current public widget vocabulary from [UG-0003](../user/UG-0003-widget-types-properties-and-signals.md).

## Compilation to Canonical Output

```mermaid
flowchart LR
    Screen["persisted Screen record"]
    Compiler["AshUI.Compiler"]
    IUR["AshUI.Compilation.IUR"]
    Canonical["AshUI.Rendering.IURAdapter"]
    Registry["AshUI.Rendering.Registry"]
    Selector["AshUI.Rendering.Selector"]
    Adapter["renderer adapter"]

    Screen --> Compiler
    Compiler --> IUR
    IUR --> Canonical
    Canonical --> Registry
    Registry --> Selector
    Selector --> Adapter
```

## Compiler Responsibilities

`AshUI.Compiler` currently owns:

- loading stored screen records by id
- validating that the record belongs to the configured screen resource
- compiling from supported persisted authority payloads
- regenerating compiler input from the authoritative screen/element graph
- caching compiled results in ETS
- invalidation and cache stats
- compilation telemetry

The compiler no longer treats detached historical authoring payloads as a normal
runtime input. The supported runtime compiler path is the resource-authority
screen boundary.

## Cache Behavior

The compiler cache key includes:

- screen id
- screen version
- document-derived cache suffix

When changing compile behavior, pay attention to whether the change should
invalidate on:

- version changes
- screen-level overrides
- runtime snapshot drift

Incorrect cache semantics are easy to miss in unit-only review.

## Canonical IUR Responsibilities

`AshUI.Rendering.IURAdapter` is the renderer-facing normalization seam.

It currently:

- validates the internal IUR
- maps internal element types to canonical widget strings
- lowers binding types into canonical signal categories
- passes canonical payloads through `UnifiedIUR.validate/1`
- emits conversion success and error telemetry

That means a widget change is often not complete until both the compiler and the
canonical adapter agree on the shape.

## Type and Binding Lowering

Two internal conversions matter most:

- element kinds become canonical widget strings such as `input`, `button`, `row`, or `table`
- binding types become canonical signal families such as `bidirectional`, `collection`, and `event`

If a new widget or binding family is introduced without updating canonical
lowering, adapters either fall back incorrectly or fail validation later.

## Renderer Registry and Fallback Modes

AshUI distinguishes between:

- external renderer package availability
- local adapter fallback renderability

The renderer registry and selector decide which adapter module and mode are
available. The adapters themselves then either delegate to external packages or
generate local fallback output.

This distinction is part of the current architecture and should stay explicit in
code and docs.

## Safe Change Checklist for Widget or Renderer Work

When changing a widget family, check all of these:

- public authoring validation
- resource-authority payload generation
- compiler lowering
- canonical IUR conversion
- adapter output
- user-guide widget documentation
- spec surfaces for storage, compiler, rendering, or runtime

## See Also

- [DG-0002: Storage, Resource Authority, and Configuration](./DG-0002-storage-resource-authority-and-configuration.md)
- [DG-0004: Runtime, Bindings, and Authorization](./DG-0004-runtime-bindings-and-authorization.md)
- [DG-0005: Testing, Conformance, and Governance](./DG-0005-testing-conformance-and-governance.md)
- [UG-0005: LiveView Runtime and Rendering](../user/UG-0005-liveview-runtime-and-rendering.md)
