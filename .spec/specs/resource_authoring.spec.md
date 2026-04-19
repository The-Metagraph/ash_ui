# Resource-First Authoring

Ash UI's preferred public authoring model starts from Ash resources and keeps UI
semantics local to the resources that own them.

## Intent

Capture how screen resources, element resources, bindings, actions, and storage
resources interact in the current resource-first model.

```spec-meta
id: ashui.resource_authoring
kind: module
status: active
summary: Screen and element resources own UI authoring, bindings, actions, and relationship-driven composition while shipped storage resources remain configurable support.
surface:
  - lib/ash_ui/resource/dsl/*.ex
  - lib/ash_ui/resource/authority.ex
  - lib/ash_ui/resources/*.ex
  - examples/basic_dashboard/lib/*.ex
  - guides/user/UG-0001-getting-started.md
  - guides/user/UG-0002-resources.md
decisions:
  - ashui.decision.pluggable_ui_storage
  - ashui.decision.element_resource_authority
```

## Requirements

```spec-requirements
- id: ashui.resource_authoring.element_local_semantics
  statement: Element resources shall declare their own ui_element, ui_bindings, and ui_actions semantics through AshUI.Resource.DSL.Element.
  priority: must
  stability: stable
- id: ashui.resource_authoring.screen_composition
  statement: Screen resources shall compose related element resources through Ash relationships plus ui_relationships, using inline_fragment only for limited glue.
  priority: must
  stability: stable
- id: ashui.resource_authoring.persistence_boundary
  statement: AshUI.Resource.Authority shall persist a screen record and resource-authority payload from authored screen modules without making the persisted snapshot the primary authoring boundary.
  priority: must
  stability: stable
- id: ashui.resource_authoring.storage_support
  statement: Built-in Screen, Element, and Binding storage resources shall remain available as configurable support resources rather than as the sole public authoring API.
  priority: must
  stability: stable
```

## Scenarios

```spec-scenarios
- id: ashui.resource_authoring.example_dashboard
  given:
    - a dashboard screen resource uses AshUI.Resource.DSL.Screen
    - related element resources use AshUI.Resource.DSL.Element
  when:
    - the example is persisted through AshUI.Resource.Authority
  then:
    - the resulting authority graph contains screen metadata, element payloads, and binding/action declarations derived from the authored resources
  covers:
    - ashui.resource_authoring.element_local_semantics
    - ashui.resource_authoring.screen_composition
    - ashui.resource_authoring.persistence_boundary
```

## Verification

```spec-verification
- kind: command
  target: >-
    rg -n "use AshUI.Resource.DSL.Element|ui_bindings|ui_actions|use AshUI.Resource.DSL.Screen|ui_relationships" examples/basic_dashboard/lib test/support/resource_authority_modules.ex guides/user/UG-0001-getting-started.md guides/user/UG-0002-resources.md
  covers:
    - ashui.resource_authoring.element_local_semantics
    - ashui.resource_authoring.screen_composition
    - ashui.resource_authoring.example_dashboard
- kind: command
  target: >-
    rg -n "persists screen records|storage snapshot|not the primary source of truth|Screen.unified_dsl" lib/ash_ui/resource/authority.ex README.md guides/user/UG-0002-resources.md
  covers:
    - ashui.resource_authoring.persistence_boundary
- kind: command
  target: >-
    rg -n "AshUI.Resources.Screen|AshUI.Resources.Element|AshUI.Resources.Binding|default shipped" README.md guides/user/UG-0001-getting-started.md guides/user/UG-0002-resources.md lib/ash_ui/config.ex
  covers:
    - ashui.resource_authoring.storage_support
- kind: command
  target: mix test test/ash_ui/phase_13_integration_test.exs test/ash_ui/examples/basic_dashboard_test.exs
  covers:
    - ashui.resource_authoring.element_local_semantics
    - ashui.resource_authoring.screen_composition
    - ashui.resource_authoring.persistence_boundary
    - ashui.resource_authoring.example_dashboard
```
