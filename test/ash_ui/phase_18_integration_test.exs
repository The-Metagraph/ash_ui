defmodule AshUI.Phase18IntegrationTest do
  use ExUnit.Case, async: false

  alias AshUI.Compilation.IUR
  alias AshUI.Compiler
  alias AshUI.Examples.{Contract, Phase18}
  alias AshUI.LiveView.EventHandler

  @moduletag :integration
  @moduletag :examples
  @moduletag :conformance

  setup_all do
    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(Phase18.definitions(), fn definition ->
      load_example_module!(definition.directory)
    end)

    :ok
  end

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()
    :ok
  end

  describe "Section 18.4 - Phase 18 Integration Tests" do
    test "18.4.1.1 - every Phase 18 app boots as an independent Mix project and mounts its seeded screen through LiveView" do
      Enum.each(Phase18.definitions(), fn definition ->
        module = Phase18.example_module(definition.directory)
        project_path = Phase18.project_path(definition.directory)
        mounted = module.mount_seeded!()
        rendered_ui = module.rendered_ui(mounted.socket.assigns)
        rendered_shell = render_example_live(module, definition.directory, rendered_ui)

        assert File.exists?(Path.join(project_path, "mix.exs"))
        assert File.exists?(Path.join(project_path, "README.md"))
        assert File.exists?(Path.join(project_path, "config/config.exs"))

        assert File.exists?(
                 Path.join(project_path, "lib/ash_ui_examples/#{definition.directory}.ex")
               )

        assert mounted.screen_name == Phase18.screen_name(definition.directory)
        assert mounted.socket.assigns.ash_ui_screen.name == mounted.screen_name
        assert mounted.socket.assigns.ash_ui_screen.route == "/"
        assert rendered_shell =~ "ashui-example-shell"
        assert rendered_shell =~ definition.title
      end)
    end

    test "18.4.1.2 - every app persists its screen through authority and compiles from the authoritative resource graph" do
      Enum.each(Phase18.definitions(), fn definition ->
        module = Phase18.example_module(definition.directory)
        mounted = module.mount_seeded!()
        ui_storage_domain = Module.concat([module, UiStorageDomain])
        screen_resource = Module.concat([module, UiScreen])

        screens = Ash.read!(screen_resource, domain: ui_storage_domain, authorize?: false)

        assert length(screens) == 1

        screen = hd(screens)
        assert screen.name == mounted.screen_name
        assert screen.id == mounted.screen.id
        assert screen.metadata["shell_id"] == "example-#{definition.directory}-shell"
        assert get_in(screen.unified_dsl, ["screen", "module"])
        assert get_in(screen.unified_dsl, ["composition", "roots"]) != []

        assert {:ok, %IUR{} = compiled_iur} =
                 Compiler.compile(screen, use_cache: false, ui_storage: module.ui_storage())

        assert compiled_iur.type == :screen
        assert compiled_iur.children != []
        assert compiled_iur.metadata["ash_ui"]["authoring_source"]["kind"] == "resource_authority"
        assert compiled_iur.metadata["ash_ui"]["resource_authority"]["screen_module"] ==
                 get_in(screen.unified_dsl, ["screen", "module"])
      end)
    end

    test "18.4.1.3 - the shared Ash HQ shell stays visually consistent across representative content, form, and input apps" do
      assert :ok = Contract.validate_theme_baseline()

      Enum.each(
        [
          {"text", "ashui-example-copy"},
          {"form_builder", "ash-form-builder"},
          {"text_input", "ashui-example-input"}
        ],
        fn {directory, subject_fragment} ->
          module = Phase18.example_module(directory)
          definition = Phase18.definition!(directory)
          mounted = module.mount_seeded!()
          rendered_ui = module.rendered_ui(mounted.socket.assigns)
          rendered_shell = render_example_live(module, directory, rendered_ui)

          assert module.theme_css() =~ "--ashui-example-primary-gradient"
          assert module.theme_css() =~ ".ashui-example-shell"
          assert module.theme_css() =~ ".ashui-example-review-grid"
          assert rendered_shell =~ "ashui-example-shell"
          assert rendered_shell =~ "ashui-example-shell-title"
          assert rendered_shell =~ definition.title
          assert rendered_ui =~ subject_fragment
          assert rendered_ui =~ "Meaningful Interaction Story"
          assert rendered_ui =~ "Canonical Signal Preview"
        end
      )
    end

    test "18.4.1.4 - representative binding and action flows work for text, selection, and boolean controls" do
      assert_value_flow("text_input", "value", "Suite copy", "Suite copy")
      assert_value_flow("radio_group", "value", "enterprise", "enterprise")
      assert_value_flow("toggle", "checked", true, "true")

      form_builder_module = Phase18.example_module("form_builder")
      mounted = form_builder_module.mount_seeded!()

      assert {:noreply, changed_socket} =
               EventHandler.handle_value_change(
                 %{
                   "target" => "display_name",
                   "value" => "Suite submit",
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
      assert form_builder_module.rendered_ui(action_socket.assigns) =~ "Suite submit"

      runtime_state =
        Module.concat([form_builder_module, Runtime, ExampleState])
        |> Ash.read!(domain: Module.concat([form_builder_module, RuntimeDomain]), authorize?: false)
        |> Enum.find(&(&1.id == "state-form_builder"))

      assert runtime_state.submitted_value == "Suite submit"
      assert runtime_state.status == "Form submitted through form_builder"
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
