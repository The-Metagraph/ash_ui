defmodule LiveUi.Phase6IntegrationTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "aligned examples cover native and canonical review workflows through one tooling surface" do
    assert {:ok, native_preview} = LiveUi.Tooling.preview_example(:button)
    assert {:ok, canonical_preview} =
             LiveUi.Tooling.inspect_example(:button, review_mode: :canonical)

    assert {:ok, comparison} = LiveUi.Tooling.compare_example_pair(:button)

    assert native_preview.example.path == :aligned
    assert native_preview.result.path == :native
    assert canonical_preview.example.path == :aligned
    assert canonical_preview.result.path == :canonical

    assert native_preview.result.html =~ "data-live-ui-widget=\"button\""
    assert canonical_preview.result.html =~ "data-live-ui-widget=\"button\""
    assert comparison.example.id == :button
    assert comparison.canonical_example.id == :button
    assert comparison.report.continuity.runtime_model_aligned?
  end

  test "preview inspect export and validate tasks provide one repeatable maintainer command path" do
    preview =
      capture_io(fn ->
        Mix.Task.reenable("live_ui.preview")
        Mix.Tasks.LiveUi.Preview.run(["button", "--format", "html"])
      end)

    inspect_output =
      capture_io(fn ->
        Mix.Task.reenable("live_ui.inspect")
        Mix.Tasks.LiveUi.Inspect.run(["button", "--format", "comparison"])
      end)

    export_output =
      capture_io(fn ->
        Mix.Task.reenable("live_ui.export")
        Mix.Tasks.LiveUi.Export.run(["button", "--format", "diagnostics"])
      end)

    validate_output =
      capture_io(fn ->
        Mix.Task.reenable("live_ui.validate")
        Mix.Tasks.LiveUi.Validate.run(["--format", "summary"])
      end)

    assert preview =~ "data-live-ui-widget=\"button\""
    assert inspect_output =~ "button"
    assert inspect_output =~ "Button Canonical Review"
    assert export_output =~ "diagnostics"
    assert export_output =~ "Button Canonical Review"
    assert validate_output =~ "LiveUi validation summary"
    assert validate_output =~ "release ready?: true"
  end

  test "strict validation keeps example health continuity transport and documentation release-ready" do
    report = LiveUi.Tooling.validation_report()

    assert report.example_health.all_passing?
    assert report.example_coverage.complete?
    assert report.continuity.aligned?
    assert report.transport.sound?
    assert report.runtime_authority.server_authoritative?
    assert report.documentation_surface.complete?
    assert report.release_readiness.ready?

    strict_output =
      capture_io(fn ->
        Mix.Task.reenable("live_ui.validate")
        Mix.Tasks.LiveUi.Validate.run(["--strict"])
      end)

    assert strict_output =~ "release ready?: true"
    assert "mix live_ui.validate" in LiveUi.Tooling.mix_tasks()
  end
end
