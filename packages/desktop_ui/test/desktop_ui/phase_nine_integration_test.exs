defmodule DesktopUi.PhaseNineIntegrationTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "build staging distinguishes compiled-host bundles from review bundles for every target" do
    root =
      Path.join(
        System.tmp_dir!(),
        "desktop_ui_phase_nine_build_#{System.unique_integer([:positive])}"
      )

    host_source = Path.join(root, "desktop_ui_sdl3_host")
    File.mkdir_p!(root)
    File.write!(host_source, "host")

    review_capabilities = %{
      build: %{executable_present?: false, executable_path: host_source},
      libraries: %{
        sdl3_ttf: %{available?: false},
        sdl3_image: %{available?: false}
      }
    }

    compiled_capabilities = %{
      build: %{executable_present?: true, executable_path: host_source},
      libraries: %{
        sdl3_ttf: %{available?: true},
        sdl3_image: %{available?: true}
      }
    }

    for target <- [:windows, :macos, :linux] do
      review_build =
        DesktopUi.Build.build_plan(target,
          output_root: Path.join(root, "review_builds"),
          capabilities: review_capabilities
        )

      compiled_build =
        DesktopUi.Build.build_plan(target,
          output_root: Path.join(root, "compiled_builds"),
          capabilities: compiled_capabilities
        )

      assert review_build.bundle_mode == :review_bundle
      assert review_build.runtime_mode == :review_fallback_only
      refute review_build.compiled_host_included?

      assert compiled_build.bundle_mode == :compiled_host_bundle
      assert compiled_build.runtime_mode == :native_host_available
      assert compiled_build.compiled_host_included?
    end
  end

  test "packaging workflows emit deterministic artifact diagnostics and output paths" do
    root =
      Path.join(
        System.tmp_dir!(),
        "desktop_ui_phase_nine_package_#{System.unique_integer([:positive])}"
      )

    host_source = Path.join(root, "desktop_ui_sdl3_host")
    File.mkdir_p!(root)
    File.write!(host_source, "host")

    capabilities = %{
      build: %{executable_present?: true, executable_path: host_source},
      libraries: %{
        sdl3_ttf: %{available?: true},
        sdl3_image: %{available?: false}
      }
    }

    for {target, archive_suffix} <- [windows: ".zip", macos: ".zip", linux: ".tar.gz"] do
      summary =
        capture_io(fn ->
          Mix.Task.reenable("app.start")
          Mix.Task.reenable("desktop_ui.package")

          Mix.Tasks.DesktopUi.Package.run([
            "--target",
            Atom.to_string(target),
            "--dry-run"
          ])
        end)

      assert summary =~ "DesktopUi package summary"
      assert summary =~ "target: #{target}"
      assert summary =~ "archive path:"
      assert summary =~ archive_suffix

      assert {:ok, package} =
               DesktopUi.Package.package(target,
                 output_root: Path.join(root, "packages"),
                 build_output_root: Path.join(root, "builds"),
                 capabilities: capabilities
               )

      assert package.package_ready?
      assert String.contains?(package.artifact_paths.archive, Atom.to_string(target))
      assert File.exists?(package.artifact_paths.archive)
      assert File.exists?(package.artifact_paths.manifest)
      assert File.exists?(package.artifact_paths.contents)
    end
  end
end
