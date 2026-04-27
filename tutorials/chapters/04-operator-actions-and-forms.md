# Chapter 4 - Operator Actions and Forms

## Code For This Chapter

Checkpoint app: `tutorials/code/04-operator-actions-and-forms/`

Previous checkpoint: `tutorials/code/03-filtering-and-search/`

Supporting examples: `examples/date_input`, `examples/field_group`, `examples/form_builder`, `examples/pick_list`

Chapter 3 made the workspace easy to search and narrow. Chapter 4 gives the
operator something meaningful to do inside that filtered workspace.

The checkpoint app at
[`tutorials/code/04-operator-actions-and-forms/`](../code/04-operator-actions-and-forms/)
builds directly on
[`tutorials/code/03-filtering-and-search/`](../code/03-filtering-and-search/)
and keeps the same two screens, but it extends the incidents workspace with
real write workflows. The lesson in this chapter is that forms, disabled
states, and write feedback should stay resource-backed too.

## What You Are Building

By the end of Chapter 4, the incidents workspace can:

1. capture an operator note
2. choose an assignment target
3. schedule a maintenance window with number, date, and time inputs
4. submit resource-backed workflows for acknowledge, assign, and maintenance actions
5. update feedback and incident detail state from one action pipeline

The services workspace remains useful, but the big architectural work in this
chapter happens on the incidents side.

## Start With The Runtime Workflow State

The core resource is still:

- `AshUITutorials.OperatorActionsAndForms.Runtime.WorkspaceState`

But now the runtime record has to hold form state in addition to filter state.
Important new fields include:

- `operator_note`
- `assignment_target`
- `maintenance_duration_minutes`
- `maintenance_date`
- `maintenance_time`
- `acknowledge_disabled`
- `assign_disabled`
- `maintenance_disabled`
- `form_feedback_title`
- `form_feedback_summary`
- `form_feedback_status`

That is the right place for them. These values are not temporary host concerns.
They are part of the operator workflow story this chapter is teaching.

The write path centers on:

- `AshUITutorials.OperatorActionsAndForms.Runtime.WorkspaceState.submit_operator_workflow`

That action is what turns the form from a collection of controls into a real
application surface.

## Keep The Existing Workspace Model

Chapter 4 still persists the same two screen roots through:

- `AshUITutorials.OperatorActionsAndForms.UiScreen`
- `AshUITutorials.OperatorActionsAndForms.UiElement`
- `AshUITutorials.OperatorActionsAndForms.UiBinding`

And the screens themselves stay explicit:

- `AshUITutorials.OperatorActionsAndForms.Examples.ServicesScreen`
- `AshUITutorials.OperatorActionsAndForms.Examples.IncidentsScreen`

That matters because the chapter is not replacing your existing workspace. It
is layering workflow behavior on top of it.

## The Widget Plan For This Chapter

Chapter 4 introduces the first real authored workflow shell:

| Widget | Where it goes | Why it belongs there |
|---|---|---|
| `form_builder` | Main operator workflow shell | Gives the action sequence a clear, dedicated container |
| `custom:field_group` | Note/assignment cluster and maintenance cluster | Groups related workflow inputs together |
| `form_field` | Around each individual input | Keeps labels and help text attached to the correct control |
| `input` | Operator note, duration, date, and time fields | Handles the typed form values |
| `custom:pick_list` | Assignment target choice | Makes the assignment handoff explicit and readable |
| `button` | Acknowledge, assign, schedule maintenance actions | Submits workflow intents back into the runtime resource |
| `badge` and `text` | Workflow feedback block | Shows the current workflow state without hiding it in flash-only host UI |

The key idea is that the form is not just a decoration. It is a full authored
resource surface with structure, state, and actions.

## Build The Operator Workflow Panel

The main new panel is:

- `AshUITutorials.OperatorActionsAndForms.Examples.OperatorFormsPanelElement`

It contains:

