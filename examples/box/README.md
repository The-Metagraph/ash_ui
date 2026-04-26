# Box Example

This standalone Phoenix LiveView app demonstrates the `box` example from
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

Review the focused subject panel together with the story and signal surfaces.

## Widget Attributes and Properties

Subject widget type: `card`

Authored properties:

```elixir
%{title: "Box shell", class: "ashui-example-box"}
```

Binding contract: none. This subject widget is rendered without a dedicated binding in the example definition.

Action contract: none. This subject widget is rendered without a dedicated action in the example definition.

Notes: Uses a composed native container pattern.

## Expect

Meaningful Interaction Story: review the empty container shell and confirm the example is explicit that box semantics are expressed through composed card/container structure.

Canonical Signal Preview: composed native container review pattern -> `card` shell plus support note.

## Validate

`mix run --no-start -e "IO.puts("example/box")"`
