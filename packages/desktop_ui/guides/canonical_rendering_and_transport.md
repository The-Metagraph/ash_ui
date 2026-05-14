# Canonical Rendering And Transport

`desktop_ui` consumes canonical `UnifiedIUR` inside the package boundary and
realizes it through the same shared desktop runtime used for direct-native
screens.

## Canonical Renderer Entry Point

- `DesktopUi.Renderer` accepts canonical `UnifiedIUR.Element`
- `DesktopUi.Renderer.Mapper` maps canonical widgets, layout, layering, and
  interaction descriptors into native `DesktopUi.Widget` structures
- renderer support and responsibilities are summarized through:
  - `DesktopUi.Renderer.supported_kinds/0`
  - `DesktopUi.Renderer.responsibilities/0`
  - `DesktopUi.Reference.package_reference/0`

The renderer is expected to preserve meaning while reusing one native widget
and runtime stack.

## Shared Runtime Path

After canonical rendering, the output still mounts through `DesktopUi.Runtime`.
That means direct-native and canonical flows share:

- runtime boot and realization
- style and theme resolution
- focus and event routing
- platform integration boundaries
- artifact policy assumptions
- transport translation and diagnostics

## Boundary Event Translation

`DesktopUi.Transport` keeps local desktop inputs and boundary signals explicit:

- native desktop events normalize through one transport pipeline
- local-default and boundary-crossing families remain visible
- canonical boundary signals are translated without leaking platform-specific
  event envelopes

Use:

- `DesktopUi.Transport.diagnostics/0`
- `DesktopUi.Validate.transport_validation/0`
- `mix desktop_ui.inspect transport_flow_review --format diagnostics`
- `mix desktop_ui.validate`

to review those guarantees while changing renderer or runtime behavior.
