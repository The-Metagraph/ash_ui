# Chapter 3 - Filtering and Search Checkpoint

This standalone Phoenix LiveView app is the checkpoint for
`tutorials/chapters/03-filtering-and-search.md`.

It extends the services-and-incidents workspace with persisted filters, command
search, and quick-jump navigation that all write back to the shared runtime
state resource.

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

## Chapter Focus

- Main module:
  [`AshUITutorials.FilteringAndSearch`](./lib/ash_ui_tutorials/filtering_and_search.ex)
- Current authoritative screens:
  `tutorial/services-incidents/services` and
  `tutorial/services-incidents/incidents`
- Current story scope:
  persisted service filters, incident filters, command-driven quick jumps, and
  the same shared detail surface introduced in Chapter 2
