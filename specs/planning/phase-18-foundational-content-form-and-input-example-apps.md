# Phase 18 - Foundational Content, Form, and Input Example Apps

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- `examples/*`
- `AshUI.Resource.DSL.Screen`
- `AshUI.Resource.DSL.Element`
- `AshUI.Resource.DSL.Binding`
- `AshUI.LiveView.Integration`
- `AshUI.LiveView.EventHandler`
- `AshUI.Runtime.*`
- `AshUI.Rendering.LiveUIAdapter`

## Relevant Assumptions / Defaults
- the Phase 17 suite scaffold, catalog crosswalk, and Ash HQ style baseline
  already exist
- every app in this phase keeps one primary subject per directory even when
  supporting labels, wrappers, or helper controls appear around it
- content and baseline form examples should prioritize the currently maintained
  Ash UI public widget vocabulary wherever possible
- directory names may preserve sibling-catalog parity while using canonical Ash
  UI widget types internally

[ ] 18 Phase 18 - Foundational Content, Form, and Input Example Apps
  Implement the baseline Ash UI example families that establish the common
  resource-first app shape across content, form scaffolding, and input-control
  examples.

  [x] 18.1 Section - Foundational Content Example Apps
    Create the first wave of resource-first example apps around the lowest-risk
    content and structural widgets.

    [x] 18.1.1 Task - Implement baseline content and structural apps
    Add the foundational examples that define the suite's default review shell
    and minimal resource-authority flows.

      [x] 18.1.1.1 Subtask - Implement `text`, `button`, `label`, and `link` example apps with one screen resource and one or more related element resources each.
      [x] 18.1.1.2 Subtask - Implement `icon` and `image` example apps with Ash-HQ-styled presentation panels and honest renderer/runtime expectations.
      [x] 18.1.1.3 Subtask - Implement `separator`, `spacer`, `content`, and `box` example apps, preserving directory-name parity while using canonical Ash UI types such as `divider` where required.
      [x] 18.1.1.4 Subtask - Add tests that prove every foundational app mounts through the shared example shell, shared theme contract, and resource-authority persistence path.

  [ ] 18.2 Section - Form Scaffolding Example Apps
    Establish the form-building support examples that later input apps can rely
    on without collapsing multiple concepts into one directory.

    [ ] 18.2.1 Task - Implement form scaffold apps
    Add the examples for form-oriented structure rather than individual inputs.

      [ ] 18.2.1.1 Subtask - Implement `form_builder`, `field_group`, and `field` example apps.
      [ ] 18.2.1.2 Subtask - Define the allowed supporting screen shell and helper elements for form-oriented examples so the primary subject remains clear.
      [ ] 18.2.1.3 Subtask - Demonstrate element-local bindings and actions on form-oriented resources where they materially clarify the widget story.
      [ ] 18.2.1.4 Subtask - Add tests that prove each form-scaffold app still preserves the shared Ash HQ shell and resource-first authoring contract.

  [ ] 18.3 Section - Input Control Example Apps
    Implement the baseline interactive control catalog around Ash UI's binding
    and action semantics.

    [ ] 18.3.1 Task - Implement text, selection, and boolean input apps
    Add the examples that sit at the center of the baseline input surface.

      [ ] 18.3.1.1 Subtask - Implement `text_input`, `numeric_input`, `date_input`, `time_input`, and `file_input` example apps, mapping them to the supported Ash UI input boundary or extending that boundary where necessary.
      [ ] 18.3.1.2 Subtask - Implement `checkbox`, `radio_group`, `select`, `pick_list`, and `toggle` example apps, preserving directory-name parity while using canonical Ash UI types such as `radio` and `switch`.
      [ ] 18.3.1.3 Subtask - Ensure every input app demonstrates at least one meaningful write or selection flow through element-local bindings or actions.
      [ ] 18.3.1.4 Subtask - Add tests that prove every input app exposes the primary control clearly and preserves its supported signal semantics.

    [ ] 18.3.2 Task - Align validation and runtime expectations for input apps
    Keep the example surface honest about what Ash UI actually supports today.

      [ ] 18.3.2.1 Subtask - Define how input examples surface unsupported or partial capabilities without pretending they are production-ready.
      [ ] 18.3.2.2 Subtask - Define how file-input examples behave when upload/runtime support is narrower than the directory name suggests.
      [ ] 18.3.2.3 Subtask - Define how validation errors, disabled states, and transformed values appear inside the shared example shell.
      [ ] 18.3.2.4 Subtask - Add tests that prove the input examples fail clearly when authoring/runtime assumptions are violated.

  [ ] 18.4 Section - Phase 18 Integration Tests
    Validate the foundational content, form, and input examples through one
    shared Ash UI example path.

    [ ] 18.4.1 Task - Foundational example-app integration scenarios
    Verify the first example families behave like a coherent resource-first
    suite rather than disconnected demos.

      [ ] 18.4.1.1 Subtask - Verify every Phase 18 app boots as an independent Mix project and mounts its seeded screen through LiveView.
      [ ] 18.4.1.2 Subtask - Verify every app persists its screen through `AshUI.Resource.Authority` and compiles from the authoritative resource graph.
      [ ] 18.4.1.3 Subtask - Verify the shared Ash HQ shell remains visually consistent across representative content, form, and input apps.
      [ ] 18.4.1.4 Subtask - Verify representative binding and action flows work for text, selection, and boolean controls.
