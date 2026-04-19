---
id: ashui.decision.pluggable_ui_storage
status: accepted
date: 2026-04-19
affects:
  - ashui.package
  - ashui.resource_authoring
  - ashui.runtime_authorization
---

# Pluggable UI Storage

## Context

Ash UI ships default `Screen`, `Element`, and `Binding` storage resources, but
the runtime already treats application data sources as Ash-native and data-layer
agnostic. Hard-wiring UI storage to one backend weakens that abstraction.

## Decision

Keep UI storage configurable through `AshUI.Config`. The framework resolves the
UI storage domain, screen resource, element resource, binding resource, and
optional repo child from configuration rather than hard-coded aliases.

The default shipped backend remains the Postgres-backed `AshUI.Domain` plus
`AshUI.Resources.*`, but alternate Ash-compatible backends are supported when
they preserve the resource contract.

## Consequences

Example apps and lightweight deployments can use alternate storage backends
without forking Ash UI internals, while the package keeps a durable default
production path.
