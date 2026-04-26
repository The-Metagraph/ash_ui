# Chapter 2 - Services and Incidents

## Code For This Chapter

Checkpoint app: `tutorials/code/02-services-and-incidents/`

Previous checkpoint: `tutorials/code/01-project-shell/`

Supporting examples: `examples/list`, `examples/status`, `examples/table`, `examples/tabs`

This chapter adds the first services and incidents workspace, including the
list and detail surfaces that make the tutorial feel like a real operations
console.

## What You Build

The checkpoint app at
[`tutorials/code/02-services-and-incidents/`](../code/02-services-and-incidents/)
extends the shell from
[`tutorials/code/01-project-shell/`](../code/01-project-shell/) into the first
multi-screen operator workspace.

Instead of collapsing everything into one monolithic screen resource, the app
persists two authoritative screens:

- `tutorial/services-incidents/services`
- `tutorial/services-incidents/incidents`

Those screens share one runtime state resource so a focus action on the
services list or incidents table updates the same detail card and status copy.

## Modules and Resources Introduced

- Main checkpoint module:
  [`AshUITutorials.ServicesAndIncidents`](../code/02-services-and-incidents/lib/ash_ui_tutorials/services_and_incidents.ex)
- Runtime state resource:
  `AshUITutorials.ServicesAndIncidents.Runtime.WorkspaceState`
- Persisted UI resources:
  `AshUITutorials.ServicesAndIncidents.UiScreen`,
  `AshUITutorials.ServicesAndIncidents.UiElement`, and
  `AshUITutorials.ServicesAndIncidents.UiBinding`
- Authoritative screen builders:
  `AshUITutorials.ServicesAndIncidents.Examples.ServicesScreen` and
  `AshUITutorials.ServicesAndIncidents.Examples.IncidentsScreen`
- LiveView hosts:
  `AshUITutorials.ServicesAndIncidents.Web.ServicesLive` and
  `AshUITutorials.ServicesAndIncidents.Web.IncidentsLive`

The new workspace teaches `list`, `table`, `tabs`, `status`, and the same
layout primitives from Chapter 1, but now the seeded data comes from the
shared Phase 23 baseline for services and incidents rather than static copy.

## Run The Checkpoint

From
[`tutorials/code/02-services-and-incidents/`](../code/02-services-and-incidents/):

```bash
mix deps.get
mix example.start
```

The default command again starts `live_ui` through the Phoenix LiveView host at
`http://127.0.0.1:5000/`. Visit `/` for the services workspace and
`/incidents` for the incidents workspace.

Alternate runtime previews are still available, but secondary:

```bash
mix example.start elm_ui
mix example.start desktop_ui
```

Both modes render the same authoritative screens and shared runtime state, so
the tutorial can compare renderer output later without changing the persisted
resource model introduced here.
