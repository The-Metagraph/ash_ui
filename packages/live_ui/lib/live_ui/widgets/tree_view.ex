defmodule LiveUi.Widgets.TreeView do
  @moduledoc """
  Native tree-view widget for hierarchical data.
  """

  use LiveUi.Component, family: :data, name: :tree_view, events: [:click, :selection]

  LiveUi.Component.common_attrs()
  attr(:nodes, :list, default: [])
  attr(:selection_mode, :string, default: "single")

  @impl true
  def render(assigns) do
    ~H"""
    <section
      id={@id}
      data-live-ui-widget="tree-view"
      data-live-ui-selection-mode={@selection_mode}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <ul>
        <%= for node <- @nodes do %>
          <.tree_node node={node} />
        <% end %>
      </ul>
    </section>
    """
  end

  attr(:node, :map, required: true)

  defp tree_node(assigns) do
    ~H"""
    <li
      data-node-id={fetch(@node, :id)}
      data-selected={selected?(@node)}
      data-expanded={expanded?(@node)}
      class={fetch(@node, :class)}
      {fetch(@node, :attrs) || %{}}
    >
      <span><%= fetch(@node, :label) || fetch(@node, :value) %></span>
      <%= if fetch(@node, :children) do %>
        <ul>
          <%= for child <- fetch(@node, :children) do %>
            <.tree_node node={child} />
          <% end %>
        </ul>
      <% end %>
    </li>
    """
  end

  defp selected?(node) do
    fetch(node, :selected) || fetch(node, :selected?)
  end

  defp expanded?(node) do
    fetch(node, :expanded) || fetch(node, :expanded?)
  end

  defp fetch(node, key) when is_map(node) do
    Map.get(node, key) || Map.get(node, Atom.to_string(key))
  end
end
