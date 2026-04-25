defmodule AshUI.Phase18FoundationalExamplesTest do
  use ExUnit.Case, async: false

  alias AshUI.Compiler
  alias AshUI.Examples.{Contract, Phase18}

  @moduletag :integration
  @moduletag :examples

  setup_all do
    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(Phase18.definitions_for(:foundational), fn definition ->
      load_example_module!(definition.directory)
    end)

    :ok
  end

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()
    :ok
  end

  describe "Section 18.1 - Foundational Content Example Apps" do
    test "18.1.1.4 - every foundational app mounts through the shared shell, theme contract, and resource-authority persistence path" do
      assert :ok = Contract.validate_theme_baseline()

      Enum.each(Phase18.definitions_for(:foundational), fn definition ->
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

    test "18.1.1.2 - icon, image, and link examples render subject-specific fallback markup" do
      assert_rendered_subject("icon", "ash-icon")
      assert_rendered_subject("image", "<img")
      assert_rendered_subject("link", "<a")
    end
  end

  defp assert_rendered_subject(directory, expected_fragment) do
    module = Phase18.example_module(directory)
    mounted = module.mount_seeded!()

    assert module.rendered_ui(mounted.socket.assigns) =~ expected_fragment
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
