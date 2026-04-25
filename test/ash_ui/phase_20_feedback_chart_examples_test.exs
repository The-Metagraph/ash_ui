defmodule AshUI.Phase20FeedbackChartExamplesTest do
  use ExUnit.Case, async: false

  alias AshUI.Compiler
  alias AshUI.Examples.{Contract, Phase20}
  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration

  @moduletag :integration
  @moduletag :examples

  setup_all do
    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(Phase20.definitions_for(:feedback_charts), fn definition ->
      load_example_module!(definition.directory)
    end)

    :ok
  end

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()
    :ok
  end

  describe "Section 20.3 - Feedback and Chart Example Apps" do
    test "20.3.1.4 - every feedback and chart app mounts through the shared shell and keeps the primary signal surface visible" do
      assert :ok = Contract.validate_theme_baseline()

      Enum.each(Phase20.definitions_for(:feedback_charts), fn definition ->
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
      end)
    end

    test "20.3.1.4 - representative feedback and chart examples respond visibly to runtime metric changes" do
      assert_feedback_transition(
        "status",
        %{
          "action_id" => "action_load_risk_status_button",
          "element_id" => "load-risk-status-button",
          "signal" => "click"
        },
        "state-status",
        %{current_value: "risk", status: "Status surface switched to the risk signal."},
        ["model"],
        ["Risk", "Status surface switched to the risk signal."]
      )

      assert_feedback_transition(
        "progress",
        %{
          "action_id" => "action_load_full_progress_button",
          "element_id" => "load-full-progress-button",
          "signal" => "click"
        },
        "state-progress",
        %{current_value: "100%", status: "Progress surface switched to the completed rollout."},
        ["model"],
        ["100%", "Progress surface switched to the completed rollout."]
      )

      assert_feedback_transition(
        "gauge",
        %{
          "action_id" => "action_load_elevated_gauge_button",
          "element_id" => "load-elevated-gauge-button",
          "signal" => "click"
        },
        "state-gauge",
        %{
          current_value: "87%",
          status: "Gauge surface switched to the elevated capacity snapshot."
        },
        ["model"],
        ["87%", "Gauge surface switched to the elevated capacity snapshot."]
      )

      assert_feedback_transition(
        "inline_feedback",
        %{
          "action_id" => "action_load_warning_feedback_button",
          "element_id" => "load-warning-feedback-button",
          "signal" => "click"
        },
        "state-inline_feedback",
        %{current_value: "warning", status: "Inline feedback switched to the review-risk note."},
        ["model"],
        ["Review risk", "Inline feedback switched to the review-risk note."]
      )

      assert_feedback_transition(
        "sparkline",
        %{
          "action_id" => "action_load_backlog_sparkline_button",
          "element_id" => "load-backlog-sparkline-button",
          "signal" => "click"
        },
        "state-sparkline",
        %{
          current_value: "worker backlog",
          status: "Sparkline switched to the worker-backlog trend."
        },
        ["series"],
        ["worker backlog", "Sparkline switched to the worker-backlog trend."]
      )

      assert_feedback_transition(
        "bar_chart",
        %{
          "action_id" => "action_load_service_bar_chart_button",
          "element_id" => "load-service-bar-chart-button",
          "signal" => "click"
        },
        "state-bar_chart",
        %{current_value: "service mix", status: "Bar chart switched to the service-mix series."},
        ["series"],
        ["gateway", "Bar chart switched to the service-mix series."]
      )

      assert_feedback_transition(
        "line_chart",
        %{
          "action_id" => "action_load_recovery_line_chart_button",
          "element_id" => "load-recovery-line-chart-button",
          "signal" => "click"
        },
        "state-line_chart",
        %{
          current_value: "recovery trend",
          status: "Line chart switched to the recovery-trend series."
        },
        ["series"],
        ["88", "Line chart switched to the recovery-trend series."]
      )
    end
  end

  defp assert_feedback_transition(
         directory,
         event_params,
         state_id,
         expected_state,
         hydrated_keys,
         rendered_fragments
       ) do
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

    subject =
      remounted_socket.assigns.ash_ui_iur
      |> find_iur_by_id("example-#{directory}-subject")

    Enum.each(hydrated_keys, fn key ->
      assert Map.has_key?(subject["props"], key)
    end)

    rendered_ui = module.rendered_ui(remounted_socket.assigns)

    Enum.each(rendered_fragments, fn fragment ->
      assert rendered_ui =~ fragment
    end)
  end

  defp find_iur_by_id(nil, _id), do: nil

  defp find_iur_by_id(%{"id" => id} = iur, id), do: iur

  defp find_iur_by_id(%{"children" => children}, id) when is_list(children) do
    Enum.find_value(children, &find_iur_by_id(&1, id))
  end

  defp find_iur_by_id(_iur, _id), do: nil

  defp expected_subject_fragment("status"), do: "ash-status-surface"
  defp expected_subject_fragment("progress"), do: "ash-progress-surface"
  defp expected_subject_fragment("gauge"), do: "ash-gauge-surface"
  defp expected_subject_fragment("inline_feedback"), do: "ash-inline-feedback"
  defp expected_subject_fragment("sparkline"), do: "ash-sparkline-surface"
  defp expected_subject_fragment("bar_chart"), do: "ash-bar-chart"
  defp expected_subject_fragment("line_chart"), do: "ash-line-chart"

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
