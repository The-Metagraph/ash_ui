# UG-0008: Migration from Older AshUI Models

---
id: UG-0008
title: Migration from Older AshUI Models
audience: Application Developers
status: Active
owners: Ash UI Team
last_reviewed: 2026-05-14
next_review: 2026-11-14
related_reqs: [REQ-RES-001, REQ-COMP-001, REQ-RENDER-001, REQ-AUTH-002, REQ-WIDGET-003, REQ-WIDGET-009]
related_scns: [SCN-004, SCN-041, SCN-061, SCN-081]
related_guides: [UG-0001, UG-0002, UG-0005, DG-0002, DG-0006]
diagram_required: false
---

## Overview

AshUI no longer treats legacy builder-shaped `unified_dsl` payloads as a normal
runtime authoring format. The supported path is resource-local authoring through
screen and element resources. Legacy builder payloads are migration input only.

This guide explains how to move older material onto the current model without
teaching the old model as if it were still primary.

## Prerequisites

Before reading this guide, you should:

- Have read [UG-0001](./UG-0001-getting-started.md).
- Know whether you still store builder-shaped `unified_dsl` payloads.
- Be ready to treat migration as a one-time compatibility task.

## What Changed

Older examples and prototypes often centered on hand-authored builder-shaped
documents. Current AshUI instead expects:

- screen resources as the top-level authoring unit
- element resources as local widget owners
- relationships plus `ui_relationships` for composition
- persisted screen snapshots created from resource authority

The current compiler keeps a hard cut here: migrated legacy documents are not
the supported long-term runtime authoring boundary.

## Migration Workflow

### 1. Inspect the legacy payload

Use `AshUI.Authoring.Migrator.dry_run/2` first:

```elixir
legacy_dsl = %{
  type: "column",
  props: %{},
  children: [
    %{type: "text", props: %{content: "Legacy dashboard"}, children: [], signals: [], metadata: %{}}
  ],
  signals: [],
  metadata: %{}
}

report = AshUI.Authoring.Migrator.dry_run(legacy_dsl)
```

The report tells you:

- which widget types are present
- which widget types are unsupported
- how many nodes and signals exist

### 2. Build migrated screen attrs

```elixir
{:ok, attrs} =
  AshUI.Authoring.Migrator.screen_attrs(legacy_dsl,
    name: "legacy_dashboard",
    route: "/legacy-dashboard",
    layout: :column,
    metadata: %{title: "Legacy Dashboard"}
  )
```

### 3. Persist the migrated record

Persist the returned attrs into the configured screen resource through your
normal data path.

### 4. Rewrite to resource-local authoring

Do not stop at migrated storage. The durable target is to rewrite the screen as:

- one screen resource
- focused element resources
- local bindings and actions
- explicit relationship semantics

## Compatibility Notes

The migrator understands the legacy builder input boundary and reports whether
it uses unsupported widget types under the current storage vocabulary.

Normalization still matters during migration:

- `text_input` becomes `input`
- `radio_group` becomes `radio`
- `toggle` becomes `switch`
- `separator` becomes `divider`
- `phoenix_form` becomes `runtime_form_shell`
- `repeat` becomes `list_repeat`
- `ui_relationship_repeat` becomes `list_repeat`

Those same normalization rules now show up in the maintained example suite. The
important distinction is:

- keep the sibling directory name stable for review and migration parity
- normalize the canonical Ash UI subject honestly in docs, metadata, and
  authoring validation

Examples:

- the `text_input` directory is reviewed as `text_input`, but its canonical Ash UI type is `input`
- the `radio_group` directory is reviewed as `radio_group`, but its canonical type is `radio`
- the `toggle` directory is reviewed as `toggle`, but its canonical type is `switch`
- the `separator` directory is reviewed as `separator`, but its canonical type is `divider`

This keeps historical example references stable without teaching renamed
compatibility aliases as if they were the primary authoring vocabulary.

Canonical widget components should replace older custom names when the surface
is now cataloged. For example, migrate a custom form shell to
`runtime_form_shell`, a custom segmented selector to `segmented_button_group`,
custom chat input shells to `chat_composer`, custom artifact rows to
`artifact_row`, custom callouts to `event_callout`, custom redline snippets to
`redline_inline`, and custom highlighted code blocks to
`code_block_syntax_highlighted`.

Keep `custom:*` only when the surface remains application-owned or example-only
and is not in the canonical component catalog. If a surface is cataloged, use
the canonical kind directly and let AshUI normalize supported aliases during
authoring.

## Contribution Notes for Migrated Material

If you are turning an older prototype or legacy example into a checked-in Ash UI
example app, keep these rules together:

- preserve the stable directory name when it matches the sibling `unified_ui` catalog
- rewrite the actual screen and element resources to the current canonical Ash UI types
- call out `custom:*` or composed review surfaces explicitly instead of pretending they are public built-ins
- replace older custom component names with canonical widget-component names when the component exists in the Unified catalog
- update the root example-suite docs and metadata so parity, normalization, and support status remain visible
- avoid reintroducing builder-first terminology into example READMEs, guides, or launch tooling

## What Not to Do

- Do not add new product work on top of `AshUI.DSL.Builder`.
- Do not treat migrated documents as the preferred future authoring path.
- Do not point new guides or examples back toward builder-first authoring.

## When Migration Is Complete

You are done when:

- persisted runtime records come from resource authority instead of builder docs
- screens mount from persisted resource-authority payloads
- new work uses `AshUI.Resource.DSL.Screen` and `AshUI.Resource.DSL.Element`
- legacy builder usage is isolated to explicit migration input only

## See Also

- [examples/README.md](../../examples/README.md)
- [UG-0001: Getting Started with AshUI](./UG-0001-getting-started.md)
- [UG-0002: Authoring Screens, Elements, and Relationships](./UG-0002-authoring-screens-elements-and-relationships.md)
- [DG-0002: Storage, Resource Authority, and Configuration](../developer/DG-0002-storage-resource-authority-and-configuration.md)
- [DG-0006: Contribution and Release Workflow](../developer/DG-0006-contribution-and-release-workflow.md)
