# UG-0007: Data Surfaces and Composition Patterns

---
id: UG-0007
title: Data Surfaces and Composition Patterns
audience: Application Developers
status: Active
owners: Ash UI Team
last_reviewed: 2026-04-23
next_review: 2026-10-23
related_reqs: [REQ-SCREEN-003, REQ-BIND-002, REQ-BIND-007, REQ-RENDER-002, REQ-RAIL-011]
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

## Pattern 6: Reusable Right Rail Inspectors

Use `right_rail` when a screen needs secondary panels that can switch between
related views such as summary, activity, sources, or document metadata. The
rail element owns panel order, active panel state, collapsed state, and
semantic panel descriptors. Related child resources own the panel bodies.

```elixir
ui_element do
  type(:right_rail)

  props(%{
    side: :right,
    active_panel: :summary,
    collapsed?: false,
    collapsible?: true,
    panels: [
      %{id: :summary, label: "Summary", content_slot: :summary_body},
      %{id: :activity, label: "Activity", badge: "3", content_slot: :activity_body},
      %{id: :sources, label: "Sources", disabled?: true, empty_state: "No sources yet"}
    ]
  })

  metadata(%{id: "case_inspector_rail"})
end
```

```elixir
ui_relationships do
  relationship :summary_panel do
    kind(:child)
    slot(:summary_body)
    placement(:append)
    order(0)
  end

  relationship :activity_panel do
    kind(:child)
    slot(:activity_body)
    placement(:append)
    order(1)
  end
end
```

The same canonical rail can power a document-oriented sidebar. Name the
resource for your domain, but keep the canonical element type as `right_rail`.
`doc_right_rail` may be an application-local composition name; it is not shared
package vocabulary.

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
- [UG-0003: Widget Types, Styling, Properties, and Signals](./UG-0003-widget-types-properties-and-signals.md)
- [UG-0005: LiveView Runtime and Rendering](./UG-0005-liveview-runtime-and-rendering.md)
- [Rendering contract](../../specs/contracts/rendering_contract.md)
