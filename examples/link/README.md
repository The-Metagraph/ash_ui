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

## Expect

Meaningful Interaction Story: inspect the styled navigation affordance and confirm the example calls out that link semantics are still implemented through an explicit custom surface.

Canonical Signal Preview: custom:link surface -> browser navigation; no Ash write is implied by the example itself.

## Validate

`mix run --no-start -e "IO.puts("example/link")"`
