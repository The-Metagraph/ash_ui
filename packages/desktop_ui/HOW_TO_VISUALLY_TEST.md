# How to Visually Test Phase 11 - IUR Widget Completeness

## Quick Test (Simple)

Run the existing canonical example to see the basic widgets:
```bash
cd /Users/Pascal/code/unified/packages/desktop_ui
mix desktop_ui.run canonical_foundational --linger-ms 5000
```

## Run Native Example
```bash
mix desktop_ui.run native_foundational --linger-ms 5000
```

## Run Advanced Operations Example
```bash
mix desktop_ui.run native_advanced_operations --linger-ms 5000
```

## Create a Phase 11 Test Screen

If you want to see all the new Phase 11 widgets specifically, you can create a test script:

```elixir
# Create a file: test_phase11_visual.exs
alias DesktopUi.Widgets

screen = %{
  id: "phase11-test",
  title: "Phase 11 Widgets",
  root: Widgets.column("root", [], gap: 16,
    children: [
      # Foundational
      Widgets.badge("badge1", "New", variant: :success),
      Widgets.hero("hero1", "Phase 11", subheadline: "IUR Widget Completeness"),
      Widgets.separator("sep1"),
      Widgets.link("link1", "Docs", "/docs"),

      # Input
      Widgets.numeric_input("num1", value: 42, min: 0, max: 100),
      Widgets.slider("slider1", value: 75),
      Widgets.date_input("date1", value: Date.utc_today()),
      Widgets.time_input("time1", value: Time.utc_now()),
      Widgets.file_input("file1"),

      # Data
      Widgets.stat("stat1", value: 45, label: "IUR Kinds", trend: :up),
      Widgets.key_value("kv1", key: "Status", value: "Complete"),

      # Feedback
      Widgets.status("status1", "Ready", severity: :success),
      Widgets.progress("progress1", current: 75)
    ]
  )
}

DesktopUi.Runtime.mount_native_screen(screen, platform_target: :linux)
|> elem(1)
|> DesktopUi.Sdl3.RenderPlan.build()
|> elem(1)
|> IO.inspect(limit: :infinity, pretty: true)
```

Then run:
```bash
mix run test_phase11_visual.exs
```

## Using IEx for Interactive Testing

```bash
cd /Users/Pascal/code/unified/packages/desktop_ui
iex -S mix
```

Then in IEx:
```elixir
alias DesktopUi.Widgets

# Create a screen with Phase 11 widgets
screen = %{
  id: "test",
  title: "Phase 11 Test",
  root: Widgets.column("root", [],
    children: [
      Widgets.badge("b1", "New", variant: :success),
      Widgets.hero("h1", "Phase 11", subheadline: "All 45 IUR kinds"),
      Widgets.stat("s1", value: 45, label: "Kinds", trend: :up)
    ]
  )
}

# Mount and inspect
{:ok, state} = DesktopUi.Runtime.mount_native_screen(screen, platform_target: :linux)
{:ok, plan} = DesktopUi.Sdl3.RenderPlan.build(state)

# See what's rendered
plan.diagnostics.draw_kind_counts |> IO.inspect()
plan.presentation.iur_widget_coverage |> IO.inspect()
```

## Verify Widget Coverage

```bash
# Check all supported kinds
mix eval "DesktopUi.Renderer.supported_kinds() |> length() |> IO.puts()"
# Should output: 56 (45 IUR + structural kinds)

# Check validation
mix desktop_ui.validate
```

## Build SDL3 Native Host (if needed)

```bash
# The native host should build automatically, but you can force it:
cd native/desktop_ui_sdl3_host
clang -O2 -shared -fPIC \
  -I/opt/homebrew/include \
  -o ../../priv/native/desktop_ui_sdl3_host \
  src/main.c \
  -lSDL3 -lSDL3_ttf -lSDL3_image
```
