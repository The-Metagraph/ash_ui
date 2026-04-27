defmodule AshUI.Phase24IntegrationTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  require Logger

  alias AshUI.LiveView.BindingRuntime
  alias AshUI.LiveView.EventHandler
  alias AshUI.Tutorials
  alias AshUI.Tutorials.Phase24

  @moduletag :integration
  @moduletag :tutorials

  setup_all do
    previous_level = Logger.level()
    Logger.configure(level: :warning)
    on_exit(fn -> Logger.configure(level: previous_level) end)

    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(Phase24.implemented_checkpoint_numbers(), fn number ->
      load_mix_project_module!(Phase24.chapter_project_path(number), Phase24.chapter_mix_project_module(number))
      load_source_module!(Phase24.chapter_source_path(number), Phase24.chapter_module(number))
    end)

    :ok
  end

  describe "Section 24.4 - Phase 24 Integration Tests" do
    test "24.4.1.1 - Chapters 3, 4, and 5 boot as independent Mix projects and preserve the shared shell contract" do
      assert :ok = Tutorials.validate_directory_contract()
      assert :ok = Phase24.validate_project_structure()

      expected_apps = %{
        3 => :ash_ui_tutorial_filtering_and_search,
        4 => :ash_ui_tutorial_operator_actions_and_forms,
        5 => :ash_ui_tutorial_safe_overlays_and_guards
      }

      Enum.each(Phase24.implemented_checkpoint_numbers(), fn number ->
        chapter = Tutorials.chapter!(number)
        code_directory = Path.basename(chapter["code_path"])
        mix_module = Phase24.chapter_mix_project_module(number)
        project = project_definition(mix_module)
        module = Phase24.chapter_module(number)

        assert project[:app] == Map.fetch!(expected_apps, number)
        assert Keyword.has_key?(project[:aliases], :"example.start")
        assert dependency_path!(project[:deps], :ash_ui) == "../../.."
        assert apply(module, :default_runtime, []) == "live_ui"
        assert apply(module, :supported_runtimes, []) == ["live_ui", "elm_ui", "desktop_ui"]

        mounted_services = apply(module, :mount_seeded!, [:services])
        mounted_incidents = apply(module, :mount_seeded!, [:incidents])

        assert mounted_services.socket.assigns.ash_ui_screen.name ==
                 apply(module, :screen_name, [:services])

        assert mounted_incidents.socket.assigns.ash_ui_screen.name ==
                 apply(module, :screen_name, [:incidents])

        assert mounted_services.socket.assigns.ash_ui_screen.metadata["tutorial_directory"] ==
                 code_directory

        assert mounted_incidents.socket.assigns.ash_ui_screen.metadata["tutorial_directory"] ==
                 code_directory
      end)
    end

    test "24.4.1.2 - filters, command navigation, and resource-backed form actions update checkpoint state predictably" do
      filtering_module = Phase24.chapter_module(3)
      filtering_mounted = filtering_module.mount_seeded!(:services)

      service_query_binding = value_binding!(filtering_mounted.socket, "service_query")

      assert {:noreply, socket} =
               EventHandler.handle_value_change(
                 %{
                   "binding_id" => binding_id(service_query_binding),
                   "target" => "service_query",
                   "value" => "search",
                   "element_id" => BindingRuntime.owner_element_id(service_query_binding),
                   "signal" => "change"
                 },
                 filtering_mounted.socket
               )

      filtering_state = state!(filtering_module)
      assert filtering_state.service_query == "search"

      assert Enum.map(filtering_state.services, fn service ->
               Map.get(service, :title) || Map.get(service, "title")
             end) == ["Search"]

      focus_incidents = action_binding!(socket, "focus_incidents")

      assert {:reply, %{status: :ok}, _socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => binding_id(focus_incidents),
                   "element_id" => BindingRuntime.owner_element_id(focus_incidents),
                   "signal" => "click"
                 },
                 socket
               )

      filtering_state = state!(filtering_module)
      assert filtering_state.selected_value == "incidents"
      assert filtering_state.incident_severity_filter == "sev-1"
      assert filtering_state.detail_status == "sev-1"

      forms_module = Phase24.chapter_module(4)
      forms_mounted = forms_module.mount_seeded!(:incidents)
      operator_note_binding = value_binding!(forms_mounted.socket, "operator_note")

      assert {:noreply, socket} =
               EventHandler.handle_value_change(
                 %{
                   "binding_id" => binding_id(operator_note_binding),
                   "target" => "operator_note",
                   "value" => "Investigated gateway rollback path",
                   "element_id" => BindingRuntime.owner_element_id(operator_note_binding),
                   "signal" => "change"
                 },
                 forms_mounted.socket
               )

      acknowledge_action = action_binding!(socket, "acknowledge_incident")

      assert {:reply, %{status: :ok}, _socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => binding_id(acknowledge_action),
                   "element_id" => BindingRuntime.owner_element_id(acknowledge_action),
                   "signal" => "click"
                 },
                 socket
               )

      forms_state = state!(forms_module)
      resolved_incident = Enum.find(forms_state.incident_catalog, &(&1.id == "inc-1042"))

      assert forms_state.form_feedback_status == "success"
      assert forms_state.detail_status == "acknowledged"
      assert resolved_incident.state == "acknowledged"
    end

    test "24.4.1.3 - guarded overlay flows reject unsafe actions clearly and surface success feedback after the precondition is met" do
      module = Phase24.chapter_module(5)
      mounted = module.mount_seeded!(:incidents)

      preview_silence = action_binding!(mounted.socket, "preview_silence_guard")

      assert {:reply, %{status: :ok}, socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => binding_id(preview_silence),
                   "element_id" => BindingRuntime.owner_element_id(preview_silence),
                   "signal" => "click"
                 },
                 mounted.socket
               )

      confirm_overlay = action_binding!(socket, "confirm_overlay_guard")

      assert {:reply, %{status: :ok}, socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => binding_id(confirm_overlay),
                   "element_id" => BindingRuntime.owner_element_id(confirm_overlay),
                   "signal" => "click"
                 },
                 socket
               )

      blocked_state = state!(module)
      assert blocked_state.toast_status == "blocked"
      assert blocked_state.toast_visible
      assert blocked_state.toast_title == "Silence blocked"
      assert blocked_state.toast_summary =~ "Turn on the escalated-only incident filter"

      escalated_binding = value_binding!(socket, "incident_escalated_only")

      assert {:noreply, socket} =
               EventHandler.handle_value_change(
                 %{
                   "binding_id" => binding_id(escalated_binding),
                   "target" => "incident_escalated_only",
                   "value" => true,
                   "element_id" => BindingRuntime.owner_element_id(escalated_binding),
                   "signal" => "change"
                 },
                 socket
               )

      preview_silence = action_binding!(socket, "preview_silence_guard")

      assert {:reply, %{status: :ok}, socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => binding_id(preview_silence),
                   "element_id" => BindingRuntime.owner_element_id(preview_silence),
                   "signal" => "click"
                 },
                 socket
               )

      confirm_overlay = action_binding!(socket, "confirm_overlay_guard")

      assert {:reply, %{status: :ok}, _socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => binding_id(confirm_overlay),
                   "element_id" => BindingRuntime.owner_element_id(confirm_overlay),
                   "signal" => "click"
                 },
                 socket
               )

      success_state = state!(module)
      assert success_state.toast_status == "success"
      assert success_state.toast_title == "Alerts silenced"
      assert success_state.toast_summary =~ "overlay accepted the silence action"
      assert success_state.status =~ "Escalated alerts silenced"
    end

    test "24.4.1.4 - Chapters 3, 4, and 5 reference the correct checkpoint directories and previous checkpoint paths in prose" do
      assert :ok = Tutorials.validate_chapter_reference_contract()
      assert :ok = Phase24.validate_implemented_chapter_artifacts()

      expected_pairs = %{
        3 => {"../code/03-filtering-and-search/", "../code/02-services-and-incidents/"},
        4 => {"../code/04-operator-actions-and-forms/", "../code/03-filtering-and-search/"},
        5 => {"../code/05-safe-overlays-and-guards/", "../code/04-operator-actions-and-forms/"}
      }

      Enum.each(expected_pairs, fn {number, {checkpoint_path, previous_path}} ->
        body =
          number
          |> Tutorials.chapter!()
          |> Map.fetch!("chapter_path")
          |> Path.expand(repo_root())
          |> File.read!()

        assert body =~ checkpoint_path
        assert body =~ previous_path
      end)
    end
  end

  defp load_mix_project_module!(project_root, module) do
    if Code.ensure_loaded?(module) do
      module
    else
      capture_io(:stderr, fn ->
        project_root
        |> Path.join("mix.exs")
        |> Code.require_file()
      end)

      module
    end
  end

  defp load_source_module!(source_path, module) do
    if Code.ensure_loaded?(module) do
      module
    else
      capture_io(:stderr, fn -> Code.require_file(source_path) end)
      module
    end
  end

  defp dependency_path!(deps, dependency_name) do
    deps
    |> Enum.find_value(fn
      {^dependency_name, options} when is_list(options) -> Keyword.get(options, :path)
      _other -> nil
    end)
  end

  defp project_definition(module) do
    apply(module, :project, [])
  end

  defp state!(module) do
    resource = Module.concat([module, Runtime, WorkspaceState])
    domain = Module.concat([module, RuntimeDomain])

    resource
    |> Ash.read!(domain: domain, authorize?: false)
    |> Enum.find(&(&1.id == "tutorial-services-incidents-state"))
  end

  defp value_binding!(socket, target) do
    socket.assigns.ash_ui_bindings
    |> Map.values()
    |> Enum.find(fn binding -> binding_target(binding) == target end)
  end

  defp action_binding!(socket, intent) do
    socket.assigns.ash_ui_action_bindings
    |> Map.values()
    |> Enum.find(fn binding ->
      binding
      |> binding_metadata()
      |> Map.get("intent", Map.get(binding_metadata(binding), :intent))
      |> Kernel.==(intent)
    end)
  end

  defp binding_id(binding) do
    Map.get(binding, :id) || Map.get(binding, "id")
  end

  defp binding_target(binding) do
    Map.get(binding, :target) || Map.get(binding, "target")
  end

  defp binding_metadata(binding) do
    Map.get(binding, :metadata) || Map.get(binding, "metadata") || %{}
  end

  defp repo_root do
    Path.expand("../..", __DIR__)
  end
end
