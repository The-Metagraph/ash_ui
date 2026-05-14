defmodule LiveUi.Widgets.ClusterDashboard do
  @moduledoc """
  Native cluster-dashboard widget.
  """

  use LiveUi.Component, family: :operational, name: :cluster_dashboard, events: [:change]

  LiveUi.Component.common_attrs()
  attr(:nodes, :list, default: [])
  attr(:summary, :map, default: %{})

  @impl true
  def render(assigns) do
    ~H"""
    <section
      id={@id}
      data-live-ui-widget="cluster-dashboard"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <header data-summary={inspect(@summary)}></header>
      <ul>
        <%= for node <- @nodes do %>
          <li data-node-id={node[:id]} data-status={node[:status]}><%= node[:id] %></li>
        <% end %>
      </ul>
    </section>
    """
  end
end
