defmodule AshUI.Compiler.RelationshipSemanticsTest do
  use AshUI.DataCase, async: false

  alias AshUI.Compiler
  alias AshUI.Resource.Authority
  alias AshUI.Resource.Info
  alias AshUI.Resources.Screen
  alias AshUI.Test.{
    RelationshipMixedScreen,
    RelationshipOnlyScreen,
    ResourceAuthorityFormPanelElement,
    ResourceAuthorityHeroElement,
    ResourceAuthorityScreen
  }

  describe "explicit relationship semantics" do
    test "prefer ui_relationships over inferred naming heuristics" do
      assert {:ok, screen_edges} = Info.composition_edges(ResourceAuthorityScreen)
      assert {:ok, hero_edges} = Info.composition_edges(ResourceAuthorityHeroElement)
      assert {:ok, panel_edges} = Info.composition_edges(ResourceAuthorityFormPanelElement)

      assert Enum.map(screen_edges, &Map.take(&1, [:name, :kind, :slot, :placement, :order])) == [
               %{name: :hero_elements, kind: :child, slot: :body, placement: :append, order: 0},
               %{name: :form_panels, kind: :child, slot: :body, placement: :append, order: 10}
             ]

      assert Enum.map(hero_edges, &Map.take(&1, [:name, :kind, :slot, :placement, :order])) == [
               %{name: :stats, kind: :child, slot: :body, placement: :append, order: 0},
               %{name: :meta_rows, kind: :child, slot: :aside, placement: :append, order: 1},
               %{
                 name: :details_companions,
                 kind: :companion,
                 slot: :aside,
                 placement: :append,
                 order: 2
               }
             ]

      assert Enum.map(panel_edges, &Map.take(&1, [:name, :kind, :slot, :placement, :order])) == [
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

    test "reject invalid relationship placements at compile time" do
      assert_raise ArgumentError, ~r/placement must be one of \[:append, :prepend\]/, fn ->
        Code.compile_string("""
        defmodule InvalidPhase14RelationshipScreen do
          use Ash.Resource,
            domain: AshUI.Test.ResourceAuthorityDomain,
            data_layer: Ash.DataLayer.Ets

          use AshUI.Resource.DSL.Screen

          ets do
            private?(true)
          end

          attributes do
            uuid_primary_key(:id)
          end

          actions do
            defaults([:read])
          end

          relationships do
            has_many :hero_elements, AshUI.Test.ResourceAuthorityHeroElement do
              destination_attribute(:screen_id)
            end
          end

          ui_relationships do
            relationship :hero_elements do
              kind :child
              slot :body
              placement :overlay
              order 0
            end
          end

          ui_screen do
            layout :column
          end
        end
        """)
      end
    end
  end

  describe "screen-scoped wrappers and parity" do
    test "mixed composition preserves the screen shell, screen bindings, and authored order" do
      {:ok, attrs} =
        Authority.screen_attrs(RelationshipMixedScreen,
          name: "phase14_mixed_relationship_screen"
        )

      {:ok, screen} = AshUI.Data.create(Screen, attrs: attrs)

      assert {:ok, iur} = Compiler.compile(screen, use_cache: false)

      assert get_in(iur.metadata, ["ash_ui", "resource_authority", "composition_mode"]) == "mixed"

      assert get_in(iur.metadata, ["ash_ui", "resource_authority", "screen_shell"]) == %{
               "id" => "mixed_shell",
               "type" => "column",
               "source" => "screen_inline_fragment"
             }

      assert Enum.find(iur.bindings, &(&1["id"] == "screen_title"))
      assert [%{id: "mixed_shell", type: :column} = shell] = iur.children
      assert authored_node_ids(shell) == ["leading_badge", "body_panel"]
    end

    test "relational-only and mixed composition compile the same authored element graph" do
      {:ok, mixed_attrs} =
        Authority.screen_attrs(RelationshipMixedScreen,
          name: "phase14_mixed_relationship_parity"
        )

      {:ok, relational_attrs} =
        Authority.screen_attrs(RelationshipOnlyScreen,
          name: "phase14_relational_relationship_parity"
        )

      {:ok, mixed_screen} = AshUI.Data.create(Screen, attrs: mixed_attrs)
      {:ok, relational_screen} = AshUI.Data.create(Screen, attrs: relational_attrs)

      assert {:ok, mixed_iur} = Compiler.compile(mixed_screen, use_cache: false)
      assert {:ok, relational_iur} = Compiler.compile(relational_screen, use_cache: false)

      assert authored_node_ids(mixed_iur) == ["leading_badge", "body_panel"]
      assert authored_node_ids(relational_iur) == ["leading_badge", "body_panel"]
    end
  end

  defp authored_node_ids(iur) do
    iur
    |> collect_authored_nodes()
    |> Enum.map(& &1.id)
  end

  defp collect_authored_nodes(%{metadata: %{"authoring_module" => _module}} = iur) do
    [iur | Enum.flat_map(iur.children || [], &collect_authored_nodes/1)]
  end

  defp collect_authored_nodes(%{children: children}) when is_list(children) do
    Enum.flat_map(children, &collect_authored_nodes/1)
  end

  defp collect_authored_nodes(_other), do: []
end
