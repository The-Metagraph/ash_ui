# Phase 23 - Tutorial Program Scaffold, Directory Contract, and Operations Control Center Baseline

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- `tutorials/`
- `tutorials/README.md`
- `tutorials/chapters/*`
- `tutorials/code/*`
- `tutorials/operations_control_center/*`
- `AshUI.Resource.Authority`
- `AshUI.Resource.DSL.Screen`
- `AshUI.Resource.DSL.Element`
- `AshUI.LiveView.Integration`
- the checked-in `examples/*` suite

## Relevant Assumptions / Defaults
- Phases 17-22 are already complete enough that the tutorial can reuse the
  example-suite authoring, styling, and launcher lessons directly
- the tutorial is a maintained product surface under `tutorials/`, not a loose
  collection of guide snippets spread across unrelated directories
- the maintained final tutorial application lives under
  `tutorials/operations_control_center/`
- every chapter has its own standalone checkpoint application under
  `tutorials/code/<NN>-<slug>/` so readers can start from the exact state that
  chapter explains
- every chapter document must explicitly reference its own checkpoint directory
  and the immediately previous checkpoint when it builds incrementally

[ ] 23 Phase 23 - Tutorial Program Scaffold, Directory Contract, and Operations Control Center Baseline
  Define the tutorial product surface under `tutorials/`, establish the
  Operations Control Center application contract, and land the first two
  tutorial milestones around the shell and the core services/incidents
  workspace.

[x] 23.1 Section - Tutorial Product Surface and Directory Contract
    Turn the tutorial into a first-class repo surface with explicit written and
    code-checkpoint structure.

    [x] 23.1.1 Task - Define the tutorial directory and chapter layout
    Establish one maintained filesystem contract for tutorial prose, chapter
    checkpoints, and the final application.

      [x] 23.1.1.1 Subtask - Add `tutorials/README.md` as the landing page for the Operations Control Center tutorial series and explain how the maintained final app differs from per-chapter checkpoint apps.
      [x] 23.1.1.2 Subtask - Add the written tutorial chapter path under `tutorials/chapters/`, from `01-project-shell.md` through `12-production-polish.md`.
      [x] 23.1.1.3 Subtask - Reserve `tutorials/operations_control_center/` as the maintained final tutorial application rather than hiding the final app inside `examples/` or `guides/`.
      [x] 23.1.1.4 Subtask - Reserve `tutorials/code/01-project-shell/` through `tutorials/code/12-production-polish/` as standalone checkpoint Mix/Phoenix apps.

    [x] 23.1.2 Task - Define chapter-to-code reference rules
    Ensure the prose and code remain synchronized instead of drifting into
    unrelated artifacts.

      [x] 23.1.2.1 Subtask - Define a mandatory "Code for this chapter" reference block in every chapter that links to the exact checkpoint directory under `tutorials/code/`.
      [x] 23.1.2.2 Subtask - Define how each chapter references the immediately previous checkpoint when readers are expected to build incrementally.
      [x] 23.1.2.3 Subtask - Define how chapters can cite supporting `examples/*` apps as background material without telling readers to author directly against the example suite.
      [x] 23.1.2.4 Subtask - Define drift rules that reject missing chapter-to-code references, missing checkpoint directories, or mismatches between chapter names and checkpoint slugs.

  [ ] 23.2 Section - Shared Domain, Theme, and Seed Baseline
    Define the real application that the tutorial is going to build rather than
    treating widget coverage as an abstract checklist.

    [ ] 23.2.1 Task - Define the Operations Control Center baseline
    Establish the shared domain, actor, and style contract that every later
    chapter builds on.

      [ ] 23.2.1.1 Subtask - Define the initial Ash-domain resources for `Service`, `Incident`, `Cluster`, `Deployment`, `Runbook`, and `Operator`, including the minimum relationships needed for the tutorial story.
      [ ] 23.2.1.2 Subtask - Define representative actor profiles such as `admin`, `on_call_operator`, and `viewer` so later chapters can teach permission-aware screens honestly.
      [ ] 23.2.1.3 Subtask - Reuse the Ash HQ visual baseline from the example suite for the tutorial shell while allowing the tutorial app to compose multiple widgets on one screen.
      [ ] 23.2.1.4 Subtask - Define the seed fixtures that give later chapters stable incidents, services, deploys, logs, metrics, and topology data to work with.

  [ ] 23.3 Section - Chapters 1 and 2 Initial Tutorial Milestones
    Land the first working tutorial checkpoints so the series starts from a
    real app rather than only a directory skeleton.

    [ ] 23.3.1 Task - Implement Chapter 1, Project Shell and Home Dashboard
    Create the tutorial's first runnable application state and written chapter.

      [ ] 23.3.1.1 Subtask - Implement `tutorials/code/01-project-shell/` and the matching final-app baseline with the shared Ash HQ shell, navigation frame, and resource-authority screen bootstrap.
      [ ] 23.3.1.2 Subtask - Teach the home dashboard through foundational widgets such as `text`, `label`, `button`, `icon`, `link`, `separator`, `spacer`, `content`, `box`, `row`, `column`, and `grid`.
      [ ] 23.3.1.3 Subtask - Add `tutorials/chapters/01-project-shell.md` with explicit references to `tutorials/code/01-project-shell/` and the exact modules/resources introduced in that checkpoint.
      [ ] 23.3.1.4 Subtask - Ensure the chapter explains the default `live_ui` LiveView host path while keeping optional alternate-runtime previews clearly secondary.

    [ ] 23.3.2 Task - Implement Chapter 2, Services and Incidents Workspace
    Add the first realistic operational workspace around live application data.

      [ ] 23.3.2.1 Subtask - Implement `tutorials/code/02-services-and-incidents/` with list and detail screens for services and active incidents.
      [ ] 23.3.2.2 Subtask - Teach the workspace through `list`, `table`, `tabs`, `status`, and related layout widgets without collapsing the entire tutorial into one monolithic screen resource.
      [ ] 23.3.2.3 Subtask - Add seed-backed service and incident records that make the dashboard and detail views feel like a real small operations console.
      [ ] 23.3.2.4 Subtask - Add `tutorials/chapters/02-services-and-incidents.md` with exact references to `tutorials/code/02-services-and-incidents/` and the new screen/element resources.

  [ ] 23.4 Section - Phase 23 Integration Tests
    Validate the tutorial scaffold, the directory contract, and the first two
    checkpoints before later chapters layer on more behavior.

    [ ] 23.4.1 Task - Tutorial scaffold and early-milestone scenarios
    Prove the tutorial behaves like one coherent product surface from the
    outset.

      [ ] 23.4.1.1 Subtask - Verify the `tutorials/` directory, chapter documents, maintained final app, and chapter checkpoint directories all exist and follow the documented naming contract.
      [ ] 23.4.1.2 Subtask - Verify `tutorials/code/01-project-shell/` and `tutorials/code/02-services-and-incidents/` boot as independent Mix projects and mount seeded resource-authority screens successfully.
      [ ] 23.4.1.3 Subtask - Verify the maintained final app and the Chapter 2 checkpoint both compile from authoritative screen and element resources rather than detached screen documents.
      [ ] 23.4.1.4 Subtask - Verify Chapters 1 and 2 each reference their exact checkpoint directory and any supporting example-app source material explicitly.
