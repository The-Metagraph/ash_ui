defmodule UnifiedUi.ParityTest do
  use ExUnit.Case, async: true

  alias UnifiedUi.Parity
  alias UnifiedUi.Reference

  test "publishes a parity catalog aligned with the canonical iur catalog" do
    assert Parity.catalog() == %{
             foundational_widgets: Reference.compiled_widget_families().foundational,
             input_widgets: Reference.compiled_widget_families().input,
             navigation_widgets: Reference.compiled_widget_families().navigation,
             data_widgets: Reference.compiled_widget_families().data,
             feedback_widgets: Reference.compiled_widget_families().feedback,
             advanced_widgets: Reference.compiled_widget_families().advanced,
             form_constructs: Reference.compiled_widget_families().forms,
             container_constructs: Reference.compiled_widget_families().container,
             layout_constructs: Reference.compiled_display_system_families().layout,
             layer_constructs: Reference.compiled_display_system_families().layer,
             canvas_constructs: Reference.compiled_display_system_families().canvas
           }

    assert Parity.expected_iur_catalog() == UnifiedIUR.Extension.iur_catalog()
    assert Parity.report().synchronized?
    assert Parity.validate() == :ok
  end

  test "reports maintained examples as valid and deterministic" do
    report = Parity.validation_report()

    assert report.valid?
    assert report.parity.synchronized?
    assert report.example_compilation.all_valid?
    assert report.example_compilation.deterministic?
    assert report.example_compilation.modules == Parity.example_modules()

    assert Enum.all?(report.example_compilation.results, fn result ->
             result.valid? and result.deterministic? and is_map(result.summary)
           end)

    summary = Parity.validation_summary(report)
    assert summary =~ "UnifiedUi parity validation summary"
    assert summary =~ "parity synchronized?: true"
    assert summary =~ "example compilation deterministic?: true"
    assert summary =~ "overall valid?: true"
  end

  test "returns actionable diagnostics for parity gaps" do
    incomplete_catalog = %{Parity.catalog() | foundational_widgets: []}

    assert {:error, issues} = Parity.validate(incomplete_catalog)

    assert %{category: :foundational_widgets, kind: :missing_in_unified_ui, values: values} =
             Enum.find(issues, &(&1.category == :foundational_widgets))

    assert Enum.sort(values) == Enum.sort(UnifiedIUR.Extension.iur_catalog().foundational_widgets)

    report = Parity.validation_report(Parity.example_modules(), incomplete_catalog)

    refute report.valid?
    refute report.parity.synchronized?
    assert report.example_compilation.all_valid?
    assert report.example_compilation.deterministic?

    summary = Parity.validation_summary(report)
    assert summary =~ "overall valid?: false"
    assert summary =~ "foundational_widgets"
  end
end
