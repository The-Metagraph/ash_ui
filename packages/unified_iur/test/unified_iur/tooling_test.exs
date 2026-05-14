defmodule UnifiedIUR.ToolingTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Tooling

  test "builds a release-readiness validation report for the package" do
    report = Tooling.validation_report()

    assert report.fixture_validation.all_valid?
    assert report.fixture_validation.deterministic?
    assert report.fixture_coverage.complete?
    assert report.release_readiness.attachment_coverage_complete?
    assert report.runtime_compatibility.compatible?
    assert report.parity.synchronized?
    assert report.documentation_surface.complete?
    assert report.release_readiness.ready?
  end

  test "documents governance gates and validation summaries" do
    gates = Tooling.governance_gates()
    documentation = Tooling.documentation_surface()

    assert :paired_unified_ui_catalog_review in gates.change_review_expectations
    assert :style_semantics in gates.minimum_attachment_families
    assert "guides/interoperability.md" in documentation.required_paths
    assert documentation.complete?

    summary = Tooling.validation_summary(Tooling.validation_report())

    assert summary =~ "UnifiedIUR validation summary"
    assert summary =~ "release ready?: true"
  end
end
