defmodule ElmUi.Info do
  @moduledoc """
  Lightweight package summary helpers.
  """

  @spec package_summary() :: map()
  def package_summary do
    coverage_matrix = ElmUi.Examples.coverage_matrix()
    {:ok, release_readiness} = ElmUi.Validate.release_readiness(:summary)

    %{
      package: :elm_ui,
      namespace: ElmUi,
      package_areas: ElmUi.package_areas(),
      validation_state: ElmUi.Runtime.validation_state(),
      bridge: bridge_summary(),
      style: %{
        primitives: ElmUi.Style.primitives(),
        hooks: ElmUi.Style.widget_style_hooks()
      },
      theme: %{
        catalog: ElmUi.Theme.catalog_ids(),
        default: ElmUi.Theme.default_theme().id
      },
      inspection: %{
        helpers: ElmUi.Inspection.helpers(),
        continuity_seams: ElmUi.Continuity.seams()
      },
      validation: %{
        workflows: ElmUi.Tooling.workflows(),
        example_coverage: ElmUi.Validate.example_coverage().status,
        runtime_behavior: ElmUi.Validate.runtime_behavior().status,
        documentation_surface: ElmUi.Validate.documentation_surface().status,
        release_readiness: release_readiness.status
      },
      examples: %{
        total: length(ElmUi.Examples.catalog()),
        categories: coverage_matrix.categories |> Map.keys() |> Enum.sort(),
        workflows: coverage_matrix.workflows |> Map.keys() |> Enum.sort(),
        parity_groups: coverage_matrix.parity_groups |> Map.keys() |> Enum.sort()
      },
      tooling: %{
        workflows: ElmUi.Tooling.workflows(),
        mix_tasks: ElmUi.Tooling.mix_tasks()
      },
      documentation: %{
        guides: ElmUi.Tooling.documentation_surface(),
        preview_surfaces: ElmUi.Tooling.preview_surfaces()
      }
    }
  end

  @spec renderer_summary() :: map()
  def renderer_summary do
    %{
      accepts: ElmUi.Renderer.accepts(),
      supported_kinds: ElmUi.Renderer.supported_kinds(),
      responsibilities: ElmUi.Renderer.responsibilities()
    }
  end

  @spec widget_summary(ElmUi.Widget.t()) :: map()
  def widget_summary(%ElmUi.Widget{} = widget) do
    %{
      id: widget.id,
      family: widget.family,
      kind: widget.kind,
      metadata: widget.metadata,
      state: widget.state,
      slots: widget.slots,
      slot_children:
        Map.new(widget.slot_children, fn {slot, children} -> {slot, length(children)} end),
      attribute_keys: Map.keys(widget.attributes),
      style_keys: Map.keys(widget.styles),
      event_keys: Map.keys(widget.events)
    }
  end

  @spec bridge_summary() :: map()
  def bridge_summary do
    %{
      boundaries: ElmUi.Reference.browser_bridge_boundaries(),
      signal_families: ElmUi.Signals.families(),
      frontend_modules: ElmUi.Frontend.modules(),
      server_modules: ElmUi.Server.modules()
    }
  end
end
