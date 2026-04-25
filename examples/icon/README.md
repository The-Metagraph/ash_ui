# Icon Example

This standalone Phoenix LiveView app demonstrates the `icon` example from
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

Review the focused subject panel together with the story and signal surfaces.

## Expect

Meaningful Interaction Story: review the icon inside the shared presentation panel and confirm the fallback renderer exposes both the glyph token and its accessible label.

Canonical Signal Preview: value binding -> ExampleState.display_value -> subject.label.

## Validate

`mix run --no-start -e "IO.puts("example/icon")"`
