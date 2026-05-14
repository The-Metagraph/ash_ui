defmodule DesktopUi.DocumentationTest do
  use ExUnit.Case, async: false

  @moduletag timeout: 180_000

  test "documentation surface lists maintained guides and files exist" do
    docs = DesktopUi.Tooling.documentation_surface()
    package_root = Path.expand("../..", __DIR__)

    assert docs == [
             "README.md",
             "guides/runtime_backbone.md",
             "guides/native_runtime_and_examples.md",
             "guides/canonical_rendering_and_transport.md",
             "guides/styling_platforms_and_artifacts.md",
             "guides/maintainer_workflows.md"
           ]

    assert Enum.all?(docs, fn relative_path ->
             package_root
             |> Path.join(relative_path)
             |> File.exists?()
           end)
  end

  test "reference and info summary helpers expose maintained review surfaces" do
    reference_examples = DesktopUi.Reference.example_summary()
    info_examples = DesktopUi.Info.example_summary()
    reference_transport = DesktopUi.Reference.transport_summary()
    info_transport = DesktopUi.Info.transport_summary()
    reference_style = DesktopUi.Reference.style_summary()
    info_style = DesktopUi.Info.style_summary()
    reference_artifacts = DesktopUi.Reference.artifact_summary()
    info_artifacts = DesktopUi.Info.artifact_summary()
    reference_sdl3 = DesktopUi.Reference.sdl3_summary()
    info_sdl3 = DesktopUi.Info.sdl3_summary()

    assert :native_styled_review in reference_examples.native_ids
    assert :canonical_styled_review in reference_examples.canonical_ids
    assert :styled_continuity_review in reference_examples.comparison_ids
    assert :style_review in Map.keys(reference_examples.coverage_matrix.workflows)
    assert :style_review in info_examples.workflows

    assert :canonical_signal_translation in reference_transport.integration_points
    assert :command in reference_transport.families
    assert :shortcut in info_transport.input_families

    assert reference_style.style.validation_state.direct_native_surface == :ready
    assert reference_style.theme.default_theme == :desktop_default
    assert :platform_semantics in reference_style.continuity.seams
    assert info_style.theme.default_theme == :desktop_default

    assert reference_artifacts.target_platforms == [:windows, :macos, :linux]
    assert reference_artifacts.validation_state.packaging_boundaries == :ready
    assert info_artifacts.target_platforms == [:windows, :macos, :linux]
    assert reference_sdl3.foundation.runtime_foundation == :sdl3
    assert reference_sdl3.renderer.first_backend == :sdl_renderer
    assert reference_sdl3.frame_encoder.payload_family == :frame
    assert reference_sdl3.visible_runner.interactive_execution
    assert length(reference_sdl3.manual_review_workflow.compiled_visible_review) > 0
    assert info_sdl3.renderer_completeness == :widget_complete_interactive
  end

  test "documentation and validation surfaces expose release and traceability guardrails" do
    reference = DesktopUi.reference()
    summary = DesktopUi.info()

    assert reference.documentation.guides == DesktopUi.Tooling.documentation_surface()
    assert reference.documentation.maintainer_commands == DesktopUi.Tooling.mix_tasks()

    assert reference.documentation.shared_runtime_contract.direct_native_and_canonical_share_runtime
    assert reference.documentation.sdl3_adapter_surface.foundation.runtime_foundation == :sdl3

    assert ".spec/specs/platform_runtimes.spec.md" in reference.documentation.traceability_targets

    assert ".spec/specs/desktop_ui/sdl3_runtime_rendering.spec.md" in reference.documentation.traceability_targets

    assert reference.validate.inspect == DesktopUi.Inspect
    assert reference.validate.validate == DesktopUi.Validate
    assert :sdl3_adapter_surface in reference.validate.validation_sections
    assert :documentation_surface in reference.validate.validation_sections
    assert :traceability_alignment in reference.validate.validation_sections
    assert reference.validate.release_readiness_modes == [:summary, :strict]
    assert Enum.any?(reference.validate.release_gates, &(&1.id == :sdl3_adapter_surface))
    assert reference.validate.validation_report.sdl3_adapter_surface.status == :pass
    assert reference.validate.documentation_surface.status == :pass
    assert reference.validate.traceability_alignment.status == :pass

    assert Enum.any?(
             reference.validate.evolution_rules,
             &(&1.id == :sdl3_renderer_first_backend)
           )

    assert summary.validate.documentation_surface == :pass
    assert summary.validate.traceability_alignment == :pass
    assert summary.validate.release_readiness == :pass
    assert summary.documentation.guides == DesktopUi.Tooling.documentation_surface()
    assert DesktopUi.Inspect in summary.documentation.preview_surfaces
  end
end
