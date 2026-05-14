defmodule DesktopUi.ToolingTest do
  use ExUnit.Case, async: true

  test "inspect workflows preview native, canonical, and mixed examples through one surface" do
    assert {:ok, native_preview} = DesktopUi.Inspect.preview(:native_styled_review)
    assert {:ok, canonical_preview} = DesktopUi.Inspect.preview(:canonical_styled_review)
    assert {:ok, mixed_preview} = DesktopUi.Inspect.preview(:styled_continuity_review)
    assert {:ok, host_execution} = DesktopUi.Inspect.host_execution(:native_foundational)

    assert {:ok, run_execution} =
             DesktopUi.Inspect.run_execution(:native_foundational, linger_ms: 1)

    assert {:ok, rendered_metadata} = DesktopUi.Inspect.render("native_styled_review", :metadata)

    assert {:ok, rendered_diagnostics} =
             DesktopUi.Inspect.render("styled_continuity_review", :diagnostics)

    assert {:ok, rendered_host} =
             DesktopUi.Inspect.render("native_foundational", :host)

    assert native_preview.metadata.category == :native
    assert native_preview.surface.runtime.theme == :high_contrast
    assert canonical_preview.metadata.category == :canonical
    assert canonical_preview.surface.runtime.theme == :high_contrast
    assert mixed_preview.metadata.category == :mixed
    assert mixed_preview.surface.parity.style_resolution_match?
    assert host_execution.status == :ok
    assert host_execution.frame.payload.presentation.presented_frame?
    assert run_execution.execution_mode in [:visible_window, :protocol_fallback]
    assert run_execution.backend in [:compiled_sdl3_host, :elixir_host]
    assert rendered_metadata =~ ":native_styled_review"
    assert rendered_diagnostics =~ "tooling_workflows"
    assert rendered_host =~ ":native_foundational"
  end

  test "validation workflows summarize coverage, runtime behavior, transport, artifacts, and release readiness" do
    coverage = DesktopUi.Validate.example_coverage()
    runtime = DesktopUi.Validate.runtime_behavior()
    transport = DesktopUi.Validate.transport_validation()
    artifacts = DesktopUi.Validate.artifact_validation()
    host_execution = DesktopUi.Validate.host_execution_surface()
    tooling = DesktopUi.Validate.tooling_surface()
    sdl3_adapter = DesktopUi.Validate.sdl3_adapter_surface()
    docs = DesktopUi.Validate.documentation_surface()
    traceability = DesktopUi.Validate.traceability_alignment()
    validation_report = DesktopUi.Validate.validation_report()
    validation_summary = DesktopUi.Validate.validation_summary(validation_report)

    assert coverage.status == :pass
    assert runtime.status == :pass
    assert transport.status == :pass
    assert artifacts.status == :pass
    assert host_execution.status == :pass
    assert sdl3_adapter.status == :pass
    assert tooling.status == :pass
    assert docs.status == :pass
    assert traceability.status == :pass

    assert {:ok, summary_report} = DesktopUi.Validate.release_readiness(:summary)
    assert {:ok, strict_report} = DesktopUi.Validate.release_readiness(:strict)

    assert summary_report.status == :pass
    assert strict_report.status == :pass
    assert summary_report.findings == []
    assert strict_report.findings == []
    assert Enum.all?(summary_report.gates, &(&1.status == :pass))
    assert validation_report.release_readiness.status == :pass
    assert validation_report.host_execution_surface.status == :pass
    assert validation_report.sdl3_adapter_surface.status == :pass
    assert validation_summary =~ "DesktopUi validation summary"
    assert validation_summary =~ "SDL3 adapter surface passing?: true"
    assert validation_summary =~ "host execution surface passing?: true"
    assert validation_summary =~ "widget-complete native rendering?: true"
    assert validation_summary =~ "interactive native execution?: true"
    assert validation_summary =~ "release ready?: true"
    assert validation_report.documentation_surface.status == :pass
    assert validation_report.traceability_alignment.status == :pass
    assert DesktopUi.Tooling.run_catalog().execution.fallback_backend == :elixir_host

    assert DesktopUi.Tooling.run_catalog().execution.renderer_completeness ==
             :widget_complete_interactive

    assert DesktopUi.Tooling.run_catalog().execution.manual_review_workflow.compiled_visible_review !=
             []

    assert :interactive_native_review in DesktopUi.Tooling.workflows()

    assert Enum.any?(
             DesktopUi.Tooling.run_catalog().execution.target_packages,
             &(&1.target == :linux)
           )

    assert "mix desktop_ui.run --format catalog" in DesktopUi.Tooling.mix_tasks()
    assert "mix desktop_ui.package --target linux --dry-run" in DesktopUi.Tooling.mix_tasks()
    assert "mix desktop_ui.build_host" in DesktopUi.Tooling.mix_tasks()
    assert "mix spec.traceability.generate desktop_ui" in DesktopUi.Tooling.mix_tasks()

    assert Enum.any?(
             DesktopUi.Validate.evolution_rules(),
             &(&1.id == :sdl3_renderer_first_backend)
           )
  end
end
