# Getting Started with UnifiedUi

`UnifiedUi` is the authored DSL for the unified ecosystem. It is where you
describe UI intent once, in Elixir, before compiling that description into
canonical `UnifiedIUR`.

`UnifiedUi` does not render the screen itself. Its job is to:

- define a stable authored model
- validate that authored model at compile time
- compile the result into canonical `UnifiedIUR`
- expose inspection and validation helpers for review

## The Authoring Model

A `UnifiedUi` module is organized around up to four top-level sections:

- `identity`: stable ids, titles, tags, and authored traceability
- `composition`: widgets, layout, overlays, display systems, and canvas
- `themes`: reusable palette colors, semantic roles, tokens, and component styles
- `signals`: canonical bindings and interactions

For many screens, `identity` and `composition` are enough to get started.

## First Screen

```elixir
defmodule MyApp.WelcomeScreen do
  use UnifiedUi.Dsl

  identity do
    id(:welcome_screen)
    title("Welcome")
    authored_ref([:my_app, :welcome_screen])
    tags([:user_guide, :welcome])
  end

  composition do
    root(:welcome_screen_root)
    mode(:screen)

    column :page do
      gap(:md)

      text :headline do
        value("Welcome to UnifiedUi")
      end

      text :summary do
        value("Author once, compile to canonical UnifiedIUR, render later.")
      end

      button :continue_button do
        label("Continue")
        action_intent(:continue)
      end
    end
  end
end
```

## Compile the Module

Use the compiler directly from Elixir:

```elixir
alias UnifiedUi.Compiler

summary = UnifiedUi.Compiler.summary(MyApp.WelcomeScreen)
iur = UnifiedUi.Compiler.iur!(MyApp.WelcomeScreen)
inspection = UnifiedUi.Compiler.render_inspection(MyApp.WelcomeScreen)
```

Those entrypoints let you:

- inspect authored ids and section usage
- review compiled widget, layout, theme, binding, and interaction output
- hand canonical `UnifiedIUR` to a runtime package later

## Shared Authoring Rules

`UnifiedUi` enforces a few important invariants:

- every module must declare `identity`
- every module with `composition` must declare a `root`
- `identity.id` and `composition.root` must both exist and must differ
- renderer-local callbacks and payload shapes do not belong in the DSL
- invalid placement, theme refs, interaction refs, and binding refs fail early

That early validation is the point: authored mistakes are rejected before
runtime packages ever see the screen.

## Use the Maintained Reference Modules

The package ships stable reference modules under `UnifiedUi.Examples`:

- `foundational_screen`
- `profile_form`
- `overlay_workspace`
- `operations_dashboard`
- `themed_signal_workspace`

Inspect them from `packages/unified-ui`:

```bash
mix unified_ui.inspect --example foundational_screen
mix unified_ui.export --example operations_dashboard --format snapshot
mix unified_ui.export --example themed_signal_workspace --format signals
```

## What Comes Next

Once the basic shape makes sense, continue with:

- [Widget Catalog](widget-catalog.md)
- [Layouts, Layers, and Display](layouts-layers-and-display.md)
- [Styling and Themes](styling-and-themes.md)
- [Bindings and Interactions](bindings-and-interactions.md)
