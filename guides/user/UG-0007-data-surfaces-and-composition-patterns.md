# UG-0007: Data Surfaces and Composition Patterns

---
id: UG-0007
title: Data Surfaces and Composition Patterns
audience: Application Developers
status: Active
owners: Ash UI Team
last_reviewed: 2026-04-23
next_review: 2026-10-23
related_reqs: [REQ-SCREEN-003, REQ-BIND-002, REQ-BIND-007, REQ-RENDER-002]
related_scns: [SCN-005, SCN-008, SCN-011, SCN-061]
related_guides: [UG-0002, UG-0003, UG-0004, UG-0005, UG-0006]
diagram_required: false
---

## Overview

Once you understand authoring and bindings, the next question is usually how to
compose a real screen. AshUI is strongest today when you build screens from a
small set of predictable display surfaces and relationship-driven panels rather
than trying to force a monolithic page object into one resource.

This guide shows the patterns that best match the current implementation.

## Prerequisites

Before reading this guide, you should:

- Have read [UG-0002](./UG-0002-authoring-screens-elements-and-relationships.md).
- Know the current widget vocabulary from [UG-0003](./UG-0003-widget-types-properties-and-signals.md).
- Understand list and value bindings.

## Pattern 1: Hero + Metrics + Metadata

This is the cleanest current dashboard pattern:

- `hero` for the opening story
- `stat` for headline metrics
- `key_value` for compact metadata
- `info_list` for supporting detail rows

This pattern matches the shipped fallback renderer well and keeps the screen
legible without custom renderer work.

## Pattern 2: Panel Composition Through Relationships

Use one parent panel element such as `card`, then attach related children using
`ui_relationships`:

- `:child` in `:body` for the main content
- `:companion` in `:aside` for secondary facts
- `:companion` in `:actions` for controls

That preserves explicit ownership and ordering while keeping the screen module
small.

## Pattern 3: Inline Screen Chrome Plus Resource-Owned Content

Use `ui_screen.inline_fragment` for top-level shell content that belongs to the
screen itself, for example:

- a banner text row
- a static wrapper column
- small top-of-screen explanatory copy

Do not use `inline_fragment` as a substitute for the main screen body. Real
content panels should still live in element resources so bindings, actions, and
relationships stay explicit.

## Pattern 4: Collection Displays

The collection-capable widgets are not equally mature in the fallback renderer.

### Best current fallback choice

Use `info_list` when you want:

- a collection that visibly renders today
- small labeled rows
- low renderer risk

### Use with renderer awareness

Use `list` or `table` when:

- your chosen renderer package handles them
- or a generic wrapper is acceptable while the data remains available in canonical IUR

### Special case: `select`

`select` accepts `binding_type :list`, but that is an input pattern for options,
not a read-only collection display pattern.

## Pattern 5: Form Panels in Data Screens

When a screen mixes display and editing:

- keep display surfaces in one panel
- keep editable controls in a separate panel
- keep the submit action in an `:actions` slot companion

That prevents display widgets from becoming accidental form containers.

## Example Composition Sketch

```elixir
ui_relationships do
  relationship :hero_elements do
    kind :child
    slot :body
    placement :append
    order 0
  end

  relationship :stat_tiles do
    kind :child
    slot :body
    placement :append
    order 1
  end

  relationship :metadata_rows do
    kind :companion
    slot :aside
    placement :append
    order 2
  end

  relationship :action_buttons do
    kind :companion
    slot :actions
    placement :append
    order 3
  end
end
```

The important part is not the specific slot names. The important part is that
composition is explicit, ordered, and relationship-driven.

## Composition Advice for Real Apps

- Prefer several small element resources over one massive element resource.
- Use `info_list` for low-risk collection display until your renderer path needs more.
- Keep slot names consistent across a screen family so renderer chrome stays predictable.
- Treat `card` as a structural panel in the shipped fallback renderer, not as a full semantic card system.
- Keep action buttons in `:actions` companions when they act on a panel.

## See Also

- [UG-0002: Authoring Screens, Elements, and Relationships](./UG-0002-authoring-screens-elements-and-relationships.md)
- [UG-0003: Widget Types, Properties, and Signals](./UG-0003-widget-types-properties-and-signals.md)
- [UG-0005: LiveView Runtime and Rendering](./UG-0005-liveview-runtime-and-rendering.md)
- [Rendering contract](../../specs/contracts/rendering_contract.md)
