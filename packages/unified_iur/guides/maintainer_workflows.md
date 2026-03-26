# Maintainer Workflows

This guide describes how to evolve `UnifiedIUR` safely.

## Adding a New Canonical Construct Family

When adding a new canonical construct:

1. Add the constructor and any supporting canonical data structures.
2. Add or update the reference fixture coverage in `UnifiedIUR.Fixtures`.
3. Update the expected parity catalog for `unified_ui`.
4. Add focused tests plus any phase-level integration coverage.
5. Run `mix unified_iur.validate --strict`.

## Evaluating `unified_ui` Parity

Changes to canonical families should be reviewed against the paired
`unified_ui` contract. At minimum:

1. Compare the canonical family to the expected `unified_ui` parity catalog.
2. Verify the authored DSL can represent the new or changed canonical shape.
3. Record paired review expectations before widening the canonical surface.

## Assessing Runtime Compatibility

Before merging canonical shape changes, assess their impact on `live_ui`,
`elm_ui`, and `desktop_ui`:

1. Inspect the changed fixtures and diffs.
2. Confirm attachment and slot semantics remain portable.
3. Verify no runtime-local structs or assumptions have leaked into canonical
   values.
4. Use compatibility reports to understand runtime-library risk.

## Recommended Review Loop

For any meaningful canonical change, run:

1. `mix test`
2. `mix unified_iur.inspect FIXTURE_ID --format diagnostics`
3. `mix unified_iur.export FIXTURE_ID --format snapshot`
4. `mix unified_iur.validate --strict`
