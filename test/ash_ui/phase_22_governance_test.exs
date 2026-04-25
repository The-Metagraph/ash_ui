defmodule AshUI.Phase22GovernanceTest do
  use ExUnit.Case, async: true

  alias AshUI.Examples.{Contract, Suite}

  @moduletag :integration
  @moduletag :examples

  describe "Section 22.2 - Governance and Release Readiness" do
    test "22.2.1.2 - directory-tree validation rejects stale or partially removed example apps" do
      entry = Suite.entry!("button")

      temp_root = temp_examples_root!("directory_tree")
      copy_example!("button", temp_root)
      File.mkdir_p!(Path.join(temp_root, "stale_example"))

      assert {:error, {:example_directory_drift, drift}} =
               Suite.validate_directory_tree_alignment(entries: [entry], examples_root: temp_root)

      assert drift.missing == []
      assert drift.extra == ["stale_example"]

      File.rm!(Path.join(temp_root, "button/mix.exs"))

      assert {:error, {:example_project_drift, issues}} =
               Suite.validate_catalog_projects(entries: [entry], examples_root: temp_root)

      assert Enum.any?(issues, &(&1.kind == :mix_exs))
    end

    test "22.2.1.3 - theme baseline validation rejects shell drift" do
      temp_root = temp_examples_root!("theme_drift")
      broken_css = Path.join(temp_root, "ash_hq_theme_tokens.css")

      File.write!(broken_css, ":root { --ashui-example-bg-base: #020617; }\n")

      assert {:error, {:theme_drift, drift}} =
               Contract.validate_theme_baseline(Contract.default_theme_doc_path(), broken_css)

      assert ".ashui-example-shell" in drift.missing_css_classes
      assert "--ashui-example-primary-gradient" in drift.missing_css_tokens
    end

    test "22.2.1.1 and 22.2.1.4 - release workflow and suite docs advertise the maintained example-suite policy" do
      release_script = File.read!("scripts/validate_release_readiness.sh")
      examples_readme = File.read!("examples/README.md")
      release_checklist = File.read!("release/RELEASE_CHECKLIST.md")

      assert release_script =~ "./scripts/validate_example_suite.sh"
      assert release_script =~ "RELEASE_RUN_EXAMPLE_SMOKE"
      assert release_checklist =~ "Example-suite root validation passes"
      assert examples_readme =~ "## Maintenance Policy"

      assert examples_readme =~
               "sibling `unified_ui/examples` directory names remain the stable review handles"
    end
  end

  defp temp_examples_root!(suffix) do
    path =
      Path.join(
        System.tmp_dir!(),
        "ash_ui_phase22_governance_#{suffix}_#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(path)
    on_exit(fn -> File.rm_rf(path) end)
    path
  end

  defp copy_example!(directory, temp_root) do
    File.cp_r!(Suite.project_path(directory), Path.join(temp_root, directory))
  end
end
