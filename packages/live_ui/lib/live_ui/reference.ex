defmodule LiveUi.Reference do
  @moduledoc """
  Reference helpers for package boundaries and capabilities.
  """

  @spec widget_families() :: [LiveUi.Widgets.family()]
  def widget_families do
    LiveUi.Widgets.families()
  end

  @spec runtime_modules() :: [module()]
  def runtime_modules do
    LiveUi.Runtime.modules()
  end

  @spec transport_integration_points() :: [atom()]
  def transport_integration_points do
    LiveUi.Transport.integration_points()
  end

  @spec signal_families() :: [UnifiedIUR.Interaction.family()]
  def signal_families do
    LiveUi.Signals.families()
  end

  @spec responsibilities() :: map()
  def responsibilities do
    %{
      direct_native: [
        :native_widgets,
        :native_forms,
        :native_navigation,
        :liveview_runtime,
        :local_event_handling
      ],
      canonical_renderer: LiveUi.Renderer.responsibilities()
    }
  end

  @spec runtime_assumptions() :: map()
  def runtime_assumptions do
    LiveUi.Runtime.assumptions()
  end

  @spec package_reference() :: map()
  def package_reference do
    %{
      package: LiveUi,
      widgets: %{
        families: widget_families(),
        modules: LiveUi.Widgets.modules()
      },
      runtime: %{
        capabilities: LiveUi.Runtime.capabilities(),
        modules: runtime_modules(),
        assumptions: runtime_assumptions()
      },
      renderer: %{
        accepts: LiveUi.Renderer.accepts(),
        responsibilities: LiveUi.Renderer.responsibilities()
      },
      transport: %{
        modes: LiveUi.Transport.modes(),
        integration_points: transport_integration_points(),
        supported_families: signal_families()
      },
      styling: %{
        theme: LiveUi.Info.style_summary(),
        native_surface: LiveUi.theme()
      },
      responsibilities: responsibilities(),
      tooling: %{
        workflows: LiveUi.Tooling.workflows(),
        mix_tasks: LiveUi.Tooling.mix_tasks(),
        documentation: LiveUi.Tooling.documentation_surface()
      }
    }
  end
end
