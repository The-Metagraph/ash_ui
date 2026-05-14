# DesktopUi Architecture Overview

This guide provides a comprehensive overview of the DesktopUi package architecture, including its layers, components, and data flows.

## Table of Contents
1. [High-Level Architecture](#high-level-architecture)
2. [Layered Design](#layered-design)
3. [Component Overview](#component-overview)
4. [Data Flow](#data-flow)
5. [Key Abstractions](#key-abstractions)

## High-Level Architecture

DesktopUi follows a **4-layer architecture** that enables both direct native widget usage and canonical IUR rendering through a unified runtime model.

```mermaid
graph TB
    subgraph "Presentation Layer"
        A[UnifiedUi DSL] -->|Canonical Elements| B[UnifiedIUR]
        C[Direct Native Widgets] -->|Widget.t| D[DesktopUi Runtime]
    end

    subgraph "Runtime Layer"
        B -->|IUR Elements| D
        D --> E[Runtime Backbone]
        E --> F[State Management]
        E --> G[Focus System]
        E --> H[Event Loop]
    end

    subgraph "Adapter Layer"
        E --> I[SDL3 Adapter]
        I --> J[Render Plan]
        J --> K[Frame Encoder]
    end

    subgraph "Native Layer"
        K --> L[SDL3 Host]
        L --> M[SDL3 Renderer]
        L --> N[Native Windows]
    end

    style B fill:#e1f5fe
    style D fill:#f3e5f5
    style I fill:#fff3e0
    style L fill:#e8f5e9
```

## Layered Design

### 1. Presentation Layer

The presentation layer provides two complementary entry points:

```mermaid
graph LR
    subgraph "DSL Path"
        A1[UnifiedUi DSL] --> A2[Element Tree]
    end

    subgraph "Native Path"
        B1[Widget Builders] --> B2[Widget Trees]
    end

    A2 --> C[IUR Canonical Mapper]
    B2 --> D[Runtime Mount]

    C --> D
```

**DSL Path**: For users authoring screens in the UnifiedUi DSL
- Produces `UnifiedIUR.Element` structs
- Mapped through canonical renderer to native widgets
- Enables cross-runtime compatibility (desktop_ui, live_ui, etc.)

**Native Path**: For direct native widget construction
- Uses `DesktopUi.Widgets.*` builders
- Produces `DesktopUi.Widget` structs directly
- Full access to native-specific features

### 2. Runtime Layer

The runtime layer manages the shared execution model:

```mermaid
graph TB
    subgraph "Runtime Backbone"
        A[Runtime.State] --> B[Realization.Tree]
        A --> C[Focus.Order]
        A --> D[Screen.Bindings]

        B --> E[LayoutEngine]
        E --> F[ComputedBounds]

        C --> G[FocusRouter]
        G --> H[FocusTarget]

        D --> I[BindingResolver]
        I --> J[CurrentValues]
    end
```

### 3. Adapter Layer

The SDL3 adapter bridges Elixir runtime to native execution:

```mermaid
sequenceDiagram
    participant E as Elixir Runtime
    participant A as SDL3 Adapter
    participant R as RenderPlan
    participant F as FrameEncoder
    participant H as SDL3 Host

    E->>A: Mount Screen
    A->>A: Build Realization Tree
    A->>A: Compute Layout
    A->>R: Build Render Plan
    R->>R: Generate Draw Operations
    R->>F: Encode Frame Payload
    F->>H: Send via Port
    H->>H: Render to Window
    H->>F: Return Interaction Events
    F->>E: Decode and Dispatch
```

### 4. Native Layer

The native layer handles actual rendering and input:

```mermaid
graph TB
    subgraph "SDL3 Host (C)"
        A[Port Listener] --> B[Protocol Handler]
        B --> C[Frame Parser]
        C --> D[Window Manager]
        D --> E[Renderer]
        D --> F[Event Loop]

        E --> G[Draw Operations]
        F --> H[Event Capture]
        H --> B
    end
```

## Component Overview

### Core Components

```mermaid
classDiagram
    class Runtime {
        +mount_native_screen/2
        +mount_iur_screen/2
        +handle_event/2
        +update_bindings/2
    }

    class Widget {
        +kind/1
        +id/1
        +attributes/1
        +state/1
        +metadata/1
        +events/1
    }

    class Realization {
        +tree/1
        +viewport_regions/1
        +mode/1
    }

    class Focus {
        +order/1
        +current/1
        +navigate/2
    }

    class RenderPlan {
        +build/1
        +windows/1
        +draw_operations/1
        +diagnostics/1
    }

    Runtime --> Widget
    Runtime --> Realization
    Runtime --> Focus
    Runtime --> RenderPlan
```

### Widget System Components

```mermaid
graph TB
    subgraph "Widget Builders"
        A[DesktopUi.Widgets]
        A --> B[Foundational]
        A --> C[Input]
        A --> D[Navigation]
        A --> E[Data]
        A --> F[Feedback]
        A --> G[Operational]
        A --> H[Visualization]
    end

    subgraph "Widget Struct"
        I[Widget.t]
        I --> J[kind]
        I --> K[id]
        I --> L[attributes]
        I --> M[state]
        I --> N[metadata]
        I --> O[bindings]
        I --> P[events]
        I --> Q[styles]
    end

    B --> I
    C --> I
```

### IUR Renderer Components

```mermaid
graph LR
    subgraph "Canonical Mapping"
        A[UnifiedIUR.Element] --> B[Mapper]
        B --> C[Widget.t]
    end

    subgraph "Attribute Mapping"
        D[IUR Attributes] --> E[Attribute Extractor]
        E --> F[Native Attributes]
    end

    subgraph "Event Mapping"
        G[IUR Events] --> H[Event Translator]
        H --> J[Desktop Events]
    end
```

## Data Flow

### Screen Rendering Flow

```mermaid
flowchart TD
    A[Screen Definition] --> B{Path?}
    B -->|Native| C[Widget Tree]
    B -->|IUR| D[IUR Elements]

    D --> E[Canonical Mapper]
    E --> C

    C --> F[Runtime Mount]
    F --> G[Realization]
    G --> H[Layout Engine]
    H --> I[Render Plan]
    I --> J[Frame Encoder]
    J --> K[SDL3 Host]
    K --> L[Visible Window]
```

### Event Handling Flow

```mermaid
flowchart TD
    A[User Input] --> B[SDL3 Event Loop]
    B --> C[Event Capture]
    C --> D[Event Encoding]
    D --> E[Port Transmission]
    E --> F[Elixir Runtime]
    F --> G[Event Decoder]
    G --> H[Event Router]
    H --> I[Focus Target]
    I --> J[Widget Handler]
    J --> K[State Update]
    K --> L[Re-render]
```

## Key Abstractions

### Widget Abstraction

All widgets share a common structure:

```elixir
%DesktopUi.Widget{
  kind: :button,           # Widget type
  id: "submit-btn",        # Unique identifier
  attributes: %{           # Static properties
    label: "Submit"
  },
  state: %{                # Dynamic state
    disabled: false,
    focused: false
  },
  metadata: %{             # Runtime metadata
    focusable: true,
    role: :button
  },
  bindings: %{             # Data bindings
    form_state: :my_form
  },
  events: %{               # Event handlers
    click: %{intent: :submit_form}
  },
  styles: %{               # Styling
    bg: "primary",
    fg: "light"
  }
}
```

### Screen Abstraction

Screens are the root container for widget trees:

```elixir
%{
  id: "my-screen",
  title: "My Application",
  root: %DesktopUi.Widget{
    kind: :column,
    id: "root",
    children: [
      # ... widget tree
    ]
  }
}
```

### Frame Abstraction

Frames represent the rendered output sent to the native host:

```elixir
%DesktopUi.Sdl3.Frame{
  windows: [
    %{
      window_id: "main",
      title: "My App",
      draw_operations: [
        # ... draw ops
      ]
    }
  ]
}
```

## Related Guides

- [Component Design](./component-design.md)
- [SDL3 Integration](./sdl3-integration.md)
- [IUR Renderer Architecture](./iur-renderer.md)
- [Widget System](./widget-system.md)
- [Runtime Backbone](./runtime-backbone.md)
