defmodule UnifiedUi.Parity do
  @moduledoc """
  Bilateral parity and validation helpers for keeping `UnifiedUi` aligned with
  canonical `UnifiedIUR`.
  """

  alias UnifiedIUR.Extension
  alias UnifiedIUR.Reference, as: IURReference
  alias UnifiedUi.Compiler
  alias UnifiedUi.Compiler.Result
  alias UnifiedUi.Reference

  @type parity_catalog :: %{
          foundational_widgets: [atom()],
          input_widgets: [atom()],
          navigation_widgets: [atom()],
          data_widgets: [atom()],
          feedback_widgets: [atom()],
          advanced_widgets: [atom()],
          form_constructs: [atom()],
          container_constructs: [atom()],
          layout_constructs: [atom()],
          layer_constructs: [atom()],
          canvas_constructs: [atom()]
        }

  @type validation_result :: %{
          module: module(),
          valid?: boolean(),
          deterministic?: boolean(),
          diagnostics: [map()],
          summary: map() | nil
        }

  @spec catalog() :: parity_catalog()
  def catalog do
    widgets = Reference.compiled_widget_families()
    display = Reference.compiled_display_system_families()

    %{
      foundational_widgets: widgets.foundational,
      input_widgets: widgets.input,
      navigation_widgets: widgets.navigation,
      data_widgets: widgets.data,
      feedback_widgets: widgets.feedback,
      advanced_widgets: widgets.advanced,
      form_constructs: widgets.forms,
      container_constructs: widgets.container,
      layout_constructs: display.layout,
      layer_constructs: display.layer,
      canvas_constructs: display.canvas
    }
  end

  @spec expected_iur_catalog() :: map()
  def expected_iur_catalog do
    Extension.iur_catalog()
  end

  @spec report(parity_catalog()) :: map()
  def report(parity_catalog \\ catalog()) when is_map(parity_catalog) do
    Extension.parity_report(parity_catalog)
  end

  @spec validate(parity_catalog()) :: :ok | {:error, [map()]}
  def validate(parity_catalog \\ catalog()) when is_map(parity_catalog) do
    Extension.validate_unified_ui_parity(parity_catalog)
  end

  @spec example_modules() :: [module()]
  def example_modules do
    Reference.example_catalog()
    |> Enum.map(& &1.module)
  end

  @spec validate_module(module()) :: validation_result()
  def validate_module(module) when is_atom(module) do
    try do
      result = Compiler.compile!(module)
      result_again = Compiler.compile!(module)

      deterministic? =
        IURReference.snapshot(result.iur) == IURReference.snapshot(result_again.iur)

      %{
        module: module,
        valid?: true,
        deterministic?: deterministic?,
        diagnostics:
          if(deterministic?,
            do: [],
            else: [
              %{
                kind: :nondeterministic_output,
                message: "compiled canonical IUR changed across equivalent compilations"
              }
            ]
          ),
        summary: Result.summary(result)
      }
    rescue
      error ->
        %{
          module: module,
          valid?: false,
          deterministic?: false,
          diagnostics: [
            %{
              kind: :compile_error,
              message: Exception.message(error),
              error: error.__struct__
            }
          ],
          summary: nil
        }
    end
  end

  @spec validation_report([module()], parity_catalog()) :: map()
  def validation_report(modules \\ example_modules(), parity_catalog \\ catalog()) do
    example_results = Enum.map(modules, &validate_module/1)
    parity = report(parity_catalog)

    example_compilation = %{
      modules: Enum.map(example_results, & &1.module),
      results: example_results,
      all_valid?: Enum.all?(example_results, & &1.valid?),
      deterministic?: Enum.all?(example_results, & &1.deterministic?)
    }

    %{
      unified_ui_catalog: parity_catalog,
      expected_iur_catalog: expected_iur_catalog(),
      parity: parity,
      example_compilation: example_compilation,
      valid?:
        parity.synchronized? and example_compilation.all_valid? and
          example_compilation.deterministic?
    }
  end

  @spec validation_summary(map()) :: String.t()
  def validation_summary(report) when is_map(report) do
    failing_modules =
      report.example_compilation.results
      |> Enum.reject(&(&1.valid? and &1.deterministic?))
      |> Enum.map(& &1.module)

    parity_issues =
      report.parity.categories
      |> Enum.flat_map(fn {category, details} ->
        []
        |> maybe_issue(category, :missing_in_iur, details.missing_in_iur)
        |> maybe_issue(category, :missing_in_unified_ui, details.missing_in_unified_ui)
      end)

    [
      "UnifiedUi parity validation summary",
      "  parity synchronized?: #{report.parity.synchronized?}",
      "  example compilation valid?: #{report.example_compilation.all_valid?}",
      "  example compilation deterministic?: #{report.example_compilation.deterministic?}",
      "  overall valid?: #{report.valid?}",
      "  failing modules: #{inspect(failing_modules)}",
      "  parity issues: #{inspect(parity_issues)}"
    ]
    |> Enum.join("\n")
  end

  defp maybe_issue(issues, _category, _kind, []), do: issues

  defp maybe_issue(issues, category, kind, values) do
    issues ++ [%{category: category, kind: kind, values: values}]
  end
end
