defmodule AshUI.Phase17IntegrationTest do
  use ExUnit.Case, async: false

  alias AshUI.Compiler
  alias AshUI.Examples.Contract
  alias AshUI.LiveView.Integration
  alias AshUI.Resource.Authority
  alias AshUI.Test.{ExampleSuiteFixtures, RuntimeDomain}

  @moduletag :integration
  @moduletag :conformance

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()
    :ok
  end

  describe "Section 17.4.1 - Scaffold and style baseline scenarios" do
    test "17.4.1.1 - catalog crosswalk covers every sibling unified_ui example entry exactly once" do
      assert :ok = Contract.validate_catalog_parity()
    end

    test "17.4.1.2 - a scaffolded example app can persist a resource-authority screen and mount it through LiveView" do
      %{runtime: runtime, screen: screen, screen_name: screen_name, ui_storage: ui_storage, user_id: user_id} =
        ExampleSuiteFixtures.seed_screen!()

      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          flash: %{},
          current_user: Map.put(runtime.actor, :active, true),
          user_id: user_id,
          ash_ui_storage: ui_storage,
          ash_ui_domains: [RuntimeDomain]
        }
      }

      assert screen.name == "example/button"
      assert screen.route == "/"
      assert :ok = Authority.validate_payload(screen.unified_dsl)

      assert {:ok, mounted_socket} = Integration.mount_ui_screen(socket, screen_name, %{})

      assert mounted_socket.assigns[:ash_ui_screen].id == screen.id
      assert mounted_socket.assigns[:ash_ui_bindings]["current_display_name"].value == runtime.user.name
      assert Map.has_key?(mounted_socket.assigns[:ash_ui_screen_bindings], "example_notice")
      assert Map.has_key?(mounted_socket.assigns[:ash_ui_action_bindings], "save_profile")
      assert is_map(mounted_socket.assigns[:ash_ui_iur])
    end

    test "17.4.1.3 - the shared Ash HQ theme shell defines desktop and mobile review breakpoints" do
      assert :ok = Contract.validate_theme_baseline()
    end

    test "17.4.1.4 - the suite contract rejects example names, widget mappings, or style baselines that drift from the scaffold" do
      temp_dir = Path.join(System.tmp_dir!(), "ash_ui_phase17_#{System.unique_integer([:positive])}")
      File.mkdir_p!(temp_dir)
      on_exit(fn -> File.rm_rf(temp_dir) end)

      [header | rows] =
        Contract.default_catalog_path()
        |> File.read!()
        |> String.split("\n", trim: true)

      duplicate_row = Enum.find(rows, &String.starts_with?(&1, "button\t"))
      missing_row = Enum.find(rows, &String.starts_with?(&1, "viewport\t"))

      broken_catalog = Path.join(temp_dir, "catalog_drift.tsv")

      File.write!(
        broken_catalog,
        Enum.join([header, duplicate_row | Enum.reject(rows, &(&1 == missing_row))], "\n")
      )

      assert {:error, {:catalog_drift, drift}} =
               Contract.validate_catalog_parity(
                 broken_catalog,
                 Contract.default_sibling_examples_path()
               )

      assert "button" in drift.duplicates
      assert "viewport" in drift.missing

      broken_mapping_catalog = Path.join(temp_dir, "catalog_missing_header.tsv")

      File.write!(
        broken_mapping_catalog,
        Enum.join(
          [String.replace(header, "ash_ui_canonical_subject\t", "") | rows],
          "\n"
        )
      )

      assert {:error, {:missing_catalog_headers, missing_headers}} =
               Contract.validate_catalog_parity(
                 broken_mapping_catalog,
                 Contract.default_sibling_examples_path()
               )

      assert "ash_ui_canonical_subject" in missing_headers

      broken_doc = Path.join(temp_dir, "ash_hq_theme_baseline.md")
      broken_css = Path.join(temp_dir, "ash_hq_theme_tokens.css")

      File.write!(broken_doc, "# Broken Theme\n")
      File.write!(broken_css, ":root { --ashui-example-bg-base: #020617; }\n")

      assert {:error, {:theme_drift, theme_drift}} =
               Contract.validate_theme_baseline(broken_doc, broken_css)

      assert "--ashui-example-accent" in theme_drift.missing_css_tokens
      assert ".ashui-example-primary-cta" in theme_drift.missing_css_classes
      assert "## Shared Style Profiles" in theme_drift.missing_doc_terms
    end
  end
end
