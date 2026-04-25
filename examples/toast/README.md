# Toast Example

This standalone Phoenix LiveView app demonstrates the `toast` example from
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

Trigger the nested toast buttons and confirm the message copy and preview surface update through persisted runtime fields.

## Expect

Meaningful Interaction Story: trigger different toast variants and confirm the visible message and status copy update through nested controls instead of hard-coded shell text.

Canonical Signal Preview: nested button click -> ExampleState.current_value and ExampleState.status -> toast body copy and preview stat inside the explicit `custom:toast` shell.

Runtime contract:
- Mount path: active viewers can mount the seeded screen, but mutating controls are reserved for operators and admins.
- Refresh path: the mounted shell stays grounded in persisted runtime state, with nested controls driving visible updates through real resource writes.
- Shell state path: Layered examples surface their mounted state through persisted preview and footer copy instead of hidden browser-only state. Dismissal, defer, and escalation outcomes stay visible in persisted status fields owned by nested resources. Nested public controls restore the closed or acknowledged state without leaving the shared Ash HQ shell.

## Validate

`mix run --no-start -e "IO.puts("example/toast")"`
