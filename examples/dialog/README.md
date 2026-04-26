# Dialog Example

This standalone Phoenix LiveView app demonstrates the `dialog` example from
the Phase 20 Ash UI suite.

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

Choose one nested decision button and confirm the persisted result closes the modal shell while updating the preview stat.

## Widget Attributes and Properties

Subject widget type: `custom:dialog`

Authored properties:

```elixir
%{
  description: "A composed dialog shell with nested confirm and cancel controls.",
  title: "Confirm handoff",
  class: "ashui-example-dialog-shell"
}
```

Binding contract:

```elixir
%{id: :dialog_open, target: "open", field: :enabled, transform: %{}}
```

Action contract: none. This subject widget is rendered without a dedicated action in the example definition.

Notes: Uses body, actions, and footer slots.

## Expect

Meaningful Interaction Story: confirm or cancel the dialog and verify that the result lands in persisted runtime state rather than living only inside ephemeral shell markup.

Canonical Signal Preview: nested button click -> ExampleState.selected_value and ExampleState.status -> dialog summary copy and preview stat.

Runtime contract:
- Mount path: active viewers can mount the seeded screen, but mutating controls are reserved for operators and admins.
- Refresh path: the mounted shell stays grounded in persisted runtime state, with nested controls driving visible updates through real resource writes.
- Shell state path: Layered examples surface their mounted state through persisted preview and footer copy instead of hidden browser-only state. Dismissal, defer, and escalation outcomes stay visible in persisted status fields owned by nested resources. Nested public controls restore the closed or acknowledged state without leaving the shared Ash HQ shell.

## Validate

`mix run --no-start -e "IO.puts("example/dialog")"`
