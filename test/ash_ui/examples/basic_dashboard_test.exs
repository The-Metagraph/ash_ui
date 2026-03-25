defmodule AshUI.Examples.BasicDashboardTest do
  use AshUI.DataCase, async: false

  alias AshUI.Compiler
  alias AshUI.Authoring.Document
  alias AshUI.Rendering.IURAdapter
  alias BasicDashboard.Data
  alias BasicDashboard.Storage
  alias BasicDashboardLive

  @moduletag :conformance

  defp build_socket(assigns \\ %{}) do
    %Phoenix.LiveView.Socket{
      assigns:
        assigns
        |> Enum.into(%{__changed__: %{}, flash: %{}})
    }
  end

  test "basic dashboard seed compiles a full dashboard screen with action and value bindings" do
    Data.seed!()
    screen = BasicDashboard.seed!()

    assert screen.name == "basic_dashboard"
    assert screen.__struct__ == BasicDashboard.Storage.Screen
    assert Document.authoring_document?(screen.unified_dsl)
    assert screen.unified_dsl["format"] == Document.format()

    assert {:ok, iur} = Compiler.compile(screen, ui_storage: Storage.config())
    assert {:ok, canonical_iur} = IURAdapter.to_canonical(iur)

    assert canonical_iur["type"] == "screen"
    assert length(canonical_iur["children"]) == 1
    assert length(canonical_iur["bindings"]) >= 6

    assert Enum.any?(canonical_iur["bindings"], fn binding ->
             binding["type"] == "event" and
               binding["source"] == %{
                 "resource" => "BasicDashboard.User",
                 "action" => "save_profile",
                 "id" => "current-user"
               } and
               binding["transform"] == %{
                 "params" => %{
                   "display_name" => %{"from" => "binding", "key" => "display_name"},
                   "actor_id" => %{"from" => "context", "key" => "user_id"}
                 }
               }
           end)
  end

  test "basic dashboard mounts from ETS ui storage and updates the current user" do
    assert {:ok, socket} = BasicDashboardLive.mount(%{}, %{}, build_socket())

    assert socket.assigns.ash_ui_screen.__struct__ == BasicDashboard.Storage.Screen
    assert socket.assigns.ash_ui_storage[:domain] == BasicDashboard.Storage.Domain

    value_binding =
      socket.assigns.ash_ui_bindings
      |> Map.values()
      |> Enum.find(&(&1.binding_type == :value and &1.target == "display_name"))

    action_binding =
      socket.assigns.ash_ui_bindings
      |> Map.values()
      |> Enum.find(&(&1.binding_type == :action))

    assert value_binding.value == "Pascal"
    assert action_binding.source["action"] == "save_profile"

    assert {:noreply, changed_socket} =
             BasicDashboardLive.handle_event(
               "ash_ui_change",
               %{
                 "binding_id" => value_binding.id,
                 "target" => value_binding.target,
                 "_target" => ["display_name"],
                 "display_name" => "Typed Pascal"
               },
               socket
             )

    assert Data.snapshot!().user.name == "Typed Pascal"
    assert changed_socket.assigns.ash_ui_iur["children"] != []

    assert {:reply, %{status: :ok}, _updated_socket} =
             BasicDashboardLive.handle_event(
               "ash_ui_action",
               %{"action_id" => action_binding.id},
               changed_socket
             )

    assert Data.snapshot!().user.last_actor_id == "current-user"
  end

  test "basic dashboard renders the stored IUR tree instead of a handwritten shell" do
    assert {:ok, socket} = BasicDashboardLive.mount(%{}, %{}, build_socket())

    html =
      socket.assigns
      |> BasicDashboardLive.render()
      |> Phoenix.LiveViewTest.rendered_to_string()

    assert html =~ "Model your dashboard. Let the runtime do the wiring."
    assert html =~ "Interactive profile editor"
    assert html =~ "phx-change=\"ash_ui_change\""
    assert html =~ "phx-click=\"ash_ui_action\""
    refute html =~ "ash-demo-shell"
  end
end
