# Chapter 3 - Filtering and Search

## Code For This Chapter

Checkpoint app: `tutorials/code/03-filtering-and-search/`

Previous checkpoint: `tutorials/code/02-services-and-incidents/`

Supporting examples: `examples/command_palette`, `examples/menu`, `examples/select`, `examples/text_input`

This chapter adds persisted filters, quick search, and command-based navigation
to the services-and-incidents workspace from
[`tutorials/code/02-services-and-incidents/`](../code/02-services-and-incidents/).

## What You Build

The checkpoint app at
[`tutorials/code/03-filtering-and-search/`](../code/03-filtering-and-search/)
keeps the same two authoritative screens from Chapter 2:

- `tutorial/services-incidents/services`
- `tutorial/services-incidents/incidents`

Instead of introducing host-owned local state, it extends the shared runtime
record so query inputs, select/radio controls, and quick-jump commands all
write to persisted tutorial state and then hydrate the visible `list`,
`table`, and detail props back through bindings.

## Modules and Resources Introduced

- Main checkpoint module:
  [`AshUITutorials.FilteringAndSearch`](../code/03-filtering-and-search/lib/ash_ui_tutorials/filtering_and_search.ex)
- Runtime state resource:
  `AshUITutorials.FilteringAndSearch.Runtime.WorkspaceState`
- Persisted UI resources:
  `AshUITutorials.FilteringAndSearch.UiScreen`,
  `AshUITutorials.FilteringAndSearch.UiElement`, and
  `AshUITutorials.FilteringAndSearch.UiBinding`
- Authoritative screen builders:
  `AshUITutorials.FilteringAndSearch.Examples.ServicesScreen` and
  `AshUITutorials.FilteringAndSearch.Examples.IncidentsScreen`
- New authored control surfaces:
  `AshUITutorials.FilteringAndSearch.Examples.WorkspaceMenuElement`,
  `AshUITutorials.FilteringAndSearch.Examples.CommandPaletteElement`,
  `AshUITutorials.FilteringAndSearch.Examples.ServicesFiltersGroupElement`, and
  `AshUITutorials.FilteringAndSearch.Examples.IncidentsFiltersGroupElement`
- LiveView hosts:
  `AshUITutorials.FilteringAndSearch.Web.ServicesLive` and
  `AshUITutorials.FilteringAndSearch.Web.IncidentsLive`

The key code path is
`AshUITutorials.FilteringAndSearch.hydrate_state/1`. Every filter input writes
back to `Runtime.WorkspaceState`, and the resource hook recomputes the visible
services list, incidents table, workspace copy, and command summary before the
screen re-renders.

## Run The Checkpoint

From
[`tutorials/code/03-filtering-and-search/`](../code/03-filtering-and-search/):

```bash
mix deps.get
mix example.start
```

The default command again starts `live_ui` through the Phoenix LiveView host at
`http://127.0.0.1:5000/`. Visit `/` for the services workspace and
`/incidents` for the incidents workspace.

Alternate runtime previews remain available when you need them:

```bash
mix example.start elm_ui
mix example.start desktop_ui
```

Both modes render the same authoritative screens and shared runtime state, so
the tutorial can compare renderer output later without changing the persisted
resource model introduced here.
