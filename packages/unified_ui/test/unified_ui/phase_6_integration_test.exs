defmodule UnifiedUi.Phase6IntegrationTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias UnifiedUi.{Examples, Export, Parity, Tooling}

  test "maintained examples cover foundational, advanced, and cross-cutting authored workflows" do
    assert Enum.map(Examples.catalog(), & &1.id) == [
             :foundational_screen,
             :profile_form,
             :overlay_workspace,
             :operations_dashboard,
             :themed_signal_workspace
           ]

    assert Examples.categories() == [
             :advanced_dashboard,
             :advanced_flow,
             :cross_cutting,
             :form_workflow,
             :foundational
           ]

    assert Examples.validation_purposes() == [
             :coverage,
             :determinism,
             :display_systems,
             :docs,
             :parity,
             :signals,
             :themes
           ]
  end

  test "inspection, export, and diff workflows produce review-friendly maintainer output" do
    assert {:ok, operations_report} = Tooling.inspect_example(:operations_dashboard)
    assert operations_report.compiler.summary.identity_id == :operations_dashboard

    assert {:ok, rendered_inspection} = Export.example(:operations_dashboard, :inspection)
    assert rendered_inspection =~ "UnifiedUi compiler inspection"
    assert rendered_inspection =~ "widget kinds:"

    assert {:ok, snapshot} = Export.example(:themed_signal_workspace, :snapshot)
    assert snapshot =~ ":themed_signal_workspace_root"
    assert snapshot =~ ":settings_dialog"

    assert {:ok, diff} = Tooling.diff_examples(:foundational_screen, :operations_dashboard)
    assert diff.snapshot_changed?

    assert diff.changes.widget_kinds.added == [
             :cluster_dashboard,
             :gauge,
             :log_viewer,
             :markdown_viewer,
             :process_monitor,
             :sparkline,
             :stream_widget,
             :table,
             :tree_view
           ]
  end

  test "diagnostics and parity workflows stay actionable when canonical coverage drifts" do
    diagnostics =
      UnifiedUi.Examples.ThemedSignalWorkspace
      |> Tooling.module_diagnostics()
      |> Tooling.render_diagnostics()

    assert diagnostics =~ "status: ok"
    assert diagnostics =~ "related specs:"

    drifted_catalog = %{Parity.catalog() | advanced_widgets: []}
    drift_report = Parity.validation_report(Parity.example_modules(), drifted_catalog)

    refute drift_report.valid?
    refute drift_report.parity.synchronized?

    drift_summary = Parity.validation_summary(drift_report)
    assert drift_summary =~ "overall valid?: false"
    assert drift_summary =~ "advanced_widgets"
  end

  test "the package can be assessed through one repeatable release-readiness workflow" do
    report = Tooling.validation_report()

    assert report.release_readiness.ready?
    assert report.documentation_surface.complete?
    assert report.example_compilation.all_valid?
    assert report.example_compilation.deterministic?
    assert report.parity.synchronized?

    Mix.Task.clear()

    output =
      capture_io(fn ->
        Mix.Tasks.UnifiedUi.Validate.run(["--strict"])
      end)

    assert output =~ "UnifiedUi validation summary"
    assert output =~ "release ready?: true"
  end
end
