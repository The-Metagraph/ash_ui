defmodule AshUI.Authoring.ScreenTest do
  use ExUnit.Case, async: true

  alias AshUI.Authoring.{Document, Extensions, Screen}
  alias AshUI.Data
  alias AshUI.Test.{AuthoredCustomWidgetScreen, AuthoredSupportScreen, UIStorageFixtures}

  describe "Section 9.2.1 - persisted screen authoring bridge" do
    test "builds persisted screen attrs from a UnifiedUi module" do
      assert {:ok, attrs} =
               Screen.screen_attrs(AuthoredSupportScreen,
                 route: "/authored",
                 layout: :column,
                 metadata: %{"owner" => "platform"},
                 binding_metadata: %{"profile_form" => %{"intent" => "save_profile"}}
               )

      assert attrs.name == "authored_support_screen"
      assert attrs.route == "/authored"
      assert attrs.layout == :column
      assert attrs.metadata["title"] == "Authored Support Screen"
      assert attrs.metadata["owner"] == "platform"
      assert Document.authoring_document?(attrs.unified_dsl)
      assert attrs.unified_dsl["format"] == Document.format()
      assert attrs.unified_dsl["version"] == Document.version()
      assert get_in(attrs.unified_dsl, ["authoring", "source", "kind"]) == "unified_ui_module"

      composition_summary =
        attrs.unified_dsl
        |> get_in(["authoring", "document", "composition_summary"])
        |> flatten_nodes()

      assert Enum.any?(composition_summary, &(&1["kind"] == "hero"))
      assert Enum.any?(composition_summary, &(&1["kind"] == "stat"))
      assert Enum.any?(composition_summary, &(&1["kind"] == "key_value"))
      assert Enum.any?(composition_summary, &(&1["kind"] == "info_list"))
      assert Enum.any?(composition_summary, &(&1["kind"] == "form_builder"))
    end

    test "persists a screen through configurable UI storage" do
      ui_storage = UIStorageFixtures.ui_storage_config()

      assert {:ok, screen} =
               Screen.create(AuthoredSupportScreen,
                 ui_storage: ui_storage,
                 route: "/authored",
                 layout: :column,
                 metadata: %{"seeded_by" => "screen_test"},
                 binding_metadata: %{"hero_panel" => %{"resource" => "Demo.Resource"}}
               )

      assert screen.name == "authored_support_screen"
      assert screen.route == "/authored"
      assert screen.layout == :column
      assert screen.metadata["title"] == "Authored Support Screen"
      assert screen.metadata["seeded_by"] == "screen_test"
      assert Document.authoring_document?(screen.unified_dsl)

      assert get_in(screen.unified_dsl, ["ash_ui", "compatibility", "legacy_read_cutoff"]) ==
               Document.legacy_read_cutoff()

      assert {:ok, fetched} =
               Data.read_one(AshUI.Test.UIStorageScreen,
                 ui_storage: ui_storage,
                 filter: [name: "authored_support_screen"]
               )

      assert fetched.id == screen.id

      assert get_in(fetched.unified_dsl, ["ash_ui", "binding_metadata", "hero_panel", "resource"]) ==
               "Demo.Resource"
    end

    test "returns clear errors for invalid upstream modules" do
      assert {:error, {:invalid_unified_ui_module, String, _message}} =
               Screen.screen_attrs(String)
    end

    test "validates persisted authoring documents" do
      assert {:ok, attrs} = Screen.screen_attrs(AuthoredSupportScreen, route: "/authored")
      assert :ok = Document.validate_write(attrs.unified_dsl)

      invalid =
        attrs.unified_dsl
        |> put_in(["ash_ui", "screen", "name"], "")

      assert {:error, "ash_ui.screen.name must be a non-empty string"} =
               Document.validate_write(invalid)
    end

    test "requires the Phase 10 persisted document contract for writes" do
      legacy_v1_document = %{
        "format" => "ash_ui/unified_ui_module",
        "version" => 1,
        "authoring" => %{},
        "ash_ui" => %{}
      }

      assert {:error, "must declare the Phase 10 ash_ui unified_ui document format"} =
               Document.validate_write(legacy_v1_document)
    end
  end

  describe "Section 9.2.2 - upstream extension registration surface" do
    test "exposes upstream extension metadata and guidance" do
      assert Extensions.registration_mode() == :upstream_compile_time
      assert Map.has_key?(Extensions.extension_points(), :composition)
      assert :widget_entities in Extensions.extension_points().composition
      assert Map.has_key?(Extensions.construct_families(), :widgets)

      guidance = Extensions.registration_guidance()
      assert Enum.any?(guidance, &String.contains?(&1, "UnifiedUi DSL extensions"))
    end

    test "custom widgets can flow through the upstream authoring pipeline" do
      assert {:ok, attrs} = Screen.screen_attrs(AuthoredCustomWidgetScreen, route: "/custom")

      composition_summary =
        attrs.unified_dsl
        |> get_in(["authoring", "document", "composition_summary"])
        |> flatten_nodes()

      assert Enum.any?(composition_summary, fn node ->
               node["id"] == "banner_shell" and node["kind"] == "content"
             end)

      compiler_summary = get_in(attrs.unified_dsl, ["authoring", "document", "compiler_summary"])
      top_level_children = Map.get(compiler_summary, "top_level_children", [])

      assert Enum.any?(top_level_children, fn child -> child["kind"] == "column" end)
    end
  end

  defp flatten_nodes(nodes) when is_list(nodes) do
    Enum.flat_map(nodes, fn node ->
      [node | flatten_nodes(Map.get(node, "children", []))]
    end)
  end
end
