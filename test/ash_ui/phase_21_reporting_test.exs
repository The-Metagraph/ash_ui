defmodule AshUI.Phase21ReportingTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias AshUI.Examples.Suite

  @moduletag :examples

  describe "Section 21.4 - Review Metadata and Reporting" do
    test "21.4.1.1 - per-app review metadata records family, canonical mapping, theme usage, and review-surface status" do
      button = Enum.find(Suite.review_metadata_entries(), &(&1.directory == "button"))
      dialog = Enum.find(Suite.review_metadata_entries(), &(&1.directory == "dialog"))

      assert button.family == "content"
      assert button.canonical_subject == "button"
      assert button.shared_theme
      assert button.interaction_story_status == "present"
      assert button.signal_preview_status == "present"
      assert dialog.support_status == "custom_surface"
    end

    test "21.4.1.2 - suite-level reporting summarizes completeness and continuity" do
      report = Suite.suite_report()

      output =
        capture_io(fn ->
          Mix.Tasks.AshUi.Examples.Report.run([])
        end)

      assert report.total_examples == 54
      assert report.catalog_completeness == "pass"
      assert report.resource_authority_continuity == "pass"
      assert report.theme_contract_continuity == "pass"
      assert output =~ "Ash UI Example Suite Report"
      assert output =~ "Catalog completeness: pass"
      assert output =~ "Theme-contract continuity: pass"
    end

    test "21.4.1.3 - reporting calls out custom surfaces and partial-support examples explicitly" do
      report = Suite.suite_report()

      assert "dialog" in report.custom_surface_examples
      assert "text_input" in report.partial_support_examples
      assert "status" in report.partial_support_examples
    end

    test "21.4.1.4 - review metadata stays traceable to the catalog and root index" do
      assert :ok = Suite.validate_review_metadata_snapshot()
      assert :ok = Suite.validate_review_metadata_alignment()

      temp_dir =
        Path.join(
          System.tmp_dir!(),
          "ash_ui_phase21_review_#{System.unique_integer([:positive])}"
        )

      File.mkdir_p!(temp_dir)
      on_exit(fn -> File.rm_rf(temp_dir) end)

      broken_review = Path.join(temp_dir, "review_metadata.json")
      File.write!(broken_review, "[]\n")

      assert {:error, {:review_metadata_drift, _}} =
               Suite.validate_review_metadata_snapshot(broken_review)
    end
  end
end
