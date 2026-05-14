# Canonical Rendering and Transport

`LiveUi` is the LiveView runtime package that consumes canonical `UnifiedIUR`
values and translates canonical boundary signals.

## Canonical Rendering

Canonical rendering in `LiveUi` follows three rules:

- canonical `UnifiedIUR` values are rendered through `LiveUi.Renderer`
- canonical rendering reuses native widget modules rather than creating a separate renderer stack
- canonical style and theme attachments are lowered into native runtime styling deterministically

This design keeps native and canonical paths comparable through one runtime
model, which is what the continuity tooling reports on.

## Boundary Transport

Boundary transport in `LiveUi` follows three related rules:

- renderer-local events may remain local in direct native workflows
- boundary-safe events must translate into canonical `Jido.Signal` values
- channel envelopes must round-trip those canonical signals without losing runtime intent

The maintained boundary examples and validation report are the review baseline
for transport changes. The canonical review path stays attached to the same
aligned example ids that native maintainers already use:

- `mix live_ui.inspect button --format comparison`
- `mix live_ui.export button --format diagnostics`
- `mix live_ui.inspect table --format comparison`

## Review Guidance

When reviewing canonical renderer or transport changes, look for:

- native/canonical continuity drift on the same aligned example ids
- missing canonical boundary signals for boundary-safe events
- renderer-local payload leakage into translated boundary signals
- regressions in server-authoritative runtime assumptions
