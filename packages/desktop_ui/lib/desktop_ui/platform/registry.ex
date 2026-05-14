defmodule DesktopUi.Platform.Registry do
  @moduledoc """
  Adapter registry and resolution helpers for `desktop_ui`.
  """

  @spec default() :: map()
  def default do
    %{
      windows: DesktopUi.Platform.Windows,
      macos: DesktopUi.Platform.MacOS,
      linux: DesktopUi.Platform.Linux
    }
  end

  @spec resolve(map(), atom()) ::
          {:ok, module()} | {:error, :unsupported_target | :invalid_adapter}
  def resolve(registry, target) when is_map(registry) and is_atom(target) do
    case Map.fetch(registry, target) do
      {:ok, adapter} when is_atom(adapter) ->
        if Code.ensure_loaded?(adapter) and function_exported?(adapter, :summary, 0) and
             function_exported?(adapter, :capabilities, 0) and
             function_exported?(adapter, :integration_profile, 0) do
          {:ok, adapter}
        else
          {:error, :invalid_adapter}
        end

      :error ->
        {:error, :unsupported_target}
    end
  end

  @spec registered_targets(map()) :: [atom()]
  def registered_targets(registry) when is_map(registry) do
    registry
    |> Map.keys()
    |> Enum.sort_by(&to_string/1)
  end
end
