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
end
