# ADR-0003: Elm UI Package Rename

## Status

**Accepted**

## Context

The unified-ui ecosystem renamed its Elm-backed web renderer package from `web_ui` to `elm_ui` to make the package purpose explicit. Ash UI had already converged on the same functional meaning, but it still exposed a mixed naming model:

1. The external package and renderer module were still named `web_ui` and `WebUI.Renderer` in parts of the codebase.
2. The Ash UI bridge module was still named `AshUI.Rendering.WebUIAdapter`.
3. The public renderer type was still `:html` even though the renderer is Elm-specific.

We need a single naming model across package dependencies, bridge modules, public renderer selection, docs, and tests.

## Decision

### 1. Adopt `elm_ui` As The Canonical External Package Name

Ash UI uses the upstream Elm-backed renderer names directly:

- package name: `elm_ui`
- renderer module: `ElmUI.Renderer`
- bridge module: `AshUI.Rendering.ElmUIAdapter`
- vendored package path: `packages/elm_ui`

### 2. Rename The Public Renderer Type To `:elm`

Ash UI exposes the Elm-backed web renderer as `:elm`.

This replaces the old `:html` renderer type. No compatibility alias is kept for `:html` or `:web`.

### 3. Treat Old Names As Removed

The following names are removed rather than aliased:

- `web_ui`
- `WebUI.Renderer`
- `AshUI.Rendering.WebUIAdapter`
- renderer type `:html`
- request header value `html`

### 4. Keep Renderer Semantics Stable

This is a naming and API-alignment change, not a renderer-behavior change.

The Elm-backed web renderer still:

- consumes canonical `unified_iur`
- produces an HTML shell that boots Elm
- remains separate from `live_ui` and `desktop_ui`

## Consequences

### Positive

- Ash UI now matches the upstream unified-ui package name.
- The public renderer API now reflects that the web renderer is Elm-specific.
- Contributors no longer need to translate between package, module, and renderer-type names.

### Negative

- The change is a hard break for callers still using the old names.
- Release notes and examples must be updated in lockstep to avoid confusion.

### Mitigations

- Update contracts, guides, tests, examples, and release notes in the same change.
- Add grep-based review checks to ensure no live implementation references to removed names remain.

## Related

- [ADR-0001-control-plane-authority.md](./ADR-0001-control-plane-authority.md)
- [ADR-0002-pluggable-ui-storage.md](./ADR-0002-pluggable-ui-storage.md)
- [../contracts/rendering_contract.md](../contracts/rendering_contract.md)
- [../planning/phase-07-renderer-package-integration.md](../planning/phase-07-renderer-package-integration.md)

## References

- unified-ui renderer package naming decision (`web_ui` -> `elm_ui`)
- Ash UI Phase 7 renderer integration work
