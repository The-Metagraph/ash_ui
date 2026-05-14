# Styling, Platforms, And Artifacts

`desktop_ui` keeps styling, target variation, and packaging explicit so
maintainers can review desktop behavior without losing the shared package
contract.

## Styling And Themes

- `DesktopUi.Style` defines styling primitives and widget hooks
- `DesktopUi.Theme` defines theme catalogs and inheritance rules
- `DesktopUi.Runtime.StyleResolver` applies those decisions during realization
- `DesktopUi.Continuity` compares native and canonical styled output through
  one continuity model

Use:

- `DesktopUi.Reference.style_summary/0`
- `DesktopUi.Info.style_summary/0`
- `DesktopUi.Inspection.runtime_snapshot/1`
- `mix desktop_ui.inspect native_styled_review --format diagnostics`

to inspect the effective desktop style surface.

## Bounded Platform Variation

`DesktopUi.Platform` and `DesktopUi.Platform.Integration` keep platform
variation explicit:

- Windows, macOS, and Linux may differ in window chrome, menu shape, shortcut
  scope, and notification style
- widget realization, renderer mapping, transport translation, and style
  resolution must remain shared semantics
- continuity diagnostics surface drift if platform behavior escapes those
  bounds

## Artifact Workflows

`DesktopUi.Artifacts` and `DesktopUi.Package` make packaging workflows explicit
for each target:

- Windows: archive and installer flows
- macOS: app-bundle and signed-archive flows
- Linux: archive and desktop-bundle flows

Packaging remains distinct from runtime, renderer, and transport logic. Use:

- `DesktopUi.Reference.artifact_summary/0`
- `DesktopUi.Info.artifact_summary/0`
- `DesktopUi.Package.diagnostics/0`
- `DesktopUi.Validate.artifact_validation/0`
- `mix desktop_ui.build --target linux --dry-run`
- `mix desktop_ui.package --target linux --dry-run`

to review artifact assumptions while changing package behavior.
