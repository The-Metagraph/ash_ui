defmodule DesktopUi.Info do
  @moduledoc """
  Lightweight package summary helpers for `desktop_ui`.
  """

  @spec example_summary() :: map()
  def example_summary do
    package_summary().examples
  end

  @spec transport_summary() :: map()
  def transport_summary do
    package_summary().transport
  end

  @spec style_summary() :: map()
  def style_summary do
    %{
      style: package_summary().style,
      theme: package_summary().theme,
      continuity: package_summary().continuity
    }
  end

  @spec artifact_summary() :: map()
  def artifact_summary do
    package_summary().artifacts
  end

  @spec sdl3_summary() :: map()
  def sdl3_summary do
    package_summary().sdl3
  end

  @spec package_summary() :: map()
  def package_summary do
    release_readiness = DesktopUi.Validate.surface_release_readiness()
    capabilities = DesktopUi.Sdl3.Capabilities.detect()
    inspection_surface = DesktopUi.Inspection.sdl3_adapter_surface()

    %{
      package: :desktop_ui,
      namespace: DesktopUi,
      package_areas: DesktopUi.package_areas(),
      runtime: %{
        assumptions: DesktopUi.Runtime.assumptions(),
        validation_state: DesktopUi.Runtime.validation_state(),
        event_loop:
          DesktopUi.Runtime.EventLoop.diagnostics(DesktopUi.Runtime.EventLoop.scaffold())
      },
      sdl3: %{
        foundation: DesktopUi.Sdl3.foundation(),
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
        targets: DesktopUi.Build.targets()
      },
      packaging: %{
        contract: DesktopUi.Package.contract(),
        targets: DesktopUi.Package.targets(),
        validation_state: DesktopUi.Package.validation_state()
      },
      widgets: %{
        families: DesktopUi.Widgets.families(),
        kinds: DesktopUi.Widgets.kinds(),
        contract: DesktopUi.Widget.contract(),
        validation_state: DesktopUi.Widgets.validation_state()
      },
      platform: %{
        targets: DesktopUi.Platform.targets(),
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
        responsibilities: DesktopUi.Renderer.responsibilities(),
        validation_state: DesktopUi.Renderer.validation_state()
      },
      transport: %{
        modes: DesktopUi.Transport.modes(),
        families: DesktopUi.Transport.families(),
        input_families: DesktopUi.Transport.input_families(),
        diagnostics: DesktopUi.Transport.diagnostics(),
        validation_state: DesktopUi.Transport.validation_state()
      },
      style: %{
        primitives: DesktopUi.Style.primitives(),
        validation_state: DesktopUi.Style.validation_state()
      },
      theme: %{
        default_theme: DesktopUi.Theme.default_theme().id,
        catalog_ids: DesktopUi.Theme.catalog_ids(),
        validation_state: DesktopUi.Theme.validation_state()
      },
      artifacts: %{
        target_platforms: DesktopUi.Artifacts.target_platforms(),
        workflows: DesktopUi.Artifacts.workflows(),
        boundary_policy: DesktopUi.Artifacts.boundary_policy(),
        validation_state: DesktopUi.Artifacts.validation_state()
      },
      examples: %{
        native_ids: DesktopUi.Examples.native_ids(),
        canonical_ids: DesktopUi.Examples.canonical_ids(),
        comparison_ids: DesktopUi.Examples.comparison_ids(),
        workflows: Map.keys(DesktopUi.Examples.coverage_matrix().workflows)
      },
      tooling: %{
        guides: DesktopUi.Tooling.documentation_surface(),
        workflows: DesktopUi.Tooling.workflows(),
        mix_tasks: DesktopUi.Tooling.mix_tasks()
      },
      validate: %{
        release_gates: DesktopUi.Validate.release_gates(),
        documentation_surface: DesktopUi.Validate.documentation_surface().status,
        traceability_alignment: DesktopUi.Validate.traceability_alignment().status,
        release_readiness: release_readiness.status
      },
      documentation: %{
        guides: DesktopUi.Tooling.documentation_surface(),
        preview_surfaces: DesktopUi.Tooling.preview_surfaces(),
        traceability_targets: DesktopUi.Validate.traceability_targets()
      },
      inspection: %{
        helpers: DesktopUi.Inspection.helpers(),
        validation: DesktopUi.Inspection.validation_surface(),
        sdl3_adapter_surface: DesktopUi.Inspection.sdl3_adapter_surface()
      },
      continuity: %{
        seams: DesktopUi.Continuity.seams(),
        diagnostic_kinds: DesktopUi.Continuity.diagnostic_kinds()
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
        canonical_renderer: [:renderer, :runtime, :transport]
      }
    }
  end
end
