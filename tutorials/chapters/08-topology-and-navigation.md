# Chapter 8 - Topology and Navigation

## Code For This Chapter

Checkpoint app: `tutorials/code/08-topology-and-navigation/`

Previous checkpoint: `tutorials/code/07-live-diagnostics/`

Supporting examples: `examples/canvas`, `examples/split_pane`, `examples/tree_view`, `examples/viewport`

Chapter 7 deepened the incidents workspace. Chapter 8 turns back to the
services side and gives it a much larger review surface: topology, structural
navigation, and multi-pane operator drill-downs.

The checkpoint app at
[`tutorials/code/08-topology-and-navigation/`](../code/08-topology-and-navigation/)
builds directly on
[`tutorials/code/07-live-diagnostics/`](../code/07-live-diagnostics/) and
extends the services workspace with a topology review panel that is
intentionally bigger and more spatial than anything in the earlier chapters.

## What You Are Building

By the end of Chapter 8, the services workspace can:

1. switch between service-map, dependency-path, and incident-scope review modes
2. drill into gateway, search, and Core East lanes through authored tabs
3. show structural hierarchy through a tree view
4. keep larger visual and textual review surfaces visible together through a split pane
5. expose canvas and scroll-lane focus as resource-backed state

This chapter is really about making layout and navigation explicit. Larger
surfaces should still be authored, stateful, and understandable.

## Start With Topology State In The Runtime Resource

The central resource is:

- `AshUITutorials.TopologyAndNavigation.Runtime.WorkspaceState`

Important topology fields include:

- `topology_scope`
- `topology_tab_value`
- `topology_tree_model`
- `topology_viewport_focus`
- `topology_viewport_support_title`
- `topology_viewport_support_detail`
- `topology_canvas_layer`
- `topology_canvas_board_copy`
- `topology_canvas_legend`
- `topology_scroll_focus`
- `topology_scroll_status`
- `topology_status_copy`

That is the right place for them. Scope selection, drill-down lane, canvas
layer, and scroll focus are not host-only layout trivia. In this chapter, they
are part of the operator’s working state.

## Keep The Screen Roots Stable

Chapter 8 still persists:

- `AshUITutorials.TopologyAndNavigation.UiScreen`
- `AshUITutorials.TopologyAndNavigation.UiElement`
- `AshUITutorials.TopologyAndNavigation.UiBinding`

And it keeps the explicit screen roots:

- `AshUITutorials.TopologyAndNavigation.Examples.ServicesScreen`
- `AshUITutorials.TopologyAndNavigation.Examples.IncidentsScreen`

The incidents screen largely carries forward the richer workflow stack from
earlier chapters. The services screen is where the new structural review work
happens.

## The Widget Plan For This Chapter

Chapter 8 adds the biggest layout vocabulary in the tutorial so far:

| Widget | Where it goes | Why it belongs there |
|---|---|---|
| `custom:split_pane` | Topology review shell | Keeps structural navigation and large review surfaces visible together |
| `custom:menu` | Topology scope selector | Switches the high-level topology story |
| `custom:tabs` | Drill-down lane selector | Switches between gateway, search, and cluster viewpoints |
| `custom:tree_view` | Structural hierarchy surface | Best fit for dependency and scope trees |
| `custom:viewport` | Focused review lane | Holds the active lane summary and support panel |
| `custom:canvas` | Larger visual board surface | Holds board copy, layer selection, and legend |
| `custom:scroll_bar` | Review-lane selector | Makes the active operator lane explicit |
| `button` | Scope, tab, layer, and lane actions | Drives the topology state transitions |
| `card` and `text` | Supporting context and shared detail | Keep the larger review model readable |

This chapter is not about fancy layout for its own sake. It is about showing
that larger, more spatial surfaces can still stay inside the resource-authority
model.

## Build The Topology Review Panel

The new services-side panel is:

- `AshUITutorials.TopologyAndNavigation.Examples.TopologyReviewPanelElement`

It contains:

- `AshUITutorials.TopologyAndNavigation.Examples.TopologySplitPaneElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyPanelStatusTextElement`

This is a helpful pattern for large surfaces:

1. give the panel one strong container
2. let the split pane organize the interior
3. keep a footer status text to explain the currently active topology mode

## Use A Split Pane To Separate Navigation And Review

The authored shell is:

- `AshUITutorials.TopologyAndNavigation.Examples.TopologySplitPaneElement`

It divides the topology experience into:

- `primary` for menus, tabs, and tree structure
- `secondary` for viewport, canvas, and scroll review

Its key children are:

- `AshUITutorials.TopologyAndNavigation.Examples.TopologyScopeMenuElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyTabsElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyTreeViewElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyViewportElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyScrollBarElement`

That arrangement gives the chapter a clear operator story:

1. choose the structural scope
2. drill into one lane
3. review the hierarchy
4. inspect the larger spatial surfaces

## Build The Structural Navigation Side

The left side of the split pane is anchored by:

- `AshUITutorials.TopologyAndNavigation.Examples.TopologyScopeMenuElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyTabsElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyTreeViewElement`

The scope menu contains:

- `AshUITutorials.TopologyAndNavigation.Examples.ShowServiceTopologyButtonElement`
- `AshUITutorials.TopologyAndNavigation.Examples.ShowDependencyTopologyButtonElement`
- `AshUITutorials.TopologyAndNavigation.Examples.ShowIncidentScopeTopologyButtonElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyScopeSummaryElement`

The tabs then narrow the current story through:

