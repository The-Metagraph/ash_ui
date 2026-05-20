# UG-0003: Widget Types, Styling, Properties, and Signals

---
id: UG-0003
title: Widget Types, Styling, Properties, and Signals
audience: Application Developers
status: Active
owners: Ash UI Team
last_reviewed: 2026-05-14
next_review: 2026-11-14
related_reqs: [REQ-RES-002, REQ-BIND-002, REQ-BIND-008, REQ-RENDER-002, REQ-WIDGET-001, REQ-WIDGET-002, REQ-WIDGET-003, REQ-WIDGET-008, REQ-WIDGET-009, REQ-RAIL-011]
related_scns: [SCN-002, SCN-009, SCN-061, SCN-101, SCN-165]
related_guides: [UG-0002, UG-0004, UG-0005, UG-0007, DG-0001]
diagram_required: false
---

## Overview

AshUI currently has four different boundaries that matter when you talk about
widgets and styling:

1. The public `ui_element type` vocabulary accepted by authoring validation
2. The semantic styling intent declared by resource-authored elements
3. The props that the shipped fallback LiveView adapter actually reads today
4. The signal capabilities that AshUI allows for actions and bindings

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
| `form_builder` | Form container and submit boundary | no widget-specific props are read; submit behavior is action-driven |
| `form_field` | Field wrapper | `name` as `data-field-name` |
| `divider` | Rule or separator | none |
| `spacer` | Fixed empty space | `size` |

### Content and Display

| Type | Typical use | Fallback LiveView props explicitly read |
|---|---|---|
| `text` | Inline or block copy | `content` or `text`, optional `size`, `color`, `weight`, `align` |
| `label` | Form or field label copy | `text` or `content` or `label`, optional `for` |
| `hero` | Large intro section | `eyebrow`, `title`, `message` |
| `badge` | Small status label | `presentation`, `text` or `label` or `content` |
| `confidence_indicator` | Confidence score or quality meter | `value`, `thresholds`, `label`, `show_numeric?`, `show_glyph?`, `size` |
| `diff_banner` | Comparison summary and filter chips | `new_count`, `changed_count`, `removed_count`, `active_filter`, `base_label`, `size` |
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
| `radio` | Exclusive option choice | `name`, `options`, `value` |
| `switch` | Toggle input | `checked`, `label` or `text` or `content` |
| `slider` | Range input | no dedicated fallback widget markup |
| `context_selector` | Grouped semantic context picker | `selector_id`, `groups`, `selected_values`, `max_selections`, `open?` |
| `file_tree_browser` | Filesystem-like navigation tree | `tree_id`, `root_label`, `nodes`, `selected_path`, `default_expanded?` |

### Canonical Widget Components

AshUI also admits the expanded Unified UI canonical widget-component catalog.
Use these canonical names in `ui_element type`; aliases are accepted only at
authoring boundaries and normalize before renderer-facing output.

| Family | Canonical component kinds | Compatibility aliases |
|---|---|---|
| Content, identity, and disclosure | `inline_rich_text_heading`, `disclosure`, `kicker`, `avatar`, `presence_dot` | none |
| Form control and composer | `runtime_form_shell`, `segmented_button_group`, `chat_composer`, `mode_nav` | `phoenix_form` -> `runtime_form_shell` |
| Row and artifact | `list_item_multi_column`, `artifact_row` | none |
| Workflow, progress, and status | `pipeline_stepper_horizontal`, `segmented_progress_bar`, `workflow_stage_list_vertical`, `meter_thin`, `unread_badge`, `workflow_progress_status_card` | none |
| Layer shell and callout | `sticky_frosted_header`, `slide_over_panel`, `event_callout`, `top_strip`, `sidebar_shell`, `sidebar_section`, `sidebar_item`, `command_palette`, `right_rail` | none |
| Redline and code | `redline_inline`, `code_block_syntax_highlighted` | none |
| Composition behavior | `list_repeat` | `repeat` -> `list_repeat`, `ui_relationship_repeat` -> `list_repeat` |

`list_repeat` is not a visual list shell. It is a composition behavior for
relationship-owned row templates. Declare the repeat list binding through
`ui_relationships`, keep the row template as an element resource, and use
row-scoped values such as `%{scope: :row, field: :title}` inside the template
props.

`right_rail` is the reusable rail component for inspector panels, document
sidebars, contextual tools, and similar secondary surfaces. Author it with
generic rail props:

- `panels`: ordered panel descriptors such as `%{id: :summary, label: "Summary", content_slot: :summary_body}`
- `active_panel`: the selected panel id
- `collapsed?` and `collapsible?`: rail collapse state and capability
- optional per-panel `badge`, `disabled?`, and `empty_state`
- `content_slot`: the relationship slot that supplies each panel body

