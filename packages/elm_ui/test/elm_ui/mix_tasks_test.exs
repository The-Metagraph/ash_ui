defmodule ElmUi.MixTasksTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @tasks [
    "app.start",
    "elm_ui.inspect",
    "elm_ui.export",
    "elm_ui.preview",
    "elm_ui.validate"
  ]

  setup do
    Enum.each(@tasks, &Mix.Task.reenable/1)
    :ok
  end

  test "inspect task prints catalog and example inspection output" do
    catalog_output =
      capture_io(fn ->
        run_task("elm_ui.inspect", ["--format", "catalog"])
      end)

    report_output =
      capture_io(fn ->
        run_task("elm_ui.inspect", ["styling_continuity", "--format", "comparison"])
      end)

    assert catalog_output =~ "native_styling"
    assert report_output =~ "styling_continuity"
    assert report_output =~ "continuity"
  end

  test "export task prints stable artifact output" do
    output =
      capture_io(fn ->
        run_task("elm_ui.export", ["styling_continuity", "--format", "metadata"])
      end)

    assert output =~ "elm_ui.examples.styling_continuity.export"
    assert output =~ ":styling"
  end

  test "preview task prints catalog by default and metadata on demand" do
    default_output =
      capture_io(fn ->
        run_task("elm_ui.preview", [])
      end)

    metadata_output =
      capture_io(fn ->
        run_task("elm_ui.preview", ["native_styling", "--format", "metadata"])
      end)

    assert default_output =~ "canonical_styling"
    assert metadata_output =~ ":native_styling"
  end

  test "validate task prints summary and supports strict mode" do
    summary_output =
      capture_io(fn ->
        run_task("elm_ui.validate", [])
      end)

    strict_output =
      capture_io(fn ->
        run_task("elm_ui.validate", ["--strict"])
      end)

    assert summary_output =~ "ElmUi validation summary"
    assert strict_output =~ "release ready?: true"
  end

  defp run_task(task, args) do
    Mix.Task.reenable("app.start")
    Mix.Task.reenable(task)
    Mix.Task.run(task, args)
  end
end
