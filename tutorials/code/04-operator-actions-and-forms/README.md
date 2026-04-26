# Chapter 4 - Operator Actions and Forms Checkpoint

This standalone Phoenix LiveView app is the checkpoint for
`tutorials/chapters/04-operator-actions-and-forms.md`.

It extends the filtered services-and-incidents workspace with resource-backed
operator forms for acknowledgement, assignment, and maintenance planning.

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
  [`AshUITutorials.OperatorActionsAndForms`](./lib/ash_ui_tutorials/operator_actions_and_forms.ex)
- Current authoritative screens:
  `tutorial/services-incidents/services` and
  `tutorial/services-incidents/incidents`
- Current story scope:
  services review, incidents review, persisted filters, command navigation,
  resource-backed operator actions, and form feedback inside the shared shell
