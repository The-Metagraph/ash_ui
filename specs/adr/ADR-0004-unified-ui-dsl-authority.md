# ADR-0004: Unified UI DSL Authority

## Status

**Superseded by ADR-0005**

## Note

ADR-0004 captured a refactor that made upstream `unified_ui` the authoritative
top-level authoring surface for persisted screens. That direction is no longer
the normative architecture for Ash UI.

The current architecture baseline is defined by
[ADR-0005-element-resource-authority-and-relational-screen-composition.md](./ADR-0005-element-resource-authority-and-relational-screen-composition.md),
which restores Ash-resource-native authoring authority, element-local DSL and
bindings, and relationship-driven screen composition.
