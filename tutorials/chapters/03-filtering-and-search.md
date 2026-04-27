# Chapter 3 - Filtering and Search

## Code For This Chapter

Checkpoint app: `tutorials/code/03-filtering-and-search/`

Previous checkpoint: `tutorials/code/02-services-and-incidents/`

Supporting examples: `examples/command_palette`, `examples/menu`, `examples/select`, `examples/text_input`

Chapter 2 gave you two real workspaces. Chapter 3 makes them practical. The
goal here is to add query controls, quick navigation, and persistent search
state without retreating into host-owned local UI state.

The checkpoint app at
[`tutorials/code/03-filtering-and-search/`](../code/03-filtering-and-search/)
builds directly on
[`tutorials/code/02-services-and-incidents/`](../code/02-services-and-incidents/)
and keeps the same two screens:

- `tutorial/services-incidents/services`
- `tutorial/services-incidents/incidents`

What changes is the richness of the shared runtime model and the authored
control surfaces wrapped around it.

## What You Are Building

By the end of Chapter 3, the workspace can:

1. filter services by query, status, and healthy-state inclusion
2. filter incidents by severity and escalation state
3. jump between services, incidents, and operator review through a menu
4. stage quick actions through a command palette
5. keep the filtered list, filtered table, summary copy, and shared detail card synchronized through one runtime record

This chapter is really about persistence discipline. Inputs, menus, and quick
commands all write into resource-backed state, and the visible UI rehydrates
from there.

## Start With The Runtime State And Hydration Step

The heart of the chapter is still:

- `AshUITutorials.FilteringAndSearch.Runtime.WorkspaceState`

But the most important function to read first is:

- `AshUITutorials.FilteringAndSearch.hydrate_state/1`

That function takes the raw state fields and computes the shaped data surfaces
the widgets will render. The runtime record now includes fields like:

- `service_query`
- `service_status_filter`
- `include_healthy`
- `incident_severity_filter`
- `incident_escalated_only`
- `command_query`
- `operator_view`

From those values, `hydrate_state/1` derives:

- filtered `services`
- filtered `incidents`
- `current_value`
- `services_status_copy`
- `incidents_status_copy`
- `command_summary`
- synchronized detail fields

This is a very healthy architecture move. Instead of letting each widget invent
its own view of the world, the runtime resource computes one coherent state
model and the authored widgets bind to it.

## Keep The Same Two Screens

Chapter 3 still persists the same pair of screens through:

- `AshUITutorials.FilteringAndSearch.UiScreen`
- `AshUITutorials.FilteringAndSearch.UiElement`
- `AshUITutorials.FilteringAndSearch.UiBinding`

The screen roots are:

- `AshUITutorials.FilteringAndSearch.Examples.ServicesScreen`
- `AshUITutorials.FilteringAndSearch.Examples.IncidentsScreen`

That is worth emphasizing because it keeps the chapter honest. You are not
building a separate filtering demo. You are evolving the real workspace from
Chapter 2.

## The Widget Plan For This Chapter

Chapter 3 adds a richer control layer:

| Widget | Where it goes | Why it belongs there |
|---|---|---|
| `custom:menu` | Top of both workspaces | Gives quick jumps between services, incidents, and operator review |
| `custom:command_palette` | Near the top of both workspaces | Creates an explicit command surface for staged navigation and focus actions |
| `custom:field_group` | Services filters and incidents filters | Groups related filter controls into readable blocks |
| `form_field` | Around each individual filter control | Keeps labels, help text, and controls organized |
| `input` | Query field and command query input | Handles free-form search terms |
| `select` | Service status filter | Best fit for one-of-many service state narrowing |
| `checkbox` | Include healthy services toggle | Best fit for a boolean inclusion rule |
| `radio` | Incident severity filter | Best fit for explicit severity mode selection |
| `switch` | Escalated-only incident filter | Best fit for a simple operational toggle |
| `list` | Services data surface | Shows filtered services in a compact review lane |
| `table` | Incidents data surface | Shows filtered incidents in a structured row set |
| `card`, `badge`, `text` | Shared detail and status areas | Keep the shared review state readable |

This chapter is where the workspace starts to feel interactive without becoming
messy.

## Build The Services Workspace Controls

The top-level panel is:

