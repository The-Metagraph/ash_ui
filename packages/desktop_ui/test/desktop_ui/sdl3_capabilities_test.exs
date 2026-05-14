defmodule DesktopUi.Sdl3CapabilitiesTest do
  use ExUnit.Case, async: true

  alias DesktopUi.Sdl3.{Capabilities, NativeBuild}

  test "native build surface exposes deterministic source and executable paths" do
    contract = NativeBuild.contract()
    recipe = NativeBuild.build_recipe()

    assert String.ends_with?(
             contract.source_root,
             "packages/desktop_ui/native/desktop_ui_sdl3_host"
           )

    assert String.ends_with?(contract.output_root, "packages/desktop_ui/priv/native")
    assert String.ends_with?(contract.executable_path, NativeBuild.executable_name())
    assert recipe.validation_state == :native_build_surface_ready
    assert Enum.any?(recipe.source_files, &String.ends_with?(&1, "src/main.c"))
  end

  test "capability detection recommends fallback host when no toolchain or executable is present" do
    result =
      Capabilities.detect(
        env: %{},
        find_executable: fn _ -> nil end,
        file_exists?: fn _ -> false end,
        run_cmd: fn _exe, _args, _opts -> {"", 127} end
      )

    assert result.backend.recommended == :elixir_host
    assert result.backend.available == [:elixir_host]
    refute result.build.buildable?
    refute result.build.executable_present?
    refute result.toolchains.cc.available?
    refute result.libraries.sdl3.available?
  end

  test "capability detection keeps fallback recommended when compiled host exists but is not launch ready" do
    result =
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
            {"{\"status\":\"build_ready\",\"launch_ready\":false,\"visible_runner_ready\":false,\"backend\":\"compiled_sdl3_host\"}\n",
             0}

          "/usr/bin/pkg-config", ["--exists", "sdl3"], _opts ->
            {"", 0}

          "/usr/bin/pkg-config", ["--variable=prefix", "sdl3"], _opts ->
            {"/opt/sdl3\n", 0}

          "/usr/bin/pkg-config", ["--cflags", "sdl3"], _opts ->
            {"-I/opt/sdl3/include\n", 0}

          "/usr/bin/pkg-config", ["--libs", "sdl3"], _opts ->
            {"-L/opt/sdl3/lib -lSDL3\n", 0}

          "/usr/bin/pkg-config", ["--exists", package], _opts
          when package in ["sdl3-ttf", "sdl3_ttf", "sdl3-image", "sdl3_image"] ->
            {"", 1}

          "/usr/bin/pkg-config", ["--variable=prefix", _package], _opts ->
            {"", 1}

          "/usr/bin/pkg-config", ["--cflags", _package], _opts ->
            {"", 1}

          "/usr/bin/pkg-config", ["--libs", _package], _opts ->
            {"", 1}
        end
      )

    assert result.backend.recommended == :elixir_host
    assert result.backend.available == [:compiled_sdl3_host, :elixir_host]
    assert result.build.executable_present?
    assert result.build.executable_path == "/tmp/desktop_ui_sdl3_host"
    refute result.build.launch_ready?
    refute result.build.visible_runner_ready?
    assert result.libraries.sdl3.available?
    refute result.libraries.sdl3_ttf.available?
    refute result.libraries.sdl3_image.available?
  end

  test "capability detection exposes visible-runner readiness separately from protocol launch readiness" do
    result =
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

          "/usr/bin/pkg-config", ["--cflags", "sdl3"], _opts ->
            {"-I/opt/sdl3/include\n", 0}

          "/usr/bin/pkg-config", ["--libs", "sdl3"], _opts ->
            {"-L/opt/sdl3/lib -lSDL3\n", 0}

          "/usr/bin/pkg-config", ["--exists", package], _opts
          when package in ["sdl3-ttf", "sdl3_ttf", "sdl3-image", "sdl3_image"] ->
            {"", 1}

          "/usr/bin/pkg-config", ["--variable=prefix", _package], _opts ->
            {"", 1}

          "/usr/bin/pkg-config", ["--cflags", _package], _opts ->
            {"", 1}

          "/usr/bin/pkg-config", ["--libs", _package], _opts ->
            {"", 1}
        end
      )

    assert result.backend.recommended == :elixir_host
    refute result.build.launch_ready?
    assert result.build.visible_runner_ready?
  end

  test "capability detection recommends compiled host once probe reports launch readiness" do
    result =
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
            {"{\"status\":\"protocol_ready\",\"launch_ready\":true,\"visible_runner_ready\":true,\"backend\":\"compiled_sdl3_host\"}\n",
             0}

          "/usr/bin/pkg-config", ["--exists", "sdl3"], _opts ->
            {"", 0}

          "/usr/bin/pkg-config", ["--variable=prefix", "sdl3"], _opts ->
            {"/opt/sdl3\n", 0}

          "/usr/bin/pkg-config", ["--cflags", "sdl3"], _opts ->
            {"-I/opt/sdl3/include\n", 0}

          "/usr/bin/pkg-config", ["--libs", "sdl3"], _opts ->
            {"-L/opt/sdl3/lib -lSDL3\n", 0}

          "/usr/bin/pkg-config", ["--exists", package], _opts
          when package in ["sdl3-ttf", "sdl3_ttf", "sdl3-image", "sdl3_image"] ->
            {"", 1}

          "/usr/bin/pkg-config", ["--variable=prefix", _package], _opts ->
            {"", 1}

          "/usr/bin/pkg-config", ["--cflags", _package], _opts ->
            {"", 1}

          "/usr/bin/pkg-config", ["--libs", _package], _opts ->
            {"", 1}
        end
      )

    assert result.backend.recommended == :compiled_sdl3_host
    assert result.build.launch_ready?
    assert result.build.visible_runner_ready?
  end

  test "capability detection accepts hyphenated SDL3 companion pkg-config names and compile plans emit macros" do
    capabilities =
      Capabilities.detect(
        env: %{},
        find_executable: fn
          "cc" -> "/usr/bin/cc"
          "pkg-config" -> "/usr/bin/pkg-config"
          _other -> nil
        end,
        file_exists?: fn _ -> false end,
        run_cmd: fn
          "/usr/bin/pkg-config", ["--exists", "sdl3"], _opts ->
            {"", 0}

          "/usr/bin/pkg-config", ["--variable=prefix", "sdl3"], _opts ->
            {"/opt/sdl3\n", 0}

          "/usr/bin/pkg-config", ["--cflags", "sdl3"], _opts ->
            {"-I/opt/sdl3/include\n", 0}

          "/usr/bin/pkg-config", ["--libs", "sdl3"], _opts ->
            {"-L/opt/sdl3/lib -lSDL3\n", 0}

          "/usr/bin/pkg-config", ["--exists", "sdl3-ttf"], _opts ->
            {"", 0}

          "/usr/bin/pkg-config", ["--variable=prefix", "sdl3-ttf"], _opts ->
            {"/opt/sdl3_ttf\n", 0}

          "/usr/bin/pkg-config", ["--cflags", "sdl3-ttf"], _opts ->
            {"-I/opt/sdl3_ttf/include\n", 0}

          "/usr/bin/pkg-config", ["--libs", "sdl3-ttf"], _opts ->
            {"-L/opt/sdl3_ttf/lib -lSDL3_ttf -lSDL3\n", 0}

          "/usr/bin/pkg-config", ["--exists", "sdl3-image"], _opts ->
            {"", 0}

          "/usr/bin/pkg-config", ["--variable=prefix", "sdl3-image"], _opts ->
            {"/opt/sdl3_image\n", 0}

          "/usr/bin/pkg-config", ["--cflags", "sdl3-image"], _opts ->
            {"-I/opt/sdl3_image/include -DAVIF_DLL\n", 0}

          "/usr/bin/pkg-config", ["--libs", "sdl3-image"], _opts ->
            {"-L/opt/sdl3_image/lib -lSDL3_image -lSDL3\n", 0}

          "/usr/bin/pkg-config", [_op, _package], _opts ->
            {"", 1}
        end
      )

    plan = NativeBuild.compile_plan(capabilities: capabilities)

    assert capabilities.libraries.sdl3_ttf.package == "sdl3-ttf"
    assert capabilities.libraries.sdl3_image.package == "sdl3-image"
    assert capabilities.build.native_text_ready?
    assert capabilities.build.native_image_ready?
    assert "-DDUI_HAS_SDL3_TTF=1" in plan.args
    assert "-DDUI_HAS_SDL3_IMAGE=1" in plan.args
    assert "-I/opt/sdl3_ttf/include" in plan.args
    assert "-DAVIF_DLL" in plan.args
    assert "-lSDL3_ttf" in plan.args
    assert "-lSDL3_image" in plan.args
  end
end
