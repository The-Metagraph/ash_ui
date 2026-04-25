# Image Example

This standalone Phoenix LiveView app demonstrates the `image` example from
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

Meaningful Interaction Story: confirm the image example renders as a real preview surface rather than a generic wrapper while still using the shared Ash HQ shell.

Canonical Signal Preview: static authored props -> rendered image preview; no write signal is emitted.

## Validate

`mix run --no-start -e "IO.puts("example/image")"`
