# Component Design

This guide covers the design principles and patterns used throughout DesktopUi components.

## Table of Contents
1. [Design Principles](#design-principles)
2. [Widget Component Pattern](#widget-component-pattern)
3. [Layout Components](#layout-components)
4. [State Management](#state-management)
5. [Event Handling](#event-handling)
6. [Styling System](#styling-system)

## Design Principles

### Core Principles

```mermaid
mindmap
  root((DesktopUi Design))
    Separation
      Presentation from Logic
      Native from Canonical
      Runtime from Rendering
    Composition
      Widget Composition
      Layout Composition
      Event Composition
    Extensibility
      Widget Families
      Custom Draw Kinds
      Platform Adapters
    Performance
      Lazy Evaluation
      Incremental Rendering
      Efficient Diffing
```

### 1. Separation of Concerns

Each component has a single, well-defined responsibility:

| Component | Responsibility |
|-----------|---------------|
| `Widget` | Data structure for widget definitions |
| `Runtime` | Screen lifecycle and state management |
| `Realization` | Layout computation and viewport management |
| `Renderer` | IUR to native widget translation |
| `RenderPlan` | Draw operation generation |
| `FrameEncoder` | Protocol encoding for native host |

### 2. Declarative API

Widgets are declared as data, not constructed imperatively:

```elixir
# Declarative (preferred)
Widgets.column("root", [],
  children: [
    Widgets.text("title", "Hello"),
    Widgets.button("btn", "Click")
  ]
)

# Not imperative (avoid)
# root = Column.new()
# root.add(Text.new("Hello"))
# root.add(Button.new("Click"))
```

### 3. Explicit Data Flow

Data flows in one direction through explicit bindings:

```mermaid
graph LR
    A[External State] -->|Binding| B[Widget]
    B -->|Event| C[Handler]
    C -->|Update| A
```

## Widget Component Pattern

### Widget Structure

All widgets follow the `DesktopUi.Widget.t()` type:

```mermaid
classDiagram
    class Widget {
        +kind :atom()
        +id :String.t()
        +attributes :map()
        +state :map()
        +metadata :map()
        +bindings :map()
        +events :map()
        +styles :map()
        +children :list()
    }

    class Attributes {
        +label :String.t()
        +value :any()
        +options :list()
        +min :integer()
        +max :integer()
    }

    class State {
        +disabled :boolean()
        +focused :boolean()
        +selected :boolean()
        +checked :boolean()
        +open :boolean()
        +loading :boolean()
    }

    class Metadata {
        +focusable :boolean()
        +role :atom()
        +interaction_route :atom()
    }

    class Events {
        +click :map()
        +change :map()
        +submit :map()
    }

    Widget --> Attributes
    Widget --> State
    Widget --> Metadata
    Widget --> Events
```

### Widget Builder Pattern

Widget builders provide a consistent API:

```elixir
defmodule DesktopUi.Widgets.Button do
  @spec button(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def button(id, label, opts \\ []) do
    Widget.new(:button,
      id: id,
      metadata: metadata(opts, focusable: true, role: :button),
      state: state(opts),
      attributes: %{
        label: label,
        icon: Keyword.get(opts, :icon)
      },
      events: events(
        click: Keyword.get(opts, :on_click, %{intent: :activate})
      ),
      styles: styles(opts)
    )
  end

  defp metadata(opts, defaults), do: # ...
  defp state(opts), do: # ...
  defp events(opts), do: # ...
  defp styles(opts), do: # ...
end
```

### Widget Families

Widgets are organized into families by purpose:

```mermaid
graph TB
    subgraph "Foundational"
        F1[Badge]
        F2[Button]
        F3[Hero]
        F4[Icon]
        F5[Image]
        F6[Label]
        F7[Link]
        F8[Separator]
        F9[Spacer]
        F10[Text]
    end

    subgraph "Input"
        I1[Checkbox]
        I2[DateInput]
        I3[FileInput]
        I4[NumericInput]
        I5[PickList]
        I6[RadioGroup]
        I7[Select]
        I8[Slider]
        I9[TextInput]
        I10[TimeInput]
    end

    subgraph "Navigation"
        N1[Breadcrumbs]
        N2[List]
        N3[Menu]
        N4[Tabs]
    end

    subgraph "Data"
        D1[InfoList]
        D2[Inspector]
        D3[KeyValue]
        D4[MarkdownViewer]
        D5[Stat]
        D6[Table]
        D7[TreeView]
    end

    subgraph "Feedback"
        FB1[AlertDialog]
        FB2[Dialog]
        FB3[InlineFeedback]
        FB4[Progress]
        FB5[Status]
        FB6[Toast]
    end

    subgraph "Operational"
        O1[ClusterDashboard]
        O2[CommandPalette]
        O3[LogViewer]
        O4[ProcessMonitor]
        O5[StreamWidget]
        O6[SupervisionTreeViewer]
        O7[WindowCommand]
    end

    subgraph "Visualization"
        V1[BarChart]
        V2[Canvas]
        V3[Gauge]
        V4[LineChart]
        V5[Timeline]
    end
```

## Layout Components

### Layout Hierarchy

```mermaid
graph TB
    A[Window] --> B[Column/Row/Stack]
    B --> C[Content]
    B --> D[SplitPane]
    B --> E[ScrollRegion]

    D --> F[Primary]
    D --> G[Secondary]

    E --> H[Viewport]

    C --> I[Leaf Widgets]
```

### Layout Algorithm

1. **Tree Construction**: Build widget tree from screen definition
2. **Bounds Computation**: Calculate preferred sizes for each widget
3. **Layout Assignment**: Assign final positions and sizes
4. **Viewport Calculation**: Determine visible regions

```elixir
# Layout example
Widgets.column("main", [],
  gap: 16,
  children: [
    Widgets.row("header", [],
      justify: :space_between,
      children: [
        Widgets.text("title", "My App"),
        Widgets.button("settings", "Settings")
      ]
    ),
    Widgets.content("content", [],
      children: [
        Widgets.table("data", columns, rows)
      ]
    )
  ]
)
```

## State Management

### State Sources

```mermaid
graph LR
    subgraph "External State"
        A[Database]
        B[GenServer]
        C[PubSub]
    end

    subgraph "Bindings"
        D[Value Bindings]
        E[Selection Bindings]
        F[Expansion Bindings]
    end

    subgraph "Widget State"
        G[Disabled]
        H[Focused]
        I[Selected]
    end

    A --> D
    B --> D
    C --> D
    D --> G
    E --> I
    F --> I
```

### Binding Declaration

```elixir
# Value binding
Widgets.text_input("username",
  binding: {:form, :username}
)

# Selection binding
Widgets.select("role",
  options: roles,
  binding: {:user, :role_id}
)

# Expansion binding
Widgets.tree_view("tree",
  nodes: items,
  expansion_binding: {:ui, :expanded_nodes}
)
```

### State Update Flow

```elixir
# Initial state
state = %{
  users: [%{id: 1, name: "Alice"}],
  selected_user_id: nil
}

# Widget with binding
Widgets.list("users",
  items: state.users,
  binding: {:selected_user_id}
)

# When user clicks item
# Event: %{type: :selection_changed, widget_id: "users", value: 1}

# Runtime updates bindings
# New state: %{selected_user_id: 1}
# Widget re-renders with item 1 selected
```

## Event Handling

### Event Types

```mermaid
classDiagram
    class Event {
        +type :atom()
        +widget_id :String.t()
        +window_id :String.t()
        +timestamp :DateTime.t()
    }

    class ClickEvent {
        +button :String.t()
        +pointer :map()
    }

    class KeyEvent {
        +key :String.t()
        +modifiers :list()
    }

    class FocusEvent {
        +focus_target :String.t()
    }

    class SelectionEvent {
        +selected_id :any()
        +selected_index :integer()
    }

    Event <|-- ClickEvent
    Event <|-- KeyEvent
    Event <|-- FocusEvent
    Event <|-- SelectionEvent
```

### Event Declaration

```elixir
# Widget with events
Widgets.button("submit", "Save",
  on_click: %{intent: :save_form, target: :my_form}
)

# Event handler receives
%{
  type: :click,
  widget_id: "submit",
  intent: :save_form,
  target: :my_form,
  pointer: %{x: 100, y: 50}
}
```

### Event Propagation

```mermaid
graph TD
    A[Native Event] --> B[SDL3 Host]
    B --> C[Port]
    C --> D[Runtime]
    D --> E{Event Type?}

    E -->|Focus| F[Focus System]
    E -->|Click| G[Widget Handler]
    E -->|Key| H[Key Router]

    F --> I[Update Focus State]
    G --> J[Execute Intent]
    H --> K[Focused Widget]

    I --> L[Re-render]
    J --> L
    K --> L
```

## Styling System

### Style Categories

```mermaid
mindmap
  root((Styling))
    Semantic Roles
      primary
      secondary
      accent
      muted
      canvas
      content
      border
    Variants
      default
      success
      warning
      error
      info
    Sizes
      xs
      sm
      md
      lg
      xl
    States
      default
      hover
      active
      focused
      disabled
```

### Style Application

```elixir
# Semantic styles
Widgets.button("primary", "Save",
  styles: %{variant: :primary}
)

# Custom colors
Widgets.button("custom", "Save",
  styles: %{
    bg: "#3b82f6",
    fg: "#ffffff",
    border: "#1d4ed8"
  }
)

# Combined
Widgets.button("styled", "Save",
  styles: %{
    variant: :primary,
    size: :lg,
    bg: "#3b82f6"
  }
)
```

### Style Resolution

```mermaid
graph TD
    A[Widget Styles] --> B{Has variant?}
    B -->|Yes| C[Get Variant Palette]
    B -->|No| D[Use Default Palette]

    C --> E[Has custom color?]
    D --> E

    E -->|Yes| F[Override with Custom]
    E -->|No| G[Use Semantic Color]

    F --> H[Compute State Color]
    G --> H

    H --> I[Final Style]
```

## Related Guides

- [Architecture Overview](./architecture-overview.md)
- [Widget System](./widget-system.md)
- [Runtime Backbone](./runtime-backbone.md)
- [SDL3 Integration](./sdl3-integration.md)
