defmodule LiveUi.Widgets.SupervisionTreeViewer do
  @moduledoc """
  Native supervision-tree viewer widget.
  """

  use LiveUi.Component, family: :operational, name: :supervision_tree_viewer, events: [:change]

  LiveUi.Component.common_attrs()
  attr(:nodes, :list, default: [])
  attr(:expanded, :boolean, default: true)

  @impl true
  def render(assigns) do
    ~H"""
    <section
      id={@id}
      data-live-ui-widget="supervision-tree-viewer"
      data-live-ui-expanded={@expanded}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <ul>
        <%= for node <- @nodes do %>
          <.supervision_node node={node} />
        <% end %>
      </ul>
    </section>
    """
  end

  attr(:node, :map, required: true)

  defp supervision_node(assigns) do
    ~H"""
    <li data-node-id={@node[:id]} data-type={@node[:type]} data-status={@node[:status]}>
      <span><%= @node[:label] %></span>
      <%= if @node[:children] do %>
        <ul>
          <%= for child <- @node[:children] do %>
            <.supervision_node node={child} />
          <% end %>
        </ul>
      <% end %>
    </li>
    """
  end
end
