defmodule DesktopUi.Sdl3.NativeBuild do
  @moduledoc """
  Build-path metadata for the optional compiled SDL3 native host.
  """

  alias DesktopUi.Sdl3.Capabilities

  @host_name "desktop_ui_sdl3_host"

  @spec contract() :: map()
  def contract do
    %{
      source_root: source_root(),
      output_root: output_root(),
      executable_name: executable_name(),
      executable_path: executable_path(),
      dependency_detection: [:env_override, :pkg_config, :homebrew_prefix],
      compiled_modes: [:protocol_host, :visible_frame_runner],
      first_target: :visible_window_host,
      fallback_backend: :elixir_host
    }
  end

  @spec validation_state() :: atom()
  def validation_state, do: :native_build_surface_ready

  @spec package_root() :: String.t()
  def package_root do
    Path.expand("../../..", __DIR__)
  end

  @spec source_root() :: String.t()
  def source_root do
    Path.join(package_root(), "native/desktop_ui_sdl3_host")
  end

  @spec output_root() :: String.t()
  def output_root do
    Path.join(package_root(), "priv/native")
  end

  @spec executable_name() :: String.t()
  def executable_name do
    case :os.type() do
      {:win32, _} -> "#{@host_name}.exe"
      _other -> @host_name
    end
  end

  @spec executable_path() :: String.t()
  def executable_path do
    Path.join(output_root(), executable_name())
  end

  @spec source_files() :: [String.t()]
  def source_files do
    [
      Path.join(source_root(), "src/main.c")
    ]
  end

  @spec build_recipe(keyword()) :: map()
  def build_recipe(opts \\ []) do
    %{
      executable: executable_path(),
      source_root: source_root(),
      source_files: source_files(),
      output_root: output_root(),
      compiler: Keyword.get(opts, :compiler, "cc"),
      library_resolution: [:pkg_config, :homebrew_prefix],
      validation_state: validation_state()
    }
  end

  @spec compile_plan(keyword()) :: map()
  def compile_plan(opts \\ []) do
    capabilities = Keyword.get(opts, :capabilities, Capabilities.detect())

    compiler =
      get_in(capabilities, [:toolchains, :cc, :path]) || Keyword.get(opts, :compiler, "cc")

    compile_flags =
      ["-std=c11", "-Wall", "-Wextra", "-O2"]
      |> Kernel.++(companion_macros(capabilities))
      |> Kernel.++(compiler_flags(capabilities))
      |> Enum.uniq()

    link_flags =
      capabilities
      |> linker_flags()
      |> Enum.uniq()

    %{
      compiler: compiler,
      args: compile_flags ++ source_files() ++ ["-o", executable_path()] ++ link_flags,
      companion_macros: companion_macros(capabilities),
      output_root: output_root(),
      executable: executable_path(),
      buildable?: capabilities.build.buildable?,
      launch_ready?: capabilities.build.launch_ready?,
      validation_state: :native_compile_plan_ready
    }
  end

  defp compiler_flags(capabilities) do
    capabilities
    |> Map.get(:libraries, %{})
    |> Enum.flat_map(fn {_key, details} ->
      Map.get(details, :cflags, [])
    end)
  end

  defp linker_flags(capabilities) do
    capabilities
    |> Map.get(:libraries, %{})
    |> Enum.flat_map(fn {key, details} ->
      if Map.get(details, :available?, false) do
        case Map.get(details, :libs, []) do
          [] -> default_link_flags(key)
          flags -> flags
        end
      else
        []
      end
    end)
  end

  defp companion_macros(capabilities) do
    []
    |> maybe_add_macro(
      get_in(capabilities, [:libraries, :sdl3_ttf, :available?]),
      "-DDUI_HAS_SDL3_TTF=1"
    )
    |> maybe_add_macro(
      get_in(capabilities, [:libraries, :sdl3_image, :available?]),
      "-DDUI_HAS_SDL3_IMAGE=1"
    )
  end

  defp maybe_add_macro(flags, true, macro), do: flags ++ [macro]
  defp maybe_add_macro(flags, _other, _macro), do: flags

  defp default_link_flags(:sdl3), do: ["-lSDL3"]
  defp default_link_flags(:sdl3_ttf), do: ["-lSDL3_ttf"]
  defp default_link_flags(:sdl3_image), do: ["-lSDL3_image"]
end
