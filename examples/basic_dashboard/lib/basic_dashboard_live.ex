defmodule BasicDashboardLive do
  use Phoenix.LiveView

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.LiveView.UpdateIntegration
  alias BasicDashboard.Data

  def mount(_params, _session, socket) do
    Data.seed!()
    BasicDashboard.seed!()

    socket =
      socket
      |> assign(:current_user, Data.actor())
      |> assign(:ash_ui_domains, [BasicDashboard.Domain, AshUI.Domain])

    with {:ok, socket} <- Integration.mount_ui_screen(socket, :basic_dashboard, %{}) do
      {:ok, assign_dashboard_snapshot(socket)}
    end
  end

  def handle_event("ash_ui_change", params, socket) do
    case EventHandler.handle_value_change(params, socket) do
      {:noreply, updated_socket} -> {:noreply, assign_dashboard_snapshot(updated_socket)}
      other -> other
    end
  end

  def handle_event("ash_ui_action", params, socket) do
    case EventHandler.handle_action_event(params, socket) do
      {:reply, reply, updated_socket} -> {:reply, reply, assign_dashboard_snapshot(updated_socket)}
      other -> other
    end
  end

  def handle_info(%Ash.Notifier.Notification{} = notification, socket) do
    case UpdateIntegration.handle_resource_change(notification, socket) do
      {:noreply, updated_socket} -> {:noreply, assign_dashboard_snapshot(updated_socket)}
      other -> other
    end
  end

  def render(assigns) do
    ~H"""
    <section id="basic-dashboard-example">
      <h1>{@ash_ui_screen.name}</h1>
      <div id="dashboard-data">
        <p>User: {@dashboard_data.user.name}</p>
        <p>Email: {@dashboard_data.user.email}</p>
        <p>Status: {@dashboard_data.user.status}</p>
        <p>Team: {@dashboard_data.profile.team}</p>
        <p>Last actor: {display_last_actor(@dashboard_data.user.last_actor_id)}</p>
        <p>Bound value: {current_binding_value(@ash_ui_bindings)}</p>
      </div>
      <pre><%= inspect(@ash_ui_iur, pretty: true) %></pre>
    </section>
    """
  end

  defp assign_dashboard_snapshot(socket) do
    assign(socket, :dashboard_data, Data.snapshot!())
  end

  defp current_binding_value(bindings) do
    bindings
    |> Map.values()
    |> Enum.find_value(fn binding ->
      if binding.binding_type == :value and binding.target == "value" do
        binding.value
      end
    end)
  end

  defp display_last_actor(nil), do: "none yet"
  defp display_last_actor(actor_id), do: actor_id
end
