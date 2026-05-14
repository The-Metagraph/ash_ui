defmodule UnifiedIUR.MixTasksTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "mix unified_iur.inspect prints tree output for a fixture" do
    Mix.Task.reenable("unified_iur.inspect")

    output =
      capture_io(fn ->
        Mix.Task.run("unified_iur.inspect", ["forms--profile_editor", "--format", "tree"])
      end)

    assert output =~ "- profile-editor [composite:form_builder]"
    assert output =~ "@actions"
  end

  test "mix unified_iur.export prints snapshot output for a fixture" do
    Mix.Task.reenable("unified_iur.export")

    output =
      capture_io(fn ->
        Mix.Task.run("unified_iur.export", ["forms--profile_editor", "--format", "snapshot"])
      end)

    assert output =~ "kind: :form_builder"
    assert output =~ "profile-editor"
  end

  test "mix unified_iur.inspect prints extension metadata without a fixture id" do
    Mix.Task.reenable("unified_iur.inspect")

    output =
      capture_io(fn ->
        Mix.Task.run("unified_iur.inspect", ["--format", "extensions"])
      end)

    assert output =~ "extension_points"
    assert output =~ "unified_ui_family_map"
  end

  test "mix unified_iur.validate prints the package validation summary" do
    Mix.Task.reenable("unified_iur.validate")

    output =
      capture_io(fn ->
        Mix.Task.run("unified_iur.validate", ["--strict"])
      end)

    assert output =~ "UnifiedIUR validation summary"
    assert output =~ "release ready?: true"
  end
end
