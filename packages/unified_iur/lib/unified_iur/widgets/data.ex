defmodule UnifiedIUR.Widgets.Data do
  @moduledoc """
  Canonical constructors for baseline list, table, and tree data views in
  `UnifiedIUR`.
  """

  alias UnifiedIUR.Attachment
  alias UnifiedIUR.Element
  alias UnifiedIUR.Metadata

  @kinds [:list, :table, :tree_view, :stat, :key_value, :info_list]

  @spec kinds() :: [atom()]
  def kinds do
    @kinds
  end

  @spec list([keyword() | map()], keyword() | map()) :: Element.t()
  def list(items, opts \\ []) when is_list(items) do
    opts = normalize_opts(opts)

    Element.new(:widget, :list,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          list:
            %{}
            |> maybe_put(:ordered?, option(opts, :ordered?, false))
            |> maybe_put(:selection_mode, option(opts, :selection_mode, :single))
            |> maybe_put(:items, normalize_items(items))
        }
        |> Attachment.merge(opts, component: :list),
      children: []
    )
  end

  @spec table([keyword() | map()], [keyword() | map()], keyword() | map()) :: Element.t()
  def table(columns, rows, opts \\ []) when is_list(columns) and is_list(rows) do
    opts = normalize_opts(opts)

    Element.new(:widget, :table,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          table:
            %{}
            |> maybe_put(:columns, normalize_columns(columns))
            |> maybe_put(:rows, normalize_rows(rows))
            |> maybe_put(:dense?, option(opts, :dense?, false))
        }
        |> Attachment.merge(opts, component: :table),
      children: []
    )
  end

  @spec tree_view([keyword() | map()], keyword() | map()) :: Element.t()
  def tree_view(nodes, opts \\ []) when is_list(nodes) do
    opts = normalize_opts(opts)

    Element.new(:widget, :tree_view,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          tree:
            %{}
            |> maybe_put(:selection_mode, option(opts, :selection_mode, :single))
            |> maybe_put(:nodes, normalize_nodes(nodes))
        }
        |> Attachment.merge(opts, component: :tree_view),
      children: []
    )
  end

  @spec stat(keyword() | map()) :: Element.t()
  def stat(opts \\ []) do
    opts = normalize_opts(opts)

    Element.new(:widget, :stat,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          stat:
            %{}
            |> maybe_put(:title, option(opts, :title))
            |> maybe_put(:value, option(opts, :value))
            |> maybe_put(:message, option(opts, :message))
        }
        |> Attachment.merge(opts, component: :stat),
      children: []
    )
  end

  @spec key_value(String.t(), term(), keyword() | map()) :: Element.t()
  def key_value(label, value, opts \\ []) when is_binary(label) do
    opts = normalize_opts(opts)

    Element.new(:widget, :key_value,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          key_value:
            %{}
            |> maybe_put(:label, label)
            |> maybe_put(:value, value)
            |> maybe_put(:description, option(opts, :description))
        }
        |> Attachment.merge(opts, component: :key_value),
      children: []
    )
  end

  @spec info_list([keyword() | map()], keyword() | map()) :: Element.t()
  def info_list(items, opts \\ []) when is_list(items) do
    opts = normalize_opts(opts)

    Element.new(:widget, :info_list,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          info_list:
            %{}
            |> maybe_put(:ordered?, option(opts, :ordered?, false))
            |> maybe_put(:empty_state, option(opts, :empty_state))
            |> maybe_put(:items, normalize_info_items(items))
        }
        |> Attachment.merge(opts, component: :info_list),
      children: []
    )
  end

  defp normalize_items(items) do
    Enum.map(items, fn item ->
      item = normalize_opts(item)

      %{}
      |> maybe_put(:id, option(item, :id))
      |> maybe_put(:label, option(item, :label))
      |> maybe_put(:value, option(item, :value))
      |> maybe_put(:description, option(item, :description))
      |> maybe_put(:selected?, option(item, :selected?))
    end)
  end

  defp normalize_columns(columns) do
    Enum.map(columns, fn column ->
      column = normalize_opts(column)

      %{}
      |> maybe_put(:id, option(column, :id))
      |> maybe_put(:label, option(column, :label))
      |> maybe_put(:width, option(column, :width))
      |> maybe_put(:align, option(column, :align))
    end)
  end

  defp normalize_rows(rows) do
    Enum.map(rows, fn row ->
      row = normalize_opts(row)

      %{}
      |> maybe_put(:id, option(row, :id))
      |> maybe_put(:cells, option(row, :cells, []))
      |> maybe_put(:selected?, option(row, :selected?))
    end)
  end

  defp normalize_nodes(nodes) do
    Enum.map(nodes, &normalize_node/1)
  end

  # :sub_group — categorical grouping inside a tree (e.g. "ADRs", "Specs")
  # Differs from :folder which is filesystem-style. Renders as a group header
  # with aria-role="group" rather than an expand/collapse folder affordance.
  defp normalize_node(raw_node) do
    node = normalize_opts(raw_node)
    kind = option(node, :kind)

    case kind do
      :sub_group -> normalize_sub_group_node(node)
      :file_leaf -> normalize_file_leaf_node(node)
      _ -> normalize_generic_node(node)
    end
  end

  defp normalize_generic_node(node) do
    children =
      case option(node, :children, []) do
        [] -> []
        nested when is_list(nested) -> normalize_nodes(nested)
      end

    %{}
    |> maybe_put(:id, option(node, :id))
    |> maybe_put(:kind, option(node, :kind))
    |> maybe_put(:label, option(node, :label))
    |> maybe_put(:value, option(node, :value))
    |> maybe_put(:expanded?, option(node, :expanded?))
    |> maybe_put(:selected?, option(node, :selected?))
    |> maybe_put(:children, if(children == [], do: nil, else: children))
  end

  # :sub_group: categorical grouping node
  #   - label: String.t() — visible group label (required)
  #   - children: [node()] — nested nodes within this group
  #   - expanded?: boolean() — hint (not gate) for initial render state
  defp normalize_sub_group_node(node) do
    children =
      case option(node, :children, []) do
        [] -> []
        nested when is_list(nested) -> normalize_nodes(nested)
      end

    %{}
    |> maybe_put(:id, option(node, :id))
    |> Map.put(:kind, :sub_group)
    |> maybe_put(:label, option(node, :label))
    |> maybe_put(:expanded?, option(node, :expanded?))
    |> maybe_put(:children, if(children == [], do: nil, else: children))
  end

  # :file_leaf: filesystem-path leaf node
  #   - path: String.t() — full file path (e.g. "lib/foo/bar.ex")
  #   - name: String.t() — display name (e.g. "bar.ex")
  #   - glyph: String.t() | nil — explicit glyph; falls back to extension-derived if nil
  #   - meta: map() | nil — optional metadata (lang, line count, last-modified, etc.)
  #   - selected?: boolean()
  defp normalize_file_leaf_node(node) do
    glyph = option(node, :glyph) || derive_glyph(option(node, :path))

    %{}
    |> maybe_put(:id, option(node, :id))
    |> Map.put(:kind, :file_leaf)
    |> maybe_put(:path, option(node, :path))
    |> maybe_put(:name, option(node, :name))
    |> maybe_put(:glyph, glyph)
    |> maybe_put(:meta, option(node, :meta))
    |> maybe_put(:selected?, option(node, :selected?))
  end

  # Extension-derived glyph fallback for :file_leaf nodes.
  # Returns a semantic glyph token for known Elixir/Markdown/etc extensions.
  # Returns nil for unknown extensions (renderer uses a generic file icon).
  @extension_glyphs %{
    ".ex" => "elixir",
    ".exs" => "elixir",
    ".md" => "markdown",
    ".livemd" => "markdown",
    ".json" => "json",
    ".yaml" => "yaml",
    ".yml" => "yaml",
    ".js" => "javascript",
    ".ts" => "typescript",
    ".css" => "stylesheet",
    ".html" => "markup",
    ".heex" => "markup"
  }

  defp derive_glyph(nil), do: nil

  defp derive_glyph(path) when is_binary(path) do
    ext = path |> Path.extname() |> String.downcase()
    Map.get(@extension_glyphs, ext)
  end

  defp normalize_info_items(items) do
    Enum.map(items, fn item ->
      item = normalize_opts(item)

      %{}
      |> maybe_put(:id, option(item, :id))
      |> maybe_put(:title, option(item, :title))
      |> maybe_put(:value, option(item, :value))
      |> maybe_put(:description, option(item, :description))
      |> maybe_put(:icon, option(item, :icon))
      |> maybe_put(:status, option(item, :status))
    end)
  end

  defp normalize_metadata(opts) do
    opts
    |> option(:metadata)
    |> Metadata.merge(%{
      description: option(opts, :description),
      annotations: option(opts, :annotations, %{}),
      tags: option(opts, :tags, [])
    })
  end

  defp normalize_opts(opts) when is_list(opts), do: Enum.into(opts, %{})
  defp normalize_opts(opts) when is_map(opts), do: Map.new(opts)

  defp option(opts, key, default \\ nil) do
    Map.get(opts, key, Map.get(opts, Atom.to_string(key), default))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
