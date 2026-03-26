# ADR-0005: Element Resource Authority And Relational Screen Composition

## Status

**Accepted**

## Context

Ash UI has drifted away from its original intent.

The project was meant to be an Ash-native UI framework where UI structure is
expressed through Ash resources, Ash relationships, and an `AshUI` extension
that lets those resources carry UI semantics. Instead, the recent architecture
work collapsed authority into monolithic screen documents and treated Ash UI as
little more than a persistence and runtime wrapper around upstream
`unified_ui`.

That was the wrong abstraction.

It weakens the core value proposition of Ash UI in four ways:

1. It demotes Ash resources from the primary authoring model to serialized
   storage containers.
2. It hides UI composition inside opaque screen documents instead of using Ash
   relationships, which are the framework's native composition language.
3. It separates bindings and interaction actions from the elements that actually
   use them.
4. It turns screens into monoliths, even though the system was meant to support
   composable element resources with optional inline DSL where it is genuinely
   useful.

Ash UI is not supposed to be a generic screen-document store wrapped around
`UnifiedUi.Dsl`.

Ash UI is supposed to be an Ash-resource-native UI composition framework.

## Decision

### 1. Ash Resources Are The Authoritative UI Authoring Units

The primary authoring model in Ash UI is an Ash resource that opts into the
`AshUI` extension.

Screen resources and element resources are both Ash resources first. They are
not secondary projections of a monolithic screen document.

### 2. Element Resources Own Their UI Semantics

Element resources are the primary UI building blocks.

Each element resource MAY declare, through the `AshUI` extension:

- the element DSL fragment for that resource
- the bindings relevant to that element
- the interaction actions relevant to the signals that element exposes

Bindings and actions should live as close as possible to the element that
consumes them.

### 3. Resource Relationships Define Composition

The relationships between UI elements MUST be expressed through Ash resource
relationships.

Screen composition and nested element composition are therefore modeled through
standard Ash relationships rather than being hidden inside one serialized screen
blob.

### 4. Screens Remain Composable, But Primarily Compose Element Resources

Screen resources remain the top-level mount boundary and composition root.

However, a screen should compose primarily through related element resources.
Screens MAY still declare direct DSL composition for glue code, simple inline
wrappers, layout scaffolding, or other cases where introducing another resource
would be unnecessary overhead.

Inline DSL is allowed. It is not the primary authority.

### 5. `unified_ui` Supplies DSL Constructs, Not Top-Level Authoring Authority

Upstream `unified_ui` remains important, but its role is narrowed and clarified.

`unified_ui` provides:

- widget DSL constructs
- layout constructs
- theming and styling constructs
- lowering and validation semantics for those embedded DSL fragments

`unified_ui` does not replace the Ash resource graph as the top-level authoring
model for Ash UI.

### 6. No Backward-Compatibility Requirement Applies To The Divergent Model

Ash UI does not need to preserve backward compatibility for the monolithic
screen-document-authority direction introduced by ADR-0004 and Phases 9-12.

That direction may be removed, rewritten, or hard-cut as needed to restore the
resource-first model.

## Consequences

### Positive

- The project is re-centered on Ash-native composition instead of document-first
  composition.
- Element bindings and interaction actions live with the elements they affect.
- Relationships become meaningful again for UI composition and compiler graph
  traversal.
- Screens regain composability without becoming monolithic authored documents.
- Upstream `unified_ui` is used where it is strongest: element-level DSL,
  theming, styling, and lowering semantics.

### Negative

- Recent work that established monolithic screen-document authority is now
  architectural debt.
- The compiler, runtime hydration, examples, and conformance tooling will need a
  substantial refactor.
- Some current APIs and examples will need a hard break instead of a migration
  bridge.

### Required Follow-Through

- The normative contracts must be rewritten around resource-first authoring.
- The planning track must be reopened with a new remediation phase line.
- Public examples must stop demonstrating screen-monolith authoring as the
  preferred model.

## Related

- [ADR-0001-control-plane-authority.md](./ADR-0001-control-plane-authority.md)
- [ADR-0002-pluggable-ui-storage.md](./ADR-0002-pluggable-ui-storage.md)
- [ADR-0003-elm-ui-package-rename.md](./ADR-0003-elm-ui-package-rename.md)
- [ADR-0004-unified-ui-dsl-authority.md](./ADR-0004-unified-ui-dsl-authority.md)
- [../contracts/resource_contract.md](../contracts/resource_contract.md)
- [../contracts/screen_contract.md](../contracts/screen_contract.md)
- [../contracts/binding_contract.md](../contracts/binding_contract.md)
- [../contracts/compilation_contract.md](../contracts/compilation_contract.md)
- [../planning/phase-13-element-resource-authority.md](../planning/phase-13-element-resource-authority.md)

## References

- Ash resource relationships
- Ash UI resource extension model
- upstream `unified_ui` DSL constructs and theming model
