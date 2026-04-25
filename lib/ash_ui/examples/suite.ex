defmodule AshUI.Examples.Suite do
  @moduledoc """
  Maintained discovery and reporting surface for the checked-in example suite.

  The suite metadata is derived from the Phase 18-20 example definitions plus
  the checked-in catalog crosswalk so the root `examples/` landing page, review
  metadata, and validation helpers stay synchronized.
  """

  alias AshUI.Examples.{Contract, Phase18, Phase19, Phase20}

  @phase_modules [Phase18, Phase19, Phase20]
  @readme_index_start "<!-- ash_ui:example-suite-index:start -->"
  @readme_index_end "<!-- ash_ui:example-suite-index:end -->"
  @catalog_snapshot_headers [
    "directory",
    "title",
    "phase",
    "section",
    "family",
    "canonical_subject",
    "authoring_path",
    "parity_kind",
    "support_gap",
    "maintained_runtime",
    "preview_policy",
    "runtime_notes"
  ]
  @shared_shell_label "Ash HQ example shell"

  @type catalog_entry :: %{
          required(:directory) => String.t(),
          required(:title) => String.t(),
          required(:phase) => pos_integer(),
          required(:section) => String.t(),
          required(:family) => String.t(),
          required(:canonical_subject) => String.t(),
          required(:authoring_path) => String.t(),
          required(:parity_kind) => String.t(),
          required(:support_gap) => String.t(),
          required(:maintained_runtime) => String.t(),
          required(:preview_policy) => String.t(),
          required(:runtime_notes) => String.t()
        }

  @type launch_spec :: %{
          required(:directory) => String.t(),
          required(:title) => String.t(),
          required(:project_path) => String.t(),
          required(:command) => [String.t()],
          required(:shell) => String.t(),
          required(:actor_profiles) => [String.t()],
          required(:seed_profiles) => [String.t()],
          required(:runtime_modes) => [String.t()],
          required(:actor) => String.t(),
          required(:seed) => String.t(),
          required(:runtime) => String.t(),
          required(:story_text) => String.t(),
          required(:signal_text) => String.t(),
          required(:support_notice) => String.t() | nil,
          required(:launcher) => String.t(),
          required(:preview) => String.t(),
          required(:dry_run_command) => String.t()
        }

  @doc """
  Returns the checked-in JSON catalog snapshot path.
  """
  @spec catalog_metadata_path() :: String.t()
  def catalog_metadata_path do
    Path.expand("../../../examples/catalog_metadata.json", __DIR__)
  end

  @doc """
  Returns the root example-suite README path.
  """
  @spec readme_path() :: String.t()
  def readme_path do
    Path.expand("../../../examples/README.md", __DIR__)
  end

  @doc """
  Returns the combined Phase 18-20 example definitions keyed by directory.
  """
  @spec definitions_by_directory() :: %{required(String.t()) => map()}
  def definitions_by_directory do
    @phase_modules
    |> Enum.flat_map(& &1.definitions())
    |> Map.new(&{&1.directory, &1})
  end

  @doc """
  Returns the authoritative suite catalog entries in catalog order.
  """
  @spec catalog_entries() :: [catalog_entry()]
  def catalog_entries do
    definitions = definitions_by_directory()

    {:ok, %{rows: rows}} = Contract.load_catalog()

    Enum.map(rows, fn row ->
      definition = Map.fetch!(definitions, row["directory"])

      %{
        directory: row["directory"],
        title: definition.title,
        phase: String.to_integer(row["ash_ui_phase"]),
        section: Atom.to_string(definition.section),
        family: row["family"],
        canonical_subject: row["ash_ui_canonical_subject"],
        authoring_path: row["ash_ui_authoring_path"],
        parity_kind: parity_kind(row["ash_ui_authoring_path"]),
        support_gap: row["support_gap"],
        maintained_runtime: row["maintained_runtime"],
        preview_policy: row["preview_policy"],
        runtime_notes: row["notes"]
      }
    end)
  end

  @doc """
  Returns the maintained directory identifiers in catalog order.
  """
  @spec directories() :: [String.t()]
  def directories do
    Enum.map(catalog_entries(), & &1.directory)
  end

  @doc """
  Returns the checked-in example project path for a directory.
  """
  @spec project_path(String.t()) :: String.t()
  def project_path(directory) when is_binary(directory) do
    Path.expand("../../../examples/#{directory}", __DIR__)
  end

  @doc """
  Returns the compiled example definition for a directory.
  """
  @spec definition!(String.t()) :: map()
  def definition!(directory) when is_binary(directory) do
    definitions_by_directory()
    |> Map.fetch!(directory)
  end

  @doc """
  Returns the catalog entry for a directory.
  """
  @spec entry!(String.t()) :: catalog_entry()
  def entry!(directory) when is_binary(directory) do
    Enum.find(catalog_entries(), &(&1.directory == directory)) ||
      raise KeyError, key: directory, term: :example_suite_catalog
  end

  @doc """
  Returns the maintained launcher and review metadata for one example app.
  """
  @spec launch_spec(String.t(), keyword()) :: launch_spec()
  def launch_spec(directory, opts \\ []) when is_binary(directory) do
    entry = entry!(directory)
    definition = definition!(directory)
    actor_profiles = actor_profiles(entry)
    seed_profiles = seed_profiles(entry)
    runtime_modes = runtime_modes(entry)

    actor = Keyword.get(opts, :actor, hd(actor_profiles))
    seed = Keyword.get(opts, :seed, hd(seed_profiles))
    runtime = Keyword.get(opts, :runtime, hd(runtime_modes))

    validate_profile!(actor, actor_profiles, :actor)
    validate_profile!(seed, seed_profiles, :seed)
    validate_profile!(runtime, runtime_modes, :runtime)

    project_path = project_path(directory)

    %{
      directory: directory,
      title: entry.title,
      project_path: project_path,
      command: ["mix", "example.start"],
      shell: @shared_shell_label,
      actor_profiles: actor_profiles,
      seed_profiles: seed_profiles,
      runtime_modes: runtime_modes,
      actor: actor,
      seed: seed,
      runtime: runtime,
      story_text: definition.story_text,
      signal_text: definition.signal_text,
      support_notice: definition.support_notice,
      launcher: "mix ash_ui.examples.start #{directory}",
      preview: "mix ash_ui.examples.preview #{directory}",
      dry_run_command: "cd #{project_path} && MIX_ENV=dev mix example.start"
    }
  end

  @doc """
  Returns the maintained preview contract for one example app.
  """
  @spec preview_spec(String.t(), keyword()) :: map()
  def preview_spec(directory, opts \\ []) when is_binary(directory) do
    spec = launch_spec(directory, opts)
    entry = entry!(directory)

    %{
      directory: directory,
      title: spec.title,
      shell: spec.shell,
      story_text: spec.story_text,
      signal_text: spec.signal_text,
      support_notice: spec.support_notice,
      canonical_subject: entry.canonical_subject,
      parity_kind: entry.parity_kind,
      maintained_runtime: entry.maintained_runtime,
      actor: spec.actor,
      seed: spec.seed,
      runtime: spec.runtime
    }
  end

  @doc """
  Returns the checked-in catalog snapshot body.
  """
  @spec catalog_metadata_snapshot() :: String.t()
  def catalog_metadata_snapshot do
    Jason.encode!(catalog_entries(), pretty: true)
  end

  @doc """
  Renders the generated markdown index table that the root README embeds.
  """
  @spec render_readme_index() :: String.t()
  def render_readme_index do
    rows =
      Enum.map(catalog_entries(), fn entry ->
        "| `#{entry.directory}` | #{entry.title} | `#{entry.family}` | `#{entry.phase}` | `#{entry.canonical_subject}` | `#{entry.parity_kind}` | `#{entry.maintained_runtime}` |"
      end)

    Enum.join(
      [
        @readme_index_start,
        "| Directory | Title | Family | Phase | Canonical Subject | Parity | Runtime |",
        "|---|---|---|---|---|---|---|"
        | rows
      ] ++ [@readme_index_end],
      "\n"
    )
  end

  @doc """
  Validates that the checked-in JSON snapshot matches the generated catalog metadata.
  """
  @spec validate_catalog_metadata_snapshot(String.t()) :: :ok | {:error, term()}
  def validate_catalog_metadata_snapshot(path \\ catalog_metadata_path()) do
    case File.read(path) do
      {:ok, body} ->
        current = Jason.decode!(body)
        expected = Jason.decode!(catalog_metadata_snapshot())

        if current == expected do
          :ok
        else
          {:error,
           {:catalog_metadata_drift,
            %{
              path: path,
              expected_headers: @catalog_snapshot_headers,
              expected: catalog_metadata_snapshot()
            }}}
        end

      {:error, reason} ->
        {:error, {:missing_catalog_metadata, path, reason}}
    end
  end

  @doc """
  Validates that the root README embeds the generated suite index table unchanged.
  """
  @spec validate_readme_index(String.t()) :: :ok | {:error, term()}
  def validate_readme_index(path \\ readme_path()) do
    case File.read(path) do
      {:ok, body} ->
        with {:ok, current_index} <- extract_readme_index(body) do
          expected_index = render_readme_index()

          if String.trim(current_index) == String.trim(expected_index) do
            :ok
          else
            {:error, {:readme_index_drift, %{path: path, expected: expected_index}}}
          end
        end

      {:error, reason} ->
        {:error, {:missing_readme, path, reason}}
    end
  end

  defp extract_readme_index(body) do
    case Regex.run(
           ~r/#{Regex.escape(@readme_index_start)}.*#{Regex.escape(@readme_index_end)}/s,
           body
         ) do
      [section] -> {:ok, section}
      _ -> {:error, :missing_index_markers}
    end
  end

  defp parity_kind("native_widget"), do: "exact"
  defp parity_kind("promote_fallback_widget"), do: "exact"
  defp parity_kind("normalized_widget"), do: "normalized"
  defp parity_kind("specialized_input"), do: "normalized"
  defp parity_kind("composed_native_screen"), do: "composed"
  defp parity_kind("custom_widget"), do: "custom"

  defp actor_profiles(%{phase: phase}) when phase >= 20 do
    ["admin", "operator", "read_only"]
  end

  defp actor_profiles(_entry), do: ["reviewer"]

  defp seed_profiles(%{phase: phase}) when phase >= 20 do
    ["seeded_screen", "runtime_realism"]
  end

  defp seed_profiles(_entry), do: ["seeded_screen"]

  defp runtime_modes(_entry), do: ["liveview"]

  defp validate_profile!(value, allowed, option) do
    if value in allowed do
      :ok
    else
      raise ArgumentError,
            "unsupported #{option} profile #{inspect(value)}; expected one of: #{Enum.join(allowed, ", ")}"
    end
  end
end
