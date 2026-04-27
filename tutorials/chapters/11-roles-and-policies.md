# Chapter 11 - Roles and Policies

## Code For This Chapter

Checkpoint app: `tutorials/code/11-roles-and-policies/`

Previous checkpoint: `tutorials/code/10-runtime-introspection/`

Supporting examples: `examples/dialog`, `examples/form_builder`, `examples/menu`, `examples/status`

This chapter builds directly on [`tutorials/code/10-runtime-introspection/`](../code/10-runtime-introspection/). The goal is to keep all of the operational depth from the earlier chapters while finally answering the question, “What does this application look like for different actors?” By the end of the chapter, the Operations Control Center still has the same services, incidents, runtime, diagnostics, topology, and metrics surfaces, but those screens now mount differently for `admin`, `on_call_operator`, and `viewer`.

The finished checkpoint lives in [`tutorials/code/11-roles-and-policies/`](../code/11-roles-and-policies/), and the main implementation is in [`../code/11-roles-and-policies/lib/ash_ui_tutorials/roles_and_policies.ex`](../code/11-roles-and-policies/lib/ash_ui_tutorials/roles_and_policies.ex).

## What You Are Building

Chapter 10 taught us how to look deeper into the runtime. Chapter 11 teaches us how to keep that same application safe and honest once more than one kind of user can mount it.

We are adding three actor views:

1. `admin`, backed by `admin-jules`
2. `on_call_operator`, backed by `on-call-maya`
3. `viewer`, backed by `viewer-ren`

The important point is that we are not solving this with a pile of ad hoc LiveView `if` statements. The role differences in this chapter come from the same authored graph and Ash policies that already power the rest of the tutorial.

## Modules and Resources You Will Touch

Start with these modules in [`../code/11-roles-and-policies/lib/ash_ui_tutorials/roles_and_policies.ex`](../code/11-roles-and-policies/lib/ash_ui_tutorials/roles_and_policies.ex):

- `AshUITutorials.RolesAndPolicies`
- `AshUITutorials.RolesAndPolicies.Runtime.WorkspaceState`
- `AshUITutorials.RolesAndPolicies.UiScreen`
- `AshUITutorials.RolesAndPolicies.UiElement`
- `AshUITutorials.RolesAndPolicies.UiBinding`
- `AshUITutorials.RolesAndPolicies.Examples.ServicesScreen`
- `AshUITutorials.RolesAndPolicies.Examples.IncidentsScreen`
- `AshUITutorials.RolesAndPolicies.Examples.OperatorFormsPanelElement`
- `AshUITutorials.RolesAndPolicies.Examples.GuardedActionsPanelElement`
- `AshUITutorials.RolesAndPolicies.Examples.RolePolicySummaryPanelElement`
- `AshUITutorials.RolesAndPolicies.Examples.AdminPolicyAuditPanelElement`
- `AshUITutorials.RolesAndPolicies.Examples.ViewerPolicyNoticePanelElement`
- `AshUITutorials.RolesAndPolicies.Web.ServicesLive`
- `AshUITutorials.RolesAndPolicies.Web.IncidentsLive`

You should also keep an eye on the policy checks that the authored storage resources already use:

- `AshUI.Authorization.Checks.ScreenAccess`
- `AshUI.Authorization.Checks.ElementAccess`
- `AshUI.Authorization.Checks.BindingAccess`

Those checks are what make the screen graph, element graph, and binding graph matter for authorization instead of just for rendering.

## Step 1: Add Actor-Aware Mounting

Begin at the top-level `AshUITutorials.RolesAndPolicies` module.

Add actor helpers that can:

- map query-string aliases like `admin`, `on_call_operator`, and `viewer`
- resolve them to seeded actor profiles
- expose human-readable role copy for the shell
- build actor-aware links that preserve the selected runtime

Then update `AshUITutorials.RolesAndPolicies.Web.ServicesLive` and `AshUITutorials.RolesAndPolicies.Web.IncidentsLive` so both routes read `params["actor"]`, seed the checkpoint for that actor, and assign the chosen actor as `current_user` before mounting the authored screen.

This is the first architectural lesson of the chapter: the host still decides *who* is mounting the tutorial, but the host is not the source of truth for *what that actor is allowed to see or do*.

## Step 2: Persist Actor Context in the Shared State

Next, extend `AshUITutorials.RolesAndPolicies.Runtime.WorkspaceState`.

Add persisted fields for:

- `actor_id`
- `actor_name`
- `actor_role`
- `actor_summary`
- `actor_policy_notice`

Then seed those fields through `seed_state/1`, `hydrate_state/1`, and the new actor context helper.

This gives us one durable place where the current actor can be reflected back into the screen. We are not just hiding controls. We are also teaching the reader why the current screen looks the way it does.

