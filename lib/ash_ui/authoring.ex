defmodule AshUI.Authoring do
  @moduledoc """
  Boundary helpers for upstream `UnifiedUi` authoring.

  Ash UI does not own the authored DSL grammar for widgets, layouts, theming,
  or signals. That authority lives in the upstream `UnifiedUi` package.

  Ash UI owns the persistence, binding metadata, runtime orchestration, and
  renderer integration layered around those authored definitions.
  """

  @type module_area ::
          :dsl
          | :compiler
          | :parity
          | :signals
          | :signal
          | :binding
          | :style
          | :theme
          | :reference
          | :info
          | :tooling

  @ownership_boundary %{
    unified_ui: [:authoring_dsl, :authoring_compiler, :widget_semantics, :layout_semantics],
    ash_ui: [:resource_storage, :binding_metadata, :runtime_state, :renderer_orchestration]
  }

  @doc """
  Returns the package identity plus the Ash UI-specific authoring contract.
  """
  @spec package_identity() :: map()
  def package_identity do
    UnifiedUi.package_identity()
    |> Map.merge(%{
      required?: true,
      persistence_field: :unified_dsl,
      ownership_boundary: @ownership_boundary
    })
  end

  @doc """
  Resolves a public module area from the upstream package.
  """
  @spec module_for(module_area()) :: {:ok, module()} | :error
  def module_for(area) do
    UnifiedUi.module_for(area)
  end

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
  Returns the ownership split between `UnifiedUi` and Ash UI.
  """
  @spec ownership_boundary() :: map()
  def ownership_boundary do
    @ownership_boundary
  end
end
