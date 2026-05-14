defmodule DesktopUi.PhaseTenIntegrationTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias DesktopUi.Sdl3.{Capabilities, FrameEncoder, NativeBuild, RenderPlan, VisibleRunner}

  @moduletag timeout: 300_000

  @maintained_examples [
    :native_foundational,
    :canonical_foundational,
    :native_advanced_operations,
    :canonical_advanced_operations,
    :native_transport_review,
    :canonical_transport_review,
    :native_styled_review,
    :canonical_styled_review
  ]

  setup_all do
    {:ok, capabilities: ensure_visible_runner_capabilities()}
  end

  test "maintained examples render widget-complete frames and native resources when SDL3 companions are ready",
       %{capabilities: capabilities} do
    text_support = DesktopUi.Sdl3.Text.native_support(capabilities)
    image_support = DesktopUi.Sdl3.Images.native_support(capabilities)

    if capabilities.build.visible_runner_ready? and text_support.native_backend_ready? and
         image_support.native_backend_ready? do
      Enum.each(@maintained_examples, fn example_id ->
        assert {:ok, execution} =
                 DesktopUi.Tooling.run_example(example_id,
                   backend: :compiled,
                   capabilities: capabilities,
                   linger_ms: 75
                 )

        assert execution.execution_mode == :visible_window
        assert execution.backend == :compiled_sdl3_host
        assert execution.visible_window?
        assert execution.presented_frame?
        refute execution.fallback_used?
        assert execution.resource_support.text.active_mode == :native_companion_library
        assert execution.resource_support.images.active_mode == :native_companion_library
        assert execution.details.render_plan.draw_operation_count > 0
        assert execution.details.render_plan.window_count >= 1
        assert execution.details.capabilities.native_text_ready?
        assert execution.details.capabilities.native_image_ready?
      end)
    else
      assert {:ok, execution} =
               DesktopUi.Tooling.run_example(:native_styled_review,
                 backend: :fallback,
                 capabilities: unavailable_capabilities(capabilities),
                 linger_ms: 1
               )

      assert execution.execution_mode == :protocol_fallback
      assert execution.fallback_used?
      assert execution.resource_support.text.active_mode == :elixir_measurement_fallback
      assert execution.resource_support.images.active_mode == :raw_pixel_fallback
    end
  end

  test "compiled interaction outcomes stay aligned with fallback-host render semantics",
       %{capabilities: capabilities} do
    assert {:ok, state} =
             DesktopUi.Runtime.mount_native_screen(
               DesktopUi.Examples.native_advanced_operations_screen(),
               platform_target: :linux
             )

    assert {:ok, %RenderPlan{} = plan} = RenderPlan.build(state)
    assert {:ok, frame_payload} = FrameEncoder.encode(plan)

    operations_window = Enum.find(plan.windows, &(&1.title == "Operations"))
    details_window = Enum.find(plan.windows, &(&1.title == "Details"))
    services_table = find_operation!(plan, "services-table")
    dialog_close = find_operation!(plan, "dialog-close")
    encoded_services_table = find_encoded_operation!(frame_payload, "services-table")
    encoded_dialog_close = find_encoded_operation!(frame_payload, "dialog-close")

    assert encoded_services_table.interaction.focusable
    assert encoded_services_table.interaction.selection_mode == :single
    assert encoded_dialog_close.interaction.click_intent == :close_dialog
    assert Enum.any?(frame_payload.windows, &(&1.window_id == operations_window.window_id))
    assert Enum.any?(frame_payload.windows, &(&1.window_id == details_window.window_id))

    fallback_capabilities = unavailable_capabilities(capabilities)

    assert {:ok, fallback_execution} =
             DesktopUi.Tooling.run_example(:native_advanced_operations,
               backend: :fallback,
               capabilities: fallback_capabilities,
               linger_ms: 1
             )

    assert fallback_execution.execution_mode == :protocol_fallback
    assert fallback_execution.fallback_used?
    assert fallback_execution.presented_frame?

    presented_window_ids =
      fallback_execution.details.frame.payload.presentation.presented_windows
      |> Enum.map(& &1.window_id)

    assert operations_window.window_id in presented_window_ids
    assert details_window.window_id in presented_window_ids

    if capabilities.build.visible_runner_ready? do
      interaction_events = [
        %{type: :window_activated, window_id: operations_window.window_id},
        %{
          type: :pointer_hover,
          window_id: operations_window.window_id,
          pointer: operation_center(services_table)
        },
        %{
          type: :pointer_button,
          window_id: operations_window.window_id,
          button: "left",
          pointer: operation_center(services_table)
        },
        %{
          type: :wheel_scrolled,
          window_id: operations_window.window_id,
          delta_y: 1,
          pointer: operation_center(services_table)
        },
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
                 linger_ms: 75
               )

      assert execution.presented_frame?
      assert execution.backend == :compiled_sdl3_host
      assert execution.interaction_summary["total_events"] == length(interaction_events)
      assert execution.interaction_summary["focus_changes"] >= 1
      assert execution.interaction_summary["selection_changes"] >= 1
      assert execution.interaction_summary["scroll_events"] >= 1
      assert execution.interaction_summary["command_activations"] >= 1
      assert execution.interaction_summary["window_activations"] >= 2
      assert execution.interaction_summary["multiwindow_focus_transfers"] >= 1
      assert execution.interaction_summary["last_selected_widget_id"] == services_table.widget_id
      assert execution.interaction_summary["last_scroll_widget_id"] == services_table.widget_id
      assert execution.interaction_summary["last_command_widget_id"] == dialog_close.widget_id
      assert execution.interaction_summary["last_command_intent"] == "close_dialog"
      assert execution.interaction_summary["active_window_id"] == details_window.window_id
    else
      refute capabilities.build.visible_runner_ready?
    end
  end

  test "inspection, validation, and run diagnostics report widget-complete status and explicit fallback degradation",
       %{capabilities: capabilities} do
    inspection = DesktopUi.Inspection.sdl3_adapter_surface()
    validation_summary = DesktopUi.Validate.validation_summary(DesktopUi.Validate.validation_report())
    fallback_capabilities = unavailable_capabilities(capabilities)

    assert inspection.renderer_completeness == :widget_complete_interactive
    assert inspection.visible_runner.widget_complete_rendering
    assert inspection.visible_runner.interactive_execution
    assert :explicit_fallback_when_sdl3_unavailable in inspection.manual_review_workflow.expectations

    assert validation_summary =~ "widget-complete native rendering?: true"
    assert validation_summary =~ "interactive native execution?: true"

    assert {:ok, fallback_execution} =
             DesktopUi.Tooling.run_example(:native_foundational,
               backend: :fallback,
               capabilities: fallback_capabilities,
               linger_ms: 1
             )

    assert fallback_execution.execution_mode == :protocol_fallback
    assert fallback_execution.fallback_used?
    refute fallback_execution.visible_window?
    assert fallback_execution.fallback_reason.visible_runner_ready? == false
    assert fallback_execution.resource_support.text.active_mode == :elixir_measurement_fallback
    assert fallback_execution.resource_support.images.active_mode == :raw_pixel_fallback

    backend_summary = DesktopUi.Tooling.run_backend_summary(fallback_capabilities)

    refute backend_summary.visible_runner_ready?
    refute backend_summary.interactive_visible_execution_ready?
    assert backend_summary.text.active_mode == :elixir_measurement_fallback
    assert backend_summary.images.active_mode == :raw_pixel_fallback

    output =
      capture_io(fn ->
        run_task("desktop_ui.run", ["native_foundational", "--format", "summary", "--backend", "fallback"])
      end)

    assert output =~ "renderer completeness: bounded_fallback_review"
    assert output =~ "interactive visible execution?: false"
    assert output =~ "fallback used?: true"
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

  defp unavailable_capabilities(capabilities) do
    %{
      capabilities
      | build:
          capabilities.build
          |> Map.put(:visible_runner_ready?, false)
          |> Map.put(:launch_ready?, false)
          |> Map.put(:native_text_ready?, false)
          |> Map.put(:native_image_ready?, false)
          |> Map.put(:executable_probe, %{status: :missing}),
        backend:
          capabilities.backend
          |> Map.put(:recommended, :elixir_host)
          |> Map.put(:available, [:elixir_host]),
        libraries:
          capabilities.libraries
          |> Map.update(:sdl3_ttf, %{available?: false}, &Map.put(&1, :available?, false))
          |> Map.update(:sdl3_image, %{available?: false}, &Map.put(&1, :available?, false))
    }
  end

  defp operation_center(operation) do
    bounds = operation.logical_bounds

    %{
      x: bounds.x + div(bounds.width, 2),
      y: bounds.y + div(bounds.height, 2)
    }
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

  defp find_encoded_operation!(frame_payload, widget_id) do
    frame_payload.windows
    |> Enum.flat_map(& &1.draw_operations)
    |> Enum.find(&(&1.widget_id == widget_id))
    |> case do
      nil -> flunk("expected encoded draw operation #{inspect(widget_id)} to exist")
      operation -> operation
    end
  end

  defp run_task(task, args) do
    Mix.Task.reenable("app.start")
    Mix.Task.reenable(task)
    Mix.Task.run(task, args)
  end
end
