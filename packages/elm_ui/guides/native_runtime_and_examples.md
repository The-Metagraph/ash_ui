# Native Runtime And Examples

Direct-native `elm_ui` usage starts with the package widget surface:

- `ElmUi.Widgets`
- `ElmUi.Layout`
- `ElmUi.Layer`

## Native Screen Authoring

Use `ElmUi.Widgets.screen/4` for simple package-native screens, or return a
screen map with explicit `root` and `metadata` when you need stable IDs or
theme metadata for review workflows.

Mount native screens through:

- `ElmUi.Runtime.mount_native_screen/2`
- `ElmUi.Runtime.hydrate_frontend/1`

## Example Suites

`ElmUi.Examples` exposes maintained suites for:

- minimal native runtime behavior
- foundational forms and navigation
- advanced display and layered workflows
- transport-focused workflows
- styling-heavy review scenarios

Use:

- `ElmUi.Examples.native_examples/0` for the native suite
- `ElmUi.Examples.catalog/0` for metadata
- `ElmUi.Examples.coverage_matrix/0` for workflow and parity coverage

## Review Metadata

Each example entry includes:

- category: native, canonical, or mixed
- workflow: minimal, foundational, advanced, transport, or styling
- coverage tags
- parity obligations
- stable preview, inspection, comparison, and export artifact names
