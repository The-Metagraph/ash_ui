# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and the project uses semantic versioning for tagged releases.

## Unreleased

### Added

- release readiness assets under `release/`
- release validation and rollback test scripts

### Changed

- expanded conformance coverage
- added telemetry and dashboards for major runtime operations
- completed user and developer documentation for current architecture
- renamed the Elm-backed web renderer from `web_ui` / `WebUI.Renderer` / `AshUI.Rendering.WebUIAdapter` / `:html` to `elm_ui` / `ElmUI.Renderer` / `AshUI.Rendering.ElmUIAdapter` / `:elm`
- removed the superseded screen-document-authority authoring path; persisted screens now accept only `ash_ui/resource_authority` payloads sourced from screen and element resources
- removed `AshUI.Authoring.Screen`; screen persistence now goes directly through `AshUI.Resource.Authority`
- removed the superseded document-first compiler path; `AshUI.Compiler` and incremental recompilation now accept only resource-authority screen payloads regenerated from the current screen/element graph
