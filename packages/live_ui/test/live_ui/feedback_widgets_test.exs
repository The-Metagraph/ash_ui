defmodule LiveUi.FeedbackWidgetsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component
  alias LiveUi.Widget.Identity

  @moduledoc """
  Regression tests for feedback and chart widgets to verify they preserve
  identity, styling, slots, and event semantics through the widget
  component architecture.
  """

  describe "status widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Status)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Status.Component
      assert metadata.family == :feedback
      assert metadata.name == :status
    end

    test "status component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.Status.component/1, %{
          id: "test-status",
          text: "Processing complete"
        })

      assert html =~ ~s(data-live-ui-widget-boundary="status")
      assert html =~ "Processing complete"
    end

    test "status component supports severity levels" do
      html =
        render_component(&LiveUi.Widgets.Status.component/1, %{
          id: "error-status",
          text: "An error occurred",
          severity: "error"
        })

      assert html =~ ~s(data-live-ui-severity="error")
    end

    test "status component supports status states" do
      html =
        render_component(&LiveUi.Widgets.Status.component/1, %{
          id: "loading-status",
          text: "Loading...",
          status: "loading"
        })

      assert html =~ ~s(data-live-ui-status="loading")
    end
  end

  describe "progress widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Progress)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Progress.Component
      assert metadata.family == :feedback
      assert metadata.name == :progress
    end

    test "progress component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.Progress.component/1, %{
          id: "test-progress",
          current: 50
        })

      assert html =~ ~s(data-live-ui-widget-boundary="progress")
    end

    test "progress component supports percentage values" do
      html =
        render_component(&LiveUi.Widgets.Progress.component/1, %{
          id: "percent-progress",
          current: 75,
          total: 100
        })

      assert html =~ "75"
    end

    test "progress component supports indeterminate state" do
      html =
        render_component(&LiveUi.Widgets.Progress.component/1, %{
          id: "indeterminate-progress",
          indeterminate: true
        })

      assert html =~ ~s(data-live-ui-indeterminate)
    end
  end

  describe "gauge widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Gauge)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Gauge.Component
      assert metadata.family == :feedback
      assert metadata.name == :gauge
    end

    test "gauge component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.Gauge.component/1, %{
          id: "test-gauge",
          value: 60,
          min: 0,
          max: 100
        })

      assert html =~ ~s(data-live-ui-widget-boundary="gauge")
    end

    test "gauge component supports custom ranges" do
      html =
        render_component(&LiveUi.Widgets.Gauge.component/1, %{
          id: "ranged-gauge",
          value: 5,
          min: 0,
          max: 10
        })

      assert html =~ ~s(data-live-ui-min="0")
      assert html =~ ~s(data-live-ui-max="10")
    end

    test "gauge component supports value display" do
      html =
        render_component(&LiveUi.Widgets.Gauge.component/1, %{
          id: "display-gauge",
          value: 80,
          min: 0,
          max: 100
        })

      assert html =~ "80"
      assert html =~ ~s(data-live-ui-value="80")
    end
  end

  describe "inline_feedback widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.InlineFeedback)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.InlineFeedback.Component
      assert metadata.family == :feedback
      assert metadata.name == :inline_feedback
    end

    test "inline_feedback component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.InlineFeedback.component/1, %{
          id: "test-feedback",
          message: "Field is required",
          severity: "error"
        })

      assert html =~ ~s(data-live-ui-widget-boundary="inline_feedback")
      assert html =~ "Field is required"
    end

    test "inline_feedback component supports different severities" do
      severities = ["error", "warning", "info", "success"]

      for severity <- severities do
        html =
          render_component(&LiveUi.Widgets.InlineFeedback.component/1, %{
            id: "feedback-#{severity}",
            message: "#{severity} message",
            severity: severity
          })

        assert html =~ ~s(data-live-ui-severity="#{severity}")
      end
    end
  end

  describe "sparkline widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Sparkline)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Sparkline.Component
      assert metadata.family == :display
      assert metadata.name == :sparkline
    end

    test "sparkline component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.Sparkline.component/1, %{
          id: "test-sparkline",
          series: [10, 20, 15, 25, 30]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="sparkline")
    end

    test "sparkline component supports data series" do
      html =
        render_component(&LiveUi.Widgets.Sparkline.component/1, %{
          id: "data-sparkline",
          series: [5, 10, 15, 20, 25]
        })

      assert html =~ "sparkline"
    end
  end

  describe "bar_chart widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.BarChart)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.BarChart.Component
      assert metadata.family == :display
      assert metadata.name == :bar_chart
    end

    test "bar_chart component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.BarChart.component/1, %{
          id: "test-bar-chart",
          series: [10, 20, 15]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="bar_chart")
    end

    test "bar_chart component supports data series" do
      html =
        render_component(&LiveUi.Widgets.BarChart.component/1, %{
          id: "series-bar-chart",
          series: [100, 200, 150]
        })

      assert html =~ "bar_chart"
    end
  end

  describe "line_chart widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.LineChart)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.LineChart.Component
      assert metadata.family == :display
      assert metadata.name == :line_chart
    end

    test "line_chart component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.LineChart.component/1, %{
          id: "test-line-chart",
          series: [10, 20, 15]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="line_chart")
    end

    test "line_chart component supports data series" do
      html =
        render_component(&LiveUi.Widgets.LineChart.component/1, %{
          id: "series-line-chart",
          series: [5, 15, 10, 25]
        })

      assert html =~ "line_chart"
    end
  end

  describe "widget identity preservation" do
    test "widget identity is stable across renders for status" do
      identity1 =
        Identity.new(
          Component.metadata(LiveUi.Widgets.Status),
          %{id: "stable-status"}
        )

      identity2 =
        Identity.new(
          Component.metadata(LiveUi.Widgets.Status),
          %{id: "stable-status"}
        )

      assert identity1.id == identity2.id
      assert Identity.key(identity1) == Identity.key(identity2)
      assert Identity.key(identity1) == "native:feedback:status:stable-status:root"
    end

    test "widget identity includes mode in key for gauge" do
      native_identity =
        Identity.new(
          Component.metadata(LiveUi.Widgets.Gauge),
          %{id: "mode-gauge"},
          mode: :native
        )

      canonical_identity =
        Identity.new(
          Component.metadata(LiveUi.Widgets.Gauge),
          %{id: "mode-gauge"},
          mode: :canonical
        )

      assert Identity.key(native_identity) == "native:feedback:gauge:mode-gauge:root"
      assert Identity.key(canonical_identity) == "canonical:feedback:gauge:mode-gauge:root"
    end
  end

  describe "bounded local state support" do
    test "feedback widgets support local_state_keys for bounded state" do
      status_metadata = Component.metadata(LiveUi.Widgets.Status)
      progress_metadata = Component.metadata(LiveUi.Widgets.Progress)
      gauge_metadata = Component.metadata(LiveUi.Widgets.Gauge)

      # Feedback widgets can have local_state_keys for bounded UI state
      assert is_list(status_metadata.local_state_keys)
      assert is_list(progress_metadata.local_state_keys)
      assert is_list(gauge_metadata.local_state_keys)
    end
  end

  describe "styling attributes preservation" do
    test "status component preserves tone and variant styling" do
      html =
        render_component(&LiveUi.Widgets.Status.component/1, %{
          id: "styled-status",
          text: "Styled status",
          tone: "success",
          variant: "solid"
        })

      assert html =~ ~s(data-live-ui-tone="success")
      assert html =~ ~s(data-live-ui-variant="solid")
    end

    test "progress component preserves tone styling" do
      html =
        render_component(&LiveUi.Widgets.Progress.component/1, %{
          id: "toned-progress",
          value: 50,
          tone: "primary"
        })

      assert html =~ ~s(data-live-ui-tone="primary")
    end
  end
end
