defmodule AshUI.Phase21LauncherWorkflowTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias AshUI.Examples.Suite

  @moduletag :examples

  describe "Section 21.2 - Independent App Run and Preview Tooling" do
    test "21.2.1.1 - the root launcher delegates to each app's maintained mix example.start workflow" do
      output =
        capture_io(fn ->
          Mix.Tasks.AshUi.Examples.Start.run(["button", "--dry-run"])
        end)

      assert output =~ "Button Example (`button`)"
      assert output =~ "Project path: #{Suite.project_path("button")}"

      assert output =~
               "Dry run: cd #{Suite.project_path("button")} && MIX_ENV=dev mix example.start"
    end

    test "21.2.1.2 - the launcher and preview workflow surface representative actor, seed, and runtime profiles" do
      output =
        capture_io(fn ->
          Mix.Tasks.AshUi.Examples.Preview.run([
            "status",
            "--actor",
            "operator",
            "--seed",
            "runtime_realism",
            "--runtime",
            "liveview"
          ])
        end)

      assert output =~ "Status Example (`status`)"
      assert output =~ "Review profile: actor=operator seed=runtime_realism runtime=live_ui"
    end

    test "21.2.1.3 - preview output foregrounds the shared shell, interaction story, and canonical signal preview" do
      output =
        capture_io(fn ->
          Mix.Tasks.AshUi.Examples.Preview.run(["dialog", "--actor", "operator"])
        end)

      assert output =~ "Shell: Ash HQ example shell"
      assert output =~ "Meaningful Interaction Story:"
      assert output =~ "Canonical Signal Preview:"
      assert output =~ "Support notice:"
    end

    test "21.2.1.4 - maintainers can discover and launch representative apps from one root workflow" do
      list_output =
        capture_io(fn ->
          Mix.Tasks.AshUi.Examples.List.run([])
        end)

      assert list_output =~ "button | content | 18 | exact | mix ash_ui.examples.start button"
      assert list_output =~ "tabs | navigation | 19 | custom | mix ash_ui.examples.start tabs"

      assert list_output =~
               "status | feedback | 20 | normalized | mix ash_ui.examples.start status"

      assert_raise ArgumentError, fn ->
        Suite.launch_spec("button", actor: "operator")
      end
    end
  end
end
