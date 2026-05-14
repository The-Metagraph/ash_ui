defmodule DesktopUi.Sdl3WidgetCompleteRenderingTest do
  use ExUnit.Case, async: true

  alias DesktopUi.Sdl3.RenderPlan

  test "maintained native and canonical examples produce widget-complete draw operations" do
    examples()
    |> Enum.each(fn {source, screen} ->
      assert {:ok, state} = mount_example(source, screen)
      assert {:ok, %RenderPlan{} = plan} = RenderPlan.build(state)

      operations = Enum.flat_map(plan.windows, & &1.draw_operations)

      assert plan.presentation.widget_complete_draw_operations
      refute plan.presentation.placeholder_draw_operations
      refute Enum.empty?(operations)
      refute Enum.any?(operations, &(&1.draw_kind == :widget_placeholder))
      assert Enum.all?(operations, &(is_map(&1.visual_state) and is_map(&1.metrics)))
    end)
  end

  test "advanced maintained flows expose layered, operational, and clipping draw kinds" do
    assert {:ok, state} =
             DesktopUi.Runtime.mount_native_screen(
               DesktopUi.Examples.native_advanced_operations_screen(),
               platform_target: :linux
             )

    assert {:ok, %RenderPlan{} = plan} = RenderPlan.build(state)

    draw_kinds =
      plan.windows
      |> Enum.flat_map(& &1.draw_operations)
      |> Enum.map(& &1.draw_kind)
      |> MapSet.new()

    assert MapSet.subset?(
             MapSet.new([
               :window_chrome,
               :overlay_surface,
               :dialog_surface,
               :context_menu_surface,
               :split_pane_surface,
               :viewport_surface,
               :table_surface,
               :command_palette_surface,
               :cluster_dashboard_surface,
               :gauge_surface,
               :canvas_surface,
               :positioned_fragment,
               :process_monitor_surface,
               :log_viewer_surface
             ]),
             draw_kinds
           )
  end

  defp examples do
    [
      {:native, DesktopUi.Examples.native_foundational_screen()},
      {:canonical, DesktopUi.Examples.canonical_foundational_screen()},
      {:native, DesktopUi.Examples.native_advanced_operations_screen()},
      {:canonical, DesktopUi.Examples.canonical_advanced_operations_screen()},
      {:native, DesktopUi.Examples.native_transport_review()},
      {:canonical, DesktopUi.Examples.canonical_transport_review()},
      {:native, DesktopUi.Examples.native_styled_review()},
      {:canonical, DesktopUi.Examples.canonical_styled_review()}
    ]
  end

  defp mount_example(:native, screen),
    do: DesktopUi.Runtime.mount_native_screen(screen, platform_target: :linux)

  defp mount_example(:canonical, screen),
    do: DesktopUi.Runtime.mount_iur_screen(screen, platform_target: :linux)
end
