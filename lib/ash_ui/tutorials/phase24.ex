defmodule AshUI.Tutorials.Phase24 do
  @moduledoc """
  Phase 24 helper contract for the interaction-heavy middle tutorial checkpoints.

  Chapters 3 through 5 keep the same believable operations story while adding
  filters, form workflows, and guarded overlays on top of the Phase 23
  baseline.
  """

  alias AshUI.Tutorials
  alias AshUI.Tutorials.Phase23

  @implemented_checkpoint_numbers [3, 4, 5]
  @chapter_source_paths %{
    3 => "tutorials/code/03-filtering-and-search/lib/ash_ui_tutorials/filtering_and_search.ex",
    4 =>
      "tutorials/code/04-operator-actions-and-forms/lib/ash_ui_tutorials/operator_actions_and_forms.ex",
    5 =>
      "tutorials/code/05-safe-overlays-and-guards/lib/ash_ui_tutorials/safe_overlays_and_guards.ex"
  }
  @chapter_modules %{
    3 => AshUITutorials.FilteringAndSearch,
    4 => AshUITutorials.OperatorActionsAndForms,
    5 => AshUITutorials.SafeOverlaysAndGuards
  }
  @chapter_mix_project_modules %{
    3 => AshUITutorials.FilteringAndSearch.MixProject,
    4 => AshUITutorials.OperatorActionsAndForms.MixProject,
    5 => AshUITutorials.SafeOverlaysAndGuards.MixProject
  }
  @chapter_artifact_markers %{
    3 => [
      "../code/03-filtering-and-search/lib/ash_ui_tutorials/filtering_and_search.ex",
      "AshUITutorials.FilteringAndSearch.Runtime.WorkspaceState",
      "AshUITutorials.FilteringAndSearch.UiScreen",
      "AshUITutorials.FilteringAndSearch.UiElement",
      "AshUITutorials.FilteringAndSearch.UiBinding",
      "AshUITutorials.FilteringAndSearch.Examples.ServicesScreen",
      "AshUITutorials.FilteringAndSearch.Examples.IncidentsScreen",
      "AshUITutorials.FilteringAndSearch.Examples.WorkspaceMenuElement",
      "AshUITutorials.FilteringAndSearch.Examples.CommandPaletteElement",
      "AshUITutorials.FilteringAndSearch.Examples.ServicesFiltersGroupElement",
      "AshUITutorials.FilteringAndSearch.Examples.IncidentsFiltersGroupElement",
      "AshUITutorials.FilteringAndSearch.Web.ServicesLive",
      "AshUITutorials.FilteringAndSearch.Web.IncidentsLive"
    ],
    4 => [
      "../code/04-operator-actions-and-forms/lib/ash_ui_tutorials/operator_actions_and_forms.ex",
      "AshUITutorials.OperatorActionsAndForms.Runtime.WorkspaceState",
      "AshUITutorials.OperatorActionsAndForms.UiScreen",
      "AshUITutorials.OperatorActionsAndForms.UiElement",
      "AshUITutorials.OperatorActionsAndForms.UiBinding",
      "AshUITutorials.OperatorActionsAndForms.Examples.ServicesScreen",
      "AshUITutorials.OperatorActionsAndForms.Examples.IncidentsScreen",
      "AshUITutorials.OperatorActionsAndForms.Examples.OperatorFormsPanelElement",
      "AshUITutorials.OperatorActionsAndForms.Examples.OperatorWorkflowFormElement",
      "AshUITutorials.OperatorActionsAndForms.Examples.NoteAndAssignmentGroupElement",
      "AshUITutorials.OperatorActionsAndForms.Examples.MaintenanceWindowGroupElement",
      "AshUITutorials.OperatorActionsAndForms.Examples.AcknowledgeIncidentButtonElement",
      "AshUITutorials.OperatorActionsAndForms.Examples.AssignIncidentButtonElement",
      "AshUITutorials.OperatorActionsAndForms.Examples.ScheduleMaintenanceButtonElement",
      "AshUITutorials.OperatorActionsAndForms.Web.ServicesLive",
      "AshUITutorials.OperatorActionsAndForms.Web.IncidentsLive"
    ],
    5 => [
      "../code/05-safe-overlays-and-guards/lib/ash_ui_tutorials/safe_overlays_and_guards.ex",
      "AshUITutorials.SafeOverlaysAndGuards.Runtime.WorkspaceState",
      "AshUITutorials.SafeOverlaysAndGuards.UiScreen",
      "AshUITutorials.SafeOverlaysAndGuards.UiElement",
      "AshUITutorials.SafeOverlaysAndGuards.UiBinding",
      "AshUITutorials.SafeOverlaysAndGuards.Examples.ServicesScreen",
      "AshUITutorials.SafeOverlaysAndGuards.Examples.IncidentsScreen",
      "AshUITutorials.SafeOverlaysAndGuards.Examples.GuardedActionsPanelElement",
      "AshUITutorials.SafeOverlaysAndGuards.Examples.GuardedActionsMenuElement",
      "AshUITutorials.SafeOverlaysAndGuards.Examples.GuardOverlayElement",
      "AshUITutorials.SafeOverlaysAndGuards.Examples.ResolveGuardDialogElement",
      "AshUITutorials.SafeOverlaysAndGuards.Examples.RestartGuardAlertElement",
      "AshUITutorials.SafeOverlaysAndGuards.Examples.OpenResolveGuardButtonElement",
      "AshUITutorials.SafeOverlaysAndGuards.Examples.OpenRestartGuardButtonElement",
      "AshUITutorials.SafeOverlaysAndGuards.Examples.OpenSilenceGuardButtonElement",
      "AshUITutorials.SafeOverlaysAndGuards.Examples.OpenDiscardNoteGuardButtonElement",
      "AshUITutorials.SafeOverlaysAndGuards.Examples.DismissGuardToastButtonElement",
      "AshUITutorials.SafeOverlaysAndGuards.Web.ServicesLive",
      "AshUITutorials.SafeOverlaysAndGuards.Web.IncidentsLive"
    ]
  }

  @doc """
  Returns the implemented checkpoint numbers for Phase 24.
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
  Validates the required project structure for the implemented Phase 24 checkpoints.
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
  Validates that the implemented chapter docs reference the exact code artifacts introduced in Chapters 3 through 5.
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

  defp repo_root do
    Path.expand("../../..", __DIR__)
  end
end
