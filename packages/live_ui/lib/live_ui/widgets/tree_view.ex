defmodule LiveUi.Widgets.TreeView do
  @moduledoc """
  Native tree-view widget for hierarchical data.

  Supports three node kinds:
  - generic (default) — standard expand/collapse branch or leaf node
  - `:sub_group` — categorical grouping (EX-1: Wave 3.7). Renders as a
    `role="group"` container with a visible header label. Differs from
    `:folder` (filesystem); sub_group represents semantic categories like
    "ADRs", "Specs", "Plans" within a repo card.
  - `:file_leaf` — filesystem-path leaf (EX-2: Wave 3.7). Renders as a
    treeitem row with a glyph token (extension-derived fallback), file name,
    and optional meta. `aria-label` is "File: {name}".
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

  defp tree_node(%{node: node} = assigns) do
    case fetch(node, :kind) do
      :sub_group -> sub_group_node(assigns)
      :file_leaf -> file_leaf_node(assigns)
      _ -> generic_tree_node(assigns)
    end
  end

  # Generic node: standard branch/leaf with label and optional children.
  defp generic_tree_node(assigns) do
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

  # :sub_group node: categorical grouping rendered as a group container.
  # Uses role="group" + aria-label for screen reader announcement.
  # Visual treatment: header label + optional expand state, no folder-chevron.
  defp sub_group_node(assigns) do
    ~H"""
    <li
      data-node-id={fetch(@node, :id)}
      data-node-kind="sub_group"
      data-expanded={expanded?(@node)}
      role="group"
      aria-label={fetch(@node, :label)}
      class={fetch(@node, :class)}
      {fetch(@node, :attrs) || %{}}
    >
      <span data-sub-group-label><%= fetch(@node, :label) %></span>
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

  # :file_leaf node: filesystem-path leaf row.
  # aria-label is "File: {name}" for treeitem containment semantics.
  # data-glyph carries the extension-derived or explicit glyph token.
  # data-file-path carries the full path for host event handlers.
  defp file_leaf_node(assigns) do
    ~H"""
    <li
      data-node-id={fetch(@node, :id)}
      data-node-kind="file_leaf"
      data-selected={selected?(@node)}
      data-file-path={fetch(@node, :path)}
      data-glyph={fetch(@node, :glyph)}
      aria-label={"File: #{fetch(@node, :name) || fetch(@node, :path)}"}
      class={fetch(@node, :class)}
      {fetch(@node, :attrs) || %{}}
    >
      <span data-file-name><%= fetch(@node, :name) || fetch(@node, :path) %></span>
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
