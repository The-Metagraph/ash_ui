defmodule UnifiedUi.ValidationTest do
  use ExUnit.Case, async: true

  alias UnifiedUi.Tooling

  test "reports package validation, signal coverage, and release-readiness gates" do
    report = Tooling.validation_report()

    assert report.example_compilation.all_valid?
    assert report.example_compilation.deterministic?
    assert report.parity.synchronized?

    assert report.example_coverage == %{
             total_examples: 5,
             categories: %{
               advanced_dashboard: 1,
               advanced_flow: 1,
               cross_cutting: 1,
               form_workflow: 1,
               foundational: 1
             },
             covered_categories: [
               :advanced_dashboard,
               :advanced_flow,
               :cross_cutting,
               :form_workflow,
               :foundational
             ],
             missing_categories: [],
             parity_obligations: [
               :advanced_widgets,
               :canvas_constructs,
               :container_constructs,
               :data_widgets,
               :feedback_widgets,
               :form_constructs,
               :foundational_widgets,
               :input_widgets,
               :layer_constructs,
               :layout_constructs,
               :navigation_widgets
             ],
             missing_parity_obligations: [],
             validation_purposes: [
               :coverage,
               :determinism,
               :display_systems,
               :docs,
               :parity,
               :signals,
               :themes
             ],
             complete?: true
           }

    assert report.signal_surface == %{
             example_ids_with_signals: [:themed_signal_workspace],
             families: [:change, :command, :navigation, :submit],
             canonical_only?: true,
             total_bindings: 2,
             total_interactions: 9
           }

    assert report.documentation_surface.complete?
    assert report.documentation_surface.missing_paths == []

    assert report.release_readiness.ready?
    assert Enum.all?(report.release_readiness.criteria, & &1.passed?)
  end

  test "summarizes the current release-readiness state" do
    summary =
      Tooling.validation_report()
      |> Tooling.validation_summary()

    assert summary =~ "UnifiedUi validation summary"
    assert summary =~ "parity synchronized?: true"
    assert summary =~ "documentation surface complete?: true"
    assert summary =~ "release ready?: true"
  end
end
