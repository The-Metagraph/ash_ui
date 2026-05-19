defmodule AshUI.Phase31PackageBoundaryTest do
  use ExUnit.Case, async: true

  @moduletag :conformance

  describe "Section 31.1 - catalog boundary and drift detection" do
    test "Ash UI mirrors the Unified UI canonical widget-component catalog" do
      assert Code.ensure_loaded?(UnifiedUi.WidgetComponents)
      assert Code.ensure_loaded?(UnifiedIUR.Widgets.Components)
      assert Code.ensure_loaded?(AshUI.WidgetComponents)

      assert AshUI.WidgetComponents.explicit_exclusions() == []
      assert AshUI.WidgetComponents.kinds() == UnifiedUi.WidgetComponents.kinds()
      assert AshUI.WidgetComponents.catalog() == UnifiedUi.WidgetComponents.catalog()
    end

    test "Ash UI mirrors Unified UI compatibility aliases" do
      assert AshUI.WidgetComponents.aliases() == UnifiedUi.WidgetComponents.aliases()

      assert AshUI.WidgetComponents.canonical_kind(:phoenix_form) ==
               {:ok, :runtime_form_shell}

      assert AshUI.WidgetComponents.canonical_kind("repeat") == {:ok, :list_repeat}

      assert AshUI.WidgetComponents.canonical_kind(:ui_relationship_repeat) ==
               {:ok, :list_repeat}
    end

    test "component families remain available at the Ash UI boundary" do
      families = AshUI.WidgetComponents.families()

      assert families.content_identity_and_disclosure == [
               :inline_rich_text_heading,
               :disclosure,
               :kicker,
               :avatar,
               :presence_dot
             ]

      assert families.form_control_and_composer == [
               :runtime_form_shell,
               :segmented_button_group,
               :chat_composer,
               :mode_nav
             ]

      assert families.row_and_artifact == [:list_item_multi_column, :artifact_row]

      assert families.workflow_progress_and_status == [
               :pipeline_stepper_horizontal,
               :segmented_progress_bar,
               :workflow_stage_list_vertical,
               :meter_thin,
               :unread_badge,
               :workflow_progress_status_card
             ]

      assert families.layer_shell_and_callout == [
               :sticky_frosted_header,
               :slide_over_panel,
               :event_callout,
               :top_strip,
               :sidebar_shell,
               :sidebar_section,
               :sidebar_item,
               :right_rail,
               :command_palette
             ]

      assert families.redline_and_code == [:redline_inline, :code_block_syntax_highlighted]
      assert families.composition_behavior == [:list_repeat]
    end

    test "unknown names return the upstream catalog diagnostic" do
      assert {:error, diagnostic} = AshUI.WidgetComponents.canonical_kind(:not_in_catalog)

      assert diagnostic == %{
               status: :unknown,
               name: :not_in_catalog,
               message:
                 ":not_in_catalog is not part of the canonical widget-component catalog or AshUi compatibility aliases."
             }
    end
  end
end
