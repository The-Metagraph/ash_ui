defmodule AshUI.Phase27IntegrationTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  require Logger

  alias AshUI.LiveView.Integration
  alias AshUI.LiveView.BindingRuntime
  alias AshUI.LiveView.EventHandler
  alias AshUI.Tutorials
  alias AshUI.Tutorials.Phase27

  @moduletag :integration
  @moduletag :tutorials

  setup_all do
    previous_level = Logger.level()
    Logger.configure(level: :warning)
    on_exit(fn -> Logger.configure(level: previous_level) end)

    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(Phase27.implemented_checkpoint_numbers(), fn number ->
      load_mix_project_module!(Phase27.chapter_project_path(number), Phase27.chapter_mix_project_module(number))
      load_source_module!(Phase27.chapter_source_path(number), Phase27.chapter_module(number))
    end)

    :ok
  end

  describe "Section 27.3 - Phase 27 Integration Tests" do
    test "27.3.1.1 - Chapters 10 and 11 boot as independent Mix projects and preserve the shared shell contract" do
      assert :ok = Tutorials.validate_directory_contract()
      assert :ok = Phase27.validate_project_structure()

      expected_apps = %{
        10 => :ash_ui_tutorial_runtime_introspection,
        11 => :ash_ui_tutorial_roles_and_policies
      }

      Enum.each(Phase27.implemented_checkpoint_numbers(), fn number ->
        chapter = Tutorials.chapter!(number)
        code_directory = Path.basename(chapter["code_path"])
        mix_module = Phase27.chapter_mix_project_module(number)
        project = project_definition(mix_module)
        module = Phase27.chapter_module(number)

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

      roles_module = Phase27.chapter_module(11)

      assert apply(roles_module, :page_path, ["incidents", apply(roles_module, :actor_profile_value, ["viewer"]), "elm_ui"]) ==
               "/incidents?actor=viewer-ren&runtime=elm_ui"
    end

    test "27.3.1.2 - runtime introspection stays resource-authored and the runtime lanes remain traceable to seeded operational stories" do
      assert :ok = Phase27.validate_authoritative_resource_sources()

      module = Phase27.chapter_module(10)
      mounted = module.mount_seeded!(:services)

      service_screen =
        persisted_screens(module)
        |> Enum.find(&(&1.name == apply(module, :screen_name, [:services])))

      modules = composition_modules(service_screen.unified_dsl)

      assert Enum.all?(persisted_screens(module), &authoritative_screen_graph?/1)
      assert "Elixir.AshUITutorials.RuntimeIntrospection.Examples.RuntimeReviewPanelElement" in modules
      assert "Elixir.AshUITutorials.RuntimeIntrospection.Examples.RuntimeCommandPaletteElement" in modules
      assert "Elixir.AshUITutorials.RuntimeIntrospection.Examples.RuntimeSupervisionTreeViewerElement" in modules
      assert "Elixir.AshUITutorials.RuntimeIntrospection.Examples.RuntimeProcessTableElement" in modules

      initial_state = state!(module)
      assert initial_state.runtime_focus == "gateway supervisor"
      assert initial_state.runtime_support_title == "Gateway supervisor lane"
      assert initial_state.runtime_command_summary =~ "all runtime rows"

      search_binding = action_binding_by_message!(mounted.socket, "Search runtime view loaded")

      assert {:reply, %{status: :ok}, socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => binding_id(search_binding),
                   "element_id" => BindingRuntime.owner_element_id(search_binding),
                   "signal" => "click"
                 },
                 mounted.socket
               )

      search_state = state!(module)
      assert search_state.runtime_focus == "search replica supervision"
      assert search_state.detail_title == "Search recovery lane"
      assert search_state.runtime_support_notice =~ "captured review packet"
      assert search_state.runtime_command_summary =~ "2 process rows remain visible"

      assert Enum.map(search_state.runtime_process_rows, &Map.fetch!(&1, "component")) ==
               ["backlog_shard_a", "backlog_shard_b"]

      recovery_binding = action_binding_by_message!(socket, "Recovery runtime view loaded")

      assert {:reply, %{status: :ok}, _socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => binding_id(recovery_binding),
                   "element_id" => BindingRuntime.owner_element_id(recovery_binding),
                   "signal" => "click"
                 },
                 socket
               )

      recovery_state = state!(module)
      assert recovery_state.runtime_focus == "rollback coordination"
      assert recovery_state.detail_title == "Rollback coordination lane"
      assert recovery_state.runtime_command_summary =~ "2 process rows remain visible"

      assert Enum.map(recovery_state.runtime_process_rows, &Map.fetch!(&1, "component")) ==
               ["notify_commander", "notify_platform_manager"]
    end

    test "27.3.1.3 - role-aware screens and actions differ by actor and viewer writes fail with policy errors" do
      module = Phase27.chapter_module(11)
      module.seed!()

      admin = apply(module, :actor_profile_value, ["admin"])
      on_call = apply(module, :actor_profile_value, ["on_call_operator"])
      viewer = apply(module, :actor_profile_value, ["viewer"])

      on_call_socket = module.mount_seeded!(:incidents, mount_actor: on_call).socket
      viewer_socket = module.mount_seeded!(:incidents, mount_actor: viewer).socket

      viewer_messages = action_binding_messages(viewer_socket)
      on_call_messages = action_binding_messages(on_call_socket)

      assert "Acknowledge workflow executed" in on_call_messages
      assert "Resolve guard opened" in on_call_messages

      assert {:reply, %{status: :error, reason: "unauthorized"}, unauthorized_socket} =
               trigger_action_by_message(viewer_socket, "Acknowledge workflow executed")

      assert unauthorized_socket.assigns.flash.error ==
               "You are not authorized to perform this action"

      assert "Acknowledge workflow executed" in viewer_messages

      update_workspace_selection!(module, "incidents")
      admin_incidents_socket = mount_with_current_state!(module, :incidents, admin)
      _viewer_incidents_socket = mount_with_current_state!(module, :incidents, viewer)

      admin_incidents_markup = apply(module, :rendered_ui, [admin_incidents_socket.assigns])

      assert admin_incidents_markup =~ "Admin policy review"

      update_workspace_selection!(module, "operator")
      _on_call_operator_socket = mount_with_current_state!(module, :incidents, on_call)
      _viewer_operator_socket = mount_with_current_state!(module, :incidents, viewer)

      assert {:ok, updated_state} =
               module
               |> state!()
               |> Ash.Changeset.for_update(:submit_operator_workflow, %{
                 workflow_intent: "acknowledge",
                 operator_note: "Operator note includes enough incident context."
               })
               |> Ash.update(domain: runtime_domain(module), actor: on_call)

      assert updated_state.form_feedback_status == "success"
      assert updated_state.detail_status == "acknowledged"

      assert {:error, %Ash.Error.Forbidden{}} =
               module
               |> state!()
               |> Ash.Changeset.for_update(:submit_operator_workflow, %{
                 workflow_intent: "acknowledge",
                 operator_note: "Viewer attempts to acknowledge the incident."
               })
               |> Ash.update(domain: runtime_domain(module), actor: viewer)

      assert {:error, %Ash.Error.Forbidden{}} =
               module
               |> state!()
               |> Ash.Changeset.for_update(:preview_guarded_action, %{guard_intent: "resolve"})
               |> Ash.update(domain: runtime_domain(module), actor: viewer)
    end

    test "27.3.1.4 - Chapters 10 and 11 reference the correct checkpoint directories, actor profiles, and policy modules in prose" do
      assert :ok = Tutorials.validate_chapter_reference_contract()
      assert :ok = Phase27.validate_implemented_chapter_artifacts()

      expected_pairs = %{
        10 => {"../code/10-runtime-introspection/", "../code/09-metrics-and-capacity/"},
        11 => {"../code/11-roles-and-policies/", "../code/10-runtime-introspection/"}
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

  defp persisted_screens(module) do
    resource = Module.concat(module, UiScreen)
    domain = Module.concat(module, UiStorageDomain)
    Ash.read!(resource, domain: domain, authorize?: false)
  end

  defp authoritative_screen_graph?(screen) do
    roots = get_in(screen.unified_dsl, ["composition", "roots"]) || []

    roots != [] and
      Enum.all?(roots, fn root ->
        is_binary(root["module"]) and String.contains?(root["module"], "Examples.")
      end)
  end

  defp composition_modules(iur) do
    iur
    |> get_in(["composition", "roots"])
    |> List.wrap()
    |> Enum.flat_map(&composition_modules_from_root/1)
  end

  defp composition_modules_from_root(%{"module" => module, "children" => children}) do
    [module | Enum.flat_map(List.wrap(children), &composition_modules_from_root/1)]
  end

  defp composition_modules_from_root(%{"module" => module}) do
    [module]
  end

  defp composition_modules_from_root(_other), do: []

  defp state!(module) do
    resource = Module.concat([module, Runtime, WorkspaceState])
    domain = runtime_domain(module)

    resource
    |> Ash.read!(domain: domain, authorize?: false)
    |> Enum.find(&(&1.id == "tutorial-services-incidents-state"))
  end

  defp runtime_domain(module) do
    Module.concat([module, RuntimeDomain])
  end

  defp action_binding_by_message!(socket, success_message) do
    socket.assigns.ash_ui_action_bindings
    |> Map.values()
    |> Enum.find(fn binding ->
      binding
      |> binding_metadata()
      |> Map.get("success_message", Map.get(binding_metadata(binding), :success_message))
      |> Kernel.==(success_message)
    end)
  end

  defp action_binding_messages(socket) do
    socket.assigns.ash_ui_action_bindings
    |> Map.values()
    |> Enum.map(fn binding ->
      binding
      |> binding_metadata()
      |> Map.get("success_message", Map.get(binding_metadata(binding), :success_message))
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp update_workspace_selection!(module, selected_value) do
    module
    |> state!()
    |> Ash.Changeset.for_update(:update, %{selected_value: selected_value})
    |> Ash.update!(domain: runtime_domain(module), authorize?: false)
  end

  defp mount_with_current_state!(module, screen_kind, actor) do
    socket =
      module.build_socket(%{
        current_user: actor,
        ash_ui_storage: module.ui_storage(),
        ash_ui_domains: module.runtime_domains()
      })

    {:ok, socket} = Integration.mount_ui_screen(socket, module.screen_name(screen_kind), %{})
    {:ok, socket} = EventHandler.wire_handlers(socket)
    socket
  end

  defp trigger_action_by_message(socket, success_message) do
    binding = action_binding_by_message!(socket, success_message)

    EventHandler.handle_action_event(
      %{
        "action_id" => binding_id(binding),
        "element_id" => BindingRuntime.owner_element_id(binding),
        "signal" => "click"
      },
      socket
    )
  end

  defp binding_id(binding) do
    Map.get(binding, :id) || Map.get(binding, "id")
  end

  defp binding_metadata(binding) do
    Map.get(binding, :metadata) || Map.get(binding, "metadata") || %{}
  end

  defp repo_root do
    Path.expand("../..", __DIR__)
  end
end
