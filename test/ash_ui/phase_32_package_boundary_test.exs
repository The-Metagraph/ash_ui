defmodule AshUI.Phase32PackageBoundaryTest do
  use ExUnit.Case, async: true

  @moduletag :conformance

  describe "Section 32.1 - canonical rail catalog boundary" do
    test "right_rail is the reusable canonical rail kind" do
      assert :right_rail in UnifiedUi.WidgetComponents.kinds()
      assert :right_rail in AshUI.WidgetComponents.kinds()

      refute :doc_right_rail in UnifiedUi.WidgetComponents.kinds()
      refute :doc_right_rail in AshUI.WidgetComponents.kinds()
      refute Map.has_key?(UnifiedUi.WidgetComponents.aliases(), :doc_right_rail)
      refute Map.has_key?(AshUI.WidgetComponents.aliases(), :doc_right_rail)
    end

    test "right_rail family metadata is layer shell and callout" do
      assert {:ok, unified_component} = UnifiedUi.WidgetComponents.component(:right_rail)
      assert unified_component.family == :layer_shell_and_callout

      assert {:ok, ash_kind} = AshUI.WidgetComponents.canonical_kind(:right_rail)
      assert ash_kind == :right_rail

      assert :right_rail in UnifiedUi.WidgetComponents.component_families().layer_shell_and_callout
      assert :right_rail in AshUI.WidgetComponents.families().layer_shell_and_callout
    end

    test "document rail names stay application-owned" do
      assert {:error, diagnostic} = UnifiedUi.WidgetComponents.canonical_kind(:doc_right_rail)

      assert diagnostic == %{
               status: :unknown,
               name: :doc_right_rail,
               message:
                 ":doc_right_rail is not part of the canonical widget-component catalog or AshUi compatibility aliases."
             }
    end
  end
end
