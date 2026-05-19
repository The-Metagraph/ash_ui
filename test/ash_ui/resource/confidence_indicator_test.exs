defmodule AshUI.Resource.ConfidenceIndicatorTest do
  use ExUnit.Case, async: true

  alias AshUI.DSL.Storage
  alias AshUI.Resources.Validations.Authoring

  describe "confidence_indicator authoring admission" do
    test "admits confidence_indicator as a baseline widget type" do
      assert Storage.valid_widget_type?("confidence_indicator")
      assert Storage.canonical_widget_type(:confidence_indicator) == {:ok, "confidence_indicator"}

      assert %{type: :confidence_indicator} =
               Authoring.validate_element_definition!(%{
                 type: :confidence_indicator,
                 props: %{value: 0.87}
               })
    end
  end
end
