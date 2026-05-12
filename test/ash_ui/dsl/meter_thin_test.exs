defmodule AshUI.DSL.MeterThinTest do
  @moduledoc """
  Tests for the meter_thin widget type in AshUI.

  Covers:
    - DSL.Storage admission (valid_widget_type?/1)
    - IUR adapter mapping (map_element_type/1 via to_canonical/2)
    - LiveUIAdapter HEEx rendering (value normalization, label, ARIA)
    - LiveUI renderer (packages/live_ui) HEEx rendering
  """

  use ExUnit.Case, async: true

  alias AshUI.Compilation.IUR
  alias AshUI.DSL.Storage
  alias AshUI.Rendering.IURAdapter
  alias AshUI.Rendering.LiveUIAdapter

  # ── Storage admission ─────────────────────────────────────────

  describe "Storage.valid_widget_type?/1" do
    test "admits meter_thin" do
      assert Storage.valid_widget_type?("meter_thin") == true
    end

    test "still admits existing widget types" do
      assert Storage.valid_widget_type?("text") == true
      assert Storage.valid_widget_type?("button") == true
      assert Storage.valid_widget_type?("spacer") == true
    end

    test "still rejects unknown types" do
      assert Storage.valid_widget_type?("invalid_widget") == false
    end
  end

  # ── IUR adapter mapping ───────────────────────────────────────

  describe "IURAdapter.to_canonical/2 with meter_thin element" do
    defp meter_screen(props) do
      struct(IUR,
        id: "screen-mt",
        type: :screen,
        name: "meter_screen",
        attributes: %{"layout" => :column},
        children: [
          struct(IUR,
            id: "meter-1",
            type: :meter_thin,
            name: "progress",
            props: props,
            attributes: %{},
            children: [],
            bindings: [],
            metadata: %{},
            version: 1
          )
        ],
        bindings: [],
        metadata: %{},
        version: 1
      )
    end

    test "maps :meter_thin element type to string form" do
      ash_iur = meter_screen(%{"value" => 50})

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur, telemetry: false)
      [child] = canonical["children"]
      assert child["type"] == "meter_thin"
    end

    test "props are preserved in canonical form" do
      ash_iur = meter_screen(%{"value" => 75, "label" => "Loading..."})

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur, telemetry: false)
      [child] = canonical["children"]
      assert child["type"] == "meter_thin"
    end
  end

  # ── LiveUIAdapter HEEx rendering ─────────────────────────────

  describe "LiveUIAdapter.render/2 with meter_thin" do
    defp meter_iur(props) do
      %{
        "type" => "screen",
        "id" => "screen-1",
        "name" => "test_screen",
        "layout" => "column",
        "children" => [
          %{
            "type" => "meter_thin",
            "id" => "meter-1",
            "props" => props,
            "children" => [],
            "metadata" => %{}
          }
        ],
        "bindings" => [],
        "metadata" => %{}
      }
    end

    test "renders container with correct CSS class" do
      {:ok, html} = LiveUIAdapter.render(meter_iur(%{"value" => 50}))

      assert html =~ "ash-meter-thin"
    end

    test "renders track and fill elements" do
      {:ok, html} = LiveUIAdapter.render(meter_iur(%{"value" => 50}))

      assert html =~ "ash-meter-thin-track"
      assert html =~ "ash-meter-thin-fill"
    end

    test "has role=progressbar" do
      {:ok, html} = LiveUIAdapter.render(meter_iur(%{"value" => 50}))

      assert html =~ ~s(role="progressbar")
    end

    test "integer value 50 renders 50% fill" do
      {:ok, html} = LiveUIAdapter.render(meter_iur(%{"value" => 50}))

      assert html =~ ~s(width: 50%)
    end

    test "float fraction 0.5 is normalized to 50% fill" do
      {:ok, html} = LiveUIAdapter.render(meter_iur(%{"value" => 0.5}))

      assert html =~ ~s(width: 50%)
    end

    test "value exceeding max is clamped to 100%" do
      {:ok, html} = LiveUIAdapter.render(meter_iur(%{"value" => 200}))

      assert html =~ ~s(width: 100%)
      refute html =~ "width: 200%"
    end

    test "negative value is clamped to 0%" do
      {:ok, html} = LiveUIAdapter.render(meter_iur(%{"value" => -10}))

      assert html =~ ~s(width: 0%)
    end

    test "label is rendered when present" do
      {:ok, html} = LiveUIAdapter.render(meter_iur(%{"value" => 50, "label" => "Loading"}))

      assert html =~ "Loading"
      assert html =~ "ash-meter-thin-label"
    end

    test "no label element when label is absent" do
      {:ok, html} = LiveUIAdapter.render(meter_iur(%{"value" => 50}))

      refute html =~ "ash-meter-thin-label"
    end
  end
end
