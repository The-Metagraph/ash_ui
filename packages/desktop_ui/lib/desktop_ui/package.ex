defmodule DesktopUi.Package do
  @moduledoc """
  Target packaging workflows for `desktop_ui`.
  """

  @manifest_name "package-manifest.json"
  @contents_name "bundle-contents.json"
  @windows_payload "desktop_ui-windows"
  @linux_payload "desktop_ui-linux"
  @macos_bundle "DesktopUi.app"

  @type target :: DesktopUi.Build.target()

  @spec contract() :: map()
  def contract do
    %{
      targets: targets(),
      output_family: :packaged_target_directory,
      package_root: package_root(),
      manifest_name: @manifest_name,
      contents_name: @contents_name,
      artifact_modes: [:archive_only, :bundle_and_archive],
      includes: [
        :package_manifest,
        :bundle_contents,
        :archive_output,
        :compiled_host_presence,
        :fallback_warnings
      ]
    }
  end

  @spec validation_state() :: atom()
  def validation_state, do: :target_packaging_surface_ready

  @spec targets() :: [target()]
  def targets, do: DesktopUi.Build.targets()

  @spec package_root(keyword()) :: String.t()
  def package_root(opts \\ []) do
    Keyword.get(
      opts,
      :output_root,
      Path.join(DesktopUi.Build.package_root(), "artifacts/packages")
    )
  end

  @spec target_package_root(target(), keyword()) :: String.t()
  def target_package_root(target, opts \\ []) when target in [:windows, :macos, :linux] do
    Path.join(package_root(opts), Atom.to_string(target))
  end

  @spec package_plan(target(), keyword()) :: map()
  def package_plan(target, opts \\ []) when target in [:windows, :macos, :linux] do
    build_plan =
      Keyword.get_lazy(opts, :build_plan, fn ->
        DesktopUi.Build.build_plan(target, build_opts(opts))
      end)

    target_root = target_package_root(target, opts)
    payload_root = payload_root(target_root, target)
    bundle_path = bundle_path(target_root, target)
    archive_path = archive_path(target_root, target)
    warnings = package_warnings(build_plan)

    %{
      target: target,
      target_root: target_root,
      payload_root: payload_root,
      bundle_path: bundle_path,
      archive_path: archive_path,
      manifest_path: Path.join(target_root, @manifest_name),
      contents_path: Path.join(target_root, @contents_name),
      packaging_workflow: DesktopUi.Artifacts.workflow(target).packaging,
      artifact_types: DesktopUi.Artifacts.artifact_types(target),
      build: build_plan,
      compiled_host_included?: build_plan.compiled_host_included?,
      fallback_review_only?: build_plan.bundle_mode == :review_bundle,
      warnings: warnings,
      validation_state: validation_state()
    }
  end

  @spec package(target(), keyword()) :: {:ok, map()} | {:error, term()}
  def package(target, opts \\ [])

  def package(target, opts) when target in [:windows, :macos, :linux] do
    with {:ok, build} <- DesktopUi.Build.build(target, build_opts(opts)) do
      plan = package_plan(target, Keyword.put(opts, :build_plan, build))

      with :ok <- remove_existing_target(plan.target_root),
           :ok <- File.mkdir_p(plan.target_root),
           :ok <- materialize_package(plan, opts),
           :ok <- File.write(plan.contents_path, JSON.encode!(bundle_contents(plan))),
           :ok <- write_package_archive(plan),
           :ok <- File.write(plan.manifest_path, JSON.encode!(package_manifest(plan))) do
        {:ok,
         Map.merge(plan, %{
           package_ready?: true,
           artifact_paths: %{
             manifest: plan.manifest_path,
             contents: plan.contents_path,
             archive: plan.archive_path,
             bundle: plan.bundle_path,
             payload: plan.payload_root
           }
         })}
      end
    end
  end

  def package(target, _opts), do: {:error, {:unsupported_target, target}}

  @spec diagnostics(keyword()) :: map()
  def diagnostics(opts \\ []) do
    target_packages =
      Enum.map(targets(), fn target ->
        plan = package_plan(target, opts)

        %{
          target: target,
          archive_path: plan.archive_path,
          bundle_path: plan.bundle_path,
          payload_root: plan.payload_root,
          compiled_host_included?: plan.compiled_host_included?,
          fallback_review_only?: plan.fallback_review_only?,
          warnings: plan.warnings
        }
      end)

    %{
      contract: contract(),
      validation_state: validation_state(),
      target_packages: target_packages,
      fallback_targets:
        target_packages
        |> Enum.filter(& &1.fallback_review_only?)
        |> Enum.map(& &1.target)
    }
  end

  @spec package_manifest(map()) :: map()
  def package_manifest(plan) do
    %{
      package: "desktop_ui",
      target: Atom.to_string(plan.target),
      packaging_workflow: plan.packaging_workflow,
      artifact_types: plan.artifact_types,
      archive_path: plan.archive_path,
      bundle_path: plan.bundle_path,
      payload_root: plan.payload_root,
      compiled_host_included?: plan.compiled_host_included?,
      fallback_review_only?: plan.fallback_review_only?,
      warnings: Enum.map(plan.warnings, &Atom.to_string/1),
      build_manifest_path: plan.build.manifest_path,
      validation_state: Atom.to_string(plan.validation_state)
    }
  end

  @spec package_summary(map()) :: map()
  def package_summary(plan) do
    %{
      target: plan.target,
      target_root: plan.target_root,
      archive_path: plan.archive_path,
      bundle_path: plan.bundle_path,
      payload_root: plan.payload_root,
      compiled_host_included?: plan.compiled_host_included?,
      fallback_review_only?: plan.fallback_review_only?,
      warnings: plan.warnings
    }
  end

  defp materialize_package(%{target: :windows} = plan, _opts) do
    copy_tree(plan.build.stage_root, plan.payload_root)
  end

  defp materialize_package(%{target: :linux} = plan, _opts) do
    copy_tree(plan.build.stage_root, plan.payload_root)
  end

  defp materialize_package(%{target: :macos} = plan, _opts) do
    macos_dir = Path.join(plan.bundle_path, "Contents/MacOS")
    resources_dir = Path.join(plan.bundle_path, "Contents/Resources")
    launcher_path = Path.join(macos_dir, "desktop_ui")

    with :ok <- File.mkdir_p(macos_dir),
         :ok <- File.mkdir_p(resources_dir),
         :ok <- copy_tree(plan.build.stage_root, Path.join(resources_dir, "staged")),
         :ok <- File.write(Path.join(plan.bundle_path, "Contents/Info.plist"), info_plist()),
         :ok <- File.write(launcher_path, macos_launcher(plan)),
         :ok <- File.chmod(launcher_path, 0o755) do
      :ok
    end
  end

  defp materialize_package(_plan, _opts), do: :ok

  defp bundle_contents(plan) do
    root =
      cond do
        is_binary(plan.bundle_path) -> plan.bundle_path
        is_binary(plan.payload_root) -> plan.payload_root
        true -> plan.target_root
      end

    %{
      package: "desktop_ui",
      target: Atom.to_string(plan.target),
      root: root,
      archive_path: plan.archive_path,
      compiled_host_included?: plan.compiled_host_included?,
      fallback_review_only?: plan.fallback_review_only?,
      warnings: Enum.map(plan.warnings, &Atom.to_string/1),
      files: relative_files(plan.target_root, root)
    }
  end

  defp payload_root(target_root, :windows), do: Path.join(target_root, @windows_payload)
  defp payload_root(target_root, :linux), do: Path.join(target_root, @linux_payload)
  defp payload_root(_target_root, :macos), do: nil

  defp bundle_path(target_root, :macos), do: Path.join(target_root, @macos_bundle)
  defp bundle_path(_target_root, _target), do: nil

  defp archive_path(target_root, :windows), do: Path.join(target_root, "desktop_ui-windows.zip")
  defp archive_path(target_root, :macos), do: Path.join(target_root, "desktop_ui-macos.zip")
  defp archive_path(target_root, :linux), do: Path.join(target_root, "desktop_ui-linux.tar.gz")

  defp write_package_archive(%{target: :linux} = plan) do
    files = archive_relative_files(plan)

    with_target_root(plan.target_root, fn ->
      :erl_tar.create(
        String.to_charlist(plan.archive_path),
        Enum.map(files, &String.to_charlist/1),
        [:compressed]
      )
    end)
    |> normalize_archive_result()
  end

  defp write_package_archive(plan) do
    files = archive_relative_files(plan)

    with_target_root(plan.target_root, fn ->
      :zip.create(
        String.to_charlist(plan.archive_path),
        Enum.map(files, &String.to_charlist/1),
        []
      )
    end)
    |> normalize_archive_result()
  end

  defp archive_relative_files(%{bundle_path: bundle_path, target_root: target_root})
       when is_binary(bundle_path) do
    relative_files(target_root, bundle_path)
  end

  defp archive_relative_files(%{payload_root: payload_root, target_root: target_root})
       when is_binary(payload_root) do
    relative_files(target_root, payload_root)
  end

  defp normalize_archive_result(:ok), do: :ok
  defp normalize_archive_result({:ok, _path}), do: :ok
  defp normalize_archive_result(other), do: other

  defp relative_files(root, subtree) do
    subtree
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.filter(&File.regular?/1)
    |> Enum.map(&Path.relative_to(&1, root))
    |> Enum.sort()
  end

  defp copy_tree(source, destination) do
    with :ok <- File.mkdir_p(Path.dirname(destination)),
         {:ok, _paths} <- File.cp_r(source, destination) do
      :ok
    end
  end

  defp remove_existing_target(path) do
    case File.rm_rf(path) do
      {:ok, _removed} -> :ok
      other -> other
    end
  end

  defp with_target_root(target_root, fun) do
    File.cd!(target_root, fun)
  end

  defp info_plist do
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
     "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>CFBundleExecutable</key>
        <string>desktop_ui</string>
        <key>CFBundleIdentifier</key>
        <string>dev.unified.desktop_ui</string>
        <key>CFBundleName</key>
        <string>DesktopUi</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
      </dict>
    </plist>
    """
  end

  defp macos_launcher(%{compiled_host_included?: true} = plan) do
    host_name = Path.basename(plan.build.compiled_host_destination)

    """
    #!/usr/bin/env sh
    SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
    "$SCRIPT_DIR/../Resources/staged/bin/#{host_name}" --version
    """
  end

  defp macos_launcher(_plan) do
    """
    #!/usr/bin/env sh
    echo "desktop_ui review bundle only"
    echo "no compiled SDL3 host was bundled in this packaged app"
    """
  end

  defp package_warnings(build_plan) do
    []
    |> maybe_add_warning(not build_plan.compiled_host_included?, :compiled_host_missing)
    |> maybe_add_warning(build_plan.bundle_mode == :review_bundle, :review_bundle_only)
    |> maybe_add_warning(
      not build_plan.text_support.native_backend_ready?,
      :text_native_backend_unavailable
    )
    |> maybe_add_warning(
      not build_plan.image_support.native_backend_ready?,
      :image_native_backend_unavailable
    )
  end

  defp maybe_add_warning(warnings, true, warning), do: warnings ++ [warning]
  defp maybe_add_warning(warnings, false, _warning), do: warnings

  defp build_opts(opts) do
    []
    |> maybe_put_opt(:capabilities, opts)
    |> maybe_put_output_root(opts)
    |> maybe_put_opt(:copy_file, opts)
    |> maybe_put_opt(:file_exists?, opts)
  end

  defp maybe_put_opt(opts, key, source_opts) do
    case Keyword.fetch(source_opts, key) do
      {:ok, value} -> Keyword.put(opts, key, value)
      :error -> opts
    end
  end

  defp maybe_put_output_root(opts, source_opts) do
    case Keyword.fetch(source_opts, :build_output_root) do
      {:ok, value} -> Keyword.put(opts, :output_root, value)
      :error -> opts
    end
  end
end
