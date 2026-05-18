defmodule LiveUi.Widgets.SegmentedButtonGroupTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Widgets.SegmentedButtonGroup

  @options [
    %{value: "a", label: "Option A"},
    %{value: "b", label: "Option B"},
    %{value: "c", label: "Option C"}
  ]

  describe "SegmentedButtonGroup component" do
    test "renders all options as buttons" do
      html =
        render_component(&SegmentedButtonGroup.component/1, %{
          id: "test-sbg",
          options: @options,
          label: "Test group"
        })

      assert html =~ "Option A"
      assert html =~ "Option B"
      assert html =~ "Option C"
    end

    test "outer container has role=radiogroup and aria-label" do
      html =
        render_component(&SegmentedButtonGroup.component/1, %{
          id: "test-sbg",
          options: @options,
          label: "My Filter"
        })

      assert html =~ ~s(role="radiogroup")
      assert html =~ ~s(aria-label="My Filter")
    end

    test "outer container has data-live-ui-widget attribute" do
      html =
        render_component(&SegmentedButtonGroup.component/1, %{
          id: "test-sbg",
          options: @options,
          label: "Test group"
        })

      assert html =~ ~s(data-live-ui-widget="segmented_button_group")
    end

    test "each option button has role=radio" do
      html =
        render_component(&SegmentedButtonGroup.component/1, %{
          id: "test-sbg",
          options: @options,
          label: "Test group"
        })

      # Three options means three role="radio" attributes
      radio_count = html |> String.split(~s(role="radio")) |> length()
      assert radio_count == length(@options) + 1
    end

    test "selected option gets aria-checked=true and is-selected class" do
      html =
        render_component(&SegmentedButtonGroup.component/1, %{
          id: "test-sbg",
          options: @options,
          selected_value: "b",
          label: "Test group"
        })

      # The "b" option should be selected
      assert html =~ ~s(aria-checked="true")
      assert html =~ "is-selected"
    end

    test "non-selected options get aria-checked=false and no is-selected class" do
      html =
        render_component(&SegmentedButtonGroup.component/1, %{
          id: "test-sbg",
          options: @options,
          selected_value: "a",
          label: "Test group"
        })

      # Count aria-checked="false" occurrences — should be 2 (options b and c)
      false_count = html |> String.split(~s(aria-checked="false")) |> length()
      assert false_count == 3

      # Only one option is selected, so one aria-checked="true"
      true_count = html |> String.split(~s(aria-checked="true")) |> length()
      assert true_count == 2

      # The selected option has the class; others do not
      assert html =~ "is-selected"
    end

    test "with no selected_value all options have aria-checked=false" do
      html =
        render_component(&SegmentedButtonGroup.component/1, %{
          id: "test-sbg",
          options: @options,
          selected_value: nil,
          label: "Test group"
        })

      refute html =~ ~s(aria-checked="true")

      false_count = html |> String.split(~s(aria-checked="false")) |> length()
      assert false_count == length(@options) + 1
    end

    test "with no selected_value no option has is-selected class" do
      html =
        render_component(&SegmentedButtonGroup.component/1, %{
          id: "test-sbg",
          options: @options,
          label: "Test group"
        })

      refute html =~ "is-selected"
    end

    test "each option button has data-option-value" do
      html =
        render_component(&SegmentedButtonGroup.component/1, %{
          id: "test-sbg",
          options: @options,
          label: "Test group"
        })

      assert html =~ ~s(data-option-value="a")
      assert html =~ ~s(data-option-value="b")
      assert html =~ ~s(data-option-value="c")
    end

    test "disabled options render disabled buttons" do
      html =
        render_component(&SegmentedButtonGroup.component/1, %{
          id: "test-sbg",
          options: [
            %{value: "a", label: "Option A"},
            %{value: "b", label: "Option B", disabled?: true}
          ],
          label: "Test group"
        })

      assert html =~ "Option B"
      assert html =~ "disabled"
    end

    test "per-option attrs are rendered on option buttons" do
      html =
        render_component(&SegmentedButtonGroup.component/1, %{
          id: "test-sbg",
          options: [
            %{
              value: "a",
              label: "Option A",
              attrs: %{
                "phx-click" => "canonical_interaction",
                "phx-value-value" => "a",
                "phx-target" => "#runtime-host"
              }
            }
          ],
          label: "Test group"
        })

      assert html =~ ~s(phx-click="canonical_interaction")
      assert html =~ ~s(phx-value-value="a")
      assert html =~ ~s(phx-target="#runtime-host")
    end

    test "when option attrs are absent, phx-click is not set" do
      html =
        render_component(&SegmentedButtonGroup.component/1, %{
          id: "test-sbg",
          options: @options,
          label: "Test group"
        })

      refute html =~ ~s(phx-click=)
    end

    test "widget metadata has correct family and name" do
      metadata = LiveUi.Component.metadata(SegmentedButtonGroup)

      assert metadata.family == :form_control_and_composer
      assert metadata.name == :segmented_button_group
      assert :selection in metadata.events
    end

    test "is exposed through the form control widget family" do
      assert SegmentedButtonGroup in LiveUi.Widgets.form_control_and_composer_modules()
      assert SegmentedButtonGroup in LiveUi.Widgets.modules()
    end

    test "widget is mountable (has LiveComponent boundary)" do
      metadata = LiveUi.Component.metadata(SegmentedButtonGroup)

      assert metadata.mountable?
    end
  end

  describe "count badge" do
    test "option with count renders count badge span" do
      html =
        render_component(&SegmentedButtonGroup.component/1, %{
          id: "test-sbg",
          options: [
            %{value: "adrs", label: "ADRs", count: 12},
            %{value: "specs", label: "Specs", count: 8}
          ],
          label: "Document type"
        })

      assert html =~ ~s(class="live-ui-segmented-button-group-option-count")
      assert html =~ "12"
      assert html =~ "8"
    end

    test "count badge has aria-hidden=true" do
      html =
        render_component(&SegmentedButtonGroup.component/1, %{
          id: "test-sbg",
          options: [%{value: "a", label: "All", count: 5}],
          label: "Test group"
        })

      assert html =~ ~s(aria-hidden="true")
    end

    test "option without count does not render count badge span" do
      html =
        render_component(&SegmentedButtonGroup.component/1, %{
          id: "test-sbg",
          options: @options,
          label: "Test group"
        })

      refute html =~ ~s(live-ui-segmented-button-group-option-count)
    end

    test "option with count nil does not render count badge span" do
      html =
        render_component(&SegmentedButtonGroup.component/1, %{
          id: "test-sbg",
          options: [%{value: "a", label: "Option A", count: nil}],
          label: "Test group"
        })

      refute html =~ ~s(live-ui-segmented-button-group-option-count)
    end

    test "count of zero renders a badge with '0'" do
      html =
        render_component(&SegmentedButtonGroup.component/1, %{
          id: "test-sbg",
          options: [%{value: "plans", label: "Plans", count: 0}],
          label: "Test group"
        })

      assert html =~ ~s(live-ui-segmented-button-group-option-count)
      assert html =~ ">0<"
    end

    test "mixed options: some with count, some without" do
      html =
        render_component(&SegmentedButtonGroup.component/1, %{
          id: "test-sbg",
          options: [
            %{value: "adrs", label: "ADRs", count: 12},
            %{value: "specs", label: "Specs"}
          ],
          label: "Document type"
        })

      assert html =~ "12"
      assert html =~ "ADRs"
      assert html =~ "Specs"
    end
  end
end
