defmodule AshUI.CompilerTest do
  use AshUI.DataCase, async: false

  alias AshUI.Compiler
  alias AshUI.Compilation.IUR
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
      assert {:ok, %IUR{} = iur} = Compiler.compile(screen)

      assert iur.type == :screen
      assert iur.name == "compiler_test_screen"
      assert is_map(iur.attributes)
      assert iur.attributes["layout"] == :row
      assert iur.attributes["route"] == "/compiler-test"
    end

    test "compiles elements as IUR children", %{screen: screen} do
      assert {:ok, %IUR{} = iur} = Compiler.compile(screen)

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
      assert {:ok, %IUR{} = iur} = Compiler.compile(screen)

      assert length(iur.bindings) > 0

      binding = hd(iur.bindings)
      assert is_map(binding)
      assert binding["source"]["resource"] == "Test"
      assert binding["target"] == "test_target"
      assert binding["binding_type"] == :value
    end

    test "validates IUR after compilation", %{screen: screen} do
      assert {:ok, %IUR{} = iur} = Compiler.compile(screen)
      assert :ok = IUR.validate(iur)
    end
  end

  describe "compile/2 with options" do
    setup do
      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs: ScreenDocumentFixtures.resource_screen_attrs("options_test_screen",
            layout: :column
          )
        )

      %{screen: screen}
    end

    test "load_elements: false skips loading elements", %{screen: screen} do
      assert {:ok, %IUR{} = iur} = Compiler.compile(screen, load_elements: false)
      assert iur.children == []
    end

    test "load_bindings: false skips loading bindings", %{screen: screen} do
      assert {:ok, %IUR{} = iur} = Compiler.compile(screen, load_bindings: false)
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
      dsl = %{
        type: "row",
        props: %{"spacing" => 16},
        children: [
          %{
            type: "text",
            props: %{"content" => "Hello"},
            children: [],
            signals: [],
            metadata: %{}
          }
        ],
        signals: [],
        metadata: %{}
      }

      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs: ScreenDocumentFixtures.migrated_screen_attrs("dsl_test_screen", dsl,
            layout: :row
          )
        )

      %{screen: screen, dsl: dsl}
    end

    test "compiles valid unified_dsl to IUR", %{screen: screen} do
      assert {:ok, %IUR{} = iur} = Compiler.compile_from_unified_dsl(screen)
      assert iur.type == :screen
    end

    test "validates dsl before compilation" do
      invalid_dsl = %{
        "format" => "ash_ui/unified_ui_document",
        "version" => 2,
        "authoring" => %{
          "source" => %{
            "kind" => "legacy_builder_migration",
            "migration" => %{
              "from_format" => "ash_ui.dsl.builder",
              "from_version" => 1,
              "mode" => "deterministic"
            }
          },
          "package" => %{},
          "document" => %{
            "identity" => %{"id" => "invalid_dsl_screen"},
            "composition" => %{
              "mode" => "screen",
              "root" => %{"id" => "invalid", "kind" => "invalid_widget_type", "family" => "unknown"}
            }
          }
        },
        "ash_ui" => %{
          "screen" => %{"name" => "invalid_dsl_screen", "layout" => "row", "route" => nil},
          "metadata" => %{},
          "binding_metadata" => %{},
          "runtime_annotations" => %{
            "extension_points" => %{},
            "construct_families" => %{},
            "compiler_dsl" => %{
              "type" => "invalid_widget_type",
              "props" => %{},
              "children" => [],
              "signals" => [],
              "metadata" => %{}
            }
          }
        }
      }

      assert {:error, error} =
               AshUI.Data.create(Screen,
                 attrs: %{
                   name: "invalid_dsl_screen",
                   unified_dsl: invalid_dsl,
                   layout: :row
                 }
               )

      assert Exception.message(error) =~ "compiler_dsl is invalid"
      assert Exception.message(error) =~ "invalid_widget_type"
    end
  end

  describe "caching" do
    setup do
      Compiler.init_cache()
      :ok
    end

    test "caches compiled IUR" do
      dsl = %{
        type: "text",
        props: %{"content" => "Cached"},
        children: [],
        signals: [],
        metadata: %{}
      }

      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs: ScreenDocumentFixtures.migrated_screen_attrs("cache_test_screen", dsl,
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
      dsl = %{
        type: "text",
        props: %{},
        children: [],
        signals: [],
        metadata: %{}
      }

      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs: ScreenDocumentFixtures.migrated_screen_attrs("no_cache_screen", dsl,
            layout: :row
          )
        )

      Compiler.clear_cache()
      Compiler.init_cache()

      assert {:ok, _iur} = Compiler.compile(screen, use_cache: false)
      assert Compiler.cache_stats().hits == 0
    end

    test "invalidate_cache removes cached entry" do
      dsl = %{
        type: "text",
        props: %{},
        children: [],
        signals: [],
        metadata: %{}
      }

      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs: ScreenDocumentFixtures.migrated_screen_attrs("invalidate_screen", dsl,
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
      # Create multiple screens
      dsl1 = %{type: "text", props: %{}, children: [], signals: [], metadata: %{}}
      dsl2 = %{type: "button", props: %{}, children: [], signals: [], metadata: %{}}

      {:ok, screen1} =
        AshUI.Data.create(Screen,
          attrs: ScreenDocumentFixtures.migrated_screen_attrs("batch_screen_1", dsl1,
            layout: :row
          )
        )

      {:ok, screen2} =
        AshUI.Data.create(Screen,
          attrs: ScreenDocumentFixtures.migrated_screen_attrs("batch_screen_2", dsl2,
            layout: :row
          )
        )

      assert {:ok, results} = Compiler.compile_batch([screen1.id, screen2.id])
      assert map_size(results) == 2
    end
  end
end
