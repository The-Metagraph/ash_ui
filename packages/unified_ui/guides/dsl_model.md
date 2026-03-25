# UnifiedUi DSL Model

`UnifiedUi` is the authored DSL for the ecosystem. It is where canonical UI
intent is declared before being compiled into `UnifiedIUR`.

## Sections

Every authored module is organized around top-level sections:

- `identity`: stable authored identity, traceability, and package-facing metadata
- `composition`: canonical widgets, layouts, layers, viewports, and canvas constructs
- `themes`: reusable theme definitions, palette entries, semantic roles, tokens, and component styles
- `signals`: canonical bindings and interaction descriptors

The package treats these sections as the only supported authored extension
surface. Runtime-local concepts do not belong here.

## Construct Families

The authored composition model is organized around construct families:

- foundational visuals such as text, label, image, icon, button, link, separator, and spacer
- input and form primitives such as text input, toggle, select, field, field group, and form builder
- navigation widgets such as menu, tabs, and command palette
- data widgets such as table, tree view, markdown viewer, and log viewer
- feedback widgets such as gauge and charts
- advanced operational widgets such as stream widgets, monitors, and dashboards
- display systems such as layout containers, overlays, viewports, split panes, scroll bars, and canvas

The maintained examples in `UnifiedUi.Examples` are part of the package
contract because they demonstrate how these families are authored together.

## Identity and Placement Invariants

The DSL enforces authored invariants at compile time:

- every authored module must declare `identity`
- `identity.id` and `composition.root` must both exist and must differ
- `identity.authored_ref` must end in `identity.id`
- leaf nodes cannot contain authored children
- overlay, viewport, canvas, and field placement rules are validated when authored modules compile

These constraints make the compiler output more predictable and make package
reviews easier because malformed authored shapes fail early.

## Examples as Reference Modules

The package ships maintained examples for the major authored scenarios:

- `foundational_screen`
- `profile_form`
- `overlay_workspace`
- `operations_dashboard`
- `themed_signal_workspace`

These modules are intentionally stable reference points for docs, inspection,
validation, and parity review.
