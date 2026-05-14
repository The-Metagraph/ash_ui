defmodule DesktopUi.Platform.Integration do
  @moduledoc """
  Bounded platform integration rules for `desktop_ui`.
  """

  @shared_semantics [
    :widget_realization,
    :renderer_mapping,
    :transport_translation,
    :style_resolution
  ]
  @allowed_variation [:window_controls, :menu_shape, :shortcut_scope, :notification_style]
  @integration_categories [:windowing, :menus, :shortcuts, :notifications]

  @spec categories() :: [atom()]
  def categories, do: @integration_categories

  @spec shared_semantics() :: [atom()]
  def shared_semantics, do: @shared_semantics

  @spec allowed_variation() :: [atom()]
  def allowed_variation, do: @allowed_variation

  @spec target_profile(DesktopUi.Platform.target()) :: map()
  def target_profile(target) do
    summary = DesktopUi.Platform.adapter_summary(target)

    %{
      target: target,
      integration: Map.fetch!(summary, :integration),
      allowed_variation: Map.fetch!(summary, :allowed_variation),
      shared_semantics: Map.fetch!(summary, :shared_semantics),
      continuity: continuity(target)
    }
  end

  @spec continuity(DesktopUi.Platform.target()) :: map()
  def continuity(target) do
    profile = DesktopUi.Platform.adapter_summary(target)

    %{
      target: target,
      shared_runtime: profile.runtime_foundation == :sdl3,
      shared_renderer: Enum.sort(profile.shared_semantics) == Enum.sort(@shared_semantics),
      bounded_variation_only:
        Enum.sort(profile.allowed_variation) == Enum.sort(@allowed_variation)
    }
  end

  @spec diagnostics() :: map()
  def diagnostics do
    profiles =
      DesktopUi.Platform.targets()
      |> Enum.map(&target_profile/1)

    %{
      categories: @integration_categories,
      shared_semantics: @shared_semantics,
      allowed_variation: @allowed_variation,
      target_profiles: profiles,
      mismatches:
        profiles
        |> Enum.flat_map(&mismatch_diagnostics/1)
        |> Enum.sort_by(fn diagnostic -> {diagnostic.target, diagnostic.reason} end)
    }
  end

  defp mismatch_diagnostics(profile) do
    []
    |> maybe_add_missing_categories(profile)
    |> maybe_add_shared_semantic_drift(profile)
    |> maybe_add_variation_drift(profile)
  end

  defp maybe_add_missing_categories(diagnostics, profile) do
    declared =
      profile.integration
      |> Map.keys()
      |> Enum.reject(&(&1 in [:target]))

    missing = @integration_categories -- declared

    if missing == [] do
      diagnostics
    else
      diagnostics ++
        [%{target: profile.target, reason: :missing_integration_categories, categories: missing}]
    end
  end

  defp maybe_add_shared_semantic_drift(diagnostics, profile) do
    if Enum.sort(profile.shared_semantics) == Enum.sort(@shared_semantics) do
      diagnostics
    else
      diagnostics ++
        [
          %{
            target: profile.target,
            reason: :shared_semantics_drift,
            shared_semantics: profile.shared_semantics
          }
        ]
    end
  end

  defp maybe_add_variation_drift(diagnostics, profile) do
    if Enum.sort(profile.allowed_variation) == Enum.sort(@allowed_variation) do
      diagnostics
    else
      diagnostics ++
        [
          %{
            target: profile.target,
            reason: :allowed_variation_drift,
            allowed_variation: profile.allowed_variation
          }
        ]
    end
  end
end
