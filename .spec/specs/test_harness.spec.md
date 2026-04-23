# Test Harness

Shared test bootstrap and reusable support fixtures for Ash UI integration, runtime, storage, and authoring coverage.

## Intent

Define the repository test harness boundary that starts the application, provisions sandboxed data access, and supplies reusable support modules for runtime, storage, and authoring scenarios.

```spec-meta
id: ash_ui.test_harness
kind: policy
status: active
summary: ExUnit bootstrap, sandbox helpers, and reusable fixture modules for runtime, storage, authority, and legacy authoring tests.
surface:
  - guides/developer/DG-0005-testing-conformance-and-governance.md
  - test/test_helper.exs
  - test/support/data_case.ex
  - test/support/mock_user_resources.ex
  - test/support/resource_authority_modules.ex
  - test/support/runtime_test_resources.ex
  - test/support/screen_document_fixtures.ex
  - test/support/ui_storage_test_resources.ex
  - test/support/unified_ui_authoring_modules.ex
```

## Requirements

```spec-requirements
- id: ash_ui.test_harness.bootstrap_and_sandbox
  statement: The repository test harness shall start ExUnit and the Ash UI application with the required runtime domains configured and provide an Ecto sandbox helper for tests that need repo-backed ownership.
  priority: must
  stability: stable
- id: ash_ui.test_harness.runtime_and_storage_fixtures
  statement: The test support layer shall provide reusable runtime-domain, notification, and configurable UI storage fixtures that seed records, sockets, and persisted screens for runtime and storage scenarios.
  priority: must
  stability: stable
- id: ash_ui.test_harness.authority_and_authoring_fixtures
  statement: The test support layer shall provide reusable resource-authority modules, screen document builders, and upstream authoring fixture modules used to exercise authority, compiler, and legacy authoring paths.
  priority: must
  stability: stable
```

## Verification

```spec-verification
- kind: command
  target: mix test test/ash_ui/liveview/phase_4_integration_test.exs test/ash_ui/pluggable_ui_storage_test.exs
  execute: true
  covers:
    - ash_ui.test_harness.bootstrap_and_sandbox
    - ash_ui.test_harness.runtime_and_storage_fixtures
- kind: command
  target: mix test test/ash_ui/phase_9_integration_test.exs test/ash_ui/phase_10_integration_test.exs test/ash_ui/phase_11_integration_test.exs
  execute: true
  covers:
    - ash_ui.test_harness.runtime_and_storage_fixtures
    - ash_ui.test_harness.authority_and_authoring_fixtures
```
