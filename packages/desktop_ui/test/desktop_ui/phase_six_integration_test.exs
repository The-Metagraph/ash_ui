defmodule DesktopUi.PhaseSixIntegrationTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "maintained examples and preview workflows expose native canonical and mixed review paths through one tooling surface" do
    assert {:ok, native_preview} = DesktopUi.Tooling.preview_example(:native_styled_review)
    assert {:ok, canonical_preview} = DesktopUi.Tooling.preview_example(:canonical_styled_review)
    assert {:ok, mixed_preview} = DesktopUi.Tooling.preview_example(:styled_continuity_review)

    assert native_preview.metadata.category == :native
    assert native_preview.surface.runtime.source_kind == :native
    assert native_preview.surface.runtime.theme == :high_contrast

    assert canonical_preview.metadata.category == :canonical
    assert canonical_preview.surface.runtime.source_kind == :canonical
    assert canonical_preview.surface.runtime.theme == :high_contrast

    assert mixed_preview.metadata.category == :mixed
    assert mixed_preview.surface.parity.widget_identity_match?
    assert mixed_preview.surface.parity.style_resolution_match?
    assert mixed_preview.surface.parity.platform_semantics_match?

    reference = DesktopUi.Reference.package_reference()

    assert :styled_continuity_review in reference.examples.comparison_ids
    assert :style_review in Map.keys(reference.examples.coverage_matrix.workflows)
    assert DesktopUi.Inspect in reference.tooling.preview_surfaces
  end

  test "inspect and validate tasks provide one repeatable maintainer command path" do
    inspect_output =
      capture_io(fn ->
        Mix.Task.reenable("app.start")
        Mix.Task.reenable("desktop_ui.inspect")
        Mix.Tasks.DesktopUi.Inspect.run(["styled_continuity_review", "--format", "comparison"])
      end)

    validate_output =
      capture_io(fn ->
        Mix.Task.reenable("app.start")
        Mix.Task.reenable("desktop_ui.validate")
        Mix.Tasks.DesktopUi.Validate.run(["--format", "summary"])
      end)

    assert inspect_output =~ "styled_continuity_review"
    assert inspect_output =~ "style_resolution_match?"
    assert validate_output =~ "DesktopUi validation summary"
    assert validate_output =~ "documentation surface passing?: true"
    assert validate_output =~ "traceability alignment passing?: true"
    assert validate_output =~ "release ready?: true"
  end

  test "documentation release readiness and evolution guardrails stay aligned" do
    package_root = Path.expand("../..", __DIR__)
    readme = File.read!(Path.join(package_root, "README.md"))

    canonical_guide =
      File.read!(Path.join(package_root, "guides/canonical_rendering_and_transport.md"))

    maintainer_guide = File.read!(Path.join(package_root, "guides/maintainer_workflows.md"))
    report = DesktopUi.Validate.validation_report()
    reference = DesktopUi.reference()
    summary = DesktopUi.info()

    assert readme =~ "mix spec.traceability.generate desktop_ui"
    assert readme =~ "UnifiedIUR"
    assert canonical_guide =~ "DesktopUi.Transport"
    assert canonical_guide =~ "DesktopUi.Renderer"
    assert maintainer_guide =~ "does not own authored `UnifiedUi` or canonical `UnifiedIUR`"

    assert report.documentation_surface.status == :pass
    assert report.traceability_alignment.status == :pass
    assert report.release_readiness.status == :pass
    assert Enum.all?(report.release_readiness.gates, &(&1.status == :pass))
    assert ".spec/specs/signal_transport.spec.md" in DesktopUi.Validate.traceability_targets()
    assert ".spec/specs/platform_runtimes.spec.md" in reference.documentation.traceability_targets
    assert summary.validate.release_readiness == :pass

    assert Enum.any?(
             report.release_readiness.evolution_rules,
             &(&1.id == :desktop_ui_not_dsl_or_iur_owner)
           )
  end
end
