# Spacer Example

This standalone Phoenix LiveView app demonstrates the `spacer` example from
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

Meaningful Interaction Story: verify the authored spacer creates intentional breathing room inside the shared review shell without introducing fake container semantics.

Canonical Signal Preview: static spacer props -> rendered layout gap; no write signal is emitted.

## Validate

`mix run --no-start -e "IO.puts("example/spacer")"`
