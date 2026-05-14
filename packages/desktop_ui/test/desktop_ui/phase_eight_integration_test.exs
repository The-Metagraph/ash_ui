defmodule DesktopUi.PhaseEightIntegrationTest do
  use ExUnit.Case, async: true

  alias DesktopUi.Sdl3.Capabilities

  test "capability detection distinguishes buildable, visible-ready, and fallback-only environments" do
    fallback_only =
      Capabilities.detect(
        env: %{},
        find_executable: fn _ -> nil end,
        file_exists?: fn _ -> false end,
        run_cmd: fn _exe, _args, _opts -> {"", 127} end
      )

    buildable_not_built =
      Capabilities.detect(
        env: %{},
        find_executable: fn
          "cc" -> "/usr/bin/cc"
          "pkg-config" -> "/usr/bin/pkg-config"
          _other -> nil
        end,
        file_exists?: fn _ -> false end,
        run_cmd: fn
          "/usr/bin/pkg-config", ["--exists", "sdl3"], _opts -> {"", 0}
          "/usr/bin/pkg-config", ["--variable=prefix", "sdl3"], _opts -> {"/opt/sdl3\n", 0}
          "/usr/bin/pkg-config", ["--exists", _package], _opts -> {"", 1}
          "/usr/bin/pkg-config", ["--variable=prefix", _package], _opts -> {"", 1}
        end
      )

    visible_ready =
      Capabilities.detect(
        env: %{"DESKTOP_UI_SDL3_HOST" => "/tmp/desktop_ui_sdl3_host"},
        find_executable: fn
          "cc" -> "/usr/bin/cc"
          "pkg-config" -> "/usr/bin/pkg-config"
          _other -> nil
        end,
        file_exists?: fn
          "/tmp/desktop_ui_sdl3_host" -> true
          _other -> false
        end,
        run_cmd: fn
          "/tmp/desktop_ui_sdl3_host", ["--probe"], _opts ->
            {"{\"status\":\"visible_frame_ready\",\"launch_ready\":false,\"visible_runner_ready\":true,\"backend\":\"compiled_sdl3_host\"}\n",
             0}

          "/usr/bin/pkg-config", ["--exists", "sdl3"], _opts ->
            {"", 0}

          "/usr/bin/pkg-config", ["--variable=prefix", "sdl3"], _opts ->
            {"/opt/sdl3\n", 0}

          "/usr/bin/pkg-config", ["--exists", _package], _opts ->
            {"", 1}

          "/usr/bin/pkg-config", ["--variable=prefix", _package], _opts ->
            {"", 1}
        end
      )

    refute fallback_only.build.buildable?
    assert fallback_only.backend.available == [:elixir_host]

    assert buildable_not_built.build.buildable?
    refute buildable_not_built.build.executable_present?
    refute buildable_not_built.build.visible_runner_ready?

    assert visible_ready.build.visible_runner_ready?
    assert visible_ready.backend.available == [:compiled_sdl3_host, :elixir_host]
  end

  test "run execution chooses the compiled visible runner when it is ready" do
    parent = self()

    capabilities = %{
      build: %{
        executable_path: "/tmp/desktop_ui_sdl3_host",
        executable_present?: true,
        buildable?: true,
        launch_ready?: false,
        visible_runner_ready?: true,
        executable_probe: %{status: "visible_frame_ready"}
      },
      backend: %{recommended: :elixir_host, fallback: :elixir_host}
    }

    assert {:ok, execution} =
             DesktopUi.Tooling.run_example(:native_foundational,
               capabilities: capabilities,
               linger_ms: 1,
               run_cmd: fn executable, args, _opts ->
                 send(parent, {:compiled_visible_runner, executable, args})
                 {"visible_frame_presented", 0}
               end
             )

    assert_received {:compiled_visible_runner, "/tmp/desktop_ui_sdl3_host",
                     ["--frame-script", _script_path, "--linger-ms", "1"]}

    assert execution.backend == :compiled_sdl3_host
    assert execution.execution_mode == :visible_window
    assert execution.visible_window?
    assert execution.presented_frame?
    assert execution.details.render_plan.logical_units
    assert execution.details.render_plan.window_ids != []
  end

  test "run execution falls back explicitly when the compiled visible runner is unavailable" do
    capabilities = %{
      build: %{
        executable_path: "/tmp/desktop_ui_sdl3_host",
        executable_present?: false,
        buildable?: false,
        launch_ready?: false,
        visible_runner_ready?: false,
        executable_probe: %{status: :missing}
      },
      backend: %{recommended: :elixir_host, fallback: :elixir_host},
      libraries: %{
        sdl3_ttf: %{available?: false},
        sdl3_image: %{available?: false}
      }
    }

    assert {:ok, execution} =
             DesktopUi.Tooling.run_example(:native_foundational,
               capabilities: capabilities,
               linger_ms: 1
             )

    assert execution.backend == :elixir_host
    assert execution.execution_mode == :protocol_fallback
    refute execution.visible_window?
    assert execution.presented_frame?
    assert execution.fallback_used?
    refute execution.resource_support.text.native_backend_ready?
    refute execution.resource_support.images.native_backend_ready?
    assert execution.details.frame.payload.presentation.presented_windows != []

    assert Enum.all?(
             execution.details.frame.payload.presentation.presented_windows,
             &(get_in(&1, [:logical_bounds, :units]) == :logical)
           )
  end
end
