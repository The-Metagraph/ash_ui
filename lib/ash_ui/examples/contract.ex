defmodule AshUI.Examples.Contract do
  @moduledoc """
  Validation helpers for the Phase 17 example-suite contract.

  These checks keep the catalog crosswalk and shared Ash HQ theme baseline from
  drifting before the standalone example applications land.
  """

  @required_catalog_headers [
    "directory",
    "widget",
    "family",
    "unified_ui_phase",
    "shell_kind",
    "interaction_family",
    "interaction_storytelling",
    "interaction_source",
    "ash_ui_phase",
    "ash_ui_canonical_subject",
    "ash_ui_authoring_path",
    "support_gap",
    "complexity_tier",
    "maintained_runtime",
    "preview_policy",
    "notes"
  ]

  @required_theme_doc_terms [
    "## Palette Tokens",
    "## Shared Style Profiles",
    "## Authoring-Facing Style API",
    "## Accessibility And Responsive Baseline",
    "`example_shell`",
    "`example_primary_cta`"
  ]

  @required_theme_tokens [
    "--ashui-example-bg-base",
    "--ashui-example-accent",
    "--ashui-example-accent-strong",
    "--ashui-example-signal",
    "--ashui-example-border-soft",
    "--ashui-example-primary-gradient"
  ]

  @required_theme_classes [
    ".ashui-example-shell",
    ".ashui-example-review-grid",
    ".ashui-example-panel",
    ".ashui-example-code-surface",
    ".ashui-example-primary-cta",
    ".ashui-example-secondary-cta",
    ".ashui-example-focus-ring"
  ]

  @required_theme_media_queries [
    "@media (min-width: 1024px)",
    "@media (prefers-reduced-motion: reduce)"
  ]

  @doc """
  Returns the checked-in catalog crosswalk used by the example-suite contract.
  """
  @spec default_catalog_path() :: String.t()
  def default_catalog_path do
    Path.expand("../../../examples/catalog.tsv", __DIR__)
  end

  @doc """
  Returns the sibling `unified_ui/examples` directory used for parity checks.
  """
  @spec default_sibling_examples_path() :: String.t()
  def default_sibling_examples_path do
    Path.expand("../../../../unified_ui/examples", __DIR__)
  end

  @doc """
  Returns the Ash HQ theme baseline guide consumed by contract validation.
  """
  @spec default_theme_doc_path() :: String.t()
  def default_theme_doc_path do
    Path.expand("../../../examples/ash_hq_theme_baseline.md", __DIR__)
  end

  @doc """
  Returns the shared Ash HQ theme token stylesheet consumed by contract validation.
  """
  @spec default_theme_css_path() :: String.t()
  def default_theme_css_path do
    Path.expand("../../../examples/ash_hq_theme_tokens.css", __DIR__)
  end

  @doc """
  Loads the TSV catalog and returns the parsed headers plus row maps.
  """
  @spec load_catalog(String.t()) :: {:ok, %{headers: [String.t()], rows: [map()]}} | {:error, term()}
  def load_catalog(path \\ default_catalog_path()) do
    with {:ok, body} <- read_existing(path) do
      lines =
        body
        |> String.split("\n", trim: true)
        |> Enum.reject(&(&1 == ""))

      case lines do
        [] ->
          {:error, {:empty_catalog, path}}

        [header | rows] ->
          headers = String.split(header, "\t")

          parsed_rows =
            Enum.map(rows, fn row ->
              values = String.split(row, "\t")
              Enum.zip(headers, values) |> Map.new()
            end)

          {:ok, %{headers: headers, rows: parsed_rows}}
      end
    end
  end

  @doc """
  Validates that the Ash UI catalog stays aligned with the sibling `unified_ui` example directories.
  """
  @spec validate_catalog_parity(String.t(), String.t()) :: :ok | {:error, term()}
  def validate_catalog_parity(
        catalog_path \\ default_catalog_path(),
        sibling_examples_path \\ default_sibling_examples_path()
      ) do
    with {:ok, %{headers: headers, rows: rows}} <- load_catalog(catalog_path),
         :ok <- validate_catalog_headers(headers),
         {:ok, sibling_dirs} <- sibling_directories(sibling_examples_path) do
      directories = Enum.map(rows, &Map.fetch!(&1, "directory"))
      duplicates = duplicate_values(directories)
      missing = sibling_dirs -- Enum.uniq(directories)
      extra = Enum.uniq(directories) -- sibling_dirs

      if duplicates == [] and missing == [] and extra == [] do
        :ok
      else
        {:error,
         {:catalog_drift,
          %{duplicates: duplicates, missing: missing, extra: extra, catalog: catalog_path}}}
      end
    end
  end

  @doc """
  Validates that the checked-in Ash HQ theme baseline guide and CSS expose the required contract markers.
  """
  @spec validate_theme_baseline(String.t(), String.t()) :: :ok | {:error, term()}
  def validate_theme_baseline(
        theme_doc_path \\ default_theme_doc_path(),
        theme_css_path \\ default_theme_css_path()
      ) do
    with {:ok, theme_doc} <- read_existing(theme_doc_path),
         {:ok, theme_css} <- read_existing(theme_css_path) do
      missing_doc_terms = Enum.reject(@required_theme_doc_terms, &String.contains?(theme_doc, &1))

      missing_css_tokens =
        Enum.reject(@required_theme_tokens, &String.contains?(theme_css, &1))

      missing_css_classes =
        Enum.reject(@required_theme_classes, &String.contains?(theme_css, &1))

      missing_css_media_queries =
        Enum.reject(@required_theme_media_queries, &String.contains?(theme_css, &1))

      if missing_doc_terms == [] and missing_css_tokens == [] and missing_css_classes == [] and
           missing_css_media_queries == [] do
        :ok
      else
        {:error,
         {:theme_drift,
          %{
            missing_doc_terms: missing_doc_terms,
            missing_css_tokens: missing_css_tokens,
            missing_css_classes: missing_css_classes,
            missing_css_media_queries: missing_css_media_queries,
            theme_doc: theme_doc_path,
            theme_css: theme_css_path
          }}}
      end
    end
  end

  defp validate_catalog_headers(headers) do
    missing = @required_catalog_headers -- headers

    if missing == [] do
      :ok
    else
      {:error, {:missing_catalog_headers, missing}}
    end
  end

  defp sibling_directories(path) do
    with {:ok, entries} <- File.ls(path) do
      directories =
        entries
        |> Enum.filter(&File.dir?(Path.join(path, &1)))
        |> Enum.sort()

      {:ok, directories}
    else
      {:error, reason} -> {:error, {:missing_sibling_examples, path, reason}}
    end
  end

  defp duplicate_values(values) do
    values
    |> Enum.frequencies()
    |> Enum.filter(fn {_value, count} -> count > 1 end)
    |> Enum.map(fn {value, _count} -> value end)
    |> Enum.sort()
  end

  defp read_existing(path) do
    case File.read(path) do
      {:ok, body} -> {:ok, body}
      {:error, reason} -> {:error, {:missing_file, path, reason}}
    end
  end
end
