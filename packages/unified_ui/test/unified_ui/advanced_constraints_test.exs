defmodule UnifiedUi.AdvancedConstraintsTest do
  use ExUnit.Case, async: true

  test "rejects overlay stacks that target non-overlay layer refs" do
    assert_compile_dsl_error(
      """
      identity do
        id(:invalid_overlay)
      end

      composition do
        root(:invalid_overlay_root)

        box :panel do
          text :copy do
            value("Panel")
          end
        end

        box :detail_panel do
          text :detail_copy do
            value("Detail")
          end
        end

        overlay :broken_overlay do
          base_ref(:panel)
          layer_refs([:detail_panel])
        end
      end
      """,
      "may only reference overlay nodes in layer_refs"
    )
  end

  test "rejects viewport content refs that point to overlay-only nodes" do
    assert_compile_dsl_error(
      """
      identity do
        id(:invalid_viewport)
      end

      composition do
        root(:invalid_viewport_root)

        toast :notice do
          message("Saved")
        end

        viewport :broken_viewport do
          content_ref(:notice)
          width(80)
          height(20)
        end
      end
      """,
      "may not target overlay nodes through content_ref"
    )
  end

  test "rejects canvas operations without positioned coordinate metadata" do
    assert_compile_dsl_error(
      """
      identity do
        id(:invalid_canvas)
      end

      composition do
        root(:invalid_canvas_root)

        canvas :broken_canvas do
          width(80)
          height(24)
          operations([
            [kind: :cell, text: "X"]
          ])
        end
      end
      """,
      "operations must declare a {x, y} position"
    )
  end

  defp compile_module(body) do
    module_name = "Generated#{System.unique_integer([:positive])}"

    Code.compile_string("""
    defmodule UnifiedUi.AdvancedConstraintsTest.#{module_name} do
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
