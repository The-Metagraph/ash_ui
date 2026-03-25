defmodule UnifiedIUR.Layer do
  @moduledoc """
  Canonical layering and overlay constructors for `UnifiedIUR`.
  """

  alias UnifiedIUR.Attachment
  alias UnifiedIUR.Element
  alias UnifiedIUR.Element.Child
  alias UnifiedIUR.Metadata
  alias UnifiedIUR.Widgets.Navigation

  @type opts :: keyword() | map()

  @kinds [:overlay, :dialog, :toast, :alert_dialog, :context_menu]

  @spec kinds() :: [atom()]
  def kinds do
    @kinds
  end

  @spec overlay(
          Element.t(),
          [Child.t() | Element.t() | {Child.slot(), Element.t() | nil} | map()],
          opts()
        ) ::
          Element.t()
  def overlay(%Element{} = base, layers, opts \\ []) when is_list(layers) do
    opts = normalize_opts(opts)

    Element.new(:layer, :overlay,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          overlay:
            %{}
            |> maybe_put(:mode, option(opts, :mode, :stacked))
            |> maybe_put(:background_fill, option(opts, :background_fill, :transparent))
            |> maybe_put(:dismissible?, option(opts, :dismissible?))
            |> maybe_put(:focus_scope, option(opts, :focus_scope))
        }
        |> Attachment.merge(opts, component: :overlay),
      children: [Child.new(:base, base) | normalize_layer_children(layers)]
    )
  end

  @spec dialog(Element.t(), opts()) :: Element.t()
  def dialog(%Element{} = content, opts \\ []) do
    opts = normalize_opts(opts)

    Element.new(:layer, :dialog,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          dialog:
            %{}
            |> maybe_put(:title, option(opts, :title))
            |> maybe_put(:modal?, option(opts, :modal?, true))
            |> maybe_put(:dismissible?, option(opts, :dismissible?, true))
            |> maybe_put(:size, option(opts, :size, :md))
            |> maybe_put(:background_fill, option(opts, :background_fill, :scrim))
            |> maybe_put(:focus_scope, option(opts, :focus_scope, :dialog))
        }
        |> Attachment.merge(opts, component: :dialog),
      children: [Child.new(:content, content)]
    )
  end

  @spec toast(Element.t(), opts()) :: Element.t()
  def toast(%Element{} = content, opts \\ []) do
    opts = normalize_opts(opts)

    Element.new(:layer, :toast,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          toast:
            %{}
            |> maybe_put(:placement, option(opts, :placement, :top_end))
            |> maybe_put(:duration_ms, option(opts, :duration_ms, 5000))
            |> maybe_put(:severity, option(opts, :severity, :info))
            |> maybe_put(:transient?, option(opts, :transient?, true))
        }
        |> Attachment.merge(opts, component: :toast),
      children: [Child.new(:content, content)]
    )
  end

  @spec alert_dialog(Element.t(), opts()) :: Element.t()
  def alert_dialog(%Element{} = content, opts \\ []) do
    opts = normalize_opts(opts)

    Element.new(:layer, :alert_dialog,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          alert_dialog:
            %{}
            |> maybe_put(:title, option(opts, :title))
            |> maybe_put(:severity, option(opts, :severity, :warning))
            |> maybe_put(:requires_confirmation?, option(opts, :requires_confirmation?, true))
            |> maybe_put(:background_fill, option(opts, :background_fill, :scrim))
            |> maybe_put(:focus_scope, option(opts, :focus_scope, :alert_dialog))
        }
        |> Attachment.merge(opts, component: :alert_dialog),
      children: [Child.new(:content, content)]
    )
  end

  @spec context_menu([keyword() | map()], opts()) :: Element.t()
  def context_menu(items, opts \\ []) when is_list(items) do
    opts = normalize_opts(opts)

    menu =
      Navigation.menu(items,
        id: option(opts, :menu_id),
        orientation: :vertical,
        active_item: option(opts, :active_item)
      )

    Element.new(:layer, :context_menu,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          context_menu:
            %{}
            |> maybe_put(:anchor, normalize_map(option(opts, :anchor, %{})))
            |> maybe_put(:placement, option(opts, :placement, :bottom_start))
            |> maybe_put(:dismissible?, option(opts, :dismissible?, true))
            |> maybe_put(:background_fill, option(opts, :background_fill, :none))
        }
        |> Attachment.merge(opts, component: :context_menu),
      children: [Child.new(:menu, menu)]
    )
  end

  defp normalize_layer_children(children) do
    Enum.map(children, &normalize_child/1)
  end

  defp normalize_child(%Child{} = child), do: child
  defp normalize_child(%Element{} = element), do: Child.new(:overlay, element)

  defp normalize_child({slot, %Element{} = element}) when is_atom(slot) or is_binary(slot),
    do: Child.new(slot, element)

  defp normalize_child(%{slot: slot, element: %Element{} = element})
       when is_atom(slot) or is_binary(slot) do
    Child.new(slot, element)
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
