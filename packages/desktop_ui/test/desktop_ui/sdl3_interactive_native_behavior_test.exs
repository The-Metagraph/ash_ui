defmodule DesktopUi.Sdl3InteractiveNativeBehaviorTest do
  use ExUnit.Case, async: false

  alias DesktopUi.Sdl3.{Capabilities, NativeBuild, RenderPlan, VisibleRunner}

  test "compiled visible runner preserves maintained interactive behavior when SDL3 is available" do
    capabilities = ensure_visible_runner_capabilities()

    if capabilities.build.visible_runner_ready? do
      {:ok, state} =
        DesktopUi.Runtime.mount_native_screen(
          DesktopUi.Examples.native_advanced_operations_screen(),
          platform_target: :linux
        )

      assert {:ok, %RenderPlan{} = plan} = RenderPlan.build(state)

      operations_window = Enum.find(plan.windows, &(&1.title == "Operations"))
      details_window = Enum.find(plan.windows, &(&1.title == "Details"))
      services_table = find_operation!(plan, "services-table")
      dialog_close = find_operation!(plan, "dialog-close")

      interaction_events = [
        %{type: :window_activated, window_id: operations_window.window_id},
        %{
          type: :focus_changed,
          window_id: operations_window.window_id,
          focus_target: services_table.widget_id
        },
        %{type: :keyboard_key_down, window_id: operations_window.window_id, key: "Down"},
        %{
          type: :focus_changed,
          window_id: operations_window.window_id,
          focus_target: dialog_close.widget_id
        },
        %{type: :keyboard_key_down, window_id: operations_window.window_id, key: "Return"},
        %{type: :window_activated, window_id: details_window.window_id}
      ]

      assert {:ok, execution} =
               VisibleRunner.run(plan,
                 capabilities: capabilities,
                 interaction_events: interaction_events,
                 linger_ms: 250
               )

      assert execution.status == :ok
      assert execution.presented_frame?
      assert execution.backend == :compiled_sdl3_host

      assert execution.interaction_summary["total_events"] == 6
      assert execution.interaction_summary["scripted_events"] == 6
      assert execution.interaction_summary["focus_changes"] >= 2
      assert execution.interaction_summary["command_activations"] >= 1
      assert execution.interaction_summary["selection_changes"] >= 1
      assert execution.interaction_summary["scroll_events"] >= 1
      assert execution.interaction_summary["overlay_transitions"] >= 1
      assert execution.interaction_summary["window_activations"] >= 2
      assert execution.interaction_summary["multiwindow_focus_transfers"] >= 1
      assert execution.interaction_summary["last_selected_widget_id"] == services_table.widget_id
      assert execution.interaction_summary["last_command_widget_id"] == dialog_close.widget_id
      assert execution.interaction_summary["last_command_intent"] == "close_dialog"
      assert execution.interaction_summary["last_scroll_widget_id"] == services_table.widget_id
      assert execution.interaction_summary["active_window_id"] == details_window.window_id
    else
      refute capabilities.build.visible_runner_ready?
      assert capabilities.backend.fallback == :elixir_host
    end
  end

  defp ensure_visible_runner_capabilities do
    capabilities = Capabilities.detect()

    cond do
      capabilities.build.visible_runner_ready? ->
        capabilities

      capabilities.build.buildable? ->
        compile_plan = NativeBuild.compile_plan(capabilities: capabilities)
        File.mkdir_p!(compile_plan.output_root)
        {_, 0} = System.cmd(compile_plan.compiler, compile_plan.args, stderr_to_stdout: true)
        Capabilities.detect()

      true ->
        capabilities
    end
  end

  defp find_operation!(plan, widget_id) do
    plan.windows
    |> Enum.flat_map(& &1.draw_operations)
    |> Enum.find(&(&1.widget_id == widget_id))
    |> case do
      nil -> flunk("expected draw operation #{inspect(widget_id)} to exist")
      operation -> operation
    end
  end
end
