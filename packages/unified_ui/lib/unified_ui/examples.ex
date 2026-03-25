defmodule UnifiedUi.Examples do
  @moduledoc """
  Maintained reference modules for baseline `UnifiedUi` authored workflows.
  """

  alias UnifiedUi.Examples.{
    FoundationalScreen,
    OperationsDashboard,
    OverlayWorkspace,
    ProfileForm,
    ThemedSignalWorkspace
  }

  @catalog [
    %{
      id: :foundational_screen,
      category: :foundational,
      scenario: :simple_screen,
      module: FoundationalScreen,
      constructs: [:foundational_visual, :layout],
      parity_obligations: [:foundational_widgets, :container_constructs, :layout_constructs],
      validation_purpose: [:docs, :determinism, :parity],
      review_artifact: %{
        inspection: "foundational_screen.inspection",
        snapshot: "foundational_screen.snapshot"
      },
      summary: "Minimal screen showing foundational widgets and baseline layouts."
    },
    %{
      id: :profile_form,
      category: :form_workflow,
      scenario: :input_navigation_flow,
      module: ProfileForm,
      constructs: [:input, :navigation, :forms],
      parity_obligations: [:input_widgets, :navigation_widgets, :form_constructs],
      validation_purpose: [:docs, :signals, :parity],
      review_artifact: %{inspection: "profile_form.inspection", snapshot: "profile_form.snapshot"},
      summary: "Baseline form workflow with grouped fields, tabs, and command actions."
    },
    %{
      id: :overlay_workspace,
      category: :advanced_flow,
      scenario: :overlay_split_workspace,
      module: OverlayWorkspace,
      constructs: [:overlay, :display, :layout],
      parity_obligations: [:layer_constructs, :layout_constructs, :navigation_widgets],
      validation_purpose: [:docs, :display_systems, :parity],
      review_artifact: %{
        inspection: "overlay_workspace.inspection",
        snapshot: "overlay_workspace.snapshot"
      },
      summary: "Advanced overlay and split-pane workflow with contextual actions."
    },
    %{
      id: :operations_dashboard,
      category: :advanced_dashboard,
      scenario: :operational_visibility,
      module: OperationsDashboard,
      constructs: [:data, :feedback, :advanced],
      parity_obligations: [
        :data_widgets,
        :feedback_widgets,
        :advanced_widgets,
        :layout_constructs
      ],
      validation_purpose: [:docs, :coverage, :parity],
      review_artifact: %{
        inspection: "operations_dashboard.inspection",
        snapshot: "operations_dashboard.snapshot"
      },
      summary: "Operational dashboard covering data, feedback, and advanced monitoring widgets."
    },
    %{
      id: :themed_signal_workspace,
      category: :cross_cutting,
      scenario: :theme_signal_workspace,
      module: ThemedSignalWorkspace,
      constructs: [:themes, :signals, :overlay, :display, :forms, :canvas],
      parity_obligations: [
        :feedback_widgets,
        :input_widgets,
        :layer_constructs,
        :layout_constructs,
        :canvas_constructs
      ],
      validation_purpose: [:docs, :signals, :themes, :determinism, :parity],
      review_artifact: %{
        inspection: "themed_signal_workspace.inspection",
        snapshot: "themed_signal_workspace.snapshot"
      },
      summary:
        "Cross-cutting themed workspace combining style inheritance, bindings, interactions, overlays, and canvas output."
    }
  ]

  @spec modules() :: [module()]
  def modules do
    Enum.map(@catalog, & &1.module)
  end

  @spec ids() :: [atom()]
  def ids do
    Enum.map(@catalog, & &1.id)
  end

  @spec categories() :: [atom()]
  def categories do
    @catalog
    |> Enum.map(& &1.category)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @spec validation_purposes() :: [atom()]
  def validation_purposes do
    @catalog
    |> Enum.flat_map(& &1.validation_purpose)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @spec catalog() :: [map()]
  def catalog do
    @catalog
  end

  @spec example(atom()) :: {:ok, map()} | :error
  def example(id) when is_atom(id) do
    case Enum.find(@catalog, &(&1.id == id)) do
      nil -> :error
      entry -> {:ok, entry}
    end
  end

  @spec coverage_report() :: map()
  def coverage_report do
    %{
      total_examples: length(@catalog),
      ids: ids(),
      categories:
        categories()
        |> Map.new(fn category ->
          {category, Enum.count(@catalog, &(&1.category == category))}
        end),
      constructs:
        @catalog
        |> Enum.flat_map(& &1.constructs)
        |> Enum.uniq()
        |> Enum.sort(),
      parity_obligations:
        @catalog
        |> Enum.flat_map(& &1.parity_obligations)
        |> Enum.uniq()
        |> Enum.sort(),
      validation_purposes: validation_purposes()
    }
  end
end
