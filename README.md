# Ash UI

<!-- covers: ash_ui.package.bootstrap_contract -->

Ash UI is a resource-backed UI framework for Elixir built on Ash. Screen and
element Ash resources that use `AshUI.Resource.DSL.*` are the authoritative
authoring units. Their relationships define composition, element-local
bindings and actions define runtime behavior, and Ash UI persists that
authority graph as a `Screen.unified_dsl` snapshot for compilation, rendering,
and runtime orchestration.

## What Works Today

- default shipped `Screen`, `Element`, and `Binding` storage resources in `AshUI.Domain`
- configurable UI storage domain/resource boundary with optional repo startup
- resource-local authoring through `AshUI.Resource.DSL.Screen` and `AshUI.Resource.DSL.Element`
- relationship-driven composition through Ash relationships and `ui_relationships`
- element-local bindings and signal-aware actions through `ui_bindings` and `ui_actions`
- persisted `Screen.unified_dsl` snapshots generated from the authority graph
- compilation to `AshUI.Compilation.IUR` through `AshUI.Compiler`
- canonical conversion through `AshUI.Rendering.IURAdapter`
- LiveView mount, event, and update integration helpers
- runtime authorization policies and checks
- normalized telemetry events, in-memory metrics, and dashboard definitions
- a checked-in `examples/` suite that mirrors the sibling `unified_ui/examples`
  catalog through standalone Ash UI apps

## Architecture at a Glance

```mermaid
flowchart LR
    Resources["Screen + element resources"]
    Authority["AshUI.Resource.Authority"]
    Snapshot["Screen record + unified_dsl snapshot"]
    Compiler["AshUI.Compiler"]
    IUR["Ash UI IUR"]
    Canonical["canonical IUR"]
    Runtime["LiveView runtime"]
    Renderers["renderer adapters"]

    Resources --> Authority
    Authority --> Snapshot
    Resources --> Compiler
    Snapshot --> Compiler
    Compiler --> IUR
    IUR --> Canonical
    Canonical --> Renderers
    Canonical --> Runtime
```

## Example Suite

Ash UI now ships a maintained example suite under [examples/README.md](./examples/README.md).
It mirrors the sibling `unified_ui/examples` directory names so reviews can stay
catalog-stable across packages, but every checked-in Ash UI example is rebuilt
through screen and element resources plus `AshUI.Resource.Authority`.

That means the suite is intentionally not a one-for-one copy of upstream
authoring semantics:

- directory parity is stable, even when the canonical Ash UI subject is normalized
- canonical type normalization currently includes `text_input -> input`,
  `radio_group -> radio`, `toggle -> switch`, and `separator -> divider`
- some directories remain explicit `custom:*` or composed review surfaces until
  Ash UI exposes a stable public widget contract for them

From the repo root, maintainers can work the suite through:

- `mix ash_ui.examples.list`
- `mix ash_ui.examples.preview <directory>`
- `mix ash_ui.examples.start <directory> --dry-run`
- `mix ash_ui.examples.validate`
- `mix ash_ui.examples.report`

The shared visual contract for every checked-in app is defined in
[examples/ash_hq_theme_baseline.md](./examples/ash_hq_theme_baseline.md). Each
app vendors that Ash HQ-derived shell locally instead of depending on a shared
runtime package.

## Quick Start

Add the core dependencies:

```elixir
defp deps do
  [
    {:ash_ui, "~> 0.1.0"},
    {:ash, "~> 3.0"},
    {:ash_postgres, "~> 2.0"},
    {:phoenix_live_view, "~> 1.0"},
    {:telemetry, "~> 1.0"}
  ]
end
```

Ash UI now treats Ash resource modules that use `AshUI.Resource.DSL.*` as the
authoritative authoring surface. `unified_ui` still matters because it owns the
shared widget and layout grammar under the hood, but application code should
model screens and elements as Ash resources rather than authoring a detached
screen document.

Define a screen resource and related element resources, then persist the
composed graph through Ash UI:

