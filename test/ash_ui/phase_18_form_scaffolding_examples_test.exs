defmodule AshUI.Phase18FormScaffoldingExamplesTest do
  use ExUnit.Case, async: false

  alias AshUI.Compiler
  alias AshUI.Examples.{Contract, Phase18}
  alias AshUI.LiveView.EventHandler

  @moduletag :integration
  @moduletag :examples

  setup_all do
    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(Phase18.definitions_for(:form_scaffolding), fn definition ->
      load_example_module!(definition.directory)
    end)

    :ok
  end

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()
    :ok
  end

  describe "Section 18.2 - Form Scaffolding Example Apps" do
    test "18.2.1.4 - every form-scaffold app mounts through the shared shell, theme contract, and resource-first authoring path" do
      assert :ok = Contract.validate_theme_baseline()

      Enum.each(Phase18.definitions_for(:form_scaffolding), fn definition ->
        module = Phase18.example_module(definition.directory)
        mounted = module.mount_seeded!()
        rendered_ui = module.rendered_ui(mounted.socket.assigns)
        rendered_shell = render_example_live(module, definition.directory, rendered_ui)

        assert mounted.screen_name == Phase18.screen_name(definition.directory)
        assert mounted.socket.assigns.ash_ui_screen.name == mounted.screen_name
        assert mounted.socket.assigns.ash_ui_screen.route == "/"

        assert mounted.socket.assigns.ash_ui_screen.metadata["shell_id"] ==
                 "example-#{definition.directory}-shell"

        assert rendered_ui =~ "ashui-example-panel"
        assert rendered_ui =~ expected_subject_fragment(definition.directory)
        assert rendered_shell =~ "ashui-example-shell"
        assert rendered_shell =~ definition.title
        assert rendered_shell =~ definition.story_text

        assert File.exists?(Path.join(Phase18.project_path(definition.directory), "mix.exs"))
        assert File.exists?(Path.join(Phase18.project_path(definition.directory), "README.md"))

        assert File.exists?(
                 Path.join(Phase18.project_path(definition.directory), "assets/css/app.css")
               )
      end)
    end

    test "18.2.1.3 - form-oriented examples keep bindings and actions local to the authored resources" do
      assert_input_flow("field", "display_name", "display-name-input", "Field Runtime")
      assert_input_flow("field_group", "notes", "notes-input", "Grouped Runtime")

      module = Phase18.example_module("form_builder")
      mounted = module.mount_seeded!()

      assert {:noreply, changed_socket} =
               EventHandler.handle_value_change(
                 %{
                   "target" => "display_name",
                   "value" => "Submitted Ada",
                   "element_id" => "display-name-input",
                   "signal" => "change"
                 },
                 mounted.socket
               )

      assert {:reply, %{status: :ok}, action_socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => "submit_profile",
                   "element_id" => "example-form_builder-subject",
                   "signal" => "submit"
                 },
                 changed_socket
               )

      assert get_in(action_socket.assigns, [:flash, :info]) == "Action completed successfully"
      assert module.rendered_ui(action_socket.assigns) =~ "Submitted Ada"

      runtime_state_module = Module.concat([module, Runtime, ExampleState])
      runtime_domain_module = Module.concat([module, RuntimeDomain])

      state =
        runtime_state_module
        |> Ash.read!(domain: runtime_domain_module, authorize?: false)
        |> Enum.find(&(&1.id == "state-form_builder"))

      assert state.submitted_value == "Submitted Ada"
      assert state.status == "Form submitted through form_builder"
    end
  end

  defp assert_input_flow(directory, target, element_id, value) do
    module = Phase18.example_module(directory)
    mounted = module.mount_seeded!()

    assert {:noreply, changed_socket} =
             EventHandler.handle_value_change(
               %{
                 "target" => target,
                 "value" => value,
                 "element_id" => element_id,
                 "signal" => "change"
               },
               mounted.socket
             )

    assert module.rendered_ui(changed_socket.assigns) =~ value
  end

  defp expected_subject_fragment("form_builder"), do: "<form"
  defp expected_subject_fragment("field"), do: "ash-form-field"
  defp expected_subject_fragment("field_group"), do: "ash-field-group"

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
