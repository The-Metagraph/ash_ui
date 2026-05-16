defmodule LiveUi.Phase18IntegrationTest do
  use ExUnit.Case, async: true

  test "repository example ids align one for one with the live_ui package examples" do
    report = LiveUi.Tooling.validation_report()

    assert report.example_coverage.complete?
    assert report.example_coverage.repository_example_ids == report.example_coverage.aligned_ids
    assert report.example_coverage.missing_root_example_ids == []
    assert report.example_coverage.unexpected_example_ids == []
  end

  test "native preview canonical comparison and export stay attached to the same aligned id" do
    assert {:ok, preview} = LiveUi.Tooling.preview_example(:button)
    assert {:ok, comparison} = LiveUi.Tooling.compare_example_pair(:button)
    assert {:ok, diagnostics} = LiveUi.Export.example(:button, :diagnostics)

    assert preview.example.id == :button
    assert preview.result.path == :native
    assert comparison.example.id == :button
    assert comparison.canonical_example.id == :button
    assert diagnostics =~ "Button Canonical Review"
  end

  test "demo and divergent package-only example ids are retired" do
    refute Code.ensure_loaded?(LiveUi.Demo)
    assert :error = LiveUi.Examples.find(:native_display)
    assert :error = LiveUi.Examples.find(:canonical_form)
    assert :error = LiveUi.Examples.find(:styled_continuity_compare)
  end

  test "validation and release readiness fail when aligned example inventory drifts" do
    drifted_catalog = tl(LiveUi.Examples.catalog())
    drifted = LiveUi.Tooling.validation_report(catalog: drifted_catalog)

    refute drifted.example_coverage.complete?
    refute drifted.release_readiness.ready?
    assert drifted.example_coverage.missing_root_example_ids != []
  end

  test "validation and release readiness fail when docs reintroduce demo wording" do
    polluted_docs = %{
      "README.md" => File.read!("README.md") <> "\n\nmix live_ui.demo --serve\n"
    }

    drifted = LiveUi.Tooling.validation_report(documentation_opts: [doc_contents: polluted_docs])

    refute drifted.documentation_surface.complete?
    refute drifted.release_readiness.ready?

    assert %{path: "README.md", label: "mix live_ui.demo"} in drifted.documentation_surface.prohibited_mentions
  end
end
