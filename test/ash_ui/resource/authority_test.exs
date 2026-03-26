defmodule AshUI.Resource.AuthorityTest do
  use AshUI.DataCase, async: false

  alias AshUI.Resource.Authority
  alias AshUI.Resource.Info
  alias AshUI.Test.ResourceAuthorityFormElement
  alias AshUI.Test.ResourceAuthorityScreen
  alias AshUI.Test.ResourceAuthorityStatElement
  alias AshUI.Test.UIStorageFixtures
  alias AshUI.Test.UIStorageScreen

  describe "resource-local authority introspection" do
    test "exposes screen definitions and screen bindings from resource modules" do
      assert Info.resource_role(ResourceAuthorityScreen) == :screen
      assert {:ok, definition} = Info.screen_definition(ResourceAuthorityScreen)
      assert {:ok, bindings} = Info.screen_bindings(ResourceAuthorityScreen)

      assert definition.layout == :column
      assert definition.route == "/resource-authority"
      assert definition.metadata.title == "Resource Authority Screen"
      assert definition.elements == [ResourceAuthorityStatElement, ResourceAuthorityFormElement]
      assert [%{id: :screen_notice, target: "flash.notice", binding_type: :value}] = bindings
    end

    test "exposes element definitions, bindings, and actions from resource modules" do
      assert Info.resource_role(ResourceAuthorityStatElement) == :element
      assert {:ok, stat_definition} = Info.element_definition(ResourceAuthorityStatElement)
      assert {:ok, stat_bindings} = Info.element_bindings(ResourceAuthorityStatElement)
      assert {:ok, form_actions} = Info.element_actions(ResourceAuthorityFormElement)

      assert stat_definition.type == :text
      assert stat_definition.variants == [:primary]
      assert [%{id: :current_value, target: "content", binding_type: :value}] = stat_bindings
      assert [%{id: :save_profile, signal: :click, target: "submit"}] = form_actions
    end
  end

  describe "resource-local persistence boundary" do
    test "builds screen attrs from a screen resource module" do
      assert {:ok, attrs} =
               Authority.screen_attrs(ResourceAuthorityScreen,
                 name: "resource_authority_screen"
               )

      assert attrs.name == "resource_authority_screen"
      assert attrs.route == "/resource-authority"
      assert attrs.layout == :column
      assert attrs.metadata["title"] == "Resource Authority Screen"
      assert attrs.unified_dsl["format"] == Authority.format()
      assert attrs.unified_dsl["screen"]["module"] == "Elixir.AshUI.Test.ResourceAuthorityScreen"
      assert Enum.map(attrs.unified_dsl["elements"], & &1["module"]) == [
               "Elixir.AshUI.Test.ResourceAuthorityStatElement",
               "Elixir.AshUI.Test.ResourceAuthorityFormElement"
             ]
    end

    test "persists a resource-authority payload without AshUI.Authoring" do
      ui_storage = UIStorageFixtures.ui_storage_config()

      assert {:ok, screen} =
               Authority.create(ResourceAuthorityScreen,
                 ui_storage: ui_storage,
                 authorize?: false,
                 name: "persisted_resource_authority_screen"
               )

      assert screen.__struct__ == UIStorageScreen
      assert screen.unified_dsl["format"] == Authority.format()
      assert screen.unified_dsl["screen"]["name"] == "persisted_resource_authority_screen"
      assert screen.unified_dsl["screen"]["bindings"] |> length() == 1
      assert screen.unified_dsl["elements"] |> length() == 2
    end
  end
end
