defmodule UnifiedIUR.Widgets.Advanced do
  @moduledoc """
  Canonical constructors for advanced operational, inspection, and document
  widgets in `UnifiedIUR`.
  """

  alias UnifiedIUR.Attachment
  alias UnifiedIUR.Element
  alias UnifiedIUR.Metadata

  @kinds [
    :stream_widget,
    :log_viewer,
    :process_monitor,
    :cluster_dashboard,
    :command_palette,
    :markdown_viewer,
    :supervision_tree_viewer
  ]

  @spec kinds() :: [atom()]
  def kinds do
    @kinds
  end

  @spec stream_widget([keyword() | map()], keyword() | map()) :: Element.t()
  def stream_widget(entries, opts \\ []) when is_list(entries) do
    opts = normalize_opts(opts)

    Element.new(:widget, :stream_widget,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          stream:
            %{}
            |> maybe_put(:entries, normalize_entries(entries))
            |> maybe_put(:ordering, option(opts, :ordering, :append_only))
            |> maybe_put(:severity_field, option(opts, :severity_field))
            |> maybe_put(:timestamp_field, option(opts, :timestamp_field))
        }
        |> Attachment.merge(opts, component: :stream_widget),
      children: []
    )
  end

  @spec log_viewer([keyword() | map()], keyword() | map()) :: Element.t()
  def log_viewer(entries, opts \\ []) when is_list(entries) do
    opts = normalize_opts(opts)

    Element.new(:widget, :log_viewer,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          logs:
            %{}
            |> maybe_put(:entries, normalize_entries(entries))
            |> maybe_put(:wrap?, option(opts, :wrap?, true))
            |> maybe_put(:show_timestamps?, option(opts, :show_timestamps?, true))
        }
        |> Attachment.merge(opts, component: :log_viewer),
      children: []
    )
  end

  @spec process_monitor([keyword() | map()], keyword() | map()) :: Element.t()
  def process_monitor(processes, opts \\ []) when is_list(processes) do
    opts = normalize_opts(opts)

    Element.new(:widget, :process_monitor,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          monitor:
            %{}
            |> maybe_put(:processes, normalize_entities(processes))
            |> maybe_put(:sort_by, option(opts, :sort_by))
            |> maybe_put(:severity, option(opts, :severity))
        }
        |> Attachment.merge(opts, component: :process_monitor),
      children: []
    )
  end

  @spec cluster_dashboard([keyword() | map()], keyword() | map()) :: Element.t()
  def cluster_dashboard(nodes, opts \\ []) when is_list(nodes) do
    opts = normalize_opts(opts)

    Element.new(:widget, :cluster_dashboard,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          cluster:
            %{}
            |> maybe_put(:nodes, normalize_entities(nodes))
            |> maybe_put(:summary, normalize_map(option(opts, :summary, %{})))
            |> maybe_put(:severity, option(opts, :severity))
        }
        |> Attachment.merge(opts, component: :cluster_dashboard),
      children: []
    )
  end

  @spec command_palette([keyword() | map()], keyword() | map()) :: Element.t()
  def command_palette(commands, opts \\ []) when is_list(commands) do
    opts = normalize_opts(opts)

    Element.new(:widget, :command_palette,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          command_palette:
            %{}
            |> maybe_put(:commands, normalize_entities(commands))
            |> maybe_put(:query, option(opts, :query))
            |> maybe_put(:active_command, option(opts, :active_command))
            |> maybe_put(:placeholder, option(opts, :placeholder))
        }
        |> Attachment.merge(opts, component: :command_palette),
      children: []
    )
  end

  @spec markdown_viewer(String.t(), keyword() | map()) :: Element.t()
  def markdown_viewer(markdown, opts \\ []) when is_binary(markdown) do
    opts = normalize_opts(opts)

    Element.new(:widget, :markdown_viewer,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          document:
            %{}
            |> maybe_put(:format, :markdown)
            |> maybe_put(:source, markdown)
            |> maybe_put(:mode, option(opts, :mode, :rendered))
            |> maybe_put(:anchors, option(opts, :anchors))
        }
        |> Attachment.merge(opts, component: :markdown_viewer),
      children: []
    )
  end

  @spec supervision_tree_viewer([keyword() | map()], keyword() | map()) :: Element.t()
  def supervision_tree_viewer(nodes, opts \\ []) when is_list(nodes) do
    opts = normalize_opts(opts)

    Element.new(:widget, :supervision_tree_viewer,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          inspection:
            %{}
            |> maybe_put(:nodes, normalize_hierarchy(nodes))
            |> maybe_put(:expanded?, option(opts, :expanded?, true))
            |> maybe_put(:show_restarts?, option(opts, :show_restarts?, true))
        }
        |> Attachment.merge(opts, component: :supervision_tree_viewer),
      children: []
    )
  end

  defp normalize_entries(entries) do
    Enum.map(entries, fn entry ->
      entry = normalize_opts(entry)

      %{}
      |> maybe_put(:id, option(entry, :id))
      |> maybe_put(:message, option(entry, :message))
      |> maybe_put(:severity, option(entry, :severity))
      |> maybe_put(:timestamp, option(entry, :timestamp))
      |> maybe_put(:metadata, normalize_map(option(entry, :metadata, %{})))
    end)
  end

  defp normalize_entities(items) do
    Enum.map(items, fn item ->
      item
      |> normalize_opts()
      |> Map.new()
    end)
  end

  defp normalize_hierarchy(nodes) do
    Enum.map(nodes, fn node ->
      node = normalize_opts(node)

      children =
        case option(node, :children, []) do
          [] -> []
          nested when is_list(nested) -> normalize_hierarchy(nested)
        end

      %{}
      |> maybe_put(:id, option(node, :id))
      |> maybe_put(:label, option(node, :label))
      |> maybe_put(:type, option(node, :type))
      |> maybe_put(:status, option(node, :status))
      |> maybe_put(:restarts, option(node, :restarts))
      |> maybe_put(:children, if(children == [], do: nil, else: children))
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

  defp normalize_map(nil), do: %{}
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp normalize_opts(opts) when is_list(opts), do: Enum.into(opts, %{})
  defp normalize_opts(opts) when is_map(opts), do: Map.new(opts)

  defp option(opts, key, default \\ nil) do
    Map.get(opts, key, Map.get(opts, Atom.to_string(key), default))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
