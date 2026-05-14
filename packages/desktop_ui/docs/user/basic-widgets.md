# Basic Widgets

This guide covers the foundational widgets available in DesktopUi for building user interfaces.

## Table of Contents
1. [Text & Typography](#text--typography)
2. [Buttons & Actions](#buttons--actions)
3. [Icons & Images](#icons--images)
4. [Layout Containers](#layout-containers)
5. [Separators & Spacers](#separators--spacers)

## Text & Typography

### Text Widget

Display plain text content:

```elixir
Widgets.text("greeting", "Hello, World!")

# With styling
Widgets.text("title", "Welcome!",
  styles: %{
    size: :xl,
    variant: :primary
  }
)
```

### Label Widget

Labels for form fields and annotations:

```elixir
Widgets.label("username-label", "Username:")

# With association
Widgets.label("password-label", "Password:",
  for: "password-input"
)
```

### Hero Widget

Large promotional headers:

```elixir
Widgets.hero("welcome", "Welcome to MyApp",
  subheadline: "The best way to manage your data",
  actions: [
    %{label: "Get Started", intent: :signup},
    %{label: "Learn More", href: "/docs"}
  ]
)
```

### Badge Widget

Status indicators and labels:

```elixir
# Default badge
Widgets.badge("status", "New")

# Color variants
Widgets.badge("success", "Complete", variant: :success)
Widgets.badge("warning", "Pending", variant: :warning)
Widgets.badge("error", "Failed", variant: :error)

# Size variants
Widgets.badge("small", "SM", size: :sm)
Widgets.badge("large", "LG", size: :lg)
```

## Buttons & Actions

### Button Widget

The primary action widget:

```elixir
# Simple button
Widgets.button("submit", "Submit")

# With variant
Widgets.button("primary", "Save", variant: :primary)
Widgets.button("secondary", "Cancel", variant: :secondary)
Widgets.button("danger", "Delete", variant: :error)

# With size
Widgets.button("large", "Click Me", size: :lg)

# Disabled
Widgets.button("disabled", "Can't Click", disabled: true)

# With icon
Widgets.button("settings", "",
  icon: :gear,
  label: "Settings"
)

# Click handler
Widgets.button("click", "Click Me",
  on_click: fn event ->
    IO.puts("Clicked: #{event.widget_id}")
  end
)
```

### Toggle Widget

On/off switch:

```elixir
Widgets.toggle("dark-mode", "Dark Mode",
  checked: false,
  on_change: fn %{checked: enabled?} ->
    MyApp.Theme.set_dark_mode(enabled?)
  end
)
```

### Link Widget

Navigation links:

```elixir
Widgets.link("docs", "Documentation",
  href: "/docs"
)

# With external target
Widgets.link("external", "Visit Site",
  href: "https://example.com",
  target: "_blank"
)
```

### Command Widget

Command palette items:

```elixir
Widgets.command("save", "Save File",
  shortcut: "Cmd+S",
  intent: :save
)
```

## Icons & Images

### Icon Widget

Display icons:

```elixir
# Named icon
Widgets.icon("settings", :gear)

# With fallback text
Widgets.icon("logo", :company_logo,
  fallback_text: "[Logo]"
)

# Styled
Widgets.icon("large-icon", :star,
  styles: %{size: :xl}
)
```

Available icons include:
- `:gear`, `:settings`, `:config`
- `:star`, `:heart`, `:bookmark`
- `:home`, `:folder`, `:file`
- `:search`, `:filter`, `:sort`
- `:check`, `:close`, `:plus`, `:minus`
- And many more...

### Image Widget

Display images:

```elixir
# From URL
Widgets.image("logo", "/assets/logo.png")

# With alt text
Widgets.image("photo", "/uploads/photo.jpg",
  alt: "Vacation photo"
)

# With sizing
Widgets.image("thumbnail", "/image.jpg",
  styles: %{width: 100, height: 100}
)
```

## Layout Containers

### Column Widget

Vertical layout:

```elixir
Widgets.column("main", [],
  gap: 16,
  children: [
    Widgets.text("title", "Header"),
    Widgets.text("body", "Content goes here..."),
    Widgets.button("action", "Click")
  ]
)

# With alignment
Widgets.column("sidebar", [],
  gap: 8,
  align: :start,      # :start, :center, :end, :stretch
  justify: :start,    # :start, :center, :end, :space_between
  children: [...]
)
```

### Row Widget

Horizontal layout:

```elixir
Widgets.row("toolbar", [],
  gap: 8,
  children: [
    Widgets.button("save", "Save"),
    Widgets.button("cancel", "Cancel")
  ]
)

# With alignment
Widgets.row("header", [],
  gap: 16,
  align: :center,
  justify: :space_between,
  children: [
    Widgets.text("title", "My App"),
    Widgets.button("settings", "", icon: :gear)
  ]
)
```

### Stack Widget

Overlapping widgets:

```elixir
Widgets.stack("overlay", [],
  children: [
    Widgets.content("main", []),
    Widgets.toast("notification", "Saved!")
  ]
)
```

### Content Widget

Generic container:

```elixir
Widgets.content("panel", [],
  styles: %{bg: "muted"},
  children: [
    Widgets.text("title", "Panel Title"),
    Widgets.text("body", "Panel content")
  ]
)
```

### Window Widget

Top-level window:

```elixir
Widgets.window("main", "My Application",
  children: [
    Widgets.column("root", [],
      children: [
        Widgets.text("title", "Welcome!"),
        Widgets.button("btn", "Click Me")
      ]
    )
  ]
)
```

## Separators & Spacers

### Separator Widget

Visual dividers:

```elixir
# Horizontal separator
Widgets.separator("sep-1", orientation: :horizontal)

# Vertical separator
Widgets.separator("sep-2", orientation: :vertical)

# Styled
Widgets.separator("strong", orientation: :horizontal,
  styles: %{variant: :strong}
)
```

### Spacer Widget

Fixed or flexible spacing:

```elixir
# Fixed size spacer
Widgets.spacer("gap-8", size: :sm)   # 8px
Widgets.spacer("gap-16", size: :md)  # 16px
Widgets.spacer("gap-32", size: :lg)  # 32px

# In a row
Widgets.row("items", [],
  children: [
    Widgets.text("a", "Item A"),
    Widgets.spacer("spacer", []),
    Widgets.text("b", "Item B")
  ]
)
```

## Complete Example

Here's a complete example using basic widgets:

```elixir
defmodule MyApp.Screens.Home do
  alias DesktopUi.Widgets

  def screen do
    %{
      id: "home-screen",
      title: "MyApp - Home",
      root: layout()
    }
  end

  defp layout do
    Widgets.column("root", [],
      gap: 24,
      children: [
        header(),
        hero_section(),
        actions_section(),
        footer()
      ]
    )
  end

  defp header do
    Widgets.row("header", [],
      gap: 16,
      justify: :space_between,
      align: :center,
      children: [
        Widgets.text("logo", "MyApp"),
        Widgets.row("nav", [],
          gap: 8,
          children: [
            Widgets.link("home", "Home", "/"),
            Widgets.link("docs", "Docs", "/docs"),
            Widgets.link("about", "About", "/about")
          ]
        )
      ]
    )
  end

  defp hero_section do
    Widgets.hero("hero", "Build Desktop Apps in Elixir",
      subheadline: "Native, fast, and beautiful",
      actions: [
        %{label: "Get Started", intent: :signup},
        %{label: "View Docs", href: "/docs"}
      ]
    )
  end

  defp actions_section do
    Widgets.row("actions", [],
      gap: 16,
      children: [
        Widgets.button("primary", "Get Started",
          variant: :primary,
          size: :lg
        ),
        Widgets.button("secondary", "Learn More")
      ]
    )
  end

  defp footer do
    Widgets.column("footer", [],
      gap: 8,
      children: [
        Widgets.separator("sep", orientation: :horizontal),
        Widgets.row("footer-content", [],
          gap: 16,
          children: [
            Widgets.text("copyright", "© 2025 MyApp"),
            Widgets.badge("beta", "Beta", variant: :warning)
          ]
        )
      ]
    )
  end
end
```

## Quick Reference

| Widget | Purpose | Example |
|--------|---------|---------|
| `text/1` | Display text | `Widgets.text("id", "Hello")` |
| `label/2` | Field label | `Widgets.label("id", "Name:")` |
| `hero/2` | Large header | `Widgets.hero("id", "Title")` |
| `badge/2` | Status indicator | `Widgets.badge("id", "New")` |
| `button/2` | Action button | `Widgets.button("id", "Click")` |
| `toggle/2` | On/off switch | `Widgets.toggle("id", "Enable")` |
| `link/3` | Navigation link | `Widgets.link("id", "Text", "/path")` |
| `icon/2` | Icon display | `Widgets.icon("id", :gear)` |
| `image/2` | Image display | `Widgets.image("id", "/path")` |
| `column/2` | Vertical layout | `Widgets.column("id", children)` |
| `row/2` | Horizontal layout | `Widgets.row("id", children)` |
| `stack/2` | Overlapping layout | `Widgets.stack("id", children)` |
| `separator/1` | Visual divider | `Widgets.separator("id")` |
| `spacer/1` | Spacing | `Widgets.spacer("id")` |

## Next Steps

- [Layout & Composition](./layout-composition.md) - Advanced layouts
- [Input & Forms](./input-forms.md) - Form widgets
- [Styling & Theming](./styling-theming.md) - Custom styles
