# AshUI User Guides

User guides for application developers building screens with AshUI.

The sequence below is ordered as a learning path. Read them top to bottom if you
are new to the library.

## Learning Path

1. **[UG-0001: Getting Started with AshUI](UG-0001-getting-started.md)** - What AshUI does, how authored screens flow into runtime, and the shortest realistic first screen.
2. **[UG-0002: Authoring Screens, Elements, and Relationships](UG-0002-authoring-screens-elements-and-relationships.md)** - The resource-local DSL and how screens are composed.
3. **[UG-0003: Widget Types, Properties, and Signals](UG-0003-widget-types-properties-and-signals.md)** - The current widget vocabulary, renderer-read props, and signal capabilities.
4. **[UG-0004: Bindings, Actions, and Forms](UG-0004-bindings-actions-and-forms.md)** - Value, list, and action bindings plus practical form authoring.
5. **[UG-0005: LiveView Runtime and Rendering](UG-0005-liveview-runtime-and-rendering.md)** - Mount, compile, hydrate, render, and event routing behavior.
6. **[UG-0006: Authorization and Runtime Safety](UG-0006-authorization-and-runtime-safety.md)** - How AshUI enforces screen, binding, and action access.
7. **[UG-0007: Data Surfaces and Composition Patterns](UG-0007-data-surfaces-and-composition-patterns.md)** - Patterns for dashboards, inspectors, collections, and nested composition.
8. **[UG-0008: Migration from Older AshUI Models](UG-0008-migration-from-older-ash-ui-models.md)** - How to migrate older persisted payloads and historical docs/examples.

## Guide Status

| Guide | Status | Last Reviewed |
|---|---|---|
| UG-0001 | Active | 2026-04-23 |
| UG-0002 | Active | 2026-04-23 |
| UG-0003 | Active | 2026-04-23 |
| UG-0004 | Active | 2026-04-23 |
| UG-0005 | Active | 2026-04-23 |
| UG-0006 | Active | 2026-04-23 |
| UG-0007 | Active | 2026-04-23 |
| UG-0008 | Active | 2026-04-23 |

## What These Guides Assume

- You are authoring UI through `AshUI.Resource.DSL.Screen` and `AshUI.Resource.DSL.Element`.
- You want the current implementation in this repository, not older historical authoring material.
- You care about the shipped fallback renderer/runtime behavior, not only the broader vendored ecosystem.

## Related Documentation

- [Guide index](../README.md)
- [Developer guides](../developer/README.md)
- [Specifications](../../specs/README.md)
- [RFCs](../../rfcs/README.md)
