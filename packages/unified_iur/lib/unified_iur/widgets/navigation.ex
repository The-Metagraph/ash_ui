defmodule UnifiedIUR.Widgets.Navigation do
  @moduledoc """
  Canonical constructors for baseline navigation widgets in `UnifiedIUR`.
  """

  alias UnifiedIUR.Attachment
  alias UnifiedIUR.Element
  alias UnifiedIUR.Metadata

  @kinds [:menu, :tabs, :context_selector]

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

  defp normalize_items(items) do
    Enum.map(items, fn item ->
      item = normalize_opts(item)

      %{}
      |> maybe_put(:id, option(item, :id))
      |> maybe_put(:label, option(item, :label))
      |> maybe_put(:value, option(item, :value))
      |> maybe_put(:description, option(item, :description))
      |> maybe_put(:disabled?, option(item, :disabled?))
      |> maybe_put(:active?, option(item, :active?))
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
