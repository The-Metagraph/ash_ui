# Chapter 2 - Services and Incidents

## Code For This Chapter

Checkpoint app: `tutorials/code/02-services-and-incidents/`

Previous checkpoint: `tutorials/code/01-project-shell/`

Supporting examples: `examples/list`, `examples/status`, `examples/table`, `examples/tabs`

Now that Chapter 1 has a shared shell, Chapter 2 gives that shell a real
workspace. Instead of one home panel, you will build two authoritative screens
that share one runtime state record:

- `tutorial/services-incidents/services`
- `tutorial/services-incidents/incidents`

That is the big architectural step in this chapter. The user sees separate
services and incidents workspaces, but both screens still talk to the same
`WorkspaceState` resource.

## What You Are Building

The checkpoint app at
[`tutorials/code/02-services-and-incidents/`](../code/02-services-and-incidents/)
extends the shell from
[`tutorials/code/01-project-shell/`](../code/01-project-shell/) into the first
multi-screen operator workspace.

The finished checkpoint does four important things:

1. introduces a services screen with a list surface
2. introduces an incidents screen with a table surface
3. keeps both screens synchronized through one shared detail card model
4. proves that separate screens can still feel like one application when they share runtime state

## Start With The Runtime State

The first change from Chapter 1 happens in the runtime resource:

- `AshUITutorials.ServicesAndIncidents.Runtime.WorkspaceState`

This chapter no longer needs only summary copy. It needs workspace data:

- `services`
- `incidents`
- `selected_value`
- `detail_title`
- `detail_summary`
- `detail_status`
- `services_status_copy`
- `incidents_status_copy`
- `incident_focus_title`
- `incident_focus_summary`

That tells you what the application is trying to do. The runtime resource owns:

1. the current workspace focus
2. the data shown in the list and table
3. the shared detail card content
4. the status copy that explains what the operator is reviewing

The important shift is that the detail card is no longer tied to one screen. It
is shared state that both screens can rewrite.

## Keep Two Screens, Not One Giant Screen

Chapter 2 introduces two screen roots:

- `AshUITutorials.ServicesAndIncidents.Examples.ServicesScreen`
- `AshUITutorials.ServicesAndIncidents.Examples.IncidentsScreen`

Both are persisted through:

- `AshUITutorials.ServicesAndIncidents.UiScreen`
- `AshUITutorials.ServicesAndIncidents.UiElement`
- `AshUITutorials.ServicesAndIncidents.UiBinding`

This is a good moment to be disciplined. It would be tempting to pack services
and incidents into one giant screen with toggles. Do not do that here. The
tutorial is trying to show that screen boundaries can stay explicit while the
runtime story stays shared.

## The Widget Plan For This Chapter

The new widgets in Chapter 2 are straightforward:

| Widget | Where it goes | Why it belongs there |
|---|---|---|
| `custom:tabs` | Top of each workspace panel | Shows that services and incidents are separate workspaces inside one application story |
| `list` | Services screen body | Best fit for a short service catalog with titles and summaries |
| `table` | Incidents screen body | Best fit for structured incident rows with severity, service, state, and owner |
| `row` | Services and incidents action rows | Holds focus buttons that rewrite the shared detail card |
| `button` | Tabs and focus actions | Lets the operator switch workspace intent or drill into one item |
| `card` | Workspace panel and shared detail area | Keeps each screen organized and gives the detail surface a durable home |
| `badge` | Shared detail status | Makes the focused service or incident state easy to scan |
| `text` | Active tab copy, detail title, detail summary, status copy, story copy, signal copy | Carries the workspace narrative |

Chapter 2 keeps the widget vocabulary modest on purpose. The new lesson is
screen organization, not control density.

## Build The Services Screen

The services screen root is `AshUITutorials.ServicesAndIncidents.Examples.ServicesScreen`.
Its top-level panel is:

- `AshUITutorials.ServicesAndIncidents.Examples.ServicesPanelElement`

That panel organizes the services workspace into five child areas:

- `services_tabs`
- `services_lists`
- `action_rows`
- `detail_cards`
- `status_texts`

This gives the page a clean rhythm:

1. identify the current workspace
2. show the data surface
3. offer a couple of focus actions
4. show the shared detail card
5. explain the current review state

### Services Workspace Widgets

Inside the services panel, place:

- `AshUITutorials.ServicesAndIncidents.Examples.ServicesTabsElement` as `custom:tabs`
- `AshUITutorials.ServicesAndIncidents.Examples.ServicesListElement` as `list`
- `AshUITutorials.ServicesAndIncidents.Examples.ServicesActionRowElement` as `row`
- `AshUITutorials.ServicesAndIncidents.Examples.ServicesDetailCardElement` as `card`
- `AshUITutorials.ServicesAndIncidents.Examples.ServicesStatusTextElement` as `text`

Then fill the tabs with:

- `AshUITutorials.ServicesAndIncidents.Examples.ServicesTabButtonElement`
- `AshUITutorials.ServicesAndIncidents.Examples.IncidentsTabButtonElement`
- `AshUITutorials.ServicesAndIncidents.Examples.ServicesActivePanelElement`

