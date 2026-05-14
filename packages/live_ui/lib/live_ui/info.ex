defmodule LiveUi.Info do
  @moduledoc """
  Lightweight package summary helpers.
  """

  alias LiveUi.Component.Metadata

  @spec package_summary() :: map()
  def package_summary do
    %{
      package: :live_ui,
      namespace: LiveUi,
      package_areas: LiveUi.package_areas(),
      validation_state: LiveUi.Runtime.validation_state(),
      styling: style_summary(),
      tooling: %{
        workflows: LiveUi.Tooling.workflows(),
        mix_tasks: LiveUi.Tooling.mix_tasks()
      },
      documentation: LiveUi.Tooling.documentation_surface()
    }
  end

  @spec style_summary(LiveUi.Theme.t() | keyword() | map() | nil) :: map()
  def style_summary(theme \\ LiveUi.Theme.default()) do
    theme = LiveUi.Theme.new(theme)

    %{
      theme_id: theme.id,
      native_components:
        theme
        |> Map.fetch!(:native)
        |> Map.fetch!(:components)
        |> Map.keys()
        |> Enum.sort(),
      token_count: map_size(theme.canonical.tokens)
    }
  end

  @spec widget_summary(module()) :: map()
  def widget_summary(widget_module) do
    %Metadata{} = metadata = LiveUi.Component.metadata(widget_module)

    %{
      module: metadata.module,
      component_module: metadata.component_module,
      mountable?: metadata.mountable?,
      runtime_boundary: metadata.runtime_boundary,
      local_state_keys: metadata.local_state_keys,
      family: metadata.family,
      name: metadata.name,
      assigns: metadata.assigns,
      slots: metadata.slots,
      style_hooks: metadata.style_hooks,
      events: metadata.events
    }
  end

  @spec advanced_widget_summary() :: [map()]
  def advanced_widget_summary do
    Enum.map(LiveUi.Widgets.advanced_modules(), &widget_summary/1)
  end

  @spec screen_summary(module()) :: map()
  def screen_summary(screen_module) do
    definition = LiveUi.Screen.definition(screen_module)

    %{
      module: definition.module,
      id: definition.id,
      title: definition.title,
      mount_defaults: definition.mount_defaults,
      event_routes: definition.event_routes,
      bridge_hooks: definition.bridge_hooks,
      metadata: definition.metadata
    }
  end

  @spec renderer_summary() :: map()
  def renderer_summary do
    %{
      accepts: LiveUi.Renderer.accepts(),
      supported_kinds: LiveUi.Renderer.supported_kinds(),
      responsibilities: LiveUi.Renderer.responsibilities()
    }
  end

  @spec continuity_summary(map()) :: map()
  def continuity_summary(report) when is_map(report) do
    %{
      shared_widgets: Map.get(report, :shared_widgets, []),
      native_only_widgets: Map.get(report, :native_only_widgets, []),
      canonical_only_widgets: Map.get(report, :canonical_only_widgets, []),
      browser_style: Map.get(report, :browser_style, %{}),
      diagnostics: Map.get(report, :diagnostics, []),
      continuity: Map.get(report, :continuity, %{})
    }
  end
end
