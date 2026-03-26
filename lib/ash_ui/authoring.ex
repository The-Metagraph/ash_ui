defmodule AshUI.Authoring do
  @moduledoc """
  Boundary helpers for resource-first Ash UI authoring.

  Ash resources that use `AshUI.Resource.DSL.*` are the authoritative authoring
  units. Upstream `UnifiedUi` still owns widget and layout grammar, but Ash UI
  now persists relational screen and element resources instead of monolithic
  authored-screen documents.

  This module exposes package metadata plus the resource-first persistence
  helpers that still sit at the Ash UI package boundary.
  """

  alias AshUI.Authoring.{Extensions, Screen}

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
    Extensions.extension_points()
  end

  @doc """
  Returns the upstream construct family catalog.
  """
  @spec construct_families() :: %{atom() => [atom()]}
  def construct_families do
    Extensions.construct_families()
  end

  @doc """
  Returns the upstream authoring registration mode Ash UI expects callers to use.
  """
  @spec registration_mode() :: :upstream_compile_time
  def registration_mode do
    Extensions.registration_mode()
  end

  @doc """
  Returns guidance for extending widgets and layouts through upstream `UnifiedUi`.
  """
  @spec registration_guidance() :: [String.t()]
  def registration_guidance do
    Extensions.registration_guidance()
  end

  @doc """
  Builds `Screen` attributes from an authoritative screen resource module.
  """
  @spec screen_attrs(module(), keyword()) :: {:ok, map()} | {:error, term()}
  def screen_attrs(module, opts \\ []) do
    Screen.screen_attrs(module, opts)
  end

  @doc """
  Persists a `Screen` record from an authoritative screen resource module.
  """
  @spec create_screen(module(), keyword()) :: {:ok, struct()} | {:error, term()}
  def create_screen(module, opts \\ []) do
    Screen.create(module, opts)
  end

  @doc """
  Returns the ownership split between `UnifiedUi` and Ash UI.
  """
  @spec ownership_boundary() :: map()
  def ownership_boundary do
    @ownership_boundary
  end
end
