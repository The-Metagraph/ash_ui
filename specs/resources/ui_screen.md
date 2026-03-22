# UI.Screen Component Spec

## Default Module

`AshUI.Resources.Screen`

Alternate implementations may replace this module when configured as the active UI storage screen resource.

## Purpose

Defines the persisted top-level screen record used by compilation, runtime mounting, and renderer adaptation.

## Persisted Attributes

- `id`: UUID primary key
- `name`: unique screen identifier
- `unified_dsl`: nested screen tree
- `layout`: layout hint
- `route`: optional route
- `metadata`: free-form annotations
- `active`: soft enablement flag
- `version`: update version
- `inserted_at`
- `updated_at`

## Relationships

- `has_many :elements`
- `has_many :bindings`

## Actions

- `read`
- `create`
- `update`
- `destroy`

## Runtime Role

- loaded by `AshUI.LiveView.Integration`
- compiled by `AshUI.Compiler`
- adapted by `AshUI.Rendering.IURAdapter`
- authorized through runtime authorization helpers today

## Storage Contract Notes

- the framework resolves the active screen resource through UI storage configuration
- alternate implementations must preserve the documented attributes, relationships, and actions
- the built-in implementation is Postgres-backed, but ETS-backed or other Ash-compatible data layers are allowed

## Current Gaps

- lifecycle is partly runtime-managed rather than fully expressed as screen resource actions
