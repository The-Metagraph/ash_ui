defmodule UnifiedIUR.Widgets.Navigation do
  @moduledoc """
  Canonical constructors for baseline navigation widgets in `UnifiedIUR`.
  """

  alias UnifiedIUR.Attachment
  alias UnifiedIUR.Element
  alias UnifiedIUR.Metadata

  @kinds [:menu, :tabs, :context_selector, :file_tree_browser]

  @spec kinds() :: [atom()]
  def kinds do
    @kinds
  end

  @spec menu([keyword() | map()], keyword() | map()) :: Element.t()
  def menu(items, opts \\ []) when is_list(items) do
    opts = normalize_opts(opts)

    Element.new(:widget, :menu,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          navigation:
            %{}
            |> maybe_put(:orientation, option(opts, :orientation, :vertical))
            |> maybe_put(:active_item, option(opts, :active_item))
            |> maybe_put(:items, normalize_items(items))
        }
        |> Attachment.merge(opts, component: :menu),
      children: []
    )
  end

  @spec tabs([keyword() | map()], keyword() | map()) :: Element.t()
  def tabs(items, opts \\ []) when is_list(items) do
    opts = normalize_opts(opts)

    Element.new(:widget, :tabs,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          navigation:
            %{}
            |> maybe_put(:orientation, option(opts, :orientation, :horizontal))
            |> maybe_put(:active_item, option(opts, :active_item))
            |> maybe_put(:items, normalize_items(items))
        }
        |> Attachment.merge(opts, component: :tabs),
      children: []
    )
  end

  @spec context_selector(keyword() | map()) :: Element.t()
  def context_selector(opts \\ []) do
    opts = normalize_opts(opts)

    selector_id =
      normalize_required_string!(option(opts, :selector_id, option(opts, :id)), :selector_id)

    max_selections = normalize_max_selections!(option(opts, :max_selections, 1))

    Element.new(:widget, :context_selector,
      id: option(opts, :id, selector_id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          context_selector:
            %{
              selector_id: selector_id,
              groups: normalize_context_groups!(option(opts, :groups, [])),
              placeholder: option(opts, :placeholder, "Select context..."),
              selected_values: normalize_selected_values!(option(opts, :selected_values, [])),
              max_selections: max_selections,
              multiple?: multiple_selection?(max_selections),
              label_prefix: option(opts, :label_prefix, "context:"),
              open?: option(opts, :open?, false),
              disabled?: option(opts, :disabled?, false)
            }
            |> maybe_put(:selection_intent, option(opts, :selection_intent))
        }
        |> Attachment.merge(opts, component: :context_selector),
      children: []
    )
  end

  @spec file_tree_browser(keyword() | map()) :: Element.t()
  def file_tree_browser(opts \\ []) do
    opts = normalize_opts(opts)

    tree_id =
      normalize_file_tree_string!(option(opts, :tree_id, option(opts, :id)), :tree_id)

    selected_path = option(opts, :selected_path)

    if not is_nil(selected_path) and not is_binary(selected_path) do
      raise ArgumentError, "file_tree_browser :selected_path must be a string when provided"
    end

    default_expanded? =
      normalize_file_tree_boolean!(
        option(opts, :default_expanded?, option(opts, :default_expanded, true)),
        :default_expanded?
      )

    Element.new(:widget, :file_tree_browser,
      id: option(opts, :id, tree_id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          file_tree:
            %{
              tree_id: tree_id,
              root_label: option(opts, :root_label, option(opts, :label, "")),
              nodes: normalize_file_tree_nodes!(option(opts, :nodes, [])),
              default_expanded?: default_expanded?
            }
            |> maybe_put(:selected_path, selected_path)
            |> maybe_put(:selection_intent, option(opts, :selection_intent))
            |> maybe_put(:toggle_intent, option(opts, :toggle_intent))
        }
        |> Attachment.merge(opts, component: :file_tree_browser),
      children: []
    )
  end

  defp normalize_items(items) do
    Enum.map(items, fn item ->
      item = normalize_opts(item)

      count = option(item, :count)

      unless is_nil(count) or (is_integer(count) and count >= 0) do
        raise ArgumentError,
              "tabs item :count must be a non-negative integer or nil, got #{inspect(count)}"
      end

      %{}
      |> maybe_put(:id, option(item, :id))
      |> maybe_put(:label, option(item, :label))
      |> maybe_put(:value, option(item, :value))
      |> maybe_put(:description, option(item, :description))
      |> maybe_put(:disabled?, option(item, :disabled?))
      |> maybe_put(:active?, option(item, :active?))
      |> maybe_put(:count, count)
    end)
  end

  defp normalize_context_groups!(groups) when is_list(groups) do
    Enum.map(groups, &normalize_context_group!/1)
  end

  defp normalize_context_groups!(_groups) do
    raise ArgumentError, "context_selector :groups must be a list"
  end

  defp normalize_context_group!(group) when is_map(group) or is_list(group) do
    group = normalize_opts(group)
    id = normalize_required_string!(option(group, :id, option(group, :group_id)), :group_id)

    label =
      normalize_required_string!(option(group, :label, option(group, :group_label)), :group_label)

    %{
      id: id,
      label: label,
      items: normalize_context_items!(option(group, :items, []))
    }
    |> maybe_put(:description, option(group, :description))
    |> maybe_put(:metadata, option(group, :metadata))
  end

  defp normalize_context_group!(_group) do
    raise ArgumentError, "context_selector groups must be maps"
  end

  defp normalize_context_items!(items) when is_list(items) do
    Enum.map(items, &normalize_context_item!/1)
  end

  defp normalize_context_items!(_items) do
    raise ArgumentError, "context_selector group :items must be a list"
  end

  defp normalize_context_item!(item) when is_map(item) or is_list(item) do
    item = normalize_opts(item)
    value = option(item, :value)

    if is_nil(value) do
      raise ArgumentError, "context_selector items require a :value"
    end

    %{
      id: option(item, :id, value),
      value: value,
      label: option(item, :label, to_string(value))
    }
    |> maybe_put(:description, option(item, :description))
    |> maybe_put(:selected?, option(item, :selected?))
    |> maybe_put(:disabled?, option(item, :disabled?))
    |> maybe_put(:metadata, option(item, :metadata))
  end

  defp normalize_context_item!(_item) do
    raise ArgumentError, "context_selector items must be maps"
  end

  defp normalize_required_string!(value, field) when is_binary(value) do
    if String.trim(value) == "" do
      raise ArgumentError, "context_selector requires a non-empty :#{field}"
    end

    value
  end

  defp normalize_required_string!(value, field) when is_atom(value) and not is_nil(value),
    do: normalize_required_string!(Atom.to_string(value), field)

  defp normalize_required_string!(_value, field) do
    raise ArgumentError, "context_selector requires a non-empty :#{field}"
  end

  defp normalize_selected_values!(values) when is_list(values), do: values

  defp normalize_selected_values!(_values) do
    raise ArgumentError, "context_selector :selected_values must be a list"
  end

  defp normalize_max_selections!(:unlimited), do: :unlimited
  defp normalize_max_selections!("unlimited"), do: :unlimited
  defp normalize_max_selections!(value) when is_integer(value) and value >= 1, do: value

  defp normalize_max_selections!(_value) do
    raise ArgumentError,
          "context_selector :max_selections must be a positive integer or :unlimited"
  end

  defp multiple_selection?(:unlimited), do: true
  defp multiple_selection?(value) when is_integer(value), do: value > 1

  defp normalize_file_tree_nodes!(nodes) when is_list(nodes) do
    Enum.map(nodes, &normalize_file_tree_node!/1)
  end

  defp normalize_file_tree_nodes!(_nodes) do
    raise ArgumentError, "file_tree_browser :nodes must be a list"
  end

  defp normalize_file_tree_node!(node) when is_map(node) or is_list(node) do
    node = normalize_opts(node)

    case normalize_file_tree_node_type!(option(node, :type)) do
      :folder -> normalize_file_tree_folder!(node)
      :file_leaf -> normalize_file_tree_leaf!(node)
    end
  end

  defp normalize_file_tree_node!(_node) do
    raise ArgumentError, "file_tree_browser nodes must be maps"
  end

  defp normalize_file_tree_folder!(node) do
    path = normalize_file_tree_string!(option(node, :path, option(node, :id)), :path)
    id = normalize_file_tree_string!(option(node, :id, path), :id)

    %{
      id: id,
      type: :folder,
      name: option(node, :name, Path.basename(path)),
      path: path,
      children: normalize_file_tree_nodes!(option(node, :children, []))
    }
    |> maybe_put(:expanded?, normalize_optional_file_tree_boolean!(option(node, :expanded?)))
  end

  defp normalize_file_tree_leaf!(node) do
    path = normalize_file_tree_string!(option(node, :path, option(node, :id)), :path)
    id = normalize_file_tree_string!(option(node, :id, path), :id)

    %{
      id: id,
      type: :file_leaf,
      name: option(node, :name, Path.basename(path)),
      path: path
    }
    |> maybe_put(:file_kind, option(node, :file_kind, option(node, :kind)))
    |> maybe_put(:language, option(node, :language, option(node, :lang)))
    |> maybe_put(
      :line_count,
      normalize_optional_line_count!(option(node, :line_count, option(node, :lines)))
    )
  end

  defp normalize_file_tree_node_type!(:folder), do: :folder
  defp normalize_file_tree_node_type!("folder"), do: :folder
  defp normalize_file_tree_node_type!(:directory), do: :folder
  defp normalize_file_tree_node_type!("directory"), do: :folder
  defp normalize_file_tree_node_type!(:file_leaf), do: :file_leaf
  defp normalize_file_tree_node_type!("file_leaf"), do: :file_leaf
  defp normalize_file_tree_node_type!(:file), do: :file_leaf
  defp normalize_file_tree_node_type!("file"), do: :file_leaf

  defp normalize_file_tree_node_type!(type) do
    raise ArgumentError,
          "file_tree_browser node type must be :folder or :file_leaf, got: #{inspect(type)}"
  end

  defp normalize_file_tree_string!(value, field) when is_binary(value) do
    if String.trim(value) == "" do
      raise ArgumentError, "file_tree_browser requires a non-empty :#{field}"
    end

    value
  end

  defp normalize_file_tree_string!(value, field) when is_atom(value) and not is_nil(value),
    do: normalize_file_tree_string!(Atom.to_string(value), field)

  defp normalize_file_tree_string!(_value, field) do
    raise ArgumentError, "file_tree_browser requires a non-empty :#{field}"
  end

  defp normalize_file_tree_boolean!(value, _field) when is_boolean(value), do: value

  defp normalize_file_tree_boolean!(value, field) do
    raise ArgumentError, "file_tree_browser :#{field} must be a boolean, got: #{inspect(value)}"
  end

  defp normalize_optional_file_tree_boolean!(nil), do: nil
  defp normalize_optional_file_tree_boolean!(value) when is_boolean(value), do: value

  defp normalize_optional_file_tree_boolean!(value) do
    raise ArgumentError,
          "file_tree_browser node :expanded? must be a boolean when provided, got: #{inspect(value)}"
  end

  defp normalize_optional_line_count!(nil), do: nil
  defp normalize_optional_line_count!(value) when is_integer(value) and value >= 0, do: value

  defp normalize_optional_line_count!(value) do
    raise ArgumentError,
          "file_tree_browser node :line_count must be a non-negative integer when provided, got: #{inspect(value)}"
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
