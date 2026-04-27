defmodule AshUI.Tutorials.Phase28 do
  @moduledoc """
  Phase 28 helper contract for the production-polish checkpoint and maintained final tutorial app.

  Chapter 12 closes the written tutorial by turning the Operations Control
  Center into a more complete teaching surface, then syncing the maintained
  final application forward to that same milestone with only documented naming
  and packaging differences.
  """

  alias AshUI.Tutorials
  alias AshUI.Tutorials.Phase23

  @implemented_checkpoint_numbers [12]
  @chapter_source_paths %{
    12 => "tutorials/code/12-production-polish/lib/ash_ui_tutorials/production_polish.ex"
  }
  @chapter_stylesheet_paths %{
    12 => "tutorials/code/12-production-polish/assets/css/app.css"
  }
  @chapter_modules %{
    12 => AshUITutorials.ProductionPolish
  }
  @chapter_mix_project_modules %{
    12 => AshUITutorials.ProductionPolish.MixProject
  }
  @chapter_artifact_markers %{
    12 => [
      "../code/12-production-polish/",
      "../code/12-production-polish/lib/ash_ui_tutorials/production_polish.ex",
      "../code/11-roles-and-policies/",
      "../operations_control_center/",
      "AshUITutorials.ProductionPolish.Runtime.WorkspaceState",
      "AshUITutorials.ProductionPolish.Web.Components.TutorialShell",
      "AshUITutorials.ProductionPolish.Examples.ServicesProductionPolishPanelElement",
      "AshUITutorials.ProductionPolish.Examples.IncidentsProductionPolishPanelElement",
      "AshUITutorials.ProductionPolish.Examples.ReviewStateStatusElement",
      "AshUITutorials.ProductionPolish.Examples.ReviewStateInlineFeedbackElement",
      "AshUITutorials.ProductionPolish.Examples.ShowServicesLoadingStateButtonElement",
      "AshUITutorials.ProductionPolish.Examples.ShowIncidentsErrorStateButtonElement",
      "experience_mode"
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
  @final_app_readme_markers [
    "../code/12-production-polish/",
    "Allowed Differences From Chapter 12",
    "tutorial_directory: \"operations_control_center\"",
    "operations-control-center-*",
    "AshUITutorials.OperationsControlCenter",
    "AshUITutorials.ProductionPolish"
  ]
  @responsive_stylesheet_markers [
    ":focus-visible",
    ".ashui-tutorial-skip-link",
    ".ashui-tutorial-runtime-links",
    "@media (prefers-reduced-motion: reduce)",
    "@media (max-width: 760px)"
  ]

  @doc """
  Returns the implemented checkpoint numbers for Phase 28.
  """
  @spec implemented_checkpoint_numbers() :: [pos_integer()]
  def implemented_checkpoint_numbers, do: @implemented_checkpoint_numbers

  @doc """
  Returns the absolute project path for the Chapter 12 checkpoint.
  """
  @spec chapter_project_path(pos_integer()) :: String.t()
  def chapter_project_path(number) do
    number
    |> Tutorials.chapter!()
    |> Map.fetch!("code_path")
    |> Path.expand(repo_root())
  end

  @doc """
  Returns the absolute source path for the Chapter 12 checkpoint module.
  """
  @spec chapter_source_path(pos_integer()) :: String.t()
  def chapter_source_path(number) do
    @chapter_source_paths
    |> Map.fetch!(number)
    |> Path.expand(repo_root())
  end

  @doc """
  Returns the absolute stylesheet path for the Chapter 12 checkpoint.
  """
  @spec chapter_stylesheet_path(pos_integer()) :: String.t()
  def chapter_stylesheet_path(number) do
    @chapter_stylesheet_paths
    |> Map.fetch!(number)
    |> Path.expand(repo_root())
  end

  @doc """
  Returns the root tutorial module for the Chapter 12 checkpoint.
  """
  @spec chapter_module(pos_integer()) :: module()
  def chapter_module(number), do: Map.fetch!(@chapter_modules, number)

  @doc """
  Returns the Mix project module for the Chapter 12 checkpoint.
  """
  @spec chapter_mix_project_module(pos_integer()) :: module()
  def chapter_mix_project_module(number), do: Map.fetch!(@chapter_mix_project_modules, number)

  @doc """
  Returns the maintained final tutorial-app root.
  """
  @spec final_app_project_path() :: String.t()
  def final_app_project_path do
    Tutorials.final_app_path()
  end

  @doc """
  Returns the maintained final tutorial-app source path.
  """
  @spec final_app_source_path() :: String.t()
  def final_app_source_path do
    Path.join(final_app_project_path(), "lib/ash_ui_tutorials/operations_control_center.ex")
  end

  @doc """
  Returns the maintained final tutorial-app stylesheet path.
  """
  @spec final_app_stylesheet_path() :: String.t()
  def final_app_stylesheet_path do
    Path.join(final_app_project_path(), "assets/css/app.css")
  end

  @doc """
  Returns the maintained final tutorial-app module.
  """
  @spec final_app_module() :: module()
  def final_app_module, do: AshUITutorials.OperationsControlCenter

  @doc """
  Returns the maintained final tutorial-app Mix project module.
  """
  @spec final_app_mix_project_module() :: module()
  def final_app_mix_project_module, do: AshUITutorials.OperationsControlCenter.MixProject

  @doc """
  Returns the markers that document the allowed differences for the maintained final app.
  """
  @spec documented_final_app_differences() :: [String.t()]
  def documented_final_app_differences, do: @final_app_readme_markers

  @doc """
  Validates the required project structure for the Chapter 12 checkpoint and the maintained final app.
  """
  @spec validate_project_structure() :: :ok | {:error, term()}
  def validate_project_structure do
    chapter_issues =
      Enum.flat_map(@implemented_checkpoint_numbers, fn number ->
        root_path = chapter_project_path(number)

        Enum.reject(Phase23.required_project_files(), &File.exists?(Path.join(root_path, &1)))
        |> Enum.map(fn missing_file ->
          %{kind: :checkpoint, chapter: Tutorials.chapter!(number)["slug"], root_path: root_path, missing_file: missing_file}
        end)
      end)

    final_root = final_app_project_path()

    final_issues =
      Enum.reject(Phase23.required_project_files(), &File.exists?(Path.join(final_root, &1)))
      |> Enum.map(fn missing_file ->
        %{kind: :final_app, root_path: final_root, missing_file: missing_file}
      end)

    issues = chapter_issues ++ final_issues

    if issues == [] do
      :ok
    else
      {:error, {:tutorial_project_drift, issues}}
    end
  end

  @doc """
  Validates that Chapter 12 references the exact checkpoint and final-app artifacts introduced by Phase 28.
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
  Validates that the Chapter 12 checkpoint and maintained final app still compile from authoritative screen and element resources.
  """
  @spec validate_authoritative_resource_sources() :: :ok | {:error, term()}
  def validate_authoritative_resource_sources do
    chapter_issues =
      @implemented_checkpoint_numbers
      |> Enum.flat_map(fn number ->
        source_path = chapter_source_path(number)
        body = File.read!(source_path)
        source_issues(body, source_path, Tutorials.chapter!(number)["slug"])
      end)

    final_body = File.read!(final_app_source_path())
    final_issues = source_issues(final_body, final_app_source_path(), "operations_control_center")

    issues = chapter_issues ++ final_issues

    if issues == [] do
      :ok
    else
      {:error, {:tutorial_authority_drift, issues}}
    end
  end

  @doc """
  Validates the responsive stylesheet markers for the Chapter 12 checkpoint and the maintained final app.
  """
  @spec validate_responsive_stylesheets() :: :ok | {:error, term()}
  def validate_responsive_stylesheets do
    issues =
      [
        {"12-production-polish", chapter_stylesheet_path(12)},
        {"operations_control_center", final_app_stylesheet_path()}
      ]
      |> Enum.flat_map(fn {label, stylesheet_path} ->
        body = File.read!(stylesheet_path)

        Enum.reject(@responsive_stylesheet_markers, &String.contains?(body, &1))
        |> Enum.map(fn missing_marker ->
          %{label: label, stylesheet_path: stylesheet_path, missing_marker: missing_marker}
        end)
      end)

    if issues == [] do
      :ok
    else
      {:error, {:tutorial_stylesheet_drift, issues}}
    end
  end

  @doc """
  Validates that the maintained final-app README documents the allowed Chapter 12 differences explicitly.
  """
  @spec validate_final_app_documentation() :: :ok | {:error, term()}
  def validate_final_app_documentation do
    body = File.read!(Path.join(final_app_project_path(), "README.md"))

    issues =
      Enum.reject(@final_app_readme_markers, &String.contains?(body, &1))
      |> Enum.map(fn missing_marker ->
        %{missing_marker: missing_marker}
      end)

    if issues == [] do
      :ok
    else
      {:error, {:tutorial_final_app_doc_drift, issues}}
    end
  end

  defp source_issues(body, source_path, label) do
    missing_required =
      Enum.reject(@authoritative_source_markers, &String.contains?(body, &1))
      |> Enum.map(fn missing_marker ->
        %{label: label, source_path: source_path, kind: :missing_required, marker: missing_marker}
      end)

    forbidden_present =
      Enum.filter(@forbidden_source_markers, &String.contains?(body, &1))
      |> Enum.map(fn forbidden_marker ->
        %{label: label, source_path: source_path, kind: :forbidden_marker, marker: forbidden_marker}
      end)

    missing_required ++ forbidden_present
  end

  defp repo_root do
    Path.expand("../../..", __DIR__)
  end
end
