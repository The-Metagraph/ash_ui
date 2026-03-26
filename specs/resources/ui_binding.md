# UI.Binding Component Spec

## Built-In Support Module

`AshUI.Resources.Binding`

This module is the built-in storage/support implementation when a detached
binding storage resource is used. It is not the normative authoring authority.

## Purpose

Defines binding declarations for value reads, list reads, and action execution.
Normatively, bindings are authored on the relevant screen or element resource
through the `AshUI` extension.

## Authoring Surface

- binding declaration on a screen or element resource
- structured `source`
- renderer-facing `target`
- `binding_type`
- optional `transform`
- optional signal-linked action declaration

## Relationships

- belongs to the owning element resource when element-local
- belongs to the owning screen resource when screen-scoped

## Actions

- runtime evaluation, update, and action execution are required
- detached persistence actions are an implementation detail when a standalone
  binding resource is used

## Runtime Role

- evaluated by the Ash UI runtime
- scoped to the owning screen or element
- kept close to the owning signal source and action declarations

## Storage Contract Notes

- standalone `AshUI.Resources.Binding` records may still exist, but they are not
  the primary authoring contract
- alternate implementations must preserve resource-local binding authorship and
  runtime semantics

## Current Gaps

- the implemented repo still needs to move binding authority back onto the
  owning screen and element resources
