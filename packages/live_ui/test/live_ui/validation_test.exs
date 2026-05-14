defmodule LiveUi.ValidationTest do
  use ExUnit.Case, async: true

  test "validation report summarizes example health continuity transport and runtime authority" do
    report = LiveUi.Tooling.validation_report()

    assert report.example_health.all_passing?
    assert report.example_coverage.complete?
    assert report.example_coverage.repository_example_ids == report.example_coverage.aligned_ids
    assert report.example_coverage.missing_root_example_ids == []
    assert report.example_coverage.unexpected_example_ids == []
    assert report.continuity.aligned?
    assert report.continuity.browser_style_aligned?
    assert report.transport.sound?
    assert report.runtime_authority.server_authoritative?
    assert report.documentation_surface.complete?
    assert report.documentation_surface.missing_snippets == %{}
    assert report.documentation_surface.prohibited_mentions == []
    assert report.release_readiness.ready?

    assert :aligned_focused_example_review in report.governance_gates.change_review_expectations
    assert :canonical_review_on_aligned_ids in report.governance_gates.change_review_expectations
  end

  test "validation summary prints actionable release-readiness information" do
    summary = LiveUi.Tooling.validation_summary(LiveUi.Tooling.validation_report())

    assert summary =~ "LiveUi validation summary"
    assert summary =~ "examples passing?: true"
    assert summary =~ "continuity aligned?: true"
    assert summary =~ "browser style aligned?: true"
    assert summary =~ "documentation complete?: true"
    assert summary =~ "release ready?: true"
    assert summary =~ "missing root ids: []"
    assert summary =~ "unexpected ids: []"
  end
end
