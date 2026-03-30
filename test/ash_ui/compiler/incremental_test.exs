defmodule AshUI.Compiler.IncrementalTest do
  use AshUI.DataCase, async: false

  alias AshUI.Compiler.Incremental
  alias AshUI.Resources.Screen
  alias AshUI.Test.ScreenDocumentFixtures

  describe "build_dependencies/1" do
    setup do
      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs:
            ScreenDocumentFixtures.resource_screen_attrs(unique_name("incremental_test_screen"),
              layout: :row
            )
        )

      %{screen: screen}
    end

    test "builds dependency graph for screen", %{screen: screen} do
      assert {:ok, graph} = Incremental.build_dependencies(screen)

      assert is_map(graph.screen_to_elements)
      assert is_map(graph.element_to_screen)
      assert is_map(graph.element_to_bindings)
      assert is_map(graph.binding_to_element)
    end

    test "tracks authored element to screen relationships", %{screen: screen} do
      {:ok, graph} = Incremental.build_dependencies(screen)

      assert graph.element_to_screen["dashboard_hero"] == screen.id
    end

    test "tracks authored binding to element relationships", %{screen: screen} do
      {:ok, graph} = Incremental.build_dependencies(screen)

      assert graph.binding_to_element["current_value"] == "current_value_stat"
    end

    test "detects no circular dependencies in valid graph", %{screen: screen} do
      {:ok, graph} = Incremental.build_dependencies(screen)

      assert Incremental.detect_circular_dependencies(graph) == :ok
    end

    test "derives authored element and binding dependencies from persisted documents" do
      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs:
            ScreenDocumentFixtures.resource_screen_attrs(
              unique_name("authored_dependency_screen"),
              binding_metadata: %{
                "display_name_input" => %{
                  "source" => %{"resource" => "User", "field" => "name", "id" => "user-1"},
                  "binding_type" => :value,
                  "element_id" => "display_name_input"
                }
              }
            )
        )

      assert {:ok, graph} = Incremental.build_dependencies(screen)
      assert screen.id in Map.keys(graph.screen_to_elements)
      assert "display_name_input" in graph.screen_to_elements[screen.id]
      assert graph.binding_to_element["display_name_input"] == "display_name_input"
    end

    test "rebuilds authority dependencies from the screen resource graph when serialized nodes drift" do
      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs:
            ScreenDocumentFixtures.resource_screen_attrs(
              unique_name("resource_graph_dependency_screen")
            )
        )

      changed_document = %{
        "format" => screen.unified_dsl["format"],
        "version" => screen.unified_dsl["version"],
        "screen" => %{"module" => get_in(screen.unified_dsl, ["screen", "module"])}
      }

      runtime_screen = %{screen | unified_dsl: changed_document}

      assert {:ok, graph} = Incremental.build_dependencies(runtime_screen)
      assert "dashboard_hero" in graph.screen_to_elements[screen.id]
      assert "display_name_input" in graph.screen_to_elements[screen.id]
      assert graph.binding_to_element["display_name_input"] == "display_name_input"
    end
  end

  describe "affects_screen?/4" do
    setup do
      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs:
            ScreenDocumentFixtures.resource_screen_attrs(unique_name("affects_test_screen"),
              layout: :row
            )
        )

      {:ok, graph} = Incremental.build_dependencies(screen)

      %{screen: screen, graph: graph}
    end

    test "returns true when authored element belongs to screen", %{graph: graph, screen: screen} do
      assert Incremental.affects_screen?(graph, :element, "dashboard_hero", screen.id) == true
    end

    test "returns false for unrelated element", %{graph: graph, screen: screen} do
      assert Incremental.affects_screen?(graph, :element, "unrelated-element", screen.id) == false
    end
  end

  describe "get_dependents/3" do
    setup do
      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs:
            ScreenDocumentFixtures.resource_screen_attrs(unique_name("dependents_test_screen"),
              layout: :row
            )
        )

      {:ok, graph} = Incremental.build_dependencies(screen)

      %{screen: screen, graph: graph}
    end

    test "returns all dependents of an authored element", %{graph: graph} do
      {:ok, dependents} = Incremental.get_dependents(graph, :element, "current_value_stat")

      assert length(dependents) >= 1
      assert Enum.any?(dependents, &(&1.type == :screen))
      assert Enum.any?(dependents, &(&1.type == :binding and &1.id == "current_value"))
    end
  end

  describe "detect_circular_dependencies/1" do
    test "returns :ok for acyclic graph" do
      graph = %{
        screen_to_elements: %{"screen-1" => ["element-1"]},
        element_to_screen: %{"element-1" => "screen-1"},
        element_to_bindings: %{},
        binding_to_element: %{}
      }

      assert Incremental.detect_circular_dependencies(graph) == :ok
    end

    test "returns error for cyclic graph" do
      graph = %{
        screen_to_elements: %{"screen-1" => ["screen-1"]},
        element_to_screen: %{"screen-1" => "screen-1"},
        element_to_bindings: %{},
        binding_to_element: %{}
      }

      assert {:error, cycles} = Incremental.detect_circular_dependencies(graph)
      assert length(cycles) > 0
    end
  end

  describe "recompile_on_change/4" do
    setup do
      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs:
            ScreenDocumentFixtures.resource_screen_attrs(unique_name("recompile_test_screen"),
              layout: :row
            )
        )

      %{screen: screen}
    end

    test "recompiles screen when element changes", %{screen: screen} do
      # Mark screen as needing recompile by invalidating cache
      AshUI.Compiler.invalidate_cache(screen.id)

      # The actual recompile would happen on element change
      # This tests the path
      assert {:ok, _iur} = AshUI.Compiler.compile(screen, use_cache: false)
    end

    test "returns cached version when unaffected change", %{screen: screen} do
      # Compile once to cache
      assert {:ok, _iur} = AshUI.Compiler.compile(screen, use_cache: true)

      # Compile again should hit cache
      {:ok, _iur} = AshUI.Compiler.compile(screen, use_cache: true)

      stats = AshUI.Compiler.cache_stats()
      assert stats.hits >= 1
    end
  end

  describe "recompile_batch/2" do
    test "recompiles multiple screens efficiently" do
      changes = [
        {:screen, "screen-1", :element, "element-1"},
        {:screen, "screen-2", :binding, "binding-1"}
      ]

      # Should not error even with non-existent screens
      assert {:ok, results} = Incremental.recompile_batch(changes)
      assert is_map(results)
    end

    test "handles empty changes list" do
      assert {:ok, %{}} = Incremental.recompile_batch([])
    end
  end

  defp unique_name(prefix) do
    "#{prefix}_#{System.unique_integer([:positive])}"
  end
end
