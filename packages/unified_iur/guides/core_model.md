# Core Model

The `UnifiedIUR` core model is built around `UnifiedIUR.Element`.

## Element Identity

Every canonical element carries:

- `id`
- `type`
- `kind`

These fields are the stable identity boundary for canonical shape,
deterministic snapshotting, and runtime-library consumption.

## Metadata

Each element also carries canonical metadata through `UnifiedIUR.Metadata`,
including:

- `authored_ref`
- `description`
- `annotations`
- `tags`
- `extra`

Metadata must remain portable and must not embed runtime-local structs.

## Children and Traversal

Tree structure is represented through `UnifiedIUR.Element.Child`, which keeps
slot identity explicit. Traversal and summary helpers are exposed through:

- `UnifiedIUR.Tree`
- `UnifiedIUR.Reference`
- `UnifiedIUR.Interoperability`
- `UnifiedIUR.Inspect`

Maintainers should preserve child-slot meaning and deterministic child order
when evolving canonical constructs.