Concrete layout width, responsive behavior, and visual treatment belong to the
renderer or host application CSS. Document-specific rails should compose
`right_rail` with document panel resources; do not introduce `doc_right_rail`
as a canonical widget type.

`workflow_progress_status_card` is the reusable card for a workflow subject.
Use it for health, progress, dependency, release, or coordination surfaces that
need the same subject identity plus status shape. Author generic subject props
such as `subject_id`, `name`, `path`, `progress_pct`, `active_count`,
`blocked_count`, `depends_on`, `depended_by`, `selected?`, and optional
`open_action`. The canonical renderer-facing output groups those values under
`attributes.subject`; it does not expose map placement names, route helpers,
LiveView event fields, or application-specific card names.

You can also author `custom:*` types. They are accepted as widget types, but the
shipped validation/runtime does not automatically give them built-in signal
semantics. Some explicitly supported custom surfaces do have dedicated fallback
renderer behavior, but that does not make them public built-in widget types.
Do not use `custom:*` for a component listed in the canonical catalog; use the
canonical kind and let AshUI normalize any supported alias.

## Shared Styling Props the Fallback Adapter Reads

Across many widgets, the fallback LiveView adapter also reads:

- `class`
- `inline_style`
- `style` when it is a string or a `%{extra: %{css: ...}}` shaped map

These are renderer conveniences, not the same thing as stable semantic props.

## Theme and Styling Model

AshUI does not currently define a global theme resource. The supported model is
resource-authored semantic intent plus host-owned CSS.

Element resources declare intent in `ui_element` through:

- `props[:class]` for host-defined semantic CSS hooks
- `props[:variant]` when the selected renderer documents that it reads a
  variant prop for the widget
- `variants [...]` for semantic tags that should stay attached to the element
  definition for tooling, review, or future renderer use
- `props[:inline_style]` or `props[:style]` only for dynamic values that cannot
  be expressed as semantic classes or variants

Host applications own the concrete visual system: palette tokens, gradients,
shell treatments, spacing rhythm, responsive layout, and CSS class definitions.
The resource should say "primary CTA", "review panel", or "signal preview";
the host CSS decides what those names look like.

For example:

```elixir
ui_element do
  type(:button)

  props(%{
    label: "Save profile",
    class: "profile-primary-cta",
    variant: "primary"
  })

  variants([:primary, :profile_action])
  metadata(%{id: "save_profile_button"})
end
```

In that shape:

- `profile-primary-cta` must be defined by the host app CSS
- `variant: "primary"` is a renderer-facing prop, not a guarantee that every
  renderer will style it the same way
- `variants([:primary, :profile_action])` records semantic tags on the authored
  element, but the shipped fallback LiveView adapter mostly reads `props`
- no palette, border radius, blur, or layout token is hard-coded into the
  resource

For example-suite apps, use the shared Ash HQ profiles from
[examples/ash_hq_theme_baseline.md](../../examples/ash_hq_theme_baseline.md):
`example_shell`, `example_panel`, `example_story`, `example_signal_preview`,
`example_code_surface`, `example_primary_cta`, `example_secondary_cta`, and
`example_status_notice`. App-local CSS may implement those names as classes,
semantic variants, or a small combination of both.

### Styling Decision Rules

- Prefer semantic class hooks over one-off inline CSS.
- Use `variants` when the style meaning should remain attached to the resource
  even if a renderer ignores it today.
- Use `props[:variant]` only when you are targeting renderer behavior that
  reads that prop, such as the fallback LiveView button renderer.
- Use `inline_style` for data-driven dimensions or measurements, such as chart
  widths or bar heights.
- Do not use `inline_style` to re-declare palette, backdrop, glass treatment,
  spacing rhythm, or other theme rules that belong in host CSS.

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
| `form_builder` | `:submit` |
| `diff_banner` | `:change`, `:input` |
| `right_rail` | `:change`, `:toggle`, `:click` |

If you declare a signal outside this matrix, authoring validation raises.

### Widgets That Accept `binding_type :list`

| Widget type | Notes |
|---|---|
| `info_list` | Best current built-in collection display surface in the fallback adapter |
| `list` | Collection-capable and now renders a dedicated fallback collection surface |
| `table` | Collection-capable and now renders a dedicated fallback tabular surface |
| `select` | Collection-capable for option loading |
| `list_repeat` | Collection-capable repeat behavior for relationship-owned row templates |

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
- `form_builder`
- `runtime_form_shell`
- `segmented_button_group`
- `chat_composer`
- `diff_banner`
- `context_selector`
- `file_tree_browser`
- `right_rail`

## Compatibility and Normalization Notes

AshUI internally normalizes some upstream names:

