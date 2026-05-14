# Runtime Backbone

`LiveUi` is designed as a server-authoritative LiveView runtime library.

The package exposes native widget boundaries, runtime helpers, canonical
renderer entry points, and transport translation modules without taking over
application startup.

## Core Runtime Model

The package uses one shared runtime for:

- directly authored native `LiveUi.Screen` modules
- canonical `UnifiedIUR` values rendered through `LiveUi.Renderer`

That shared runtime is intentionally server-authoritative:

- the server owns runtime state
- boundary events are translated into canonical `Jido.Signal` values
- browser hooks are normalized before entering runtime event handling
- canonical rendering reuses the same runtime host instead of introducing a second renderer stack

## Modal Stack Navigation

Canonical modal navigation is resolved on the LiveView server. `open_modal`
pushes a symbolic modal entry with params and metadata onto the server-owned
modal stack. Targetless `close_modal` closes the topmost modal, and targeted
`close_modal` closes a matching symbolic modal without changing screen history
or forward state.

Phoenix router lookup and URL generation may still be used by host
applications, but those values stay outside the canonical navigation descriptor.
The maintained web navigation comparison example exposes the modal stack in
native and canonical runtime snapshots for review.

## Boundary Expectations

`LiveUi` is allowed to keep renderer-local behavior inside the direct native
path, but canonical boundary translation must remain CloudEvents-compatible and
must not leak renderer-local payload semantics into boundary signals.

Use the same aligned example ids and `mix live_ui.validate` to review these
transport expectations when the runtime boundary changes. Native runtime review,
canonical review, and transport inspection are all attached to the same aligned
example ids instead of separate package-only lanes.
