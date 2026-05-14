defmodule ElmUi.PhaseSixIntegrationTest do
  use ExUnit.Case, async: true

  test "maintained examples cover native, canonical, and mixed workflows through stable helpers" do
    assert Enum.sort(Enum.map(ElmUi.Examples.native_examples(), & &1.id)) == [
             :native_advanced,
             :native_counter,
             :native_foundational,
             :native_navigation,
             :native_styling,
             :native_transport
           ]

    assert Enum.sort(Enum.map(ElmUi.Examples.canonical_examples(), & &1.id)) == [
             :canonical_advanced,
             :canonical_foundational,
             :canonical_navigation,
             :canonical_styling,
             :canonical_transport,
             :canonical_welcome
           ]

    assert Enum.sort(Enum.map(ElmUi.Examples.mixed_examples(), & &1.id)) == [
             :advanced_continuity,
             :foundational_continuity,
             :mixed_transport,
             :navigation_continuity,
             :styling_continuity
           ]

    assert {:ok, native_preview} = ElmUi.Inspect.preview(:native_styling)
    assert {:ok, canonical_preview} = ElmUi.Inspect.preview(:canonical_styling)
    assert {:ok, mixed_preview} = ElmUi.Inspect.preview(:styling_continuity)

    assert native_preview.surface.runtime.theme == :midnight
    assert canonical_preview.surface.runtime.theme == :midnight
    assert mixed_preview.surface.continuity.validation.status == :pass
  end

  test "preview, inspection, export, and validation workflows remain coherent across the split runtime" do
    inspect_catalog = ElmUi.Inspect.catalog()
    assert {:ok, export_artifact} = ElmUi.Export.artifact(:styling_continuity)
    assert {:ok, release_readiness} = ElmUi.Validate.release_readiness(:summary)

    assert inspect_catalog.package_overview.runtime.capabilities != []
    assert ElmUi.Inspect in inspect_catalog.preview_surfaces

    assert export_artifact.artifact_names.comparison ==
             "elm_ui.examples.styling_continuity.comparison"

    assert export_artifact.payload.continuity.validation.status == :pass
    assert release_readiness.status == :pass
    assert Enum.all?(release_readiness.gates, &(&1.status == :pass))
  end

  test "strict release-readiness modes fail deterministically on missing coverage or stale diagnostics" do
    failing_section = %{
      kind: :example_coverage,
      status: :fail,
      checks: [],
      findings: [%{check: :native_examples_present, details: %{missing: [:native_styling]}}]
    }

    assert {:error, failure_report} =
             ElmUi.Validate.release_readiness(
               :strict,
               section_overrides: %{example_coverage: failing_section}
             )

    assert failure_report.status == :fail
    assert Enum.any?(failure_report.findings, &(&1.check == :native_examples_present))
    assert Enum.any?(failure_report.gates, &(&1.id == :example_coverage and &1.status == :fail))
  end

  test "documentation, reference surfaces, and continuity gates stay aligned for package promotion reviews" do
    reference = ElmUi.reference()
    info = ElmUi.info()
    styling = ElmUi.Examples.styling_comparison()

    assert "guides/styling_and_inspection.md" in reference.documentation.guides
    assert Enum.any?(reference.validation.release_gates, &(&1.id == :documentation_surface))

    assert Enum.any?(
             reference.validation.evolution_rules,
             &(&1.id == :renderer_decisions_must_stay_explicit)
           )

    assert info.validation.release_readiness == :pass
    assert styling.continuity.validation.status == :pass
    assert styling.continuity.frontend_realization_match?
  end
end
