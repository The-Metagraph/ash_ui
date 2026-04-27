defmodule AshUI.Tutorials.Phase27 do
  @moduledoc """
  Phase 27 helper contract for the runtime-introspection and role-aware tutorial checkpoints.

  Chapters 10 and 11 deepen the Operations Control Center twice: first by
  exposing explicit runtime review surfaces, then by teaching how those same
  screens behave under different actor roles and Ash policy constraints.
  """

  alias AshUI.Tutorials
  alias AshUI.Tutorials.Phase23

  @implemented_checkpoint_numbers [10, 11]
  @chapter_source_paths %{
    10 => "tutorials/code/10-runtime-introspection/lib/ash_ui_tutorials/runtime_introspection.ex",
    11 => "tutorials/code/11-roles-and-policies/lib/ash_ui_tutorials/roles_and_policies.ex"
  }
  @chapter_modules %{
    10 => AshUITutorials.RuntimeIntrospection,
    11 => AshUITutorials.RolesAndPolicies
  }
  @chapter_mix_project_modules %{
    10 => AshUITutorials.RuntimeIntrospection.MixProject,
    11 => AshUITutorials.RolesAndPolicies.MixProject
  }
  @chapter_artifact_markers %{
    10 => [
      "../code/10-runtime-introspection/lib/ash_ui_tutorials/runtime_introspection.ex",
      "AshUITutorials.RuntimeIntrospection.Runtime.WorkspaceState",
      "AshUITutorials.RuntimeIntrospection.UiScreen",
      "AshUITutorials.RuntimeIntrospection.UiElement",
      "AshUITutorials.RuntimeIntrospection.UiBinding",
      "AshUITutorials.RuntimeIntrospection.Examples.ServicesScreen",
      "AshUITutorials.RuntimeIntrospection.Examples.IncidentsScreen",
      "AshUITutorials.RuntimeIntrospection.Examples.RuntimeReviewPanelElement",
      "AshUITutorials.RuntimeIntrospection.Examples.RuntimeCommandPaletteElement",
      "AshUITutorials.RuntimeIntrospection.Examples.RuntimeTabsElement",
      "AshUITutorials.RuntimeIntrospection.Examples.RuntimeSupervisionTreeViewerElement",
      "AshUITutorials.RuntimeIntrospection.Examples.RuntimeProcessTableElement",
      "AshUITutorials.RuntimeIntrospection.Web.ServicesLive",
      "AshUITutorials.RuntimeIntrospection.Web.IncidentsLive"
    ],
    11 => [
      "../code/11-roles-and-policies/lib/ash_ui_tutorials/roles_and_policies.ex",
      "AshUITutorials.RolesAndPolicies.Runtime.WorkspaceState",
      "AshUITutorials.RolesAndPolicies.UiScreen",
      "AshUITutorials.RolesAndPolicies.UiElement",
      "AshUITutorials.RolesAndPolicies.UiBinding",
      "AshUITutorials.RolesAndPolicies.Examples.ServicesScreen",
      "AshUITutorials.RolesAndPolicies.Examples.IncidentsScreen",
      "AshUITutorials.RolesAndPolicies.Examples.OperatorFormsPanelElement",
      "AshUITutorials.RolesAndPolicies.Examples.GuardedActionsPanelElement",
      "AshUITutorials.RolesAndPolicies.Examples.RolePolicySummaryPanelElement",
      "AshUITutorials.RolesAndPolicies.Examples.AdminPolicyAuditPanelElement",
      "AshUITutorials.RolesAndPolicies.Examples.ViewerPolicyNoticePanelElement",
      "AshUI.Authorization.Checks.ScreenAccess",
      "AshUI.Authorization.Checks.ElementAccess",
      "AshUI.Authorization.Checks.BindingAccess",
      "admin-jules",
      "on-call-maya",
      "viewer-ren"
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
  Returns the implemented checkpoint numbers for Phase 27.
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
  Validates the required project structure for the implemented Phase 27 checkpoints.
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
  Validates that the implemented chapter docs reference the exact code artifacts introduced in Chapters 10 and 11.
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
