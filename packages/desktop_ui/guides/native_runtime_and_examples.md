# Native Runtime And Examples

`desktop_ui` is usable directly through its own native desktop widget surface.
That direct-native path is a core package contract, not a demo-only layer.

## Direct-Native Surface

Use `DesktopUi.Widgets` for the native desktop surface:

- foundational content and action widgets
- input and navigation widgets
- advanced data, feedback, visualization, and operational widgets
- multiwindow, overlay, viewport, split-pane, and positioned layout constructs
- shared style, theme, platform, artifact, and transport seams

The direct-native path still uses the same runtime, style resolution, target
variation policy, and boundary translation model as canonical rendering.

## Maintained Example Catalog

The maintained examples are intentionally paired:

- native examples show direct-native authoring through `DesktopUi.Widgets`
- canonical examples show `UnifiedIUR` flowing through `DesktopUi.Renderer`
- mixed examples compare continuity, transport, styling, and cross-target
  behavior

Use these helpers instead of memorizing IDs:

- `DesktopUi.Examples.catalog/0`
- `DesktopUi.Examples.metadata/1`
- `DesktopUi.Examples.coverage_matrix/0`
- `DesktopUi.Reference.example_summary/0`
- `mix desktop_ui.inspect --format catalog`

## Example Workflows

The maintained example set covers:

- foundational workspace review
- advanced layered and multiwindow review
- transport and normalized input review
- styled review and style continuity

Those examples are intended to stay useful for local package review, CI-facing
validation, and release-readiness workflows.

## Visible SDL3 Review Workflow

When SDL3 is available locally, the maintained native and canonical examples
can run through the compiled visible-window host:

- `mix desktop_ui.build_host --dry-run`
- `mix desktop_ui.build_host`
- `mix desktop_ui.run native_foundational --backend compiled --linger-ms 3000`
- `mix desktop_ui.run canonical_foundational --backend compiled --linger-ms 3000`
- `mix desktop_ui.run native_advanced_operations --backend compiled --linger-ms 3000`
- `mix desktop_ui.run native_transport_review --backend compiled --linger-ms 3000`
- `mix desktop_ui.run native_styled_review --backend compiled --linger-ms 3000`

That visible review loop is expected to show:

- widget-complete native rendering instead of placeholder-only geometry
- native text and image realization when SDL3 companion libraries are present
- keyboard and pointer interaction with focus, command, selection, and scroll behavior
- bounded dialog, context-menu, and multiwindow transitions

When SDL3 or its companion libraries are missing, `desktop_ui` keeps the run
path reviewable by falling back explicitly to the Elixir-host protocol path.
That fallback still exercises boot, frame, transport, and bounded resource
contracts, but it does not overstate native visible completeness or pretend the
compiled interactive renderer is active.