## Step 3: Add the Actor Summary Surface to the Services Screen

The services screen gets a new authored summary panel:

- `AshUITutorials.RolesAndPolicies.Examples.RolePolicySummaryPanelElement`
- `AshUITutorials.RolesAndPolicies.Examples.RolePolicyNameTextElement`
- `AshUITutorials.RolesAndPolicies.Examples.RolePolicySummaryTextElement`
- `AshUITutorials.RolesAndPolicies.Examples.RolePolicyNoticeTextElement`

Wire that panel into `AshUITutorials.RolesAndPolicies.Examples.ServicesWorkspacePanelElement` after the runtime review panel.

That placement is deliberate. By Chapter 11, the services workspace already contains filters, topology, metrics, and runtime introspection. The actor summary panel belongs near the bottom because it explains the whole workspace that came before it. It is a policy explanation surface, not a replacement for the earlier operational widgets.

## Step 4: Make Operator-Only Screens Explicit in the Authored Graph

Now move to the incidents workspace.

The operator workflow form and guarded action surfaces are still the right widgets for the chapter:

- `form_builder`
- `custom:field_group`
- `input`
- `custom:pick_list`
- `custom:context_menu`
- `custom:overlay`
- `custom:dialog`
- `custom:alert_dialog`
- `custom:toast`

The difference is that Chapter 11 adds `required_roles` metadata to the authored resources that own these surfaces.

In practice, that means `AshUITutorials.RolesAndPolicies.Examples.OperatorFormsPanelElement`, `AshUITutorials.RolesAndPolicies.Examples.OperatorWorkflowFormElement`, `AshUITutorials.RolesAndPolicies.Examples.GuardedActionsPanelElement`, and the operator-only action bindings all carry the role requirement for `[:on_call_operator, :admin]`.

This is the heart of the chapter. The viewer does not lose forms and destructive actions because the LiveView template decided to hide them. The viewer loses them because the persisted elements and bindings say they require a different role.

## Step 5: Add Role-Specific Incident Panels

Chapter 11 also adds two role-specific incident review panels:

- `AshUITutorials.RolesAndPolicies.Examples.AdminPolicyAuditPanelElement`
- `AshUITutorials.RolesAndPolicies.Examples.ViewerPolicyNoticePanelElement`

Wire both into `AshUITutorials.RolesAndPolicies.Examples.IncidentsWorkspacePanelElement`.

The admin panel is there to show that full operators sometimes need a separate audit and override explanation surface. The viewer panel is there to make read-only behavior feel intentional instead of broken. A good permission-aware screen should explain itself.

## Step 6: Tighten the Runtime Resource Policy

The screen graph is only half the story. We also need the runtime resource to reject the wrong writes.

In `AshUITutorials.RolesAndPolicies.Runtime.WorkspaceState`, keep plain `update` available for active actors so viewers can still navigate filters and read-only review lanes. Then lock the write-heavy custom update actions down:

- `submit_operator_workflow`
- `preview_guarded_action`
- `confirm_guarded_action`

Those actions should stay available to `:admin` through the bypass and to `:on_call_operator` through explicit policy authorization. A `viewer` mount should fail clearly if it tries to trigger those actions directly.

That is the second architectural lesson of the chapter: UI visibility and runtime mutation both need policy coverage.

## Step 7: Add the Actor Switcher to the Tutorial Shell

Finally, update `AshUITutorials.RolesAndPolicies.Web.Components.TutorialShell`.

Add a small actor switcher in the header that links back into the same page with a different `actor` query parameter while preserving the selected runtime.

This is a thin host concern, and that is fine. The shell is allowed to choose the actor. What matters is that once the actor is selected, the real differences still come from:

- `AshUITutorials.RolesAndPolicies.UiScreen`
- `AshUITutorials.RolesAndPolicies.UiElement`
- `AshUITutorials.RolesAndPolicies.UiBinding`
- `AshUI.Authorization.Checks.ScreenAccess`
- `AshUI.Authorization.Checks.ElementAccess`
- `AshUI.Authorization.Checks.BindingAccess`

That is what keeps the tutorial honest.

## What to Look For in the Finished Checkpoint

When Chapter 11 is working, you should be able to mount the checkpoint app three ways and see real differences:

- `admin` keeps the full services and incidents surface, including the admin review panel and the destructive operator paths.
- `on_call_operator` keeps the workflow and guard surfaces but does not see the admin-only audit panel.
- `viewer` still sees dashboards, runtime trees, runbooks, tables, and diagnostics, but the mutation surfaces are removed from the authored graph and direct write attempts are denied by policy.

That is the full goal of the chapter: a friendlier tutorial on roles and policies, built with the same resource-first screen model as everything that came before it.
