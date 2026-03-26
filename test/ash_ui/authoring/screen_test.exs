defmodule AshUI.Authoring.ScreenTest do
  use ExUnit.Case, async: true

  alias AshUI.Authoring.{Extensions, Screen}
  alias AshUI.Resource.Authority
  alias AshUI.Test.{
    ResourceAuthorityScreen,
    ResourceAuthorityStatElement,
    UIStorageFixtures
  }

  describe "Section 13.1.2 - resource-first authoring bridge" do
    test "builds persisted screen attrs from a screen resource module" do
      assert {:ok, attrs} =
               Screen.screen_attrs(ResourceAuthorityScreen,
                 route: "/authored",
                 layout: :column,
                 metadata: %{"owner" => "platform"}
               )

      assert attrs.name == "resource_authority_screen"
      assert attrs.route == "/authored"
      assert attrs.layout == :column
      assert attrs.metadata["title"] == "Resource Authority Screen"
      assert attrs.metadata["owner"] == "platform"
      assert attrs.unified_dsl["format"] == Authority.format()
      assert attrs.unified_dsl["version"] == Authority.version()
      assert attrs.unified_dsl["screen"]["module"] == "Elixir.AshUI.Test.ResourceAuthorityScreen"
      assert attrs.unified_dsl["screen"]["bindings"] |> length() == 1

      assert Enum.map(attrs.unified_dsl["elements"], & &1["module"]) == [
               "Elixir.AshUI.Test.ResourceAuthorityStatElement",
               "Elixir.AshUI.Test.ResourceAuthorityFormElement"
             ]
    end

    test "persists a screen through configurable UI storage" do
      ui_storage = UIStorageFixtures.ui_storage_config()

      assert {:ok, screen} =
               Screen.create(ResourceAuthorityScreen,
                 ui_storage: ui_storage,
                 route: "/authored",
                 layout: :column,
                 metadata: %{"seeded_by" => "screen_test"}
               )

      assert screen.name == "resource_authority_screen"
      assert screen.route == "/authored"
      assert screen.layout == :column
      assert screen.metadata["title"] == "Resource Authority Screen"
      assert screen.metadata["seeded_by"] == "screen_test"
      assert screen.unified_dsl["format"] == Authority.format()
      assert screen.unified_dsl["elements"] |> length() == 2
    end

    test "returns clear errors for non-screen modules" do
      assert {:error, {:missing_screen_authority, String}} = Screen.screen_attrs(String)
    end

    test "returns clear errors for element modules" do
      assert {:error, {:expected_screen_resource, ResourceAuthorityStatElement}} =
               Screen.screen_attrs(ResourceAuthorityStatElement)
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
      assert Enum.any?(guidance, &String.contains?(&1, "AshUI.Resource.Authority"))
    end
  end
end
