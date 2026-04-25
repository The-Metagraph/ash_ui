defmodule AshUI.Phase22TraceabilityTest do
  use ExUnit.Case, async: true

  alias AshUI.Examples.Suite

  @moduletag :integration
  @moduletag :examples
  @moduletag :conformance

  @catalog_path "specs/conformance/scenario_catalog.md"
  @matrix_path "specs/conformance/spec_conformance_matrix.md"
  @traceability_path "specs/conformance/scenario_test_matrix.md"

  describe "Section 22.3 - Conformance and Traceability" do
    test "22.3.1.1 and 22.3.1.2 - example-suite scenarios cover each maintained rollout phase and governance proof" do
      catalog = File.read!(@catalog_path)
      traceability = File.read!(@traceability_path)

      suite_phases =
        Suite.catalog_entries()
        |> Enum.map(& &1.phase)
        |> Enum.uniq()
        |> Enum.sort()

      expected_phase_files = Enum.map(suite_phases, &"test/ash_ui/phase_#{&1}_integration_test.exs")

      assert suite_phases == [18, 19, 20]
      assert catalog =~ "#### SCN-052: Example Suite Resource-Authority Flows"
      assert catalog =~ "#### SCN-054: Shared Example Theme Shell and Review Surfaces"
      assert catalog =~ "#### SCN-055: Example Suite Governance Drift Detection"

      scn_052 = traceability_row!(traceability, "SCN-052")
      scn_054 = traceability_row!(traceability, "SCN-054")
      scn_055 = traceability_row!(traceability, "SCN-055")

      Enum.each(expected_phase_files, fn file ->
        assert scn_052 =~ file
        assert scn_054 =~ file
      end)

      assert scn_054 =~ "test/ash_ui/phase_17_integration_test.exs"
      assert scn_055 =~ "test/ash_ui/phase_22_governance_test.exs"
    end

    test "22.3.1.3 - the spec matrix treats the shared theme shell and review surfaces as normative" do
      matrix = File.read!(@matrix_path)
      review_entries = Suite.review_metadata_entries()

      assert req_row!(matrix, "REQ-SCREEN-001") =~ "SCN-052"
      assert req_row!(matrix, "REQ-COMP-001") =~ "SCN-052"
      assert req_row!(matrix, "REQ-COMP-008") =~ "SCN-055"
      assert req_row!(matrix, "REQ-RENDER-002") =~ "SCN-054"
      assert req_row!(matrix, "REQ-RENDER-007") =~ "SCN-054"
      assert req_row!(matrix, "REQ-RENDER-008") =~ "SCN-054"
      assert req_row!(matrix, "REQ-RENDER-008") =~ "SCN-055"

      assert review_entries != []
      assert Enum.all?(review_entries, & &1.shared_theme)
      assert Enum.all?(review_entries, &(&1.interaction_story_status == "present"))
      assert Enum.all?(review_entries, &(&1.signal_preview_status == "present"))
    end

    test "22.3.1.4 - traceability docs stay synchronized with the maintained suite metadata" do
      assert :ok = Suite.validate_catalog_metadata_snapshot()
      assert :ok = Suite.validate_readme_index()
      assert :ok = Suite.validate_review_metadata_alignment()

      catalog_entries = Suite.catalog_entries()
      review_entries = Suite.review_metadata_entries()

      assert length(catalog_entries) == length(review_entries)

      catalog_directories = Enum.map(catalog_entries, & &1.directory)
      review_directories = Enum.map(review_entries, & &1.directory)

      assert catalog_directories == review_directories
    end
  end

  defp traceability_row!(body, scenario) do
    Regex.run(~r/^\|\s*#{scenario}\s*\|.*$/m, body)
    |> case do
      [row] -> row
      _ -> flunk("missing traceability row for #{scenario}")
    end
  end

  defp req_row!(body, req) do
    Regex.run(~r/^\|\s*#{Regex.escape(req)}\s*\|.*$/m, body)
    |> case do
      [row] -> row
      _ -> flunk("missing spec matrix row for #{req}")
    end
  end
end
