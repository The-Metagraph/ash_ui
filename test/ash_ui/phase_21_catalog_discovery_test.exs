defmodule AshUI.Phase21CatalogDiscoveryTest do
  use ExUnit.Case, async: true

  alias AshUI.Examples.Suite

  @moduletag :examples

  describe "Section 21.1 - Root Suite Index and Catalog Discovery" do
    test "21.1.1.1 - the root example README acts as a maintained landing page for the mirrored suite" do
      readme = File.read!(Suite.readme_path())

      assert readme =~ "# Ash UI Example Suite"
      assert readme =~ "examples/catalog_metadata.json"
      assert readme =~ "<!-- ash_ui:example-suite-index:start -->"
      assert readme =~ "<!-- ash_ui:example-suite-index:end -->"
    end

    test "21.1.1.2 - machine-readable catalog metadata maps directories to family, canonical subject, and runtime notes" do
      entries = Suite.catalog_entries()
      button = Enum.find(entries, &(&1.directory == "button"))
      toggle = Enum.find(entries, &(&1.directory == "toggle"))
      stream_widget = Enum.find(entries, &(&1.directory == "stream_widget"))

      assert length(entries) == 54
      assert button.family == "content"
      assert button.canonical_subject == "button"
      assert button.runtime_notes =~ "public `button`"
      assert toggle.canonical_subject == "switch"
      assert stream_widget.maintained_runtime == "liveview"
    end

    test "21.1.1.3 - discovery metadata records exact, normalized, composed, and custom parity kinds" do
      entries = Suite.catalog_entries()

      assert Enum.find(entries, &(&1.directory == "button")).parity_kind == "exact"
      assert Enum.find(entries, &(&1.directory == "text_input")).parity_kind == "normalized"
      assert Enum.find(entries, &(&1.directory == "stream_widget")).parity_kind == "composed"
      assert Enum.find(entries, &(&1.directory == "dialog")).parity_kind == "custom"
    end

    test "21.1.1.4 - the root index and JSON snapshot stay synchronized with generated suite metadata" do
      assert :ok = Suite.validate_catalog_metadata_snapshot()
      assert :ok = Suite.validate_readme_index()

      temp_dir =
        Path.join(
          System.tmp_dir!(),
          "ash_ui_phase21_catalog_#{System.unique_integer([:positive])}"
        )

      File.mkdir_p!(temp_dir)
      on_exit(fn -> File.rm_rf(temp_dir) end)

      broken_metadata = Path.join(temp_dir, "catalog_metadata.json")
      broken_readme = Path.join(temp_dir, "README.md")

      File.write!(broken_metadata, "[]\n")
      File.write!(broken_readme, "# Broken\n")

      assert {:error, {:catalog_metadata_drift, _}} =
               Suite.validate_catalog_metadata_snapshot(broken_metadata)

      assert {:error, :missing_index_markers} = Suite.validate_readme_index(broken_readme)
    end
  end
end
