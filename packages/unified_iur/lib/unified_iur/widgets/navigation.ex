defmodule UnifiedIUR.Widgets.Navigation do
  @moduledoc """
  Canonical constructors for baseline navigation widgets in `UnifiedIUR`.
  """

  alias UnifiedIUR.Attachment
  alias UnifiedIUR.Element
  alias UnifiedIUR.Metadata

  @kinds [:menu, :tabs]

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
