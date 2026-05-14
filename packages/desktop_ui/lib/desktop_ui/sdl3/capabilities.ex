defmodule DesktopUi.Sdl3.Capabilities do
  @moduledoc """
  Capability discovery for compiled SDL3 host support and fallback selection.
  """

  alias DesktopUi.Sdl3.NativeBuild

  @sdl_packages [
    sdl3: %{pkg_config: ["sdl3"], brew: "sdl3", link_flag: "-lSDL3"},
    sdl3_ttf: %{
      pkg_config: ["sdl3-ttf", "sdl3_ttf"],
      brew: "sdl3_ttf",
      link_flag: "-lSDL3_ttf"
    },
    sdl3_image: %{
      pkg_config: ["sdl3-image", "sdl3_image"],
      brew: "sdl3_image",
      link_flag: "-lSDL3_image"
    }
  ]

  @type probe_opts :: keyword()

  @spec contract() :: map()
  def contract do
    %{
      discovery_sources: [:env_override, :built_executable, :pkg_config, :homebrew_prefix],
      preferred_backend: :compiled_sdl3_host,
      fallback_backend: :elixir_host,
      compiled_host_probe: :json_stdout,
      visible_runner_probe: :json_stdout,
      required_toolchains: [:cc],
      optional_tooling: [:pkg_config, :brew]
    }
  end

  @spec validation_state() :: atom()
  def validation_state, do: :capability_detection_ready

  @spec detect(probe_opts()) :: map()
  def detect(opts \\ []) do
    toolchains = detect_toolchains(opts)
    built_executable = detect_built_executable(opts)
    libraries = detect_libraries(toolchains, opts)
    build = detect_build(toolchains, libraries, built_executable)

    %{
      toolchains: toolchains,
      libraries: libraries,
      build: build,
      backend: %{
        preferred: :compiled_sdl3_host,
        fallback: :elixir_host,
        recommended: backend_recommendation(build),
        available: backend_availability(build),
        validation_state: validation_state()
      }
    }
  end

  @spec recommended_backend(probe_opts()) :: atom()
  def recommended_backend(opts) when is_list(opts) do
    opts |> detect() |> get_in([:backend, :recommended])
  end

  @spec built_executable_path(probe_opts()) :: String.t() | nil
  def built_executable_path(opts \\ []) do
    opts |> detect_built_executable() |> Map.get(:path)
  end

  @spec compiled_host_available?(probe_opts()) :: boolean()
  def compiled_host_available?(opts \\ []) do
    opts |> detect_built_executable() |> Map.get(:available?, false)
  end

  @spec compiled_host_launch_ready?(probe_opts()) :: boolean()
  def compiled_host_launch_ready?(opts \\ []) do
    opts |> detect() |> get_in([:build, :launch_ready?])
  end

  defp detect_toolchains(opts) do
    %{
      cc: executable_probe("cc", opts),
      pkg_config: executable_probe("pkg-config", opts),
      brew: executable_probe("brew", opts)
    }
  end

  defp detect_built_executable(opts) do
    env = env_map(opts)
    override = Map.get(env, "DESKTOP_UI_SDL3_HOST")
    override_available? = is_binary(override) and file_exists?(override, opts)

    compiled_path = NativeBuild.executable_path()
    compiled_available? = file_exists?(compiled_path, opts)

    %{
      override_path: override,
      override_available?: override_available?,
      compiled_path: compiled_path,
      compiled_available?: compiled_available?,
      path: if(override_available?, do: override, else: compiled_path),
      available?: override_available? or compiled_available?,
      probe:
        if override_available? or compiled_available? do
          probe_host(if(override_available?, do: override, else: compiled_path), opts)
        else
          %{available?: false, launch_ready?: false, status: :missing}
        end
    }
  end

  defp detect_libraries(toolchains, opts) do
    brew_prefixes = detect_homebrew_prefixes(toolchains, opts)

    Map.new(@sdl_packages, fn {key, package_config} ->
      {key, library_probe(package_config, key, toolchains, brew_prefixes, opts)}
    end)
  end

  defp detect_homebrew_prefixes(toolchains, opts) do
    if toolchains.brew.available? do
      Map.new(@sdl_packages, fn {key, package_config} ->
        {key, homebrew_prefix(package_config.brew, opts)}
      end)
    else
      %{}
    end
  end

  defp detect_build(toolchains, libraries, built_executable) do
    required_packages = [:sdl3]
    companion_packages = [:sdl3_ttf, :sdl3_image]

    all_required_available? =
      Enum.all?(required_packages, &get_in(libraries, [&1, :available?]))

    companion_available =
      Enum.filter(companion_packages, &get_in(libraries, [&1, :available?]))

    %{
      native_build_surface: NativeBuild.contract(),
      toolchain_ready?: toolchains.cc.available?,
      required_libraries_ready?: all_required_available?,
      companion_libraries_ready: companion_available,
      native_text_ready?:
        companion_backend_ready?(:native_text_ready?, built_executable, libraries, :sdl3_ttf),
      native_image_ready?:
        companion_backend_ready?(:native_image_ready?, built_executable, libraries, :sdl3_image),
      executable_present?: built_executable.available?,
      executable_path: built_executable.path,
      launch_ready?: get_in(built_executable, [:probe, :launch_ready?]) || false,
      visible_runner_ready?: get_in(built_executable, [:probe, :visible_runner_ready?]) || false,
      executable_probe: built_executable.probe,
      buildable?: toolchains.cc.available? and all_required_available?,
      validation_state: NativeBuild.validation_state()
    }
  end

  defp backend_recommendation(%{executable_present?: true, launch_ready?: true}),
    do: :compiled_sdl3_host

  defp backend_recommendation(_build), do: :elixir_host

  defp backend_availability(%{executable_present?: true}),
    do: [:compiled_sdl3_host, :elixir_host]

  defp backend_availability(_build), do: [:elixir_host]

  defp library_probe(package_config, key, toolchains, brew_prefixes, opts) do
    pkg_config_result = pkg_config_probe(package_config.pkg_config, toolchains, opts)
    brew_prefix = Map.get(brew_prefixes, key)

    cond do
      pkg_config_result.available? ->
        pkg_config_result
        |> Map.put(:source, :pkg_config)
        |> Map.put(:formula, package_config.brew)

      is_binary(brew_prefix) ->
        %{
          package: List.first(package_config.pkg_config),
          requested_packages: package_config.pkg_config,
          formula: package_config.brew,
          available?: true,
          source: :homebrew_prefix,
          prefix: brew_prefix,
          cflags: ["-I#{Path.join(brew_prefix, "include")}"],
          libs: ["-L#{Path.join(brew_prefix, "lib")}", package_config.link_flag]
        }

      true ->
        %{
          package: List.first(package_config.pkg_config),
          requested_packages: package_config.pkg_config,
          formula: package_config.brew,
          available?: false,
          source: :missing,
          prefix: nil,
          cflags: [],
          libs: []
        }
    end
  end

  defp pkg_config_probe(package_names, toolchains, opts) do
    if toolchains.pkg_config.available? do
      Enum.find_value(
        package_names,
        unavailable_pkg_config_result(package_names),
        fn package_name ->
          case run_cmd(toolchains.pkg_config.path, ["--exists", package_name], opts) do
            {_, 0} ->
              {prefix_output, _} =
                run_cmd(toolchains.pkg_config.path, ["--variable=prefix", package_name], opts)

              {cflags_output, _} =
                run_cmd(toolchains.pkg_config.path, ["--cflags", package_name], opts)

              {libs_output, _} =
                run_cmd(toolchains.pkg_config.path, ["--libs", package_name], opts)

              %{
                package: package_name,
                requested_packages: package_names,
                available?: true,
                prefix: String.trim(prefix_output),
                cflags: split_flags(cflags_output),
                libs: split_flags(libs_output)
              }

            _other ->
              nil
          end
        end
      )
    else
      unavailable_pkg_config_result(package_names)
    end
  end

  defp homebrew_prefix(package_name, opts) do
    brew_path = executable_probe("brew", opts).path

    case run_cmd(brew_path, ["--prefix", package_name], opts) do
      {output, 0} ->
        case String.trim(output) do
          "" -> nil
          trimmed -> if(prefix_usable?(trimmed, opts), do: trimmed, else: nil)
        end

      _other ->
        nil
    end
  end

  defp probe_host(path, opts) when is_binary(path) do
    case run_cmd(path, ["--probe"], opts) do
      {output, 0} ->
        case JSON.decode(output) do
          {:ok, decoded} when is_map(decoded) ->
            %{
              available?: true,
              launch_ready?: Map.get(decoded, "launch_ready", false) == true,
              visible_runner_ready?: visible_runner_ready?(decoded),
              native_text_ready?: Map.get(decoded, "native_text_ready", false) == true,
              native_image_ready?: Map.get(decoded, "native_image_ready", false) == true,
              status: Map.get(decoded, "status", "unknown"),
              backend: Map.get(decoded, "backend"),
              compiled_with: Map.get(decoded, "compiled_with"),
              text_mode: Map.get(decoded, "text_mode"),
              image_mode: Map.get(decoded, "image_mode")
            }

          _other ->
            %{
              available?: true,
              launch_ready?: false,
              visible_runner_ready?: false,
              native_text_ready?: false,
              native_image_ready?: false,
              status: :invalid_probe_payload
            }
        end

      _other ->
        %{
          available?: true,
          launch_ready?: false,
          visible_runner_ready?: false,
          native_text_ready?: false,
          native_image_ready?: false,
          status: :probe_failed
        }
    end
  end

  defp executable_probe(name, opts) do
    path = find_executable(name, opts)

    %{
      name: String.to_atom(String.replace(name, "-", "_")),
      path: path,
      available?: is_binary(path)
    }
  end

  defp env_map(opts) do
    opts
    |> Keyword.get(:env, System.get_env())
    |> Enum.into(%{})
  end

  defp find_executable(name, opts) do
    finder = Keyword.get(opts, :find_executable, &System.find_executable/1)
    finder.(name)
  end

  defp run_cmd(nil, _args, _opts), do: {"", 127}

  defp run_cmd(executable, args, opts) do
    runner = Keyword.get(opts, :run_cmd, &System.cmd/3)
    runner.(executable, args, stderr_to_stdout: true)
  rescue
    _error -> {"", 127}
  end

  defp file_exists?(path, opts) do
    checker = Keyword.get(opts, :file_exists?, &File.exists?/1)
    checker.(path)
  end

  defp prefix_usable?(prefix, opts) do
    file_exists?(prefix, opts) and file_exists?(Path.join(prefix, "include"), opts) and
      file_exists?(Path.join(prefix, "lib"), opts)
  end

  defp unavailable_pkg_config_result(package_names) do
    %{
      package: List.first(package_names),
      requested_packages: package_names,
      available?: false,
      prefix: nil,
      cflags: [],
      libs: []
    }
  end

  defp split_flags(output) when is_binary(output) do
    output
    |> String.trim()
    |> case do
      "" -> []
      trimmed -> OptionParser.split(trimmed)
    end
  end

  defp companion_backend_ready?(probe_key, built_executable, libraries, library_key) do
    if built_executable.available? do
      get_in(built_executable, [:probe, probe_key]) || false
    else
      get_in(libraries, [library_key, :available?]) || false
    end
  end

  defp visible_runner_ready?(decoded) do
    Map.get(decoded, "visible_runner_ready", false) == true or
      Map.get(decoded, "launch_ready", false) == true or
      Map.get(decoded, "status") in ["visible_frame_ready", "protocol_ready"]
  end
end
