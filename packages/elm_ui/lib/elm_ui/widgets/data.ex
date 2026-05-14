defmodule ElmUi.Widgets.Data do
  @moduledoc """
  Advanced data and document-oriented widgets for direct-use `elm_ui`
  review flows.
  """

  alias ElmUi.Widgets.Builder

  @kinds [:list, :table, :tree_view, :stat, :key_value, :info_list, :markdown_viewer, :log_viewer]

  @spec kinds() :: [atom()]
  def kinds, do: @kinds

  @spec list(String.t() | atom(), [keyword() | map()], keyword() | map()) :: ElmUi.Widget.t()
  def list(id, items, opts \\ []) when is_list(items) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:list,
      id: id,
      attributes: %{
        ordered: Builder.option(opts, :ordered, false),
        selection_mode: Builder.option(opts, :selection_mode, :single),
        items: normalize_items(items)
      },
      state: Builder.state(opts, [:disabled, :loading, :focused, :selected]),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_change: :change),
      metadata: Builder.metadata(opts, %{native_surface: :data, review_surface: true})
    )
  end

  @spec table(
          String.t() | atom(),
          [keyword() | map()],
          [keyword() | map()],
          keyword() | map()
        ) :: ElmUi.Widget.t()
  def table(id, columns, rows, opts \\ []) when is_list(columns) and is_list(rows) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:table,
      id: id,
      attributes: %{
        columns: normalize_columns(columns),
        rows: normalize_rows(rows),
        dense: Builder.option(opts, :dense, false),
        selection_mode: Builder.option(opts, :selection_mode, :single),
        sorting: normalize_sorting(opts),
        filters: normalize_filters(Builder.option(opts, :filters, [])),
        pagination: normalize_pagination(opts)
      },
      state: Builder.state(opts, [:disabled, :loading, :focused, :selected]),
      styles: Builder.styles(opts),
      events:
        Builder.events(opts,
          on_change: :change,
          on_sort: :sort,
          on_filter: :filter,
          on_paginate: :paginate
        ),
      metadata: Builder.metadata(opts, %{native_surface: :data, review_surface: true})
    )
  end

  @spec tree_view(String.t() | atom(), [keyword() | map()], keyword() | map()) ::
          ElmUi.Widget.t()
  def tree_view(id, nodes, opts \\ []) when is_list(nodes) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:tree_view,
      id: id,
      attributes: %{
        nodes: normalize_nodes(nodes),
        selection_mode: Builder.option(opts, :selection_mode, :single),
        filters: normalize_filters(Builder.option(opts, :filters, [])),
        query: Builder.option(opts, :query),
        expand_all: Builder.option(opts, :expand_all, false)
      },
      state: Builder.state(opts, [:disabled, :focused, :loading, :expanded]),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_change: :change, on_filter: :filter, on_expand: :expand),
      metadata: Builder.metadata(opts, %{native_surface: :data, review_surface: true})
    )
  end

  @spec stat(String.t() | atom(), keyword() | map()) :: ElmUi.Widget.t()
  def stat(id, opts \\ []) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:stat,
      id: id,
      attributes: %{
        title: Builder.option(opts, :title),
        value: Builder.option(opts, :value),
        message: Builder.option(opts, :message)
      },
      state: Builder.state(opts, [:disabled]),
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :data, review_surface: true})
    )
  end

  @spec key_value(String.t() | atom(), String.t(), term(), keyword() | map()) :: ElmUi.Widget.t()
  def key_value(id, label, value, opts \\ []) when is_binary(label) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:key_value,
      id: id,
      attributes: %{
        label: label,
        value: value,
        description: Builder.option(opts, :description)
      },
      state: Builder.state(opts, [:disabled]),
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :data, review_surface: true})
    )
  end

  @spec info_list(String.t() | atom(), [keyword() | map()], keyword() | map()) :: ElmUi.Widget.t()
  def info_list(id, items, opts \\ []) when is_list(items) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:info_list,
      id: id,
      attributes: %{
        items: normalize_info_items(items),
        ordered: Builder.option(opts, :ordered, false),
        empty_state: Builder.option(opts, :empty_state)
      },
      state: Builder.state(opts, [:disabled]),
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :data, review_surface: true})
    )
  end

  @spec markdown_viewer(String.t() | atom(), String.t(), keyword() | map()) :: ElmUi.Widget.t()
  def markdown_viewer(id, markdown, opts \\ []) when is_binary(markdown) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:markdown_viewer,
      id: id,
      attributes: %{
        source: markdown,
        format: :markdown,
        mode: Builder.option(opts, :mode, :rendered),
        anchors: normalize_anchors(Builder.option(opts, :anchors, []))
      },
      state: Builder.state(opts, [:disabled]),
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :document, review_surface: true})
    )
  end

  @spec log_viewer(String.t() | atom(), [keyword() | map()], keyword() | map()) ::
          ElmUi.Widget.t()
  def log_viewer(id, entries, opts \\ []) when is_list(entries) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:log_viewer,
      id: id,
      attributes: %{
        entries: normalize_entries(entries),
        wrap: Builder.option(opts, :wrap, true),
        show_timestamps: Builder.option(opts, :show_timestamps, true),
        follow: Builder.option(opts, :follow, false),
        filters: normalize_filters(Builder.option(opts, :filters, [])),
        pagination: normalize_pagination(opts)
      },
      state: Builder.state(opts, [:disabled, :focused, :streaming]),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_filter: :filter, on_paginate: :paginate),
      metadata: Builder.metadata(opts, %{native_surface: :document, review_surface: true})
    )
  end

  defp normalize_columns(columns) do
    Enum.map(columns, fn column ->
      column = Builder.options(column)

      %{}
      |> Builder.maybe_put(:id, Builder.option(column, :id))
      |> Builder.maybe_put(:label, Builder.option(column, :label))
      |> Builder.maybe_put(:width, Builder.option(column, :width))
      |> Builder.maybe_put(:align, Builder.option(column, :align))
      |> Builder.maybe_put(:sortable, Builder.option(column, :sortable))
      |> Builder.maybe_put(:sort_key, Builder.option(column, :sort_key))
    end)
  end

  defp normalize_items(items) do
    Enum.map(items, fn item ->
      item = Builder.options(item)

      %{}
      |> Builder.maybe_put(:id, Builder.option(item, :id))
      |> Builder.maybe_put(:label, Builder.option(item, :label))
      |> Builder.maybe_put(:value, Builder.option(item, :value))
      |> Builder.maybe_put(:description, Builder.option(item, :description))
      |> Builder.maybe_put(:selected, Builder.option(item, :selected))
    end)
  end

  defp normalize_info_items(items) do
    Enum.map(items, fn item ->
      item = Builder.options(item)

      %{}
      |> Builder.maybe_put(:id, Builder.option(item, :id))
      |> Builder.maybe_put(:title, Builder.option(item, :title))
      |> Builder.maybe_put(:value, Builder.option(item, :value))
      |> Builder.maybe_put(:description, Builder.option(item, :description))
      |> Builder.maybe_put(:icon, Builder.option(item, :icon))
      |> Builder.maybe_put(:status, Builder.option(item, :status))
    end)
  end

  defp normalize_rows(rows) do
    Enum.map(rows, fn row ->
      row = Builder.options(row)

      %{}
      |> Builder.maybe_put(:id, Builder.option(row, :id))
      |> Builder.maybe_put(:cells, Builder.option(row, :cells, []))
      |> Builder.maybe_put(:selected, Builder.option(row, :selected))
      |> Builder.maybe_put(:metadata, Builder.option(row, :metadata))
    end)
  end

  defp normalize_nodes(nodes) do
    Enum.map(nodes, fn node ->
      node = Builder.options(node)
      children = node |> Builder.option(:children, []) |> normalize_nodes()

      %{}
      |> Builder.maybe_put(:id, Builder.option(node, :id))
      |> Builder.maybe_put(:label, Builder.option(node, :label))
      |> Builder.maybe_put(:value, Builder.option(node, :value))
      |> Builder.maybe_put(:expanded, Builder.option(node, :expanded))
      |> Builder.maybe_put(:selected, Builder.option(node, :selected))
      |> Builder.maybe_put(:children, if(children == [], do: nil, else: children))
    end)
  end

  defp normalize_entries(entries) do
    Enum.map(entries, fn entry ->
      entry = Builder.options(entry)

      %{}
      |> Builder.maybe_put(:id, Builder.option(entry, :id))
      |> Builder.maybe_put(:message, Builder.option(entry, :message))
      |> Builder.maybe_put(:severity, Builder.option(entry, :severity))
      |> Builder.maybe_put(:timestamp, Builder.option(entry, :timestamp))
      |> Builder.maybe_put(:metadata, Builder.option(entry, :metadata))
    end)
  end

  defp normalize_anchors(anchors) when is_list(anchors) do
    Enum.map(anchors, fn anchor ->
      anchor = Builder.options(anchor)

      %{}
      |> Builder.maybe_put(:id, Builder.option(anchor, :id))
      |> Builder.maybe_put(:label, Builder.option(anchor, :label))
      |> Builder.maybe_put(:level, Builder.option(anchor, :level))
    end)
  end

  defp normalize_anchors(_other), do: []

  defp normalize_sorting(opts) do
    %{}
    |> Builder.maybe_put(:key, Builder.option(opts, :sort_key))
    |> Builder.maybe_put(:direction, Builder.option(opts, :sort_direction))
  end

  defp normalize_filters(filters) do
    Enum.map(List.wrap(filters), fn filter ->
      filter = Builder.options(filter)

      %{}
      |> Builder.maybe_put(:field, Builder.option(filter, :field))
      |> Builder.maybe_put(:operator, Builder.option(filter, :operator))
      |> Builder.maybe_put(:value, Builder.option(filter, :value))
    end)
  end

  defp normalize_pagination(opts) do
    %{}
    |> Builder.maybe_put(:page, Builder.option(opts, :page))
    |> Builder.maybe_put(:page_size, Builder.option(opts, :page_size))
    |> Builder.maybe_put(:total_entries, Builder.option(opts, :total_entries))
  end
end
