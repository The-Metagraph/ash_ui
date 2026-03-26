defmodule UnifiedIUR.Metadata do
  @moduledoc """
  Canonical metadata and annotation container for `UnifiedIUR.Element` values.

  Metadata remains renderer-independent and carries authored traceability,
  descriptive annotations, tags, and forward-compatible extension data.
  """

  @type annotation_key :: atom() | String.t()
  @type annotation_value :: term()
  @type authored_ref :: term() | nil

  @type t :: %__MODULE__{
          authored_ref: authored_ref(),
          description: String.t() | nil,
          annotations: %{optional(annotation_key()) => annotation_value()},
          tags: [atom() | String.t()],
          extra: map()
        }

  defstruct authored_ref: nil,
            description: nil,
            annotations: %{},
            tags: [],
            extra: %{}

  @spec new(keyword() | map() | t() | nil) :: t()
  def new(nil), do: %__MODULE__{}

  def new(%__MODULE__{} = metadata) do
    %__MODULE__{
      authored_ref: metadata.authored_ref,
      description: metadata.description,
      annotations: normalize_map(metadata.annotations),
      tags: normalize_tags(metadata.tags),
      extra: normalize_map(metadata.extra)
    }
  end

  def new(metadata) when is_list(metadata) do
    metadata |> Enum.into(%{}) |> new()
  end

  def new(metadata) when is_map(metadata) do
    %__MODULE__{
      authored_ref: fetch(metadata, :authored_ref),
      description: fetch(metadata, :description),
      annotations: metadata |> fetch(:annotations, %{}) |> normalize_map(),
      tags: metadata |> fetch(:tags, []) |> normalize_tags(),
      extra: metadata |> fetch(:extra, %{}) |> normalize_map()
    }
  end

  @spec merge(t() | map() | keyword() | nil, t() | map() | keyword() | nil) :: t()
  def merge(left, right) do
    left = new(left)
    right = new(right)

    %__MODULE__{
      authored_ref: right.authored_ref || left.authored_ref,
      description: right.description || left.description,
      annotations: Map.merge(left.annotations, right.annotations),
      tags: Enum.uniq(left.tags ++ right.tags),
      extra: Map.merge(left.extra, right.extra)
    }
  end

  @spec put_annotation(t() | map() | keyword() | nil, annotation_key(), annotation_value()) :: t()
  def put_annotation(metadata, key, value) do
    metadata = new(metadata)
    %{metadata | annotations: Map.put(metadata.annotations, key, value)}
  end

  @spec put_extra(t() | map() | keyword() | nil, term(), term()) :: t()
  def put_extra(metadata, key, value) do
    metadata = new(metadata)
    %{metadata | extra: Map.put(metadata.extra, key, value)}
  end

  defp fetch(source, key, default \\ nil) do
    Map.get(source, key, Map.get(source, Atom.to_string(key), default))
  end

  defp normalize_map(nil), do: %{}
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp normalize_tags(nil), do: []

  defp normalize_tags(tags) when is_list(tags) do
    tags
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end
end
