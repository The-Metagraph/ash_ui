# Phase 20 - Overlay, Data, Feedback, Chart, and Operational Example Apps

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- `examples/*`
- `AshUI.Resource.DSL.Screen`
- `AshUI.Resource.DSL.Element`
- `AshUI.LiveView.Integration`
- `AshUI.LiveView.UpdateIntegration`
- `AshUI.Notifications`
- `AshUI.Runtime.*`
- `AshUI.Authorization.*`
- `AshUI.Telemetry`

## Relevant Assumptions / Defaults
- earlier phases already established the shared suite shell, the resource-first
  app template, and any prerequisite widget-type admissions
- examples in this phase are allowed to depend on richer seeded runtime data,
  list bindings, notifications, or simulated operational feeds where needed
- the suite should still keep one primary story per directory even when these
  examples need companion controls or monitoring context
- operational examples should prefer representative simulated data over fake
  visual shells with no runtime meaning

[ ] 20 Phase 20 - Overlay, Data, Feedback, Chart, and Operational Example Apps
  Implement the higher-complexity example families that depend on richer data,
  layered rendering, live updates, or operational storytelling.

  [ ] 20.1 Section - Overlay and Layered-Flow Example Apps
    Add the examples that demonstrate layered, modal, and ephemeral UI flows.

    [ ] 20.1.1 Task - Implement overlay and layered-flow apps
    Build the examples whose primary subject is rendered above or around the
    rest of the screen.

      [ ] 20.1.1.1 Subtask - Implement `overlay`, `dialog`, and `alert_dialog` example apps.
      [ ] 20.1.1.2 Subtask - Implement `context_menu` and `toast` example apps.
      [ ] 20.1.1.3 Subtask - Define the action, binding, and state-handling semantics that drive those examples through resource-local declarations.
      [ ] 20.1.1.4 Subtask - Add tests that prove layered examples mount, transition, and recover without breaking the shared shell.

  [ ] 20.2 Section - Data-Surface Example Apps
    Add the examples whose main value is browsing, inspecting, or reading
    structured data.

    [ ] 20.2.1 Task - Implement data-view apps
    Build the examples that make Ash UI list, table, tree, and document-style
    surfaces reviewable.

      [ ] 20.2.1.1 Subtask - Implement `list` and `table` example apps using list bindings and representative seeded data.
      [ ] 20.2.1.2 Subtask - Implement `tree_view`, `markdown_viewer`, and `log_viewer` example apps with clear data-loading stories.
      [ ] 20.2.1.3 Subtask - Define the canonical interaction story for passive data surfaces so each app still demonstrates meaningful reviewer-visible behavior.
      [ ] 20.2.1.4 Subtask - Add tests that prove representative data surfaces refresh correctly when bound data changes.

  [ ] 20.3 Section - Feedback and Chart Example Apps
    Add the examples that visualize status, progress, and lightweight metrics.

    [ ] 20.3.1 Task - Implement feedback and chart apps
    Build the examples that turn application state or metrics into visible UI
    feedback.

      [ ] 20.3.1.1 Subtask - Implement `status`, `progress`, `gauge`, and `inline_feedback` example apps.
      [ ] 20.3.1.2 Subtask - Implement `sparkline`, `bar_chart`, and `line_chart` example apps.
      [ ] 20.3.1.3 Subtask - Define whether chart examples use maintained public widget types, explicit custom surfaces, or renderer-backed extensions.
      [ ] 20.3.1.4 Subtask - Add tests that prove representative feedback and chart examples respond visibly to seeded or live-updated data.

  [ ] 20.4 Section - Operational and Monitoring Example Apps
    Add the examples that simulate richer runtime systems and observer views.

    [ ] 20.4.1 Task - Implement operational apps
    Build the examples that showcase live-ish or system-level flows through Ash
    UI resource-authority screens.

      [ ] 20.4.1.1 Subtask - Implement `stream_widget`, `process_monitor`, and `supervision_tree_viewer` example apps.
      [ ] 20.4.1.2 Subtask - Implement the `cluster_dashboard` example app as the suite's flagship operational composition example.
      [ ] 20.4.1.3 Subtask - Define how those apps use notifications, seeded refresh cycles, or simulated telemetry without introducing dishonest runtime claims.
      [ ] 20.4.1.4 Subtask - Add tests that prove representative operational examples preserve state updates, list refresh, and action-driven control flows.

  [ ] 20.5 Section - Runtime, Authorization, and Seed Realism
    Keep the complex example apps grounded in real Ash UI runtime behavior
    instead of decorative shells.

    [ ] 20.5.1 Task - Align complex examples with real runtime semantics
    Make the advanced examples prove the package's runtime story and not only
    its rendering story.

      [ ] 20.5.1.1 Subtask - Define when advanced examples should include authorization policies and actor-aware mounting.
      [ ] 20.5.1.2 Subtask - Define when notifications or update subscriptions are required instead of one-shot seeded renders.
      [ ] 20.5.1.3 Subtask - Define how operational examples surface failures, loading states, and recovery paths inside the shared shell.
      [ ] 20.5.1.4 Subtask - Add tests that prove complex examples stay aligned with Ash UI runtime and authorization expectations.

  [ ] 20.6 Section - Phase 20 Integration Tests
    Validate the advanced example families through one coherent Ash UI example
    workflow.

    [ ] 20.6.1 Task - Advanced example-app integration scenarios
    Verify the suite can support complex data and runtime stories without
    breaking the shared example contract.

      [ ] 20.6.1.1 Subtask - Verify representative overlay, data, feedback, and operational apps boot as independent projects and mount seeded screens.
      [ ] 20.6.1.2 Subtask - Verify representative apps demonstrate visible data refresh, action handling, or layered transitions through real Ash UI runtime paths.
      [ ] 20.6.1.3 Subtask - Verify advanced examples preserve the Ash HQ shell while still foregrounding their primary subject.
      [ ] 20.6.1.4 Subtask - Verify complex examples do not rely on superseded document-first authoring or ad hoc runtime shortcuts.
