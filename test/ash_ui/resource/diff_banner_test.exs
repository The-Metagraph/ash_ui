defmodule AshUI.Resource.DiffBannerTest do
  use ExUnit.Case, async: true

  alias AshUI.DSL.Storage
  alias AshUI.Resources.Validations.Authoring

  describe "diff_banner authoring admission" do
    test "admits diff_banner as a baseline feedback widget type" do
      assert Storage.valid_widget_type?("diff_banner")
      assert Storage.canonical_widget_type(:diff_banner) == {:ok, "diff_banner"}

      assert %{type: :diff_banner} =
               Authoring.validate_element_definition!(%{
                 type: :diff_banner,
                 props: %{new_count: 3, changed_count: 2, removed_count: 1}
               })
    end

    test "allows diff_banner filter actions" do
      definition = %{type: :diff_banner, props: %{filter_intent: :filter_diff}}

      action =
        Authoring.validate_action_definition!(%{
          id: :filter_diff,
          signal: :change,
          source: %{resource: "Demo.Finding", action: "filter"},
          target: "diff_filter"
        })

      assert :ok = Authoring.validate_element_authority!(definition, [], [action])
    end
  end
end
