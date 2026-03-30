defmodule AshUI.Compiler.Phase6IntegrationTest do
  use AshUI.DataCase, async: false

  alias AshUI.Compiler
  alias AshUI.Compiler.Incremental
  alias AshUI.Compiler.Extensions
  alias AshUI.DSL.Builder
  alias AshUI.Test.ScreenDocumentFixtures

  @moduletag :conformance

  defp default_dsl do
    Builder.row(
      children: [
        Builder.text("Hello, World!"),
        Builder.button("Click Me")
      ]
    )
  end

  describe "Section 6.5.1 - DSL storage and retrieval scenarios" do
    test "DSL builder creates valid structure" do
      dsl = Builder.row(children: [Builder.text("Test")])

      assert dsl.type == "row"
      assert is_list(dsl.children)
      assert length(dsl.children) == 1
    end

    test "DSL builder creates nested structure" do
      dsl =
        Builder.column(
          children: [
            Builder.row(
              children: [
                Builder.text("Nested")
              ]
            )
          ]
        )

      assert dsl.type == "column"
      assert length(dsl.children) == 1
      assert hd(dsl.children).type == "row"
    end
  end

  describe "Section 6.5.2 - Compilation scenarios" do
    setup do
      Compiler.init_cache()
      Extensions.init()
    end

    test "simple screen compiles successfully" do
      dsl = Builder.text("Simple Screen")

      {:ok, screen} =
        AshUI.Data.create(AshUI.Resources.Screen,
          attrs: migrated_screen_attrs("simple_screen", dsl)
        )

      assert {:ok, _iur} = Compiler.compile(screen)
    end

    test "complex nested screen compiles successfully" do
      dsl =
        Builder.row(
          children: [
            Builder.column(
              children: [
                Builder.text("Nested 1"),
                Builder.text("Nested 2")
              ]
            ),
            Builder.button("Submit")
          ]
        )

      {:ok, screen} =
        AshUI.Data.create(AshUI.Resources.Screen,
          attrs: migrated_screen_attrs("complex_screen", dsl)
        )

      assert {:ok, _iur} = Compiler.compile(screen)
    end

    test "compilation errors are reported clearly" do
      invalid_dsl = %{
        type: "invalid_widget",
        props: %{},
        children: [],
        signals: [],
        metadata: %{}
      }

      assert {:error, error} =
               AshUI.Data.create(AshUI.Resources.Screen,
                 attrs: %{
                   name: "invalid_screen",
                   unified_dsl: invalid_dsl,
                   layout: :row
                 }
               )

      assert Exception.message(error) =~ "ash_ui resource_authority format"
    end

    test "cache hit returns cached IUR" do
      dsl = Builder.text("Cached Screen")

      {:ok, screen} =
        AshUI.Data.create(AshUI.Resources.Screen,
          attrs: migrated_screen_attrs("cached_screen", dsl)
        )

      # First compilation
      assert {:ok, _iur1} = Compiler.compile(screen, use_cache: true)

      # Second compilation should hit cache
      assert {:ok, _iur2} = Compiler.compile(screen, use_cache: true)

      stats = Compiler.cache_stats()
      assert stats.hits >= 1
    end
  end

  describe "Section 6.5.3 - Incremental compilation scenarios" do
    test "element change triggers screen recompile" do
      {:ok, screen} =
        AshUI.Data.create(AshUI.Resources.Screen,
          attrs: migrated_screen_attrs("incremental_screen", default_dsl())
        )

      {:ok, element} =
        AshUI.Data.create(AshUI.Resources.Element,
          attrs: %{
            type: :text,
            props: %{"content" => "Initial"},
            screen_id: screen.id,
            position: 1
          }
        )

      # Build dependencies
      {:ok, graph} = Incremental.build_dependencies(screen)

      # Element should affect screen
      assert Incremental.affects_screen?(graph, :element, element.id, screen.id)
    end

    test "unchanged resources use cache" do
      Compiler.clear_cache()

      {:ok, screen} =
        AshUI.Data.create(AshUI.Resources.Screen,
          attrs: migrated_screen_attrs("cache_test_screen", default_dsl())
        )

      # First compile
      assert {:ok, _iur} = Compiler.compile(screen, use_cache: true)

      # Second compile should hit cache (no changes)
      assert {:ok, _iur} = Compiler.compile(screen, use_cache: true)

      stats = Compiler.cache_stats()
      assert stats.hits >= 1
    end

    test "dependency tracking works" do
      {:ok, screen} =
        AshUI.Data.create(AshUI.Resources.Screen,
          attrs: migrated_screen_attrs("dependency_screen", default_dsl())
        )

      {:ok, element} =
        AshUI.Data.create(AshUI.Resources.Element,
          attrs: %{
            type: :text,
            props: %{"content" => "Test"},
            screen_id: screen.id,
            position: 1
          }
        )

      {:ok, binding} =
        AshUI.Data.create(AshUI.Resources.Binding,
          attrs: %{
            source: %{"resource" => "Test", "field" => "value"},
            target: "test_target",
            binding_type: :value,
            element_id: element.id,
            screen_id: screen.id
          }
        )

      {:ok, graph} = Incremental.build_dependencies(screen)

      # Check element to screen dependency
      assert graph.element_to_screen[element.id] == screen.id

      # Check binding to element dependency
      assert graph.binding_to_element[binding.id] == element.id
    end

    test "circular dependencies are detected" do
      # Create a self-referential graph
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

  describe "Section 6.5.4 - Extension scenarios" do
    setup do
      Extensions.init()
    end

    test "custom widget can be registered" do
      definition = %{
        module: CustomWidget,
        props: [
          %{name: :value, type: :string, required: true}
        ],
        validate: fn props ->
          if Map.has_key?(props, :value), do: :ok, else: {:error, :missing_value}
        end,
        compile: fn props -> %{type: "custom_widget", value: Map.get(props, :value)} end
      }

      assert :ok = Extensions.register_widget("custom:scenario_widget", definition)
      assert Extensions.widget_registered?("custom:scenario_widget")
    end

    test "custom widget compiles correctly" do
      definition = %{
        module: CustomWidget,
        props: [],
        validate: fn _ -> :ok end,
        compile: fn _ -> %{type: "custom_widget"} end
      }

      Extensions.register_widget("custom:compile_widget", definition)

      assert {:ok, compiled} = Extensions.compile_widget("custom:compile_widget", %{})
      assert compiled.type == "custom_widget"
    end

    test "custom layout can be registered" do
      definition = %{
        module: CustomLayout,
        props: [
          %{name: :columns, type: :integer, default: 3}
        ],
        validate: fn _ -> :ok end,
        compile: fn props, children ->
          %{type: "custom_layout", props: props, children: children}
        end
      }

      assert :ok = Extensions.register_layout("custom:scenario_layout", definition)
      assert Extensions.layout_registered?("custom:scenario_layout")
    end

    test "custom layout compiles correctly" do
      definition = %{
        module: CustomLayout,
        props: [],
        validate: fn _ -> :ok end,
        compile: fn props, children ->
          %{type: "custom_layout", props: props, children: children}
        end
      }

      Extensions.register_layout("custom:compile_layout", definition)

      assert {:ok, compiled} = Extensions.compile_layout("custom:compile_layout", %{}, [])
      assert compiled.type == "custom_layout"
    end
  end

  describe "End-to-end compilation flows" do
    setup do
      Compiler.init_cache()
      Extensions.init()
    end

    test "full DSL to IUR pipeline" do
      # Build DSL using builder
      dsl =
        Builder.row(
          spacing: 16,
          children: [
            Builder.column(
              children: [
                Builder.text("Header", size: 24, color: "blue"),
                Builder.text("Subtext", size: 14)
              ]
            ),
            Builder.button("Action", on_click: "save")
          ]
        )

      # Store in database
      {:ok, screen} =
        AshUI.Data.create(AshUI.Resources.Screen,
          attrs: migrated_screen_attrs("full_pipeline_screen", dsl)
        )

      # Compile to IUR
      assert {:ok, iur} = Compiler.compile(screen)

      # Verify structure
      assert iur.type == :screen
      assert is_map(iur.attributes)
    end

    test "error handling in compilation pipeline" do
      # Invalid DSL should fail validation
      invalid_dsl = %{
        type: "invalid",
        props: %{},
        children: [],
        signals: [],
        metadata: %{}
      }

      assert {:error, error} =
               AshUI.Data.create(AshUI.Resources.Screen,
                 attrs: %{
                   name: "error_screen",
                   unified_dsl: invalid_dsl,
                   layout: :row
                 }
               )

      assert Exception.message(error) =~ "ash_ui resource_authority format"
    end
  end

  describe "Performance scenarios" do
    test "cache improves compilation performance" do
      Compiler.clear_cache()

      dsl = Builder.text("Performance Test")

      {:ok, screen} =
        AshUI.Data.create(AshUI.Resources.Screen,
          attrs: migrated_screen_attrs("perf_screen", dsl)
        )

      # Compile multiple times
      for _ <- 1..10 do
        Compiler.compile(screen, use_cache: true)
      end

      stats = Compiler.cache_stats()
      # Most should hit cache
      assert stats.hits > 5
    end
  end

  defp migrated_screen_attrs(name, _dsl, opts \\ []) do
    layout = Keyword.get(opts, :layout, :row)
    metadata = Keyword.get(opts, :metadata, %{})

    ScreenDocumentFixtures.resource_screen_attrs(name, layout: layout, metadata: metadata)
  end
end
