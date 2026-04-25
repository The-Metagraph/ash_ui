# Overlay Example

This standalone Phoenix LiveView app demonstrates the `overlay` example from
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

Open and dismiss the layered surface with the nested action row and confirm the preview state follows the persisted runtime value.

## Expect

Meaningful Interaction Story: open the overlay, inspect the layered body copy, and dismiss it again without losing the shared Ash HQ shell around the example.

Canonical Signal Preview: nested button click -> ExampleState.enabled -> overlay visibility and status copy inside the explicit `custom:overlay` shell.

Runtime contract:
- Mount path: active viewers can mount the seeded screen, but mutating controls are reserved for operators and admins.
- Refresh path: the mounted shell stays grounded in persisted runtime state, with nested controls driving visible updates through real resource writes.
- Shell state path: Layered examples surface their mounted state through persisted preview and footer copy instead of hidden browser-only state. Dismissal, defer, and escalation outcomes stay visible in persisted status fields owned by nested resources. Nested public controls restore the closed or acknowledged state without leaving the shared Ash HQ shell.

## Validate

`mix run --no-start -e "IO.puts("example/overlay")"`
