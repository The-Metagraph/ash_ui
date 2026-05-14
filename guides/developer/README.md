# AshUI Developer Guides

Developer guides for contributors working on AshUI internals.

The sequence below is the intended learning path for new maintainers.

## Learning Path

1. **[DG-0001: Architecture and Control Planes](DG-0001-architecture-and-control-planes.md)** - The package-level model, stable internal boundaries, and the main modules to debug first.
2. **[DG-0002: Storage, Resource Authority, and Configuration](DG-0002-storage-resource-authority-and-configuration.md)** - How authored resources become persisted screens and how the configurable storage boundary works.
3. **[DG-0003: Compiler, Canonical IUR, Styling, and Renderers](DG-0003-compiler-canonical-iur-and-renderers.md)** - Internal compilation, canonical conversion, styling data flow, and adapter selection.
4. **[DG-0004: Runtime, Bindings, and Authorization](DG-0004-runtime-bindings-and-authorization.md)** - LiveView mount flow, event routing, runtime binding work, and authorization checks.
5. **[DG-0005: Testing, Conformance, and Governance](DG-0005-testing-conformance-and-governance.md)** - Test layers, support fixtures, Spec Led workflow, and repository validation.
6. **[DG-0006: Contribution and Release Workflow](DG-0006-contribution-and-release-workflow.md)** - How to package a coherent change and move it through release-readiness.

## Guide Status

| Guide | Status | Last Reviewed |
|---|---|---|
| DG-0001 | Active | 2026-04-23 |
| DG-0002 | Active | 2026-04-23 |
| DG-0003 | Active | 2026-05-14 |
| DG-0004 | Active | 2026-04-23 |
| DG-0005 | Active | 2026-04-23 |
| DG-0006 | Active | 2026-04-23 |

## What These Guides Assume

- You are reading the current architecture, not older planning placeholders.
- You want to understand the actual repo seams in `lib/`, `test/`, `guides/`, and `.spec/`.
- You are comfortable reading Elixir source and running focused Mix commands.

## Related Documentation

- [Guide index](../README.md)
- [User guides](../user/README.md)
- [Specifications](../../specs/README.md)
- [RFCs](../../rfcs/README.md)
