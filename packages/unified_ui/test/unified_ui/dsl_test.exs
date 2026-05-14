defmodule UnifiedUi.DslTest do
  use ExUnit.Case, async: true

  import Spark.Dsl.Extension, only: [get_opt: 4]

  defmodule ExampleScreen do
    use UnifiedUi.Dsl

    identity do
      id(:example_screen)
      title("Example Screen")
      description("Minimal authored screen")
      authored_ref([:examples, :example_screen])
      annotations(source: :test)
      tags([:example])
    end

    composition do
      root(:screen_shell)
      mode(:screen)
      summary("Baseline screen shell")
    end

    themes do
      default_theme(:workspace)

      theme do
        id(:workspace)

        palette_color do
          id(:surface)
          color(named_color(:black))
        end
      end
    end

    signals do
      namespace(:workspace)
      default_target(:session)
    end
  end

  test "registers the baseline Spark sections and extension points" do
    assert UnifiedUi.Dsl.section_names() == [:identity, :composition, :themes, :signals]

    assert UnifiedUi.Dsl.extension_points() == %{
             identity: [:metadata_fields, :traceability_fields],
             composition: [:widget_entities, :layout_entities, :layer_entities],
             themes: [:theme_entities, :style_entities, :token_entities],
             signals: [:signal_entities, :binding_entities, :payload_entities]
           }

    assert UnifiedUi.Dsl.default_section_options() == %{
             identity: %{annotations: %{}, tags: []},
             composition: %{mode: :screen},
             themes: %{inherit?: true},
             signals: %{mode: :canonical}
           }
  end

  test "compiles a minimal authored module through the Spark DSL extension" do
    assert :example_screen == get_opt(ExampleScreen, [:identity], :id, nil)
    assert "Example Screen" == get_opt(ExampleScreen, [:identity], :title, nil)
    assert [:examples, :example_screen] == get_opt(ExampleScreen, [:identity], :authored_ref, nil)

    assert :screen_shell == get_opt(ExampleScreen, [:composition], :root, nil)
    assert :screen == get_opt(ExampleScreen, [:composition], :mode, nil)

    assert :workspace == get_opt(ExampleScreen, [:themes], :default_theme, nil)
    assert :workspace == get_opt(ExampleScreen, [:signals], :namespace, nil)
    assert :session == get_opt(ExampleScreen, [:signals], :default_target, nil)
  end

  test "exposes author-facing helper imports for metadata values" do
    assert UnifiedUi.Dsl.module_imports() == [UnifiedUi.Dsl.Helpers]
    assert UnifiedUi.Dsl.Helpers.annotation_map(source: :test) == %{source: :test}
    assert UnifiedUi.Dsl.Helpers.tag_list([:alpha, :alpha, :beta]) == [:alpha, :beta]
    assert UnifiedUi.Dsl.Helpers.path_segments(:profile) == [:profile]
  end
end
