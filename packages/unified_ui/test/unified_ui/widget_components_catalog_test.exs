defmodule UnifiedUi.WidgetComponentsCatalogTest do
  use ExUnit.Case, async: true

  alias UnifiedUi.WidgetComponents

  test "catalog groups the AshUi admissions into canonical families" do
    assert WidgetComponents.families() == [
             :content_identity_and_disclosure,
             :form_control_and_composer,
             :row_and_artifact,
             :workflow_progress_and_status,
             :layer_shell_and_callout,
             :redline_and_code,
             :composition_behavior
           ]

    assert WidgetComponents.component_families() == %{
             content_identity_and_disclosure: [
               :inline_rich_text_heading,
               :disclosure,
               :kicker,
               :avatar,
               :presence_dot,
               :unread_badge
             ],
             form_control_and_composer: [
               :runtime_form_shell,
               :segmented_button_group,
               :chat_composer
             ],
             row_and_artifact: [:list_item_multi_column, :artifact_row, :sidebar_item],
             workflow_progress_and_status: [
               :pipeline_stepper_horizontal,
               :segmented_progress_bar,
               :workflow_stage_list_vertical,
               :meter_thin
             ],
             layer_shell_and_callout: [
               :sidebar_section,
               :sticky_frosted_header,
               :slide_over_panel,
               :event_callout
             ],
             redline_and_code: [:redline_inline, :code_block_syntax_highlighted],
             composition_behavior: [:list_repeat]
           }
  end

  test "source mapping records every AshUi PR in order" do
    source_mapping = WidgetComponents.source_mapping()

    assert Enum.sort(Map.keys(source_mapping)) == Enum.to_list(79..98) ++ [101, 102, 104]
    assert source_mapping[79].canonical_kind == :inline_rich_text_heading
    assert source_mapping[81].source_name == :phoenix_form
    assert source_mapping[81].canonical_kind == :runtime_form_shell
    assert source_mapping[101].source_name == :unread_badge
    assert source_mapping[101].canonical_kind == :unread_badge
    assert source_mapping[102].source_name == :sidebar_item
    assert source_mapping[102].canonical_kind == :sidebar_item
    assert source_mapping[104].source_name == :sidebar_section
    assert source_mapping[104].canonical_kind == :sidebar_section
    assert source_mapping[98].source_name == :ui_relationship_repeat
    assert source_mapping[98].canonical_kind == :list_repeat
  end

  test "canonical name lookup accepts AshUi aliases with diagnostics" do
    assert WidgetComponents.canonical_kind(:runtime_form_shell) == {:ok, :runtime_form_shell}
    assert WidgetComponents.canonical_kind("runtime_form_shell") == {:ok, :runtime_form_shell}
    assert WidgetComponents.canonical_kind(:phoenix_form) == {:ok, :runtime_form_shell}
    assert WidgetComponents.canonical_kind("repeat") == {:ok, :list_repeat}

    assert WidgetComponents.name_diagnostic(:phoenix_form) == %{
             status: :alias,
             name: :phoenix_form,
             canonical: :runtime_form_shell,
             family: :form_control_and_composer,
             message:
               ":phoenix_form is an AshUi compatibility alias; use :runtime_form_shell for canonical UnifiedUi authoring."
           }
  end

  test "unknown names produce diagnostics without allocating atoms for strings" do
    assert {:error, diagnostic} = WidgetComponents.canonical_kind("not_in_catalog")

    assert diagnostic == %{
             status: :unknown,
             name: "not_in_catalog",
             message:
               "\"not_in_catalog\" is not part of the canonical widget-component catalog or AshUi compatibility aliases."
           }
  end

  test "package reference and tooling expose the catalog" do
    assert UnifiedUi.Widgets.component_kinds() == WidgetComponents.kinds()

    assert UnifiedUi.Widgets.component_aliases() == %{
             phoenix_form: :runtime_form_shell,
             repeat: :list_repeat,
             ui_relationship_repeat: :list_repeat
           }

    assert UnifiedUi.Reference.widget_component_families() ==
             WidgetComponents.component_families()

    assert UnifiedUi.Reference.widget_component_source_mapping()[98].canonical_kind ==
             :list_repeat

    tooling_catalog = UnifiedUi.Tooling.widget_component_catalog()

    assert tooling_catalog.families == WidgetComponents.component_families()
    assert tooling_catalog.aliases == WidgetComponents.aliases()
    assert tooling_catalog.source_mapping[81].canonical_kind == :runtime_form_shell
  end
end
