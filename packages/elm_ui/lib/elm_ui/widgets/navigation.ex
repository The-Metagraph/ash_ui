defmodule ElmUi.Widgets.Navigation do
  @moduledoc """
  Baseline navigation widgets for direct-use `elm_ui` screens.
  """

  alias ElmUi.Widgets.Builder

  @kinds [:context_selector, :file_tree_browser, :menu, :tabs]

  @spec kinds() :: [atom()]
  def kinds, do: @kinds

  @spec menu(String.t() | atom(), [keyword() | map()], keyword() | map()) :: ElmUi.Widget.t()
  def menu(id, items, opts \\ []) when is_list(items) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:menu,
      id: id,
      attributes: %{
        orientation: Builder.option(opts, :orientation, :vertical),
        active_item: Builder.option(opts, :active_item),
        items: normalize_items(items)
      },
      state: Builder.state(opts, [:disabled, :current]),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_navigate: :navigation),
      metadata: Builder.metadata(opts, %{native_surface: :navigation})
    )
  end

  @spec tabs(String.t() | atom(), [keyword() | map()], keyword() | map()) :: ElmUi.Widget.t()
  def tabs(id, items, opts \\ []) when is_list(items) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:tabs,
      id: id,
      attributes: %{
        orientation: Builder.option(opts, :orientation, :horizontal),
        active_item: Builder.option(opts, :active_item),
        items: normalize_items(items)
      },
      state: Builder.state(opts, [:disabled, :current]),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_navigate: :navigation),
      metadata: Builder.metadata(opts, %{native_surface: :navigation})
    )
  end

  @spec context_selector(String.t() | atom(), [keyword() | map()], keyword() | map()) ::
          ElmUi.Widget.t()
  def context_selector(id, groups, opts \\ []) when is_list(groups) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:context_selector,
      id: id,
      attributes: %{
        selector_id: Builder.option(opts, :selector_id, id),
        groups: normalize_groups(groups),
        placeholder: Builder.option(opts, :placeholder, "Select context..."),
        selected_values: Builder.option(opts, :selected_values, []),
        max_selections: Builder.option(opts, :max_selections, 1),
        multiple?: Builder.option(opts, :multiple?, false),
        label_prefix: Builder.option(opts, :label_prefix, "context:")
      },
      state: Builder.state(opts, [:disabled, :open, :selected]),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_select: :selection, on_change: :change),
      metadata: Builder.metadata(opts, %{native_surface: :navigation, role: :listbox})
    )
  end

  @spec file_tree_browser(String.t() | atom(), [keyword() | map()], keyword() | map()) ::
          ElmUi.Widget.t()
  def file_tree_browser(id, nodes, opts \\ []) when is_list(nodes) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:file_tree_browser,
      id: id,
      attributes: %{
        tree_id: Builder.option(opts, :tree_id, id),
        root_label: Builder.option(opts, :root_label, "Files"),
        nodes: normalize_file_tree_nodes(nodes),
        selected_path: Builder.option(opts, :selected_path),
        default_expanded?: Builder.option(opts, :default_expanded?, true)
      },
      state: Builder.state(opts, [:disabled, :selected]),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_select: :selection, on_toggle: :change),
      metadata: Builder.metadata(opts, %{native_surface: :navigation, role: :tree})
    )
  end

  defp normalize_groups(groups) do
    Enum.map(groups, fn group ->
      group = Builder.options(group)

      %{}
      |> Builder.maybe_put(:id, Builder.option(group, :id, Builder.option(group, :group_id)))
      |> Builder.maybe_put(
        :label,
        Builder.option(group, :label, Builder.option(group, :group_label))
      )
      |> Builder.maybe_put(:description, Builder.option(group, :description))
      |> Builder.maybe_put(:items, normalize_items(Builder.option(group, :items, [])))
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
      |> Builder.maybe_put(:disabled, Builder.option(item, :disabled))
      |> Builder.maybe_put(:active, Builder.option(item, :active))
    end)
  end

  defp normalize_file_tree_nodes(nodes) do
    Enum.map(nodes, fn node ->
      node = Builder.options(node)

      %{}
      |> Builder.maybe_put(:id, Builder.option(node, :id))
      |> Builder.maybe_put(:type, Builder.option(node, :type, :file_leaf))
      |> Builder.maybe_put(:name, Builder.option(node, :name))
      |> Builder.maybe_put(:path, Builder.option(node, :path, Builder.option(node, :id)))
      |> Builder.maybe_put(:expanded?, Builder.option(node, :expanded?))
      |> Builder.maybe_put(:file_kind, Builder.option(node, :file_kind))
      |> Builder.maybe_put(:language, Builder.option(node, :language))
      |> Builder.maybe_put(:line_count, Builder.option(node, :line_count))
      |> Builder.maybe_put(
        :children,
        normalize_file_tree_nodes(Builder.option(node, :children, []))
      )
    end)
  end
end
