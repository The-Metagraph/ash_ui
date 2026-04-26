# Markdown Viewer Example

This standalone Phoenix LiveView app demonstrates the `markdown_viewer` example from
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

Review the bound content and confirm the preview card reflects the same persisted runtime state.

## Widget Attributes and Properties

Subject widget type: `custom:markdown_viewer`

Authored properties:

```elixir
%{
  description: "A document viewer that swaps between authored markdown sources.",
  title: "Review notes",
  class: "ashui-example-markdown-shell"
}
```

Binding contract:

```elixir
%{
  id: :markdown_content,
  target: "content",
  field: :notes,
  transform: %{},
  binding_type: :value
}
```

Action contract: none. This subject widget is rendered without a dedicated action in the example definition.

Notes: Binds markdown content into a renderer-backed document surface.

## Expect

Meaningful Interaction Story: switch the active document and confirm the markdown viewer updates its rendered body from persisted runtime content instead of duplicated static copy.

Canonical Signal Preview: nested button click -> ExampleState.notes -> bound markdown content plus active-document preview.

Runtime contract:
- Mount path: active viewers can mount the seeded screen, but mutating controls are reserved for operators and admins.
- Refresh path: mounted viewers stay current through `ExampleState` notifications and LiveView binding reevaluation, not only by remounting the screen.
- Shell state path: Data-surface examples expose the active dataset through preview and status copy as soon as the seeded screen mounts. Fallback or warning states must stay visible in the shared shell status copy rather than being implied by an empty collection alone. Operator-driven dataset changes and runtime notifications refresh the mounted viewer session through real binding reevaluation.

## Validate

`mix run --no-start -e "IO.puts("example/markdown_viewer")"`
