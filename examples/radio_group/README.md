# Radio Group Example

This standalone Phoenix LiveView app demonstrates the `radio_group` example from
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

Meaningful Interaction Story: pick a radio option and confirm the normalized `radio` subject preserves the directory story while the preview stat reflects the selected value.

Canonical Signal Preview: change -> ExampleState.selected_value -> canonical radio-group markup and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/radio_group")"`
