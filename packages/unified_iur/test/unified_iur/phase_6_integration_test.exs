defmodule UnifiedIUR.Phase6IntegrationTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias UnifiedIUR.{Element, Export, Fixtures, Inspect, Tooling, Validate}

  defmodule LiveUi.NativePreview do
    defstruct [:id]
  end

  test "phase 6 fixture, inspection, and export workflows cover the canonical surface" do
    assert Enum.sort(Enum.map(Fixtures.all(), & &1.id)) == Enum.sort(Fixtures.ids())

    coverage = Fixtures.coverage_report()

    assert coverage.complete?
    assert coverage.attachment_families.style_semantics.covered?
    assert coverage.attachment_families.theme_semantics.covered?
    assert coverage.attachment_families.interaction_semantics.covered?
    assert coverage.attachment_families.binding_semantics.covered?

    assert {:ok, inspection} = Inspect.fixture("advanced--operations_center")
    assert inspection.tree_summary.total_elements >= 10
    assert inspection.render_tree =~ "command-palette"
    assert inspection.diagnostics.valid?

    assert {:ok, first_export} = Export.fixture("advanced--operations_center", :snapshot)
    assert {:ok, second_export} = Export.fixture("advanced--operations_center", :snapshot)
    assert first_export == second_export
    assert first_export =~ "operations-center"
    assert first_export =~ "command_palette"
  end

  test "phase 6 diagnostics and diff workflows stay actionable for maintainers" do
    unsafe =
      Element.new(:widget, :content,
        id: "unsafe-content",
        attributes: %{extra: %{native: %LiveUi.NativePreview{id: "preview-1"}}}
      )

    diagnostics = Validate.diagnostics(unsafe)

    refute diagnostics.valid?

    assert Enum.any?(diagnostics.errors, fn error ->
             error.construct_family == :interoperability and
               String.contains?(error.guidance, "runtime-native structs")
           end)

    diff =
      Export.diff(
        Fixtures.fixture!("foundational--workspace_chrome").element,
        Fixtures.fixture!("forms--profile_editor").element
      )

    refute diff.equivalent?
    assert diff.text =~ "kind"
  end

  test "phase 6 validation workflows and release gates support end-to-end package review" do
    report = Tooling.validation_report()

    assert report.fixture_validation.all_valid?
    assert report.fixture_validation.deterministic?
    assert report.parity.synchronized?
    assert report.runtime_compatibility.compatible?
    assert report.documentation_surface.complete?
    assert report.release_readiness.ready?

    parity_regression_report = Tooling.validation_report(%{foundational_widgets: [:text]})

    refute parity_regression_report.parity.synchronized?
    refute parity_regression_report.release_readiness.ready?

    Mix.Task.reenable("unified_iur.validate")

    output =
      capture_io(fn ->
        Mix.Task.run("unified_iur.validate", ["--strict"])
      end)

    assert output =~ "UnifiedIUR validation summary"
    assert output =~ "release ready?: true"
  end
end
