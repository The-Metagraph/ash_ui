# Link Example

This standalone Phoenix LiveView app demonstrates the `link` example from
the Phase 18 Ash UI suite.

It preserves the sibling `unified_ui` directory name while rebuilding the
example through resource-authority screens, related element resources, and the
shared Ash HQ shell.

## Run

From this directory:

```bash
mix deps.get
mix example.start
```

`mix example.start` starts the default `live_ui` renderer, shown through the
example's Phoenix LiveView host at `http://127.0.0.1:5000/`.

To preview another runtime, pass its name as the first argument:

```bash
mix example.start live_ui
mix example.start elm_ui
mix example.start desktop_ui
```

If the server is already running, the same runtime switch can be reviewed by
visiting `/?runtime=live_ui`, `/?runtime=elm_ui`, or
`/?runtime=desktop_ui`.

## Try It

Inspect the navigation affordance and confirm the support note explains the custom-surface boundary.

## Widget Attributes and Properties

Subject widget type: `custom:link`

Authored properties:

```elixir
%{
  label: "Open Ash HQ",
  target: "_blank",
  rel: "noreferrer",
  class: "ashui-example-link",
  href: "https://www.ash-hq.org/"
}
```

Binding contract: none. This subject widget is rendered without a dedicated binding in the example definition.

Action contract: none. This subject widget is rendered without a dedicated action in the example definition.

Notes: Preserves the sibling directory name while using a custom surface.

## Expect

Meaningful Interaction Story: inspect the styled navigation affordance and confirm the example calls out that link semantics are still implemented through an explicit custom surface.

Canonical Signal Preview: custom:link surface -> browser navigation; no Ash write is implied by the example itself.

## Validate

`mix run --no-start -e "IO.puts("example/link")"`
