defmodule AshUI.Phase14IntegrationTest do
  use AshUI.DataCase, async: false

  import ExUnit.CaptureIO, only: [capture_io: 2]

  alias AshUI.Compiler
  alias AshUI.Resource.Authority
  alias AshUI.Test.{RelationshipMixedScreen, ResourceAuthorityScreen, UIStorageFixtures}

  @moduletag :integration
  @moduletag :conformance

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()

    %{ui_storage: UIStorageFixtures.ui_storage_config()}
  end

  describe "Section 14.4.1 - Relationship-driven composition scenarios" do
    test "14.4.1.1 - a screen with related element resources compiles in relationship order", %{
      ui_storage: ui_storage
    } do
      screen = create_screen!(ResourceAuthorityScreen, ui_storage, "phase14_relationship_order")

      assert {:ok, iur} = Compiler.compile(screen, ui_storage: ui_storage, use_cache: false)

      shell = find_node(iur, "screen_shell")

      assert authored_child_ids(shell) == ["dashboard_hero", "form_panel"]
    end

    test "14.4.1.2 - nested element relationships produce nested IUR output", %{
      ui_storage: ui_storage
    } do
      screen = create_screen!(ResourceAuthorityScreen, ui_storage, "phase14_nested_graph")

      assert {:ok, iur} = Compiler.compile(screen, ui_storage: ui_storage, use_cache: false)

      hero = find_node(iur, "dashboard_hero")
      form_panel = find_node(iur, "form_panel")

      assert authored_child_ids(hero) == ["current_value_stat", "renderer_meta", "explainer_list"]
      assert authored_child_ids(form_panel) == ["profile_field", "display_name_input", "save_profile_button"]
    end

    test "14.4.1.3 - mixed relational plus inline composition works", %{ui_storage: ui_storage} do
      screen = create_screen!(RelationshipMixedScreen, ui_storage, "phase14_mixed_graph")

      assert {:ok, iur} = Compiler.compile(screen, ui_storage: ui_storage, use_cache: false)

      assert get_in(iur.metadata, ["ash_ui", "resource_authority", "composition_mode"]) == "mixed"
      assert Enum.any?(iur.bindings, &(&1["id"] == "screen_title"))

      shell = find_node(iur, "mixed_shell")
      assert find_node(iur, "mixed_shell_label")
      assert authored_child_ids(shell) == ["leading_badge", "body_panel"]
    end

    test "14.4.1.4 - illegal graphs fail fast and descriptively" do
      duplicate_screen = compile_duplicate_screen!()
      cyclical_screen = compile_cyclical_screen!()

      assert {:error, {:duplicate_composition_relationships, duplicates}} =
               Authority.screen_attrs(duplicate_screen, name: unique_name("phase14_duplicate"))

      assert length(duplicates) == 1
      assert Enum.any?(duplicates, &String.contains?(&1, "Phase14DuplicateElement"))

      assert {:error, {:cyclical_composition, modules}} =
               Authority.screen_attrs(cyclical_screen, name: unique_name("phase14_cycle"))

      assert Enum.any?(modules, &String.contains?(&1, "Phase14CycleParentElement"))
      assert Enum.any?(modules, &String.contains?(&1, "Phase14CycleChildElement"))
    end
  end

  defp create_screen!(screen_module, ui_storage, prefix) do
    {:ok, screen} =
      Authority.create(screen_module,
        ui_storage: ui_storage,
        authorize?: false,
        name: unique_name(prefix)
      )

    screen
  end

  defp authored_child_ids(%{children: children}) when is_list(children) do
    children
    |> Enum.filter(&authored_node?/1)
    |> Enum.map(& &1.id)
  end

  defp authored_child_ids(_node), do: []

  defp authored_node?(%{metadata: metadata}) when is_map(metadata) do
    is_binary(Map.get(metadata, "authoring_module"))
  end

  defp authored_node?(_node), do: false

  defp find_node(%{id: id} = node, id), do: node

  defp find_node(%{children: children}, id) when is_list(children) do
    Enum.find_value(children, &find_node(&1, id))
  end

  defp find_node(_node, _id), do: nil

  defp compile_duplicate_screen! do
    suffix = System.unique_integer([:positive])
    domain = "AshUI.Test.Phase14DuplicateDomain#{suffix}"
    element = "AshUI.Test.Phase14DuplicateElement#{suffix}"
    screen = "AshUI.Test.Phase14DuplicateScreen#{suffix}"

    capture_io(:stderr, fn ->
      Code.compile_string("""
      defmodule #{domain} do
        use Ash.Domain, validate_config_inclusion?: false

        resources do
          resource #{screen}
          resource #{element}
        end
      end

      defmodule #{element} do
        use Ash.Resource,
          domain: #{domain},
          data_layer: Ash.DataLayer.Ets

        use AshUI.Resource.DSL.Element

        ets do
          private?(true)
        end

        attributes do
          uuid_primary_key(:id)
          attribute(:screen_id, :uuid, allow_nil?: true)
          attribute(:parent_id, :uuid, allow_nil?: true)
        end

        actions do
          defaults([:read])
        end

        ui_element do
          type :text
          props %{content: "Duplicate"}
          metadata %{id: "duplicate_element"}
        end
      end

      defmodule #{screen} do
        use Ash.Resource,
          domain: #{domain},
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
          has_many :left_elements, #{element} do
            destination_attribute(:screen_id)
          end

          has_many :right_elements, #{element} do
            destination_attribute(:screen_id)
          end
        end

        ui_screen do
          layout :column
        end
      end
      """)
    end)

    Module.concat(AshUI.Test, "Phase14DuplicateScreen#{suffix}")
  end

  defp compile_cyclical_screen! do
    suffix = System.unique_integer([:positive])
    domain = "AshUI.Test.Phase14CycleDomain#{suffix}"
    parent = "AshUI.Test.Phase14CycleParentElement#{suffix}"
    child = "AshUI.Test.Phase14CycleChildElement#{suffix}"
    screen = "AshUI.Test.Phase14CycleScreen#{suffix}"

    capture_io(:stderr, fn ->
      Code.compile_string("""
      defmodule #{domain} do
        use Ash.Domain, validate_config_inclusion?: false

        resources do
          resource #{screen}
          resource #{parent}
          resource #{child}
        end
      end

      defmodule #{parent} do
        use Ash.Resource,
          domain: #{domain},
          data_layer: Ash.DataLayer.Ets

        use AshUI.Resource.DSL.Element

        ets do
          private?(true)
        end

        attributes do
          uuid_primary_key(:id)
          attribute(:screen_id, :uuid, allow_nil?: true)
          attribute(:parent_id, :uuid, allow_nil?: true)
        end

        actions do
          defaults([:read])
        end

        relationships do
          has_many :children, #{child} do
            destination_attribute(:parent_id)
          end
        end

        ui_element do
          type :card
          props %{title: "Parent"}
          metadata %{id: "cycle_parent"}
        end
      end

      defmodule #{child} do
        use Ash.Resource,
          domain: #{domain},
          data_layer: Ash.DataLayer.Ets

        use AshUI.Resource.DSL.Element

        ets do
          private?(true)
        end

        attributes do
          uuid_primary_key(:id)
          attribute(:screen_id, :uuid, allow_nil?: true)
          attribute(:parent_id, :uuid, allow_nil?: true)
        end

        actions do
          defaults([:read])
        end

        relationships do
          has_many :loopbacks, #{parent} do
            destination_attribute(:parent_id)
          end
        end

        ui_element do
          type :text
          props %{content: "Child"}
          metadata %{id: "cycle_child"}
        end
      end

      defmodule #{screen} do
        use Ash.Resource,
          domain: #{domain},
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
          has_many :root_elements, #{parent} do
            destination_attribute(:screen_id)
          end
        end

        ui_screen do
          layout :column
        end
      end
      """)
    end)

    Module.concat(AshUI.Test, "Phase14CycleScreen#{suffix}")
  end

  defp unique_name(prefix) do
    "#{prefix}_#{System.unique_integer([:positive])}"
  end
end
