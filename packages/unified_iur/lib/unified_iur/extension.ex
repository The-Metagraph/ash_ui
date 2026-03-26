defmodule UnifiedIUR.Extension do
  @moduledoc """
  Extension, compatibility, and `unified_ui` parity guidance for canonical
  `UnifiedIUR` growth.
  """

  alias UnifiedIUR.{Canvas, Forms, Layer, Layout, Widgets}

  @container_constructs [:box]

  @spec extension_points() :: map()
  def extension_points do
    %{
      element_types: UnifiedIUR.Core.element_types(),
      metadata_fields: [:authored_ref, :description, :annotations, :tags, :extra],
      attachment_fields: [:style, :theme, :interactions, :bindings, :interaction_scope],
      additive_growth_fields: [:attributes, :metadata, :extra],
      reserved_identity_fields: [:id, :type, :kind],
      child_shape_preservation: true
    }
  end

  @spec compatibility_rules() :: map()
  def compatibility_rules do
    %{
      additive_optional_fields_allowed?: true,
      default_values_must_preserve_shape?: true,
      identity_and_type_must_remain_stable?: true,
      child_slot_order_must_remain_stable?: true,
      attachment_keys_must_remain_portable?: true
    }
  end

  @spec migration_guidance() :: map()
  def migration_guidance do
    %{
      deprecation_process: [
        :introduce_additive_shape,
        :publish_paired_unified_ui_mapping,
        :migrate_runtime_consumers,
        :remove_legacy_shape_only_after_paired_review
      ],
      shape_correction_process: [
        :record_reason,
        :add_default_or_compatibility_bridge,
        :publish_snapshot_diff_examples,
        :update_unified_ui_parity_report
      ]
    }
  end

  @spec iur_catalog() :: map()
  def iur_catalog do
    %{
      foundational_widgets: Widgets.foundational_kinds(),
      input_widgets: Widgets.input_kinds(),
      navigation_widgets: Widgets.navigation_kinds(),
      data_widgets: Widgets.data_view_kinds(),
      feedback_widgets: Widgets.feedback_kinds(),
      advanced_widgets: Widgets.advanced_kinds(),
      form_constructs: Forms.kinds(),
      container_constructs: @container_constructs,
      layout_constructs: Layout.kinds(),
      layer_constructs: Layer.kinds(),
      canvas_constructs: Canvas.kinds()
    }
  end

  @spec unified_ui_family_map() :: map()
  def unified_ui_family_map do
    %{
      widgets: %{
        foundational: Widgets.foundational_kinds(),
        input: Widgets.input_kinds(),
        navigation: Widgets.navigation_kinds(),
        data: Widgets.data_view_kinds(),
        feedback: Widgets.feedback_kinds(),
        advanced: Widgets.advanced_kinds()
      },
      display_systems: %{
        forms: Forms.kinds(),
        containers: @container_constructs,
        layouts: Layout.kinds(),
        layers: Layer.kinds(),
        canvas: Canvas.kinds()
      }
    }
  end

  @spec parity_report(map()) :: map()
  def parity_report(unified_ui_catalog) when is_map(unified_ui_catalog) do
    iur_catalog = flatten_catalog(iur_catalog())
    unified_ui_catalog = flatten_catalog(unified_ui_catalog)

    categories =
      iur_catalog
      |> Map.keys()
      |> Kernel.++(Map.keys(unified_ui_catalog))
      |> Enum.uniq()
      |> Enum.sort()

    category_reports =
      Map.new(categories, fn category ->
        iur_families = Map.get(iur_catalog, category, [])
        unified_ui_families = Map.get(unified_ui_catalog, category, [])

        {category,
         %{
           iur: iur_families,
           unified_ui: unified_ui_families,
           missing_in_iur: unified_ui_families -- iur_families,
           missing_in_unified_ui: iur_families -- unified_ui_families
         }}
      end)

    %{
      synchronized?:
        Enum.all?(category_reports, fn {_category, report} ->
          report.missing_in_iur == [] and report.missing_in_unified_ui == []
        end),
      categories: category_reports
    }
  end

  @spec validate_unified_ui_parity(map()) :: :ok | {:error, [map()]}
  def validate_unified_ui_parity(unified_ui_catalog) when is_map(unified_ui_catalog) do
    report = parity_report(unified_ui_catalog)

    issues =
      report.categories
      |> Enum.flat_map(fn {category, category_report} ->
        []
        |> maybe_issue(category, :missing_in_iur, category_report.missing_in_iur)
        |> maybe_issue(category, :missing_in_unified_ui, category_report.missing_in_unified_ui)
      end)

    if issues == [], do: :ok, else: {:error, issues}
  end

  defp flatten_catalog(catalog) do
    Map.new(catalog, fn {category, families} ->
      flattened =
        case families do
          value when is_map(value) ->
            value
            |> Map.values()
            |> List.flatten()

          value ->
            List.wrap(value)
        end
        |> List.flatten()
        |> Enum.uniq()
        |> Enum.sort()

      {category, flattened}
    end)
  end

  defp maybe_issue(issues, _category, _kind, []), do: issues

  defp maybe_issue(issues, category, kind, values) do
    issues ++ [%{category: category, kind: kind, values: values}]
  end
end
