defmodule UnifiedUi.LayoutTest do
  use ExUnit.Case, async: true

  alias Spark.Dsl.Extension

  defmodule LayoutShowcase do
    use UnifiedUi.Dsl

    identity do
      id(:layout_showcase)
      authored_ref([:examples, :layout_showcase])
    end

    composition do
      root(:layout_root)
      mode(:screen)

      box :shell do
        summary("Box shell")

        text :title do
          value("UnifiedUi layout showcase")
        end

        button :primary_action do
          label("Continue")
        end
      end

      row :toolbar do
        gap(:md)

        menu :main_menu do
          items(home: "Home", profile: "Profile")
          active_item(:home)
        end

        button :save_button do
          label("Save")
        end
      end

      column :details do
        text :details_text do
          value("Details column")
        end
      end

      grid :summary_grid do
        columns(2)

        text :summary_a do
          value("A")
        end

        text :summary_b do
          value("B")
        end
      end

      stack :overlay_stack do
        text :overlay_text do
          value("Overlay")
        end
      end
    end
  end

  test "registers baseline layout kinds for package inspection" do
    assert UnifiedUi.Layout.kinds() == [:box, :row, :column, :grid, :stack]
  end

  test "stores top-level layout nodes in the authored composition tree" do
    nodes = Extension.get_entities(LayoutShowcase, [:composition])

    assert Enum.map(nodes, & &1.kind) == [:box, :row, :column, :grid, :stack]
    assert Enum.map(nodes, & &1.family) == [:layout, :layout, :layout, :layout, :layout]
  end

  test "summarizes layout composition without requiring a renderer runtime" do
    assert UnifiedUi.Info.composition_summary(LayoutShowcase) == [
             %{
               id: :shell,
               family: :layout,
               kind: :box,
               summary: "Box shell",
               children: [
                 %{
                   id: :title,
                   family: :foundational,
                   kind: :text,
                   role: :text,
                   value: "UnifiedUi layout showcase"
                 },
                 %{id: :primary_action, family: :foundational, kind: :button, label: "Continue"}
               ]
             },
             %{
               id: :toolbar,
               family: :layout,
               kind: :row,
               children: [
                 %{
                   id: :main_menu,
                   family: :navigation,
                   kind: :menu,
                   items: [home: "Home", profile: "Profile"]
                 },
                 %{id: :save_button, family: :foundational, kind: :button, label: "Save"}
               ]
             },
             %{
               id: :details,
               family: :layout,
               kind: :column,
               children: [
                 %{
                   id: :details_text,
                   family: :foundational,
                   kind: :text,
                   role: :text,
                   value: "Details column"
                 }
               ]
             },
             %{
               id: :summary_grid,
               family: :layout,
               kind: :grid,
               children: [
                 %{id: :summary_a, family: :foundational, kind: :text, role: :text, value: "A"},
                 %{id: :summary_b, family: :foundational, kind: :text, role: :text, value: "B"}
               ]
             },
             %{
               id: :overlay_stack,
               family: :layout,
               kind: :stack,
               children: [
                 %{
                   id: :overlay_text,
                   family: :foundational,
                   kind: :text,
                   role: :text,
                   value: "Overlay"
                 }
               ]
             }
           ]
  end

  test "rejects invalid field placement at compile time" do
    assert_compile_dsl_error(
      """
      identity do
        id(:broken_field)
      end

      composition do
        root(:broken_field_root)

        form_builder :broken_form do
          field :empty_field do
            field_name(:empty)
          end
        end
      end
      """,
      "must contain exactly one input child"
    )
  end

  defp compile_module(body) do
    module_name = "Generated#{System.unique_integer([:positive])}"

    Code.compile_string("""
    defmodule UnifiedUi.LayoutTest.#{module_name} do
      use UnifiedUi.Dsl

      #{body}
    end
    """)
  end

  defp assert_compile_dsl_error(body, expected_message) do
    {pid, ref} = spawn_monitor(fn -> compile_module(body) end)

    receive do
      {:DOWN, ^ref, :process, ^pid, :normal} ->
        flunk("expected authored module compilation to fail, but it succeeded")

      {:DOWN, ^ref, :process, ^pid, reason} ->
        assert Exception.format_exit(reason) =~ expected_message
    end
  end
end
