# UG-0006: Authorization and Runtime Safety

---
id: UG-0006
title: Authorization and Runtime Safety
audience: Application Developers
status: Active
owners: Ash UI Team
last_reviewed: 2026-04-23
next_review: 2026-10-23
related_reqs: [REQ-AUTH-002, REQ-AUTH-003, REQ-AUTH-005, REQ-AUTH-007, REQ-AUTH-009, REQ-AUTH-012]
related_scns: [SCN-021, SCN-081, SCN-082, SCN-084, SCN-085, SCN-101]
related_guides: [UG-0001, UG-0004, UG-0005, UG-0007, DG-0004]
diagram_required: false
---

## Overview

AshUI authorization is not limited to one screen-level check. The current
runtime authorizes at multiple boundaries:

- screen mount
- action execution
- binding reads
- binding writes

That matters because a screen can mount successfully and still reject a later
action or write if the actor is not allowed to perform it.

## Prerequisites

Before reading this guide, you should:

- Have read [UG-0005](./UG-0005-liveview-runtime-and-rendering.md).
- Understand how bindings and actions are declared.
- Know how your app models the current user and roles.

## The User Shape AshUI Expects

At runtime, the simplest supported user shape is a map or struct with at least:

- `id`
- `active`
- any role or ownership fields your policies use

Example:

```elixir
%{id: "user-1", role: :admin, active: true}
```

Inactive users are denied before protected operations continue.

## Runtime Authorization Checks

The current runtime entry points are:

| Check | What it protects |
|---|---|
| `check_mount_authorization/2` | Loading and mounting a screen |
| `check_action_authorization/3` | Executing an action or signal-driven command |
| `check_read_access/2` | Reading bound resource data |
| `check_write_access/2` | Writing through bidirectional bindings |

These checks are layered on top of Ash resource policies for screens, elements,
and bindings.

## What This Means for Screen Authors

- Do not assume a successful mount implies all later actions are allowed.
- Keep actions on the element that owns them so authorization failures are local and understandable.
- Treat bindings as data access points; they are subject to read/write authorization too.
- Always assign a real actor before calling `mount_ui_screen/3`.

## Safe Patterns

### Pattern: Fail early at mount

Assign the authenticated user before mounting and let AshUI reject the mount if
the screen is not accessible.

### Pattern: Keep write ownership close to the input

If an input writes to a resource field, the binding on that input is the right
place for authorization to be evaluated.

### Pattern: Keep action ownership close to the button

If a button triggers a workflow, declare the action on that button resource and
let the runtime enforce authorization at execution time.

## Runtime Safety Notes

Current safety behavior includes:

- no implicit development or test bypass
- an explicit runtime bypass setting exists, but it is a deliberate configuration decision
- structured authorization failures at runtime
- cached authorization decisions to reduce repeated checks

Treat bypass as an operational exception, not as a normal app-development mode.

## Troubleshooting

### A screen does not mount for a valid user

Check the screen policy and whether the assigned user is active. Mount
authorization happens before the screen is hydrated.

### A button renders but clicking it fails

That often means mount authorization passed but action authorization failed.
Inspect the action source, user role, and target resource policy.

### An input shows data but saving fails

That usually means read access is allowed but write access is not. Check the
binding source and the runtime write policy for that resource.

## See Also

- [UG-0004: Bindings, Actions, and Forms](./UG-0004-bindings-actions-and-forms.md)
- [UG-0005: LiveView Runtime and Rendering](./UG-0005-liveview-runtime-and-rendering.md)
- [DG-0004: Runtime, Bindings, and Authorization](../developer/DG-0004-runtime-bindings-and-authorization.md)
- [Authorization contract](../../specs/contracts/authorization_contract.md)
