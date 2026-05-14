defmodule ElmUi.Tooling do
  @moduledoc """
  Package tooling and inspection helpers for the `elm_ui` scaffold.
  """

  @spec workflows() :: [atom()]
  def workflows do
    [
      :package_tests,
      :example_preview,
      :reference_inspection,
      :canonical_render_smoke,
      :transport_round_trip,
      :runtime_inspection,
      :continuity_diagnostics,
      :artifact_export,
      :package_validation,
      :release_readiness,
      :documentation_review,
      :evolution_policy_review
    ]
  end

  @spec preview_surfaces() :: [module()]
  def preview_surfaces do
    [
      ElmUi.Reference,
      ElmUi.Info,
      ElmUi.Style,
      ElmUi.Theme,
      ElmUi.Inspection,
      ElmUi.Inspect,
      ElmUi.Export,
      ElmUi.Validate,
      ElmUi.Continuity,
      ElmUi.Examples
    ]
  end

  @spec mix_tasks() :: [String.t()]
  def mix_tasks do
    [
      "mix deps.get",
      "mix compile",
      "mix test",
      "mix elm_ui.preview --format catalog",
      "mix elm_ui.inspect native_styling",
      "mix elm_ui.export styling_continuity --format comparison",
      "mix elm_ui.validate --strict",
      "mix spec.plancheck elm_ui",
      "mix spec.compliance elm_ui"
    ]
  end

  @spec documentation_surface() :: [String.t()]
  def documentation_surface do
    [
      "README.md",
      "guides/runtime_backbone.md",
      "guides/native_runtime_and_examples.md",
      "guides/canonical_rendering_and_transport.md",
      "guides/styling_and_inspection.md",
      "guides/maintainer_workflows.md"
    ]
  end

  @spec validation_state() :: map()
  def validation_state do
    %{
      workflows: workflows(),
      package_areas: ElmUi.package_areas(),
      runtime_validation: ElmUi.Runtime.validation_state()
    }
  end
end
