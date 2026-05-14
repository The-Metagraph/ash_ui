defmodule DesktopUi.Build do
  @moduledoc """
  Target build staging workflows for `desktop_ui`.
  """

  alias DesktopUi.Sdl3.Capabilities

  @manifest_name "build-manifest.json"
  @launch_windows "launch_desktop_ui.bat"
  @launch_posix "launch_desktop_ui.sh"

  @type target :: :windows | :macos | :linux

  @spec contract() :: map()
  def contract do
    %{
      targets: targets(),
      output_family: :staged_target_directory,
      stage_root: stage_root(),
      manifest_name: @manifest_name,
      bundle_modes: [:compiled_host_bundle, :review_bundle],
      includes: [
        :build_manifest,
        :launch_instructions,
        :examples_catalog,
        :compiled_host_optional
      ]
    }
  end

  @spec validation_state() :: atom()
  def validation_state, do: :target_build_surface_ready

  @spec targets() :: [target()]
  def targets, do: DesktopUi.Artifacts.target_platforms()

  @spec package_root() :: String.t()
  def package_root do
    Path.expand("../..", __DIR__)
  end

  @spec stage_root(keyword()) :: String.t()
  def stage_root(opts \\ []) do
    Keyword.get(opts, :output_root, Path.join(package_root(), "artifacts/builds"))
  end

  @spec target_stage_root(target(), keyword()) :: String.t()
  def target_stage_root(target, opts \\ []) when target in [:windows, :macos, :linux] do
    Path.join(stage_root(opts), Atom.to_string(target))
  end

  @spec build_plan(target(), keyword()) :: map()
  def build_plan(target, opts \\ []) when target in [:windows, :macos, :linux] do
    capabilities = Keyword.get(opts, :capabilities, Capabilities.detect())
    target_root = target_stage_root(target, opts)
    compiled_host_path = capabilities.build.executable_path

    compiled_host_included? =
      capabilities.build.executable_present? && file_exists?(compiled_host_path, opts)

    bundle_mode = if(compiled_host_included?, do: :compiled_host_bundle, else: :review_bundle)

    %{
      target: target,
      stage_root: target_root,
      manifest_path: Path.join(target_root, @manifest_name),
      runtime_mode:
        if(compiled_host_included?, do: :native_host_available, else: :review_fallback_only),
      bundle_mode: bundle_mode,
      compiled_host_included?: compiled_host_included?,
      compiled_host_source: compiled_host_path,
      compiled_host_destination:
        if(compiled_host_included?,
          do: Path.join([target_root, "bin", Path.basename(compiled_host_path)])
        ),
      launch_script_path: Path.join([target_root, "bin", launch_script_name(target)]),
      examples_manifest_path: Path.join([target_root, "share", "examples.json"]),
      capabilities: capabilities,
      text_support: DesktopUi.Sdl3.Text.native_support(capabilities),
      image_support: DesktopUi.Sdl3.Images.native_support(capabilities),
      artifact_workflow: DesktopUi.Artifacts.workflow(target),
      validation_state: validation_state()
    }
  end

  @spec build(target(), keyword()) :: {:ok, map()} | {:error, term()}
  def build(target, opts \\ [])

  def build(target, opts) when target in [:windows, :macos, :linux] do
    plan = build_plan(target, opts)

    with :ok <- File.mkdir_p(Path.join(plan.stage_root, "bin")),
         :ok <- File.mkdir_p(Path.join(plan.stage_root, "share")),
         :ok <- maybe_copy_compiled_host(plan, opts),
         :ok <- File.write(plan.launch_script_path, launch_script(plan)),
         :ok <- maybe_mark_launch_script_executable(plan.launch_script_path, target),
         :ok <- File.write(plan.examples_manifest_path, JSON.encode!(examples_manifest())),
         :ok <- File.write(plan.manifest_path, JSON.encode!(build_manifest(plan))) do
      {:ok,
       Map.merge(plan, %{
         stage_ready?: true,
         output_paths: %{
           manifest: plan.manifest_path,
           launch_script: plan.launch_script_path,
           examples_manifest: plan.examples_manifest_path,
           compiled_host: plan.compiled_host_destination
         }
       })}
    end
  end

  def build(target, _opts), do: {:error, {:unsupported_target, target}}

  @spec build_manifest(map()) :: map()
  def build_manifest(plan) do
    %{
      package: "desktop_ui",
      target: Atom.to_string(plan.target),
      bundle_mode: Atom.to_string(plan.bundle_mode),
      runtime_mode: Atom.to_string(plan.runtime_mode),
      compiled_host_included?: plan.compiled_host_included?,
      compiled_host_source: plan.compiled_host_source,
      compiled_host_destination: plan.compiled_host_destination,
      artifact_workflow: plan.artifact_workflow,
      resource_support: %{
        text: plan.text_support,
        images: plan.image_support
      },
      validation_state: Atom.to_string(plan.validation_state)
    }
  end

  @spec build_summary(map()) :: map()
  def build_summary(plan) do
    %{
      target: plan.target,
      stage_root: plan.stage_root,
      bundle_mode: plan.bundle_mode,
      runtime_mode: plan.runtime_mode,
      compiled_host_included?: plan.compiled_host_included?,
      text_native_backend_ready?: plan.text_support.native_backend_ready?,
      image_native_backend_ready?: plan.image_support.native_backend_ready?
    }
  end

  defp examples_manifest do
    %{
      native_ids: DesktopUi.Examples.native_ids(),
      canonical_ids: DesktopUi.Examples.canonical_ids(),
      comparison_ids: DesktopUi.Examples.comparison_ids()
    }
  end

  defp launch_script(%{target: :windows, bundle_mode: :compiled_host_bundle} = plan) do
    [
      "@echo off",
      "set SCRIPT_DIR=%~dp0",
      "\"%SCRIPT_DIR%\\#{Path.basename(plan.compiled_host_destination)}\" --version"
    ]
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp launch_script(%{target: :windows}) do
    [
      "@echo off",
      "echo desktop_ui review bundle only",
      "echo no compiled SDL3 host was bundled in this staged build"
    ]
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp launch_script(%{bundle_mode: :compiled_host_bundle} = plan) do
    """
    #!/usr/bin/env sh
    SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
    "$SCRIPT_DIR/#{Path.basename(plan.compiled_host_destination)}" --version
    """
  end

  defp launch_script(_plan) do
    """
    #!/usr/bin/env sh
    echo "desktop_ui review bundle only"
    echo "no compiled SDL3 host was bundled in this staged build"
    """
  end

  defp maybe_copy_compiled_host(%{compiled_host_included?: true} = plan, opts) do
    copier = Keyword.get(opts, :copy_file, &File.cp/2)
    copier.(plan.compiled_host_source, plan.compiled_host_destination)
  end

  defp maybe_copy_compiled_host(_plan, _opts), do: :ok

  defp maybe_mark_launch_script_executable(_path, :windows), do: :ok

  defp maybe_mark_launch_script_executable(path, _target) do
    File.chmod(path, 0o755)
  end

  defp launch_script_name(:windows), do: @launch_windows
  defp launch_script_name(_target), do: @launch_posix

  defp file_exists?(nil, _opts), do: false

  defp file_exists?(path, opts) do
    checker = Keyword.get(opts, :file_exists?, &File.exists?/1)
    checker.(path)
  end
end
