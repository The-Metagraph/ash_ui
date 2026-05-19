defmodule UnifiedIUR.Widgets.FeedbackTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element
  alias UnifiedIUR.Widgets.Feedback

  test "builds baseline feedback and progress constructs with shared severity hooks" do
    status = Feedback.status("Idle", id: "service-status", severity: :info, status: :idle)

    progress =
      Feedback.progress(
        id: "upload-progress",
        current: 4,
        total: 10,
        label: "Upload",
        status: :running
      )

    gauge = Feedback.gauge(id: "cpu-gauge", value: 62, label: "CPU", severity: :warning)

    inline_feedback =
      Feedback.inline_feedback("Configuration saved.",
        id: "save-feedback",
        title: "Saved",
        severity: :success,
        status: :complete
      )

    assert %Element{
             kind: :status,
             attributes: %{feedback: %{text: "Idle", severity: :info, status: :idle}}
           } = status

    assert %Element{
             kind: :progress,
             attributes: %{
               progress: %{current: 4, total: 10, indeterminate?: false, label: "Upload"},
               feedback: %{status: :running}
             }
           } = progress

    assert %Element{
             kind: :gauge,
             attributes: %{
               gauge: %{value: 62, min: 0, max: 100, label: "CPU"},
               feedback: %{severity: :warning}
             }
           } = gauge

    assert %Element{
             kind: :inline_feedback,
             attributes: %{
               feedback: %{
                 title: "Saved",
                 message: "Configuration saved.",
                 severity: :success,
                 status: :complete
               }
             }
           } = inline_feedback
  end

  describe "confidence_indicator/2" do
    test "builds a confidence indicator with thresholds and presentation flags" do
      element =
        Feedback.confidence_indicator(0.87,
          id: "confidence-score",
          label: "Match confidence",
          thresholds: %{warn: 0.5, pass: 0.8},
          show_numeric?: false,
          show_glyph?: true,
          size: :small
        )

      assert %Element{
               kind: :confidence_indicator,
               attributes: %{
                 confidence: %{
                   value: 0.87,
                   thresholds: %{warn: 0.5, pass: 0.8},
                   label: "Match confidence",
                   show_numeric?: false,
                   show_glyph?: true,
                   size: :small
                 }
               }
             } = element
    end

    test "raises on invalid values, thresholds, and sizes" do
      assert_raise ArgumentError, ~r/0\.0\.\.1\.0/, fn ->
        Feedback.confidence_indicator(1.1)
      end

      assert_raise ArgumentError, ~r/warn.*less than.*pass/, fn ->
        Feedback.confidence_indicator(0.5, thresholds: %{warn: 0.8, pass: 0.5})
      end

      assert_raise ArgumentError, ~r/:size/, fn ->
        Feedback.confidence_indicator(0.5, size: :xl)
      end
    end
  end
end
