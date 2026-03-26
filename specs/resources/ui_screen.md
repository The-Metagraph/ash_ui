# UI.Screen Component Spec

## Built-In Support Module

`AshUI.Resources.Screen`

This module is the built-in storage/support implementation when a detached
screen storage resource is used. It is not the normative authoring authority.

## Purpose

Defines the top-level screen resource used by compilation, runtime mounting, and
renderer adaptation.

## Authoring Surface

- resource module declared with `use Ash.Resource`
- `AshUI` extension section for screen-level composition
- route and screen metadata
- relationships to primary element resources
- optional direct inline DSL fragments for glue/layout composition

## Relationships

- primary relationships to child element resources
- optional relationships to companion screen-scoped resources
- optional screen-scoped binding ownership where needed

## Actions

- Ash actions needed for the screen/resource
- lifecycle actions as required by the application/runtime

## Runtime Role

- loaded by `AshUI.LiveView.Integration`
- used as the root of relationship-driven UI compilation
- provides screen-scoped metadata, bindings, and inline composition
- adapted to canonical IUR for renderers

## Storage Contract Notes

- screens are not normatively defined as monolithic persisted documents
- direct screen-level DSL is allowed, but related element resources remain the
  primary composition authority
- alternate implementations must preserve the same screen-root and
  relationship-first semantics

## Current Gaps

- the repo still needs to restore relationship-first screen composition as the
  implemented default
