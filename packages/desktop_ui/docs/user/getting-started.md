# Getting Started with DesktopUi

Welcome to DesktopUi! This guide will help you get started building native desktop applications in Elixir.

## What is DesktopUi?

DesktopUi is an Elixir package for building native desktop applications with:
- **Native widgets**: Windows, buttons, inputs, tables, and more
- **Cross-platform**: Runs on Windows, macOS, and Linux
- **Declarative UI**: Build interfaces with Elixir code
- **Interactive**: Handle keyboard, mouse, and touch input
- **Styled**: Built-in theming and customization

## Installation

Add `desktop_ui` to your dependencies in `mix.exs`:

```elixir
defp deps do
  [
    {:desktop_ui, "~> 0.1"}
  ]
end
```

Then run:

```bash
mix deps.get
mix compile
```

## Your First DesktopUi App

Let's create a simple "Hello, World!" application:

```elixir
# lib/my_app.ex
defmodule MyApp do
  alias DesktopUi.Widgets

  def main do
    # Create a window with a simple message
    screen = %{
      id: "hello-screen",
      title: "Hello DesktopUi",
      root: Widgets.column("root", [],
        gap: 16,
        children: [
          Widgets.text("title", "Welcome to DesktopUi!"),
          Widgets.button("btn", "Click Me")
        ]
      )
    }

    # Mount and run the screen
    {:ok, state} = DesktopUi.Runtime.mount_native_screen(screen, platform_target: :linux)
    {:ok, _plan} = DesktopUi.Sdl3.RenderPlan.build(state)

    # Keep the process alive
    Process.sleep(:infinity)
  end
end
```

Run it with:

```bash
mix run --no-halt -e "MyApp.main()"
```

## Building a Real Application

### Screen Structure

Every DesktopUi application starts with a **screen**:

```elixir
screen = %{
  id: "my-app-screen",        # Unique screen identifier
  title: "My Application",     # Window title
  root: widget_tree           # Root widget
}
```

### Basic Layouts

Use layout widgets to arrange your interface:

```elixir
# Column layout (vertical stacking)
Widgets.column("main", [],
  gap: 8,
  children: [
    Widgets.text("title", "Dashboard"),
    Widgets.button("refresh", "Refresh Data")
  ]
)

# Row layout (horizontal arrangement)
Widgets.row("toolbar", [],
  gap: 8,
  children: [
    Widgets.button("save", "Save"),
    Widgets.button("cancel", "Cancel")
  ]
)

# Stack layout (overlapping widgets)
Widgets.stack("overlay", [],
  children: [
    Widgets.content("main", []),
    Widgets.dialog("confirm", [], open: true)
  ]
)
```

### Adding Interactivity

Make your app interactive with events:

```elixir
Widgets.button("greet", "Say Hello",
  on_click: fn event ->
    IO.puts("Hello from #{event.widget_id}!")
    :ok
  end
)
```

## Common Widgets

### Text and Labels

```elixir
# Display text
Widgets.text("greeting", "Hello, World!")

# Styled label
Widgets.label("title", "Welcome",
  styles: %{size: :lg, variant: :primary}
)
```

### Buttons

```elixir
# Simple button
Widgets.button("click-me", "Click Me")

# Button with options
Widgets.button("submit", "Save Changes",
  variant: :primary,
  size: :lg,
  disabled: false
)

# Icon button
Widgets.button("settings", "",
  icon: :settings,
  on_click: &open_settings/1
)
```

### Input Fields

```elixir
# Text input
Widgets.text_input("username",
  placeholder: "Enter username",
  binding: {:form, :username}
)

# Numeric input
Widgets.numeric_input("age",
  value: 25,
  min: 0,
  max: 120
)

# Checkbox
Widgets.checkbox("agree", "I agree to terms",
  checked: false,
  binding: {:form, :agreed}
)

# Select dropdown
Widgets.select("role",
  options: [
    [label: "Admin", value: "admin"],
    [label: "User", value: "user"]
  ]
)
```

### Data Display

```elixir
# Table
Widgets.table("users",
  columns: [
    [key: :name, label: "Name"],
    [key: :email, label: "Email"]
  ],
  rows: [
    %{name: "Alice", email: "alice@example.com"},
    %{name: "Bob", email: "bob@example.com"}
  ]
)

# Stat card
Widgets.stat("user-count",
  value: 1234,
  label: "Total Users",
  trend: :up
)
```

## Styling Your App

### Semantic Colors

```elixir
Widgets.button("primary", "Save",
  styles: %{variant: :primary}    # primary, secondary, accent, muted
)

Widgets.button("success", "Complete",
  styles: %{variant: :success}    # success, warning, error
)
```

### Custom Colors

```elixir
Widgets.button("custom", "Custom",
  styles: %{
    bg: "#3b82f6",      # Background color
    fg: "#ffffff",      # Foreground (text) color
    border: "#1d4ed8"   # Border color
  }
)
```

### Widget Sizes

```elixir
Widgets.button("small", "Small", styles: %{size: :sm})
Widgets.button("medium", "Medium", styles: %{size: :md})
Widgets.button("large", "Large", styles: %{size: :lg})
```

## Handling Events

### Event Types

```elixir
# Click events
Widgets.button("btn", "Click",
  on_click: fn %{widget_id: id} ->
    IO.puts("Button #{id} clicked!")
  end
)

# Change events (inputs)
Widgets.text_input("search",
  on_change: fn %{value: text} ->
    MyApp.Search.perform(text)
  end
)

# Selection events
Widgets.list("items",
  items: items,
  on_select: fn %{selected: item} ->
    MyApp.show_item(item)
  end
)
```

### Intents

For common actions, use intents:

```elixir
Widgets.button("save", "Save",
  on_click: %{intent: :save_form}
)

Widgets.button("close", "Close",
  on_click: %{intent: :close_dialog}
)
```

## Running Your App

### Interactive Mode

```bash
# From your project directory
cd my_app

# Run with visible window
mix desktop_ui.run native_foundational --linger-ms 10000
```

### Production Mode

```elixir
# In your application.ex
defmodule MyApp.Application do
  def start(_type, _args) do
    children = [
      # ... other children ...
      {DesktopUi.Runtime, screens: MyApp.screens()}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## Next Steps

- [Basic Widgets](./basic-widgets.md) - Learn about all available widgets
- [Layout & Composition](./layout-composition.md) - Build complex interfaces
- [Input & Forms](./input-forms.md) - Handle user input
- [Styling & Theming](./styling-theming.md) - Customize your app's appearance
- [Events & Interactions](./events-interactions.md) - Make your app interactive

## Quick Reference

```elixir
# Window
Widgets.window("id", "Title", [children])

# Layouts
Widgets.column("id", children, opts)
Widgets.row("id", children, opts)

# Content
Widgets.text("id", "content")
Widgets.label("id", "text")
Widgets.icon("id", :icon_name)

# Actions
Widgets.button("id", "label")
Widgets.toggle("id", "label")
Widgets.link("id", "text", "/path")

# Inputs
Widgets.text_input("id", opts)
Widgets.numeric_input("id", opts)
Widgets.checkbox("id", "label", opts)
Widgets.select("id", options, opts)

# Display
Widgets.table("id", columns, rows)
Widgets.stat("id", value:, label:)
```
