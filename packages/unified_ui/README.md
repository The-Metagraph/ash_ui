# UnifiedUi

`UnifiedUi` is the authored DSL and compiler package for the unified ecosystem.

The package is intentionally a pure Elixir library. It owns:

- the authored DSL surface
- canonical signal and binding authoring
- compilation into canonical `UnifiedIUR`
- package reference, inspection, and tooling helpers

The package does not own renderer runtimes, renderer-specific widget trees, or
required long-lived runtime services.

## Package Model

`UnifiedUi` is the single authored boundary for the ecosystem:

- authors describe widgets, layouts, display systems, themes, and canonical signals here
- the compiler lowers authored modules into canonical `UnifiedIUR`
- runtime libraries such as `live_ui`, `elm_ui`, and `desktop_ui` are downstream consumers of the canonical output, not alternative authoring surfaces

The package is designed to stay renderer-agnostic. If a change would introduce
renderer-local concepts into authored modules, that change is outside the
package contract.

## Main Areas

- `UnifiedUi.Dsl`: Spark-backed authored DSL sections and entities
- `UnifiedUi.Compiler`: canonical lowering into `UnifiedIUR`
- `UnifiedUi.Info` and `UnifiedUi.Reference`: authored-surface introspection and package reference data
- `UnifiedUi.Examples`: maintained authored examples used for docs, review, and validation
- `UnifiedUi.Tooling`: maintainer workflows for inspection, export, diagnostics, and validation

## Maintainer Commands

Run these commands from `packages/unified-ui`:

```bash
mix test
mix unified_ui.inspect --example foundational_screen
mix unified_ui.export --example themed_signal_workspace --format snapshot
mix unified_ui.validate
```

## User Guides

- [Documentation Index](./docs/README.md)
- [Getting Started](./docs/user/getting-started.md)
- [Widget Catalog](./docs/user/widget-catalog.md)
- [Layouts, Layers, and Display](./docs/user/layouts-layers-and-display.md)
- [Styling and Themes](./docs/user/styling-and-themes.md)
- [Bindings and Interactions](./docs/user/bindings-and-interactions.md)

## Developer Guides

- [Architecture Overview](./docs/developer/architecture-overview.md)
- [DSL Section Model](./docs/developer/dsl-section-model.md)
- [Compilation Pipeline](./docs/developer/compilation-pipeline.md)
- [Package Components](./docs/developer/package-components.md)

## Maintainer Guides

- [DSL Model](./guides/dsl_model.md)
- [Theming and Signals](./guides/theming_and_signals.md)
- [Compiler and Parity](./guides/compiler_and_parity.md)
- [Maintainer Workflows](./guides/maintainer_workflows.md)
