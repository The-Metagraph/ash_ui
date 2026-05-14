defmodule LiveUi.Widget.Identity do
  @moduledoc """
  Stable addressing contract for mountable `live_ui` widget component instances.
  """

  alias LiveUi.Component.Metadata

  @enforce_keys [:id, :component_module, :widget_module, :family, :name]
  defstruct [:id, :component_module, :widget_module, :family, :name, path: [], mode: :native]

  @type t :: %__MODULE__{
          id: String.t(),
          component_module: module(),
          widget_module: module(),
          family: atom(),
          name: atom(),
          path: [String.t()],
          mode: :native | :canonical
        }

  @spec new(Metadata.t(), map() | keyword(), keyword()) :: t()
  def new(%Metadata{} = metadata, assigns, opts \\ []) do
    %__MODULE__{
      id: required_id!(metadata, assigns),
      component_module: metadata.component_module,
      widget_module: metadata.wrapper_module || metadata.module,
      family: metadata.family,
      name: metadata.name,
      path: normalize_path(Keyword.get(opts, :path, [])),
      mode: Keyword.get(opts, :mode, :native)
    }
  end

  @spec key(t()) :: String.t()
  def key(%__MODULE__{} = identity) do
    path =
      case identity.path do
        [] -> "root"
        segments -> Enum.join(segments, "/")
      end

    Enum.join(
      [
        Atom.to_string(identity.mode),
        Atom.to_string(identity.family),
        Atom.to_string(identity.name),
        identity.id,
        path
      ],
      ":"
    )
  end

  @spec required_id!(Metadata.t(), map() | keyword()) :: String.t()
  def required_id!(%Metadata{} = metadata, assigns) do
    case fetch(assigns, :id) do
      nil ->
        raise ArgumentError,
              "widget #{inspect(metadata.module)} requires an :id for stable LiveComponent identity"

      id ->
        to_string(id)
    end
  end

  defp fetch(assigns, key) when is_map(assigns) do
    Map.get(assigns, key) || Map.get(assigns, Atom.to_string(key))
  end

  defp fetch(assigns, key) when is_list(assigns) do
    Keyword.get(assigns, key) || Keyword.get(assigns, String.to_atom(to_string(key)))
  end

  defp fetch(_assigns, _key), do: nil

  defp normalize_path(path) when is_list(path), do: Enum.map(path, &to_string/1)
  defp normalize_path(_path), do: []
end
