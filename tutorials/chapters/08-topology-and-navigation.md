# Chapter 8 - Topology and Navigation

## Code For This Chapter

Checkpoint app: `tutorials/code/08-topology-and-navigation/`

Previous checkpoint: `tutorials/code/07-live-diagnostics/`

Supporting examples: `examples/canvas`, `examples/split_pane`, `examples/tree_view`, `examples/viewport`

This chapter extends the diagnostics-enabled services workspace from
[`tutorials/code/07-live-diagnostics/`](../code/07-live-diagnostics/)
with the first structural topology review surfaces.

## What You Build

The checkpoint app at
[`tutorials/code/08-topology-and-navigation/`](../code/08-topology-and-navigation/)
keeps the same two authoritative screens from Chapter 7 and extends the
services workspace with a persisted topology-review panel.

That panel uses:

- `custom:menu` to switch between service maps, dependency paths, and
  incident-scope review stories
- `custom:tabs` to drill into gateway, search, and Core East lanes without
  discarding the larger topology shell
- `custom:tree_view` for the active dependency graph
- `custom:split_pane` to keep structural navigation and large review surfaces
  visible together
- `custom:viewport`, `custom:canvas`, and `custom:scroll_bar` for the active
  lane focus, board copy, and review-lane emphasis

The key design constraint in this chapter is persistence: topology state has to
stay resource-authored and explicit. A lane switch should update the same
`WorkspaceState` record that already powers filters, shared detail copy,
runbook review, and seeded diagnostics instead of sneaking layout state into
the LiveView host.

## Modules and Resources Introduced

- Main checkpoint module:
  [`AshUITutorials.TopologyAndNavigation`](../code/08-topology-and-navigation/lib/ash_ui_tutorials/topology_and_navigation.ex)
- Runtime state resource:
  `AshUITutorials.TopologyAndNavigation.Runtime.WorkspaceState`
- Persisted UI resources:
  `AshUITutorials.TopologyAndNavigation.UiScreen`,
  `AshUITutorials.TopologyAndNavigation.UiElement`, and
  `AshUITutorials.TopologyAndNavigation.UiBinding`
- Existing authoritative screen builders:
  `AshUITutorials.TopologyAndNavigation.Examples.ServicesScreen` and
  `AshUITutorials.TopologyAndNavigation.Examples.IncidentsScreen`
- New authored topology shell resources:
  `AshUITutorials.TopologyAndNavigation.Examples.TopologyReviewPanelElement`,
  `AshUITutorials.TopologyAndNavigation.Examples.TopologySplitPaneElement`,
  `AshUITutorials.TopologyAndNavigation.Examples.TopologyScopeMenuElement`,
  `AshUITutorials.TopologyAndNavigation.Examples.TopologyTabsElement`, and
  `AshUITutorials.TopologyAndNavigation.Examples.TopologyTreeViewElement`
- New authored large-surface review resources:
  `AshUITutorials.TopologyAndNavigation.Examples.TopologyViewportElement`,
  `AshUITutorials.TopologyAndNavigation.Examples.TopologyViewportSupportPanelElement`,
  `AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasElement`, and
  `AshUITutorials.TopologyAndNavigation.Examples.TopologyScrollBarElement`
- New authored topology controls:
  `AshUITutorials.TopologyAndNavigation.Examples.ShowServiceTopologyButtonElement`,
  `AshUITutorials.TopologyAndNavigation.Examples.ShowDependencyTopologyButtonElement`,
  `AshUITutorials.TopologyAndNavigation.Examples.ShowIncidentScopeTopologyButtonElement`,
  `AshUITutorials.TopologyAndNavigation.Examples.FocusGatewayTopologyTabButtonElement`,
  `AshUITutorials.TopologyAndNavigation.Examples.FocusSearchTopologyTabButtonElement`,
  `AshUITutorials.TopologyAndNavigation.Examples.FocusClusterTopologyTabButtonElement`,
  `AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasTrafficPathButtonElement`,
  `AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasBlastRadiusButtonElement`,
  `AshUITutorials.TopologyAndNavigation.Examples.TopologyCommanderScrollButtonElement`,
  `AshUITutorials.TopologyAndNavigation.Examples.TopologyInfrastructureScrollButtonElement`,
  and `AshUITutorials.TopologyAndNavigation.Examples.TopologyHandoffScrollButtonElement`
- LiveView hosts:
  `AshUITutorials.TopologyAndNavigation.Web.ServicesLive` and
  `AshUITutorials.TopologyAndNavigation.Web.IncidentsLive`

The topology path still centers on
`AshUITutorials.TopologyAndNavigation.Runtime.WorkspaceState.update`. Menu,
tab, canvas, and scroll interactions all write explicit state fields like
`topology_scope`, `topology_tab_value`, `topology_tree_model`,
`topology_canvas_layer`, and `topology_scroll_focus`, then let hydration keep
the derived detail copy and review surfaces coherent.

## Run The Checkpoint

From
[`tutorials/code/08-topology-and-navigation/`](../code/08-topology-and-navigation/):

```bash
mix deps.get
mix example.start
```

The default command starts `live_ui` through the Phoenix LiveView host at
`http://127.0.0.1:5000/`. Visit `/` for the services workspace with the
topology panel active and `/incidents` for the incidents workspace that still
includes the Chapter 7 runbook and diagnostics surfaces.

Alternate runtime previews are still available:

```bash
mix example.start elm_ui
mix example.start desktop_ui
```

Those modes keep the same authoritative screen graph and the same explicit
topology state contract, so later chapters can add metrics and capacity
dashboards without rewriting the structural review model introduced here.
