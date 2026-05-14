defmodule DesktopUi.Widgets.Operational do
  @moduledoc """
  Advanced operational and diagnostic widgets for direct-native `desktop_ui`.
  """

  alias DesktopUi.Widget

  @spec kinds() :: [atom()]
  def kinds do
    [:cluster_dashboard, :command_palette, :log_viewer, :process_monitor, :stream_widget,
     :supervision_tree_viewer, :window_command]
  end

  @spec stream_widget(String.t() | atom(), keyword()) :: Widget.t()
  def stream_widget(id, opts \\ []) do
    Widget.new(:stream_widget,
      id: id,
      metadata:
        metadata(opts,
          focusable: true,
          role: :stream_widget
        ),
      state:
        state(opts,
          streaming: Keyword.get(opts, :streaming, true),
          paused: Keyword.get(opts, :paused, false),
          line_limit: Keyword.get(opts, :line_limit, 1000)
        ),
      attributes: %{
        entries: normalize_items(Keyword.get(opts, :entries, [])),
        follow: Keyword.get(opts, :follow, true),
        filter: Keyword.get(opts, :filter),
        level: Keyword.get(opts, :level)
      },
      events:
        events(
          pause: Keyword.get(opts, :on_pause),
          resume: Keyword.get(opts, :on_resume),
          clear: Keyword.get(opts, :on_clear),
          filter: Keyword.get(opts, :on_filter)
        ),
      styles: styles(opts)
    )
  end

  @spec supervision_tree_viewer(String.t() | atom(), keyword()) :: Widget.t()
  def supervision_tree_viewer(id, opts \\ []) do
    Widget.new(:supervision_tree_viewer,
      id: id,
      metadata:
        metadata(opts,
          focusable: true,
          role: :supervision_tree_viewer
        ),
      state:
        state(opts,
          expanded: Keyword.get(opts, :expanded, []),
          selected: Keyword.get(opts, :selected)
        ),
      bindings:
        bindings(
          selection: Keyword.get(opts, :selection_binding, Keyword.get(opts, :binding)),
          expansion: Keyword.get(opts, :expansion_binding)
        ),
      attributes: %{
        tree: normalize_items(Keyword.get(opts, :tree, [])),
        query: Keyword.get(opts, :query),
        show_children: Keyword.get(opts, :show_children, true),
        application: Keyword.get(opts, :application)
      },
      events:
        events(
          select: Keyword.get(opts, :on_select),
          expand: Keyword.get(opts, :on_expand),
          collapse: Keyword.get(opts, :on_collapse),
          refresh: Keyword.get(opts, :on_refresh)
        ),
      styles: styles(opts)
    )
  end

  @spec log_viewer(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def log_viewer(id, entries, opts \\ []) do
    Widget.new(:log_viewer,
      id: id,
      metadata:
        metadata(opts,
          focusable: true,
          role: :log_viewer,
          interaction_route: Keyword.get(opts, :interaction_route, :window_local)
        ),
      state:
        state(opts,
          streaming: Keyword.get(opts, :streaming, false),
          paused: Keyword.get(opts, :paused, false)
        ),
      bindings:
        bindings(
          filters: Keyword.get(opts, :filters_binding),
          query: Keyword.get(opts, :query_binding)
        ),
      attributes: %{
        entries: normalize_items(entries),
        follow: Keyword.get(opts, :follow, false),
        query: Keyword.get(opts, :query)
      },
      events:
        events(filter: Keyword.get(opts, :on_filter), paginate: Keyword.get(opts, :on_paginate)),
      styles: styles(opts)
    )
  end

  @spec cluster_dashboard(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def cluster_dashboard(id, nodes, opts \\ []) do
    Widget.new(:cluster_dashboard,
      id: id,
      metadata:
        metadata(opts,
          role: :cluster_dashboard,
          window_identity: Keyword.get(opts, :window_identity)
        ),
      state:
        state(opts,
          loading: Keyword.get(opts, :loading, false),
          severity: Keyword.get(opts, :severity)
        ),
      attributes: %{nodes: normalize_items(nodes), summary: Keyword.get(opts, :summary, %{})},
      styles: styles(opts)
    )
  end

  @spec command_palette(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def command_palette(id, commands, opts \\ []) do
    Widget.new(:command_palette,
      id: id,
      metadata:
        metadata(opts,
          focusable: true,
          role: :command_palette,
          interaction_route: Keyword.get(opts, :interaction_route, :multi_window),
          window_identity: Keyword.get(opts, :window_identity)
        ),
      state:
        state(opts, open: Keyword.get(opts, :open, false), current: Keyword.get(opts, :current)),
      bindings: bindings(query: Keyword.get(opts, :query_binding, Keyword.get(opts, :binding))),
      attributes: %{commands: normalize_items(commands), query: Keyword.get(opts, :query)},
      events:
        events(
          change: Keyword.get(opts, :on_change),
          command: Keyword.get(opts, :on_command),
          selection: Keyword.get(opts, :on_select)
        ),
      styles: styles(opts)
    )
  end

  @spec process_monitor(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def process_monitor(id, processes, opts \\ []) do
    Widget.new(:process_monitor,
      id: id,
      metadata:
        metadata(opts,
          focusable: true,
          role: :process_monitor,
          window_identity: Keyword.get(opts, :window_identity)
        ),
      state:
        state(opts,
          loading: Keyword.get(opts, :loading, false),
          selected: Keyword.get(opts, :selected)
        ),
      bindings:
        bindings(selection: Keyword.get(opts, :selection_binding, Keyword.get(opts, :binding))),
      attributes: %{processes: normalize_items(processes), sort_by: Keyword.get(opts, :sort_by)},
      events:
        events(
          sort: Keyword.get(opts, :on_sort),
          filter: Keyword.get(opts, :on_filter),
          selection: Keyword.get(opts, :on_select)
        ),
      styles: styles(opts)
    )
  end

  @spec window_command(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def window_command(id, label, opts \\ []) do
    Widget.new(:window_command,
      id: id,
      metadata:
        metadata(opts,
          focusable: true,
          role: :window_command,
          window_identity: Keyword.get(opts, :window_identity),
          interaction_route: Keyword.get(opts, :interaction_route, :multi_window)
        ),
      state: state(opts),
      attributes: %{label: label},
      events:
        events(
          command:
            Keyword.get(opts, :on_command, %{intent: Keyword.get(opts, :intent, :window_command)})
        ),
      styles: styles(opts)
    )
  end

  defp metadata(opts, defaults),
    do: defaults |> Keyword.merge(Keyword.get(opts, :metadata, [])) |> Map.new()

  defp state(opts, defaults \\ []),
    do:
      defaults
      |> Keyword.merge(disabled: Keyword.get(opts, :disabled, false), focused: false)
      |> Map.new()

  defp bindings(entries), do: entries |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()
  defp events(entries), do: entries |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()
  defp styles(opts), do: Map.new(Keyword.get(opts, :styles, []))
  defp normalize_items(items), do: Enum.map(List.wrap(items), &normalize_item/1)
  defp normalize_item(item) when is_list(item), do: Enum.into(item, %{})
  defp normalize_item(item) when is_map(item), do: Map.new(item)
end
