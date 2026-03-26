defmodule AshUI do
  @moduledoc """
  AshUI is a declarative UI framework built on Ash Framework.

  It provides:
  - Database-driven UI definitions stored as Ash Resources
  - upstream `UnifiedUi` authoring DSL integration for UI components
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
  Returns the authoritative upstream authoring boundary used by Ash UI.
  """
  def authoring do
    AshUI.Authoring.package_identity()
  end
end
