defmodule AshUI.LiveView.ScreenHostTest do
  use AshUI.DataCase, async: false

  alias AshUI.LiveView.ScreenHost
  alias BasicDashboard.Data
  alias BasicDashboard.Storage

  defmodule HostedBasicDashboardLive do
    use AshUI.LiveView.ScreenHost, screen: :basic_dashboard

    def ash_ui_prepare(_params, _session, socket) do
      Data.seed!()
      BasicDashboard.seed!()
      {:ok, socket}
    end

    def ash_ui_current_user(_params, _session, _socket), do: Data.actor()
    def ash_ui_storage(_params, _session, _socket), do: Storage.config()
    def ash_ui_domains(_params, _session, _socket), do: [BasicDashboard.Domain]
  end

  defp build_socket(assigns \\ %{}) do
    %Phoenix.LiveView.Socket{
      assigns:
        assigns
        |> Enum.into(%{__changed__: %{}, flash: %{}})
    }
  end

  test "generic host mounts a stored screen with shared Ash UI wiring" do
    assert {:ok, socket} = HostedBasicDashboardLive.mount(%{}, %{}, build_socket())

    assert socket.assigns.ash_ui_screen.__struct__ == BasicDashboard.Storage.Screen
    assert socket.assigns.ash_ui_storage[:domain] == BasicDashboard.Storage.Domain
    assert socket.assigns.ash_ui_iur["type"] == "screen"
  end

  test "generic host delegates change and action events" do
    assert {:ok, socket} = HostedBasicDashboardLive.mount(%{}, %{}, build_socket())

    value_binding =
      socket.assigns.ash_ui_bindings
      |> Map.values()
      |> Enum.find(&(&1.binding_type == :value and &1.target == "display_name"))

    action_binding =
      socket.assigns.ash_ui_bindings
      |> Map.values()
      |> Enum.find(&(&1.binding_type == :action))

    assert {:noreply, changed_socket} =
             HostedBasicDashboardLive.handle_event(
               "ash_ui_change",
               %{
                 "binding_id" => value_binding.id,
                 "target" => value_binding.target,
                 "_target" => ["display_name"],
                 "display_name" => "Hosted Pascal"
               },
               socket
             )

    assert Data.snapshot!().user.name == "Hosted Pascal"

    assert {:reply, %{status: :ok}, _updated_socket} =
             HostedBasicDashboardLive.handle_event(
               "ash_ui_action",
               %{"action_id" => action_binding.id},
               changed_socket
             )

    assert Data.snapshot!().user.last_actor_id == "current-user"
  end

  test "generic host renders the hydrated live UI output" do
    assert {:ok, socket} = HostedBasicDashboardLive.mount(%{}, %{}, build_socket())

    html =
      socket.assigns
      |> HostedBasicDashboardLive.render()
      |> Phoenix.LiveViewTest.rendered_to_string()

    assert html =~ "Model your dashboard. Let the runtime do the wiring."
    assert html =~ "ash-table"
    assert html =~ "ash-list"
  end

  test "render_iur/2 safely handles nil" do
    assert ScreenHost.render_iur(nil) == ""
  end
end
