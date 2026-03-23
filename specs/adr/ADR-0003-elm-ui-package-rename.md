# ADR-0003: Elm UI Package Rename

## Status

**Accepted**

## Context

The unified-ui ecosystem has renamed its Elm-backed web renderer package from `web_ui` to `elm_ui` to make the package purpose explicit. That rename matches the direction already taken in this repository:

1. The renderer is no longer documented as a generic static HTML renderer.
2. The `web_ui` integration path is explicitly Elm-backed.
3. The name `web_ui` creates ambiguity with broader web-rendering concerns that are not specific to Elm.

Ash UI's current specifications and guides still describe the external renderer package as `web_ui`, and some implementation details in this repository still use historical names such as `AshUI.Rendering.WebUIAdapter` and `packages/web_ui`.

We need a clear architectural decision for how Ash UI should name this boundary in specs and documentation while the implementation catches up.

## Decision

### 1. Adopt `elm_ui` As The Canonical External Package Name

Ash UI specifications, ADRs, topology documents, and user-facing documentation will refer to the upstream Elm-backed renderer package as `elm_ui`.

When describing the external unified-ui boundary, Ash UI will use:

- package name: `elm_ui`
- renderer module: `ElmUI.Renderer`
- behavior description: Elm-backed web rendering

### 2. Treat `web_ui` As A Transitional Internal Name

Historical names that still exist inside this repository remain implementation details until a follow-up code refactor lands.

That includes:

- `AshUI.Rendering.WebUIAdapter`
- vendored paths such as `packages/web_ui`
- any compatibility configuration that still uses the old name in code

Developer-facing documentation may mention these historical names only when needed to explain the current implementation state.

### 3. Keep Renderer Semantics Stable

This ADR is a naming decision, not a rendering-behavior change.

The Elm-backed web renderer still:

- consumes canonical `unified_iur`
- produces an HTML shell that boots Elm
- remains separate from `live_ui` and `desktop_ui`

### 4. Defer Public Renderer-Type Renames

This ADR does not rename Ash UI's public renderer selection atoms or local module names. Any future rename of public API labels such as `:html` is a separate compatibility decision and requires its own change review.

## Consequences

### Positive

- Ash UI now matches the upstream unified-ui package name.
- Specifications describe the renderer according to its actual Elm-focused role.
- Future contributors have a clearer path for the eventual implementation rename.

### Negative

- Documentation must carry a short transition note while internal code still uses `web_ui`.
- Specs and implementation names temporarily diverge at the package-boundary label.

### Mitigations

- Keep the transition note explicit in architecture and getting-started docs.
- Treat `elm_ui` as the architectural name and `web_ui` as a temporary implementation alias.
- Follow up with a focused code/module rename PR when compatibility impact is understood.

## Related

- [ADR-0001-control-plane-authority.md](./ADR-0001-control-plane-authority.md)
- [ADR-0002-pluggable-ui-storage.md](./ADR-0002-pluggable-ui-storage.md)
- [../contracts/rendering_contract.md](../contracts/rendering_contract.md)
- [../planning/phase-07-renderer-package-integration.md](../planning/phase-07-renderer-package-integration.md)

## References

- unified-ui renderer package naming decision (`web_ui` -> `elm_ui`)
- Ash UI Phase 7 renderer integration work
