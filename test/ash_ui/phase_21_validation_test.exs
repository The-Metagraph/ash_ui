defmodule AshUI.Phase21ValidationTest do
  use ExUnit.Case, async: true

  alias AshUI.Examples.Suite

  @moduletag :examples

  describe "Section 21.3 - Validation and Governance Checks" do
    test "21.3.1.1 - validation catches catalog entries without the expected project structure or launcher metadata" do
      temp_root = temp_examples_root!("catalog_projects")
      entry = Suite.entry!("button")

      copy_example!("button", temp_root)
      assert :ok = Suite.validate_catalog_projects(entries: [entry], examples_root: temp_root)

      File.rm!(Path.join(temp_root, "button/README.md"))

      assert {:error, {:example_project_drift, issues}} =
               Suite.validate_catalog_projects(entries: [entry], examples_root: temp_root)

      assert Enum.any?(issues, &(&1.directory == "button" and &1.kind == :readme))
    end

    test "21.3.1.2 - validation requires resource authority persistence and resource DSL markers" do
      temp_root = temp_examples_root!("resource_authority")
      entry = Suite.entry!("button")
      source_path = Path.join(temp_root, "button/lib/ash_ui_examples/button.ex")

      copy_example!("button", temp_root)

      assert :ok =
               Suite.validate_resource_authority_continuity(
                 entries: [entry],
                 examples_root: temp_root
               )

      source =
        source_path
        |> File.read!()
        |> String.replace("Authority.create(", "Legacy.create(")

      File.write!(source_path, source)

      assert {:error, {:resource_authority_drift, issues}} =
               Suite.validate_resource_authority_continuity(
                 entries: [entry],
                 examples_root: temp_root
               )

      assert Enum.any?(
               issues,
               &(&1.directory == "button" and &1.kind == :resource_authority_create)
             )
    end

    test "21.3.1.3 - validation requires the shared theme contract and reviewer-visible story surfaces" do
      temp_root = temp_examples_root!("theme_review")
      entry = Suite.entry!("dialog")
      css_path = Path.join(temp_root, "dialog/assets/css/app.css")

      copy_example!("dialog", temp_root)

      assert :ok =
               Suite.validate_theme_review_contract(entries: [entry], examples_root: temp_root)

      File.write!(css_path, ":root { --ashui-example-primary-gradient: none; }\n")

      assert {:error, {:theme_review_drift, issues}} =
               Suite.validate_theme_review_contract(entries: [entry], examples_root: temp_root)

      assert Enum.any?(issues, &(&1.directory == "dialog" and &1.kind == :theme_shell))
    end

    test "21.3.1.4 - governance checks reject builder-first and document-first example regressions" do
      temp_root = temp_examples_root!("governance")
      entry = Suite.entry!("button")
      readme_path = Path.join(temp_root, "button/README.md")

      copy_example!("button", temp_root)
      assert :ok = Suite.validate_governance(entries: [entry], examples_root: temp_root)

      File.write!(
        readme_path,
        File.read!(readme_path) <> "\nLegacy note: builder-first path via AshUI.DSL.Builder.\n"
      )

      assert {:error, {:example_governance_violations, issues}} =
               Suite.validate_governance(entries: [entry], examples_root: temp_root)

      assert Enum.any?(issues, &(&1.directory == "button" and &1.kind == :builder_first))
      assert Enum.any?(issues, &(&1.directory == "button" and &1.kind == :builder_first_text))
    end
  end

  defp temp_examples_root!(suffix) do
    path =
      Path.join(
        System.tmp_dir!(),
        "ash_ui_phase21_#{suffix}_#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(path)
    on_exit(fn -> File.rm_rf(path) end)
    path
  end

  defp copy_example!(directory, temp_root) do
    File.cp_r!(Suite.project_path(directory), Path.join(temp_root, directory))
  end
end
