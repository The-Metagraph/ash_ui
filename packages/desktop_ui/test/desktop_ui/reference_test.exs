defmodule DesktopUi.ReferenceTest do
  use ExUnit.Case, async: true

  test "reference and inspection surfaces expose runtime seams and responsibilities" do
    reference = DesktopUi.reference()
    summary = DesktopUi.info()

    assert reference.widgets.validation_state.direct_native_scaffold == :ready
    assert reference.widgets.registration_model.direct_native_only
    assert reference.runtime.validation_state == :runtime_backbone_ready
    assert reference.sdl3.foundation.runtime_foundation == :sdl3
    assert reference.sdl3.renderer.first_backend == :sdl_renderer
    assert reference.sdl3.renderer.future_backend == :sdl_gpu
    assert reference.sdl3.frame_encoder.payload_family == :frame
    assert reference.sdl3.interaction_script.format == :tab_separated_key_values
    assert reference.sdl3.renderer_completeness == :widget_complete_interactive
    assert reference.sdl3.visible_runner.interactive_execution
    assert length(reference.sdl3.manual_review_workflow.compiled_visible_review) > 0
    assert reference.packaging.contract.output_family == :packaged_target_directory
    assert Enum.any?(reference.packaging.target_packages, &(&1.target == :macos))
    assert reference.packaging.validation_state == :target_packaging_surface_ready
    assert reference.platform.validation_state == :platform_adapter_ready
    assert reference.layout.validation_state.advanced_display_systems == :ready
    assert reference.layer.validation_state.multiwindow_coordination == :ready

    assert reference.transport.integration_points == [
             :runtime,
             :platform_input_normalization,
             :canonical_signal_translation,
             :transport_diagnostics
           ]

    assert :command in reference.transport.families
    assert :shortcut in reference.transport.input_families
    assert :navigation in reference.transport.boundary_crossing_families
    assert :focus_ring in reference.style.primitives.colors
    assert reference.style.validation_state.direct_native_surface == :ready
    assert reference.theme.default_theme == :desktop_default
    assert :high_contrast in reference.theme.catalog_ids
    assert reference.theme.validation_state.shared_style_model == :ready
    assert reference.platform.integration.mismatches == []
    assert reference.artifacts.workflows.windows.packaging == [:zip_archive, :msi_installer]
    assert reference.artifacts.boundary_policy.transport_semantics_preserved
    assert reference.artifacts.validation_state.packaging_boundaries == :ready

    assert reference.continuity.seams == [
             :widget_identity,
             :style_resolution,
             :platform_semantics
           ]

    assert reference.inspection.continuity_contract.validation == [:pass, :fail]
    assert DesktopUi.Inspect in reference.tooling.preview_surfaces
    assert reference.tooling.validation_state.runtime_validation == :runtime_backbone_ready
    assert Enum.any?(reference.validate.release_gates, &(&1.id == :tooling_surface))
    assert reference.validate.validation_report.tooling_surface.status == :pass

    assert :style_resolution in reference.platform.capability_contract.shared_semantics_outside_platform

    assert reference.transport.modules == [
             DesktopUi.Transport,
             DesktopUi.Transport.Normalize,
             DesktopUi.Transport.Signal,
             DesktopUi.Transport.Diagnostics,
             DesktopUi.Transport.Error
           ]

    assert reference.inspection.package_overview.runtime_foundation == :sdl3
    assert reference.inspection.sdl3_adapter_surface.foundation.runtime_foundation == :sdl3

    assert reference.inspection.sdl3_adapter_surface.validation_state.adapter ==
             :app_handoff_ready

    assert reference.inspection.sdl3_adapter_surface.validation_state.frame_encoder ==
             :frame_encoding_ready

    assert reference.inspection.shared_runtime_contract.direct_native_and_canonical_share_runtime
    assert reference.inspection.shared_runtime_contract.lifecycle_model == :callback_oriented
    assert reference.inspection.transport_contract.no_platform_leakage_guarantee
    assert reference.inspection.layering_contract.multiwindow_runtime
    assert reference.inspection.validation_surface.widgets.focus_metadata == :ready
    assert reference.responsibilities.bounded_platform_variation

    assert summary.package == :desktop_ui
    assert summary.sdl3.foundation.runtime_foundation == :sdl3
    assert summary.sdl3.renderer_completeness == :widget_complete_interactive
    assert length(summary.sdl3.manual_review_workflow.expectations) > 0
    assert summary.packaging.contract.output_family == :packaged_target_directory
    assert summary.packaging.validation_state == :target_packaging_surface_ready
    assert :window in summary.widgets.families
    assert :window in summary.widgets.kinds
    assert :viewport in summary.layout.kinds
    assert :overlay in summary.layer.kinds
    assert :command in summary.transport.families
    assert summary.style.validation_state.component_variants == :ready
    assert summary.theme.default_theme == :desktop_default
    assert summary.platform.integration.mismatches == []
    assert summary.artifacts.workflows.macos.packaging == [:app_bundle, :signed_zip]
    assert summary.artifacts.boundary_policy.packaging_distinct_from_renderer_logic
    assert summary.continuity.seams == [:widget_identity, :style_resolution, :platform_semantics]

    assert Enum.any?(
             summary.tooling.mix_tasks,
             &String.starts_with?(&1, "mix desktop_ui.inspect")
           )

    assert Enum.any?(summary.validate.release_gates, &(&1.id == :artifact_validation))
    assert summary.inspection.validation.runtime == :runtime_backbone_ready
  end
end
