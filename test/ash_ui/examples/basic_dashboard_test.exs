defmodule AshUI.Examples.BasicDashboardTest do
  use AshUI.DataCase, async: false

  require Ash.Query

  alias BasicDashboard.Data
  alias BasicDashboardLive
  alias AshUI.Resources.Binding

  @moduletag :conformance
  defp build_socket(assigns \\ %{}) do
    %Phoenix.LiveView.Socket{
      assigns:
        assigns
        |> Enum.into(%{__changed__: %{}, flash: %{}})
    }
  end

  test "basic dashboard seed persists JSON-safe action parameter mappings" do
    Data.seed!()
    screen = BasicDashboard.seed!()

    bindings =
      Binding
      |> Ash.Query.filter(screen_id == ^screen.id)
      |> Ash.read!(domain: AshUI.Domain)

    assert screen.name == "basic_dashboard"
    assert function_exported?(BasicDashboardLive, :mount, 3)

    assert Enum.any?(bindings, fn binding ->
             binding.binding_type == :action and
               binding.source == %{
                 "resource" => "BasicDashboard.User",
                 "action" => "save_profile",
                 "id" => "current-user"
               } and
               binding.transform == %{
                 "params" => %{
                   "display_name" => %{"from" => "event", "key" => "display_name"},
                   "actor_id" => %{"from" => "context", "key" => "user_id"}
                 }
               }
           end)
  end

  test "basic dashboard mounts with ETS-backed data and updates the current user" do
    assert {:ok, socket} = BasicDashboardLive.mount(%{}, %{}, build_socket())

    assert socket.assigns.dashboard_data.user.name == "Pascal"
    assert socket.assigns.dashboard_data.user.email == "pascal@example.com"
    assert socket.assigns.dashboard_data.profile.team == "Platform"

    value_binding =
      socket.assigns.ash_ui_bindings
      |> Map.values()
      |> Enum.find(&(&1.binding_type == :value))

    action_binding =
      socket.assigns.ash_ui_bindings
      |> Map.values()
      |> Enum.find(&(&1.binding_type == :action))

    assert value_binding.value == "Pascal"
    assert value_binding.source["resource"] == "BasicDashboard.User"

    assert {:noreply, changed_socket} =
             BasicDashboardLive.handle_event(
               "ash_ui_change",
               %{"target" => "value", "value" => "Typed Pascal"},
               socket
             )

    assert changed_socket.assigns.dashboard_data.user.name == "Typed Pascal"
    assert Data.snapshot!().user.name == "Typed Pascal"

    assert {:reply, %{status: :ok}, updated_socket} =
             BasicDashboardLive.handle_event(
               "ash_ui_action",
               %{
                 "action_id" => action_binding.id,
                 "data" => %{"display_name" => "Updated Pascal"}
               },
               changed_socket
             )

    assert updated_socket.assigns.dashboard_data.user.name == "Updated Pascal"
    assert updated_socket.assigns.dashboard_data.user.last_actor_id == "current-user"
    assert Data.snapshot!().user.name == "Updated Pascal"
  end
end
