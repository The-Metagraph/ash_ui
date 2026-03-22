# UI.Binding Component Spec

## Default Module

`AshUI.Resources.Binding`

Alternate implementations may replace this module when configured as the active UI storage binding resource.

## Purpose

Defines persisted runtime bindings for value reads, list reads, and action execution.

## Persisted Attributes

- `id`: UUID primary key
- `source`: structured map describing resource, field, relationship, or action
- `target`: renderer-facing target string
- `binding_type`: one of `:value`, `:list`, `:action`
- `transform`: transformation configuration
- `metadata`: free-form annotations
- `active`: soft enablement flag
- `version`: update version
- `inserted_at`
- `updated_at`

## Relationships

- `belongs_to :element`
- `belongs_to :screen`

## Actions

- `read`
- `create`
- `update`
- `destroy`
- optional filtered reads

## Runtime Role

- evaluated by `AshUI.Runtime.BindingEvaluator`
- written through `AshUI.Runtime.BidirectionalBinding`
- action-triggered through `AshUI.Runtime.ActionBinding`
- list-oriented updates handled by `AshUI.Runtime.ListBinding`

## Storage Contract Notes

- the framework resolves the active binding resource through UI storage configuration
- alternate implementations must preserve the documented attributes, relationships, and actions
- structured `source` and `transform` maps remain the compatibility baseline across storage backends

## Current Gaps

- no binding-resource storage gaps remain beyond the broader runtime and action contract surface
