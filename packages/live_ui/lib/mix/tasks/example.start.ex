defmodule Mix.Tasks.Example.Start do
  use Mix.Task

  @shortdoc "Starts the current example app with an optional target package"

  @moduledoc """
  Starts the current example app from its own directory.

      mix example.start
      mix example.start --target-package live_ui
      mix example.start --target-package desktop_ui
      mix example.start --target-package elm_ui
      mix example.start --target-package terminal_ui
      mix example.start --target-package desktop_ui --platform macos --linger-ms 5000
      mix example.start --target-package terminal_ui --backend-mode tty
      mix example.start --port 4100

  The default target package is `live_ui`. Use `desktop_ui` to run the example
  through the native desktop runtime instead of starting Phoenix.

  `elm_ui` and `terminal_ui` currently run the compiled example through their
  canonical runtime mount paths and print review-oriented runtime output to
  stdout rather than starting a standalone browser or terminal session.
  """

  @impl true
  def run(args) do
    Mix.Task.run("compile")

    {opts, positional, invalid} =
      OptionParser.parse(args,
        strict: [
          backend_mode: :string,
          help: :boolean,
          linger_ms: :integer,
          platform: :string,
          port: :integer,
          runtime: :string,
          target_package: :string
        ]
      )

    cond do
      opts[:help] ->
        Mix.shell().info(@moduledoc)

      positional != [] or invalid != [] ->
        Mix.raise("""
        usage: mix example.start [--target-package live_ui|desktop_ui|elm_ui|terminal_ui] [--runtime live_ui|desktop_ui|elm_ui|terminal_ui] [--port PORT] [--platform auto|linux|macos|windows] [--linger-ms MILLISECONDS] [--backend-mode auto|raw|tty]
        """)

      true ->
        target_package = selected_target_package(opts)

        case target_package do
          :live_ui -> run_live_ui(opts)
          :desktop_ui -> run_desktop_ui(opts)
          :elm_ui -> run_elm_ui(opts)
          :terminal_ui -> run_terminal_ui(opts)
        end
    end
  end

  defp run_live_ui(opts) do
    port =
      opts
      |> Keyword.get(:port)
      |> maybe_to_string()

    put_target_package_env(:live_ui)

    if port do
      System.put_env("PORT", port)
    end

    Mix.Tasks.Phx.Server.run([])
  end

  defp run_desktop_ui(opts) do
    desktop_runtime = Module.concat([DesktopUi, Runtime])
    render_plan_module = Module.concat([DesktopUi, Sdl3, RenderPlan])
    visible_runner_module = Module.concat([DesktopUi, Sdl3, VisibleRunner])

    ensure_runtime_available!(desktop_runtime, :desktop_ui)
    ensure_runtime_available!(render_plan_module, :desktop_ui)
    ensure_runtime_available!(visible_runner_module, :desktop_ui)

    put_target_package_env(:desktop_ui)

    platform_target =
      opts
      |> Keyword.get(:platform, "auto")
      |> parse_platform()

    linger_ms = Keyword.get(opts, :linger_ms, 5_000)
    example_module = example_module()
    iur_element = current_example_iur(example_module)

    Mix.shell().info("Starting #{inspect(example_module)} with desktop_ui on #{platform_target}")

    with {:ok, runtime_state} <-
           apply(desktop_runtime, :mount_iur, [iur_element, [platform_target: platform_target]]),
         {:ok, render_plan} <- apply(render_plan_module, :build, [runtime_state]) do
      case apply(visible_runner_module, :run, [render_plan, [linger_ms: linger_ms]]) do
        {:ok, result} ->
          result

        {:error, reason} ->
          Mix.raise("desktop_ui example launch failed: #{inspect(reason)}")
      end
    else
      {:error, reason} ->
        Mix.raise("desktop_ui example launch failed: #{inspect(reason)}")
    end
  end

  defp run_elm_ui(_opts) do
    elm_runtime = Module.concat([ElmUi, Runtime])
    inspection_module = Module.concat([ElmUi, Inspection])

    ensure_runtime_available!(elm_runtime, :elm_ui)
    ensure_runtime_available!(inspection_module, :elm_ui)

    put_target_package_env(:elm_ui)

    example_module = example_module()
    iur_element = current_example_renderable_iur(example_module)

    Mix.shell().info("Starting #{inspect(example_module)} with elm_ui review output")

    case apply(elm_runtime, :mount_iur_screen, [iur_element, []]) do
      {:ok, runtime_state} ->
        case apply(inspection_module, :runtime_snapshot, [runtime_state]) do
          {:ok, snapshot} ->
            print_runtime_snapshot("ElmUi runtime snapshot", snapshot)

          {:error, reason} ->
            Mix.raise("elm_ui example launch failed: #{inspect(reason)}")
        end

      {:error, reason} ->
        if print_runtime_compatibility_report(:elm_ui, reason, example_module, iur_element) do
          :ok
        else
          Mix.raise("elm_ui example launch failed: #{inspect(reason)}")
        end
    end
  end

  defp run_terminal_ui(opts) do
    terminal_runtime = Module.concat([TerminalUi, Runtime])
    inspection_module = Module.concat([TerminalUi, Inspection])

    ensure_runtime_available!(terminal_runtime, :terminal_ui)
    ensure_runtime_available!(inspection_module, :terminal_ui)

    put_target_package_env(:terminal_ui)

    backend_mode =
      opts
      |> Keyword.get(:backend_mode, "auto")
      |> parse_backend_mode()

    example_module = example_module()
    iur_element = current_example_renderable_iur(example_module)

    Mix.shell().info(
      "Starting #{inspect(example_module)} with terminal_ui review output on #{backend_mode}"
    )

    case apply(terminal_runtime, :mount_iur_screen, [iur_element, [backend_mode: backend_mode]]) do
      {:ok, runtime_state} ->
        snapshot = apply(inspection_module, :runtime_snapshot, [runtime_state])
        print_runtime_snapshot("TerminalUi runtime snapshot", snapshot)

      {:error, reason} ->
        if print_runtime_compatibility_report(
             :terminal_ui,
             reason,
             example_module,
             iur_element
           ) do
          :ok
        else
          Mix.raise("terminal_ui example launch failed: #{inspect(reason)}")
        end
    end
  end

  defp selected_target_package(opts) do
    opts
    |> Keyword.get(:target_package, Keyword.get(opts, :runtime))
    |> Kernel.||(System.get_env("UNIFIED_TARGET_PACKAGE"))
    |> Kernel.||(System.get_env("UNIFIED_RUNTIME"))
    |> Kernel.||("live_ui")
    |> parse_target_package()
  end

  defp parse_target_package(option) when is_atom(option),
    do: parse_target_package(Atom.to_string(option))

  defp parse_target_package(option) when is_binary(option) do
    option
    |> String.downcase()
    |> String.replace("-", "_")
    |> case do
      "live" <> _ ->
        :live_ui

      "desktop" <> _ ->
        :desktop_ui

      "elm" <> _ ->
        :elm_ui

      "terminal" <> _ ->
        :terminal_ui

      other ->
        Mix.raise("""
        unsupported target package: #{inspect(option)}

        Supported target packages:
          - live_ui
          - desktop_ui
          - elm_ui
          - terminal_ui

        Normalized value: #{other}
        """)
    end
  end

  defp parse_platform(nil), do: detect_platform()
  defp parse_platform("auto"), do: detect_platform()
  defp parse_platform("linux"), do: :linux
  defp parse_platform("macos"), do: :macos
  defp parse_platform("windows"), do: :windows

  defp parse_platform(other) do
    Mix.raise("unsupported desktop platform: #{inspect(other)}")
  end

  defp parse_backend_mode(nil), do: :auto
  defp parse_backend_mode("auto"), do: :auto
  defp parse_backend_mode("raw"), do: :raw
  defp parse_backend_mode("tty"), do: :tty

  defp parse_backend_mode(other) do
    Mix.raise("unsupported terminal backend mode: #{inspect(other)}")
  end

  defp detect_platform do
    case :os.type() do
      {:unix, :darwin} -> :macos
      {:unix, _other} -> :linux
      {:win32, _other} -> :windows
      other -> Mix.raise("unsupported host platform for desktop_ui: #{inspect(other)}")
    end
  end

  defp example_module do
    app =
      Mix.Project.config()
      |> Keyword.fetch!(:app)
      |> Atom.to_string()

    unless String.starts_with?(app, "unified_example_") do
      Mix.raise("""
      mix example.start can only be used from an example app directory.

      Current Mix app: #{app}
      """)
    end

    app
    |> String.trim_leading("unified_example_")
    |> Macro.camelize()
    |> then(&Module.concat([UnifiedExamples, &1]))
  end

  defp example_screen_module(example_module) do
    ensure_runtime_available!(example_module, :current_example)

    if function_exported?(example_module, :screen_module, 0) do
      example_module.screen_module()
    else
      Mix.raise("""
      #{inspect(example_module)} does not expose screen_module/0.

      `mix example.start` is intended for example applications under `examples/`.
      """)
    end
  end

  defp ensure_runtime_available!(module, subject) do
    unless Code.ensure_loaded?(module) do
      Mix.raise("""
      required module #{inspect(module)} is not available for #{inspect(subject)}

      Run `mix deps.get` in the current example directory and make sure the target
      package is included in the app dependencies.
      """)
    end
  end

  defp current_example_iur(example_module) do
    compiler_module = Module.concat([UnifiedUi, Compiler])
    screen_module = example_screen_module(example_module)

    ensure_runtime_available!(compiler_module, :compiler)
    apply(compiler_module, :iur!, [screen_module])
  end

  defp current_example_renderable_iur(example_module) do
    runtime_module = Module.concat(example_module, Runtime)
    iur_element = current_example_iur(example_module)

    ensure_runtime_available!(runtime_module, :example_runtime)

    if function_exported?(runtime_module, :renderable_element, 1) do
      apply(runtime_module, :renderable_element, [iur_element])
    else
      iur_element
    end
  end

  defp print_runtime_snapshot(title, snapshot) do
    Mix.shell().info(title)

    snapshot
    |> Kernel.inspect(pretty: true, width: 100, limit: :infinity, sort_maps: true)
    |> Mix.shell().info()
  end

  defp print_runtime_compatibility_report(target_package, reason, example_module, iur_element) do
    if compatibility_reportable_reason?(reason) do
      supported_kinds = supported_kinds_for(target_package)
      present_kinds = canonical_kinds(iur_element)

      report = %{
        mode: :compatibility_report,
        target_package: target_package,
        example_module: example_module,
        screen_module: example_screen_module(example_module),
        reason: normalize_runtime_reason(reason),
        renderable_root: canonical_element_summary(iur_element),
        present_kinds: present_kinds,
        supported_kinds: supported_kinds,
        unsupported_kinds: present_kinds -- supported_kinds,
        suggested_fallback_targets: [:live_ui, :desktop_ui]
      }

      print_runtime_snapshot("#{runtime_label(target_package)} compatibility report", report)
      true
    else
      false
    end
  end

  defp compatibility_reportable_reason?(%{reason: :unsupported_kind}), do: true

  defp compatibility_reportable_reason?(%{
         reason: :invalid_canonical_screen,
         details: %{renderer_code: :unsupported_kind}
       }),
       do: true

  defp compatibility_reportable_reason?(_reason), do: false

  defp normalize_runtime_reason(%{reason: reason, message: message} = error) do
    %{
      reason: reason,
      message: message,
      details: Map.get(error, :details, %{})
    }
  end

  defp normalize_runtime_reason(reason), do: reason

  defp supported_kinds_for(:elm_ui) do
    supported_kinds_from_module(Module.concat([ElmUi, Renderer]))
  end

  defp supported_kinds_for(:terminal_ui) do
    supported_kinds_from_module(Module.concat([TerminalUi, Renderer]))
  end

  defp supported_kinds_for(_target_package), do: []

  defp supported_kinds_from_module(module) do
    if Code.ensure_loaded?(module) and function_exported?(module, :supported_kinds, 0) do
      apply(module, :supported_kinds, [])
    else
      []
    end
  end

  defp canonical_element_summary(%{id: id, kind: kind, type: type}) do
    %{id: id, kind: kind, type: type}
  end

  defp canonical_element_summary(other), do: %{value: other}

  defp canonical_kinds(%{kind: kind, children: children}) do
    ([kind] ++
       Enum.flat_map(List.wrap(children), fn
         %{element: child} -> canonical_kinds(child)
         _other -> []
       end))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp canonical_kinds(_other), do: []

  defp runtime_label(:elm_ui), do: "ElmUi"
  defp runtime_label(:terminal_ui), do: "TerminalUi"
  defp runtime_label(target_package), do: inspect(target_package)

  defp put_target_package_env(target_package) do
    value = Atom.to_string(target_package)
    System.put_env("UNIFIED_TARGET_PACKAGE", value)
    System.put_env("UNIFIED_RUNTIME", value)
  end

  defp maybe_to_string(nil), do: nil
  defp maybe_to_string(value), do: Integer.to_string(value)
end
