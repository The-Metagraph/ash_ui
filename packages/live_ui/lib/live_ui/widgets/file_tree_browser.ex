defmodule LiveUi.Widgets.FileTreeBrowser do
  @moduledoc """
  Native file tree browser widget for filesystem-like navigation.
  """

  use LiveUi.Component,
    family: :navigation,
    name: :file_tree_browser,
    events: [:selection, :change]

  LiveUi.Component.common_attrs()
  attr(:tree_id, :string, required: true)
  attr(:root_label, :string, default: "Files")
  attr(:nodes, :list, default: [])
  attr(:selected_path, :string, default: nil)
  attr(:default_expanded?, :boolean, default: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class={["live-ui-file-tree-browser", @class]}
      data-live-ui-widget="file-tree-browser"
      data-tree-id={@tree_id}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      role="tree"
      aria-label={@root_label}
      {@rest}
    >
      <.file_tree_node
        :for={node <- @nodes}
        node={node}
        selected_path={@selected_path}
        default_expanded?={@default_expanded?}
        depth={0}
      />
    </div>
    """
  end

  attr(:node, :map, required: true)
  attr(:selected_path, :string, default: nil)
  attr(:default_expanded?, :boolean, default: true)
  attr(:depth, :integer, default: 0)

  defp file_tree_node(%{node: node} = assigns) do
    assigns =
      assigns
      |> assign(:node_type, node_type(node))
      |> assign(:expanded?, node_expanded?(node, assigns.default_expanded?))

    ~H"""
    <.folder_node
      :if={@node_type == :folder}
      node={@node}
      expanded?={@expanded?}
      selected_path={@selected_path}
      default_expanded?={@default_expanded?}
      depth={@depth}
    />
    <.file_node
      :if={@node_type == :file_leaf}
      node={@node}
      selected_path={@selected_path}
      depth={@depth}
    />
    """
  end

  attr(:node, :map, required: true)
  attr(:expanded?, :boolean, required: true)
  attr(:selected_path, :string, default: nil)
  attr(:default_expanded?, :boolean, default: true)
  attr(:depth, :integer, default: 0)

  defp folder_node(assigns) do
    ~H"""
    <div class="live-ui-file-tree-browser__folder" role="none">
      <button
        type="button"
        class={[
          "live-ui-file-tree-browser__folder-row",
          @expanded? && "live-ui-file-tree-browser__folder-row--expanded"
        ]}
        style={indent_style(@depth)}
        role="treeitem"
        aria-expanded={to_string(@expanded?)}
        data-node-id={node_id(@node)}
        data-node-path={node_path(@node)}
        {node_attrs(@node, :toggle_attrs)}
      >
        <span class="live-ui-file-tree-browser__marker" aria-hidden="true">
          {if @expanded?, do: "v", else: ">"}
        </span>
        <span class="live-ui-file-tree-browser__folder-name">{node_name(@node)}/</span>
      </button>

      <div :if={@expanded?} class="live-ui-file-tree-browser__children" role="group">
        <.file_tree_node
          :for={child <- node_children(@node)}
          node={child}
          selected_path={@selected_path}
          default_expanded?={@default_expanded?}
          depth={@depth + 1}
        />
      </div>
    </div>
    """
  end

  attr(:node, :map, required: true)
  attr(:selected_path, :string, default: nil)
  attr(:depth, :integer, default: 0)

  defp file_node(assigns) do
    assigns = assign(assigns, :selected?, node_selected?(assigns.node, assigns.selected_path))

    ~H"""
    <button
      type="button"
      class={[
        "live-ui-file-tree-browser__file-row",
        @selected? && "live-ui-file-tree-browser__file-row--selected"
      ]}
      style={indent_style(@depth)}
      role="treeitem"
      aria-selected={to_string(@selected?)}
      data-node-id={node_id(@node)}
      data-file-path={node_path(@node)}
      {node_attrs(@node, :select_attrs)}
    >
      <span class="live-ui-file-tree-browser__file-glyph" aria-hidden="true">
        {file_glyph(@node)}
      </span>
      <span class="live-ui-file-tree-browser__file-name">{node_name(@node)}</span>
      <span :if={file_meta(@node) != ""} class="live-ui-file-tree-browser__file-meta">
        {file_meta(@node)}
      </span>
    </button>
    """
  end

  defp node_type(node) do
    case fetch(node, :type, :file_leaf) do
      type when type in [:folder, "folder", :directory, "directory"] -> :folder
      _type -> :file_leaf
    end
  end

  defp node_id(node), do: fetch(node, :id, node_path(node))
  defp node_path(node), do: fetch(node, :path, node_id_fallback(node))
  defp node_name(node), do: fetch(node, :name, Path.basename(to_string(node_path(node))))
  defp node_children(node), do: fetch(node, :children, [])

  defp node_id_fallback(node), do: fetch(node, :id, "")

  defp node_attrs(node, key), do: fetch(node, key, %{})

  defp node_expanded?(node, default) do
    case fetch(node, :expanded?) do
      nil -> default
      value -> value
    end
  end

  defp node_selected?(node, selected_path) when is_binary(selected_path) do
    selected_path == to_string(node_path(node))
  end

  defp node_selected?(_node, _selected_path), do: false

  defp file_meta(node) do
    [fetch(node, :language), line_count_meta(fetch(node, :line_count))]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" - ")
  end

  defp line_count_meta(nil), do: nil
  defp line_count_meta(count), do: "#{count} lines"

  defp file_glyph(node) do
    case fetch(node, :file_kind, fetch(node, :language, Path.extname(to_string(node_name(node))))) do
      :elixir -> "ex"
      "elixir" -> "ex"
      :markdown -> "md"
      "markdown" -> "md"
      :json -> "{}"
      "json" -> "{}"
      value -> value |> to_string() |> String.trim_leading(".") |> String.slice(0, 3)
    end
    |> case do
      "" -> "-"
      glyph -> glyph
    end
  end

  defp indent_style(depth), do: "padding-inline-start: #{depth * 12}px"

  defp fetch(source, key, default \\ nil)
  defp fetch(source, key, default) when is_map(source), do: Map.get(source, key, default)
  defp fetch(source, key, default) when is_list(source), do: Keyword.get(source, key, default)
  defp fetch(_source, _key, default), do: default
end
