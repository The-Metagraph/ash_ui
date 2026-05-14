# Native Runtime and Examples

`LiveUi` is a directly usable native LiveView widget and runtime library.

## Native Surface

The native package surface includes:

- foundational widgets such as text, labels, inputs, buttons, and content containers
- forms, field groups, and navigation widgets
- advanced data, overlay, display, and operational widgets
- native theme/style helpers through `LiveUi.Theme` and `LiveUi.Style`
- native screen definitions through `LiveUi.Screen`

## Aligned Focused Example Inventory

The package example inventory follows the same widget-focused ids as the root
`examples/` suite. Each aligned entry is a package-specialized live_ui screen
for the same widget-focused example ids that the repository exposes publicly.

Every catalog entry exposes:

- a stable example `id`
- a matching repository `root_example_id`
- a `preview_id` for maintainer tooling
- a `review_artifact` identity used in exports and review workflows
- `families` describing the feature areas the example covers
- `coverage` metadata describing native/canonical/transport expectations on the same widget-focused example ids

## Preview and Inspection

Use the package tooling to review maintained examples:

- `mix live_ui.preview button --format html`
- `mix live_ui.inspect button --format comparison`
- `mix live_ui.export button --format diagnostics`

These commands are designed to keep example review anchored to the package
contract rather than one-off debug helpers. The same widget-focused example ids
stay stable whether you are reviewing direct native rendering, a canonical
review path, or transport diagnostics.