| Upstream or compatibility name | Canonical AshUI type |
|---|---|
| `text_input` | `input` |
| `radio_group` | `radio` |
| `toggle` | `switch` |
| `separator` | `divider` |
| `phoenix_form` | `runtime_form_shell` |
| `repeat` | `list_repeat` |
| `ui_relationship_repeat` | `list_repeat` |

Two important edge cases:

- `label` and `form_builder` are part of the current validated public `ui_element type` vocabulary.
- `form_builder` remains a thin form shell in the shipped fallback renderer; richer form semantics still live on nested public widgets.
- `props[:variant]` on `button` is renderer-read today, while `variants [...]` on `ui_element` is better treated as semantic tagging for downstream tooling.

### Representative Example Directories

The checked-in example suite is organized by sibling `unified_ui/examples`
directory name, not only by canonical Ash UI type. Use these directories when
you want to inspect the maintained behavior for each major family:

| Family | Representative directories | What they demonstrate |
|---|---|---|
| foundational content | `text`, `button`, `label`, `icon`, `image`, `link` | exact public widgets plus honest custom handling where link semantics are still explicit |
| forms and inputs | `form_builder`, `field`, `field_group`, `text_input`, `select`, `radio_group`, `toggle` | normalized input naming, composed form shells, and element-local actions/bindings |
| layout and navigation | `row`, `column`, `grid`, `menu`, `tabs`, `context_selector`, `file_tree_browser`, `command_palette` | relationship-first composition with exact and custom navigation shells |
| display and inspection | `viewport`, `scroll_bar`, `split_pane`, `canvas` | example-only display shells that keep state changes on nested public widgets |
| overlays and data surfaces | `dialog`, `alert_dialog`, `table`, `tree_view`, `markdown_viewer`, `log_viewer` | composed review shells, explicit custom boundaries, and seeded screen persistence |
| feedback and operational surfaces | `status`, `progress`, `diff_banner`, `confidence_indicator`, `sparkline`, `bar_chart`, `cluster_dashboard` | normalized status treatment, comparison feedback, custom chart shells, and runtime-rich operational review stories |

If a directory name differs from the canonical Ash UI type, treat the example
directory as the review handle and the canonical type as the runtime authoring
target.

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
| `custom:status` | Example-only status signal shell | keep state changes on nested public child widgets |
| `custom:progress` | Example-only progress signal shell | keep state changes on nested public child widgets |
| `custom:gauge` | Example-only capacity gauge shell | keep state changes on nested public child widgets |
| `custom:inline_feedback` | Example-only inline advisory shell | keep state changes on nested public child widgets |
| `custom:sparkline` | Example-only compact trend shell | keep series swaps on nested public child widgets |
| `custom:bar_chart` | Example-only categorical chart shell | keep series swaps on nested public child widgets |
| `custom:line_chart` | Example-only trend chart shell | keep series swaps on nested public child widgets |
| `custom:stream_widget` | Example-only operational feed shell | keep snapshot swaps on nested public child widgets |
| `custom:process_monitor` | Example-only process state shell | keep snapshot swaps on nested public child widgets |
| `custom:supervision_tree_viewer` | Example-only supervision hierarchy shell | keep snapshot swaps on nested public child widgets |
| `custom:cluster_dashboard` | Example-only multi-region operational shell | keep snapshot swaps on nested public child widgets |
| `custom:toast` | Example-only transient notification shell | keep trigger actions on nested public child widgets |

Treat those as explicit renderer extensions for the example suite, not as
stable built-in authoring types for general application work.

## Choosing the Right Widget Today

- Use `hero`, `stat`, `key_value`, and `info_list` when you want predictable shipped fallback rendering.
- Use `list`, `table`, `image`, `icon`, `radio`, `switch`, `label`, and `form_builder` when the shipped fallback renderer is sufficient and your props stay within the currently documented surface.
- Use `slider` only if your chosen renderer path supports it or a generic wrapper is acceptable.
- Use canonical widget components when your surface is in the Unified UI catalog.
- Use `custom:*` when you are deliberately extending the renderer boundary or building an explicitly example-only shell, not when you need a built-in interactive widget or cataloged component.

## See Also

- [examples/README.md](../../examples/README.md)
- [Canonical widget component examples](../../examples/canonical_widget_components.md)
- [examples/ash_hq_theme_baseline.md](../../examples/ash_hq_theme_baseline.md)
- [UG-0002: Authoring Screens, Elements, and Relationships](./UG-0002-authoring-screens-elements-and-relationships.md)
- [UG-0004: Bindings, Actions, and Forms](./UG-0004-bindings-actions-and-forms.md)
- [UG-0005: LiveView Runtime and Rendering](./UG-0005-liveview-runtime-and-rendering.md)
- [Rendering contract](../../specs/contracts/rendering_contract.md)
