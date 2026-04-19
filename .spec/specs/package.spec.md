# Ash UI Package Boundary

Ash UI ships as an Elixir package that owns the resource-first framework
surface, boots the runtime services, and composes optional renderer packages at
the root boundary.

## Intent

Capture the package-level contract that ties the root Mix project, OTP
application, example compile surface, optional renderer packages, and Spec Led
tooling together.

```spec-meta
id: ashui.package
kind: package
status: active
summary: The root Ash UI package publishes the ash_ui application, boots runtime services, includes the shipped example in dev/test compilation, keeps renderer dependencies optional, and carries Spec Led tooling for local governance.
surface:
  - mix.exs
  - lib/ash_ui.ex
  - lib/ash_ui/application.ex
  - README.md
  - examples/basic_dashboard/mix.exs
decisions:
  - ashui.decision.pluggable_ui_storage
  - ashui.decision.element_resource_authority
  - ashui.decision.elm_ui_package_rename
```

## Requirements

```spec-requirements
- id: ashui.package.identity_and_boot
  statement: The root Mix project shall publish app :ash_ui, start AshUI.Application, and expose package-level helpers through the AshUI module.
  priority: must
  stability: stable
- id: ashui.package.example_compile_surface
  statement: Development and test compilation shall include the shipped basic dashboard example so example regressions are caught during ordinary local work.
  priority: should
  stability: stable
- id: ashui.package.optional_renderer_boundary
  statement: live_ui, elm_ui, and desktop_ui shall remain optional path dependencies of the root package boundary rather than mandatory runtime prerequisites.
  priority: must
  stability: stable
- id: ashui.package.specled_tooling
  statement: Development and test environments shall include Spec Led tooling so the repository can validate the .spec workspace locally and in CI.
  priority: must
  stability: stable
```

## Scenarios

```spec-scenarios
- id: ashui.package.local_dev_boot
  given:
    - a developer checks out the repository
    - the root package dependencies are available
  when:
    - the project compiles or boots in development or test
  then:
    - AshUI.Application starts the runtime services
    - the shipped basic dashboard example is part of the compile surface
    - renderer packages remain optional
    - Spec Led tooling is available for workspace validation
  covers:
    - ashui.package.identity_and_boot
    - ashui.package.example_compile_surface
    - ashui.package.optional_renderer_boundary
    - ashui.package.specled_tooling
```

## Verification

```spec-verification
- kind: command
  target: >-
    rg -n "app: :ash_ui|mod: \\{AshUI\\.Application|def application do|def domain do|def authoring do" mix.exs lib/ash_ui.ex lib/ash_ui/application.ex
  covers:
    - ashui.package.identity_and_boot
    - ashui.package.local_dev_boot
- kind: command
  target: >-
    rg -n "examples/basic_dashboard/lib|elixirc_paths\\(:dev\\)|elixirc_paths\\(:test\\)" mix.exs examples/basic_dashboard/mix.exs README.md
  covers:
    - ashui.package.example_compile_surface
    - ashui.package.local_dev_boot
- kind: command
  target: >-
    rg -n "path: \"packages/live_ui\"|path: \"packages/elm_ui\"|path: \"packages/desktop_ui\"|optional: true" mix.exs
  covers:
    - ashui.package.optional_renderer_boundary
    - ashui.package.local_dev_boot
- kind: command
  target: >-
    rg -n "spec_led_ex|mix spec\\.validate|mix spec\\.check|\\.spec/README\\.md" mix.exs README.md scripts/validate_specs_governance.sh .github/workflows/specs-governance.yml
  covers:
    - ashui.package.specled_tooling
    - ashui.package.local_dev_boot
```
