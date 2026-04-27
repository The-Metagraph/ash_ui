defmodule AshUI.Tutorials.Phase26 do
  @moduledoc """
  Phase 26 helper contract for the topology/navigation and metrics/capacity tutorial checkpoints.

  Chapters 8 and 9 extend the services workspace with structural review
  surfaces first, then layered telemetry dashboards, while keeping both
  chapters explicit about persisted state and sampled data limits.
  """

  alias AshUI.Tutorials
  alias AshUI.Tutorials.Phase23

  @implemented_checkpoint_numbers [8, 9]
  @chapter_source_paths %{
    8 => "tutorials/code/08-topology-and-navigation/lib/ash_ui_tutorials/topology_and_navigation.ex",
    9 => "tutorials/code/09-metrics-and-capacity/lib/ash_ui_tutorials/metrics_and_capacity.ex"
  }
  @chapter_modules %{
    8 => AshUITutorials.TopologyAndNavigation,
    9 => AshUITutorials.MetricsAndCapacity
  }
  @chapter_mix_project_modules %{
    8 => AshUITutorials.TopologyAndNavigation.MixProject,
    9 => AshUITutorials.MetricsAndCapacity.MixProject
  }
  @chapter_artifact_markers %{
    8 => [
      "../code/08-topology-and-navigation/lib/ash_ui_tutorials/topology_and_navigation.ex",
      "AshUITutorials.TopologyAndNavigation.Runtime.WorkspaceState",
      "AshUITutorials.TopologyAndNavigation.UiScreen",
      "AshUITutorials.TopologyAndNavigation.UiElement",
      "AshUITutorials.TopologyAndNavigation.UiBinding",
      "AshUITutorials.TopologyAndNavigation.Examples.ServicesScreen",
      "AshUITutorials.TopologyAndNavigation.Examples.IncidentsScreen",
      "AshUITutorials.TopologyAndNavigation.Examples.TopologyReviewPanelElement",
      "AshUITutorials.TopologyAndNavigation.Examples.TopologySplitPaneElement",
      "AshUITutorials.TopologyAndNavigation.Examples.TopologyScopeMenuElement",
      "AshUITutorials.TopologyAndNavigation.Examples.TopologyTabsElement",
      "AshUITutorials.TopologyAndNavigation.Examples.TopologyTreeViewElement",
      "AshUITutorials.TopologyAndNavigation.Examples.TopologyViewportElement",
      "AshUITutorials.TopologyAndNavigation.Examples.TopologyCanvasElement",
      "AshUITutorials.TopologyAndNavigation.Examples.TopologyScrollBarElement",
      "AshUITutorials.TopologyAndNavigation.Web.ServicesLive",
      "AshUITutorials.TopologyAndNavigation.Web.IncidentsLive"
    ],
    9 => [
      "../code/09-metrics-and-capacity/lib/ash_ui_tutorials/metrics_and_capacity.ex",
      "AshUITutorials.MetricsAndCapacity.Runtime.WorkspaceState",
      "AshUITutorials.MetricsAndCapacity.UiScreen",
      "AshUITutorials.MetricsAndCapacity.UiElement",
      "AshUITutorials.MetricsAndCapacity.UiBinding",
      "AshUITutorials.MetricsAndCapacity.Examples.ServicesScreen",
      "AshUITutorials.MetricsAndCapacity.Examples.IncidentsScreen",
      "AshUITutorials.MetricsAndCapacity.Examples.MetricsReviewPanelElement",
      "AshUITutorials.MetricsAndCapacity.Examples.MetricsClusterDashboardElement",
      "AshUITutorials.MetricsAndCapacity.Examples.LoadGatewayMetricsButtonElement",
      "AshUITutorials.MetricsAndCapacity.Examples.LoadSearchMetricsButtonElement",
      "AshUITutorials.MetricsAndCapacity.Examples.LoadFleetMetricsButtonElement",
      "AshUITutorials.MetricsAndCapacity.Examples.MetricsProgressElement",
      "AshUITutorials.MetricsAndCapacity.Examples.MetricsGaugeElement",
      "AshUITutorials.MetricsAndCapacity.Examples.MetricsSparklineElement",
      "AshUITutorials.MetricsAndCapacity.Examples.MetricsBarChartElement",
      "AshUITutorials.MetricsAndCapacity.Examples.MetricsLineChartElement",
      "AshUITutorials.MetricsAndCapacity.Web.ServicesLive",
      "AshUITutorials.MetricsAndCapacity.Web.IncidentsLive"
    ]
  }
  @chapter_stylesheet_markers %{
    8 => [".ashui-tutorial-topology-split", "@media (max-width: 960px)"],
    9 => [".ashui-tutorial-topology-split", ".ashui-tutorial-metrics-panel", "@media (max-width: 960px)"]
  }
  @authoritative_source_markers [
    "Authority.create(",
    "use AshUI.Resource.DSL.Screen",
    "use AshUI.Resource.DSL.Element"
  ]
  @forbidden_source_markers [
    "AshUI.DSL.Builder",
    "screen-document",
    "screen document",
    "builder-first"
  ]

  @doc """
  Returns the implemented checkpoint numbers for Phase 26.
  """
  @spec implemented_checkpoint_numbers() :: [pos_integer()]
  def implemented_checkpoint_numbers, do: @implemented_checkpoint_numbers

  @doc """
  Returns the absolute project path for one implemented checkpoint.
  """
  @spec chapter_project_path(pos_integer()) :: String.t()
  def chapter_project_path(number) do
    number
    |> Tutorials.chapter!()
    |> Map.fetch!("code_path")
    |> Path.expand(repo_root())
  end

  @doc """
  Returns the absolute source path for one implemented checkpoint module.
  """
  @spec chapter_source_path(pos_integer()) :: String.t()
  def chapter_source_path(number) do
    @chapter_source_paths
    |> Map.fetch!(number)
    |> Path.expand(repo_root())
  end

  @doc """
  Returns the absolute stylesheet path for one implemented checkpoint.
  """
  @spec chapter_stylesheet_path(pos_integer()) :: String.t()
  def chapter_stylesheet_path(number) do
    chapter_project_path(number)
    |> Path.join("assets/css/app.css")
  end

  @doc """
  Returns the root tutorial module for one implemented checkpoint.
  """
  @spec chapter_module(pos_integer()) :: module()
  def chapter_module(number), do: Map.fetch!(@chapter_modules, number)

  @doc """
  Returns the Mix project module for one implemented checkpoint.
  """
  @spec chapter_mix_project_module(pos_integer()) :: module()
  def chapter_mix_project_module(number), do: Map.fetch!(@chapter_mix_project_modules, number)

  @doc """
  Validates the required project structure for the implemented Phase 26 checkpoints.
  """
  @spec validate_project_structure() :: :ok | {:error, term()}
  def validate_project_structure do
    issues =
      Enum.flat_map(@implemented_checkpoint_numbers, fn number ->
        root_path = chapter_project_path(number)

        Enum.reject(Phase23.required_project_files(), &File.exists?(Path.join(root_path, &1)))
        |> Enum.map(fn missing_file ->
          %{chapter: Tutorials.chapter!(number)["slug"], root_path: root_path, missing_file: missing_file}
        end)
      end)

    if issues == [] do
      :ok
    else
      {:error, {:tutorial_project_drift, issues}}
    end
  end

  @doc """
  Validates that the implemented chapter docs reference the exact code artifacts introduced in Chapters 8 and 9.
  """
  @spec validate_implemented_chapter_artifacts() :: :ok | {:error, term()}
  def validate_implemented_chapter_artifacts do
    issues =
      @chapter_artifact_markers
      |> Enum.flat_map(fn {number, markers} ->
        chapter = Tutorials.chapter!(number)
        body = File.read!(Path.expand(chapter["chapter_path"], repo_root()))

        Enum.reject(markers, &String.contains?(body, &1))
        |> Enum.map(fn missing_marker ->
          %{chapter: chapter["slug"], missing_marker: missing_marker}
        end)
      end)

    if issues == [] do
      :ok
    else
      {:error, {:tutorial_artifact_reference_drift, issues}}
    end
  end

  @doc """
  Validates that the implemented checkpoint sources still compile from authoritative screen and element resources.
  """
  @spec validate_authoritative_resource_sources() :: :ok | {:error, term()}
  def validate_authoritative_resource_sources do
    issues =
      @implemented_checkpoint_numbers
      |> Enum.flat_map(fn number ->
        source_path = chapter_source_path(number)
        body = File.read!(source_path)

        missing_required =
          Enum.reject(@authoritative_source_markers, &String.contains?(body, &1))
          |> Enum.map(fn missing_marker ->
            %{chapter: Tutorials.chapter!(number)["slug"], source_path: source_path, kind: :missing_required, marker: missing_marker}
          end)

        forbidden_present =
          Enum.filter(@forbidden_source_markers, &String.contains?(body, &1))
          |> Enum.map(fn forbidden_marker ->
            %{chapter: Tutorials.chapter!(number)["slug"], source_path: source_path, kind: :forbidden_marker, marker: forbidden_marker}
          end)

        missing_required ++ forbidden_present
      end)

    if issues == [] do
      :ok
    else
      {:error, {:tutorial_authority_drift, issues}}
    end
  end

  @doc """
  Validates the responsive stylesheet markers for the implemented Phase 26 checkpoints.
  """
  @spec validate_responsive_stylesheets() :: :ok | {:error, term()}
  def validate_responsive_stylesheets do
    issues =
      @chapter_stylesheet_markers
      |> Enum.flat_map(fn {number, markers} ->
        stylesheet_path = chapter_stylesheet_path(number)
        body = File.read!(stylesheet_path)

        Enum.reject(markers, &String.contains?(body, &1))
        |> Enum.map(fn missing_marker ->
          %{chapter: Tutorials.chapter!(number)["slug"], stylesheet_path: stylesheet_path, missing_marker: missing_marker}
        end)
      end)

    if issues == [] do
      :ok
    else
      {:error, {:tutorial_stylesheet_drift, issues}}
    end
  end

  defp repo_root do
    Path.expand("../../..", __DIR__)
  end
end
