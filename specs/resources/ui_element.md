# UI.Element Component Spec

## Default Module

`AshUI.Resources.Element`

Alternate implementations may replace this module when configured as the active UI storage element resource.

## Purpose

Defines persisted element records that support relational querying, ordering, and incremental composition alongside `Screen.unified_dsl`.

## Persisted Attributes

- `id`: UUID primary key
- `type`: renderer-facing component identifier
- `props`: component properties
- `variants`: variant list
- `position`: ordering value
- `metadata`: free-form annotations
- `active`: soft enablement flag
- `version`: update version
- `inserted_at`
- `updated_at`

## Relationships

- `belongs_to :screen`
- `has_many :bindings`

## Actions

- `read`
- `create`
- `update`
- `destroy`

## Runtime Role

- loaded when screens compile from relational resources
- used for ordering and association queries
- paired with bindings for dynamic behavior

## Storage Contract Notes

- the framework resolves the active element resource through UI storage configuration
- alternate implementations must preserve the documented attributes, relationships, and actions
- the built-in implementation is Postgres-backed, but other Ash-compatible data layers are allowed

## Current Gaps

- no element-specific storage gaps beyond the broader remaining DSL-extension work