- `AshUITutorials.FilteringAndSearch.Examples.ServicesWorkspacePanelElement`

Its key child surfaces are:

- `AshUITutorials.FilteringAndSearch.Examples.WorkspaceMenuElement`
- `AshUITutorials.FilteringAndSearch.Examples.CommandPaletteElement`
- `AshUITutorials.FilteringAndSearch.Examples.ServicesFiltersGroupElement`
- `AshUITutorials.FilteringAndSearch.Examples.ServicesListElement`
- `AshUITutorials.FilteringAndSearch.Examples.SharedDetailCardElement`

That sequence matters:

1. decide where you are in the workspace
2. stage a quick command if needed
3. refine the visible service set
4. review the filtered list
5. keep one shared detail story visible

### Menu Surface

Use `AshUITutorials.FilteringAndSearch.Examples.WorkspaceMenuElement` as
`custom:menu`. It contains:

- `AshUITutorials.FilteringAndSearch.Examples.ShowServicesButtonElement`
- `AshUITutorials.FilteringAndSearch.Examples.ShowIncidentsButtonElement`
- `AshUITutorials.FilteringAndSearch.Examples.ShowOperatorViewButtonElement`
- `AshUITutorials.FilteringAndSearch.Examples.WorkspaceSelectionSummaryElement`

That gives the workspace a durable navigation surface without forcing a route
change every time the operator changes context.

### Command Palette

Use `AshUITutorials.FilteringAndSearch.Examples.CommandPaletteElement` as the
explicit quick-command surface. It contains:

- `AshUITutorials.FilteringAndSearch.Examples.CommandPaletteInputElement`
- `AshUITutorials.FilteringAndSearch.Examples.CommandFocusGatewayButtonElement`
- `AshUITutorials.FilteringAndSearch.Examples.CommandFocusIncidentButtonElement`
- `AshUITutorials.FilteringAndSearch.Examples.CommandOpenOperatorViewButtonElement`
- `AshUITutorials.FilteringAndSearch.Examples.CommandSummaryTextElement`

This is a good tutorial move because it keeps the command system honest. The
command palette is not magic. It is just another authored resource surface with
explicit buttons, input, and bound summary copy.

### Services Filter Group

`AshUITutorials.FilteringAndSearch.Examples.ServicesFiltersGroupElement` is the
main services filter cluster. It groups three field surfaces:

- `AshUITutorials.FilteringAndSearch.Examples.ServicesQueryFieldElement`
- `AshUITutorials.FilteringAndSearch.Examples.ServiceStatusFieldElement`
- `AshUITutorials.FilteringAndSearch.Examples.IncludeHealthyFieldElement`

Those fields wrap the actual controls:

- `AshUITutorials.FilteringAndSearch.Examples.ServicesQueryInputElement`
- `AshUITutorials.FilteringAndSearch.Examples.ServiceStatusSelectElement`
- `AshUITutorials.FilteringAndSearch.Examples.IncludeHealthyCheckboxElement`

This is a nice architectural pattern to keep using. Let the field resource own
label, help text, and layout. Let the input resource own the actual value entry.

## Build The Incidents Workspace Controls

The incidents side mirrors the same high-level structure through:

- `AshUITutorials.FilteringAndSearch.Examples.IncidentsWorkspacePanelElement`

It keeps the shared menu and command palette, then swaps in:

- `AshUITutorials.FilteringAndSearch.Examples.IncidentsFiltersGroupElement`
- `AshUITutorials.FilteringAndSearch.Examples.IncidentsTableElement`

The incident filter group contains:

- `AshUITutorials.FilteringAndSearch.Examples.IncidentSeverityFieldElement`
- `AshUITutorials.FilteringAndSearch.Examples.IncidentEscalatedFieldElement`

Those fields then wrap:

- `AshUITutorials.FilteringAndSearch.Examples.IncidentSeverityRadioElement`
- `AshUITutorials.FilteringAndSearch.Examples.IncidentEscalatedSwitchElement`

This is why the chapter needs both screens. Services and incidents want similar
navigation, but they want different filter widgets because the underlying
review task is different.

## Bind Every Control Back Into Shared State

The most important discipline in Chapter 3 is that every control writes back
into `AshUITutorials.FilteringAndSearch.Runtime.WorkspaceState`.

Examples:

