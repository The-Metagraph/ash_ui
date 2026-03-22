defmodule AshUI.Application do
  @moduledoc """
  OTP application entry point for Ash UI.

  Starts the repo and runtime services required by the framework.
  """

  use Application

  @impl true
  @doc """
  Starts the Ash UI supervision tree.
  """
  def start(_type, _args) do
    AshUI.Compiler.init_cache()
    AshUI.Authorization.Runtime.init_cache()

    children = [
      AshUI.Telemetry,
      AshUI.Rendering.Registry
    ]
    children = maybe_add_storage_repo(children)

    opts = [strategy: :one_for_one, name: AshUI.Supervisor]

    Supervisor.start_link(children, opts)
  end

  defp maybe_add_storage_repo(children) do
    case AshUI.Config.ui_storage_repo() do
      nil ->
        children

      repo when is_atom(repo) ->
        if Code.ensure_loaded?(repo) and function_exported?(repo, :start_link, 1) do
          List.insert_at(children, 1, repo)
        else
          children
        end
    end
  end
end
