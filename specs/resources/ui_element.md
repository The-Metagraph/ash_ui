# UI.Element Component Spec

## Built-In Support Module

`AshUI.Resources.Element`

This module is the built-in storage/support implementation when a detached
element storage resource is used. It is not the normative authoring authority.

## Purpose

Defines the authoritative UI building block: an Ash resource using the `AshUI`
extension that carries its own element DSL fragment plus optional local
bindings and interaction actions.

## Authoring Surface

- resource module declared with `use Ash.Resource`
- `AshUI` extension section for the element DSL fragment
- optional local binding declarations
- optional interaction action declarations
- ordinary Ash attributes and relationships for composition context

## Relationships

- relationship to the owning screen resource
- optional parent/child or companion element relationships
- optional relationship-driven ordering and placement metadata

## Actions

- Ash actions needed by the application/resource
- optional UI-relevant interaction actions declared through the `AshUI`
  extension

## Runtime Role

- loaded as part of the screen's resource graph
- contributes its DSL fragment, bindings, and actions to compilation
- participates in incremental recompilation when it or its relationships change

## Storage Contract Notes

- authoring authority belongs to the resource module and its `AshUI` extension
- detached `AshUI.Resources.Element` records may still exist as support
  materialization, but they are not the primary authoring model
- alternate implementations must preserve the documented resource-first authoring
  semantics

## Current Gaps

- the repo still needs to restore this resource-first model in code after the
  screen-document-authority detour
