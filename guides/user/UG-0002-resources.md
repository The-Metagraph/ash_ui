# UG-0002: Working with Ash UI Resources

---
id: UG-0002
title: Working with Ash UI Resources
audience: Application Developers
status: Active
owners: Ash UI Team
last_reviewed: 2026-03-20
next_review: 2026-09-20
related_reqs: [REQ-RES-001, REQ-RES-003, REQ-RES-004, REQ-RES-007]
related_scns: [SCN-001, SCN-003, SCN-004, SCN-005]
related_guides: [UG-0001, UG-0003, UG-0004]
diagram_required: false
---

## Overview

This guide explains the three Ash UI resources you work with directly: screens, elements, and bindings. It focuses on the Ash UI resource contract and the default shipped implementation in `AshUI.Domain`.

## Prerequisites

Before reading this guide, you should:

- Know how to create and query Ash resources
- Have read [UG-0001: Getting Started](./UG-0001-getting-started.md)
- Know which UI storage backend your application uses

## The Core Resources

Ash UI stores UI state as regular Ash records:

- `AshUI.Resources.Screen`
- `AshUI.Resources.Element`
- `AshUI.Resources.Binding`

The shared domain is `AshUI.Domain`, so reads and writes typically go through that module.

That is the default shipped setup. Ash UI can also be configured to use alternate `Screen`, `Element`, and `Binding` resources in a different domain, as long as they satisfy the same contract.

`AshUI.Data` uses the configured UI storage domain, so application code can keep the same CRUD helpers even when the storage backend changes.

## Screen Records

`AshUI.Resources.Screen` is the top-level composition root.

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

## Element Records

`AshUI.Resources.Element` holds the atomic authored UI pieces associated with a
screen or parent element.

Important fields:

- `type`: widget or layout type such as `:text`, `:button`, or `:textinput`
- `props`: renderer-facing properties
- `variants`: style or behavior variants
- `screen_id`: optional top-level screen relationship
- `parent_id`: optional parent element relationship in nested graphs

Create two elements for a screen:

```elixir
alias AshUI.Resources.Element

{:ok, header} =
  Domain.create(Element,
    attrs: %{
      screen_id: screen.id,
      type: :text,
      props: %{"content" => "Settings", "size" => 24},
      position: 0
    }
  )

{:ok, save_button} =
  Domain.create(Element,
    attrs: %{
      screen_id: screen.id,
      type: :button,
      props: %{"label" => "Save"},
      variants: [:primary],
      position: 1
    }
  )
```

## Binding Records

`AshUI.Resources.Binding` connects runtime resources and UI targets.

Important fields:

- `source`: map describing the backing resource field or action
- `target`: target property or event name
- `binding_type`: one of `:value`, `:list`, or `:action`
- `transform`: optional transformation rules
- `element_id`: optional link to an element
- `screen_id`: parent screen

Create a value binding and an action binding:

```elixir
alias AshUI.Resources.Binding

{:ok, _name_binding} =
  Domain.create(Binding,
    attrs: %{
      screen_id: screen.id,
      element_id: header.id,
      binding_type: :value,
      target: "content",
      source: %{"resource" => "User", "field" => "name", "id" => "user-1"}
    }
  )

{:ok, _save_binding} =
  Domain.create(Binding,
    attrs: %{
      screen_id: screen.id,
      element_id: save_button.id,
      binding_type: :action,
      target: "submit",
      source: %{"resource" => "User", "action" => "save"}
    }
  )
```

## Relationship Patterns

The current resource relationships are:

- Screen `has_many :elements`
- Screen `has_many :bindings`
- Element `belongs_to :screen`
- Element `has_many :bindings`
- Binding `belongs_to :screen`
- Binding `belongs_to :element`

The normative pattern is:

1. express screen composition through Ash relationships between screen and element resources
2. keep element-local bindings and actions on the element resource that owns the widget
3. use `Screen.unified_dsl` as persisted compiler storage, not as the hand-authored source of truth
4. reserve screen-level inline DSL for light shell wrappers or layout glue when another resource would be noise

## UI Storage Versus Binding Source Domains

Keep these two concepts separate:

- `Screen`, `Element`, and `Binding` live in the configured UI storage domain.
- Binding `source` maps point at application resources that may live in entirely different Ash domains.

For example, you can keep UI definitions in ETS-backed resources while bindings read user data from a Postgres-backed application domain.

## Versioning and Updates

All three resources increment `version` on update. That matters for:

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

## Querying Active Records

Bindings include a `read_with_filter` action that only returns active records. For simple application code, using the domain with a filter keeps intent explicit:

```elixir
active_bindings = Domain.read!(AshUI.Resources.Binding, filter: [screen_id: screen.id, active: true])
```

## Practical Modeling Advice

- Use `name` as the stable human-facing screen identifier.
- Use screen and element relationships as the primary composition language.
- Use `unified_dsl` as persisted output, not an authoring shortcut.
- Keep `props` renderer-neutral where possible.
- Treat `metadata` as optional annotations, not core behavior.
- Keep binding `source` maps explicit so authorization and runtime code can inspect them safely.
- Treat `AshUI.Domain` and `AshUI.Resources.*` as defaults, not hard framework requirements.

## See Also

- [UG-0001: Getting Started](./UG-0001-getting-started.md)
- [UG-0003: Data Binding](./UG-0003-data-binding.md)
- [UG-0004: Authorization](./UG-0004-authorization.md)
- [resource_contract.md](../../specs/contracts/resource_contract.md)
