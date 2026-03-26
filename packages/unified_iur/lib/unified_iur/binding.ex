defmodule UnifiedIUR.Binding do
  @moduledoc """
  Canonical binding and dependency references for `UnifiedIUR`.
  """

  @type path_segment :: atom() | String.t()
  @type t :: %__MODULE__{
          name: atom() | String.t() | nil,
          path: [path_segment()],
          scope: [path_segment()],
          value: term(),
          default: term(),
          format: atom() | String.t() | nil,
          source: atom() | String.t() | nil,
          collection?: boolean(),
          depends_on: [dependency_reference()],
          derived: map(),
          metadata: map()
        }

  @type dependency_reference :: %{
          optional(:scope) => [path_segment()],
          optional(:format) => atom() | String.t(),
          optional(:source) => atom() | String.t(),
          path: [path_segment()]
        }

  defstruct name: nil,
            path: [],
            scope: [],
            value: nil,
            default: nil,
            format: nil,
            source: nil,
            collection?: false,
            depends_on: [],
            derived: %{},
            metadata: %{}

  @spec new(keyword() | map() | t() | nil) :: t()
  def new(nil), do: %__MODULE__{}
  def new(%__MODULE__{} = binding), do: normalize(binding)
  def new(binding) when is_list(binding), do: binding |> Enum.into(%{}) |> new()
  def new(binding) when is_map(binding), do: binding |> struct_from_map() |> normalize()

  @spec reference([path_segment()] | path_segment(), keyword() | map()) ::
          dependency_reference()
  def reference(path, opts \\ []) do
    opts = normalize_map(opts)

    %{}
    |> Map.put(:path, normalize_path(path))
    |> maybe_put(:scope, normalize_optional_path(fetch(opts, :scope)))
    |> maybe_put(:format, fetch(opts, :format))
    |> maybe_put(:source, fetch(opts, :source))
  end

  @spec put_dependency(
          t() | keyword() | map() | nil,
          dependency_reference() | [path_segment()] | path_segment(),
          keyword() | map()
        ) :: t()
  def put_dependency(binding, dependency, opts \\ []) do
    binding = new(binding)

    reference =
      case dependency do
        %{path: _path} = reference -> normalize_reference(reference)
        %{"path" => _path} = reference -> normalize_reference(reference)
        path -> reference(path, opts)
      end

    %{binding | depends_on: binding.depends_on ++ [reference]}
  end

  @spec put_derived(t() | keyword() | map() | nil, atom() | String.t(), term()) :: t()
  def put_derived(binding, key, value) do
    binding = new(binding)
    %{binding | derived: Map.put(binding.derived, key, value)}
  end

  defp struct_from_map(binding) do
    %__MODULE__{
      name: fetch(binding, :name),
      path: normalize_path(fetch(binding, :path, [])),
      scope: normalize_path(fetch(binding, :scope, [])),
      value: fetch(binding, :value),
      default: fetch(binding, :default),
      format: fetch(binding, :format),
      source: fetch(binding, :source),
      collection?: fetch(binding, :collection?, false),
      depends_on: fetch(binding, :depends_on, []),
      derived: normalize_map(fetch(binding, :derived, %{})),
      metadata: normalize_map(fetch(binding, :metadata, %{}))
    }
  end

  defp normalize(%__MODULE__{} = binding) do
    %__MODULE__{
      name: binding.name,
      path: normalize_path(binding.path),
      scope: normalize_path(binding.scope),
      value: binding.value,
      default: binding.default,
      format: binding.format,
      source: binding.source,
      collection?: binding.collection? || false,
      depends_on: Enum.map(binding.depends_on, &normalize_reference/1),
      derived: normalize_map(binding.derived),
      metadata: normalize_map(binding.metadata)
    }
  end

  defp normalize_reference(reference) do
    %{
      path:
        reference
        |> fetch(:path, [])
        |> normalize_path()
    }
    |> maybe_put(:scope, normalize_optional_path(fetch(reference, :scope)))
    |> maybe_put(:format, fetch(reference, :format))
    |> maybe_put(:source, fetch(reference, :source))
  end

  defp normalize_optional_path(nil), do: nil
  defp normalize_optional_path(path), do: normalize_path(path)

  defp normalize_path(nil), do: []
  defp normalize_path(path) when is_atom(path) or is_binary(path), do: [path]
  defp normalize_path(path) when is_list(path), do: path

  defp normalize_map(nil), do: %{}
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp fetch(source, key, default \\ nil) do
    Map.get(source, key, Map.get(source, Atom.to_string(key), default))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
