# ADR-0002: Pluggable UI Storage

## Status

**Accepted**

## Context

Ash UI currently ships three built-in UI-definition resources:

- `AshUI.Resources.Screen`
- `AshUI.Resources.Element`
- `AshUI.Resources.Binding`

Those resources are implemented with `AshPostgres.DataLayer` and `AshUI.Repo`, which is a sensible default for durable screen definitions. At the same time, the runtime binding layer already resolves arbitrary Ash resources from configured domains, and tests in this repository use `Ash.DataLayer.Ets` successfully for application data.

That split has created an architectural mismatch:

1. The framework treats application data as Ash-native and data-layer agnostic.
2. The framework treats its own UI-definition storage as hard-wired to Postgres.
3. Example applications and lightweight deployments need to run UI-definition storage on ETS or another Ash-compatible data layer without forking Ash UI internals.

We need a single decision that clarifies the storage boundary and gives the framework a stable configuration contract.

## Decision

### 1. Separate UI Storage From Runtime Data Domains

Ash UI will distinguish between:

- **UI storage**: the Ash resources that persist `Screen`, `Element`, and `Binding`
- **runtime data domains**: the Ash domains used by bindings to read and write application data

These are related but not the same concern and must be configured independently.

### 2. Introduce a Configured UI Storage Contract

Framework modules must resolve the UI storage boundary through configuration rather than hardcoded module aliases.

The storage contract includes:

- a UI storage domain
- a screen resource
- an element resource
- a binding resource
- an optional repo child to start under the application supervisor

The default shipped configuration remains:

- `AshUI.Domain`
- `AshUI.Resources.Screen`
- `AshUI.Resources.Element`
- `AshUI.Resources.Binding`
- `AshUI.Repo`

### 3. Keep the Resource Contract Stable

Alternate UI storage resources may use any Ash-compatible data layer if they preserve the Ash UI resource contract:

- `Screen` exposes the required attributes and actions
- `Element` exposes the required attributes and actions
- `Binding` exposes the required attributes and actions
- relationships remain compatible with compiler and runtime expectations

This contract is structural rather than a custom Elixir behaviour because Ash resources are already defined through Ash DSL and introspection.

### 4. Make Repo Startup Optional

The Ash UI application must only start a storage repo when the configured UI storage backend needs one. Repo startup cannot be assumed for ETS-backed or other non-Ecto-backed storage implementations.

### 5. Preserve Postgres as the Default Production Path

This ADR does not deprecate the built-in Postgres resources. Postgres remains the default shipped backend for durable UI-definition storage. The change is that it becomes the default implementation, not the only supported implementation.

## Consequences

### Positive

- Example apps can use ETS-backed UI storage without carrying Postgres setup.
- The framework better matches Ash's data-layer abstraction model.
- Contributors can test storage-agnostic framework logic without coupling every path to Ecto.
- Production users keep the existing Postgres-backed default.

### Negative

- Framework code must resolve storage modules dynamically instead of assuming concrete aliases.
- More integration tests are needed to verify both default and alternate storage backends.
- Some public examples and guides need a clearer distinction between UI storage and binding source domains.

### Mitigations

- Keep the default configuration exactly aligned with the current built-in modules.
- Add a single configuration resolver instead of ad hoc `Application.get_env/3` calls spread across the codebase.
- Extend Phase 1 tests with an ETS-backed UI storage scenario.

## Related

- [ADR-0001-control-plane-authority.md](./ADR-0001-control-plane-authority.md)
- [../contracts/resource_contract.md](../contracts/resource_contract.md)
- [../planning/phase-01-core-ash-resource-integration.md](../planning/phase-01-core-ash-resource-integration.md)

## References

- Ash Framework resource and domain architecture
- Ash data layer abstraction model
