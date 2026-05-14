# DesktopUi Documentation

Welcome to the DesktopUi documentation! This library provides native desktop UI capabilities for Elixir applications.

## 📚 Documentation Index

### For Users

Learn how to use DesktopUi to build desktop applications:

1. [Getting Started](user/getting-started.md) - Installation and your first app
2. [Basic Widgets](user/basic-widgets.md) - Text, buttons, icons, layouts
3. [Layout & Composition](user/layout-composition.md) - Building complex layouts
4. [Input & Forms](user/input-forms.md) - Forms and user input
5. [Styling & Theming](user/styling-theming.md) - Customizing appearance
6. [Events & Interactions](user/events-interactions.md) - Handling user actions

### For Developers

Learn about DesktopUi's architecture and contribute to the library:

1. [Architecture Overview](developer/architecture-overview.md) - High-level design
2. [Component Design](developer/component-design.md) - Design patterns
3. [SDL3 Integration](developer/sdl3-integration.md) - Native rendering
4. [IUR Renderer](developer/iur-renderer.md) - Canonical IUR mapping

## Quick Start

```elixir
# Add to deps
{:desktop_ui, "~> 0.1"}

# Create a window
alias DesktopUi.Widgets

screen = %{
  id: "my-app",
  title: "My Application",
  root: Widgets.column("root", [],
    children: [
      Widgets.text("title", "Welcome!"),
      Widgets.button("btn", "Click Me")
    ]
  )
}

# Mount and run
{:ok, state} = DesktopUi.Runtime.mount_native_screen(screen, platform_target: :linux)
```

## Features

- ✅ **45 Native Widgets** - Complete widget coverage
- 🖥️ **Cross-platform** - Windows, macOS, Linux
- 🎨 **Styling** - Semantic colors and themes
- ⌨️ **Keyboard** - Full keyboard navigation
- 📱 **Touch** - Mouse and touch input support
- 🔀 **IUR Renderer** - Canonical cross-runtime compatibility

## Examples

Run example applications:

```bash
# Native example
mix desktop_ui.run native_foundational --linger-ms 5000

# Canonical example
mix desktop_ui.run canonical_foundational --linger-ms 5000

# Advanced operations
mix desktop_ui.run native_advanced_operations --linger-ms 5000
```

## Support

- **Issues**: https://github.com/pcharbon70/unified_ui/issues
- **Discussions**: https://github.com/pcharbon70/unified_ui/discussions
