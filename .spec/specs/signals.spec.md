# Signals

Canonical signal normalization and CloudEvents transport helpers for Ash UI bindings.

## Intent

Define how Ash UI turns bindings into canonical signal structures and how those signals serialize into transport-friendly envelopes.

```spec-meta
id: ash_ui.signals
kind: module
status: active
summary: Binding-to-signal normalization, transform helpers, signal structs, and CloudEvents conversion.
surface:
  - specs/contracts/binding_contract.md
  - lib/ash_ui/signal.ex
  - lib/ash_ui/signal/struct.ex
  - lib/ash_ui/signal/cloud_events.ex
```

## Requirements

```spec-requirements
- id: ash_ui.signals.binding_normalization
  statement: AshUI.Signal shall normalize value, list, and action bindings plus map or string sources into canonical bidirectional, collection, and event signal shapes.
  priority: must
  stability: stable
- id: ash_ui.signals.transform_helpers
  statement: Signal transformation helpers shall support the shipped uppercase, lowercase, trim, default, and format operations.
  priority: should
  stability: stable
- id: ash_ui.signals.cloud_events_transport
  statement: Signal structs and CloudEvents helpers shall build validated signal envelopes, round-trip individual events, and batch multiple signals for transport.
  priority: must
  stability: evolving
```

## Verification

```spec-verification
- kind: command
  target: mix test test/ash_ui/signal_test.exs test/ash_ui/signal/struct_test.exs test/ash_ui/signal/cloud_events_test.exs
  execute: true
  covers:
    - ash_ui.signals.binding_normalization
    - ash_ui.signals.transform_helpers
    - ash_ui.signals.cloud_events_transport
```
