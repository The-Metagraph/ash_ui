defmodule AshUI.Rendering.SegmentedButtonGroupElementTest do
  @moduledoc """
  Tests for the segmented_button_group element across the widget catalog.

  Covers:
  - Admission: valid_widget_type?/1 accepts "segmented_button_group"
  - LiveUI renderer renders all options as buttons
  - Active option carries aria-pressed="true"
  - Event name propagates to each button
  - Custom event_value_key propagates to each button
  - Purity guard: no literal hex / rgb / named-color values in rendered HTML
  """

  use ExUnit.Case, async: true

  alias AshUI.DSL.Storage
  alias LiveUI.Renderer, as: LiveUIRenderer

  @base_iur %{
    "type" => "segmented_button_group",
    "id" => "seg-1",
    "props" => %{
      "options" => [
        %{"value" => "all", "label" => "All"},
        %{"value" => "in_flight", "label" => "In flight"},
        %{"value" => "blocked", "label" => "Blocked"}
      ],
      "active" => "all",
      "event" => "select_segment",
      "event_value_key" => "value",
      "aria_label" => "Filter by status",
      "class" => ""
    },
    "children" => []
  }

  describe "storage admission" do
    test "valid_widget_type?/1 accepts segmented_button_group" do
      assert Storage.valid_widget_type?("segmented_button_group") == true
    end

    test "segmented_button_group validates correctly within a DSL tree" do
      dsl = %{
        type: "fragment",
        props: %{},
        children: [
          %{
            type: "segmented_button_group",
            props: %{
              "options" => [%{"value" => "a", "label" => "A"}],
              "active" => "a"
            },
            children: [],
            signals: [],
            metadata: %{}
          }
        ],
        signals: [],
        metadata: %{}
      }

      assert Storage.validate_write(dsl) == :ok
    end
  end

  describe "LiveUI renderer" do
    test "renders one button per option" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@base_iur))

      assert html =~ "All"
      assert html =~ "In flight"
      assert html =~ "Blocked"
    end

    test "active option has aria-pressed=true" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@base_iur))

      assert html =~ ~s(aria-pressed="true")
    end

    test "inactive options have aria-pressed=false" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@base_iur))

      assert Regex.scan(~r/aria-pressed="false"/, html) |> length() == 2
    end

    test "event name propagates to each button" do
      iur = put_in(@base_iur, ["props", "event"], "filter_changed")
      {:ok, html} = LiveUIRenderer.render(screen_with(iur))

      assert html =~ ~s(phx-click="filter_changed")
    end

    test "default event is select_segment" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@base_iur))

      assert html =~ ~s(phx-click="select_segment")
    end

    test "event_value_key propagates to each button" do
      iur = put_in(@base_iur, ["props", "event_value_key"], "mode")
      {:ok, html} = LiveUIRenderer.render(screen_with(iur))

      assert html =~ "phx-value-mode="
    end

    test "container has role=group and ash-segmented-button-group class" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@base_iur))

      assert html =~ ~s(role="group")
      assert html =~ "ash-segmented-button-group"
    end

    test "rendered HTML contains no literal hex color values" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@base_iur))

      refute html =~ ~r/#[0-9a-fA-F]{3,6}\b/,
             "found literal hex color value in segmented_button_group HTML"
    end

    test "rendered HTML contains no rgb() color values" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@base_iur))

      refute html =~ ~r/\brgb\s*\(/,
             "found rgb() color value in segmented_button_group HTML"
    end

    test "rendered HTML contains no named color literals in inline style" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@base_iur))

      refute html =~ ~r/\bcolor:\s*(red|blue|green|white|black|gray|grey)\b/i,
             "found named color literal in segmented_button_group HTML"
    end
  end

  # ── Helpers ───────────────────────────────────────────────────

  defp screen_with(widget) do
    %{
      "type" => "screen",
      "id" => "screen-1",
      "name" => "test_screen",
      "layout" => "column",
      "children" => [widget],
      "bindings" => [],
      "metadata" => %{}
    }
  end
end
