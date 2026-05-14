defmodule UnifiedUi.MixTasksTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "mix unified_ui.inspect prints example reports and coverage" do
    Mix.Task.clear()

    report_output =
      capture_io(fn ->
        Mix.Tasks.UnifiedUi.Inspect.run(["--example", "operations_dashboard"])
      end)

    assert report_output =~ "operations_dashboard"
    assert report_output =~ "construct_families"
    assert report_output =~ "related_specs"

    Mix.Task.clear()

    coverage_output =
      capture_io(fn ->
        Mix.Tasks.UnifiedUi.Inspect.run(["--coverage"])
      end)

    assert coverage_output =~ "total_examples"
    assert coverage_output =~ "themed_signal_workspace"
  end

  test "mix unified_ui.export prints snapshot and signal review output" do
    Mix.Task.clear()

    snapshot_output =
      capture_io(fn ->
        Mix.Tasks.UnifiedUi.Export.run([
          "--example",
          "themed_signal_workspace",
          "--format",
          "snapshot"
        ])
      end)

    assert snapshot_output =~ ":themed_signal_workspace_root"
    assert snapshot_output =~ ":dialog"

    Mix.Task.clear()

    signal_output =
      capture_io(fn ->
        Mix.Tasks.UnifiedUi.Export.run([
          "--module",
          "UnifiedUi.Examples.ThemedSignalWorkspace",
          "--format",
          "signals"
        ])
      end)

    assert signal_output =~ "open_settings"
    assert signal_output =~ "binding_refs"
  end

  test "mix unified_ui.validate prints the current validation state" do
    Mix.Task.clear()

    summary_output =
      capture_io(fn ->
        Mix.Tasks.UnifiedUi.Validate.run([])
      end)

    assert summary_output =~ "UnifiedUi validation summary"
    assert summary_output =~ "release ready?: true"

    Mix.Task.clear()

    strict_output =
      capture_io(fn ->
        Mix.Tasks.UnifiedUi.Validate.run(["--strict"])
      end)

    assert strict_output =~ "release ready?: true"
  end
end
