# UG-0003: Data Binding in Ash UI

---
id: UG-0003
title: Data Binding in Ash UI
audience: Application Developers
status: Active
owners: Ash UI Team
last_reviewed: 2026-03-30
next_review: 2026-09-30
related_reqs: [REQ-BIND-001, REQ-BIND-002, REQ-BIND-003, REQ-BIND-007, REQ-BIND-008, REQ-BIND-010]
related_scns: [SCN-006, SCN-007, SCN-009, SCN-010, SCN-021, SCN-101]
related_guides: [UG-0001, UG-0002, UG-0004, DG-0003]
diagram_required: false
---

## Overview

This guide explains how Ash UI bindings work today, how to shape `source` and
`target` values, and how runtime helpers read, write, and execute bindings and
actions declared on screen and element resources.

## Prerequisites

Before reading this guide, you should:

- Have read [UG-0001: Getting Started](./UG-0001-getting-started.md)
- Understand the resource model from [UG-0002](./UG-0002-resources.md)
- Be familiar with LiveView events and assigns

## Binding Families

At runtime, Ash UI works with three executable binding families:

- `:value`: a single value for display or form state
- `:list`: a collection-oriented binding
- `:action`: an event-to-action binding

In authoring code:

- `ui_bindings` declares `:value` and `:list` bindings
- `ui_actions` declares signal-driven `:action` behavior

The runtime normalizes both into the execution metadata it assigns on the
socket, and the storage backend may persist normalized `Binding` rows for
inspection or framework use.

## Binding Shape

A binding declaration minimally needs:

```elixir
%{
  id: :display_name,
  binding_type: :value,
  target: "value",
  source: %{"resource" => "User", "field" => "name", "id" => "user-1"}
}
```

Important rules:

- `source` is a map, not a dot-separated string
- `target` is a short renderer-facing target such as `"value"` or `"submit"`
- `transform` may be a list of transformation maps

## Value Bindings

Use `:value` when a field should be read into UI state and potentially written
back.

```elixir
ui_bindings do
  binding :display_name do
    source %{"resource" => "User", "field" => "name", "id" => "user-1"}
    target "value"
    binding_type :value
    transform [
      %{"function" => "trim"},
      %{"function" => "default", "args" => ["Anonymous"]}
    ]
  end
end
```

After compilation and mount, the runtime works with the normalized binding
value rather than the original DSL declaration:

```elixir
binding = socket.assigns.ash_ui_bindings["display_name"]
context = %{user_id: "user-1", params: %{}, assigns: %{}}
{:ok, value} = AshUI.Runtime.BindingEvaluator.evaluate(binding, context)
```

## List Bindings

Use `:list` when the element expects a collection.

```elixir
ui_bindings do
  binding :audit_entries do
    source %{"resource" => "AuditLog", "relationship" => "entries", "id" => "user-1"}
    target "items"
    binding_type :list
    transform %{}
  end
end
```

In the current runtime, list bindings follow the same evaluation path as value
bindings. Keep the source map clear enough that renderer and authorization code
can reason about it.

## Action Declarations

Use `ui_actions` when the UI should trigger an Ash-side operation. This keeps
interactive behavior local to the widget that emits the signal.

```elixir
ui_actions do
  action :save_profile do
    signal :submit
    target "submit"
    source %{"resource" => "Profile", "action" => "save", "id" => "profile-1"}
    transform %{
      "params" => %{
        "display_name" => %{"from" => "event", "key" => "display_name"},
        "actor_id" => %{"from" => "context", "key" => "user_id"}
      }
    }
  end
end
```

Persisted parameter mappings should keep values JSON-safe:

- event values: `%{"from" => "event", "key" => "display_name"}`
- context values: `%{"from" => "context", "key" => "user_id"}`
- static values: `%{"from" => "static", "value" => "Created"}`

Tuple mappings are still accepted for in-memory compatibility, but map-based
mappings are the stable stored format.

Execute an action from the normalized runtime metadata:

```elixir
action = socket.assigns.ash_ui_bindings["save_profile"]
context = %{user_id: "user-1", params: %{}, assigns: %{}}
event_data = %{"display_name" => "Pascal"}

{:ok, result} = AshUI.Runtime.ActionBinding.execute_action(action, event_data, context)
```

## Writing Back To Resources

Bidirectional updates go through `AshUI.Runtime.BidirectionalBinding`.

```elixir
binding = socket.assigns.ash_ui_bindings["display_name"]
context = %{user_id: "user-1", params: %{}, assigns: %{}}

{:ok, socket, result} =
  AshUI.Runtime.BidirectionalBinding.write_binding(binding, "Updated Name", socket, context)
```

Successful writes now return the real Ash update result metadata, including the
updated record and resolved field value.

## Event Handling In LiveView

Event helpers look up normalized bindings and actions in
`socket.assigns[:ash_ui_bindings]`.

```elixir
def handle_event("ash_ui_change", params, socket) do
  AshUI.LiveView.EventHandler.handle_value_change(params, socket)
end

def handle_event("ash_ui_action", params, socket) do
  AshUI.LiveView.EventHandler.handle_action_event(params, socket)
end
```

For these handlers to work smoothly:

- keep `target` values stable
- keep the owning element resource in the screen relationship graph
- assign `:ash_ui_user` and mount through `AshUI.LiveView.Integration`

## Telemetry

Bindings emit canonical telemetry events during evaluation and updates:

- `[:ash_ui, :binding, :evaluate]`
- `[:ash_ui, :binding, :update]`
- `[:ash_ui, :binding, :error]`

You can inspect the aggregated metrics snapshot with:

```elixir
AshUI.Telemetry.snapshot()
```

## Troubleshooting Patterns

### `{:error, {:invalid_source, source}}`

Your `source` is not a map in the expected shape.

### Empty or placeholder values

The runtime now resolves binding data through real Ash reads. If you see empty
values, check authorization, the source map, and whether the owning element
resource is still part of the composed screen graph before assuming the
renderer is broken.

### Writes fail with forbidden errors

Check the current user, active status, and the authorization rules around the
binding source.

## See Also

- [UG-0002: Working with Ash UI Resources](./UG-0002-resources.md)
- [UG-0004: Authorization](./UG-0004-authorization.md)
- [binding_contract.md](../../specs/contracts/binding_contract.md)
- [observability_contract.md](../../specs/contracts/observability_contract.md)
