defmodule ElmUi.ToolingTest do
  use ExUnit.Case, async: true

  test "inspect workflows preview native, canonical, and mixed examples through one surface" do
    assert {:ok, native_preview} = ElmUi.Inspect.preview(:native_styling)
    assert {:ok, canonical_preview} = ElmUi.Inspect.preview(:canonical_styling)
    assert {:ok, mixed_preview} = ElmUi.Inspect.preview(:styling_continuity)
    assert {:ok, rendered_metadata} = ElmUi.Inspect.render("native_styling", :metadata)
    assert {:ok, rendered_diagnostics} = ElmUi.Inspect.render("styling_continuity", :diagnostics)

    assert native_preview.metadata.category == :native
    assert native_preview.surface.runtime.theme == :midnight

    assert canonical_preview.metadata.category == :canonical
    assert canonical_preview.surface.runtime.theme == :midnight

    assert mixed_preview.metadata.category == :mixed
    assert mixed_preview.surface.continuity.validation.status == :pass
    assert rendered_metadata =~ ":native_styling"
    assert rendered_diagnostics =~ "tooling_workflows"
  end

  test "export workflows use stable artifact names from example metadata" do
    assert {:ok, artifact} = ElmUi.Export.artifact(:styling_continuity)
    assert {:ok, rendered_export} = ElmUi.Export.example("styling_continuity", :comparison)

    assert artifact.artifact_names.preview == "elm_ui.examples.styling_continuity.preview"
    assert artifact.artifact_names.export == "elm_ui.examples.styling_continuity.export"
    assert artifact.metadata.workflow == :styling
    assert artifact.payload.continuity.validation.status == :pass
    assert rendered_export =~ "elm_ui.examples.styling_continuity.comparison"
  end

  test "validation workflows summarize coverage, runtime behavior, and release readiness" do
    coverage = ElmUi.Validate.example_coverage()
    runtime = ElmUi.Validate.runtime_behavior()
    tooling = ElmUi.Validate.tooling_surface()
    documentation = ElmUi.Validate.documentation_surface()
    validation_report = ElmUi.Validate.validation_report()
    validation_summary = ElmUi.Validate.validation_summary(validation_report)

    assert coverage.status == :pass
    assert runtime.status == :pass
    assert tooling.status == :pass
    assert documentation.status == :pass

    assert {:ok, summary_report} = ElmUi.Validate.release_readiness(:summary)
    assert {:ok, strict_report} = ElmUi.Validate.release_readiness(:strict)

    assert summary_report.status == :pass
    assert strict_report.status == :pass
    assert summary_report.findings == []
    assert strict_report.findings == []
    assert Enum.all?(summary_report.gates, &(&1.status == :pass))
    assert validation_report.release_readiness.status == :pass
    assert validation_summary =~ "ElmUi validation summary"
    assert validation_summary =~ "release ready?: true"

    assert Enum.any?(
             summary_report.evolution_rules,
             &(&1.id == :tooling_and_docs_move_with_surface)
           )
  end
end
