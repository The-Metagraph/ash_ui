defmodule AshUI.Phase20OverlayExamplesTest do
  use ExUnit.Case, async: false

  alias AshUI.Compiler
  alias AshUI.Examples.{Contract, Phase20}
  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration

  @moduletag :integration
  @moduletag :examples

  setup_all do
    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(Phase20.definitions_for(:overlay_layered_flows), fn definition ->
      load_example_module!(definition.directory)
    end)

    :ok
  end

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()
    :ok
  end

  describe "Section 20.1 - Overlay and Layered-Flow Example Apps" do
    test "20.1.1.4 - every overlay app mounts through the shared shell and keeps the layered subject visible" do
      assert :ok = Contract.validate_theme_baseline()

      Enum.each(Phase20.definitions_for(:overlay_layered_flows), fn definition ->
        module = Phase20.example_module(definition.directory)
        mounted = module.mount_seeded!()
        rendered_ui = module.rendered_ui(mounted.socket.assigns)
        rendered_shell = render_example_live(module, definition.directory, rendered_ui)

        assert mounted.screen_name == Phase20.screen_name(definition.directory)
        assert mounted.socket.assigns.ash_ui_screen.name == mounted.screen_name
        assert mounted.socket.assigns.ash_ui_screen.route == "/"

        assert mounted.socket.assigns.ash_ui_screen.metadata["shell_id"] ==
                 "example-#{definition.directory}-shell"

        assert rendered_ui =~ expected_subject_fragment(definition.directory)
        assert rendered_shell =~ "ashui-example-shell"
        assert rendered_shell =~ definition.title
        assert rendered_shell =~ definition.story_text

        assert File.exists?(Path.join(Phase20.project_path(definition.directory), "mix.exs"))
        assert File.exists?(Path.join(Phase20.project_path(definition.directory), "README.md"))
        assert File.exists?(Path.join(Phase20.project_path(definition.directory), "assets/css/app.css"))
      end)
    end

    test "20.1.1.4 - representative layered apps keep actions local to nested child resources and persist visible state changes" do
      assert_state_transition(
        "overlay",
        %{
          "action_id" => "action_open_overlay_button",
          "element_id" => "open-overlay-button",
          "signal" => "click"
        },
        "state-overlay",
        %{enabled: true, status: "Overlay opened from the nested trigger."},
        ["data-state=\"open\"", "Overlay opened from the nested trigger."]
      )

      assert_state_transition(
        "dialog",
        %{
          "action_id" => "action_confirm_dialog_button",
          "element_id" => "confirm-dialog-button",
          "signal" => "click"
        },
        "state-dialog",
        %{
          enabled: false,
          selected_value: "confirmed",
          status: "Dialog confirmed and dismissed from the nested action row."
        },
        ["data-state=\"closed\"", "confirmed"]
      )

      assert_state_transition(
        "alert_dialog",
        %{
          "action_id" => "action_acknowledge_alert_dialog_button",
          "element_id" => "acknowledge-alert-dialog-button",
          "signal" => "click"
        },
        "state-alert_dialog",
        %{
          enabled: false,
          selected_value: "acknowledged",
          status: "Alert acknowledged and the dialog closed through the destructive action."
        },
        ["data-state=\"closed\"", "acknowledged"]
      )

      assert_state_transition(
        "context_menu",
        %{
          "action_id" => "action_reassign_owner_button",
          "element_id" => "reassign-owner-button",
          "signal" => "click"
        },
        "state-context_menu",
        %{
          selected_value: "reassign owner",
          status: "Reassign owner selected from the nested context menu."
        },
        ["reassign owner", "Reassign owner selected from the nested context menu."]
      )

      assert_state_transition(
        "toast",
        %{
          "action_id" => "action_send_risk_toast_button",
          "element_id" => "send-risk-toast-button",
          "signal" => "click"
        },
        "state-toast",
        %{
          current_value: "Risk signal elevated. Recovery toast delivered.",
          status: "Risk toast triggered from the nested action row."
        },
        [
          "data-state=\"visible\"",
          "Risk signal elevated. Recovery toast delivered."
        ]
      )
    end
  end

  defp assert_state_transition(directory, event_params, state_id, expected_state, rendered_fragments) do
    module = Phase20.example_module(directory)
    mounted = module.mount_seeded!()

    assert {:reply, %{status: :ok}, updated_socket} =
             EventHandler.handle_action_event(event_params, mounted.socket)

    assert get_in(updated_socket.assigns, [:flash, :info]) == "Action completed successfully"

    state =
      Module.concat([module, Runtime, ExampleState])
      |> Ash.read!(domain: Module.concat([module, RuntimeDomain]), authorize?: false)
      |> Enum.find(&(&1.id == state_id))

    Enum.each(expected_state, fn {field, value} ->
      assert Map.get(state, field) == value
    end)

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

    rendered_ui = module.rendered_ui(remounted_socket.assigns)

    Enum.each(rendered_fragments, fn fragment ->
      assert rendered_ui =~ fragment
    end)
  end

  defp expected_subject_fragment("overlay"), do: "ash-overlay-surface"
  defp expected_subject_fragment("dialog"), do: "ash-dialog-surface"
  defp expected_subject_fragment("alert_dialog"), do: "ash-alert-dialog-surface"
  defp expected_subject_fragment("context_menu"), do: "ash-context-menu"
  defp expected_subject_fragment("toast"), do: "ash-toast"

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
    module = Phase20.example_module(directory)

    if Code.ensure_loaded?(module) do
      module
    else
      directory
      |> Phase20.project_path()
      |> Path.join("lib/ash_ui_examples/#{directory}.ex")
      |> Code.require_file()

      module
    end
  end
end
