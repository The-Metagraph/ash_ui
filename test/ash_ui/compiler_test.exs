defmodule AshUI.CompilerTest do
  use AshUI.DataCase, async: false

  alias AshUI.Compiler
  alias AshUI.Compilation.IUR
  alias AshUI.Resources.Screen
  alias AshUI.Test.ScreenDocumentFixtures

  @moduletag :conformance

  describe "compile/2" do
    setup do
      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs:
            ScreenDocumentFixtures.resource_screen_attrs("compiler_test_screen",
              layout: :row,
              route: "/compiler-test",
              binding_metadata: %{
                "display_name_input" => %{
                  "source" => %{
                    "resource" => "AshUI.Test.User",
                    "field" => "name",
                    "id" => "user-1"
                  },
                  "binding_type" => :value,
                  "target" => "display_name",
                  "element_id" => "display_name_input"
                }
              }
            )
        )

      %{screen: screen}
    end

    test "compiles screen resource to valid IUR structure", %{screen: screen} do
      assert {:ok, %IUR{} = iur} = Compiler.compile(screen)

      assert iur.type == :screen
      assert iur.name == "compiler_test_screen"
      assert is_map(iur.attributes)
      assert iur.attributes["layout"] == :row
      assert iur.attributes["route"] == "/compiler-test"
    end

    test "compiles authored upstream widgets as IUR children", %{screen: screen} do
      assert {:ok, %IUR{} = iur} = Compiler.compile(screen)

      assert length(iur.children) == 1

      assert %IUR{type: :column} = shell = hd(iur.children)
      assert %IUR{type: :hero} = find_iur_node(shell, :hero)
      assert %IUR{type: :stat} = find_iur_node(shell, :stat)
      assert %IUR{type: :key_value} = find_iur_node(shell, :key_value)
      assert %IUR{type: :info_list} = find_iur_node(shell, :info_list)
      assert %IUR{type: :form_field} = find_iur_node(shell, :form_field)
      assert %IUR{type: :input} = find_iur_node(shell, :input)

      assert find_iur_node(shell, :hero).props["title"] == "Elements are the authoritative units"
    end

    test "compiles persisted binding metadata as IUR bindings", %{screen: screen} do
      assert {:ok, %IUR{} = iur} = Compiler.compile(screen)

      assert length(iur.bindings) > 0

      binding =
        Enum.find(iur.bindings, fn binding ->
          binding["element_id"] == "display_name_input"
        end)

      assert is_map(binding)
      assert binding["source"]["resource"] == "AshUI.Test.User"
      assert binding["target"] == "display_name"
      assert binding["binding_type"] == :value
      assert binding["element_id"] == "display_name_input"
    end

    test "validates IUR after compilation", %{screen: screen} do
      assert {:ok, %IUR{} = iur} = Compiler.compile(screen)
      assert :ok = IUR.validate(iur)
    end
  end

  describe "compile/2 error handling" do
    test "returns error for non-existent screen" do
      assert {:error, _reason} = Compiler.compile("non-existent-id")
    end
  end

  # Phase 6: Compiler and DSL Integration Tests

  describe "compile_from_unified_dsl/2" do
    setup do
      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs:
            ScreenDocumentFixtures.resource_screen_attrs("dsl_test_screen",
              layout: :row
            )
        )

      %{screen: screen}
    end

    test "compiles valid unified_dsl to IUR", %{screen: screen} do
      assert {:ok, %IUR{} = iur} = Compiler.compile_from_unified_dsl(screen)
      assert iur.type == :screen

      assert Enum.any?(iur.children, fn child ->
               child.type == :hero or Enum.any?(child.children, &(&1.type == :hero))
             end)
    end

    test "rejects payloads outside the resource-authority contract" do
      assert {:error, error} =
               AshUI.Data.create(Screen,
                 attrs: %{
                   name: "invalid_authority_screen",
                   unified_dsl: %{"format" => "ash_ui/unified_ui_document", "version" => 2},
                   layout: :row
                 }
               )

      assert Exception.message(error) =~ "resource_authority"
    end
  end

  describe "caching" do
    setup do
      Compiler.init_cache()
      :ok
    end

    test "caches compiled IUR" do
      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs:
            ScreenDocumentFixtures.resource_screen_attrs("cache_test_screen",
              layout: :row
            )
        )

      assert {:ok, iur1} = Compiler.compile(screen, use_cache: true)
      assert {:ok, iur2} = Compiler.compile(screen, use_cache: true)
      assert iur1 == iur2

      # Should get same result
      stats = Compiler.cache_stats()
      assert stats.hits >= 1
    end

    test "use_cache: false bypasses cache" do
      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs:
            ScreenDocumentFixtures.resource_screen_attrs("no_cache_screen",
              layout: :row
            )
        )

      Compiler.clear_cache()
      Compiler.init_cache()

      assert {:ok, _iur} = Compiler.compile(screen, use_cache: false)
      assert Compiler.cache_stats().hits == 0
    end

    test "invalidate_cache removes cached entry" do
      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs:
            ScreenDocumentFixtures.resource_screen_attrs("invalidate_screen",
              layout: :row
            )
        )

      Compiler.clear_cache()
      Compiler.init_cache()

      assert {:ok, _iur} = Compiler.compile(screen)
      assert Compiler.cache_stats().size > 0

      Compiler.invalidate_cache(screen.id)

      # Size should decrease
      assert Compiler.cache_stats().size == 0
    end

    test "cache key changes when the authored upstream document changes" do
      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs:
            ScreenDocumentFixtures.resource_screen_attrs("document_hash_cache_screen",
              layout: :row
            )
        )

      Compiler.clear_cache()
      Compiler.init_cache()

      assert {:ok, _iur} = Compiler.compile(screen, use_cache: true)

      changed_document = put_in(screen.unified_dsl, ["screen", "metadata", "cache_variant"], "changed")

      changed_screen = %{screen | unified_dsl: changed_document}

      assert {:ok, _iur} = Compiler.compile(changed_screen, use_cache: true)
      assert Compiler.cache_stats().size == 2
    end

    test "clear_cache removes all entries" do
      Compiler.clear_cache()

      assert Compiler.cache_stats().size == 0
    end

    test "cache_stats returns current statistics" do
      stats = Compiler.cache_stats()

      assert is_map(stats)
      assert Map.has_key?(stats, :size)
      assert Map.has_key?(stats, :hits)
      assert Map.has_key?(stats, :misses)
    end
  end

  describe "compile_batch/2" do
    test "compiles multiple screens" do
      {:ok, screen1} =
        AshUI.Data.create(Screen,
          attrs:
            ScreenDocumentFixtures.resource_screen_attrs("batch_screen_1",
              layout: :row
            )
        )

      {:ok, screen2} =
        AshUI.Data.create(Screen,
          attrs:
            ScreenDocumentFixtures.resource_screen_attrs("batch_screen_2",
              layout: :row
            )
        )

      assert {:ok, results} = Compiler.compile_batch([screen1.id, screen2.id])
      assert map_size(results) == 2
    end
  end

  defp find_iur_node(%IUR{type: type} = node, type), do: node

  defp find_iur_node(%IUR{children: children}, type) when is_list(children) do
    Enum.find_value(children, &find_iur_node(&1, type))
  end

  defp find_iur_node(_node, _type), do: nil
end
