# UG-0003: Widget Types, Properties, and Signals

---
id: UG-0003
title: Widget Types, Properties, and Signals
audience: Application Developers
status: Active
owners: Ash UI Team
last_reviewed: 2026-04-23
next_review: 2026-10-23
related_reqs: [REQ-RES-002, REQ-BIND-002, REQ-BIND-008, REQ-RENDER-002]
related_scns: [SCN-002, SCN-009, SCN-061, SCN-101]
related_guides: [UG-0002, UG-0004, UG-0005, UG-0007, DG-0001]
diagram_required: false
---

## Overview

AshUI currently has three different boundaries that matter when you talk about
widgets:

1. The public `ui_element type` vocabulary accepted by authoring validation
2. The props that the shipped fallback LiveView adapter actually reads today
3. The signal capabilities that AshUI allows for actions and bindings

Those boundaries do not fully overlap. This guide keeps them separate so you
can design screens against what AshUI actually supports today.

## Prerequisites

Before reading this guide, you should:

- Have read [UG-0002](./UG-0002-authoring-screens-elements-and-relationships.md).
- Understand that `props` is a free-form map.
- Know that some richer behavior depends on renderer packages beyond the shipped fallback adapter.

## Public Authoring Types Available Today

These are the types currently accepted by `ui_element` validation.

### Layout and Structure

| Type | Typical use | Fallback LiveView props explicitly read |
|---|---|---|
| `row` | Horizontal layout | `spacing` |
| `column` | Vertical layout | `spacing` |
| `grid` | Multi-column layout | `columns`, `spacing` |
| `stack` | Overlaid or stacked grouping | `spacing` |
| `fragment` | Canonical wrapper fragment | none |
| `container` | Generic wrapper container | none |
| `card` | Panel or bounded container | no widget-specific props are read by the fallback adapter |
| `form_field` | Field wrapper | `name` as `data-field-name` |
| `divider` | Rule or separator | none |
| `spacer` | Fixed empty space | `size` |

### Content and Display

| Type | Typical use | Fallback LiveView props explicitly read |
|---|---|---|
| `text` | Inline or block copy | `content` or `text`, optional `size`, `color`, `weight`, `align` |
| `hero` | Large intro section | `eyebrow`, `title`, `message` |
| `badge` | Small status label | `presentation`, `text` or `label` or `content` |
| `stat` | Metric card | `title`, `value`, `message` |
| `key_value` | Definition row | `label` or `title`, `value`, `description` |
| `info_list` | Simple list of labeled values | `items`, optional `ordered?` |
| `list` | Collection surface | `title`, `description`, `empty_text`, hydrated `items` |
| `table` | Tabular collection surface | `title`, `description`, `empty_text`, `columns`, hydrated `items` |
| `image` | Image/media slot | no widget-specific props are read by the fallback adapter |
| `icon` | Icon slot | no widget-specific props are read by the fallback adapter |

### Interactive

| Type | Typical use | Fallback LiveView props explicitly read |
|---|---|---|
| `button` | Action trigger | `label`, `variant` |
| `input` | Single-line text-style input | `name`, `placeholder`, `value`, `type` |
| `textarea` | Multi-line text input | `name`, `placeholder`, `value`, `rows` |
| `checkbox` | Boolean input | `name`, `checked` |
| `select` | Option picker | `name`, `options`, `value` |
| `radio` | Exclusive option choice | no dedicated fallback widget markup |
| `switch` | Toggle input | no dedicated fallback widget markup |
| `slider` | Range input | no dedicated fallback widget markup |

You can also author `custom:*` types. They are accepted as widget types, but the
shipped validation/runtime does not automatically give them built-in signal
semantics. Some explicitly supported custom surfaces do have dedicated fallback
renderer behavior, but that does not make them public built-in widget types.

## Shared Styling Props the Fallback Adapter Reads

Across many widgets, the fallback LiveView adapter also reads:

- `class`
- `inline_style`
- `style` when it is a string or a `%{extra: %{css: ...}}` shaped map

These are renderer conveniences, not the same thing as stable semantic props.

## Signals and Binding Capabilities

Signal support is type-specific.

### Widgets That Accept `ui_actions`

| Widget type | Supported signals |
|---|---|
| `button` | `:click`, `:submit` |
| `input` | `:change`, `:input`, `:submit` |
| `textarea` | `:change`, `:input`, `:submit` |
| `select` | `:change`, `:input`, `:submit` |
| `checkbox` | `:change`, `:toggle` |
| `radio` | `:change`, `:input` |
| `switch` | `:change`, `:toggle` |
| `slider` | `:change`, `:input` |

