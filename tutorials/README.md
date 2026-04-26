# Ash UI Tutorials

This directory is the maintained landing page for the Ash UI tutorial program.

The tutorial series builds one realistic **Operations Control Center**
application over time instead of presenting disconnected widget walkthroughs.

## Directory Contract

- `tutorials/operations_control_center/` is the maintained final application.
- `tutorials/chapters/` contains the written tutorial chapters.
- `tutorials/code/<NN>-<slug>/` contains the standalone checkpoint app for one
  chapter.
- `tutorials/chapter_metadata.json` is the maintained machine-readable chapter
  index used for validation and review.

## Final App Versus Checkpoints

The maintained final application under `tutorials/operations_control_center/`
tracks the completed tutorial story.

The checkpoint apps under `tutorials/code/` are intentionally narrower. Each
one freezes the exact state a reader should have after finishing one chapter so
they can start there directly without replaying the entire series.

## Supporting Example Policy

Chapters may cite `examples/*` as supporting reference material when a focused
widget example helps clarify one concept quickly.

Those example apps are background material only. Readers should continue the
tutorial inside the checkpoint app for that chapter and not author the tutorial
application directly inside `examples/`.

## Chapter Index

<!-- ash_ui:tutorial-index:start -->
1. `01-project-shell`
   Code checkpoint: `tutorials/code/01-project-shell/`
2. `02-services-and-incidents`
   Code checkpoint: `tutorials/code/02-services-and-incidents/`
3. `03-filtering-and-search`
   Code checkpoint: `tutorials/code/03-filtering-and-search/`
4. `04-operator-actions-and-forms`
   Code checkpoint: `tutorials/code/04-operator-actions-and-forms/`
5. `05-safe-overlays-and-guards`
   Code checkpoint: `tutorials/code/05-safe-overlays-and-guards/`
6. `06-runbooks-and-attachments`
   Code checkpoint: `tutorials/code/06-runbooks-and-attachments/`
7. `07-live-diagnostics`
   Code checkpoint: `tutorials/code/07-live-diagnostics/`
8. `08-topology-and-navigation`
   Code checkpoint: `tutorials/code/08-topology-and-navigation/`
9. `09-metrics-and-capacity`
   Code checkpoint: `tutorials/code/09-metrics-and-capacity/`
10. `10-runtime-introspection`
    Code checkpoint: `tutorials/code/10-runtime-introspection/`
11. `11-roles-and-policies`
    Code checkpoint: `tutorials/code/11-roles-and-policies/`
12. `12-production-polish`
    Code checkpoint: `tutorials/code/12-production-polish/`
<!-- ash_ui:tutorial-index:end -->
