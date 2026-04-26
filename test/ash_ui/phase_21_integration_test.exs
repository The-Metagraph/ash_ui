defmodule AshUI.Phase21IntegrationTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias AshUI.Examples.Suite

  @moduletag :examples
  @moduletag :integration

  describe "Section 21.5 - Phase 21 Integration Tests" do
    test "21.5.1.1 - maintainers can discover, preview, and dry-run representative apps through the root workflow" do
      list_output =
        capture_io(fn ->
          Mix.Tasks.AshUi.Examples.List.run([])
        end)

      preview_output =
        capture_io(fn ->
          Mix.Tasks.AshUi.Examples.Preview.run(["tabs"])
        end)

      start_output =
        capture_io(fn ->
          Mix.Tasks.AshUi.Examples.Start.run(["status", "--dry-run", "--actor", "operator"])
        end)

      assert list_output =~ "button | content | 18 | exact | mix ash_ui.examples.start button"
      assert list_output =~ "tabs | navigation | 19 | custom | mix ash_ui.examples.start tabs"

      assert list_output =~
               "status | feedback | 20 | normalized | mix ash_ui.examples.start status"

      assert preview_output =~ "Tabs Example (`tabs`)"
      assert preview_output =~ "Meaningful Interaction Story:"
      assert start_output =~ "Status Example (`status`)"

      assert start_output =~
               "Dry run: cd #{Suite.project_path("status")} && MIX_ENV=dev mix example.start"
    end

    test "21.5.1.2 - suite validation catches catalog drift, superseded authoring, and theme divergence together" do
      temp_root = temp_examples_root!("integration_validation")
      entry = Suite.entry!("dialog")
      mix_path = Path.join(temp_root, "dialog/mix.exs")
      source_path = Path.join(temp_root, "dialog/lib/ash_ui_examples/dialog.ex")
      css_path = Path.join(temp_root, "dialog/assets/css/app.css")

      copy_example!("dialog", temp_root)

      File.write!(
        mix_path,
        String.replace(File.read!(mix_path), "\"example.start\": [&example_start/1]", "\"example.start\": []")
      )

      File.write!(
        source_path,
        String.replace(File.read!(source_path), "Authority.create(", "Legacy.create(")
      )

      File.write!(css_path, ":root { --ashui-example-primary-gradient: none; }\n")

      assert {:error, {:suite_validation_failed, failures}} =
               Suite.validate_suite(entries: [entry], examples_root: temp_root)

      assert Enum.any?(failures, &(&1.check == :catalog_projects))
      assert Enum.any?(failures, &(&1.check == :resource_authority))
      assert Enum.any?(failures, &(&1.check == :theme_review))
    end

    test "21.5.1.3 - review metadata remains aligned with the catalog, README index, and suite report" do
      report_output =
        capture_io(fn ->
          Mix.Tasks.AshUi.Examples.Report.run([])
        end)

      assert :ok = Suite.validate_review_metadata_alignment()
      assert report_output =~ "Review-metadata alignment: pass"
    end

    test "21.5.1.4 - unsupported or partial surfaces stay visible in preview and report output" do
      preview_output =
        capture_io(fn ->
          Mix.Tasks.AshUi.Examples.Preview.run(["dialog"])
        end)

      report_output =
        capture_io(fn ->
          Mix.Tasks.AshUi.Examples.Report.run([])
        end)

      assert preview_output =~ "Support notice:"
      assert report_output =~ "Custom surfaces: "
      assert report_output =~ "dialog"
      assert report_output =~ "Partial support: "
      assert report_output =~ "text_input"
    end
  end

  defp temp_examples_root!(suffix) do
    path =
      Path.join(
        System.tmp_dir!(),
        "ash_ui_phase21_integration_#{suffix}_#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(path)
    on_exit(fn -> File.rm_rf(path) end)
    path
  end

  defp copy_example!(directory, temp_root) do
    File.cp_r!(Suite.project_path(directory), Path.join(temp_root, directory))
  end
end
