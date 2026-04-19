---
id: ashui.decision.elm_ui_package_rename
status: accepted
date: 2026-04-19
affects:
  - ashui.rendering
  - ashui.governance
---

# Elm UI Package Rename

## Context

The unified renderer ecosystem renamed the Elm-backed web renderer from
`web_ui` to `elm_ui`. Ash UI needs one canonical naming model across renderer
selection, adapters, docs, and package references.

## Decision

Treat `elm_ui`, `ElmUI.Renderer`, and `AshUI.Rendering.ElmUIAdapter` as the
canonical public naming model. The renderer type is `:elm`.

Historical `web_ui` naming is not the preferred public vocabulary, even if some
compatibility or transitional references still survive in vendored code or old
materials.

## Consequences

Renderer-facing docs and public APIs stay aligned with the upstream ecosystem,
and contributors no longer need to translate between mixed naming conventions.
