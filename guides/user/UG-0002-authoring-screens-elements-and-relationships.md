# UG-0002: Authoring Screens, Elements, and Relationships

---
id: UG-0002
title: Authoring Screens, Elements, and Relationships
audience: Application Developers
status: Active
owners: Ash UI Team
last_reviewed: 2026-04-23
next_review: 2026-10-23
related_reqs: [REQ-RES-001, REQ-RES-003, REQ-RES-004, REQ-SCREEN-003]
related_scns: [SCN-001, SCN-003, SCN-004, SCN-005]
related_guides: [UG-0001, UG-0003, UG-0004, UG-0007, DG-0001]
diagram_required: false
---

## Overview

AshUI authoring is resource-local. A screen resource declares screen-wide
metadata and composition rules. Element resources declare one widget each plus
their local bindings and actions. Ash relationships and `ui_relationships`
control how those resources become a rendered screen.

This guide explains the supported authoring surface as it exists today.

## Prerequisites

Before reading this guide, you should:

- Have read [UG-0001](./UG-0001-getting-started.md).
- Know how to define Ash resources and relationships.
- Be comfortable reading maps used as DSL configuration.

## The Four Authoring Building Blocks

### `ui_screen`

`ui_screen` belongs on a screen resource and currently supports these keys:

| Key | Purpose |
|---|---|
| `layout` | Top-level screen layout. Supported values are `:default`, `:bare`, `:modal`, `:panel`, `:row`, `:column`, `:grid`, `:stack`. |
| `route` | Optional route string persisted with the screen record. |
| `metadata` | Free-form screen metadata. |
| `inline_fragment` | Optional canonical fragment map merged into the screen composition. |

### `ui_element`

`ui_element` belongs on an element resource and currently supports:

| Key | Purpose |
|---|---|
| `type` | Widget type, validated against the current public AshUI vocabulary. |
| `props` | Free-form props map. Validation is type-level, while most prop semantics are renderer-specific. |
| `variants` | Semantic tags preserved with the element definition. |
| `metadata` | Free-form metadata, commonly including a stable `id`. |

Two practical notes:

- `metadata.id` is worth treating as required in real applications because event routing and diagnostics are easier when every element has a stable id.
- `variants` is not the same as `props[:variant]`. The shipped fallback LiveView adapter mostly reads `props`, not the `variants` list.

### `ui_bindings` and `ui_actions`

Element resources own interactive behavior:

| Construct | Purpose |
|---|---|
| `ui_bindings` | Declares `:value`, `:list`, or `:action` bindings owned by the element. |
| `ui_actions` | Declares signal-triggered actions such as button clicks. |

Each binding/action is validated at compile time. Signals and binding types are
not globally free-form; they are constrained by widget type.

### `ui_relationships`

`ui_relationships` maps Ash relationships to visual composition semantics:

| Key | Purpose |
|---|---|
| `kind` | `:child` or `:companion` |
| `slot` | Named placement area such as `:body`, `:header`, `:aside`, or `:actions` |
| `placement` | `:append` or `:prepend` |
| `order` | Non-negative integer order within the slot |

This layer is what makes Ash relationships visible to the compiler and
renderer.

## A Realistic Screen Shape

```elixir
defmodule MyApp.UI.ProfileScreen do
  use Ash.Resource, domain: MyApp.UI.Domain, data_layer: Ash.DataLayer.Ets
  use AshUI.Resource.DSL.Screen

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read])
  end

  relationships do
    has_many :hero_elements, MyApp.UI.ProfileHero do
      destination_attribute(:screen_id)
    end

    has_many :sidebar_badges, MyApp.UI.ProfileBadge do
      destination_attribute(:screen_id)
    end
  end

  ui_relationships do
    relationship :hero_elements do
      kind :child
      slot :body
      placement :append
      order 0
    end

    relationship :sidebar_badges do
      kind :companion
      slot :aside
      placement :prepend
      order 1
    end
  end

  ui_screen do
    layout :column
    route "/profile"
    metadata %{title: "Profile"}

    inline_fragment %{
      type: "column",
      props: %{spacing: 12},
      children: [
        %{
          type: "text",
          props: %{content: "Inline screen chrome"},
          children: [],
          signals: [],
          metadata: %{id: "profile_banner"}
        }
      ],
      signals: [],
      metadata: %{id: "profile_shell"}
    }
  end

  ui_screen_bindings do
    binding :screen_notice do
      source %{resource: "Demo.Page", field: "notice", id: "profile"}
      target "flash.notice"
      binding_type :value
      transform %{default: "ready"}
    end
  end
end
```

## Screen-Scoped vs Element-Scoped Bindings

The current rule is strict:

- Screen-scoped bindings can only target `title` or prefixes `flash.`, `screen.`, and `metadata.`
- Element-scoped bindings cannot target those reserved screen fields

This separation keeps global screen state and local widget state from drifting
into each other.

## Relationship Semantics Matter More Than Nesting Tricks

AshUI wants you to express composition through relationships instead of trying
to encode everything into one raw stored tree.

Prefer:

- one screen resource that describes the page
- focused element resources that each own one widget or panel
- explicit relationship semantics for slot, order, and placement

Avoid:

- hiding your real screen structure only in `inline_fragment`
- putting screen-global bindings on an element
- treating the persisted `unified_dsl` snapshot as the authoring surface

## Authoring Conventions That Age Well

- Give every element a stable `metadata.id`.
- Keep bindings and actions on the element that owns the interaction.
- Use `:child` for primary content and `:companion` for supporting chrome such as actions or badges.
- Use `inline_fragment` for screen shell chrome, not as a replacement for element resources.
- Keep `props` small and purposeful; arbitrary props survive, but only renderer-read props have stable immediate behavior.

## See Also

- [UG-0001: Getting Started with AshUI](./UG-0001-getting-started.md)
- [UG-0003: Widget Types, Styling, Properties, and Signals](./UG-0003-widget-types-properties-and-signals.md)
- [UG-0007: Data Surfaces and Composition Patterns](./UG-0007-data-surfaces-and-composition-patterns.md)
- [Resource contract](../../specs/contracts/resource_contract.md)
