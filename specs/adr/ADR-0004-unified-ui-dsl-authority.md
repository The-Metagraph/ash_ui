# ADR-0004: Unified UI DSL Authority

## Status

**Accepted**

## Context

Ash UI currently persists screen definitions in the `Screen.unified_dsl` field, but the repository does not actually use the upstream `unified_ui` extension and DSL as the authoring surface. Instead, it builds and validates an Ash UI-specific map format through `AshUI.DSL.Builder`, then compiles that stored map directly in `AshUI.Compiler`.

That implementation choice created a major architectural gap:

1. The specs say that unified-ui owns the canonical DSL and compiler surface.
2. The examples and compiler path use Ash UI-owned builder helpers instead of the upstream DSL.
3. Widget and layout semantics can drift because Ash UI is effectively maintaining a parallel DSL.
4. The repository advertises unified-ui integration, but the authoring and compilation boundary is still mostly in-repo.

We need a single authoritative authoring model that matches the upstream ecosystem and keeps Ash UI focused on Ash resource storage, bindings, runtime orchestration, and renderer integration.

## Decision

### 1. `unified_ui` Owns The Authoring DSL

Ash UI adopts the upstream `unified_ui` extension and DSL as the only authoritative authoring surface for screen definitions, widgets, layouts, and compiler-facing authoring semantics.

Ash UI MUST NOT continue evolving `AshUI.DSL.Builder` as a parallel public DSL.

### 2. Ash UI Persists Serialized `unified_ui` Documents

`Screen.unified_dsl` remains the durable persistence field, but its contents are defined as a serialized `unified_ui` document format owned by the upstream package rather than an Ash UI-specific builder map.

Ash UI owns storage, versioning, migrations, and Ash resource relationships around that field. It does not own the DSL grammar.

### 3. `AshUI.Compiler` Delegates DSL Compilation Upstream

`AshUI.Compiler` remains the Ash-facing orchestration boundary, but it delegates DSL parsing, validation, widget/layout expansion, and authoring-level compilation to the upstream `UnifiedUI` compiler pipeline.

Ash UI retains responsibility for:

- loading persisted screen records
- attaching Ash-specific bindings and runtime metadata
- caching and invalidation
- canonical `unified_iur` conversion and renderer routing

Ash UI does not remain the source of truth for widget or layout semantics.

### 4. `AshUI.DSL.Builder` Becomes Migration-Only

`AshUI.DSL.Builder` is reclassified as a legacy compatibility layer used only to migrate existing persisted screens and examples into the upstream DSL model.

New public examples, guides, and tests MUST use the upstream `unified_ui` extension once the refactor lands.

### 5. Planning And Conformance Must Reflect The Gap

The existing Phase 6 plan is treated as a historical partial implementation. The missing upstream DSL/compiler authority is reopened and tracked through a new remediation phase track.

## Consequences

### Positive

- The repo architecture finally matches the stated unified-ui integration model.
- Widget and layout semantics come from one upstream source.
- Ash UI can focus on Ash-specific concerns instead of maintaining a duplicate DSL.
- Examples become a truer demonstration of the intended ecosystem.

### Negative

- This requires a non-trivial refactor of persistence, compiler delegation, examples, and tests.
- Existing stored screens and example seeds need a migration path.
- Some internal APIs that currently expose builder helpers will need to change or be deprecated.

### Mitigations

- Keep `AshUI.DSL.Builder` available only as an explicitly documented migration path during rollout.
- Introduce the refactor as a phased remediation program with integration coverage at each phase.
- Update specs and planning docs before implementation so the repo stops overstating what Phase 6 already achieved.

## Related

- [ADR-0001-control-plane-authority.md](./ADR-0001-control-plane-authority.md)
- [ADR-0002-pluggable-ui-storage.md](./ADR-0002-pluggable-ui-storage.md)
- [ADR-0003-elm-ui-package-rename.md](./ADR-0003-elm-ui-package-rename.md)
- [../contracts/resource_contract.md](../contracts/resource_contract.md)
- [../contracts/compilation_contract.md](../contracts/compilation_contract.md)
- [../planning/phase-06-compiler-and-dsl-integration.md](../planning/phase-06-compiler-and-dsl-integration.md)
- [../planning/phase-09-unified-ui-dsl-authority.md](../planning/phase-09-unified-ui-dsl-authority.md)

## References

- `AshUI.DSL.Builder`
- `AshUI.Compiler`
- upstream `unified_ui` DSL and compiler
