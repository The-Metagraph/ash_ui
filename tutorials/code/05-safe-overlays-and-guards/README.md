# Chapter 5 - Safe Overlays and Guards Checkpoint

This standalone Phoenix LiveView app is the checkpoint for
`tutorials/chapters/05-safe-overlays-and-guards.md`.

It extends the filtered services-and-incidents workspace with resource-backed
guard rails for resolve, restart, silence, and destructive note-discard flows.

## Run

From this directory:

```bash
mix deps.get
mix example.start
```

`mix example.start` starts the default `live_ui` renderer inside the Phoenix
LiveView host at `http://127.0.0.1:5000/`.

To preview another runtime, pass its name as the first argument:

```bash
mix example.start live_ui
mix example.start elm_ui
mix example.start desktop_ui
```

If the server is already running, the same runtime switch can be reviewed by
visiting `/?runtime=live_ui`, `/?runtime=elm_ui`, or
`/?runtime=desktop_ui`.

## Current Surface

- Main module:
  [`AshUITutorials.SafeOverlaysAndGuards`](./lib/ash_ui_tutorials/safe_overlays_and_guards.ex)
- Current authoritative screens:
  `tutorial/services-incidents/services` and
  `tutorial/services-incidents/incidents`
- Current story scope:
  services review, incidents review, persisted filters, command navigation,
  resource-backed operator actions, guarded overlays, confirmation dialogs, and
  toast feedback inside the shared shell
