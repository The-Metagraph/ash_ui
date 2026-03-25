defmodule AshUI.Authoring.Extensions do
  @moduledoc """
  Public extension guidance for authored `UnifiedUi` modules.

  Ash UI no longer treats widget or layout registration as a runtime concern for
  application-facing authoring. Public extensions should be authored as
  compile-time `Spark`/`UnifiedUi.Dsl` extensions and then persisted through the
  Ash UI authoring bridge.

  The older `AshUI.Compiler.Extensions` registry remains available as a
  compatibility layer for legacy builder-driven compiler scenarios, but it is no
  longer the public authoring contract.
  """

  @doc """
  Returns the upstream authored DSL extension points.
  """
  @spec extension_points() :: %{atom() => [atom()]}
  def extension_points do
    UnifiedUi.Reference.extension_points()
  end

  @doc """
  Returns the upstream construct family catalog.
  """
  @spec construct_families() :: %{atom() => [atom()]}
  def construct_families do
    UnifiedUi.Reference.construct_families()
  end

  @doc """
  Returns the public registration mode for authored widgets and layouts.
  """
  @spec registration_mode() :: :upstream_compile_time
  def registration_mode, do: :upstream_compile_time

  @doc """
  Describes the remaining Ash UI-specific compatibility layer.
  """
  @spec compatibility_layer() :: map()
  def compatibility_layer do
    %{
      legacy_registry_module: AshUI.Compiler.Extensions,
      legacy_registry_role: :builder_compatibility_only,
      ash_ui_owned_metadata: [:binding_metadata, :route_metadata, :screen_metadata]
    }
  end

  @doc """
  Returns developer-facing guidance for extending upstream authored modules.
  """
  @spec registration_guidance() :: [String.t()]
  def registration_guidance do
    [
      "Author new widgets and layouts as compile-time UnifiedUi DSL extensions.",
      "Patch composition entities through UnifiedUi extension points like :widget_entities and :layout_entities.",
      "Persist authored modules through AshUI.Authoring.Screen instead of registering runtime widget semantics in Ash UI."
    ]
  end
end
