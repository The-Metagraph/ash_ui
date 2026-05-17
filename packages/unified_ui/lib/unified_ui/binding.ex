defmodule UnifiedUi.Binding do
  @moduledoc """
  Canonical authored binding declarations for `UnifiedUi`.
  """

  @type path_segment :: atom() | String.t()

  @type ref_t :: %{
          kind: :binding_ref,
          id: atom() | String.t()
        }

  @type t :: %__MODULE__{
          __identifier__: atom() | nil,
          __spark_metadata__: term(),
          id: atom() | nil,
          path: [path_segment()],
          scope: [path_segment()],
          default: term(),
          format: atom() | String.t() | nil,
          source: atom() | String.t() | nil,
          collection?: boolean(),
          depends_on: [ref_t()],
          derived: map(),
          summary: String.t() | nil,
          metadata: map()
        }

  defstruct __identifier__: nil,
            __spark_metadata__: nil,
            id: nil,
            path: [],
            scope: [],
            default: nil,
            format: nil,
            source: nil,
            collection?: false,
            depends_on: [],
            derived: %{},
            summary: nil,
            metadata: %{}

  @spec new(keyword() | map() | t()) :: t()
  def new(%__MODULE__{} = binding), do: normalize(binding)
  def new(binding) when is_list(binding), do: binding |> Enum.into(%{}) |> new()

  def new(binding) when is_map(binding) do
    %__MODULE__{
      id: fetch(binding, :id),
      path: binding |> fetch(:path, []) |> normalize_path(),
      scope: binding |> fetch(:scope, []) |> normalize_path(),
      default: fetch(binding, :default),
      format: fetch(binding, :format),
      source: fetch(binding, :source),
      collection?: fetch(binding, :collection?, false),
      depends_on: binding |> fetch(:depends_on, []) |> normalize_refs(),
      derived: binding |> fetch(:derived, %{}) |> normalize_map(),
      summary: fetch(binding, :summary),
      metadata: binding |> fetch(:metadata, %{}) |> normalize_map()
    }
  end

  @spec ref(atom() | String.t()) :: ref_t()
  def ref(id) when is_atom(id) or is_binary(id), do: %{kind: :binding_ref, id: id}

  @spec reference?(term()) :: boolean()
  def reference?(%{kind: :binding_ref, id: id}) when is_atom(id) or is_binary(id), do: true

  def reference?(%{"kind" => :binding_ref, "id" => id}) when is_atom(id) or is_binary(id),
    do: true

  def reference?(_other), do: false

  @spec summary(t() | keyword() | map()) :: map()
  def summary(binding) do
    binding = new(binding)

    %{
      id: binding.id,
      path: binding.path,
      scope: binding.scope,
      default: binding.default,
      format: binding.format,
      source: binding.source,
      collection?: binding.collection?,
      depends_on: binding.depends_on,
      derived: binding.derived,
      summary: binding.summary,
      metadata: binding.metadata
    }
    |> Enum.reject(fn {_key, value} -> value in [nil, [], %{}] end)
    |> Enum.into(%{})
  end

  defp normalize(%__MODULE__{} = binding) do
    %__MODULE__{
      binding
      | path: normalize_path(binding.path),
        scope: normalize_path(binding.scope),
        depends_on: normalize_refs(binding.depends_on),
        derived: normalize_map(binding.derived),
        metadata: normalize_map(binding.metadata)
    }
  end

  defp normalize_refs(refs) do
    refs
    |> List.wrap()
    |> Enum.map(fn
      %{kind: :binding_ref, id: id} when is_atom(id) or is_binary(id) ->
        ref(id)

      %{"kind" => :binding_ref, "id" => id} when is_atom(id) or is_binary(id) ->
        ref(id)

      id when is_atom(id) or is_binary(id) ->
        ref(id)
    end)
  end

  defp normalize_path(nil), do: []
  defp normalize_path(path) when is_atom(path) or is_binary(path), do: [path]
  defp normalize_path(path) when is_list(path), do: path

  defp normalize_map(nil), do: %{}
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp fetch(source, key, default \\ nil) do
    Map.get(source, key, Map.get(source, Atom.to_string(key), default))
  end
end
