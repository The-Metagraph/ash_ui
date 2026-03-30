defmodule AshUI do
  @moduledoc """
  AshUI is a declarative UI framework built on Ash Framework.

  It provides:
  - Resource-first screen and element authoring through `AshUI.Resource.DSL.*`
  - persisted `Screen.unified_dsl` snapshots generated from the resource graph
  - Phoenix LiveView runtime integration
  - Policy-based authorization for UI access
  """

  @doc """
  Returns the configured UI storage domain.
  """
  def domain do
    AshUI.Config.ui_storage_domain()
  end

  @doc """
  Returns package identity and ownership metadata for Ash UI authoring.
  """
  def authoring do
    AshUI.Authoring.package_identity()
  end
end
