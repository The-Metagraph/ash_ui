defmodule DesktopUi.PackageTest do
  use ExUnit.Case, async: true

  test "package plans surface archive targets and fallback warnings for every platform" do
    root =
      Path.join(
        System.tmp_dir!(),
        "desktop_ui_package_plan_#{System.unique_integer([:positive])}"
      )

    plans =
      for target <- [:windows, :macos, :linux] do
        DesktopUi.Package.package_plan(target,
          output_root: Path.join(root, "packages"),
          build_output_root: Path.join(root, "builds"),
          capabilities: %{
            build: %{
              executable_present?: false,
              executable_path: Path.join(root, "desktop_ui_sdl3_host")
            },
            libraries: %{
              sdl3_ttf: %{available?: false},
              sdl3_image: %{available?: false}
            }
          }
        )
      end

    assert Enum.all?(plans, &String.contains?(&1.archive_path, Atom.to_string(&1.target)))
    assert Enum.all?(plans, & &1.fallback_review_only?)
    assert Enum.all?(plans, &(:compiled_host_missing in &1.warnings))

    assert Enum.any?(
             plans,
             &(is_binary(&1.bundle_path) and String.ends_with?(&1.bundle_path, ".app"))
           )
  end

  test "packaging emits deterministic manifests and packaged artifacts for each target" do
    root =
      Path.join(
        System.tmp_dir!(),
        "desktop_ui_package_test_#{System.unique_integer([:positive])}"
      )

    source = Path.join(root, "desktop_ui_sdl3_host")
    File.mkdir_p!(root)
    File.write!(source, "host")

    capabilities = %{
      build: %{executable_present?: true, executable_path: source},
      libraries: %{
        sdl3_ttf: %{available?: true},
        sdl3_image: %{available?: false}
      }
    }

    for target <- [:windows, :macos, :linux] do
      assert {:ok, package} =
               DesktopUi.Package.package(target,
                 output_root: Path.join(root, "packages"),
                 build_output_root: Path.join(root, "builds"),
                 capabilities: capabilities
               )

      assert package.package_ready?
      assert File.exists?(package.artifact_paths.manifest)
      assert File.exists?(package.artifact_paths.contents)
      assert File.exists?(package.artifact_paths.archive)

      manifest = JSON.decode!(File.read!(package.artifact_paths.manifest))
      assert manifest["compiled_host_included?"] == true
      assert manifest["fallback_review_only?"] == false

      contents = JSON.decode!(File.read!(package.artifact_paths.contents))
      assert is_list(contents["files"])
      assert contents["files"] != []

      case target do
        :macos ->
          assert is_binary(package.artifact_paths.bundle)
          assert File.dir?(package.artifact_paths.bundle)

        _other ->
          assert is_binary(package.artifact_paths.payload)
          assert File.dir?(package.artifact_paths.payload)
      end
    end
  end
end
