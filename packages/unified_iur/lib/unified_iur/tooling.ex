defmodule UnifiedIUR.Tooling do
  @moduledoc """
  Namespace anchor for package-local tooling and maintainer-oriented helpers.
  """

  alias UnifiedIUR.{
    Export,
    Extension,
    Fixtures,
    Inspect,
    Interoperability,
    Normalize,
    Reference,
    Validate
  }

  @required_docs [
    "README.md",
    "lib/unified_iur.ex",
    "lib/unified_iur/tooling.ex",
    "guides/construct_families.md",
    "guides/core_model.md",
    "guides/interoperability.md",
    "guides/maintainer_workflows.md"
  ]

  @spec fixture_catalog() :: [map()]
  def fixture_catalog do
    Fixtures.catalog()
  end

  @spec inspect_fixture(String.t()) :: {:ok, map()} | :error
  def inspect_fixture(id) do
    Inspect.fixture(id)
  end

  @spec export_fixture(String.t(), Export.export_format()) :: {:ok, String.t()} | :error
  def export_fixture(id, format \\ :fixture) do
    Export.fixture(id, format)
  end

  @spec validation_diagnostics(UnifiedIUR.Element.t() | map() | keyword()) :: map()
  def validation_diagnostics(input) do
    Validate.diagnostics(input)
  end

  @spec extension_metadata() :: map()
  def extension_metadata do
    Inspect.extension_metadata()
  end

  @spec governance_gates() :: map()
  def governance_gates do
    %{
      minimum_fixture_categories: Fixtures.categories(),
      minimum_attachment_families: [
        :style_semantics,
        :theme_semantics,
        :interaction_semantics,
        :binding_semantics
      ],
      change_review_expectations: [
        :paired_unified_ui_catalog_review,
        :runtime_consumer_review_for_canonical_boundary_changes,
        :snapshot_diff_review_for_shape_changes
      ],
      release_readiness_focus: [:portability, :determinism, :extension_safety]
    }
  end

  @spec expected_unified_ui_parity_catalog() :: map()
  def expected_unified_ui_parity_catalog do
    Extension.iur_catalog()
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

  @spec validation_report(map()) :: map()
  def validation_report(unified_ui_catalog \\ expected_unified_ui_parity_catalog())
      when is_map(unified_ui_catalog) do
    fixtures = Fixtures.all()

    fixture_results =
      Enum.map(fixtures, fn fixture ->
        normalized = Normalize.element!(fixture.element)
        compatibility = Interoperability.compatibility_report(normalized)

        %{
          id: fixture.id,
          valid?: Validate.element(normalized) == :ok,
          deterministic?: Reference.equivalent?(fixture.element, normalized),
          compatibility: compatibility
        }
      end)

    coverage = Fixtures.coverage_report()

    base_report = %{
      fixture_validation: fixture_validation_report(fixture_results),
      fixture_coverage: coverage,
      parity: parity_report(unified_ui_catalog),
      runtime_compatibility: runtime_compatibility_report(fixture_results),
      documentation_surface: documentation_surface(),
      governance_gates: governance_gates()
    }

    Map.put(base_report, :release_readiness, release_readiness_report(base_report))
  end

  @spec validation_summary(map()) :: String.t()
  def validation_summary(report) when is_map(report) do
    invalid_fixtures = report.fixture_validation.invalid_fixture_ids
    nondeterministic_fixtures = report.fixture_validation.nondeterministic_fixture_ids
    missing_categories = missing_categories(report.fixture_coverage.categories)

    missing_attachment_families =
      missing_attachment_families(report.fixture_coverage.attachment_families)

    missing_docs = report.documentation_surface.missing_paths

    [
      "UnifiedIUR validation summary",
      "  fixtures valid?: #{report.fixture_validation.all_valid?}",
      "  deterministic normalization?: #{report.fixture_validation.deterministic?}",
      "  fixture coverage complete?: #{report.fixture_coverage.complete?}",
      "  attachment coverage complete?: #{report.release_readiness.attachment_coverage_complete?}",
      "  runtime compatible?: #{report.runtime_compatibility.compatible?}",
      "  unified_ui parity synchronized?: #{report.parity.synchronized?}",
      "  documentation surface complete?: #{report.documentation_surface.complete?}",
      "  release ready?: #{report.release_readiness.ready?}",
      "  invalid fixtures: #{inspect(invalid_fixtures)}",
      "  nondeterministic fixtures: #{inspect(nondeterministic_fixtures)}",
      "  missing construct categories: #{inspect(missing_categories)}",
      "  missing attachment families: #{inspect(missing_attachment_families)}",
      "  missing docs: #{inspect(missing_docs)}"
    ]
    |> Enum.join("\n")
  end

  defp fixture_validation_report(fixture_results) do
    invalid_fixture_ids =
      fixture_results
      |> Enum.reject(& &1.valid?)
      |> Enum.map(& &1.id)

    nondeterministic_fixture_ids =
      fixture_results
      |> Enum.reject(& &1.deterministic?)
      |> Enum.map(& &1.id)

    %{
      total: length(fixture_results),
      invalid_fixture_ids: invalid_fixture_ids,
      nondeterministic_fixture_ids: nondeterministic_fixture_ids,
      all_valid?: invalid_fixture_ids == [],
      deterministic?: nondeterministic_fixture_ids == []
    }
  end

  defp parity_report(unified_ui_catalog) do
    report = Extension.parity_report(unified_ui_catalog)

    %{
      synchronized?: report.synchronized?,
      categories: report.categories
    }
  end

  defp runtime_compatibility_report(fixture_results) do
    fixture_reports =
      Enum.map(fixture_results, fn fixture ->
        %{
          id: fixture.id,
          runtime_safe?: fixture.compatibility.runtime_safe?,
          issues: fixture.compatibility.issues
        }
      end)

    %{
      compatible?: Enum.all?(fixture_reports, &(&1.runtime_safe? and &1.issues == [])),
      consumers: Interoperability.runtime_consumers(),
      fixtures: fixture_reports
    }
  end

  defp release_readiness_report(report) do
    attachment_coverage_complete? =
      report.fixture_coverage.attachment_families
      |> Enum.all?(fn {_family, family_report} -> family_report.covered? end)

    criteria = [
      gate(
        :fixtures_valid,
        "All canonical fixtures validate cleanly.",
        report.fixture_validation.all_valid?
      ),
      gate(
        :deterministic_normalization,
        "Normalization preserves deterministic canonical shape.",
        report.fixture_validation.deterministic?
      ),
      gate(
        :construct_coverage,
        "Fixture suites cover all canonical widget and display-system categories.",
        report.fixture_coverage.complete?
      ),
      gate(
        :attachment_coverage,
        "Fixture suites cover style, theme, interaction, and binding semantics.",
        attachment_coverage_complete?
      ),
      gate(
        :runtime_compatibility,
        "Fixtures remain portable for runtime-library consumption.",
        report.runtime_compatibility.compatible?
      ),
      gate(
        :unified_ui_parity,
        "Canonical package parity expectations remain synchronized with unified_ui.",
        report.parity.synchronized?
      ),
      gate(
        :documentation_surface,
        "Maintainer-facing documentation surface is present for release review.",
        report.documentation_surface.complete?
      )
    ]

    %{
      ready?: Enum.all?(criteria, & &1.passed?),
      attachment_coverage_complete?: attachment_coverage_complete?,
      criteria: criteria,
      required_change_review: governance_gates().change_review_expectations
    }
  end

  defp gate(id, description, passed?) do
    %{id: id, description: description, passed?: passed?}
  end

  defp missing_categories(categories) do
    categories
    |> Enum.flat_map(fn {category, report} ->
      if report.missing == [], do: [], else: [category]
    end)
  end

  defp missing_attachment_families(attachment_families) do
    attachment_families
    |> Enum.flat_map(fn {family, report} ->
      if report.covered?, do: [], else: [family]
    end)
  end
end
