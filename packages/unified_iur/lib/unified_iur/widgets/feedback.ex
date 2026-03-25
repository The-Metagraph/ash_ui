defmodule UnifiedIUR.Widgets.Feedback do
  @moduledoc """
  Canonical constructors for baseline feedback, status, and progress widgets in
  `UnifiedIUR`.
  """

  alias UnifiedIUR.Attachment
  alias UnifiedIUR.Element
  alias UnifiedIUR.Metadata

  @kinds [:status, :progress, :gauge, :inline_feedback]

  @spec kinds() :: [atom()]
  def kinds do
    @kinds
  end

  @spec status(String.t(), keyword() | map()) :: Element.t()
  def status(text, opts \\ []) when is_binary(text) do
    opts = normalize_opts(opts)

    Element.new(:widget, :status,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          feedback:
            %{}
            |> maybe_put(:text, text)
            |> maybe_put(:severity, option(opts, :severity, :info))
            |> maybe_put(:status, option(opts, :status, :idle))
        }
        |> Attachment.merge(opts, component: :status),
      children: []
    )
  end

  @spec progress(keyword() | map()) :: Element.t()
  def progress(opts \\ []) do
    opts = normalize_opts(opts)

    Element.new(:widget, :progress,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          progress:
            %{}
            |> maybe_put(:current, option(opts, :current))
            |> maybe_put(:total, option(opts, :total))
            |> maybe_put(:indeterminate?, option(opts, :indeterminate?, false))
            |> maybe_put(:label, option(opts, :label)),
          feedback:
            %{}
            |> maybe_put(:severity, option(opts, :severity))
            |> maybe_put(:status, option(opts, :status))
        }
        |> Attachment.merge(opts, component: :progress),
      children: []
    )
  end

  @spec gauge(keyword() | map()) :: Element.t()
  def gauge(opts \\ []) do
    opts = normalize_opts(opts)

    Element.new(:widget, :gauge,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          gauge:
            %{}
            |> maybe_put(:value, option(opts, :value))
            |> maybe_put(:min, option(opts, :min, 0))
            |> maybe_put(:max, option(opts, :max, 100))
            |> maybe_put(:label, option(opts, :label)),
          feedback:
            %{}
            |> maybe_put(:severity, option(opts, :severity))
            |> maybe_put(:status, option(opts, :status))
        }
        |> Attachment.merge(opts, component: :gauge),
      children: []
    )
  end

  @spec inline_feedback(String.t(), keyword() | map()) :: Element.t()
  def inline_feedback(message, opts \\ []) when is_binary(message) do
    opts = normalize_opts(opts)

    Element.new(:widget, :inline_feedback,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          feedback:
            %{}
            |> maybe_put(:title, option(opts, :title))
            |> maybe_put(:message, message)
            |> maybe_put(:severity, option(opts, :severity, :info))
            |> maybe_put(:status, option(opts, :status))
        }
        |> Attachment.merge(opts, component: :inline_feedback),
      children: []
    )
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
