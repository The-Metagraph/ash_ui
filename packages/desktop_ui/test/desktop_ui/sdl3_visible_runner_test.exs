defmodule DesktopUi.Sdl3VisibleRunnerTest do
  use ExUnit.Case, async: true

  alias DesktopUi.Sdl3.{RenderPlan, VisibleRunner}

  test "visible runner exports frame scripts and executes the compiled host command deterministically" do
    {:ok, state} =
      DesktopUi.Runtime.mount_native_screen(DesktopUi.Examples.native_foundational_screen(),
        platform_target: :linux
      )

    assert {:ok, %RenderPlan{} = plan} = RenderPlan.build(state)

    script_root = Path.join(System.tmp_dir!(), "desktop_ui_visible_runner_test")
    File.mkdir_p!(script_root)
    script_path = Path.join(script_root, "native_foundational.frame")
    parent = self()

    capabilities = %{
      build: %{
        executable_path: "/tmp/desktop_ui_sdl3_host",
        launch_ready?: false,
        visible_runner_ready?: true,
        executable_probe: %{status: "visible_frame_ready"}
      }
    }

    assert {:ok, execution} =
             VisibleRunner.run(plan,
               capabilities: capabilities,
               frame_script_path: script_path,
               cleanup?: false,
               linger_ms: 250,
               run_cmd: fn executable, args, _opts ->
                 send(parent, {:visible_runner_invoked, executable, args})
                 {"visible_frame_presented", 0}
               end
             )

    assert_received {:visible_runner_invoked, "/tmp/desktop_ui_sdl3_host",
                     ["--frame-script", ^script_path, "--linger-ms", "250"]}

    assert execution.status == :ok
    assert execution.backend == :compiled_sdl3_host
    assert execution.execution_mode == :visible_window
    assert execution.visible_window?
    assert execution.presented_frame?
    assert execution.capabilities.visible_runner_ready?
    assert execution.output == "visible_frame_presented"
    assert File.read!(script_path) =~ "DESKTOP_UI_SDL3_FRAME"
  end

  test "visible runner reports a bounded error when the compiled visible backend is unavailable" do
    {:ok, state} =
      DesktopUi.Runtime.mount_native_screen(DesktopUi.Examples.native_foundational_screen(),
        platform_target: :linux
      )

    assert {:ok, %RenderPlan{} = plan} = RenderPlan.build(state)

    assert {:error, error} =
             VisibleRunner.run(plan,
               capabilities: %{
                 build: %{
                   executable_path: "/tmp/desktop_ui_sdl3_host",
                   launch_ready?: false,
                   visible_runner_ready?: false,
                   executable_probe: %{status: :missing}
                 }
               }
             )

    assert error.reason == :compiled_visible_runner_not_ready
    assert error.phase == :sdl3_visible_runner
  end

  test "visible runner writes interaction scripts and decodes interaction summaries" do
    {:ok, state} =
      DesktopUi.Runtime.mount_native_screen(DesktopUi.Examples.native_foundational_screen(),
        platform_target: :linux
      )

    assert {:ok, %RenderPlan{} = plan} = RenderPlan.build(state)

    script_root = Path.join(System.tmp_dir!(), "desktop_ui_visible_runner_interaction_test")
    File.mkdir_p!(script_root)
    script_path = Path.join(script_root, "native_foundational.frame")
    interaction_script_path = Path.join(script_root, "native_foundational.interaction")
    parent = self()
    window_id = hd(plan.windows).window_id

    capabilities = %{
      build: %{
        executable_path: "/tmp/desktop_ui_sdl3_host",
        launch_ready?: false,
        visible_runner_ready?: true,
        executable_probe: %{status: "visible_frame_ready"}
      }
    }

    interaction_events = [
      %{type: :focus_changed, window_id: window_id, focus_target: "save-button"},
      %{type: :keyboard_key_down, window_id: window_id, key: "Return"}
    ]

    assert {:ok, execution} =
             VisibleRunner.run(plan,
               capabilities: capabilities,
               frame_script_path: script_path,
               interaction_script_path: interaction_script_path,
               interaction_events: interaction_events,
               cleanup?: false,
               linger_ms: 250,
               run_cmd: fn executable, args, _opts ->
                 send(parent, {:visible_runner_invoked, executable, args})

                 {"visible_frame_presented\n{\"interaction_summary\":{\"total_events\":2,\"scripted_events\":2,\"focus_changes\":1,\"command_activations\":1}}\n",
                  0}
               end
             )

    assert_received {:visible_runner_invoked, "/tmp/desktop_ui_sdl3_host",
                     [
                       "--frame-script",
                       ^script_path,
                       "--linger-ms",
                       "250",
                       "--interaction-script",
                       ^interaction_script_path
                     ]}

    assert execution.interaction_summary == %{
             "command_activations" => 1,
             "focus_changes" => 1,
             "scripted_events" => 2,
             "total_events" => 2
           }

    assert File.read!(interaction_script_path) =~ "DESKTOP_UI_SDL3_INTERACTION"
    assert File.read!(interaction_script_path) =~ "focus_target=save-button"
  end
end
