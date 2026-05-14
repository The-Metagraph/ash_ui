defmodule DesktopUi.MixTasksTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @tasks [
    "app.start",
    "desktop_ui.build",
    "desktop_ui.package",
    "desktop_ui.inspect",
    "desktop_ui.run",
    "desktop_ui.build_host",
    "desktop_ui.validate"
  ]

  setup do
    Enum.each(@tasks, &Mix.Task.reenable/1)
    :ok
  end

  test "inspect task prints catalog and example inspection output" do
    catalog_output =
      capture_io(fn ->
        run_task("desktop_ui.inspect", ["--format", "catalog"])
      end)

    report_output =
      capture_io(fn ->
        run_task("desktop_ui.inspect", ["styled_continuity_review", "--format", "comparison"])
      end)

    host_output =
      capture_io(fn ->
        run_task("desktop_ui.inspect", ["native_foundational", "--format", "host"])
      end)

    assert catalog_output =~ "native_styled_review"
    assert report_output =~ "styled_continuity_review"
    assert report_output =~ "parity"
    assert host_output =~ ":native_foundational"
  end

  test "run task prints catalog and run execution output" do
    catalog_output =
      capture_io(fn ->
        run_task("desktop_ui.run", ["--format", "catalog"])
      end)

    summary_output =
      capture_io(fn ->
        run_task("desktop_ui.run", ["native_foundational", "--format", "summary"])
      end)

    assert catalog_output =~ "runnable_examples"
    assert summary_output =~ "DesktopUi run summary"
    assert summary_output =~ "backend:"
    assert summary_output =~ "presented frame?: true"
    assert summary_output =~ "renderer completeness:"
    assert summary_output =~ "interactive visible execution?:"
    assert summary_output =~ "interaction events observed:"
    assert summary_output =~ "native text mode:"
    assert summary_output =~ "native image mode:"
  end

  test "build_host task prints dry-run compile diagnostics" do
    dry_run_output =
      capture_io(fn ->
        run_task("desktop_ui.build_host", ["--dry-run"])
      end)

    assert dry_run_output =~ "compile_plan"
    assert dry_run_output =~ "desktop_ui_sdl3_host"
  end

  test "build task prints dry-run staging diagnostics" do
    dry_run_output =
      capture_io(fn ->
        run_task("desktop_ui.build", ["--target", "linux", "--dry-run"])
      end)

    assert dry_run_output =~ "DesktopUi build summary"
    assert dry_run_output =~ "bundle mode:"
  end

  test "package task prints dry-run packaging diagnostics" do
    dry_run_output =
      capture_io(fn ->
        run_task("desktop_ui.package", ["--target", "linux", "--dry-run"])
      end)

    assert dry_run_output =~ "DesktopUi package summary"
    assert dry_run_output =~ "archive path:"
    assert dry_run_output =~ "warnings:"
  end

  test "validate task prints summary and supports strict mode" do
    summary_output =
      capture_io(fn ->
        run_task("desktop_ui.validate", [])
      end)

    strict_output =
      capture_io(fn ->
        run_task("desktop_ui.validate", ["--strict"])
      end)

    assert summary_output =~ "DesktopUi validation summary"
    assert summary_output =~ "host execution surface passing?: true"
    assert strict_output =~ "release ready?: true"
  end

  defp run_task(task, args) do
    Mix.Task.reenable("app.start")
    Mix.Task.reenable(task)
    Mix.Task.run(task, args)
  end
end
