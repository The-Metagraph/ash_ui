defmodule LiveUi.Widgets.ConfidenceIndicatorTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component

  describe "metadata" do
    test "has a feedback widget component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.ConfidenceIndicator)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.ConfidenceIndicator.Component
      assert metadata.family == :feedback
      assert metadata.name == :confidence_indicator
    end
  end

  describe "rendering" do
    test "renders meter semantics, band, glyph, and numeric value" do
      html =
        render_component(&LiveUi.Widgets.ConfidenceIndicator.component/1, %{
          id: "confidence-score",
          value: 0.87,
          label: "Match confidence"
        })

      assert html =~ ~s(data-live-ui-widget="confidence-indicator")
      assert html =~ ~s(role="meter")
      assert html =~ ~s(aria-valuenow="87")
      assert html =~ ~s(aria-valuemin="0")
      assert html =~ ~s(aria-valuemax="100")
      assert html =~ ~s(aria-label="Match confidence")
      assert html =~ ~s(data-confidence-band="pass")
      assert html =~ "OK"
      assert html =~ "87%"
    end

    test "classifies fail and warn bands using custom thresholds" do
      warn_html =
        render_component(&LiveUi.Widgets.ConfidenceIndicator.component/1, %{
          id: "warn-confidence",
          value: 0.55,
          warn_threshold: 0.4,
          pass_threshold: 0.7
        })

      fail_html =
        render_component(&LiveUi.Widgets.ConfidenceIndicator.component/1, %{
          id: "fail-confidence",
          value: 0.25,
          warn_threshold: 0.4,
          pass_threshold: 0.7
        })

      assert warn_html =~ ~s(data-confidence-band="warn")
      assert warn_html =~ "!"
      assert fail_html =~ ~s(data-confidence-band="fail")
      assert fail_html =~ "X"
    end

    test "can hide optional glyph and numeric text" do
      html =
        render_component(&LiveUi.Widgets.ConfidenceIndicator.component/1, %{
          id: "quiet-confidence",
          value: 0.87,
          show_glyph?: false,
          show_numeric?: false
        })

      refute html =~ "OK"
      refute html =~ "live-ui-confidence__glyph"
      refute html =~ "live-ui-confidence__numeric"
    end
  end
end
