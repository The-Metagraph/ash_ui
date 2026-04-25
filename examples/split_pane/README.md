# Split Pane Example

This standalone Phoenix LiveView app demonstrates the `split_pane` example from
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

Trigger the nested action controls and confirm the active pane or layer updates while the larger display surface remains an explicit custom shell.

## Expect

Meaningful Interaction Story: move emphasis between split panes and confirm the active pane copy changes through nested public actions instead of screen-local imperative layout code.

Canonical Signal Preview: nested button click -> ExampleState.selected_value -> secondary pane copy, status text, and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/split_pane")"`
