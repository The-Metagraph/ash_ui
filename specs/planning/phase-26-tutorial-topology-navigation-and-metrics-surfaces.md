# Phase 26 - Tutorial Topology, Navigation, and Metrics Surfaces

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- `tutorials/chapters/*`
- `tutorials/code/*`
- `tutorials/operations_control_center/*`
- `AshUI.Resource.DSL.Screen`
- `AshUI.Resource.DSL.Element`
- topology, display, and chart examples from `examples/*`

## Relevant Assumptions / Defaults
- earlier phases have already established the tutorial shell, service and
  incident workspaces, operator actions, runbooks, and live diagnostics
- topology and metrics chapters should treat visual surfaces as part of real
  operational decision-making, not as isolated display demos
- every chapter in this phase must keep its own code checkpoint under
  `tutorials/code/`

[ ] 26 Phase 26 - Tutorial Topology, Navigation, and Metrics Surfaces
  Implement the tutorial milestones that add service-topology workspaces,
  richer navigation views, and telemetry dashboards to the Operations Control
  Center application.

  [ ] 26.1 Section - Chapter 8 Topology and Navigation Workspaces
    Add the structural and exploratory surfaces operators use to understand how
    systems connect.

    [ ] 26.1.1 Task - Implement service-topology and navigation views
    Teach structural composition across panes, trees, and large review surfaces.

      [ ] 26.1.1.1 Subtask - Implement `tutorials/code/08-topology-and-navigation/` with `tree_view`, `menu`, and `tabs` for navigating services, dependencies, and incident scopes.
      [ ] 26.1.1.2 Subtask - Introduce `viewport`, `scroll_bar`, `split_pane`, and `canvas` where they materially improve large-topology review and not merely because they exist in the widget catalog.
      [ ] 26.1.1.3 Subtask - Ensure topology screens remain resource-first by persisting the composed screen/element graph and explicit drill-down state.
      [ ] 26.1.1.4 Subtask - Add `tutorials/chapters/08-topology-and-navigation.md` with exact references to `tutorials/code/08-topology-and-navigation/`.

  [ ] 26.2 Section - Chapter 9 Metrics, Trends, and Capacity Views
    Add the telemetry surfaces operators use to understand current risk and
    longer-running trends.

    [ ] 26.2.1 Task - Implement charting and capacity dashboards
    Teach summary and trend analysis through real operational narratives.

      [ ] 26.2.1.1 Subtask - Implement `tutorials/code/09-metrics-and-capacity/` with `progress`, `gauge`, `sparkline`, `bar_chart`, and `line_chart` surfaces tied to services, deploys, or clusters.
      [ ] 26.2.1.2 Subtask - Introduce `cluster_dashboard` and related summary panels where they help unify service health, fleet capacity, and recent incident context.
      [ ] 26.2.1.3 Subtask - Keep chart and dashboard stories explicit about what metrics are derived, sampled, or simulated inside the tutorial seed data.
      [ ] 26.2.1.4 Subtask - Add `tutorials/chapters/09-metrics-and-capacity.md` with exact references to `tutorials/code/09-metrics-and-capacity/`.

  [ ] 26.3 Section - Phase 26 Integration Tests
    Validate the topology and telemetry chapters through coherent operational
    review scenarios.

    [ ] 26.3.1 Task - Topology and metrics scenarios
    Prove the tutorial now supports both structural and quantitative review.

      [ ] 26.3.1.1 Subtask - Verify the Chapter 8 and 9 checkpoint apps boot independently and preserve the shared tutorial shell, code-reference contract, and route expectations.
      [ ] 26.3.1.2 Subtask - Verify topology and navigation surfaces keep large-screen review usable without abandoning mobile and smaller desktop breakpoints.
      [ ] 26.3.1.3 Subtask - Verify chart, dashboard, and capacity views stay synchronized with the seeded services, incidents, and cluster data they claim to represent.
      [ ] 26.3.1.4 Subtask - Verify Chapters 8 and 9 each reference the correct checkpoint directory and supporting resources clearly.
