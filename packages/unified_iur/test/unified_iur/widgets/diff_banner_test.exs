defmodule UnifiedIUR.Widgets.DiffBannerTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element
  alias UnifiedIUR.Widgets.Feedback

  describe "diff_banner/1" do
    test "builds a baseline feedback element with defaults" do
      element = Feedback.diff_banner()

      assert %Element{kind: :diff_banner, type: :widget} = element

      assert %{
               diff: %{
                 new_count: 0,
                 changed_count: 0,
                 removed_count: 0,
                 active_filter: :all,
                 show_filter_chips?: true,
                 size: :default
               }
             } = element.attributes

      refute Map.has_key?(element.attributes, :component)
    end

    test "builds a banner with counts, base label, and filter intent" do
      element =
        Feedback.diff_banner(
          id: "ask-diff",
          new_count: 4,
          changed_count: 7,
          removed_count: 2,
          base_label: "Compared to last run",
          active_filter: :changed,
          filter_intent: :filter_diff
        )

      assert element.id == "ask-diff"
      assert get_in(element.attributes, [:diff, :new_count]) == 4
      assert get_in(element.attributes, [:diff, :changed_count]) == 7
      assert get_in(element.attributes, [:diff, :removed_count]) == 2
      assert get_in(element.attributes, [:diff, :base_label]) == "Compared to last run"
      assert get_in(element.attributes, [:diff, :active_filter]) == :changed
      assert get_in(element.attributes, [:diff, :filter_intent]) == :filter_diff
    end

    test "accepts every filter including all" do
      for filter <- [:all, :new, :changed, :removed] do
        element = Feedback.diff_banner(active_filter: filter)
        assert get_in(element.attributes, [:diff, :active_filter]) == filter
      end
    end

    test "accepts compact and default sizes" do
      for size <- [:default, :compact] do
        element = Feedback.diff_banner(size: size)
        assert get_in(element.attributes, [:diff, :size]) == size
      end
    end

    test "rejects invalid counts" do
      assert_raise ArgumentError, ~r/:new_count must be a non-negative integer/, fn ->
        Feedback.diff_banner(new_count: -1)
      end

      assert_raise ArgumentError, ~r/:changed_count must be a non-negative integer/, fn ->
        Feedback.diff_banner(changed_count: -1)
      end

      assert_raise ArgumentError, ~r/:removed_count must be a non-negative integer/, fn ->
        Feedback.diff_banner(removed_count: -1)
      end
    end

    test "rejects invalid filter and size values" do
      assert_raise ArgumentError, ~r/:active_filter must be one of/, fn ->
        Feedback.diff_banner(active_filter: :stale)
      end

      assert_raise ArgumentError, ~r/:size must be one of/, fn ->
        Feedback.diff_banner(size: :large)
      end
    end
  end
end
