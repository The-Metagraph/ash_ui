defmodule DesktopUi.Artifacts do
  @moduledoc """
  Platform artifact workflow policy for `desktop_ui`.
  """

  @workflows %{
    windows: %{
      build: [:fetch_deps, :compile_release, :assemble_sdl_runtime, :stage_windows_assets],
      packaging: [:zip_archive, :msi_installer],
      artifact_types: [:portable_archive, :installer],
      runtime_contract: %{foundation: :sdl3, semantics: :shared}
    },
    macos: %{
      build: [:fetch_deps, :compile_release, :assemble_sdl_runtime, :stage_app_bundle],
      packaging: [:app_bundle, :signed_zip],
      artifact_types: [:app_bundle, :archive],
      runtime_contract: %{foundation: :sdl3, semantics: :shared}
    },
    linux: %{
      build: [:fetch_deps, :compile_release, :assemble_sdl_runtime, :stage_desktop_assets],
      packaging: [:tar_archive, :appimage_like_bundle],
      artifact_types: [:archive, :desktop_bundle],
      runtime_contract: %{foundation: :sdl3, semantics: :shared}
    }
  }

  @spec target_platforms() :: [atom()]
  def target_platforms, do: [:windows, :macos, :linux]

  @spec workflow(atom()) :: map()
  def workflow(target), do: Map.fetch!(@workflows, target)

  @spec workflows() :: map()
  def workflows, do: @workflows

  @spec artifact_types(atom()) :: [atom()]
  def artifact_types(target), do: workflow(target).artifact_types

  @spec responsibilities() :: [atom()]
  def responsibilities do
    [
      :platform_builds,
      :platform_packaging,
      :artifact_policy_boundaries,
      :runtime_semantics_preservation
    ]
  end

  @spec boundary_policy() :: map()
  def boundary_policy do
    %{
      shared_runtime_semantics: true,
      widget_semantics_preserved: true,
      transport_semantics_preserved: true,
      packaging_distinct_from_runtime_logic: true,
      packaging_distinct_from_renderer_logic: true
    }
  end

  @spec diagnostics() :: map()
  def diagnostics do
    %{
      targets: target_platforms(),
      workflows: workflows(),
      boundary_policy: boundary_policy(),
      invalid_targets:
        target_platforms()
        |> Enum.reject(&(workflow(&1).runtime_contract.foundation == :sdl3))
    }
  end

  @spec validation_state() :: map()
  def validation_state do
    %{
      workflow_catalog: :ready,
      packaging_boundaries: :ready,
      shared_semantics_preservation: :ready
    }
  end
end
