defmodule AshUI.Application do
  @moduledoc """
  OTP application entry point for Ash UI.

  Starts the repo and runtime services required by the framework.
  """

  use Application

  alias AshUI.Authorization.Runtime
  alias AshUI.Compiler
  alias AshUI.Rendering.Registry
  alias AshUI.Telemetry
  alias Phoenix.PubSub

  @impl true
  @doc """
  Starts the Ash UI supervision tree.
  """
  def start(_type, _args) do
    Compiler.init_cache()
    Runtime.init_cache()

    children = [
      {PubSub, name: AshUI.PubSub},
      Telemetry,
      Registry
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
