defmodule AshUI.Authoring.Screen do
  @moduledoc """
  Resource-first persistence helpers for authoritative screen resources.

  Screen resources using `AshUI.Resource.DSL.Screen` are the primary authoring
  units. This module keeps the package-level boundary stable while delegating
  persistence to `AshUI.Resource.Authority`.
  """

  alias AshUI.Resource.Authority

  @doc """
  Builds persisted `Screen` attributes from a screen resource module.
  """
  @spec screen_attrs(module(), keyword()) :: {:ok, map()} | {:error, term()}
  def screen_attrs(module, opts \\ []) when is_atom(module) and is_list(opts) do
    Authority.screen_attrs(module, opts)
  end

  @doc """
  Persists a `Screen` resource from a screen resource module.
  """
  @spec create(module(), keyword()) :: {:ok, struct()} | {:error, term()}
  def create(module, opts \\ []) when is_atom(module) and is_list(opts) do
    Authority.create(module, opts)
  end
end
