# Canonical Rendering Boundary

Ash UI owns canonical conversion and renderer adapter selection while renderer
packages own their platform-specific output semantics.

## Intent

Capture the current rendering contract between Ash UI's internal IUR and the
external unified renderer packages.

```spec-meta
id: ashui.rendering
kind: module
status: active
summary: Ash UI adapts internal IUR to canonical unified_iur, validates compatibility, and delegates platform output to live_ui, elm_ui, and desktop_ui adapters.
surface:
  - lib/ash_ui/rendering/*.ex
  - packages/live_ui/lib/**/*.ex
  - packages/elm_ui/lib/**/*.ex
  - packages/desktop_ui/lib/**/*.ex
  - mix.exs
  - README.md
decisions:
  - ashui.decision.control_plane_authority
  - ashui.decision.elm_ui_package_rename
```

## Requirements

```spec-requirements
- id: ashui.rendering.canonical_conversion
  statement: Ash UI shall convert valid AshUI.Compilation.IUR structs into canonical unified_iur-compatible maps and validate the result before renderer consumption.
  priority: must
  stability: stable
- id: ashui.rendering.adapter_selection
  statement: Ash UI shall expose renderer adapters and registry logic for live_ui, elm_ui, and desktop_ui without making renderer packages own authoring or compilation responsibilities.
  priority: must
  stability: stable
- id: ashui.rendering.elm_naming
  statement: The public Elm-backed renderer naming in Ash UI shall use elm_ui, ElmUI, and the :elm renderer vocabulary rather than historical web_ui naming as the preferred current model.
  priority: should
  stability: stable
- id: ashui.rendering.optional_dependencies
  statement: Renderer packages shall remain optional path dependencies at the root package boundary so Ash UI can compile without every renderer present at runtime.
  priority: should
  stability: stable
```

## Verification

```spec-verification
- kind: command
  target: >-
    rg -n "to_canonical|UnifiedIUR.validate|compatible\\?|convert_success|convert_error" lib/ash_ui/rendering/iur_adapter.ex
  covers:
    - ashui.rendering.canonical_conversion
- kind: command
  target: >-
    rg -n "LiveUIAdapter|ElmUIAdapter|DesktopUIAdapter|Registry|Selector" lib/ash_ui/rendering README.md
  covers:
    - ashui.rendering.adapter_selection
- kind: command
  target: >-
    rg -n "elm_ui|ElmUI|:elm|Elm-backed" README.md lib/ash_ui/rendering packages/elm_ui
  covers:
    - ashui.rendering.elm_naming
- kind: command
  target: >-
    rg -n "optional: true|path: \"packages/live_ui\"|path: \"packages/elm_ui\"|path: \"packages/desktop_ui\"" mix.exs
  covers:
    - ashui.rendering.optional_dependencies
- kind: command
  target: mix test test/ash_ui/rendering/phase_7_integration_test.exs test/ash_ui/examples/basic_dashboard_adapter_runner_test.exs
  covers:
    - ashui.rendering.canonical_conversion
    - ashui.rendering.adapter_selection
```
