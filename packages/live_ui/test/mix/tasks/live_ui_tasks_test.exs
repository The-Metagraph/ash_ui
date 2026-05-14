defmodule Mix.Tasks.LiveUiTasksTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "preview task prints html and catalog output" do
    html =
      capture_io(fn ->
        Mix.Task.reenable("live_ui.preview")
        Mix.Tasks.LiveUi.Preview.run(["button", "--format", "html"])
      end)

    assert html =~ "data-live-ui-widget=\"button\""

    catalog =
      capture_io(fn ->
        Mix.Task.reenable("live_ui.preview")
        Mix.Tasks.LiveUi.Preview.run([])
      end)

    assert catalog =~ ":button"
    assert catalog =~ ":table"
  end

  test "demo task is retired from the public tooling surface" do
    refute Code.ensure_loaded?(Mix.Tasks.LiveUi.Demo)
  end

  test "inspect and export tasks print comparison-oriented maintainer output" do
    inspection =
      capture_io(fn ->
        Mix.Task.reenable("live_ui.inspect")
        Mix.Tasks.LiveUi.Inspect.run(["button", "--format", "comparison"])
      end)

    assert inspection =~ "Button Canonical Review"
    assert inspection =~ "shared_widgets"

    export =
      capture_io(fn ->
        Mix.Task.reenable("live_ui.export")
        Mix.Tasks.LiveUi.Export.run(["button", "--format", "metadata"])
      end)

    assert export =~ "review_artifact"
    assert export =~ "live_ui/examples/button"
  end
end
