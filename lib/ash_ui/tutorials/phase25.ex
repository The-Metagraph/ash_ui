defmodule AshUI.Tutorials.Phase25 do
  @moduledoc """
  Phase 25 helper contract for the runbook and diagnostics tutorial checkpoints.

  Chapters 6 and 7 extend the same incidents workspace with richer incident
  guidance and the first live-shaped diagnostic surfaces while keeping the
  tutorial explicit about support limits.
  """

  alias AshUI.Tutorials
  alias AshUI.Tutorials.Phase23

  @implemented_checkpoint_numbers [6, 7]
  @chapter_source_paths %{
    6 => "tutorials/code/06-runbooks-and-attachments/lib/ash_ui_tutorials/runbooks_and_attachments.ex",
    7 => "tutorials/code/07-live-diagnostics/lib/ash_ui_tutorials/live_diagnostics.ex"
  }
  @chapter_modules %{
    6 => AshUITutorials.RunbooksAndAttachments,
    7 => AshUITutorials.LiveDiagnostics
  }
  @chapter_mix_project_modules %{
    6 => AshUITutorials.RunbooksAndAttachments.MixProject,
    7 => AshUITutorials.LiveDiagnostics.MixProject
  }
  @chapter_artifact_markers %{
    6 => [
      "../code/06-runbooks-and-attachments/lib/ash_ui_tutorials/runbooks_and_attachments.ex",
      "AshUITutorials.RunbooksAndAttachments.Runtime.WorkspaceState",
      "AshUITutorials.RunbooksAndAttachments.UiScreen",
      "AshUITutorials.RunbooksAndAttachments.UiElement",
      "AshUITutorials.RunbooksAndAttachments.UiBinding",
      "AshUITutorials.RunbooksAndAttachments.Examples.ServicesScreen",
      "AshUITutorials.RunbooksAndAttachments.Examples.IncidentsScreen",
      "AshUITutorials.RunbooksAndAttachments.Examples.RunbookReviewPanelElement",
      "AshUITutorials.RunbooksAndAttachments.Examples.RunbookSplitPaneElement",
      "AshUITutorials.RunbooksAndAttachments.Examples.RunbookMarkdownViewerElement",
      "AshUITutorials.RunbooksAndAttachments.Examples.AttachmentEvidenceCardElement",
      "AshUITutorials.RunbooksAndAttachments.Examples.AttachmentFileFieldElement",
      "AshUITutorials.RunbooksAndAttachments.Examples.AttachmentFileInputElement",
      "AshUITutorials.RunbooksAndAttachments.Examples.AttachmentReferenceLinkElement",
      "AshUITutorials.RunbooksAndAttachments.Examples.AttachmentImageElement",
      "AshUITutorials.RunbooksAndAttachments.Examples.LoadGatewayRunbookButtonElement",
      "AshUITutorials.RunbooksAndAttachments.Examples.LoadRollbackRunbookButtonElement",
      "AshUITutorials.RunbooksAndAttachments.Web.ServicesLive",
      "AshUITutorials.RunbooksAndAttachments.Web.IncidentsLive"
    ],
    7 => [
      "../code/07-live-diagnostics/lib/ash_ui_tutorials/live_diagnostics.ex",
      "AshUITutorials.LiveDiagnostics.Runtime.WorkspaceState",
      "AshUITutorials.LiveDiagnostics.UiScreen",
      "AshUITutorials.LiveDiagnostics.UiElement",
      "AshUITutorials.LiveDiagnostics.UiBinding",
      "AshUITutorials.LiveDiagnostics.Examples.ServicesScreen",
      "AshUITutorials.LiveDiagnostics.Examples.IncidentsScreen",
      "AshUITutorials.LiveDiagnostics.Examples.LiveDiagnosticsPanelElement",
      "AshUITutorials.LiveDiagnostics.Examples.DiagnosticsStatusElement",
      "AshUITutorials.LiveDiagnostics.Examples.DiagnosticsInlineFeedbackElement",
      "AshUITutorials.LiveDiagnostics.Examples.DiagnosticsLogViewerElement",
      "AshUITutorials.LiveDiagnostics.Examples.DiagnosticsStreamWidgetElement",
      "AshUITutorials.LiveDiagnostics.Examples.DiagnosticsProcessMonitorElement",
      "AshUITutorials.LiveDiagnostics.Examples.LoadGatewayDiagnosticsButtonElement",
      "AshUITutorials.LiveDiagnostics.Examples.LoadSearchDiagnosticsButtonElement",
      "AshUITutorials.LiveDiagnostics.Examples.LoadPressureDiagnosticsButtonElement",
      "AshUITutorials.LiveDiagnostics.Web.ServicesLive",
      "AshUITutorials.LiveDiagnostics.Web.IncidentsLive"
    ]
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
  Returns the implemented checkpoint numbers for Phase 25.
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
  Validates the required project structure for the implemented Phase 25 checkpoints.
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
  Validates that the implemented chapter docs reference the exact code artifacts introduced in Chapters 6 and 7.
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

  defp repo_root do
    Path.expand("../../..", __DIR__)
  end
end
