# SDL3 Integration

This guide covers how DesktopUi integrates with SDL3 for native window management, rendering, and input handling.

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Protocol](#protocol)
4. [Draw Operations](#draw-operations)
5. [Event Handling](#event-handling)
6. [Resource Management](#resource-management)

## Overview

DesktopUi uses SDL3 as its primary rendering and input backend. The integration follows a **port-driver pattern** where the Elixir runtime communicates with a native SDL3 host process.

```mermaid
graph LR
    subgraph "Elixir"
        A[Runtime] --> B[SDL3 Adapter]
        B --> C[Port]
    end

    subgraph "Native Process"
        C --> D[SDL3 Host]
        D --> E[SDL3]
        E --> F[Platform]
    end

    F -->|Windows/Events| D
    D --> C
```

### Why SDL3?

- **Cross-platform**: Single codebase for Windows, macOS, and Linux
- **Modern API**: SDL3 provides improved APIs over SDL2
- **Hardware acceleration**: GPU-accelerated rendering
- **Input handling**: Comprehensive keyboard, mouse, and touch support
- **Audio support**: Built-in audio capabilities (future use)

## Architecture

### Component Layers

```mermaid
graph TB
    subgraph "Elixir Layer"
        A[Runtime.State] --> B[RenderPlan]
        B --> C[FrameEncoder]
    end

    subgraph "Protocol Layer"
        C --> D[JSON Protocol]
        D --> E[Erlang Port]
    end

    subgraph "Native Layer"
        E --> F[Protocol Handler]
        F --> G[SDL3 Host]
        G --> H[SDL3 API]
    end

    H --> I[Platform]
    I --> J[Windows]
    I --> K[Inputs]
```

### Communication Flow

```mermaid
sequenceDiagram
    participant E as Elixir Runtime
    participant P as Port
    participant H as SDL3 Host
    participant S as SDL3

    E->>P: Frame JSON
    P->>H: stdin
    H->>H: Parse Frame
    H->>S: Render Windows
    S-->>H: Events
    H->>H: Encode Events
    H->>P: stdout
    P->>E: Event JSON
```

## Protocol

### Message Format

All messages are JSON-encoded with a `type` field:

```elixir
# Frame message (Elixir → Native)
%{
  "type" => "frame",
  "frame_id" => "frame-123",
  "windows" => [%{
    "window_id" => "main",
    "title" => "My App",
    "draw_operations" => [...]
  }]
}

# Event message (Native → Elixir)
%{
  "type" => "pointer_button",
  "window_id" => "main",
  "widget_id" => "btn-1",
  "button" => "left",
  "pointer" => %{"x" => 100, "y" => 50}
}
```

### Message Types

```mermaid
classDiagram
    class FrameMessage {
        +type :frame
        +frame_id :String
        +windows :list
    }

    class EventMessage {
        +type :atom()
        +window_id :String
        +widget_id :String?
        +timestamp :integer()
    }

    class ShutdownMessage {
        +type :shutdown
        +reason :String?
    }

    class AckMessage {
        +type :ack
        +id :String
    }

    FrameMessage
    EventMessage <|-- KeyEvent
    EventMessage <|-- PointerEvent
    EventMessage <|-- FocusEvent
    EventMessage <|-- WindowEvent
```

### Draw Operation Protocol

Each draw operation contains rendering instructions:

```json
{
  "widget_id": "btn-1",
  "draw_kind": "button_control",
  "kind": "button",
  "family": "action",
  "x": 10,
  "y": 10,
  "width": 200,
  "height": 40,
  "bg": "primary",
  "fg": "light",
  "content": "Click Me",
  "focusable": true,
  "focused": false,
  "disabled": false,
  "interaction": {
    "click_intent": "activate"
  }
}
```

## Draw Operations

### Draw Kind Hierarchy

```mermaid
graph TD
    A[Draw Operations] --> B[Containers]
    A --> C[Controls]
    A --> D[Content]
    A --> E[Overlays]

    B --> B1[container_surface]
    B --> B2[column_surface]
    B --> B3[row_surface]

    C --> C1[button_control]
    C --> C2[text_input_control]
    C --> C3[checkbox_control]

    D --> D1[text_block]
    D --> D2[label_block]
    D --> D3[icon_block]

    E --> E1[dialog_surface]
    E --> E2[popover_surface]
    E --> E3[toast_surface]
```

### Draw Operation Structure

```c
typedef struct {
  char window_id[128];
  char widget_id[128];
  char draw_kind[64];
  char kind[64];
  char family[64];

  // Position and size
  int x, y, width, height;

  // Clipping
  int clip;
  int clip_x, clip_y, clip_width, clip_height;

  // Styling
  char bg[64];
  char fg[64];
  char border[64];
  char variant[64];

  // Content
  char content[256];
  char image_source[256];

  // State
  int focusable, disabled, focused, selected;
  int checked, active, open;
  int value, current, selected_index;

  // Interaction
  char click_intent[64];
  char shortcut_intent[64];
  char selection_intent[64];
} dui_draw;
```

### Rendering Pipeline

```mermaid
graph TD
    A[dui_draw] --> B{draw_kind?}

    B --> C[Render Container]
    B --> D[Render Control]
    B --> E[Render Content]
    B --> F[Render Overlay]

    C --> G[Fill Background]
    C --> H[Render Border]

    D --> I[Draw Control Shape]
    D --> J[Draw Label]

    E --> K[Draw Text]
    E --> L[Draw Icon]
    E --> M[Draw Image]

    F --> N[Draw Overlay Background]
    F --> O[Draw Overlay Content]
```

### Color System

```mermaid
graph LR
    A[Semantic Name] --> B[Color Palette]
    B --> C[RGB Values]

    D[State Modifier] --> E[Color Adjustment]
    C --> E
    E --> F[Final Color]
```

```c
// Semantic color names
dui_color named_color(const char *name, Uint8 alpha) {
  if (strcmp(name, "primary") == 0) return (dui_color){59, 130, 246, alpha};
  if (strcmp(name, "success") == 0) return (dui_color){34, 197, 94, alpha};
  if (strcmp(name, "warning") == 0) return (dui_color){234, 179, 8, alpha};
  if (strcmp(name, "error") == 0) return (dui_color){239, 68, 68, alpha};
  // ... more colors
}
```

## Event Handling

### Event Flow

```mermaid
graph TD
    A[SDL Event] --> B[Event Loop]
    B --> C{Event Type?}

    C -->|Window| D[Window Event]
    C -->|Keyboard| E[Key Event]
    C -->|Mouse| F[Pointer Event]
    C -->|Touch| G[Touch Event]

    D --> H[Encode WindowEvent]
    E --> I[Encode KeyEvent]
    F --> J[Encode PointerEvent]
    G --> K[Encode TouchEvent]

    H --> L[Send to Elixir]
    I --> L
    J --> L
    K --> L
```

### Event Encoding

```mermaid
classDiagram
    class WindowEvent {
        +type :window_activated
        +type :window_deactivated
        +type :window_resized
        +window_id :String
    }

    class KeyEvent {
        +type :keyboard_key_down
        +type :keyboard_key_up
        +key :String
        +modifiers :list
    }

    class PointerEvent {
        +type :pointer_hover
        +type :pointer_button
        +type :wheel_scrolled
        +pointer :map
    }

    class FocusEvent {
        +type :focus_changed
        +focus_target :String
    }
```

### Hit Testing

```mermaid
graph TD
    A[Pointer Event] --> B[Get Coordinates]
    B --> C[Find Window]
    C --> D[Traverse Draw Ops]
    D --> E{Hit Widget?}

    E -->|Yes| F[Check Focusable]
    E -->|No| G[Next Widget]

    F -->|Yes| H[Generate Click Event]
    F -->|No| G

    H --> I[Send to Elixir]
```

```c
dui_draw *hit_test_draw(dui_frame *frame, const char *window_id, int x, int y) {
  for (int i = frame->draw_count - 1; i >= 0; i--) {
    dui_draw *draw = &frame->draws[i];
    if (strcmp(draw->window_id, window_id) != 0) continue;

    if (x >= draw->x && x <= draw->x + draw->width &&
        y >= draw->y && y <= draw->y + draw->height) {
      return draw;
    }
  }
  return NULL;
}
```

## Resource Management

### Text Rendering

```mermaid
graph TD
    A[Text Draw Op] --> B{Has Cached Texture?}
    B -->|Yes| C[Use Cached]
    B -->|No| D[Measure Text]
    D --> E[Create Texture]
    E --> F[Cache Texture]
    F --> G[Render]
    C --> G
```

```c
typedef struct {
  char key[768];
  int width, height;
  SDL_Texture *texture;
} dui_text_cache_entry;
```

### Image Loading

```mermaid
graph TD
    A[Image Source] --> B{Is URL?}
    B -->|Yes| C[Download]
    B -->|No| D[Load File]
    C --> E[Decode Image]
    D --> E
    E --> F[Create Texture]
    F --> G[Cache Texture]
```

```c
typedef struct {
  char source[512];
  int width, height;
  SDL_Texture *texture;
} dui_image_cache_entry;
```

### Resource Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Unloaded
    Unloaded --> Loading: Request
    Loading --> Ready: Loaded
    Loading --> Failed: Error
    Ready --> Cached: Used
    Cached --> Cached: Reused
    Cached --> Unloaded: Evict
    Failed --> Unloaded: Retry
```

## SDL3 Lifecycle

### Application Callbacks

```mermaid
graph TB
    A[SDL_AppInit] --> B[Parse Arguments]
    B --> C{--probe?}
    C -->|Yes| D[Print Probe]
    C -->|No| E{--version?}
    E -->|Yes| F[Print Version]
    E -->|No| G[Parse Frame Script]
    G --> H[Initialize SDL]
    H --> I[Create Windows]
    I --> J[SDL_AppIterate]

    J --> K{Events?}
    K -->|Yes| L[SDL_AppEvent]
    K -->|No| M[Render Frame]

    L --> M
    M --> N{Shutdown?}
    N -->|No| J
    N -->|Yes| O[SDL_AppQuit]
```

### Window Management

```mermaid
graph LR
    A[Frame Script] --> B[Window Definitions]
    B --> C[SDL_CreateWindow]
    C --> D[SDL_CreateRenderer]
    D --> E[Set Logical Presentation]
    E --> F[Window Ready]
```

## Related Guides

- [Architecture Overview](./architecture-overview.md)
- [Component Design](./component-design.md)
- [Runtime Backbone](./runtime-backbone.md)
- [Widget System](./widget-system.md)