- `ServicesQueryInputElement` binds `service_query`
- `ServiceStatusSelectElement` binds `service_status_filter`
- `IncludeHealthyCheckboxElement` binds `include_healthy`
- `IncidentSeverityRadioElement` binds `incident_severity_filter`
- `IncidentEscalatedSwitchElement` binds `incident_escalated_only`
- `CommandPaletteInputElement` binds `command_query`

From there, `hydrate_state/1` recomputes the visible surfaces and the bindings
push the updated values back into:

- `ServicesListElement`
- `IncidentsTableElement`
- `SharedDetailCardElement`
- status and summary text surfaces

That is the full loop:

1. user changes a control
2. runtime state updates
3. derived workspace state rehydrates
4. widgets redraw from bindings

## Use Actions To Stage Fast Review Paths

Buttons in the menu and command palette can also rewrite the workspace quickly.
For example:

- `AshUITutorials.FilteringAndSearch.Examples.CommandFocusGatewayButtonElement`
- `AshUITutorials.FilteringAndSearch.Examples.CommandFocusIncidentButtonElement`
- `AshUITutorials.FilteringAndSearch.Examples.CommandOpenOperatorViewButtonElement`

These actions are useful because they show that authored commands do not bypass
the state model. They simply update the same runtime record in a more opinionated
way.

That makes the command palette feel like part of the application instead of a
separate trick widget.

## Persist And Mount The Evolved Workspace

The persistence story stays familiar:

- `AshUITutorials.FilteringAndSearch.seed!/1` creates the runtime record
- authority persists `AshUITutorials.FilteringAndSearch.Examples.ServicesScreen`
- authority persists `AshUITutorials.FilteringAndSearch.Examples.IncidentsScreen`

The host surfaces remain:

- `AshUITutorials.FilteringAndSearch.Web.ServicesLive`
- `AshUITutorials.FilteringAndSearch.Web.IncidentsLive`

That is exactly what you want. The chapter becomes richer, but the host still
does not need to grow into a local-state controller.

## Modules And Resources You Will Touch

To stay grounded while reading the checkpoint code, keep these names in view:

- source file: [`../code/03-filtering-and-search/lib/ash_ui_tutorials/filtering_and_search.ex`](../code/03-filtering-and-search/lib/ash_ui_tutorials/filtering_and_search.ex)
- main checkpoint module: `AshUITutorials.FilteringAndSearch`
- runtime state resource: `AshUITutorials.FilteringAndSearch.Runtime.WorkspaceState`
- persisted UI resources: `AshUITutorials.FilteringAndSearch.UiScreen`, `AshUITutorials.FilteringAndSearch.UiElement`, `AshUITutorials.FilteringAndSearch.UiBinding`
- authoritative screen builders: `AshUITutorials.FilteringAndSearch.Examples.ServicesScreen`, `AshUITutorials.FilteringAndSearch.Examples.IncidentsScreen`
- key control surfaces: `AshUITutorials.FilteringAndSearch.Examples.WorkspaceMenuElement`, `AshUITutorials.FilteringAndSearch.Examples.CommandPaletteElement`, `AshUITutorials.FilteringAndSearch.Examples.ServicesFiltersGroupElement`, `AshUITutorials.FilteringAndSearch.Examples.IncidentsFiltersGroupElement`
- LiveView hosts: `AshUITutorials.FilteringAndSearch.Web.ServicesLive`, `AshUITutorials.FilteringAndSearch.Web.IncidentsLive`

## Run The Checkpoint

From
[`tutorials/code/03-filtering-and-search/`](../code/03-filtering-and-search/):

```bash
mix deps.get
mix example.start
```

The default command starts `live_ui` through the Phoenix LiveView host at
`http://127.0.0.1:5000/`.

Use:

- `/` for the services workspace
- `/incidents` for the incidents workspace

Alternate runtime previews are still available:

```bash
mix example.start elm_ui
mix example.start desktop_ui
```

All of them render the same authoritative screens and the same shared runtime
model.

## What To Carry Into Chapter 4

Chapter 3 proves that filtering and quick navigation can live inside the same
resource-backed state model as the list, table, and shared detail surface.

Chapter 4 builds directly on that foundation by adding the first real operator
write workflows through authored forms and resource-backed submit actions.
