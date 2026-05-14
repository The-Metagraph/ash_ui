defmodule DesktopUi.Navigation.Registry do
  @moduledoc """
  Screen registry for registering and looking up screen modules.

  Applications implement a registry module that declares their available
  screens and provides lookup functionality.

  ## Example Registry

      defmodule MyApp.Screens do
        @behaviour DesktopUi.Navigation.Registry

        @impl true
        def register do
          %{
            home: {HomeScreen, title: "Home", icon: :home},
            list: {ItemListScreen, title: "Items", icon: :list},
            detail: {ItemDetailScreen, title: "Item Details", icon: :detail}
          }
        end

        @impl true
        def get_screen(:home), do: HomeScreen
        def get_screen(:list), do: ItemListScreen
        def get_screen(:detail), do: ItemDetailScreen
        def get_screen(_), do: nil

        @impl true
        def screen_metadata(:home) do
          %{
            title: "Home",
            icon: :home,
            appears_in_history?: true,
            modal_only?: false
          }
        end

        def screen_metadata(_), do: %{}
      end
  """

  @type screen_id :: atom() | String.t()
  @type screen_module :: module()
  @type screen_tuple :: {screen_module(), keyword()}
  @type registry :: %{screen_id() => screen_tuple()}
  @type metadata :: map()

  @doc """
  Callback that returns the map of registered screens.
  """
  @callback register() :: registry()

  @doc """
  Callback that looks up a screen module by ID.
  """
  @callback get_screen(screen_id()) :: screen_module() | nil

  @doc """
  Callback that returns metadata for a screen.
  """
  @callback screen_metadata(screen_id()) :: metadata()

  @optional_callbacks screen_metadata: 1

  @spec validate(module()) :: {:ok, registry()} | {:error, term()}
  def validate(registry_module) when is_atom(registry_module) do
    with true <- Code.ensure_loaded?(registry_module),
         true <- function_exported?(registry_module, :register, 0),
         {:ok, registry} <- apply_register(registry_module),
         :ok <- validate_modules(registry) do
      {:ok, registry}
    else
      false ->
        {:error, {:invalid_registry, :not_loaded_or_no_register}}

      {:error, :not_a_map} ->
        {:error, {:invalid_registry, :register_not_map}}

      {:error, :register_failed} ->
        {:error, {:invalid_registry, :register_not_map}}

      _ ->
        {:error, {:invalid_registry, :validation_failed}}
    end
  end

  @spec lookup(module(), screen_id()) :: {:ok, screen_module()} | {:error, term()}
  def lookup(registry_module, screen_id) do
    if function_exported?(registry_module, :get_screen, 1) do
      case registry_module.get_screen(screen_id) do
        nil -> {:error, {:unknown_screen, screen_id}}
        module -> {:ok, module}
      end
    else
      {:error, {:invalid_registry, registry_module}}
    end
  end

  @spec metadata(module(), screen_id()) :: metadata()
  def metadata(registry_module, screen_id) do
    if function_exported?(registry_module, :screen_metadata, 1) do
      registry_module.screen_metadata(screen_id)
    else
      %{}
    end
  end

  @spec all_screen_ids(module()) :: [screen_id()]
  def all_screen_ids(registry_module) do
    case validate(registry_module) do
      {:ok, registry} -> Map.keys(registry)
      {:error, _} -> []
    end
  end

  # Private functions

  defp apply_register(module) do
    try do
      case module.register() do
        registry when is_map(registry) -> {:ok, registry}
        _ -> {:error, :not_a_map}
      end
    rescue
      _ -> {:error, :register_failed}
    end
  end

  defp validate_modules(registry) when is_map(registry) do
    Enum.all?(registry, fn {_id, value} ->
      case value do
        {module, _opts} when is_atom(module) -> true
        module when is_atom(module) -> true
        _ -> false
      end
    end)
    |> if(do: :ok, else: :error)
  end
end
