# Scroll Bar Example

This standalone Phoenix LiveView app demonstrates the `scroll_bar` example from
the Phase 19 Ash UI suite.

It preserves the sibling `unified_ui` directory name while rebuilding the
example through resource-authority screens, related element resources, and the
shared Ash HQ shell.

## Run

From this directory:

`mix deps.get`
`mix phx.server`

The app mounts at `http://127.0.0.1:5000/` by default.

## Try It

Use the nested focus controls and confirm the larger display shell updates without moving state ownership onto the outer custom surface.

## Expect

Meaningful Interaction Story: change the scroll focus through nested public buttons and confirm the thumb label plus status copy update without turning `scroll_bar` into an admitted public widget.

Canonical Signal Preview: nested button click -> ExampleState.selected_value -> thumb label binding, body copy, and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/scroll_bar")"`
