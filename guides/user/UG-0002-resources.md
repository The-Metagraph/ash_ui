# UG-0002: Working with Ash UI Resources

---
id: UG-0002
title: Working with Ash UI Resources
audience: Application Developers
status: Active
owners: Ash UI Team
last_reviewed: 2026-03-30
next_review: 2026-09-30
related_reqs: [REQ-RES-001, REQ-RES-003, REQ-RES-004, REQ-RES-007]
related_scns: [SCN-001, SCN-003, SCN-004, SCN-005]
related_guides: [UG-0001, UG-0003, UG-0004]
diagram_required: false
---

## Overview

This guide explains the Ash UI resource model. The key distinction is that
applications author screens and elements as Ash resources using
`AshUI.Resource.DSL.*`, while Ash UI also ships storage resources in
`AshUI.Domain` for persistence and backend introspection.

## Prerequisites

Before reading this guide, you should:

- Know how to create and query Ash resources
- Have read [UG-0001: Getting Started](./UG-0001-getting-started.md)
- Know which UI storage backend your application uses

## The Core Resource Roles

Ash UI has two resource layers:

- **authoring resources**: the screen and element resources your app defines with `AshUI.Resource.DSL.Screen` and `AshUI.Resource.DSL.Element`
- **storage resources**: the configured `Screen`, `Element`, and `Binding` backend resources, which default to `AshUI.Resources.Screen`, `AshUI.Resources.Element`, and `AshUI.Resources.Binding`

Most application code should focus on authoring resources and
`AshUI.Resource.Authority`. The shipped storage resources are framework
defaults, not the primary authoring surface.

`AshUI.Data` uses the configured UI storage domain, so persistence helpers stay
stable even when the storage backend changes.

## Screen Resources And Screen Records

The top-level authoring unit is a screen resource module. Persisting it through
`AshUI.Resource.Authority` creates the `Screen` record that Ash UI loads at
runtime.

Important fields:

- `name`: unique identifier used by LiveView integration
- `unified_dsl`: stored snapshot of the composed screen and element graph
- `layout`: layout hint such as `:column` or `:row`
- `route`: optional route string
- `metadata`: free-form metadata
- `active`: soft enablement flag
- `version`: incremented on update

Create a screen by defining a screen resource module and persisting its
authority payload as a regular `Screen` record:

```elixir
alias AshUI.Data, as: Domain
alias AshUI.Resource.Authority
alias AshUI.Resources.Screen

defmodule MyApp.UI.Domain do
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource MyApp.UI.SettingsScreen
    resource MyApp.UI.SettingsHeading
  end
end

defmodule MyApp.UI.SettingsHeading do
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
    type :text
    props %{content: "Settings", size: 24}
    metadata %{id: "settings_heading"}
  end
end

defmodule MyApp.UI.SettingsScreen do
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
    has_many :heading_texts, MyApp.UI.SettingsHeading do
      destination_attribute(:screen_id)
    end
  end

  ui_relationships do
    relationship :heading_texts do
      kind :child
      slot :body
      placement :append
      order 0
    end
  end

  ui_screen do
    route "/settings"
    layout :column
  end
end

{:ok, attrs} =
  Authority.screen_attrs(MyApp.UI.SettingsScreen,
    route: "/settings",
    layout: :column
  )

{:ok, screen} = Domain.create(Screen, attrs: attrs)
```

Do not hand-author raw `unified_dsl` maps in application code. That shape is a
persisted storage snapshot of the resource authority graph, not the primary
authoring surface.

Read a screen by name:

```elixir
{:ok, screen} = Domain.read_one(Screen, filter: [name: "settings"])
```

## Element Resources

Element resources are the atomic authored UI pieces associated with a screen or
parent element. They own widget DSL, local bindings, local actions, and nested
composition relationships.

```elixir
defmodule MyApp.UI.SettingsSaveButton do
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
    type :button
    props %{label: "Save"}
    variants [:primary]
    metadata %{id: "settings_save_button"}
  end

  ui_actions do
    action :save_settings do
      signal :click
      target "click"
      source %{resource: "Settings", action: "save", id: "settings-1"}
      transform %{}
    end
  end
end
```

Important resource-level concerns:

- `ui_element` defines widget type, props, variants, and metadata
- `ui_bindings` declares local data bindings
- `ui_actions` declares local signal-to-action behavior
- Ash relationships plus `ui_relationships` define child and companion composition

## Binding Declarations And Binding Records

Bindings are authored on screens or elements through `ui_screen_bindings` and
`ui_bindings`. Ash UI may still persist normalized binding records in the
configured storage backend, but application code should not treat
`AshUI.Resources.Binding` as the preferred authoring API.

Declare a value binding on the element that owns it:

```elixir
defmodule MyApp.UI.SettingsHeading do
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
    type :text
    props %{content: "Settings", size: 24}
    metadata %{id: "settings_heading"}
  end

  ui_bindings do
    binding :heading_copy do
      source %{resource: "User", field: "name", id: "user-1"}
      target "content"
      binding_type :value
      transform %{}
    end
  end
end
```

## Relationship Patterns

The normative authoring pattern is:

1. express screen composition through Ash relationships between screen and element resources
2. express nested composition through Ash relationships between element resources
3. use `ui_relationships` to define `kind`, `slot`, `placement`, and `order`
4. keep bindings and actions local to the element resource that owns the widget
5. use `Screen.unified_dsl` as persisted compiler storage, not as the hand-authored source of truth
6. reserve screen-level inline DSL for light shell wrappers or layout glue when another resource would be noise

The default storage resources still model Screen/Element/Binding relations, but
those are backend persistence concerns rather than the preferred authoring API.

## UI Storage Versus Binding Source Domains

Keep these two concepts separate:

- `Screen`, `Element`, and `Binding` live in the configured UI storage domain.
- Binding `source` maps point at application resources that may live in entirely different Ash domains.

For example, you can keep UI definitions in ETS-backed resources while bindings read user data from a Postgres-backed application domain.

## Versioning and Updates

Persisted UI storage records increment `version` on update. That matters for:

- compiler cache invalidation
- change tracking
- release-readiness checks

Example update:

```elixir
{:ok, updated_screen} =
  Domain.update(screen,
    attrs: %{
      metadata: Map.put(screen.metadata, "title", "Settings and Profile")
    }
  )
```

## Querying Active Backend Records

If you need to inspect backend storage directly, bindings include a
`read_with_filter` action that only returns active records. For simple
application code, using the domain with a filter keeps intent explicit:

```elixir
active_bindings = Domain.read!(AshUI.Resources.Binding, filter: [screen_id: screen.id, active: true])
```

## Practical Modeling Advice

- Use `name` as the stable human-facing screen identifier.
- Use screen and element relationships as the primary composition language.
- Keep bindings and actions local to the resource that owns the widget.
- Use `unified_dsl` as persisted output, not an authoring shortcut.
- Keep `props` renderer-neutral where possible.
- Treat `metadata` as optional annotations, not core behavior.
- Keep binding `source` maps explicit so authorization and runtime code can inspect them safely.
- Treat `AshUI.Domain` and `AshUI.Resources.*` as defaults, not hard framework requirements.

## See Also

- [UG-0001: Getting Started](./UG-0001-getting-started.md)
- [UG-0003: Data Binding](./UG-0003-data-binding.md)
- [UG-0004: Authorization](./UG-0004-authorization.md)
- [resource_authoring.spec.md](../../.spec/specs/resource_authoring.spec.md)
