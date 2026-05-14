# UnifiedUi Documentation

`UnifiedUi` is the authored UI DSL for the unified ecosystem. You use it to
declare screens, fragments, widgets, layout, themes, bindings, and
interactions in a renderer-independent model, then compile that authored module
into canonical `UnifiedIUR`.

## User Guides

Start here if you want to author UI modules with `UnifiedUi`:

1. [Getting Started](user/getting-started.md)
2. [Widget Catalog](user/widget-catalog.md)
3. [Layouts, Layers, and Display](user/layouts-layers-and-display.md)
4. [Styling and Themes](user/styling-and-themes.md)
5. [Bindings and Interactions](user/bindings-and-interactions.md)
6. [Canonical Navigation](user/canonical-navigation.md)

## Developer Guides

Start here if you are changing `UnifiedUi` itself or integrating against its
internal package model:

1. [Architecture Overview](developer/architecture-overview.md)
2. [DSL Section Model](developer/dsl-section-model.md)
3. [Compilation Pipeline](developer/compilation-pipeline.md)
4. [Package Components](developer/package-components.md)
5. [Canonical Navigation Internals](developer/canonical-navigation.md)

## Maintainer Guides

Use these when you are evolving the package itself:

1. [DSL Model](../guides/dsl_model.md)
2. [Theming and Signals](../guides/theming_and_signals.md)
3. [Compiler and Parity](../guides/compiler_and_parity.md)
4. [Maintainer Workflows](../guides/maintainer_workflows.md)

## Quick Path

The usual authoring loop is:

1. Define a module with `use UnifiedUi.Dsl`
2. Declare `identity`, `composition`, and optional `themes` / `signals`
3. Compile the module with `UnifiedUi.Compiler`
4. Hand the resulting canonical `UnifiedIUR` to a runtime package such as
   `live_ui`, `elm_ui`, `desktop_ui`, or `terminal_ui`

Useful package-local commands:

```bash
mix unified_ui.inspect --example foundational_screen
mix unified_ui.export --example themed_signal_workspace --format snapshot
mix unified_ui.validate
```