- `AshUITutorials.OperatorActionsAndForms.Examples.OperatorWorkflowFormElement`
- `AshUITutorials.OperatorActionsAndForms.Examples.FormFeedbackBadgeElement`
- `AshUITutorials.OperatorActionsAndForms.Examples.FormFeedbackTitleElement`
- `AshUITutorials.OperatorActionsAndForms.Examples.FormFeedbackSummaryElement`

This layout is worth copying in later work:

1. put the form in the body
2. put the feedback in the footer

That way the operator always sees both the current inputs and the last workflow
result in one stable place.

## Use `form_builder` As The Workflow Shell

`AshUITutorials.OperatorActionsAndForms.Examples.OperatorWorkflowFormElement`
is the top-level form resource, and it uses `form_builder`.

Inside it, place:

- `AshUITutorials.OperatorActionsAndForms.Examples.NoteAndAssignmentGroupElement`
- `AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceWindowGroupElement`
- `AshUITutorials.OperatorActionsAndForms.Examples.AcknowledgeIncidentButtonElement`
- `AshUITutorials.OperatorActionsAndForms.Examples.AssignIncidentButtonElement`
- `AshUITutorials.OperatorActionsAndForms.Examples.ScheduleMaintenanceButtonElement`

This arrangement gives the form a clear shape:

1. capture note and owner intent
2. capture maintenance timing if needed
3. fire one of three actions

That is much easier to reason about than scattering fields and buttons across
the page.

## Build The Note And Assignment Group

The first field cluster is:

- `AshUITutorials.OperatorActionsAndForms.Examples.NoteAndAssignmentGroupElement`

It contains:

- `AshUITutorials.OperatorActionsAndForms.Examples.OperatorNoteFieldElement`
- `AshUITutorials.OperatorActionsAndForms.Examples.AssignmentTargetFieldElement`

Those field resources then wrap:

- `AshUITutorials.OperatorActionsAndForms.Examples.OperatorNoteInputElement`
- `AshUITutorials.OperatorActionsAndForms.Examples.AssignmentTargetPickListElement`

This is a good place to slow down and notice the layering:

1. the field resource owns label and help text
2. the input resource owns the actual value
3. the runtime record owns the persisted state

That pattern keeps the form very readable, even as it grows.

## Build The Maintenance Window Group

The second field cluster is:

- `AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceWindowGroupElement`

It contains:

- `AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceDurationFieldElement`
- `AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceDateFieldElement`
- `AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceTimeFieldElement`

Those fields wrap:

- `AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceDurationInputElement`
- `AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceDateInputElement`
- `AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceTimeInputElement`

This is where the chapter starts to feel like an actual operations tool. The
workflow is no longer just "click to change focus". It now collects structured
inputs that matter to the action path.

## Wire The Workflow Buttons Back Into The Resource Action

The three workflow buttons are:

- `AshUITutorials.OperatorActionsAndForms.Examples.AcknowledgeIncidentButtonElement`
- `AshUITutorials.OperatorActionsAndForms.Examples.AssignIncidentButtonElement`
- `AshUITutorials.OperatorActionsAndForms.Examples.ScheduleMaintenanceButtonElement`

Each button calls the same action source:

- `WorkspaceState.submit_operator_workflow`

What changes is the `workflow_intent` and the fields passed into the transform.

This is a strong design choice:

1. one resource action owns the workflow rules
2. different authored buttons express different intents into that action
3. the feedback, disabled states, and incident updates all stay inside the same resource-backed loop

That keeps the UI easy to follow and the behavior easy to test.

## Keep Disabled State Honest

A nice detail in Chapter 4 is that disabled state is not guessed in the host.
The runtime resource computes:

- `acknowledge_disabled`
- `assign_disabled`
- `maintenance_disabled`

Then the buttons bind those values directly.

That means the screen is honest about what is and is not currently allowed, and
it stays honest across runtimes because the decision lives in shared state.

