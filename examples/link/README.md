# Link Example

This standalone Phoenix LiveView app demonstrates the `link` example from
the Phase 18 Ash UI suite.

It preserves the sibling `unified_ui` directory name while rebuilding the
example through resource-authority screens, related element resources, and the
shared Ash HQ shell.

## Run

From this directory:

`mix deps.get`
`mix phx.server`

The app mounts at `http://127.0.0.1:5000/` by default.

## Try It

Inspect the navigation affordance and confirm the support note explains the custom-surface boundary.

## Expect

Meaningful Interaction Story: inspect the styled navigation affordance and confirm the example calls out that link semantics are still implemented through an explicit custom surface.

Canonical Signal Preview: custom:link surface -> browser navigation; no Ash write is implied by the example itself.

## Validate

`mix run --no-start -e "IO.puts("example/link")"`