If you declare a signal outside this matrix, authoring validation raises.

### Widgets That Accept `binding_type :list`

| Widget type | Notes |
|---|---|
| `info_list` | Best current built-in collection display surface in the fallback adapter |
| `list` | Collection-capable and now renders a dedicated fallback collection surface |
| `table` | Collection-capable and now renders a dedicated fallback tabular surface |
| `select` | Collection-capable for option loading |

### Widgets That Accept `binding_type :action`

The current action-binding-capable widgets are:

- `button`
- `input`
- `textarea`
- `select`
- `checkbox`
- `radio`
- `switch`
- `slider`

## Compatibility and Normalization Notes

AshUI internally normalizes some upstream names:

| Upstream or compatibility name | Canonical AshUI type |
|---|---|
| `text_input` | `input` |
| `radio_group` | `radio` |
| `toggle` | `switch` |
| `separator` | `divider` |

Two important edge cases:

- The fallback LiveView adapter understands `label` and `form_builder`, but they are not part of the current validated public `ui_element type` vocabulary.
- `props[:variant]` on `button` is renderer-read today, while `variants [...]` on `ui_element` is better treated as semantic tagging for downstream tooling.

### Example-Suite Custom Surfaces

The checked-in example suite now relies on a small set of explicitly rendered
`custom:*` surfaces that remain outside the public widget vocabulary:

| Example-facing type | Intended use | Signal ownership rule |
|---|---|---|
| `custom:link` | Honest navigation affordance until link semantics are admitted publicly | keep navigation/browser behavior on the custom surface itself; do not assume Ash write semantics |
| `custom:pick_list` | Multi-pick style review surface with narrowed runtime semantics | keep value change semantics explicit and narrow |
| `custom:field_group` | Grouped form review shell around native `form_field` children | keep write semantics on nested inputs |
| `custom:menu` | Navigation shell around child buttons/text | keep actions on nested public child widgets |
| `custom:tabs` | Tabbed review shell around child buttons/panels | keep tab switching on nested public child widgets |
| `custom:command_palette` | Command launcher shell around search/input and command actions | keep search and command actions on nested public child widgets |
| `custom:viewport` | Example-only viewport review frame | keep state changes on nested public child widgets |
| `custom:scroll_bar` | Example-only scroll affordance shell | keep state changes on nested public child widgets |
| `custom:split_pane` | Example-only two-pane layout shell | keep focus or mode changes on nested public child widgets |
| `custom:canvas` | Example-only drawing/review shell | keep tool changes or writes on nested public child widgets |
| `custom:overlay` | Example-only layered review shell | keep open or dismiss actions on nested public child widgets |
| `custom:dialog` | Example-only modal confirmation shell | keep confirm or cancel actions on nested public child widgets |
| `custom:alert_dialog` | Example-only high-severity modal shell | keep destructive or recovery actions on nested public child widgets |
| `custom:context_menu` | Example-only contextual action menu shell | keep menu item actions on nested public child widgets |
| `custom:tree_view` | Example-only hierarchical inspection shell | keep branch swaps and state changes on nested public child widgets |
| `custom:markdown_viewer` | Example-only document-reading shell | keep document switching on nested public child widgets |
| `custom:log_viewer` | Example-only log-reading shell | keep stream switching on nested public child widgets |
| `custom:toast` | Example-only transient notification shell | keep trigger actions on nested public child widgets |

Treat those as explicit renderer extensions for the example suite, not as
stable built-in authoring types for general application work.

## Choosing the Right Widget Today

- Use `hero`, `stat`, `key_value`, and `info_list` when you want predictable shipped fallback rendering.
- Use `list`, `table`, `image`, `icon`, `radio`, `switch`, and `slider` only if your chosen renderer path supports them or a generic wrapper is acceptable.
- Use `custom:*` when you are deliberately extending the renderer boundary or building an explicitly example-only shell, not when you need a built-in interactive widget.

## See Also

- [UG-0002: Authoring Screens, Elements, and Relationships](./UG-0002-authoring-screens-elements-and-relationships.md)
- [UG-0004: Bindings, Actions, and Forms](./UG-0004-bindings-actions-and-forms.md)
- [UG-0005: LiveView Runtime and Rendering](./UG-0005-liveview-runtime-and-rendering.md)
- [Rendering contract](../../specs/contracts/rendering_contract.md)
