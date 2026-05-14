defmodule ElmUi.Reference do
  @moduledoc """
  Reference helpers for package capabilities and boundaries.
  """

  @spec widget_families() :: [ElmUi.Widgets.family()]
  def widget_families do
    ElmUi.Widgets.families()
  end

  @spec widget_contract() :: map()
  def widget_contract do
    ElmUi.Widget.contract()
  end

  @spec runtime_modules() :: [module()]
  def runtime_modules do
    ElmUi.Runtime.modules()
  end

  @spec transport_integration_points() :: [atom()]
  def transport_integration_points do
    ElmUi.Transport.integration_points()
  end

  @spec responsibilities() :: map()
  def responsibilities do
    %{
      direct_native: [:native_widgets, :phoenix_server_runtime, :elm_frontend_runtime],
      styling: ElmUi.Style.responsibilities(),
      display_systems: ElmUi.Layout.responsibilities(),
      layering: ElmUi.Layer.responsibilities(),
      canonical_signals: ElmUi.Signals.responsibilities(),
      canonical_renderer: ElmUi.Renderer.responsibilities()
    }
  end

  @spec runtime_assumptions() :: map()
  def runtime_assumptions do
    ElmUi.Runtime.assumptions()
  end

  @spec browser_bridge_boundaries() :: [atom()]
  def browser_bridge_boundaries do
    [:hydration_envelope, :event_envelope, :acknowledgement]
  end

  @spec package_reference() :: map()
  def package_reference do
    %{
      package: ElmUi,
      widgets: %{
        families: widget_families(),
        kinds: ElmUi.Widgets.kinds(),
        modules: ElmUi.Widgets.modules(),
        contract: widget_contract(),
        validation_state: ElmUi.Widgets.validation_state()
      },
      layout: %{
        kinds: ElmUi.Layout.kinds(),
        modules: ElmUi.Layout.modules(),
        responsibilities: ElmUi.Layout.responsibilities()
      },
      layer: %{
        kinds: ElmUi.Layer.kinds(),
        modules: ElmUi.Layer.modules(),
        responsibilities: ElmUi.Layer.responsibilities()
      },
      runtime: %{
        capabilities: ElmUi.Runtime.capabilities(),
        modules: runtime_modules(),
        assumptions: runtime_assumptions(),
        bridge_boundaries: browser_bridge_boundaries(),
        frontend_capabilities: ElmUi.FrontendRuntime.capabilities()
      },
      renderer: %{
        accepts: ElmUi.Renderer.accepts(),
        supported_kinds: ElmUi.Renderer.supported_kinds(),
        responsibilities: ElmUi.Renderer.responsibilities()
      },
      signals: %{
        families: ElmUi.Signals.families(),
        local_default_families: ElmUi.Signals.local_default_families(),
        boundary_crossing_families: ElmUi.Signals.boundary_crossing_families(),
        responsibilities: ElmUi.Signals.responsibilities()
      },
      transport: %{
        modes: ElmUi.Transport.modes(),
        integration_points: transport_integration_points(),
        families: ElmUi.Transport.families()
      },
      style: %{
        primitives: ElmUi.Style.primitives(),
        hooks: ElmUi.Style.widget_style_hooks(),
        portable_keys: ElmUi.Style.portable_keys()
      },
      theme: %{
        catalog: ElmUi.Theme.catalog_ids(),
        default: ElmUi.Theme.default_theme().id,
        palette_roles: ElmUi.Theme.palette_roles(),
        continuity_rules: ElmUi.Theme.continuity_rules(),
        runtime_contract: ElmUi.Theme.runtime_contract()
      },
      inspection: %{
        helpers: ElmUi.Inspection.helpers(),
        package_overview: ElmUi.Inspection.package_overview(),
        continuity_contract: ElmUi.Continuity.contract()
      },
      validation: %{
        inspect: ElmUi.Inspect,
        export: ElmUi.Export,
        validate: ElmUi.Validate,
        release_readiness_modes: [:summary, :strict],
        release_gates: ElmUi.Validate.release_gates(),
        evolution_rules: ElmUi.Validate.evolution_rules()
      },
      documentation: %{
        guides: ElmUi.Tooling.documentation_surface(),
        maintainer_commands: ElmUi.Tooling.mix_tasks()
      },
      tooling: %{
        workflows: ElmUi.Tooling.workflows(),
        preview_surfaces: ElmUi.Tooling.preview_surfaces(),
        documentation: ElmUi.Tooling.documentation_surface()
      },
      examples: %{
        catalog: ElmUi.Examples.catalog(),
        native_ids: Enum.map(ElmUi.Examples.native_examples(), & &1.id),
        canonical_ids: Enum.map(ElmUi.Examples.canonical_examples(), & &1.id),
        mixed_ids: Enum.map(ElmUi.Examples.mixed_examples(), & &1.id),
        coverage_matrix: ElmUi.Examples.coverage_matrix()
      },
      responsibilities: responsibilities()
    }
  end
end