- `AshUITutorials.TopologyAndNavigation.Examples.FocusGatewayTopologyTabButtonElement`
- `AshUITutorials.TopologyAndNavigation.Examples.FocusSearchTopologyTabButtonElement`
- `AshUITutorials.TopologyAndNavigation.Examples.FocusClusterTopologyTabButtonElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyTabsStatusElement`

This is a nice layering:

1. the menu picks the overall topology mode
2. the tabs pick the active lane inside that mode
3. the tree view shows the resulting structure

## Build The Large Review Surfaces

The right side of the split pane uses three complementary widgets:

- `AshUITutorials.TopologyAndNavigation.Examples.TopologyViewportElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyScrollBarElement`

The viewport focuses one drill-down lane and includes:

- `AshUITutorials.TopologyAndNavigation.Examples.TopologyViewportFocusCopyElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyViewportSupportPanelElement`

The canvas gives you a bigger board-like review surface and includes:

- `AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasTrafficPathButtonElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasBlastRadiusButtonElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasLayerElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasBoardCopyElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasLegendElement`

The scroll bar makes the current operator lane explicit through:

- `AshUITutorials.TopologyAndNavigation.Examples.TopologyCommanderScrollButtonElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyInfrastructureScrollButtonElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyHandoffScrollButtonElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyScrollFocusCopyElement`
- `AshUITutorials.TopologyAndNavigation.Examples.TopologyScrollStatusElement`

These surfaces are large, but they are still just authored resources with
bindings and actions. That is the whole point of the chapter.

## Use Actions To Rewrite Structural State

The topology buttons do not just change styling. They rewrite meaningful runtime
fields such as:

- `topology_scope`
- `topology_tab_value`
- `topology_tree_model`
- `topology_canvas_layer`
- `topology_scroll_focus`
- `detail_title`
- `detail_summary`
- `status`

That means the shared detail card and the new topology surfaces stay aligned.
The operator is not looking at unrelated demos. They are looking at one coherent
review story with multiple authored views.

## Keep The Incidents Workspace Intact

Chapter 8 is mainly a services-side expansion. The incidents screen still keeps
the earlier workflow-heavy surfaces:

- filters
- forms
- guard rails
- runbooks
- diagnostics

That is a helpful reminder that the tutorial is building one application, not a
new app per chapter. Each side of the workspace can deepen at a different pace.

## Persist And Mount The Topology-Enabled Workspace

The persistence flow remains unchanged:

- `AshUITutorials.TopologyAndNavigation.seed!/1` creates the runtime record
- authority persists `AshUITutorials.TopologyAndNavigation.Examples.ServicesScreen`
- authority persists `AshUITutorials.TopologyAndNavigation.Examples.IncidentsScreen`

The hosts remain:

- `AshUITutorials.TopologyAndNavigation.Web.ServicesLive`
- `AshUITutorials.TopologyAndNavigation.Web.IncidentsLive`

That consistency is doing a lot of work for the tutorial. It lets you explore a
new surface family without learning a new runtime model each chapter.

## Modules And Resources You Will Touch

Keep these names nearby while you read the checkpoint:

- source file: [`../code/08-topology-and-navigation/lib/ash_ui_tutorials/topology_and_navigation.ex`](../code/08-topology-and-navigation/lib/ash_ui_tutorials/topology_and_navigation.ex)
- main checkpoint module: `AshUITutorials.TopologyAndNavigation`
- runtime state resource: `AshUITutorials.TopologyAndNavigation.Runtime.WorkspaceState`
- persisted UI resources: `AshUITutorials.TopologyAndNavigation.UiScreen`, `AshUITutorials.TopologyAndNavigation.UiElement`, `AshUITutorials.TopologyAndNavigation.UiBinding`
- authoritative screen builders: `AshUITutorials.TopologyAndNavigation.Examples.ServicesScreen`, `AshUITutorials.TopologyAndNavigation.Examples.IncidentsScreen`
- topology shell resources: `AshUITutorials.TopologyAndNavigation.Examples.TopologyReviewPanelElement`, `AshUITutorials.TopologyAndNavigation.Examples.TopologySplitPaneElement`, `AshUITutorials.TopologyAndNavigation.Examples.TopologyScopeMenuElement`, `AshUITutorials.TopologyAndNavigation.Examples.TopologyTabsElement`
- structural review resources: `AshUITutorials.TopologyAndNavigation.Examples.TopologyTreeViewElement`, `AshUITutorials.TopologyAndNavigation.Examples.TopologyViewportElement`, `AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasElement`, `AshUITutorials.TopologyAndNavigation.Examples.TopologyScrollBarElement`
- LiveView hosts: `AshUITutorials.TopologyAndNavigation.Web.ServicesLive`, `AshUITutorials.TopologyAndNavigation.Web.IncidentsLive`

## Run The Checkpoint

From
[`tutorials/code/08-topology-and-navigation/`](../code/08-topology-and-navigation/):

```bash
mix deps.get
mix example.start
```

The default command starts `live_ui` through the Phoenix LiveView host at
`http://127.0.0.1:5000/`.

Use:

- `/` for the services workspace with topology enabled
- `/incidents` for the incidents workspace carrying forward the Chapter 7 stack

Alternate runtime previews remain available:

```bash
mix example.start elm_ui
mix example.start desktop_ui
```

They all render the same authored topology state and screen graph.

## What To Carry Into Chapter 9

Chapter 8 proves that large structural review surfaces can stay explicit,
resource-authored, and stateful.

Chapter 9 builds directly on that services workspace by adding metrics,
capacity, and trend review, while keeping the tutorial equally honest about
sampled telemetry.
