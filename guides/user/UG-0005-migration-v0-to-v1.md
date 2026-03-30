# UG-0005: Migration Guide from v0 to v1

---
id: UG-0005
title: Migration Guide from v0 to v1
audience: Application Developers
status: Active
owners: Ash UI Team
last_reviewed: 2026-03-30
next_review: 2026-09-30
related_reqs: [REQ-RES-001, REQ-COMP-001, REQ-RENDER-001, REQ-AUTH-002]
related_scns: [SCN-004, SCN-041, SCN-061, SCN-081]
related_guides: [UG-0001, UG-0002, UG-0003, DG-0004]
diagram_required: false
---

## Overview

This guide helps teams move from earlier Ash UI prototypes and detours into the
current v1 shape implemented in this repository: screen resources, element
resources, relationship-driven composition, and element-local bindings and
actions.

## Prerequisites

Before reading this guide, you should:

- Know which Ash UI examples or prototypes your app copied from
- Be comfortable updating Elixir modules and persisted records
- Have read [UG-0001: Getting Started](./UG-0001-getting-started.md)

## What Changed in v1

The biggest changes are:

- application authoring now centers on screen and element resources using `AshUI.Resource.DSL.*`
- screen structure is composed through Ash relationships plus `ui_relationships`
- bindings and actions live on the resource that owns the widget
- `Screen.unified_dsl` is a persisted snapshot of the authority graph, not a hand-authored document
- the main compiler entry point is `AshUI.Compiler`
- LiveView integration goes through `AshUI.LiveView.Integration`
- authorization and telemetry are first-class runtime concerns

## Old to New Mapping

| earlier style | v1 style |
|---|---|
| detached screen document or oversized screen module | screen resource plus related element resources |
| screen-local piles of bindings and actions | `ui_bindings` and `ui_actions` on the owning element resource |
| implicit layout by source order alone | explicit Ash relationships plus `ui_relationships` |
| string-based binding examples | map-based `source` values |
| direct rendering assumptions | compile to Ash IUR, then convert to canonical IUR |
| implicit test/dev auth bypass | explicit `:runtime_authorization_bypass` config |

## Step 1: Inventory The Old Screen

If you previously modeled a screen as one large module or detached payload,
start by breaking it into:

- one screen resource that owns route, layout, metadata, and any tiny shell fragment
- one element resource per meaningful widget or reusable UI fragment
- one set of composition relationships between those resources

Treat the old payload as source material only. Ash UI no longer accepts it as a
preferred runtime authoring model.

## Step 2: Move Structure Into Screen And Element Resources

```elixir
defmodule MyApp.UI.DashboardHero do
  use Ash.Resource, domain: MyApp.UI.Domain, data_layer: Ash.DataLayer.Ets
  use AshUI.Resource.DSL.Element

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:screen_id, :uuid, allow_nil?: true)
    attribute(:parent_id, :uuid, allow_nil?: true)
  end

  actions do
    defaults([:read])
  end

  ui_element do
    type :hero
    props %{
      eyebrow: "Operations",
      title: "Dashboard",
      message: "Migrated onto screen and element resources."
    }
    metadata %{id: "dashboard_hero"}
  end
end

defmodule MyApp.UI.DashboardScreen do
  use Ash.Resource, domain: MyApp.UI.Domain, data_layer: Ash.DataLayer.Ets
  use AshUI.Resource.DSL.Screen

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read])
  end

  relationships do
    has_many :hero_elements, MyApp.UI.DashboardHero do
      destination_attribute(:screen_id)
    end
  end

  ui_relationships do
    relationship :hero_elements do
      kind :child
      slot :body
      placement :append
      order 0
    end
  end

  ui_screen do
    route "/dashboard"
    layout :column
  end
end
```

## Step 3: Move Bindings And Actions To The Owning Element

Replace older source strings like `"User.name"` or `"MyApp.User.create"` with explicit source maps.

Before:

```elixir
%{source: "User.name"}
```

After:

```elixir
%{source: %{"resource" => "User", "field" => "name"}}
```

Value binding example:

```elixir
ui_bindings do
  binding :display_name do
    source %{resource: "User", field: "name", id: "user-1"}
    target "value"
    binding_type :value
    transform %{}
  end
end
```

Action example:

```elixir
ui_actions do
  action :save_profile do
    signal :submit
    target "submit"
    source %{resource: "User", action: "save_profile", id: "user-1"}
    transform %{
      "params" => %{
        "display_name" => %{"from" => "event", "key" => "display_name"}
      }
    }
  end
end
```

Screen-level bindings should be rare and reserved for shell-wide concerns.

## Step 4: Persist A Fresh Screen Record

Persist the new resource graph through `AshUI.Resource.Authority`. Do not carry
forward detached screen documents or builder payloads.

```elixir
{:ok, _screen} =
  AshUI.Resource.Authority.create(MyApp.UI.DashboardScreen,
    route: "/dashboard",
    layout: :column
  )
```

If your app still has stale `Screen` rows that were generated from the
superseded model, replace them with freshly persisted resource-authority
records before continuing.

## Step 5: Update LiveView Mounts

Replace placeholder helpers or custom ad-hoc loaders with the real integration
module.

```elixir
alias AshUI.LiveView.Integration

def mount(_params, _session, socket) do
  socket = assign(socket, :current_user, %{id: "admin-1", role: :admin, active: true})
  Integration.mount_ui_screen(socket, :dashboard, %{})
end
```

## Step 6: Expect Canonical IUR At The Boundary

In v1, the stable renderer boundary is canonical IUR. If you had custom
rendering hooks that expected raw resource structs or detached screen
documents, move them to consume:

- `AshUI.Compilation.IUR` internally
- canonical maps produced by `AshUI.Rendering.IURAdapter`

## Step 7: Revisit Authorization Assumptions

If earlier prototypes relied on tests or development mode implicitly allowing access, switch to explicit user data and explicit bypass configuration when needed.

```elixir
config :ash_ui, :runtime_authorization_bypass, false
```

## Step 8: Validate The Migration

Run focused verification after moving each screen:

```bash
mix test test/ash_ui/compiler_test.exs
mix test test/ash_ui/liveview/liveview_integration_test.exs
mix test test/ash_ui/authorization/runtime_test.exs
```

## Migration Checklist

- split old screens into screen resources and related element resources
- move bindings and actions onto the owning element resource
- express composition through Ash relationships plus `ui_relationships`
- convert binding sources to maps
- persist new screen definitions through `AshUI.Resource.Authority`
- replace stale detached screen records with fresh resource-authority records
- mount via `AshUI.LiveView.Integration`
- verify `:current_user` is assigned
- confirm telemetry and authorization behavior in the target environment

## See Also

- [UG-0001: Getting Started](./UG-0001-getting-started.md)
- [UG-0003: Data Binding](./UG-0003-data-binding.md)
- [DG-0004: Release Process](../developer/DG-0004-release-process.md)
- [phase-08-governance-gates-and-release-readiness.md](../../specs/planning/phase-08-governance-gates-and-release-readiness.md)
