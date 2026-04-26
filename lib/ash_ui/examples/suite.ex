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
  @review_snapshot_headers [
    "directory",
    "title",
    "phase",
    "family",
    "canonical_subject",
    "parity_kind",
    "shared_theme",
    "interaction_story_status",
    "signal_preview_status",
    "launcher",
    "preview",
    "actor_profiles",
    "seed_profiles",
    "runtime_modes",
    "support_status",
    "support_notice"
  ]
  @shared_shell_label "Ash HQ example shell"
  @required_project_files [
    {:mix_exs, "mix.exs"},
    {:readme, "README.md"},
    {:config, "config/config.exs"},
    {:theme_css, "assets/css/app.css"}
  ]
  @required_source_markers [
    {:resource_authority_create, "Authority.create("},
    {:screen_dsl, "use AshUI.Resource.DSL.Screen"},
    {:element_dsl, "use AshUI.Resource.DSL.Element"}
  ]
  @required_theme_markers [
    {:theme_shell, ".ashui-example-shell"},
    {:theme_panel, ".ashui-example-panel"},
    {:theme_gradient, "--ashui-example-primary-gradient"}
  ]
  @required_review_markers [
    {:story_surface, "Meaningful Interaction Story:"},
    {:signal_preview, "Canonical Signal Preview:"}
  ]
  @default_runtime "live_ui"
  @supported_runtimes ["live_ui", "elm_ui", "desktop_ui"]
  @runtime_aliases %{
    "desktop" => "desktop_ui",
    "desktop_ui" => "desktop_ui",
    "elm" => "elm_ui",
    "elm_ui" => "elm_ui",
    "live" => "live_ui",
    "live-ui" => "live_ui",
    "live_ui" => "live_ui",
    "liveview" => "live_ui"
  }
  @banned_governance_markers [
    {:builder_first, "AshUI.DSL.Builder"},
    {:legacy_document, "AshUI.Authoring.Document"},
    {:legacy_builder, "AshUI.Authoring.LegacyBuilder"},
    {:legacy_screen, "AshUI.Authoring.Screen"},
    {:legacy_migrator, "AshUI.Authoring.Migrator"},
    {:legacy_unified_ui, "UnifiedUi.Dsl"},
    {:legacy_authored_screen, "AuthoredScreen"},
    {:screen_document, "screen_document"},
    {:document_first, "document-first"},
    {:builder_first_text, "builder-first"},
    {:inline_fragment, "inline_fragment"},
    {:centralized_runtime, "AshUI.Examples.Runtime"}
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

  @type review_entry :: %{
          required(:directory) => String.t(),
          required(:title) => String.t(),
          required(:phase) => pos_integer(),
          required(:family) => String.t(),
          required(:canonical_subject) => String.t(),
          required(:parity_kind) => String.t(),
          required(:shared_theme) => boolean(),
          required(:interaction_story_status) => String.t(),
          required(:signal_preview_status) => String.t(),
          required(:launcher) => String.t(),
          required(:preview) => String.t(),
          required(:actor_profiles) => [String.t()],
          required(:seed_profiles) => [String.t()],
          required(:runtime_modes) => [String.t()],
          required(:support_status) => String.t(),
          required(:support_notice) => String.t()
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
  Returns the checked-in review metadata snapshot path.
  """
  @spec review_metadata_path() :: String.t()
  def review_metadata_path do
    Path.expand("../../../examples/review_metadata.json", __DIR__)
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
    Path.join(examples_root(), directory)
  end

  @doc """
  Returns the absolute root path for the checked-in example projects.
  """
  @spec examples_root() :: String.t()
  def examples_root do
    Path.expand("../../../examples", __DIR__)
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

    runtime =
      opts
      |> Keyword.get(:runtime, hd(runtime_modes))
      |> normalize_runtime!()

    validate_profile!(actor, actor_profiles, :actor)
    validate_profile!(seed, seed_profiles, :seed)
    validate_profile!(runtime, runtime_modes, :runtime)

    project_path = project_path(directory)

    %{
      directory: directory,
      title: entry.title,
      project_path: project_path,
      command: example_start_command(runtime, opts),
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
      dry_run_command:
        "cd #{project_path} && MIX_ENV=dev #{Enum.join(example_start_command(runtime, opts), " ")}"
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
  Returns the maintained per-app review metadata in catalog order.
  """
  @spec review_metadata_entries() :: [review_entry()]
  def review_metadata_entries do
    Enum.map(catalog_entries(), fn entry ->
      definition = definition!(entry.directory)
      spec = launch_spec(entry.directory)

      %{
        directory: entry.directory,
        title: entry.title,
        phase: entry.phase,
        family: entry.family,
        canonical_subject: entry.canonical_subject,
        parity_kind: entry.parity_kind,
        shared_theme: true,
        interaction_story_status: review_status(definition.story_text),
        signal_preview_status: review_status(definition.signal_text),
        launcher: spec.launcher,
        preview: spec.preview,
        actor_profiles: spec.actor_profiles,
        seed_profiles: spec.seed_profiles,
        runtime_modes: spec.runtime_modes,
        support_status: support_status(entry),
        support_notice: definition.support_notice || entry.runtime_notes
      }
    end)
  end

  @doc """
  Validates that catalog entries resolve to checked-in example projects and expected app metadata.
  """
  @spec validate_catalog_projects(keyword()) :: :ok | {:error, term()}
  def validate_catalog_projects(opts \\ []) do
    issues =
      opts
      |> validation_entries()
      |> Enum.flat_map(fn entry ->
        directory_path = project_path(entry.directory, opts)
        source_path = source_path(entry.directory, opts)
        readme_path = Path.join(directory_path, "README.md")
        mix_path = Path.join(directory_path, "mix.exs")

        missing_files =
          Enum.flat_map(@required_project_files, fn {kind, relative_path} ->
            path = Path.join(directory_path, relative_path)

            if File.exists?(path) do
              []
            else
              [%{directory: entry.directory, kind: kind, path: path}]
            end
          end)

        metadata_issues =
          []
          |> maybe_add_issue(readme_matches_title?(readme_path, entry.title), %{
            directory: entry.directory,
            kind: :readme_title_mismatch,
            path: readme_path
          })
          |> maybe_add_issue(mix_supports_launcher?(mix_path), %{
            directory: entry.directory,
            kind: :missing_example_start_task_support,
            path: mix_path
          })
          |> maybe_add_issue(File.exists?(source_path), %{
            directory: entry.directory,
            kind: :missing_source,
            path: source_path
          })

        missing_files ++ metadata_issues
      end)

    if issues == [] do
      :ok
    else
      {:error, {:example_project_drift, issues}}
    end
  end

  @doc """
  Validates that the checked-in example directory tree matches the maintained catalog.
  """
  @spec validate_directory_tree_alignment(keyword()) :: :ok | {:error, term()}
  def validate_directory_tree_alignment(opts \\ []) do
    root = Keyword.get(opts, :examples_root, examples_root())

    with {:ok, entries} <- File.ls(root) do
      actual_directories =
        entries
        |> Enum.filter(&File.dir?(Path.join(root, &1)))
        |> Enum.sort()

      expected_directories =
        opts
        |> validation_entries()
        |> Enum.map(& &1.directory)
        |> Enum.sort()

      missing = expected_directories -- actual_directories
      extra = actual_directories -- expected_directories

      if missing == [] and extra == [] do
        :ok
      else
        {:error,
         {:example_directory_drift,
          %{
            root: root,
            expected_directories: expected_directories,
            actual_directories: actual_directories,
            missing: missing,
            extra: extra
          }}}
      end
    else
      {:error, reason} -> {:error, {:missing_examples_root, root, reason}}
    end
  end

  @doc """
  Validates that each example app keeps resource-authority screen persistence and resource DSL usage.
  """
  @spec validate_resource_authority_continuity(keyword()) :: :ok | {:error, term()}
  def validate_resource_authority_continuity(opts \\ []) do
    issues =
      opts
      |> validation_entries()
      |> Enum.flat_map(fn entry ->
        source_path = source_path(entry.directory, opts)

        case File.read(source_path) do
          {:ok, body} ->
            Enum.flat_map(@required_source_markers, fn {kind, marker} ->
              if String.contains?(body, marker) do
                []
              else
                [%{directory: entry.directory, kind: kind, path: source_path, marker: marker}]
              end
            end)

          {:error, reason} ->
            [
              %{
                directory: entry.directory,
                kind: :missing_source,
                path: source_path,
                reason: reason
              }
            ]
        end
      end)

    if issues == [] do
      :ok
    else
      {:error, {:resource_authority_drift, issues}}
    end
  end

  @doc """
  Validates that the shared Ash HQ theme baseline assets remain aligned and present.
  """
  @spec validate_theme_baseline_alignment() :: :ok | {:error, term()}
  def validate_theme_baseline_alignment do
    Contract.validate_theme_baseline()
  end

  @doc """
  Validates that each example app uses the shared theme contract and review-surface copy.
  """
  @spec validate_theme_review_contract(keyword()) :: :ok | {:error, term()}
  def validate_theme_review_contract(opts \\ []) do
    issues =
      opts
      |> validation_entries()
      |> Enum.flat_map(fn entry ->
        css_path = theme_css_path(entry.directory, opts)
        readme_path = readme_path(entry.directory, opts)
        source_path = source_path(entry.directory, opts)

        theme_issues = contains_markers(css_path, @required_theme_markers, entry.directory)
        readme_issues = contains_markers(readme_path, @required_review_markers, entry.directory)
        source_issues = contains_markers(source_path, @required_review_markers, entry.directory)

        def_theme_issue =
          if File.exists?(source_path) and
               String.contains?(File.read!(source_path), "def theme_css") do
            []
          else
            [%{directory: entry.directory, kind: :missing_theme_css_helper, path: source_path}]
          end

        theme_issues ++ readme_issues ++ source_issues ++ def_theme_issue
      end)

    if issues == [] do
      :ok
    else
      {:error, {:theme_review_drift, issues}}
    end
  end

  @doc """
  Validates that example sources reject superseded authoring or stale shortcut markers.
  """
  @spec validate_governance(keyword()) :: :ok | {:error, term()}
  def validate_governance(opts \\ []) do
    issues =
      opts
      |> validation_entries()
      |> Enum.flat_map(fn entry ->
        paths = [source_path(entry.directory, opts), readme_path(entry.directory, opts)]

        Enum.flat_map(paths, fn path ->
          case File.read(path) do
            {:ok, body} ->
              Enum.flat_map(@banned_governance_markers, fn {kind, marker} ->
                if String.contains?(body, marker) do
                  [%{directory: entry.directory, kind: kind, path: path, marker: marker}]
                else
                  []
                end
              end)

            {:error, reason} ->
              [
                %{
                  directory: entry.directory,
                  kind: :missing_governance_surface,
                  path: path,
                  reason: reason
                }
              ]
          end
        end)
      end)

    if issues == [] do
      :ok
    else
      {:error, {:example_governance_violations, issues}}
    end
  end

  @doc """
  Runs the maintained Phase 21 example-suite validations together.
  """
  @spec validate_suite(keyword()) :: :ok | {:error, term()}
  def validate_suite(opts \\ []) do
    results = [
      {:directory_tree, validate_directory_tree_alignment(opts)},
      {:catalog_projects, validate_catalog_projects(opts)},
      {:resource_authority, validate_resource_authority_continuity(opts)},
      {:theme_baseline, validate_theme_baseline_alignment()},
      {:theme_review, validate_theme_review_contract(opts)},
      {:governance, validate_governance(opts)},
      {:catalog_metadata, validate_catalog_metadata_snapshot()},
      {:readme_index, validate_readme_index()},
      {:review_metadata_alignment, validate_review_metadata_alignment()}
    ]

    failures =
      Enum.flat_map(results, fn
        {_name, :ok} -> []
        {name, {:error, reason}} -> [%{check: name, reason: reason}]
      end)

    if failures == [] do
      :ok
    else
      {:error, {:suite_validation_failed, failures}}
    end
  end

  @doc """
  Returns the checked-in review metadata snapshot body.
  """
  @spec review_metadata_snapshot() :: String.t()
  def review_metadata_snapshot do
    Jason.encode!(review_metadata_entries(), pretty: true)
  end

  @doc """
  Validates that the checked-in review metadata snapshot matches the generated data.
  """
  @spec validate_review_metadata_snapshot(String.t()) :: :ok | {:error, term()}
  def validate_review_metadata_snapshot(path \\ review_metadata_path()) do
    case File.read(path) do
      {:ok, body} ->
        current = Jason.decode!(body)
        expected = Jason.decode!(review_metadata_snapshot())

        if current == expected do
          :ok
        else
          {:error,
           {:review_metadata_drift,
            %{
              path: path,
              expected_headers: @review_snapshot_headers,
              expected: review_metadata_snapshot()
            }}}
        end

      {:error, reason} ->
        {:error, {:missing_review_metadata, path, reason}}
    end
  end

  @doc """
  Validates that the review metadata stays aligned with the suite catalog and root README index.
  """
  @spec validate_review_metadata_alignment(String.t(), String.t()) :: :ok | {:error, term()}
  def validate_review_metadata_alignment(
        readme_path \\ readme_path(),
        review_path \\ review_metadata_path()
      ) do
    with :ok <- validate_readme_index(readme_path),
         :ok <- validate_review_metadata_snapshot(review_path) do
      readme = File.read!(readme_path)
      review_entries = Jason.decode!(File.read!(review_path))
      catalog_directories = directories()
      review_directories = Enum.map(review_entries, &Map.fetch!(&1, "directory"))
      readme_directories = extract_readme_directories(readme)

      if review_directories == catalog_directories and review_directories == readme_directories do
        :ok
      else
        {:error,
         {:review_metadata_alignment_drift,
          %{
            catalog_directories: catalog_directories,
            review_directories: review_directories,
            readme_directories: readme_directories
          }}}
      end
    end
  end

  @doc """
  Returns the maintained suite report used by the Phase 21 review workflow.
  """
  @spec suite_report() :: map()
  def suite_report do
    entries = catalog_entries()
    review_entries = review_metadata_entries()

    %{
      total_examples: length(entries),
      phases: frequency_map(entries, &Integer.to_string(&1.phase)),
      families: frequency_map(entries, & &1.family),
      parity_kinds: frequency_map(entries, & &1.parity_kind),
      directory_tree_alignment: validation_status(validate_directory_tree_alignment()),
      catalog_completeness: validation_status(validate_catalog_projects()),
      resource_authority_continuity: validation_status(validate_resource_authority_continuity()),
      theme_baseline_alignment: validation_status(validate_theme_baseline_alignment()),
      theme_contract_continuity: validation_status(validate_theme_review_contract()),
      catalog_metadata_alignment: validation_status(validate_catalog_metadata_snapshot()),
      readme_index_alignment: validation_status(validate_readme_index()),
      review_metadata_alignment: validation_status(validate_review_metadata_alignment()),
      custom_surface_examples:
        entries
        |> Enum.filter(&String.starts_with?(&1.canonical_subject, "custom:"))
        |> Enum.map(& &1.directory),
      partial_support_examples:
        review_entries
        |> Enum.filter(&(&1.support_status != "full_support"))
        |> Enum.map(& &1.directory)
    }
  end

  @doc """
  Renders the human-readable suite report used by the root mix task.
  """
  @spec render_suite_report() :: String.t()
  def render_suite_report do
    report = suite_report()

    [
      "Ash UI Example Suite Report",
      "Total examples: #{report.total_examples}",
      "Phases: #{format_frequency_map(report.phases)}",
      "Families: #{format_frequency_map(report.families)}",
      "Parity kinds: #{format_frequency_map(report.parity_kinds)}",
      "Directory-tree alignment: #{report.directory_tree_alignment}",
      "Catalog completeness: #{report.catalog_completeness}",
      "Resource-authority continuity: #{report.resource_authority_continuity}",
      "Theme-baseline alignment: #{report.theme_baseline_alignment}",
      "Theme-contract continuity: #{report.theme_contract_continuity}",
      "Catalog-metadata alignment: #{report.catalog_metadata_alignment}",
      "README-index alignment: #{report.readme_index_alignment}",
      "Review-metadata alignment: #{report.review_metadata_alignment}",
      "Custom surfaces: #{Enum.join(report.custom_surface_examples, ", ")}",
      "Partial support: #{Enum.join(report.partial_support_examples, ", ")}"
    ]
    |> Enum.join("\n")
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

  defp review_status(value) when is_binary(value) do
    if String.trim(value) == "" do
      "missing"
    else
      "present"
    end
  end

  defp support_status(%{parity_kind: "custom"}), do: "custom_surface"
  defp support_status(%{parity_kind: "exact", support_gap: "none"}), do: "full_support"
  defp support_status(_entry), do: "partial_support"

  defp validation_entries(opts) do
    Keyword.get(opts, :entries, catalog_entries())
  end

  defp project_path(directory, opts) do
    Path.join(Keyword.get(opts, :examples_root, examples_root()), directory)
  end

  defp source_path(directory, opts) do
    Path.join(project_path(directory, opts), "lib/ash_ui_examples/#{directory}.ex")
  end

  defp readme_path(directory, opts) do
    Path.join(project_path(directory, opts), "README.md")
  end

  defp theme_css_path(directory, opts) do
    Path.join(project_path(directory, opts), "assets/css/app.css")
  end

  defp readme_matches_title?(path, title) do
    case File.read(path) do
      {:ok, body} -> String.contains?(body, title)
      {:error, _reason} -> false
    end
  end

  defp mix_supports_launcher?(path) do
    case File.read(path) do
      {:ok, body} ->
        String.contains?(body, "{:ash_ui, path: \"../..\"}") and
          String.contains?(body, "\"example.start\": [&example_start/1]") and
          String.contains?(body, "@supported_runtimes [\"live_ui\", \"elm_ui\", \"desktop_ui\"]") and
          String.contains?(body, "ASH_UI_EXAMPLE_RUNTIME") and
          String.contains?(body, "runtime = normalize_runtime!(runtime)") and
          not String.contains?(body, "AshUI.Examples.Runtime") and
          String.contains?(body, "Mix.Task.run(\"phx.server\", [])")

      {:error, _reason} ->
        false
    end
  end

  defp contains_markers(path, markers, directory) do
    case File.read(path) do
      {:ok, body} ->
        Enum.flat_map(markers, fn {kind, marker} ->
          if String.contains?(body, marker) do
            []
          else
            [%{directory: directory, kind: kind, path: path, marker: marker}]
          end
        end)

      {:error, reason} ->
        [%{directory: directory, kind: :missing_surface, path: path, reason: reason}]
    end
  end

  defp maybe_add_issue(issues, true, _issue), do: issues
  defp maybe_add_issue(issues, false, issue), do: [issue | issues]

  defp extract_readme_directories(readme) do
    case extract_readme_index(readme) do
      {:ok, section} ->
        section
        |> String.split("\n", trim: true)
        |> Enum.filter(&String.starts_with?(&1, "| `"))
        |> Enum.map(fn row ->
          [_, directory | _rest] = String.split(row, "`")
          directory
        end)

      {:error, _reason} ->
        []
    end
  end

  defp frequency_map(entries, mapper) do
    entries
    |> Enum.map(mapper)
    |> Enum.frequencies()
    |> Enum.sort()
    |> Map.new()
  end

  defp validation_status(:ok), do: "pass"
  defp validation_status({:error, _reason}), do: "drift"

  defp format_frequency_map(map) do
    map
    |> Enum.map(fn {key, count} -> "#{key}=#{count}" end)
    |> Enum.join(", ")
  end

  defp actor_profiles(%{phase: phase}) when phase >= 20 do
    ["admin", "operator", "read_only"]
  end

  defp actor_profiles(_entry), do: ["reviewer"]

  defp seed_profiles(%{phase: phase}) when phase >= 20 do
    ["seeded_screen", "runtime_realism"]
  end

  defp seed_profiles(_entry), do: ["seeded_screen"]

  defp runtime_modes(_entry), do: @supported_runtimes

  defp example_start_command(runtime, opts) do
    command = ["mix", "example.start"]

    if runtime == @default_runtime and not Keyword.has_key?(opts, :runtime) do
      command
    else
      command ++ [runtime]
    end
  end

  defp normalize_runtime(nil), do: {:ok, @default_runtime}

  defp normalize_runtime(runtime) when is_binary(runtime) do
    runtime =
      runtime
      |> String.trim()
      |> String.downcase()

    case Map.fetch(@runtime_aliases, runtime) do
      {:ok, canonical} -> {:ok, canonical}
      :error -> {:error, {:unsupported_runtime, runtime, @supported_runtimes}}
    end
  end

  defp normalize_runtime!(runtime) do
    case normalize_runtime(runtime) do
      {:ok, canonical} ->
        canonical

      {:error, {:unsupported_runtime, value, supported}} ->
        raise ArgumentError,
              "unsupported runtime #{inspect(value)}; expected one of: #{Enum.join(supported, ", ")}"
    end
  end

  defp validate_profile!(value, allowed, option) do
    if value in allowed do
      :ok
    else
      raise ArgumentError,
            "unsupported #{option} profile #{inspect(value)}; expected one of: #{Enum.join(allowed, ", ")}"
    end
  end
end