## Let The Incidents Workspace Grow Without Losing Its Shape

The incidents screen still keeps its earlier pieces:

- menu
- command palette
- incidents filters
- incidents table
- shared detail card

Chapter 4 simply adds the workflow panel beside that existing review structure.
That is the right move. Operators still need search and detail context before
they submit a workflow.

The services screen remains present and useful, but the incidents screen is now
the first place where the tutorial behaves like a genuine operations console.

## Persist And Mount The Workflow-Enabled Screens

Persistence still works the same way:

- `AshUITutorials.OperatorActionsAndForms.seed!/1` creates the runtime record
- authority persists `AshUITutorials.OperatorActionsAndForms.Examples.ServicesScreen`
- authority persists `AshUITutorials.OperatorActionsAndForms.Examples.IncidentsScreen`

The hosts remain:

- `AshUITutorials.OperatorActionsAndForms.Web.ServicesLive`
- `AshUITutorials.OperatorActionsAndForms.Web.IncidentsLive`

That is the pattern to keep trusting. The screens and elements carry the UI
structure. The runtime resource carries the workflow state. The host mounts and
renders.

## Modules And Resources You Will Touch

Chapter 4 is easiest to follow if you keep these names nearby:

- source file: [`../code/04-operator-actions-and-forms/lib/ash_ui_tutorials/operator_actions_and_forms.ex`](../code/04-operator-actions-and-forms/lib/ash_ui_tutorials/operator_actions_and_forms.ex)
- main checkpoint module: `AshUITutorials.OperatorActionsAndForms`
- runtime state resource: `AshUITutorials.OperatorActionsAndForms.Runtime.WorkspaceState`
- persisted UI resources: `AshUITutorials.OperatorActionsAndForms.UiScreen`, `AshUITutorials.OperatorActionsAndForms.UiElement`, `AshUITutorials.OperatorActionsAndForms.UiBinding`
- authoritative screen builders: `AshUITutorials.OperatorActionsAndForms.Examples.ServicesScreen`, `AshUITutorials.OperatorActionsAndForms.Examples.IncidentsScreen`
- workflow surfaces: `AshUITutorials.OperatorActionsAndForms.Examples.OperatorFormsPanelElement`, `AshUITutorials.OperatorActionsAndForms.Examples.OperatorWorkflowFormElement`, `AshUITutorials.OperatorActionsAndForms.Examples.NoteAndAssignmentGroupElement`, `AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceWindowGroupElement`
- workflow actions: `AshUITutorials.OperatorActionsAndForms.Examples.AcknowledgeIncidentButtonElement`, `AshUITutorials.OperatorActionsAndForms.Examples.AssignIncidentButtonElement`, `AshUITutorials.OperatorActionsAndForms.Examples.ScheduleMaintenanceButtonElement`
- LiveView hosts: `AshUITutorials.OperatorActionsAndForms.Web.ServicesLive`, `AshUITutorials.OperatorActionsAndForms.Web.IncidentsLive`

## Run The Checkpoint

From
[`tutorials/code/04-operator-actions-and-forms/`](../code/04-operator-actions-and-forms/):

```bash
mix deps.get
mix example.start
```

The default command starts `live_ui` through the Phoenix LiveView host at
`http://127.0.0.1:5000/`.

Use:

- `/` for the services workspace
- `/incidents` for the incidents workspace with the operator forms panel

Alternate runtime previews remain available:

```bash
mix example.start elm_ui
mix example.start desktop_ui
```

All three runtimes use the same authored screen graph and the same workflow
state model.

## What To Carry Into Chapter 5

Chapter 4 proves that form inputs and workflow submits belong inside the same
resource-backed architecture as your read-only surfaces.

Chapter 5 keeps those forms, but it adds the next real concern: how to model
guard rails, confirmations, and feedback for sensitive actions without slipping
into invisible host-only overlay state.
