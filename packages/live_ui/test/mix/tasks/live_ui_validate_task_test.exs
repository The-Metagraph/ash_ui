defmodule Mix.Tasks.LiveUiValidateTaskTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "validate task prints summary and report output" do
    summary =
      capture_io(fn ->
        Mix.Task.reenable("live_ui.validate")
        Mix.Tasks.LiveUi.Validate.run([])
      end)

    assert summary =~ "LiveUi validation summary"
    assert summary =~ "release ready?: true"

    report =
      capture_io(fn ->
        Mix.Task.reenable("live_ui.validate")
        Mix.Tasks.LiveUi.Validate.run(["--format", "report"])
      end)

    assert report =~ "example_health"
    assert report =~ "release_readiness"
  end
end
