defmodule AshUI.Phase18InputExamplesTest do
  use ExUnit.Case, async: false

  alias AshUI.Compiler
  alias AshUI.Examples.{Contract, Phase18}
  alias AshUI.LiveView.EventHandler

  @moduletag :integration
  @moduletag :examples

  setup_all do
    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(Phase18.definitions_for(:inputs), fn definition ->
      load_example_module!(definition.directory)
    end)

    :ok
  end

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()
    :ok
  end

  describe "Section 18.3 - Input Control Example Apps" do
    test "18.3.1.4 - every input app exposes the primary control clearly and preserves the shared shell contract" do
      assert :ok = Contract.validate_theme_baseline()

      Enum.each(Phase18.definitions_for(:inputs), fn definition ->
        module = Phase18.example_module(definition.directory)
        mounted = module.mount_seeded!()
        rendered_ui = module.rendered_ui(mounted.socket.assigns)
        rendered_shell = render_example_live(module, definition.directory, rendered_ui)

        assert mounted.screen_name == Phase18.screen_name(definition.directory)
        assert mounted.socket.assigns.ash_ui_screen.route == "/"

        assert mounted.socket.assigns.ash_ui_screen.metadata["shell_id"] ==
                 "example-#{definition.directory}-shell"

        assert rendered_ui =~ expected_subject_fragment(definition.directory)
        assert rendered_shell =~ "ashui-example-shell"
        assert rendered_shell =~ definition.title
        assert rendered_shell =~ definition.story_text
      end)
    end

    test "18.3.1.3 - every input example demonstrates a meaningful write or selection flow" do
      assert_value_flow("text_input", "value", "Signal copy", "Signal copy")
      assert_value_flow("numeric_input", "value", "108", "108")
      assert_value_flow("date_input", "value", "2026-05-01", "2026-05-01")
      assert_value_flow("time_input", "value", "18:45", "18:45")
      assert_value_flow("file_input", "value", "contract.pdf", "contract.pdf")
      assert_value_flow("checkbox", "checked", false, "false")
      assert_value_flow("radio_group", "value", "enterprise", "enterprise")
      assert_value_flow("select", "value", "slate", "slate")
      assert_value_flow("pick_list", "value", "finance", "finance")
      assert_value_flow("toggle", "checked", true, "true")
    end

    test "18.3.2.4 - partial surfaces stay explicit and invalid runtime assumptions fail clearly" do
      assert_support_notice(
        "numeric_input",
        "numeric values string-backed in example state"
      )

      assert_support_notice(
        "file_input",
        "only echoes the selected filename"
      )

      assert_support_notice(
        "radio_group",
        "authored through the canonical `radio` type"
      )

      assert_support_notice(
        "pick_list",
        "narrows the runtime to one promoted selection"
      )

      assert_support_notice(
        "toggle",
        "authored through the canonical `switch` widget"
      )

      assert_clear_failure("checkbox", "checked", false)
    end
  end

  defp assert_value_flow(directory, target, value, expected_fragment) do
    module = Phase18.example_module(directory)
    mounted = module.mount_seeded!()

    assert {:noreply, changed_socket} =
             EventHandler.handle_value_change(
               %{
                 "target" => target,
                 "value" => value,
                 "element_id" => "example-#{directory}-subject",
                 "signal" => "change"
               },
               mounted.socket
             )

    assert module.rendered_ui(changed_socket.assigns) =~ expected_fragment
  end

  defp assert_support_notice(directory, expected_fragment) do
    module = Phase18.example_module(directory)
    mounted = module.mount_seeded!()

    assert module.rendered_ui(mounted.socket.assigns) =~ expected_fragment
  end

  defp assert_clear_failure(directory, target, value) do
    module = Phase18.example_module(directory)
    mounted = module.mount_seeded!()

    assert {:noreply, failed_socket} =
             EventHandler.handle_value_change(
               %{
                 "target" => target,
                 "value" => value,
                 "element_id" => "missing-#{directory}-subject",
                 "signal" => "change"
               },
               mounted.socket
             )

    assert get_in(failed_socket.assigns, [:flash, :error]) == "Update failed: :binding_not_found"
  end

  defp expected_subject_fragment("text_input"), do: "type=\"text\""
  defp expected_subject_fragment("numeric_input"), do: "type=\"number\""
  defp expected_subject_fragment("date_input"), do: "type=\"date\""
  defp expected_subject_fragment("time_input"), do: "type=\"time\""
  defp expected_subject_fragment("file_input"), do: "type=\"file\""
  defp expected_subject_fragment("checkbox"), do: "type=\"checkbox\""
  defp expected_subject_fragment("radio_group"), do: "ash-radio-group"
  defp expected_subject_fragment("select"), do: "<select"
  defp expected_subject_fragment("pick_list"), do: "ash-pick-list"
  defp expected_subject_fragment("toggle"), do: "ash-switch"

  defp render_example_live(module, directory, rendered_ui) do
    live_module = Module.concat([module, Web, ExampleLive])

    live_module.render(%{
      __changed__: %{},
      page_title: module.title(),
      example_directory: directory,
      theme_css: module.theme_css(),
      rendered_ui: rendered_ui
    })
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp load_example_module!(directory) do
    module = Phase18.example_module(directory)

    if Code.ensure_loaded?(module) do
      module
    else
      directory
      |> Phase18.project_path()
      |> Path.join("lib/ash_ui_examples/#{directory}.ex")
      |> Code.require_file()

      module
    end
  end
end
