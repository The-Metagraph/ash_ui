# Runtime Backbone

`desktop_ui` is designed around one shared desktop runtime model.

The package keeps one architectural split from the beginning:

- `DesktopUi.Runtime` for shared runtime state and boot behavior
- `DesktopUi.Platform` for bounded Windows, macOS, and Linux integration
- `DesktopUi.Renderer` for canonical `UnifiedIUR` entry
- `DesktopUi.Transport` for canonical boundary translation and diagnostics
- `DesktopUi.Style` and `DesktopUi.Theme` for shared style realization
- `DesktopUi.Artifacts` for platform-specific build and packaging workflows

Both entry paths use that same runtime backbone:

- direct-native widget trees mount directly through `DesktopUi.Runtime`
- canonical `UnifiedIUR` trees render through `DesktopUi.Renderer` and then
  mount through the same runtime
- inspection, continuity, artifact, and validation workflows all review that
  shared model rather than a second execution path

SDL3 is the intended shared rendering and input foundation, but the package
keeps the binding policy explicit so runtime semantics stay reviewable before
full platform packaging is introduced.
