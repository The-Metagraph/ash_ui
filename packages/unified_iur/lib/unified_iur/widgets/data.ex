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
    Enum.map(nodes, fn node ->
      node = normalize_opts(node)

      children =
        case option(node, :children, []) do
          [] -> []
          nested when is_list(nested) -> normalize_nodes(nested)
        end

      %{}
      |> maybe_put(:id, option(node, :id))
      |> maybe_put(:label, option(node, :label))
      |> maybe_put(:value, option(node, :value))
      |> maybe_put(:expanded?, option(node, :expanded?))
      |> maybe_put(:selected?, option(node, :selected?))
      |> maybe_put(:children, if(children == [], do: nil, else: children))
    end)
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
