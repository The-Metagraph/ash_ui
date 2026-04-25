defmodule AshUI.Phase19DisplaySystemExamplesTest do
  use ExUnit.Case, async: false

  alias AshUI.Compiler
  alias AshUI.Examples.{Contract, Phase19}
  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration

  @moduletag :integration
  @moduletag :examples

  setup_all do
    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(Phase19.definitions_for(:display_systems), fn definition ->
      load_example_module!(definition.directory)
    end)

    :ok
  end

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()
    :ok
  end

  describe "Section 19.3 - Display-System Example Apps" do
    test "19.3.1.4 - every display-system app mounts through the shared shell and keeps the primary surface visible" do
      assert :ok = Contract.validate_theme_baseline()

      Enum.each(Phase19.definitions_for(:display_systems), fn definition ->
        module = Phase19.example_module(definition.directory)
        mounted = module.mount_seeded!()
        rendered_ui = module.rendered_ui(mounted.socket.assigns)
        rendered_shell = render_example_live(module, definition.directory, rendered_ui)

        assert mounted.screen_name == Phase19.screen_name(definition.directory)
        assert mounted.socket.assigns.ash_ui_screen.name == mounted.screen_name
        assert mounted.socket.assigns.ash_ui_screen.route == "/"

        assert mounted.socket.assigns.ash_ui_screen.metadata["shell_id"] ==
                 "example-#{definition.directory}-shell"

        assert rendered_ui =~ expected_subject_fragment(definition.directory)
        assert rendered_ui =~ expected_surface_fragment(definition.directory)
        assert rendered_shell =~ "ashui-example-shell"
        assert rendered_shell =~ definition.title
        assert rendered_shell =~ definition.story_text

        assert File.exists?(Path.join(Phase19.project_path(definition.directory), "mix.exs"))
        assert File.exists?(Path.join(Phase19.project_path(definition.directory), "README.md"))
      end)
    end

    test "19.3.1.4 - representative display apps preserve declared slot composition in the compiled tree" do
      assert_slot_order("viewport", "body", ["viewport-focus-copy", "viewport-support-panel"])
      assert_slot_order("viewport", "aside", viewport_aside_ids())
      assert_slot_order("viewport", "footer", ["viewport-status"])

      assert_slot_order(
        "scroll_bar",
        "body",
        [
          "scroll-focus-copy",
          "queue-scroll-button",
          "escalations-scroll-button",
          "handoff-scroll-button"
        ]
      )

      assert_slot_order("scroll_bar", "footer", ["scroll-status"])
      assert_slot_order("split_pane", "primary", ["primary-review-panel"])
      assert_slot_order("split_pane", "secondary", ["secondary-focus-copy", "split-status"])
      assert_slot_order("split_pane", "actions", ["details-pane-button", "handoff-pane-button"])
      assert_slot_order("canvas", "toolbar", ["incident-map-button", "handoff-path-button"])
      assert_slot_order("canvas", "body", ["canvas-active-layer", "canvas-board-copy"])
      assert_slot_order("canvas", "legend", ["canvas-status"])
    end

    test "19.3.1.3 - display-system examples keep primary interactions local to nested child resources" do
      assert_nested_interaction(
        "viewport",
        %{
          "action_id" => "focus_timeline_lane",
          "element_id" => "timeline-viewport-button",
          "signal" => "click"
        },
        "state-viewport",
        "timeline lane",
        "Timeline lane focused in the viewport."
      )

      assert_nested_interaction(
        "scroll_bar",
        %{
          "action_id" => "focus_escalations_thumb",
          "element_id" => "escalations-scroll-button",
          "signal" => "click"
        },
        "state-scroll_bar",
        "escalations lane",
        "Escalations lane aligned with the scroll thumb."
      )

      assert_nested_interaction(
        "split_pane",
        %{
          "action_id" => "select_handoff_pane",
          "element_id" => "handoff-pane-button",
          "signal" => "click"
        },
        "state-split_pane",
        "handoff pane",
        "Handoff pane moved into focus."
      )

      assert_nested_interaction(
        "canvas",
        %{
          "action_id" => "select_handoff_path_layer",
          "element_id" => "handoff-path-button",
          "signal" => "click"
        },
        "state-canvas",
        "handoff path",
        "Handoff path layer selected on the canvas."
      )
    end
  end

  defp assert_nested_interaction(
         directory,
         event_params,
         state_id,
         expected_value,
         expected_status
       ) do
    module = Phase19.example_module(directory)
    mounted = module.mount_seeded!()

    assert {:reply, %{status: :ok}, updated_socket} =
             EventHandler.handle_action_event(event_params, mounted.socket)

    assert get_in(updated_socket.assigns, [:flash, :info]) == "Action completed successfully"

    state =
      Module.concat([module, Runtime, ExampleState])
      |> Ash.read!(domain: Module.concat([module, RuntimeDomain]), authorize?: false)
      |> Enum.find(&(&1.id == state_id))

    assert state.selected_value == expected_value
    assert state.status == expected_status

    remounted_socket =
      module.build_socket(%{
        current_user: mounted.actor,
        ash_ui_storage: module.ui_storage(),
        ash_ui_domains: module.runtime_domains()
      })
      |> then(fn socket ->
        {:ok, socket} = Integration.mount_ui_screen(socket, mounted.screen_name, %{})
        {:ok, socket} = EventHandler.wire_handlers(socket)
        socket
      end)

    assert module.rendered_ui(remounted_socket.assigns) =~ expected_value
  end

  defp assert_slot_order(directory, slot, expected_ids) do
    module = Phase19.example_module(directory)
    mounted = module.mount_seeded!()

    subject =
      mounted.socket.assigns.ash_ui_iur
      |> find_iur_by_id("example-#{directory}-subject")

    child_ids =
      subject["children"]
      |> Enum.filter(&(get_in(&1, ["metadata", "slot"]) == slot))
      |> Enum.map(& &1["id"])

    assert child_ids == expected_ids
  end

  defp find_iur_by_id(nil, _id), do: nil

  defp find_iur_by_id(%{"id" => id} = iur, id), do: iur

  defp find_iur_by_id(%{"children" => children}, id) when is_list(children) do
    Enum.find_value(children, &find_iur_by_id(&1, id))
  end

  defp find_iur_by_id(_iur, _id), do: nil

  defp expected_subject_fragment("viewport"), do: "ash-viewport"
  defp expected_subject_fragment("scroll_bar"), do: "ash-scroll-bar"
  defp expected_subject_fragment("split_pane"), do: "ash-split-pane"
  defp expected_subject_fragment("canvas"), do: "ash-canvas-surface"

  defp expected_surface_fragment("viewport"), do: "ash-viewport-frame"
  defp expected_surface_fragment("scroll_bar"), do: "ash-scroll-bar-track"
  defp expected_surface_fragment("split_pane"), do: "ash-split-pane-layout"
  defp expected_surface_fragment("canvas"), do: "ash-canvas-toolbar"

  defp viewport_aside_ids do
    ["queue-viewport-button", "timeline-viewport-button", "handoff-viewport-button"]
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
