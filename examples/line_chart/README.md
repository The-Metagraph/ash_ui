# Line Chart Example

This standalone Phoenix LiveView app demonstrates the `line_chart` example from
the Phase 20 Ash UI suite.

It preserves the sibling `unified_ui` directory name while rebuilding the
example through resource-authority screens, related element resources, and the
shared Ash HQ shell.

## Run

From this directory:

`mix deps.get`
`mix phx.server`

The app mounts at `http://127.0.0.1:5000/` by default.

## Try It

Swap the active series and confirm the chart surface redraws from persisted runtime points.

## Expect

Meaningful Interaction Story: switch the active trend series and confirm the line-chart surface redraws its points from persisted runtime data.

Canonical Signal Preview: nested button click -> ExampleState.series -> bound line series plus preview label.

## Validate

`mix run --no-start -e "IO.puts("example/line_chart")"`
