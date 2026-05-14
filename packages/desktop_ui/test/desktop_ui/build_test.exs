defmodule DesktopUi.BuildTest do
  use ExUnit.Case, async: true

  test "build plan reports review bundles when no compiled host is present" do
    plan =
      DesktopUi.Build.build_plan(:linux,
        capabilities: %{
          build: %{executable_present?: false, executable_path: "/tmp/desktop_ui_sdl3_host"},
          libraries: %{
            sdl3_ttf: %{available?: false},
            sdl3_image: %{available?: false}
          }
        },
        output_root: Path.join(System.tmp_dir!(), "desktop_ui_build_test_plan")
      )

    assert plan.bundle_mode == :review_bundle
    assert plan.runtime_mode == :review_fallback_only
    refute plan.compiled_host_included?
    refute plan.text_support.native_backend_ready?
    refute plan.image_support.native_backend_ready?
  end

  test "build stages manifests, launch scripts, and bundled hosts deterministically" do
    root =
      Path.join(System.tmp_dir!(), "desktop_ui_build_test_#{System.unique_integer([:positive])}")

    source = Path.join(root, "desktop_ui_sdl3_host")
    File.mkdir_p!(root)
    File.write!(source, "host")

    assert {:ok, build} =
             DesktopUi.Build.build(:linux,
               output_root: Path.join(root, "artifacts"),
               capabilities: %{
                 build: %{executable_present?: true, executable_path: source},
                 libraries: %{
                   sdl3_ttf: %{available?: true},
                   sdl3_image: %{available?: false}
                 }
               }
             )

    assert build.stage_ready?
    assert File.exists?(build.output_paths.manifest)
    assert File.exists?(build.output_paths.launch_script)
    assert File.exists?(build.output_paths.examples_manifest)
    assert File.exists?(build.output_paths.compiled_host)

    manifest = JSON.decode!(File.read!(build.output_paths.manifest))
    assert manifest["bundle_mode"] == "compiled_host_bundle"
    assert manifest["compiled_host_included?"] == true

    examples = JSON.decode!(File.read!(build.output_paths.examples_manifest))
    assert is_list(examples["native_ids"])
    assert File.read!(build.output_paths.launch_script) =~ "--version"
  end
end
