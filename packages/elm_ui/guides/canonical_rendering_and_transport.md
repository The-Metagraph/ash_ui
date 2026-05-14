# Canonical Rendering And Transport

`ElmUi.Renderer` accepts canonical `UnifiedIUR.Element` values and maps them
into the same native widget surface used by direct-native screens.

## Canonical Rendering

- `ElmUi.Renderer.render/2` is the canonical entrypoint.
- `ElmUi.Renderer.supported_kinds/0` describes the current canonical coverage surface.
- Canonical rendering reuses `ElmUi.Widget` values rather than inventing a
  second runtime model.

Canonical screens then flow through the same runtime path:

- `ElmUi.Runtime.mount_iur_screen/2`
- `ElmUi.Runtime.hydrate_frontend/1`

## Boundary Transport

`ElmUi.Transport` keeps package-local event meaning and canonical boundary
translation aligned.

- local interactions remain package-local when allowed
- boundary interactions translate into `Jido.Signal`
- Phoenix stays authoritative for acknowledgement and state progression

## Comparison Workflows

Use the mixed example artifacts for review:

- `ElmUi.Examples.foundational_comparison/0`
- `ElmUi.Examples.advanced_comparison/0`
- `ElmUi.Examples.mixed_transport_comparison/0`
- `ElmUi.Examples.styling_comparison/0`
