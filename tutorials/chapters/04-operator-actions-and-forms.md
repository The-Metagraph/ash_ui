# Chapter 4 - Operator Actions and Forms

## Code For This Chapter

Checkpoint app: `tutorials/code/04-operator-actions-and-forms/`

Previous checkpoint: `tutorials/code/03-filtering-and-search/`

Supporting examples: `examples/date_input`, `examples/field_group`, `examples/form_builder`, `examples/pick_list`

This chapter adds the first write workflows to the filtered services-and-incidents
workspace from
[`tutorials/code/03-filtering-and-search/`](../code/03-filtering-and-search/).

## What You Build

The checkpoint app at
[`tutorials/code/04-operator-actions-and-forms/`](../code/04-operator-actions-and-forms/)
keeps the same two authoritative screens from Chapter 3 and extends the
incidents workspace with a persisted operator-actions panel.

That panel uses:

- `form_builder` as the authored workflow shell
- `custom:field_group` plus `form_field` resources for grouped form structure
- `input` with `type="number"`, `type="date"`, and `type="time"` for the
  maintenance window
- `custom:pick_list` for the assignment target
- button actions that call `WorkspaceState.submit_operator_workflow`

The key design constraint in this chapter is that disabled states, success
feedback, and incident-catalog updates all remain resource-backed instead of
being simulated only in the host LiveView.

## Modules and Resources Introduced

- Main checkpoint module:
  [`AshUITutorials.OperatorActionsAndForms`](../code/04-operator-actions-and-forms/lib/ash_ui_tutorials/operator_actions_and_forms.ex)
- Runtime state resource:
  `AshUITutorials.OperatorActionsAndForms.Runtime.WorkspaceState`
- Persisted UI resources:
  `AshUITutorials.OperatorActionsAndForms.UiScreen`,
  `AshUITutorials.OperatorActionsAndForms.UiElement`, and
  `AshUITutorials.OperatorActionsAndForms.UiBinding`
- Existing authoritative screen builders:
  `AshUITutorials.OperatorActionsAndForms.Examples.ServicesScreen` and
  `AshUITutorials.OperatorActionsAndForms.Examples.IncidentsScreen`
- New authored form resources:
  `AshUITutorials.OperatorActionsAndForms.Examples.OperatorFormsPanelElement`,
  `AshUITutorials.OperatorActionsAndForms.Examples.OperatorWorkflowFormElement`,
  `AshUITutorials.OperatorActionsAndForms.Examples.NoteAndAssignmentGroupElement`,
  and `AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceWindowGroupElement`
- New authored action triggers:
  `AshUITutorials.OperatorActionsAndForms.Examples.AcknowledgeIncidentButtonElement`,
  `AshUITutorials.OperatorActionsAndForms.Examples.AssignIncidentButtonElement`,
  and `AshUITutorials.OperatorActionsAndForms.Examples.ScheduleMaintenanceButtonElement`
- LiveView hosts:
  `AshUITutorials.OperatorActionsAndForms.Web.ServicesLive` and
  `AshUITutorials.OperatorActionsAndForms.Web.IncidentsLive`

The write path is centered on
`AshUITutorials.OperatorActionsAndForms.Runtime.WorkspaceState.submit_operator_workflow`.
That action receives the authored workflow intent plus the persisted form state,
then rewrites feedback copy, disabled flags, incident ownership/state, and the
shared detail card in one resource-first step.

## Run The Checkpoint

From
[`tutorials/code/04-operator-actions-and-forms/`](../code/04-operator-actions-and-forms/):

```bash
mix deps.get
mix example.start
```

The default command starts `live_ui` through the Phoenix LiveView host at
`http://127.0.0.1:5000/`. Visit `/` for the services workspace and
`/incidents` for the incidents workspace with the operator-action panel.

Alternate runtime previews are still available:

```bash
mix example.start elm_ui
mix example.start desktop_ui
```

Those modes keep the same authoritative screen graph and the same resource
write path, so the tutorial can compare runtimes later without rewriting the
form contract introduced here.