```elixir
defmodule MyApp.UI.Domain do
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource MyApp.UI.DashboardScreen
    resource MyApp.UI.DashboardHero
    resource MyApp.UI.RefreshButton
  end
end

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
      eyebrow: "Resource-first example",
      title: "Dashboard",
      message: "This hero is authored as an Ash element resource."
    }
    metadata %{id: "dashboard_hero"}
  end

  ui_bindings do
    binding :hero_message do
      source %{resource: "Dashboard", field: "summary", id: "dashboard-1"}
      target "message"
      binding_type :value
      transform %{}
    end
  end
end

defmodule MyApp.UI.RefreshButton do
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
    props %{label: "Refresh"}
    metadata %{id: "refresh_button"}
  end

  ui_actions do
    action :refresh_dashboard do
      signal :click
      source %{resource: "Dashboard", action: "refresh", id: "dashboard-1"}
      target "click"
    end
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

    has_many :buttons, MyApp.UI.RefreshButton do
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

    relationship :buttons do
      kind :companion
      slot :actions
      placement :append
      order 1
    end
  end

  ui_screen do
    route "/dashboard"
    layout :column
    metadata %{"owner" => "platform"}
  end
end

{:ok, _screen} =
  AshUI.Resource.Authority.create(MyApp.UI.DashboardScreen,
    route: "/dashboard",
    layout: :column,
    metadata: %{"owner" => "platform"}
  )
```

The compiler now treats that relational authority graph as the primary source
of composition. `Screen.unified_dsl` is a persisted snapshot of the screen and
element graph, not a hand-authored monolithic document. Bindings and actions
belong on the element resource that owns the widget, while screen-level inline
DSL should be limited to tiny shell fragments where another resource would add
more noise than clarity.

Older pre-v1 payloads are no longer accepted at runtime. If you are migrating
existing data, use the one-time migration flow documented in
[UG-0008](./guides/user/UG-0008-migration-from-older-ash-ui-models.md) before persisting the
resource-authority payload.

The default shipped storage backend is Postgres through `AshUI.Domain` and
`AshUI.Repo`, but the UI storage domain and resource modules are configurable
so example apps and alternate deployments can use another Ash-compatible data
layer. Those storage resources are framework persistence defaults, not the
recommended application authoring surface.

Mount it in LiveView:

```elixir
defmodule MyAppWeb.DashboardLive do
  use MyAppWeb, :live_view

  alias AshUI.LiveView.Integration

  def mount(_params, _session, socket) do
    socket = assign(socket, :current_user, %{id: "admin-1", role: :admin, active: true})
    Integration.mount_ui_screen(socket, :dashboard, %{})
  end
end
```

## Renderer Status

Ash UI owns the compiler, runtime, and adapter boundary. Architecturally, the unified ecosystem renderer set is now `unified_iur`, `live_ui`, `elm_ui`, and `desktop_ui`.

The repository vendors minimal `unified_ui`, `unified_iur`, `live_ui`, `elm_ui`, and `desktop_ui` packages under `packages/`. `unified_ui` is required because it owns the authored DSL and authoring compiler surface. `unified_iur` is required because it defines the canonical schema boundary Ash UI produces and validates. The renderer packages remain optional path dependencies, and adapter fallbacks still exist for degraded environments.

## Documentation

- [User guides](./guides/user/README.md)
- [Developer guides](./guides/developer/README.md)
- [Guide index](./guides/README.md)
- [Specifications](./specs/README.md)
- [RFCs](./rfcs/README.md)

Key starting points:

- [UG-0001: Getting Started with AshUI](./guides/user/UG-0001-getting-started.md)
- [DG-0001: Architecture and Control Planes](./guides/developer/DG-0001-architecture-and-control-planes.md)

## Current Status

Phase 8 governance work is complete, and the runtime stack now includes real Ash-backed binding execution, authorization, LiveView reactivity, compile-time resource DSL helpers, and vendored renderer package integration.

## Development Notes

- compiler cache lives in ETS and is initialized at application start
- authorization runtime also uses ETS-backed caching
- telemetry events are aggregated through `AshUI.Telemetry.snapshot/0`
- dashboard definitions live in `priv/monitoring/dashboards/`

## License

[License to be determined]
