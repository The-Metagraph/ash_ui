defmodule AshUI.Phase9IntegrationTest do
  use ExUnit.Case, async: false

  alias AshUI.Authoring
  alias AshUI.Resource.Authority
  alias AshUI.Test.{ResourceAuthorityScreen, UIStorageFixtures}

  @moduletag :conformance

  describe "Section 9.4.1 - authoring boundary scenarios" do
    test "resource-authority screens can be persisted with semantic widgets intact" do
      ui_storage = UIStorageFixtures.ui_storage_config()

      assert {:ok, screen} =
               Authoring.create_screen(ResourceAuthorityScreen,
                 ui_storage: ui_storage,
                 name: "phase9_resource_authority",
                 route: "/phase-9",
                 layout: :column,
                 metadata: %{"seed" => "phase_9"}
               )

      assert Authority.authority_payload?(screen.unified_dsl)
      assert screen.unified_dsl["format"] == Authority.format()
      assert screen.unified_dsl["version"] == Authority.version()
      assert get_in(screen.unified_dsl, ["screen", "metadata", "seed"]) == "phase_9"

      modules = Enum.map(screen.unified_dsl["elements"], & &1["module"])

      assert "Elixir.AshUI.Test.ResourceAuthorityHeroElement" in modules
      assert "Elixir.AshUI.Test.ResourceAuthorityStatElement" in modules
      assert "Elixir.AshUI.Test.ResourceAuthorityKeyValueElement" in modules
      assert "Elixir.AshUI.Test.ResourceAuthorityInfoListElement" in modules
      assert "Elixir.AshUI.Test.ResourceAuthorityFormFieldElement" in modules
    end

    test "invalid authoring errors surface clearly through Ash UI" do
      assert {:error, error} = Authoring.screen_attrs(String)
      assert inspect(error) =~ "String"
      assert inspect(error) =~ "screen"
    end

    test "public authoring is routed through the resource-authority boundary" do
      assert {:ok, attrs} =
               Authoring.screen_attrs(ResourceAuthorityScreen,
                 name: "phase9_public_boundary",
                 route: "/phase-9/custom"
               )

      assert Authority.authority_payload?(attrs.unified_dsl)
      assert get_in(attrs.unified_dsl, ["screen", "module"]) ==
               "Elixir.AshUI.Test.ResourceAuthorityScreen"

      refute Code.ensure_loaded?(AshUI.Authoring.Screen)
    end
  end
end
