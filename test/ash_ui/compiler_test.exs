defmodule AshUI.CompilerTest do
  use AshUI.DataCase, async: false

  alias AshUI.Compiler
  alias AshUI.Authoring.Migrator
  alias AshUI.Compilation.IUR
  alias AshUI.DSL.Builder
  alias AshUI.Resources.Screen
  alias AshUI.Resources.Element
  alias AshUI.Resources.Binding
  alias AshUI.Test.ScreenDocumentFixtures

  @moduletag :conformance

  describe "compile/2" do
    setup do
      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs:
            ScreenDocumentFixtures.resource_screen_attrs("compiler_test_screen",
              layout: :row,
              route: "/compiler-test"
            )
        )

      # Create test elements
      {:ok, element1} =
        AshUI.Data.create(Element,
          attrs: %{
            type: :text,
            props: %{"content" => "Hello"},
            screen_id: screen.id,
            position: 1
          }
        )

      {:ok, element2} =
        AshUI.Data.create(Element,
          attrs: %{
            type: :button,
            props: %{"label" => "Click me"},
            screen_id: screen.id,
            position: 2
          }
        )

      # Create test binding
      {:ok, _binding} =
        AshUI.Data.create(Binding,
          attrs: %{
            source: %{"resource" => "Test", "field" => "value"},
            target: "test_target",
            binding_type: :value,
            element_id: element1.id,
            screen_id: screen.id
          }
        )

      %{screen: screen, elements: [element1, element2]}
    end

    test "compiles screen resource to valid IUR structure", %{screen: screen} do
      assert {:ok, %IUR{} = iur} = Compiler.compile(screen, compile_mode: :resources)

      assert iur.type == :screen
      assert iur.name == "compiler_test_screen"
      assert is_map(iur.attributes)
      assert iur.attributes["layout"] == :row
      assert iur.attributes["route"] == "/compiler-test"
    end

    test "compiles elements as IUR children", %{screen: screen} do
      assert {:ok, %IUR{} = iur} = Compiler.compile(screen, compile_mode: :resources)

      assert length(iur.children) == 2

      # First element is text
      [child1, child2] = iur.children
      assert child1.type == :text
      assert child1.props["content"] == "Hello"

      # Second element is button
      assert child2.type == :button
      assert child2.props["label"] == "Click me"
    end

    test "compiles bindings as IUR bindings", %{screen: screen} do
      assert {:ok, %IUR{} = iur} = Compiler.compile(screen, compile_mode: :resources)

      assert length(iur.bindings) > 0

      binding = hd(iur.bindings)
      assert is_map(binding)
      assert binding["source"]["resource"] == "Test"
      assert binding["target"] == "test_target"
      assert binding["binding_type"] == :value
    end

    test "validates IUR after compilation", %{screen: screen} do
      assert {:ok, %IUR{} = iur} = Compiler.compile(screen, compile_mode: :resources)
      assert :ok = IUR.validate(iur)
    end
  end

  describe "compile/2 with options" do
    setup do
      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs:
            ScreenDocumentFixtures.resource_screen_attrs("options_test_screen",
              layout: :column
            )
        )

      %{screen: screen}
    end

    test "load_elements: false skips loading elements", %{screen: screen} do
      assert {:ok, %IUR{} = iur} =
               Compiler.compile(screen, compile_mode: :resources, load_elements: false)

      assert iur.children == []
    end

    test "load_bindings: false skips loading bindings", %{screen: screen} do
      assert {:ok, %IUR{} = iur} =
               Compiler.compile(screen, compile_mode: :resources, load_bindings: false)

      assert iur.bindings == []
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

    test "rejects migrated builder documents after the hard cutover" do
      attrs =
        Migrator.screen_attrs!(
          Builder.text("Legacy"),
          name: "legacy_dsl_screen",
          layout: :row
        )

      assert {:ok, screen} = AshUI.Data.create(Screen, attrs: attrs)

      assert {:error, {:unsupported_authoring_document, :phase_11_upstream_modules_only}} =
               Compiler.compile_from_unified_dsl(screen)
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

      changed_document =
        put_in(
          screen.unified_dsl,
          ["ash_ui", "metadata", "cache_variant"],
          "changed"
        )

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
end
