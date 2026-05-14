defmodule DesktopUi.Reference do
  @moduledoc """
  Lightweight package reference helpers for `desktop_ui`.
  """

  @spec widget_summary() :: map()
  def widget_summary do
    package_reference().widgets
  end

  @spec example_summary() :: map()
  def example_summary do
    package_reference().examples
  end

  @spec transport_summary() :: map()
  def transport_summary do
    package_reference().transport
  end

  @spec style_summary() :: map()
  def style_summary do
    %{
      style: package_reference().style,
      theme: package_reference().theme,
      continuity: package_reference().continuity
    }
  end

  @spec artifact_summary() :: map()
  def artifact_summary do
    package_reference().artifacts
  end

  @spec sdl3_summary() :: map()
  def sdl3_summary do
    package_reference().sdl3
  end

  @spec shared_runtime_contract() :: map()
  def shared_runtime_contract do
    %{
      assumptions: DesktopUi.Runtime.assumptions(),
      platform_targets: DesktopUi.Platform.targets(),
      renderer_accepts: DesktopUi.Renderer.accepts(),
      transport_modes: DesktopUi.Transport.modes(),
      direct_native_and_canonical_share_runtime: true
    }
  end

  @spec package_reference() :: map()
  def package_reference do
    capabilities = DesktopUi.Sdl3.Capabilities.detect()
    validation_report = DesktopUi.Validate.surface_validation_report()
    inspection_surface = DesktopUi.Inspection.sdl3_adapter_surface()

    %{
      package: DesktopUi,
      package_areas: DesktopUi.package_areas(),
      widgets: %{
        families: DesktopUi.Widgets.families(),
        kinds: DesktopUi.Widgets.kinds(),
        modules: DesktopUi.Widgets.modules(),
        contract: DesktopUi.Widget.contract(),
        registration_model: DesktopUi.Widgets.registration_model(),
        validation_state: DesktopUi.Widgets.validation_state()
      },
      runtime: %{
        assumptions: DesktopUi.Runtime.assumptions(),
        modules: DesktopUi.Runtime.modules(),
        capabilities: DesktopUi.Runtime.capabilities(),
        validation_state: DesktopUi.Runtime.validation_state(),
        event_loop_diagnostics:
          DesktopUi.Runtime.EventLoop.diagnostics(DesktopUi.Runtime.EventLoop.scaffold())
      },
      sdl3: %{
        foundation: DesktopUi.Sdl3.foundation(),
        modules: DesktopUi.Sdl3.modules(),
        scope: DesktopUi.Sdl3.adapter_scope(),
        lifecycle: DesktopUi.Sdl3.App.lifecycle_contract(),
        handoff: DesktopUi.Sdl3.App.handoff_contract(),
        host: DesktopUi.Sdl3.PortHost.contract(),
        native_build: DesktopUi.Sdl3.NativeBuild.contract(),
        capabilities: capabilities,
        protocol: DesktopUi.Sdl3.Protocol.contract(),
        frame_encoder: DesktopUi.Sdl3.FrameEncoder.contract(),
        frame_script: DesktopUi.Sdl3.FrameScript.contract(),
        interaction_script: DesktopUi.Sdl3.InteractionScript.contract(),
        visible_runner: DesktopUi.Sdl3.VisibleRunner.contract(),
        renderer: DesktopUi.Sdl3.Renderer.contract(),
        events: DesktopUi.Sdl3.Events.contract(),
        text: DesktopUi.Sdl3.Text.contract(),
        images: DesktopUi.Sdl3.Images.contract(),
        run_execution: DesktopUi.Tooling.run_backend_summary(capabilities),
        manual_review_workflow: DesktopUi.Inspection.manual_review_workflow(),
        validation_state: inspection_surface.validation_state,
        renderer_completeness: inspection_surface.renderer_completeness
      },
      build: %{
        contract: DesktopUi.Build.contract(),
        targets: DesktopUi.Build.targets(),
        target_builds: Enum.map(DesktopUi.Build.targets(), &DesktopUi.Build.build_plan(&1))
      },
      packaging: %{
        contract: DesktopUi.Package.contract(),
        targets: DesktopUi.Package.targets(),
        diagnostics: DesktopUi.Package.diagnostics(),
        target_packages:
          Enum.map(DesktopUi.Package.targets(), &DesktopUi.Package.package_plan(&1)),
        validation_state: DesktopUi.Package.validation_state()
      },
      platform: %{
        targets: DesktopUi.Platform.targets(),
        modules: DesktopUi.Platform.modules(),
        capability_contract: DesktopUi.Platform.capability_contract(),
        callback_contract: DesktopUi.Platform.callback_contract(),
        integration: DesktopUi.Platform.diagnostics().integration,
        diagnostics: DesktopUi.Platform.diagnostics(),
        validation_state: DesktopUi.Platform.validation_state()
      },
      layout: %{
        kinds: DesktopUi.Layout.kinds(),
        validation_state: DesktopUi.Layout.validation_state()
      },
      layer: %{
        kinds: DesktopUi.Layer.kinds(),
        validation_state: DesktopUi.Layer.validation_state()
      },
      renderer: %{
        accepts: DesktopUi.Renderer.accepts(),
        responsibilities: DesktopUi.Renderer.responsibilities(),
        validation_state: DesktopUi.Renderer.validation_state()
      },
      transport: %{
        modes: DesktopUi.Transport.modes(),
        families: DesktopUi.Transport.families(),
        input_families: DesktopUi.Transport.input_families(),
        local_default_families: DesktopUi.Transport.local_default_families(),
        boundary_crossing_families: DesktopUi.Transport.boundary_crossing_families(),
        integration_points: DesktopUi.Transport.integration_points(),
        modules: DesktopUi.Transport.modules(),
        diagnostics: DesktopUi.Transport.diagnostics(),
        validation_state: DesktopUi.Transport.validation_state()
      },
      style: %{
        primitives: DesktopUi.Style.primitives(),
        widget_style_hooks: DesktopUi.Style.widget_style_hooks(),
        responsibilities: DesktopUi.Style.responsibilities(),
        validation_state: DesktopUi.Style.validation_state()
      },
      theme: %{
        default_theme: DesktopUi.Theme.default_theme().id,
        catalog_ids: DesktopUi.Theme.catalog_ids(),
        continuity_rules: DesktopUi.Theme.continuity_rules(),
        validation_state: DesktopUi.Theme.validation_state()
      },
      artifacts: %{
        target_platforms: DesktopUi.Artifacts.target_platforms(),
        workflows: DesktopUi.Artifacts.workflows(),
        boundary_policy: DesktopUi.Artifacts.boundary_policy(),
        diagnostics: DesktopUi.Artifacts.diagnostics(),
        responsibilities: DesktopUi.Artifacts.responsibilities(),
        validation_state: DesktopUi.Artifacts.validation_state()
      },
      examples: %{
        native_ids: DesktopUi.Examples.native_ids(),
        canonical_ids: DesktopUi.Examples.canonical_ids(),
        comparison_ids: DesktopUi.Examples.comparison_ids(),
        catalog: DesktopUi.Examples.catalog(),
        coverage_matrix: DesktopUi.Examples.coverage_matrix()
      },
      inspection: %{
        helpers: DesktopUi.Inspection.helpers(),
        package_overview: DesktopUi.Inspection.package_overview(),
        continuity_contract: DesktopUi.Inspection.continuity_contract(),
        platform_profiles: DesktopUi.Inspection.platform_profiles(),
        shared_runtime_contract: DesktopUi.Inspection.shared_runtime_contract(),
        sdl3_adapter_surface: DesktopUi.Inspection.sdl3_adapter_surface(),
        transport_contract: DesktopUi.Inspection.transport_contract(),
        layering_contract: DesktopUi.Inspection.layering_contract(),
        validation_surface: DesktopUi.Inspection.validation_surface()
      },
      continuity: %{
        seams: DesktopUi.Continuity.seams(),
        diagnostic_kinds: DesktopUi.Continuity.diagnostic_kinds(),
        contract: DesktopUi.Continuity.contract()
      },
      responsibilities: %{
        direct_native: [
          :widgets,
          :layout,
          :layer,
          :runtime,
          :sdl3,
          :platform,
          :style,
          :theme,
          :continuity
        ],
        canonical_renderer: [:renderer, :runtime, :transport],
        bounded_platform_variation: true
      },
      tooling: %{
        guides: DesktopUi.Tooling.documentation_surface(),
        workflows: DesktopUi.Tooling.workflows(),
        preview_surfaces: DesktopUi.Tooling.preview_surfaces(),
        mix_tasks: DesktopUi.Tooling.mix_tasks(),
        validation_state: DesktopUi.Tooling.validation_state()
      },
      documentation: %{
        guides: DesktopUi.Tooling.documentation_surface(),
        maintainer_commands: DesktopUi.Tooling.mix_tasks(),
        shared_runtime_contract: shared_runtime_contract(),
        sdl3_adapter_surface: DesktopUi.Inspection.sdl3_adapter_surface(),
        traceability_targets: DesktopUi.Validate.traceability_targets()
      },
      validate: %{
        inspect: DesktopUi.Inspect,
        validate: DesktopUi.Validate,
        validation_sections: validation_report |> Map.keys() |> Enum.sort(),
        release_readiness_modes: [:summary, :strict],
        release_gates: DesktopUi.Validate.release_gates(),
        evolution_rules: DesktopUi.Validate.evolution_rules(),
        documentation_surface: DesktopUi.Validate.documentation_surface(),
        traceability_alignment: DesktopUi.Validate.traceability_alignment(),
        validation_report: validation_report
      }
    }
  end
end
