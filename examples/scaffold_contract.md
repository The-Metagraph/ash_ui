# Resource-Authority Example App Scaffold

This document defines the reusable app shape that every standalone Ash UI
example must follow.

It mirrors the sibling `unified_ui` example-app layout by directory name while
rebuilding each app as a resource-authority Ash UI application instead of an
older transitional example surface.

## Per-App Layout

Every future example app under `examples/<directory_name>/` should start from
this layout:

```text
examples/<directory_name>/
├── README.md
├── mix.exs
├── config/
│   ├── config.exs
│   └── dev.exs
├── assets/
│   └── css/app.css
├── lib/
│   ├── <app>.ex
│   ├── <app>/application.ex
│   ├── <app>/example_seeds.ex
│   ├── <app>/runtime_domain.ex
│   ├── <app>/runtime/*.ex
│   ├── <app>/ui_storage_domain.ex
│   ├── <app>/ui_screen.ex
│   ├── <app>/ui_element.ex
│   ├── <app>/ui_binding.ex
│   ├── <app>/examples/<directory_name>_screen.ex
│   ├── <app>/examples/<directory_name>_subject_element.ex
│   ├── <app>/examples/<directory_name>_story_element.ex
│   ├── <app>/examples/<directory_name>_signal_preview_element.ex
│   └── <app>_web/
│       ├── endpoint.ex
│       ├── router.ex
│       ├── live/example_live.ex
│       └── components/example_shell.ex
└── test/
    ├── support/*.ex
    └── <app>/**/*_test.exs
```

The exact helper element set can expand per app, but the storage, runtime,
screen, host, and review-surface responsibilities above are required.

The app-local `assets/css/app.css` should vendor the shared Ash HQ baseline
from [ash_hq_theme_tokens.css](/home/ducky/code/unified/ash_ui/examples/ash_hq_theme_tokens.css:1)
instead of inventing a new shell for each example.

## Required Resource-Authority Modules

Every app must provide these authored module roles:

- One screen resource module, usually
  `<App>.Examples.<DirectoryName>Screen`, using `AshUI.Resource.DSL.Screen`.
- One or more subject element resources that foreground the primary widget or
  construct for the directory.
- One story element resource that feeds the reviewer-facing `Meaningful
  Interaction Story` surface.
- One signal-preview element resource that feeds the reviewer-facing
  `Canonical Signal Preview` surface.
- Any additional helper elements needed for shell framing, companion controls,
  or example-local notes.

Bindings and actions belong on the owning screen or element resource. Example
apps should not ship detached serialized payloads, superseded helper-driven
definitions, or monolithic inline trees that bypass the element relationship
graph.

## Relationship-First Review Guidance

Layout, navigation, and display examples carry an additional review bar because
their value is primarily structural.

Reviewers should reject changes in those families when:

- the screen resource grows a large `inline_fragment` or otherwise authors the
  primary subject tree directly
- the persisted screen roots stop at the review shell surfaces and start owning
  the subject internals instead of delegating to related element resources
- navigation, layout, or display controls move from related element resources
  into one monolithic screen-level fragment
- a custom example shell (`custom:*`) starts hiding the relationship graph that
  should remain visible in persisted element resources

The preferred shape is:

- screen roots only for shell glue such as the demo panel, story panel, signal
  preview, and low-noise support note surfaces
- one subject element resource plus related child element resources for the
  primary structure and companion controls
- bindings and actions kept on the child resources that actually own the
  interaction story

The intended resource pattern matches the package's existing support fixtures:

- app-local element base modules may follow the relationship-and-binding shape
  exercised in [test/support/resource_authority_modules.ex](/home/ducky/code/unified/ash_ui/test/support/resource_authority_modules.ex:1)
- app-local UI storage resources may follow the configurable storage shape
  exercised in [test/support/ui_storage_test_resources.ex](/home/ducky/code/unified/ash_ui/test/support/ui_storage_test_resources.ex:1)

## Required Host-App Modules

Every app must provide these host-side modules:

- `<App>.UiStorageDomain`
- `<App>.UiScreen`
- `<App>.UiElement`
- `<App>.UiBinding`
- `<App>.RuntimeDomain`
- `<App>.Runtime.*` resources or fixtures needed by bindings and actions
- `<App>.Web.Endpoint`
- `<App>.Web.Router`
- `<App>.Web.ExampleLive`
- `<App>.Web.Components.ExampleShell`
- `<App>.ExampleSeeds`

The default host configuration should wire `:ash_ui` to the app-local storage
resources and runtime domains:

```elixir
config :ash_ui, :ui_storage,
  domain: <App>.UiStorageDomain,
  resources: [
    screen: <App>.UiScreen,
    element: <App>.UiElement,
    binding: <App>.UiBinding
  ],
  repo: nil

config :ash_ui, :ash_domains, [<App>.RuntimeDomain]
```

`<App>.Web.ExampleLive` is the maintained browser mount surface. Its `mount/3`
should assign `current_user`, `ash_ui_storage`, and `ash_ui_domains`, then
call `AshUI.LiveView.Integration.mount_ui_screen/3` with the seeded screen
name.

## Review Surface Contract

Every app exposes one primary route at `/` and mounts one seeded screen whose
persisted name is `example/<directory_name>`.

The seeded screen must render three reviewer-visible zones:

- the focused demonstration panel for the primary widget or construct
- a `Meaningful Interaction Story` panel that explains what to try and what
  reviewer-visible change should occur
- a `Canonical Signal Preview` panel that exposes the important binding or
  action signal details in structured form

Directory, route, and DOM identifiers must stay predictable:

- screen name: `example/<directory_name>`
- screen route: `/`
- outer shell id: `example-<directory_name>-shell`
- demo panel id: `example-<directory_name>-demo`
- story panel id: `example-<directory_name>-story`
- signal preview id: `example-<directory_name>-signal-preview`

Each app-local README should keep the same review rhythm used by the sibling
suite:

- `Run`
- `Try It`
- `Expect`
- `Validate`

The `Run` section should explain the maintained launcher explicitly:

- `mix example.start` starts the default `live_ui` renderer inside the Phoenix
  LiveView host shell
- `mix example.start live_ui`, `mix example.start elm_ui`, and
  `mix example.start desktop_ui` select the runtime preview by name
- the same runtime can be reviewed through `/?runtime=<name>` once the server
  is already running

## Bootstrap And Seed Conventions

The default storage strategy for example apps is ETS-backed UI storage plus
ETS-backed runtime resources. That is the baseline unless an example needs
durable relational queries, file-upload persistence, restart-stable history, or
another capability that ETS cannot represent honestly.

Repo-backed fixtures are allowed only when the example's primary story depends
on that persistence boundary. When that happens, the app README and
`examples/catalog.tsv` notes should call it out explicitly.

Every app must expose app-local seed helpers with this contract:

- `seed!/1` creates the representative runtime actors and fixtures for the app
- `seed!/1` persists the screen through `AshUI.Resource.Authority.create/2`
- `seed!/1` returns the mounted review context, including the actor and screen
- `reset!/0` clears seeded UI storage and runtime state so tests and local
  review can reseed from a clean slate
- tests call the seed helpers directly instead of hand-assembling runtime state

`seed!/1` should prefer a small default actor set:

- one admin or maintainer actor for full review access
- one standard viewer actor where authorization differences matter
- app-local domain records that make bindings, list views, and actions
  reviewer-visible without requiring hidden setup

The reset or reseed path may be wrapped by `mix example.reset` later, but the
stable contract in Phase 17 is the app-local module API, not a shared example
support package.
