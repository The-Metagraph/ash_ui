# Phase 19 - Layout, Navigation, and Display Example Apps

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- `examples/*`
- `AshUI.Resource.DSL.Screen`
- `AshUI.Resource.DSL.Element`
- `AshUI.Resource.DSL.Relationship`
- `AshUI.Compiler`
- `AshUI.Rendering.LiveUIAdapter`
- `AshUI.Resources.Validations.Authoring`
- `guides/user/UG-0003-widget-types-properties-and-signals.md`

## Relevant Assumptions / Defaults
- the shared example scaffold, route conventions, and Ash HQ theme baseline from
  Phase 17 already exist
- the examples in this phase should stress relationship-driven composition more
  heavily than the foundational phase did
- some navigation and display-system examples may require public widget
  vocabulary expansion or explicit `custom:*` handling before they can ship
  honestly
- layout examples should favor maintained public Ash UI types such as `row`,
  `column`, and `grid` wherever possible

[ ] 19 Phase 19 - Layout, Navigation, and Display Example Apps
  Implement the layout, navigation, and display-system example families,
  expanding Ash UI's public example-ready widget surface where necessary.

  [x] 19.1 Section - Public Type Expansion for Navigation and Display
    Decide which higher-order surfaces become maintained Ash UI widget types and
    which remain explicit custom examples.

    [x] 19.1.1 Task - Define the navigation and display authoring boundary
    Resolve the capability gaps before example implementation hard-codes the
    wrong abstraction.

      [x] 19.1.1.1 Subtask - Define the supported authoring/runtime path for `menu`, `tabs`, and `command_palette`.
      [x] 19.1.1.2 Subtask - Define the supported authoring/runtime path for `viewport`, `scroll_bar`, `split_pane`, and `canvas`.
      [x] 19.1.1.3 Subtask - Decide which of those surfaces should become public Ash UI widget types versus explicit `custom:*` example-only constructs.
      [x] 19.1.1.4 Subtask - Add validation, renderer, and documentation requirements for every newly admitted example-facing widget type.

  [ ] 19.2 Section - Layout and Navigation Example Apps
    Build the example apps that primarily demonstrate composition structure and
    movement through the UI rather than one-off content widgets.

    [ ] 19.2.1 Task - Implement layout and navigation apps
    Add examples whose main value is relationship-driven structure and app-level
    flow.

      [ ] 19.2.1.1 Subtask - Implement `row`, `column`, and `grid` example apps with relationship-driven child ordering and spacing semantics.
      [ ] 19.2.1.2 Subtask - Implement `menu`, `tabs`, and `command_palette` example apps with clear navigation stories and honest runtime affordances.
      [ ] 19.2.1.3 Subtask - Use screen-local glue only where necessary, keeping the core structure in related element resources.
      [ ] 19.2.1.4 Subtask - Add tests that prove representative layout and navigation apps compile and render in the declared relationship order.

  [ ] 19.3 Section - Display-System Example Apps
    Build the examples that demonstrate larger viewports and multi-pane or
    drawing-oriented surfaces.

    [ ] 19.3.1 Task - Implement display-system apps
    Add the apps whose primary subject is a larger rendering surface or spatial
    viewport construct.

      [ ] 19.3.1.1 Subtask - Implement `viewport` and `scroll_bar` example apps.
      [ ] 19.3.1.2 Subtask - Implement `split_pane` and `canvas` example apps.
      [ ] 19.3.1.3 Subtask - Define how those examples expose their primary interaction story through resource-local bindings, actions, or layout state.
      [ ] 19.3.1.4 Subtask - Add tests that prove representative display apps preserve the Ash HQ shell without hiding the primary display construct.

  [ ] 19.4 Section - Relationship-Driven Composition Proof
    Make this phase the place where multi-resource composition becomes visibly
    unavoidable in the example suite.

    [ ] 19.4.1 Task - Emphasize relationship-first structure in complex layout apps
    Ensure the examples showcase the architecture the package actually wants
    users to adopt.

      [ ] 19.4.1.1 Subtask - Use nested element relationships as the default composition path for layout, navigation, and display apps.
      [ ] 19.4.1.2 Subtask - Restrict inline screen fragments to shell glue, helper labels, or other low-noise cases.
      [ ] 19.4.1.3 Subtask - Add review guidance that rejects monolithic screen-authority examples for these families.
      [ ] 19.4.1.4 Subtask - Add tests that prove representative apps compile from related element graphs rather than one large inline tree.

  [ ] 19.5 Section - Phase 19 Integration Tests
    Validate the layout, navigation, and display examples through the shared Ash
    UI example-suite path.

    [ ] 19.5.1 Task - Layout/navigation/display integration scenarios
    Verify the phase delivers real structural examples and not only static
    visual shells.

      [ ] 19.5.1.1 Subtask - Verify representative apps from each family boot independently and mount seeded screens through LiveView.
      [ ] 19.5.1.2 Subtask - Verify newly admitted or custom widget surfaces validate and render through the intended path.
      [ ] 19.5.1.3 Subtask - Verify relationship-driven composition remains visible in canonical output for representative apps.
      [ ] 19.5.1.4 Subtask - Verify the Ash HQ shell remains intact around high-structure examples without obscuring their primary subject.