The list surface binds the `services` collection, while the detail card binds:

- `detail_status`
- `detail_title`
- `detail_summary`

That card is the key idea. The services list is not trying to render every
detail inline. It pushes focus into a separate shared review surface.

## Build The Incidents Screen

The incidents screen root is
`AshUITutorials.ServicesAndIncidents.Examples.IncidentsScreen`. Its matching
panel is:

- `AshUITutorials.ServicesAndIncidents.Examples.IncidentsPanelElement`

It mirrors the structure of the services screen so the application still feels
coherent, but it swaps the main data surface:

- `custom:tabs` still identifies workspace focus
- `table` replaces `list` because incident rows have more fields
- `row` still holds quick focus actions
- `card` still shows the shared detail surface
- `text` still carries status and explanation copy

The important authored widgets are:

- `AshUITutorials.ServicesAndIncidents.Examples.IncidentsTabsElement`
- `AshUITutorials.ServicesAndIncidents.Examples.IncidentsTableElement`
- `AshUITutorials.ServicesAndIncidents.Examples.IncidentsActionRowElement`
- `AshUITutorials.ServicesAndIncidents.Examples.IncidentsDetailCardElement`
- `AshUITutorials.ServicesAndIncidents.Examples.IncidentsStatusTextElement`

This is why Chapter 2 matters. The screens are different enough to justify
their own routes, but similar enough to read as one consistent application.

## Use Actions To Rewrite Shared Focus

Each screen includes a small set of focus buttons:

- `AshUITutorials.ServicesAndIncidents.Examples.FocusGatewayButtonElement`
- `AshUITutorials.ServicesAndIncidents.Examples.FocusBillingButtonElement`
- `AshUITutorials.ServicesAndIncidents.Examples.FocusGatewayLatencyButtonElement`
- `AshUITutorials.ServicesAndIncidents.Examples.FocusSearchLagButtonElement`

Those buttons do not mutate isolated host state. They update the shared
`WorkspaceState` record and rewrite:

- `detail_title`
- `detail_summary`
- `detail_status`
- `status`

That is the signal worth noticing in this chapter:

1. click a button on one screen
2. update the shared runtime resource
3. rehydrate the shared detail surface through bindings

Because both screens use the same pattern, the application starts to feel like
one workspace with multiple viewpoints.

## Persist And Mount Both Screens

`AshUITutorials.ServicesAndIncidents.seed!/1` persists two screens through
authority:

- one `Authority.create(...)` call for `AshUITutorials.ServicesAndIncidents.Examples.ServicesScreen`
- one `Authority.create(...)` call for `AshUITutorials.ServicesAndIncidents.Examples.IncidentsScreen`

The LiveView hosts stay small:

- `AshUITutorials.ServicesAndIncidents.Web.ServicesLive`
- `AshUITutorials.ServicesAndIncidents.Web.IncidentsLive`

Each host seeds the app, mounts one screen by name, wires handlers, and lets
the authoritative screen graph do the real UI work.

That is exactly what you want. The host should route and mount. The resources
should define the application surfaces.

## Modules And Resources You Will Touch

Chapter 2 is still concentrated in one main source file:

- source file: [`../code/02-services-and-incidents/lib/ash_ui_tutorials/services_and_incidents.ex`](../code/02-services-and-incidents/lib/ash_ui_tutorials/services_and_incidents.ex)
- main checkpoint module: `AshUITutorials.ServicesAndIncidents`
- runtime state resource: `AshUITutorials.ServicesAndIncidents.Runtime.WorkspaceState`
- persisted UI resources: `AshUITutorials.ServicesAndIncidents.UiScreen`, `AshUITutorials.ServicesAndIncidents.UiElement`, `AshUITutorials.ServicesAndIncidents.UiBinding`
- authoritative screen builders: `AshUITutorials.ServicesAndIncidents.Examples.ServicesScreen`, `AshUITutorials.ServicesAndIncidents.Examples.IncidentsScreen`
- LiveView hosts: `AshUITutorials.ServicesAndIncidents.Web.ServicesLive`, `AshUITutorials.ServicesAndIncidents.Web.IncidentsLive`

## Run The Checkpoint

From
[`tutorials/code/02-services-and-incidents/`](../code/02-services-and-incidents/):

```bash
mix deps.get
mix example.start
```

The default command starts `live_ui` through the Phoenix LiveView host at
`http://127.0.0.1:5000/`.

Use:

- `/` for the services workspace
- `/incidents` for the incidents workspace

You can still preview alternate runtimes when useful:

```bash
mix example.start elm_ui
mix example.start desktop_ui
```

All runtime previews are using the same two persisted screen definitions and
the same shared runtime state.

## What To Carry Into Chapter 3

Chapter 2 teaches one idea really well: separate screens do not need separate
application state.

Chapter 3 keeps these same two screens, but it makes them much more useful by
adding persisted filters, quick search, and command-style navigation on top of
the shared workspace model.
