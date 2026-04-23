# Ash UI Guides

This directory contains user and developer documentation for the Ash UI
framework.

## Guide Structure

```
guides/
├── user/                    # User guides (UG-XXXX)
├── developer/               # Developer guides (DG-XXXX)
├── contracts/               # Guide documentation contracts
├── conformance/             # Guide conformance tracking
└── templates/               # Guide templates
```

## User Guides (UG-*)

User guides are written for application developers building screens with the
current AshUI architecture.

| Guide ID | Title | Audience | Status |
|---|---|---|---|
| [UG-0001](user/UG-0001-getting-started.md) | Getting Started with AshUI | Application Developers | Active |
| [UG-0002](user/UG-0002-authoring-screens-elements-and-relationships.md) | Authoring Screens, Elements, and Relationships | Application Developers | Active |
| [UG-0003](user/UG-0003-widget-types-properties-and-signals.md) | Widget Types, Properties, and Signals | Application Developers | Active |
| [UG-0004](user/UG-0004-bindings-actions-and-forms.md) | Bindings, Actions, and Forms | Application Developers | Active |
| [UG-0005](user/UG-0005-liveview-runtime-and-rendering.md) | LiveView Runtime and Rendering | Application Developers | Active |
| [UG-0006](user/UG-0006-authorization-and-runtime-safety.md) | Authorization and Runtime Safety | Application Developers | Active |
| [UG-0007](user/UG-0007-data-surfaces-and-composition-patterns.md) | Data Surfaces and Composition Patterns | Application Developers | Active |
| [UG-0008](user/UG-0008-migration-from-older-ash-ui-models.md) | Migration from Older AshUI Models | Application Developers | Active |

## Developer Guides (DG-*)

Developer guides are written for contributors to the Ash UI framework itself.

| Guide ID | Title | Audience | Status |
|---|---|---|---|
| [DG-0001](developer/DG-0001-architecture-and-control-planes.md) | Architecture and Control Planes | Framework Developers | Active |
| [DG-0002](developer/DG-0002-storage-resource-authority-and-configuration.md) | Storage, Resource Authority, and Configuration | Framework Developers | Active |
| [DG-0003](developer/DG-0003-compiler-canonical-iur-and-renderers.md) | Compiler, Canonical IUR, and Renderers | Framework Developers | Active |
| [DG-0004](developer/DG-0004-runtime-bindings-and-authorization.md) | Runtime, Bindings, and Authorization | Framework Developers | Active |
| [DG-0005](developer/DG-0005-testing-conformance-and-governance.md) | Testing, Conformance, and Governance | Framework Developers | Active |
| [DG-0006](developer/DG-0006-contribution-and-release-workflow.md) | Contribution and Release Workflow | Framework Developers | Active |

## Guide Contracts

See [contracts/](contracts/) for documentation standards and requirements.

## Conformance

See [conformance/](conformance/) for guide conformance tracking.

## Contributing

When creating or revising guides:

1. Start from the appropriate template in [templates/](templates/)
2. Follow the guide contract metadata and section requirements
3. Link to valid `REQ-*` and `SCN-*` entries
4. Update `guides/README.md` and `guides/conformance/guide_conformance_matrix.md`

## Related Documentation

- [User guide index](user/README.md)
- [Developer guide index](developer/README.md)
- [../specs/](../specs/) - Technical specifications
- [../rfcs/](../rfcs/) - Design proposals
