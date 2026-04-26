# Grid Example

This standalone Phoenix LiveView app demonstrates the `grid` example from
the Phase 19 Ash UI suite.

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

Review the rendered lane order and confirm the resource-authored structure stays visible in the mounted shell.

## Widget Attributes and Properties

Subject widget type: `grid`

Authored properties:

```elixir
%{columns: 2, class: "ashui-example-grid-layout", spacing: 18}
```

Binding contract: none. This subject widget is rendered without a dedicated binding in the example definition.

Action contract: none. This subject widget is rendered without a dedicated action in the example definition.

Notes: Uses the maintained public `grid` widget directly.

## Expect

Meaningful Interaction Story: review the multi-tile structure and confirm the grid example keeps tile ordering, spacing, and grouping in related element resources.

Canonical Signal Preview: relationship order + grid props -> rendered tile matrix inside the maintained grid widget.

## Validate

`mix run --no-start -e "IO.puts("example/grid")"`
