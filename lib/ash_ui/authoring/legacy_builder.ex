defmodule AshUI.Authoring.LegacyBuilder do
  @moduledoc """
  Legacy builder signaling helpers.

  This module exists only to signal explicit migration-time use of
  `AshUI.DSL.Builder`. New application code should not call the builder
  directly.
  """

  require Logger

  alias AshUI.Telemetry

  @warning """
  AshUI.DSL.Builder is a legacy migration-only authoring path. Prefer \
  UnifiedUi.Dsl modules persisted through AshUI.Authoring.Screen.
  """

  @doc """
  Emits the canonical legacy-builder signal and logs a one-time warning per source.
  """
  @spec signal(atom(), map()) :: :ok
  def signal(source, metadata \\ %{}) when is_atom(source) and is_map(metadata) do
    warn_once(source)

    Telemetry.emit(
      :authoring,
      :legacy_builder,
      %{count: 1},
      Map.merge(%{status: :legacy, source: source, authoring_mode: :legacy_builder}, metadata)
    )
  end

  @doc """
  Returns the removal criteria for the builder-first path.
  """
  @spec removal_criteria() :: [String.t()]
  def removal_criteria do
    [
      "Persisted screens can be stored as upstream UnifiedUi authoring documents without relying on AshUI.DSL.Builder.",
      "AshUI.Compiler delegates authored DSL compilation to upstream UnifiedUi.Compiler by default.",
      "Public examples and guides no longer teach builder-first authoring.",
      "Conformance and release gates verify the repo no longer drifts back to builder-first public usage."
    ]
  end

  defp warn_once(source) do
    key = {__MODULE__, source}

    unless :persistent_term.get(key, false) do
      Logger.warning(@warning)
      :persistent_term.put(key, true)
    end

    :ok
  end
end
