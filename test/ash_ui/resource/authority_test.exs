defmodule AshUI.Resource.AuthorityTest do
  use AshUI.DataCase, async: false

  alias AshUI.Resource.Authority
  alias AshUI.Resource.Info
  alias AshUI.Test.RelationshipMixedScreen
  alias AshUI.Test.ResourceAuthorityButtonElement
  alias AshUI.Test.ResourceAuthorityFormPanelElement
  alias AshUI.Test.ResourceAuthorityHeroElement
  alias AshUI.Test.ResourceAuthorityInputElement
  alias AshUI.Test.ResourceAuthorityScreen
  alias AshUI.Test.ResourceAuthorityStatElement
  alias AshUI.Test.UIStorageFixtures
  alias AshUI.Test.UIStorageScreen

  describe "resource-local authority introspection" do
    test "exposes screen definitions and screen bindings from resource modules" do
      assert Info.resource_role(ResourceAuthorityScreen) == :screen
      assert {:ok, definition} = Info.screen_definition(ResourceAuthorityScreen)
      assert {:ok, bindings} = Info.screen_bindings(ResourceAuthorityScreen)
      assert {:ok, edges} = Info.composition_edges(ResourceAuthorityScreen)

      assert definition.layout == :column
      assert definition.route == "/resource-authority"
      assert definition.metadata.title == "Resource Authority Screen"
      assert [%{id: :screen_notice, target: "flash.notice", binding_type: :value}] = bindings

      assert Enum.map(edges, & &1.destination) == [
               ResourceAuthorityHeroElement,
               ResourceAuthorityFormPanelElement
             ]

      assert Enum.map(edges, &Map.take(&1, [:name, :kind, :slot, :placement, :order])) == [
               %{name: :hero_elements, kind: :child, slot: :body, placement: :append, order: 0},
               %{name: :form_panels, kind: :child, slot: :body, placement: :append, order: 10}
             ]
    end

    test "exposes element definitions, bindings, and actions from resource modules" do
      assert Info.resource_role(ResourceAuthorityStatElement) == :element
      assert {:ok, stat_definition} = Info.element_definition(ResourceAuthorityStatElement)
      assert {:ok, stat_bindings} = Info.element_bindings(ResourceAuthorityStatElement)
      assert {:ok, form_actions} = Info.element_actions(ResourceAuthorityButtonElement)
      assert {:ok, form_edges} = Info.composition_edges(ResourceAuthorityFormPanelElement)

      assert stat_definition.type == :stat
      assert stat_definition.variants == [:primary]
      assert [%{id: :current_value, target: "value", binding_type: :value}] = stat_bindings
      assert [%{id: :save_profile, signal: :click, target: "submit"}] = form_actions

      assert Enum.map(form_edges, & &1.destination) == [
               AshUI.Test.ResourceAuthorityFormFieldElement,
               ResourceAuthorityInputElement,
               ResourceAuthorityButtonElement
             ]

      assert Enum.map(form_edges, &Map.take(&1, [:name, :kind, :slot, :placement, :order])) == [
               %{name: :fields, kind: :child, slot: :body, placement: :append, order: 0},
               %{name: :inputs, kind: :child, slot: :body, placement: :append, order: 1},
               %{
                 name: :actions_companions,
                 kind: :companion,
                 slot: :actions,
                 placement: :append,
                 order: 2
               }
             ]
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
      assert attrs.unified_dsl["version"] == Authority.version()
      assert attrs.unified_dsl["screen"]["module"] == "Elixir.AshUI.Test.ResourceAuthorityScreen"

      assert Enum.map(attrs.unified_dsl["composition"]["roots"], & &1["module"]) == [
               "Elixir.AshUI.Test.ResourceAuthorityHeroElement",
               "Elixir.AshUI.Test.ResourceAuthorityFormPanelElement"
             ]

      assert Enum.map(attrs.unified_dsl["elements"], & &1["module"]) == [
               "Elixir.AshUI.Test.ResourceAuthorityHeroElement",
               "Elixir.AshUI.Test.ResourceAuthorityStatElement",
               "Elixir.AshUI.Test.ResourceAuthorityKeyValueElement",
               "Elixir.AshUI.Test.ResourceAuthorityInfoListElement",
               "Elixir.AshUI.Test.ResourceAuthorityFormPanelElement",
               "Elixir.AshUI.Test.ResourceAuthorityFormFieldElement",
               "Elixir.AshUI.Test.ResourceAuthorityInputElement",
               "Elixir.AshUI.Test.ResourceAuthorityButtonElement"
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
      assert screen.unified_dsl["composition"]["roots"] |> length() == 2
      assert screen.unified_dsl["elements"] |> length() == 8
    end

    test "stores screen-shell metadata for mixed composition screens" do
      assert {:ok, attrs} =
               Authority.screen_attrs(RelationshipMixedScreen,
                 name: "mixed_relationship_authority_screen"
               )

      assert attrs.unified_dsl["screen"]["inline_fragment"]["metadata"]["id"] == "mixed_shell"
      assert Enum.map(attrs.unified_dsl["screen"]["bindings"], & &1["id"]) == ["screen_title"]
    end
  end
end
