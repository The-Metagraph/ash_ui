defmodule UnifiedIUR.Container do
  @moduledoc """
  Canonical content-container constructors for foundational `UnifiedIUR`
  widget composition.
  """

  alias UnifiedIUR.Attachment
  alias UnifiedIUR.Element
  alias UnifiedIUR.Element.Child
  alias UnifiedIUR.Widgets.Foundational

  @type child_input ::
          Child.t()
          | Element.t()
          | {Child.slot(), Element.t() | nil}
          | %{required(:slot) => Child.slot(), required(:element) => Element.t() | nil}
          | %{required(String.t()) => term()}

  @spec content([child_input()] | keyword(Element.t() | nil), keyword() | map()) :: Element.t()
  def content(children \\ [], opts \\ []) do
    Foundational.content(children, opts)
  end

  @spec box([child_input()], keyword() | map()) :: Element.t()
  def box(children \\ [], opts \\ []) when is_list(children) do
    opts = normalize_opts(opts)

    Element.new(:layout, :box,
      id: option(opts, :id),
      metadata: option(opts, :metadata),
      attributes:
        %{
          container:
            %{}
            |> maybe_put(:padding, option(opts, :padding))
            |> maybe_put(:margin, option(opts, :margin))
            |> maybe_put(:border, option(opts, :border))
            |> maybe_put(:background, option(opts, :background))
            |> maybe_put(:clip?, option(opts, :clip?)),
          layout:
            %{}
            |> maybe_put(:gap, option(opts, :gap))
            |> maybe_put(:align, option(opts, :align))
            |> maybe_put(:justify, option(opts, :justify))
            |> maybe_put(:width, option(opts, :width))
            |> maybe_put(:height, option(opts, :height))
            |> maybe_put(:min_width, option(opts, :min_width))
            |> maybe_put(:max_width, option(opts, :max_width))
            |> maybe_put(:min_height, option(opts, :min_height))
            |> maybe_put(:max_height, option(opts, :max_height))
        }
        |> Attachment.merge(opts, component: :box),
      children: children
    )
  end

  defp normalize_opts(opts) when is_list(opts), do: Enum.into(opts, %{})
  defp normalize_opts(opts) when is_map(opts), do: Map.new(opts)

  defp option(opts, key, default \\ nil) do
    Map.get(opts, key, Map.get(opts, Atom.to_string(key), default))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
