# Canonical Navigation Internals

Canonical navigation is the cross-package contract for navigation intent. The
authored `UnifiedUi` DSL records intent, the compiler lowers it into
`UnifiedIUR.Interaction`, shared transport validates it, and each runtime
resolves it through its own native navigation model.

This guide is for developers changing the navigation surface, compiler
lowering, shared fixtures, or runtime integration.

## Contract Boundaries

The boundaries are deliberately narrow:

| Layer | Owns | Must Not Own |
| --- | --- | --- |
| `UnifiedUi` | Authored navigation DSL, validation, compiler lowering, inspection | Phoenix routes, Elm messages, desktop modules, terminal degradation |
| `UnifiedIUR` | Canonical interaction representation, fixtures, boundary summaries | Runtime-local stack ids or renderer containment |
| Signal transport | `Jido.Signal` and CloudEvents-compatible boundary meaning | Renderer-local payload envelopes |
| Runtime packages | Symbol resolution, history stacks, modal presentation, diagnostics | New canonical fields that bypass `UnifiedUi` or `UnifiedIUR` |

The durable specs are:

- `.spec/specs/unified-ui/signals.spec.md`
- `.spec/specs/unified-ui/compiler.spec.md`
- `.spec/specs/unified-iur/interactions.spec.md`
- `.spec/specs/signal_transport.spec.md`
- `.spec/decisions/architecture/repo.ecosystem.canonical_navigation_boundary.md`

## Authored Surface

The authored surface is `UnifiedUi.Signal`. It defines:

- standard interaction families
- supported navigation actions
- action contracts and required fields
- local navigation fields
- modal stack semantics attached to modal actions

The current canonical actions are:

| Action | Kind | Required Fields | Optional Fields |
| --- | --- | --- | --- |
| `:navigate_to` | `:screen_transition` | `screen` | `params`, `metadata` |
| `:replace_with` | `:replace_transition` | `screen` | `params`, `metadata` |
| `:go_back` | `:history_transition` | none | `metadata` |
| `:go_forward` | `:history_transition` | none | `metadata` |
| `:open_modal` | `:modal_transition` | `modal` | `params`, `metadata` |
| `:close_modal` | `:modal_transition` | none | `modal`, `metadata` |

The compiler derives modal stack metadata from the action. Authors do not
manually add runtime stack ids or structural containment to `target_intent`.

## Lowering Path

The normal lowering path is:

```text
UnifiedUi.Dsl signals section
  -> UnifiedUi.Signal
  -> UnifiedUi.Compiler.Pipeline compile_interactions
  -> UnifiedIUR.Interaction
  -> UnifiedIUR.Element interaction attachments
  -> runtime package transport
```

For a navigation interaction, `UnifiedUi.Signal.navigation_descriptor/1`
normalizes the target intent into a descriptor containing:

- `:kind`
- `:action`
- `:screen` or `:modal` when applicable
- `:params`
- `:metadata`
- `:binding` and `:destination` for local navigation
- `:modal_stack` for `open_modal` and `close_modal`

`UnifiedIUR.Interaction.navigation_descriptor/1` is the corresponding canonical
reader on the IUR side.

## Modal Stack Semantics

Modal stacks are semantic, not structural.

`open_modal` lowers with:

```elixir
%{
  operation: :push,
  target: :symbolic_modal,
  target_required?: true,
  named_target_allowed?: true,
  containment_required?: false,
  stack_effect: :push_modal
}
```

`close_modal` lowers with:

```elixir
%{
  operation: :close,
  target: :topmost_modal,
  target_required?: false,
  named_target_allowed?: true,
  containment_required?: false,
  stack_effect: :close_topmost_or_named_modal
}
```

Targetless close means topmost close. Targeted close is still symbolic: the
target is the modal id, not a renderer-local stack entry.

## Forbidden Boundary Fields

Shared transport rejects host and runtime fields in canonical navigation
descriptors. The forbidden set is centralized in
`UnifiedIUR.Interactions.Transport.forbidden_navigation_keys/0` and consumed by
runtime transport validation.

Forbidden fields include:

- `:route`, `:path`, `:url`, `:uri`
- `:router`, `:helper`, `:live_action`
- `:module`, `:runtime_module`
- `:stack_id`, `:modal_stack_id`, `:runtime_stack`, `:runtime_stack_id`, `:stack_ref`

When adding new host-specific behavior, keep it behind runtime resolution or
runtime metadata. Do not add it to canonical `target_intent`.

## Shared Fixtures

Shared navigation fixtures live in `UnifiedIUR.Fixtures` and are exposed through
`UnifiedIUR.Interactions.Transport`.

Current boundary fixtures include:

- `screen_transition--settings_profile`
- `replace_transition--home`
- `history_transition--back`
- `modal_transition--settings_dialog`
- `modal_stack--open_confirm_dialog`
- `modal_stack--close_top`
- `modal_stack--close_named_settings`

Runtime packages should consume these fixtures in integration tests before
adding runtime-local examples. This keeps shared meaning anchored in IUR and
signal transport rather than one renderer.

## Runtime Responsibilities

Runtime packages translate canonical descriptors into native behavior:

- `live_ui` keeps navigation server-authoritative and may resolve host routes externally.
- `elm_ui` keeps the Phoenix server runtime authoritative while reflecting state to the frontend.
- `desktop_ui` resolves symbolic screens through its navigation controller and registry.
- `terminal_ui` preserves stack meaning while reporting capability-aware degradation.

Runtime-specific details belong in runtime state, diagnostics, or host
resolvers. They should not appear in canonical descriptors crossing the
ecosystem boundary.

## Change Checklist

When changing canonical navigation:

1. Update `.spec/specs/unified-ui/signals.spec.md` for authored surface changes.
2. Update `.spec/specs/unified-ui/compiler.spec.md` for lowering changes.
3. Update `.spec/specs/unified-iur/interactions.spec.md` for IUR descriptor changes.
4. Update `.spec/specs/signal_transport.spec.md` for cross-package transport changes.
5. Add or update `UnifiedUi.Signal` contracts and compiler lowering.
6. Add or update `UnifiedIUR.Interaction` and `UnifiedIUR.Interactions.Transport`.
7. Add or update shared fixtures before runtime-specific tests.
8. Update runtime translators only after the shared contract is stable.
9. Update docs and maintained examples in the same change set.

## Focused Verification

Useful focused tests:

```bash
mix test test/unified_ui/canonical_navigation_integration_test.exs
mix test test/unified_ui/compiler_test.exs
```

From `packages/unified_iur`:

```bash
mix test test/unified_iur/canonical_navigation_boundary_integration_test.exs
mix test test/unified_iur/interactions_transport_test.exs
```

Runtime packages each have canonical navigation integration tests. Run the
runtime-local tests touched by the change, then finish from the repository root:

```bash
mix spec.verify --debug
mix spec.check
mix spec.diffcheck
```
