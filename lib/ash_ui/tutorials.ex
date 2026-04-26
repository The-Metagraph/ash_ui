defmodule AshUI.Tutorials do
  @moduledoc """
  Maintained directory and chapter contract for the Operations Control Center tutorial.

  Phase 23 introduces `tutorials/` as a first-class product surface with one
  maintained final application plus chapter checkpoint directories under
  `tutorials/code/`.
  """

  @code_heading "## Code For This Chapter"
  @supporting_examples_heading "Supporting examples:"
  @required_readme_markers [
    "# Ash UI Tutorials",
    "tutorials/operations_control_center/",
    "tutorials/code/01-project-shell/",
    "tutorials/chapter_metadata.json",
    "<!-- ash_ui:tutorial-index:start -->",
    "<!-- ash_ui:tutorial-index:end -->"
  ]

  @type chapter_entry :: map()

  @doc """
  Returns the absolute `tutorials/` root.
  """
  @spec tutorials_root() :: String.t()
  def tutorials_root do
    Path.expand("../../tutorials", __DIR__)
  end

  @doc """
  Returns the tutorial landing-page path.
  """
  @spec readme_path() :: String.t()
  def readme_path do
    Path.join(tutorials_root(), "README.md")
  end

  @doc """
  Returns the machine-readable chapter metadata path.
  """
  @spec metadata_path() :: String.t()
  def metadata_path do
    Path.join(tutorials_root(), "chapter_metadata.json")
  end

  @doc """
  Returns the chapters directory path.
  """
  @spec chapters_root() :: String.t()
  def chapters_root do
    Path.join(tutorials_root(), "chapters")
  end

  @doc """
  Returns the chapter checkpoint-code root.
  """
  @spec code_root() :: String.t()
  def code_root do
    Path.join(tutorials_root(), "code")
  end

  @doc """
  Returns the maintained final tutorial-application path.
  """
  @spec final_app_path() :: String.t()
  def final_app_path do
    Path.join(tutorials_root(), "operations_control_center")
  end

  @doc """
  Loads the checked-in tutorial chapter metadata.
  """
  @spec chapter_entries() :: [chapter_entry()]
  def chapter_entries do
    metadata_path()
    |> File.read!()
    |> Jason.decode!()
  end

  @doc """
  Returns one chapter entry by number or slug.
  """
  @spec chapter!(pos_integer() | String.t()) :: chapter_entry()
  def chapter!(number) when is_integer(number) do
    Enum.find(chapter_entries(), &(&1["number"] == number)) ||
      raise KeyError, key: number, term: :tutorial_chapters
  end

  def chapter!(slug) when is_binary(slug) do
    Enum.find(chapter_entries(), &(&1["slug"] == slug)) ||
      raise KeyError, key: slug, term: :tutorial_chapters
  end

  @doc """
  Returns only the currently implemented chapter entries.
  """
  @spec implemented_chapters() :: [chapter_entry()]
  def implemented_chapters do
    Enum.filter(chapter_entries(), &(&1["status"] == "implemented"))
  end

  @doc """
  Returns only the reserved/planned chapter entries.
  """
  @spec planned_chapters() :: [chapter_entry()]
  def planned_chapters do
    Enum.filter(chapter_entries(), &(&1["status"] == "planned"))
  end

  @doc """
  Validates the landing page markers and required tutorial paths.
  """
  @spec validate_directory_contract() :: :ok | {:error, term()}
  def validate_directory_contract do
    missing_paths =
      [
        {:readme, readme_path()},
        {:metadata, metadata_path()},
        {:chapters_root, chapters_root()},
        {:code_root, code_root()},
        {:final_app_root, final_app_path()}
      ]
      |> Enum.reject(fn {_kind, path} -> File.exists?(path) end)

    chapter_path_issues =
      chapter_entries()
      |> Enum.flat_map(fn entry ->
        chapter_path = Path.expand(entry["chapter_path"], repo_root())
        code_path = Path.expand(entry["code_path"], repo_root())

        [
          path_issue(entry, :chapter_path, chapter_path),
          path_issue(entry, :code_path, code_path)
        ]
        |> Enum.reject(&is_nil/1)
      end)

    readme_marker_issues =
      readme_path()
      |> File.read!()
      |> then(fn body ->
        Enum.reject(@required_readme_markers, &String.contains?(body, &1))
      end)

    cond do
      missing_paths != [] ->
        {:error, {:tutorial_directory_drift, %{missing_paths: missing_paths}}}

      chapter_path_issues != [] ->
        {:error, {:tutorial_directory_drift, %{chapter_path_issues: chapter_path_issues}}}

      readme_marker_issues != [] ->
        {:error, {:tutorial_readme_drift, %{missing_markers: readme_marker_issues}}}

      true ->
        :ok
    end
  end

  @doc """
  Validates the mandatory chapter-to-code reference block in every chapter doc.
  """
  @spec validate_chapter_reference_contract() :: :ok | {:error, term()}
  def validate_chapter_reference_contract do
    issues =
      Enum.flat_map(chapter_entries(), fn entry ->
        path = Path.expand(entry["chapter_path"], repo_root())
        body = File.read!(path)

        required_terms =
          [
            @code_heading,
            "Checkpoint app:",
            entry["code_path"] <> "/",
            @supporting_examples_heading
          ] ++ previous_checkpoint_terms(entry) ++ supporting_example_terms(entry)

        Enum.reject(required_terms, &String.contains?(body, &1))
        |> Enum.map(fn missing_term ->
          %{chapter: entry["slug"], chapter_path: entry["chapter_path"], missing_term: missing_term}
        end)
      end)

    if issues == [] do
      :ok
    else
      {:error, {:tutorial_reference_drift, issues}}
    end
  end

  defp previous_checkpoint_terms(%{"previous_code_path" => nil}), do: ["Previous checkpoint: none."]

  defp previous_checkpoint_terms(%{"previous_code_path" => previous_code_path}) do
    ["Previous checkpoint:", previous_code_path <> "/"]
  end

  defp supporting_example_terms(%{"supporting_examples" => supporting_examples})
       when is_list(supporting_examples) do
    Enum.map(supporting_examples, &"examples/#{&1}")
  end

  defp supporting_example_terms(_entry), do: []

  defp path_issue(entry, kind, path) do
    if File.exists?(path) do
      nil
    else
      %{chapter: entry["slug"], kind: kind, missing_path: path}
    end
  end

  defp repo_root do
    Path.expand("../..", __DIR__)
  end
end
