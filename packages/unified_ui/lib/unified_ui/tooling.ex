defmodule UnifiedUi.Tooling do
  @moduledoc """
  Maintainer-facing tooling helpers for example inspection, export, diagnostics,
  and release review workflows.
  """

  alias UnifiedUi.{Compiler, Examples, Export, Info, Signals, WidgetComponents}

  @shared_specs [
    ".spec/specs/architecture.spec.md",
    ".spec/specs/dsl_iur_symbiosis.spec.md",
    ".spec/specs/unified-ui/package.spec.md",
    ".spec/specs/unified-ui/tooling.spec.md"
  ]

  @construct_specs %{
    foundational_visual: [".spec/specs/unified-ui/widgets.spec.md"],
    input: [".spec/specs/unified-ui/widgets.spec.md", ".spec/specs/unified-ui/signals.spec.md"],
    navigation: [
      ".spec/specs/unified-ui/widgets.spec.md",
      ".spec/specs/unified-ui/signals.spec.md"
    ],
    forms: [".spec/specs/unified-ui/widgets.spec.md", ".spec/specs/unified-ui/signals.spec.md"],
    data: [".spec/specs/unified-ui/widgets.spec.md"],
    feedback: [".spec/specs/unified-ui/widgets.spec.md"],
    advanced: [
      ".spec/specs/unified-ui/widgets.spec.md",
      ".spec/specs/unified-ui/display_systems.spec.md"
    ],
    content_identity_and_disclosure: [
      ".spec/specs/unified-ui/widgets.spec.md",
      ".spec/specs/unified-ui/widget_components.spec.md"
    ],
    form_control_and_composer: [
      ".spec/specs/unified-ui/widgets.spec.md",
      ".spec/specs/unified-ui/signals.spec.md",
      ".spec/specs/unified-ui/widget_components.spec.md"
    ],
    row_and_artifact: [
      ".spec/specs/unified-ui/widgets.spec.md",
      ".spec/specs/unified-ui/signals.spec.md",
      ".spec/specs/unified-ui/widget_components.spec.md"
    ],
    workflow_progress_and_status: [
      ".spec/specs/unified-ui/widgets.spec.md",
      ".spec/specs/unified-ui/widget_components.spec.md"
    ],
    layer_shell_and_callout: [
      ".spec/specs/unified-ui/widgets.spec.md",
      ".spec/specs/unified-ui/widget_components.spec.md"
    ],
    redline_and_code: [
      ".spec/specs/unified-ui/widgets.spec.md",
      ".spec/specs/unified-ui/widget_components.spec.md"
    ],
    composition_behavior: [
      ".spec/specs/unified-ui/widgets.spec.md",
      ".spec/specs/unified-ui/widget_components.spec.md",
      ".spec/specs/unified-ui/signals.spec.md"
    ],
    layout: [".spec/specs/unified-ui/display_systems.spec.md"],
    display: [".spec/specs/unified-ui/display_systems.spec.md"],
    overlay: [".spec/specs/unified-ui/display_systems.spec.md"],
    canvas: [".spec/specs/unified-ui/display_systems.spec.md"],
    themes: [".spec/specs/unified-ui/theming.spec.md"],
    signals: [".spec/specs/unified-ui/signals.spec.md", ".spec/specs/unified-ui/compiler.spec.md"]
  }

  @required_docs [
    "README.md",
    "docs/README.md",
    "docs/user/getting-started.md",
    "docs/user/widget-catalog.md",
    "docs/user/layouts-layers-and-display.md",
    "docs/user/styling-and-themes.md",
    "docs/user/bindings-and-interactions.md",
    "docs/user/canonical-navigation.md",
    "docs/developer/architecture-overview.md",
    "docs/developer/dsl-section-model.md",
    "docs/developer/compilation-pipeline.md",
    "docs/developer/package-components.md",
    "docs/developer/canonical-navigation.md",
    "guides/dsl_model.md",
    "guides/theming_and_signals.md",
    "guides/compiler_and_parity.md",
    "guides/maintainer_workflows.md"
  ]

  @required_example_categories [
    :advanced_dashboard,
    :advanced_flow,
    :cross_cutting,
    :form_workflow,
    :foundational
  ]

  @type inspection_result :: {:ok, map()} | {:error, map()}

  @spec example_catalog() :: [map()]
  def example_catalog do
    Examples.catalog()
  end

  @spec coverage_report() :: map()
  def coverage_report do
    Examples.coverage_report()
  end

  @spec coverage_summary() :: String.t()
  def coverage_summary do
    coverage_report()
    |> inspect_term()
  end

  @spec widget_component_catalog() :: map()
  def widget_component_catalog do
    %{
      families: WidgetComponents.component_families(),
      components: WidgetComponents.catalog(),
      aliases: WidgetComponents.aliases()
    }
  end

  @spec widget_component_catalog_summary() :: String.t()
  def widget_component_catalog_summary do
    widget_component_catalog()
    |> inspect_term()
  end

  @spec inspect_example(atom()) :: inspection_result() | :error
  def inspect_example(id) when is_atom(id) do
    with {:ok, example} <- Examples.example(id),
         {:ok, report} <- inspect_module(example.module) do
      {:ok,
       report
       |> Map.put(:example, Map.drop(example, [:module]))
       |> Map.put(:review_artifact, example.review_artifact)}
    end
  end

  @spec inspect_module(module()) :: inspection_result()
  def inspect_module(module) when is_atom(module) do
    try do
      composition = Info.composition_summary(module)
      module_summary = Info.inspect_module(module)
      compiler_report = Compiler.inspection(module)
      construct_families = composition |> collect_construct_families() |> Enum.sort()

      {:ok,
       %{
         module: module,
         authored: module_summary,
         compiler: compiler_report,
         construct_families: construct_families,
         signal_coverage: signal_coverage(module_summary.signal_catalog),
         related_examples: related_examples(construct_families, module),
         related_specs: related_specs(construct_families)
       }}
    rescue
      error ->
        {:error, diagnostic_report(module, error)}
    end
  end

  @spec module_diagnostics(module()) :: map()
  def module_diagnostics(module) when is_atom(module) do
    case inspect_module(module) do
      {:ok, report} ->
        %{
          status: :ok,
          module: module,
          construct_families: report.construct_families,
          related_examples: Enum.map(report.related_examples, & &1.id),
          related_specs: report.related_specs,
          summary: report.compiler.summary,
          signal_coverage: report.signal_coverage
        }

      {:error, diagnostics} ->
        diagnostics
    end
  end

  @spec diagnostics_summary(module()) :: String.t()
  def diagnostics_summary(module) when is_atom(module) do
    module
    |> module_diagnostics()
    |> render_diagnostics()
  end

  @spec diff_examples(atom(), atom()) :: {:ok, map()} | :error
  def diff_examples(left_id, right_id) when is_atom(left_id) and is_atom(right_id) do
    with {:ok, left} <- Examples.example(left_id),
         {:ok, right} <- Examples.example(right_id) do
      {:ok,
       diff_modules(left.module, right.module)
       |> Map.put(:left_example, left_id)
       |> Map.put(:right_example, right_id)}
    end
  end

  @spec diff_modules(module(), module()) :: map()
  def diff_modules(left_module, right_module)
      when is_atom(left_module) and is_atom(right_module) do
    {:ok, left} = inspect_module(left_module)
    {:ok, right} = inspect_module(right_module)

    constructs =
      (left.construct_families ++ right.construct_families)
      |> Enum.uniq()
      |> Enum.sort()

    %{
      left: left_module,
      right: right_module,
      snapshot_changed?: left.compiler.snapshot != right.compiler.snapshot,
      changes: %{
        widget_kinds:
          delta(
            left.compiler.listing.compiled.widget_kinds,
            right.compiler.listing.compiled.widget_kinds
          ),
        layout_kinds:
          delta(
            left.compiler.listing.compiled.layout_kinds,
            right.compiler.listing.compiled.layout_kinds
          ),
        layer_kinds:
          delta(
            left.compiler.listing.compiled.layer_kinds,
            right.compiler.listing.compiled.layer_kinds
          ),
        signal_ids: delta(left.compiler.listing.signals.ids, right.compiler.listing.signals.ids),
        binding_names:
          delta(left.compiler.listing.bindings.names, right.compiler.listing.bindings.names),
        theme_ids:
          delta(left.compiler.listing.themes.theme_ids, right.compiler.listing.themes.theme_ids)
      },
      related_specs: related_specs(constructs)
    }
  end

  @spec render_diagnostics(map()) :: String.t()
  def render_diagnostics(%{status: :ok} = diagnostics) do
    [
      "UnifiedUi diagnostics",
      "status: ok",
      "module: #{inspect(diagnostics.module)}",
      "construct families: #{inspect(diagnostics.construct_families)}",
      "related examples: #{inspect(diagnostics.related_examples)}",
      "related specs: #{inspect(diagnostics.related_specs)}",
      "signal families: #{inspect(diagnostics.signal_coverage.families)}",
      "binding names: #{inspect(diagnostics.signal_coverage.binding_names)}",
      "navigation target kinds: #{inspect(diagnostics.signal_coverage.interaction_target_kinds)}",
      "navigation descriptors: #{inspect(diagnostics.signal_coverage.navigation_descriptors, sort_maps: true)}"
    ]
    |> Enum.join("\n")
  end

  def render_diagnostics(%{status: :error} = diagnostics) do
    [
      "UnifiedUi diagnostics",
      "status: error",
      "module: #{inspect(diagnostics.module)}",
      "error kind: #{inspect(diagnostics.error)}",
      "message: #{diagnostics.message}",
      "related examples: #{inspect(diagnostics.related_examples)}",
      "related specs: #{inspect(diagnostics.related_specs)}",
      "hints: #{inspect(diagnostics.hints)}"
    ]
    |> Enum.join("\n")
  end

  @spec export_example(atom(), Export.export_format()) :: {:ok, String.t()} | :error
  def export_example(id, format \\ :inspection) when is_atom(id) do
    Export.example(id, format)
  end

  @spec export_module(module(), Export.export_format()) :: {:ok, String.t()} | {:error, map()}
  def export_module(module, format \\ :inspection) when is_atom(module) do
    Export.module(module, format)
  end

  @spec governance_gates() :: map()
  def governance_gates do
    %{
      minimum_example_categories: @required_example_categories,
      minimum_parity_obligations: expected_parity_obligations(),
      change_review_expectations: [
        :compiled_output_review_for_maintained_examples,
        :unified_iur_parity_review_for_catalog_changes,
        :signal_surface_review_for_interaction_changes
      ],
      release_readiness_focus: [
        :deterministic_compilation,
        :bilateral_parity,
        :signal_surface_clarity,
        :documentation_surface
      ]
    }
  end

  @spec documentation_surface() :: map()
  def documentation_surface do
    root = File.cwd!()

    present_paths =
      @required_docs
      |> Enum.filter(&File.exists?(Path.join(root, &1)))
      |> Enum.sort()

    %{
      required_paths: @required_docs,
      present_paths: present_paths,
      missing_paths: @required_docs -- present_paths,
      complete?: length(present_paths) == length(@required_docs)
    }
  end

  @spec validation_report() :: map()
  def validation_report do
    parity_report = UnifiedUi.Parity.validation_report()
    coverage = coverage_report()
    docs = documentation_surface()
    signal_surface = signal_surface_report()

    report = %{
      example_coverage: example_coverage_report(coverage),
      signal_surface: signal_surface,
      parity: parity_report.parity,
      example_compilation: parity_report.example_compilation,
      documentation_surface: docs,
      governance_gates: governance_gates()
    }

    Map.put(report, :release_readiness, release_readiness_report(report))
  end

  @spec validation_summary(map()) :: String.t()
  def validation_summary(report) when is_map(report) do
    [
      "UnifiedUi validation summary",
      "  example compilation valid?: #{report.example_compilation.all_valid?}",
      "  example compilation deterministic?: #{report.example_compilation.deterministic?}",
      "  parity synchronized?: #{report.parity.synchronized?}",
      "  example coverage complete?: #{report.example_coverage.complete?}",
      "  signal coverage canonical?: #{report.signal_surface.canonical_only?}",
      "  documentation surface complete?: #{report.documentation_surface.complete?}",
      "  release ready?: #{report.release_readiness.ready?}",
      "  missing example categories: #{inspect(report.example_coverage.missing_categories)}",
      "  missing parity obligations: #{inspect(report.example_coverage.missing_parity_obligations)}",
      "  missing docs: #{inspect(report.documentation_surface.missing_paths)}"
    ]
    |> Enum.join("\n")
  end

  defp signal_coverage(signal_catalog) do
    %{
      namespace: signal_catalog.namespace,
      mode: signal_catalog.mode,
      binding_names:
        signal_catalog.bindings
        |> Enum.map(& &1.id)
        |> sort_terms(),
      interaction_ids:
        signal_catalog.interactions
        |> Enum.map(& &1.id)
        |> sort_terms(),
      families:
        signal_catalog.interactions
        |> Enum.map(& &1.family)
        |> Enum.uniq()
        |> Enum.sort(),
      interaction_target_kinds:
        signal_catalog.interactions
        |> Enum.map(fn interaction ->
          {interaction.id, Signals.navigation_target_kind(interaction)}
        end)
        |> Enum.into(%{}),
      navigation_descriptors: signal_catalog.navigation_descriptors,
      navigation_actions: Signals.navigation_actions(),
      navigation_contract: UnifiedUi.Reference.navigation_contract(),
      target_bindings:
        signal_catalog.interactions
        |> Enum.flat_map(fn interaction ->
          binding_refs =
            interaction
            |> Map.get(:binding_refs, [])
            |> List.wrap()
            |> Enum.map(&Map.get(&1, :id, &1["id"]))

          target_binding =
            interaction
            |> Map.get(:target_intent, %{})
            |> Map.get(:binding)
            |> List.wrap()

          binding_refs ++ target_binding
        end)
        |> sort_terms()
    }
  end

  defp signal_surface_report do
    example_reports =
      Examples.catalog()
      |> Enum.map(fn example ->
        signal_coverage =
          example.module
          |> Info.inspect_module()
          |> Map.fetch!(:signal_catalog)
          |> signal_coverage()

        %{
          id: example.id,
          bindings: signal_coverage.binding_names,
          interactions: signal_coverage.interaction_ids,
          families: signal_coverage.families,
          canonical?: signal_coverage.mode == :canonical
        }
      end)

    %{
      example_ids_with_signals:
        example_reports
        |> Enum.filter(&(length(&1.bindings) > 0 or length(&1.interactions) > 0))
        |> Enum.map(& &1.id),
      families:
        example_reports
        |> Enum.flat_map(& &1.families)
        |> sort_terms(),
      canonical_only?: Enum.all?(example_reports, & &1.canonical?),
      total_bindings:
        example_reports
        |> Enum.flat_map(& &1.bindings)
        |> length(),
      total_interactions:
        example_reports
        |> Enum.flat_map(& &1.interactions)
        |> length()
    }
  end

  defp example_coverage_report(coverage) do
    covered_categories = coverage.categories |> Map.keys() |> sort_terms()
    covered_obligations = sort_terms(coverage.parity_obligations)
    missing_categories = @required_example_categories -- covered_categories
    missing_parity_obligations = expected_parity_obligations() -- covered_obligations

    %{
      total_examples: coverage.total_examples,
      categories: coverage.categories,
      covered_categories: covered_categories,
      missing_categories: missing_categories,
      parity_obligations: covered_obligations,
      missing_parity_obligations: missing_parity_obligations,
      validation_purposes: coverage.validation_purposes,
      complete?: missing_categories == [] and missing_parity_obligations == []
    }
  end

  defp release_readiness_report(report) do
    criteria = [
      gate(
        :example_compilation,
        "Maintained examples compile successfully.",
        report.example_compilation.all_valid?
      ),
      gate(
        :deterministic_examples,
        "Maintained examples compile deterministically.",
        report.example_compilation.deterministic?
      ),
      gate(
        :parity,
        "UnifiedUi stays synchronized with canonical UnifiedIUR.",
        report.parity.synchronized?
      ),
      gate(
        :example_coverage,
        "Maintained examples cover the required authored categories and parity obligations.",
        report.example_coverage.complete?
      ),
      gate(
        :canonical_signals,
        "Maintained examples exercise canonical signal authoring without renderer leakage.",
        report.signal_surface.canonical_only? and
          report.signal_surface.example_ids_with_signals != []
      ),
      gate(
        :documentation_surface,
        "Maintainer-facing documentation exists for DSL, signals, compiler, and workflows.",
        report.documentation_surface.complete?
      )
    ]

    %{
      ready?: Enum.all?(criteria, & &1.passed?),
      criteria: criteria,
      required_change_review: governance_gates().change_review_expectations
    }
  end

  defp expected_parity_obligations do
    UnifiedUi.Parity.catalog()
    |> Map.keys()
    |> sort_terms()
  end

  defp gate(id, description, passed?) do
    %{id: id, description: description, passed?: passed?}
  end

  defp related_examples(construct_families, exclude_module) do
    Examples.catalog()
    |> Enum.reject(&(&1.module == exclude_module))
    |> Enum.filter(fn example ->
      Enum.any?(example.constructs, &(&1 in construct_families))
    end)
    |> Enum.map(&Map.drop(&1, [:module]))
  end

  defp related_specs(construct_families) do
    construct_specs =
      construct_families
      |> Enum.flat_map(&Map.get(@construct_specs, &1, []))

    (@shared_specs ++ construct_specs)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp collect_construct_families(nodes) do
    Enum.flat_map(nodes, fn node ->
      [node.family | collect_construct_families(Map.get(node, :children, []))]
    end)
    |> Enum.uniq()
  end

  defp diagnostic_report(module, error) do
    %{
      status: :error,
      module: module,
      error: error.__struct__,
      message: Exception.message(error),
      related_examples: Enum.map(Examples.catalog(), & &1.id),
      related_specs: @shared_specs,
      hints: [
        "review the compiler inspection and signal summaries for a nearby maintained example",
        "check the construct-specific package specs linked in related_specs",
        "use UnifiedUi.Tooling.diff_examples/2 to compare the changed authored surface against a maintained reference"
      ]
    }
  end

  defp inspect_term(term) do
    inspect(term, pretty: true, width: 100, limit: :infinity, sort_maps: true)
  end

  defp delta(left, right) do
    %{
      added: sort_terms(right -- left),
      removed: sort_terms(left -- right),
      unchanged: sort_terms(left -- (left -- right))
    }
  end

  defp sort_terms(terms) do
    terms
    |> Enum.uniq()
    |> Enum.sort_by(&to_string/1)
  end
end
