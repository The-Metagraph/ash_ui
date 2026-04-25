defmodule AshUI.Phase19IntegrationTest do
  use ExUnit.Case, async: false

  alias AshUI.Compiler
  alias AshUI.Examples.{Contract, Phase19}

  @moduletag :integration
  @moduletag :examples
  @moduletag :conformance

  setup_all do
    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(Phase19.definitions(), fn definition ->
      load_example_module!(definition.directory)
    end)

    :ok
  end

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()
    :ok
  end

  describe "Section 19.5 - Phase 19 Integration Tests" do
    test "19.5.1.1 - representative apps from each family boot independently and mount seeded screens through LiveView" do
      Enum.each(Phase19.definitions(), fn definition ->
        module = Phase19.example_module(definition.directory)
        project_path = Phase19.project_path(definition.directory)
        mounted = module.mount_seeded!()
        rendered_ui = module.rendered_ui(mounted.socket.assigns)
        rendered_shell = render_example_live(module, definition.directory, rendered_ui)

        assert File.exists?(Path.join(project_path, "mix.exs"))
        assert File.exists?(Path.join(project_path, "README.md"))
        assert File.exists?(Path.join(project_path, "config/config.exs"))
        assert File.exists?(Path.join(project_path, "assets/css/app.css"))

        assert mounted.screen_name == Phase19.screen_name(definition.directory)
        assert mounted.socket.assigns.ash_ui_screen.name == mounted.screen_name
        assert mounted.socket.assigns.ash_ui_screen.route == "/"

        assert mounted.socket.assigns.ash_ui_screen.metadata["shell_id"] ==
                 "example-#{definition.directory}-shell"

        assert rendered_shell =~ "ashui-example-shell"
        assert rendered_shell =~ definition.title
      end)
    end

    test "19.5.1.2 - maintained and custom subject surfaces validate and render through the intended path" do
      Enum.each(
        [
          {"row", "row", "ash-row"},
          {"grid", "grid", "ash-grid"},
          {"menu", "custom:menu", "ash-menu"},
          {"command_palette", "custom:command_palette", "ash-command-palette"},
          {"viewport", "custom:viewport", "ash-viewport"},
          {"canvas", "custom:canvas", "ash-canvas-surface"}
        ],
        fn {directory, expected_type, expected_fragment} ->
          module = Phase19.example_module(directory)
          mounted = module.mount_seeded!()

          subject =
            mounted.socket.assigns.ash_ui_iur
            |> find_iur_by_id("example-#{directory}-subject")

          assert subject["type"] == expected_type
          assert module.rendered_ui(mounted.socket.assigns) =~ expected_fragment
        end
      )
    end

    test "19.5.1.3 - relationship-driven composition remains visible in canonical output for representative apps" do
      Enum.each(
        [
          {"row", ["primary-lane", "inspector-lane", "action-lane"]},
          {"menu", ["overview-button", "monitoring-button", "handoff-button", "menu-summary"]},
          {"viewport",
           ["viewport-focus-copy", "timeline-viewport-button", "handoff-viewport-button"]},
          {"split_pane", ["primary-review-panel", "secondary-focus-copy", "handoff-pane-button"]}
        ],
        fn {directory, expected_ids} ->
          module = Phase19.example_module(directory)
          mounted = module.mount_seeded!()
          screen = mounted.screen
          unified_dsl = screen.unified_dsl

          assert get_in(unified_dsl, ["screen", "inline_fragment"]) == nil

          element_ids =
            unified_dsl
            |> get_in(["elements"])
            |> Enum.map(fn element ->
              get_in(element, ["dsl", "metadata", "id"]) || element["id"]
            end)

          Enum.each(expected_ids, fn expected_id ->
            assert expected_id in element_ids
          end)

          subject =
            mounted.socket.assigns.ash_ui_iur
            |> find_iur_by_id("example-#{directory}-subject")

          assert length(subject["children"]) >= 3
        end
      )
    end

    test "19.5.1.4 - the Ash HQ shell stays intact around high-structure examples without obscuring their primary subject" do
      assert :ok = Contract.validate_theme_baseline()

      Enum.each(
        [
          {"grid", "ash-grid"},
          {"command_palette", "ash-command-palette"},
          {"scroll_bar", "ash-scroll-bar"},
          {"canvas", "ash-canvas-surface"}
        ],
        fn {directory, subject_fragment} ->
          module = Phase19.example_module(directory)
          definition = Phase19.definition!(directory)
          mounted = module.mount_seeded!()
          rendered_ui = module.rendered_ui(mounted.socket.assigns)
          rendered_shell = render_example_live(module, directory, rendered_ui)

          assert module.theme_css() =~ "--ashui-example-primary-gradient"
          assert module.theme_css() =~ ".ashui-example-shell"
          assert module.theme_css() =~ ".ashui-example-review-grid"
          assert rendered_shell =~ "ashui-example-shell"
          assert rendered_shell =~ "ashui-example-shell-title"
          assert rendered_shell =~ definition.title
          assert rendered_shell =~ definition.story_text
          assert rendered_ui =~ subject_fragment
        end
      )
    end
  end

  defp find_iur_by_id(nil, _id), do: nil

  defp find_iur_by_id(%{"id" => id} = iur, id), do: iur

  defp find_iur_by_id(%{"children" => children}, id) when is_list(children) do
    Enum.find_value(children, &find_iur_by_id(&1, id))
  end

  defp find_iur_by_id(_iur, _id), do: nil

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
    module = Phase19.example_module(directory)

    if Code.ensure_loaded?(module) do
      module
    else
      directory
      |> Phase19.project_path()
      |> Path.join("lib/ash_ui_examples/#{directory}.ex")
      |> Code.require_file()

      module
    end
  end
end
