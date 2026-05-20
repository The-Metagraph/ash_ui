defmodule DesktopUi.PhaseElevenIntegrationTest do
  use ExUnit.Case, async: false

  alias DesktopUi.Sdl3.{Capabilities, NativeBuild, RenderPlan}
  alias DesktopUi.{Renderer, Widgets, Runtime}

  @moduletag timeout: 300_000

  @moduletag :phase_eleven

  @iur_widget_count 49

  @all_iur_kinds MapSet.new([
                   # Foundational (13)
                   :badge,
                   :button,
                   :command,
                   :content,
                   :hero,
                   :icon,
                   :image,
                   :label,
                   :link,
                   :separator,
                   :spacer,
                   :text,
                   :toggle,
                   # Input (10)
                   :checkbox,
                   :date_input,
                   :file_input,
                   :numeric_input,
                   :pick_list,
                   :radio_group,
                   :select,
                   :slider,
                   :text_input,
                   :time_input,
                   # Navigation (6)
                   :breadcrumbs,
                   :context_selector,
                   :file_tree_browser,
                   :list,
                   :menu,
                   :tabs,
                   # Data (7)
                   :inspector,
                   :info_list,
                   :key_value,
                   :markdown_viewer,
                   :stat,
                   :table,
                   :tree_view,
                   # Feedback (7)
                   :alert_dialog,
                   :dialog,
                   :diff_banner,
                   :inline_feedback,
                   :progress,
                   :status,
                   :toast,
                   # Operational (7)
                   :cluster_dashboard,
                   :command_palette,
                   :log_viewer,
                   :process_monitor,
                   :stream_widget,
                   :supervision_tree_viewer,
                   :window_command,
                   # Visualization (6)
                   :bar_chart,
                   :canvas,
                   :gauge,
                   :line_chart,
                   :sparkline,
                   :timeline,
                   # Layout & Structure (3)
                   :column,
                   :row,
                   :stack,
                   # Container (1)
                   :window
                 ])

  setup_all do
    {:ok, capabilities: ensure_visible_runner_capabilities()}
  end

  describe "11.1 Foundational completeness scenarios" do
    test "badge, hero, link, separator, and spacer render with proper semantics and style resolution" do
      # Verify widget constructors exist and produce valid widgets
      badge_widget = DesktopUi.Widgets.badge("test-badge", "New", variant: :success)
      assert badge_widget.kind == :badge
      assert badge_widget.attributes.variant == :success
      assert badge_widget.attributes.content == "New"

      hero_widget = DesktopUi.Widgets.hero("test-hero", "Welcome", subheadline: "Get started")
      assert hero_widget.kind == :hero
      assert hero_widget.attributes.headline == "Welcome"
      assert hero_widget.attributes.subheadline == "Get started"

      link_widget = DesktopUi.Widgets.link("test-link", "Learn More", "/docs")
      assert link_widget.kind == :link
      assert link_widget.attributes.href == "/docs"

      separator_widget = DesktopUi.Widgets.separator("test-sep", orientation: :horizontal)
      assert separator_widget.kind == :separator
      assert separator_widget.attributes.orientation == :horizontal

      spacer_widget = DesktopUi.Widgets.spacer("test-spacer", size: :lg)
      assert spacer_widget.kind == :spacer
      assert spacer_widget.attributes.size == :lg
    end

    test "canonical mapper handles all foundational widget kinds" do
      # Verify the mapper supports all foundational kinds
      supported = Renderer.supported_kinds() |> MapSet.new()

      foundational_kinds = [:badge, :hero, :link, :separator, :spacer]

      Enum.each(foundational_kinds, fn kind ->
        assert MapSet.member?(supported, kind),
               "Expected foundational widget #{kind} to be supported by renderer"
      end)
    end
  end

  describe "11.2 Form input completeness scenarios" do
    test "numeric_input, toggle, radio_group, select, pick_list render with proper structure" do
      numeric_widget =
        DesktopUi.Widgets.numeric_input("test-numeric", value: 42, min: 0, max: 100)

      assert numeric_widget.kind == :numeric_input
      assert numeric_widget.state.value == 42
      assert numeric_widget.attributes.min == 0
      assert numeric_widget.attributes.max == 100

      toggle_widget = DesktopUi.Widgets.toggle("test-toggle", "Enable", checked: true)
      assert toggle_widget.kind == :toggle
      assert toggle_widget.state.checked == true

      radio_widget =
        DesktopUi.Widgets.radio_group("test-radio", [
          [label: "Option A", value: "a"],
          [label: "Option B", value: "b"]
        ])

      assert radio_widget.kind == :radio_group
      assert length(radio_widget.attributes.options) == 2

      select_widget =
        DesktopUi.Widgets.select("test-select", [
          [label: "Choose", value: ""],
          [label: "First", value: "1"]
        ])

      assert select_widget.kind == :select
      assert length(select_widget.attributes.options) == 2

      pick_list_widget =
        DesktopUi.Widgets.pick_list("test-pick", [
          [label: "Item 1", value: "1"],
          [label: "Item 2", value: "2"]
        ])

      assert pick_list_widget.kind == :pick_list
      assert length(pick_list_widget.attributes.options) == 2
    end

    test "slider, date_input, time_input render with proper value presentation" do
      slider_widget = DesktopUi.Widgets.slider("test-slider", value: 50, min: 0, max: 100)
      assert slider_widget.kind == :slider
      assert slider_widget.state.value == 50

      date_widget = DesktopUi.Widgets.date_input("test-date", value: ~D[2026-03-26])
      assert date_widget.kind == :date_input
      assert date_widget.state.value == ~D[2026-03-26]

      time_widget = DesktopUi.Widgets.time_input("test-time", value: ~T[14:30:00])
      assert time_widget.kind == :time_input
      assert time_widget.state.value == ~T[14:30:00]
    end

    test "file_input widget renders with file selection attributes" do
      file_widget = DesktopUi.Widgets.file_input("test-file", accept: [".png", ".jpg"])
      assert file_widget.kind == :file_input
      assert file_widget.attributes.accept == [".png", ".jpg"]
    end

    test "canonical mapper supports all form input widget kinds" do
      supported = Renderer.supported_kinds() |> MapSet.new()

      input_kinds = [
        :numeric_input,
        :slider,
        :date_input,
        :time_input,
        :file_input,
        :pick_list,
        :radio_group,
        :select
      ]

      Enum.each(input_kinds, fn kind ->
        assert MapSet.member?(supported, kind),
               "Expected input widget #{kind} to be supported by renderer"
      end)
    end
  end

  describe "11.3 Data display completeness scenarios" do
    test "stat, key_value, and info_list render with proper structure" do
      stat_widget = DesktopUi.Widgets.stat("test-stat", value: 1234, label: "Users", trend: :up)
      assert stat_widget.kind == :stat
      assert stat_widget.attributes.value == 1234
      assert stat_widget.attributes.label == "Users"
      assert stat_widget.attributes.trend == :up

      kv_widget = DesktopUi.Widgets.key_value("test-kv", key: "Status", value: "Active")
      assert kv_widget.kind == :key_value
      assert kv_widget.attributes.key == "Status"
      assert kv_widget.attributes.value == "Active"

      info_widget =
        DesktopUi.Widgets.info_list("test-info", [
          [label: "Name", value: "Test"],
          [label: "Type", value: "Integration"]
        ])

      assert info_widget.kind == :info_list
      assert length(info_widget.attributes.items) == 2
    end

    test "canonical mapper supports all data display widget kinds" do
      supported = Renderer.supported_kinds() |> MapSet.new()

      data_kinds = [:stat, :key_value, :info_list, :tree_view]

      Enum.each(data_kinds, fn kind ->
        assert MapSet.member?(supported, kind),
               "Expected data widget #{kind} to be supported by renderer"
      end)
    end
  end

  describe "11.4 Feedback and advanced widget scenarios" do
    test "status, progress, and inline_feedback render with semantic colors" do
      status_widget = DesktopUi.Widgets.status("test-status", "Ready", severity: :success)
      assert status_widget.kind == :status
      assert status_widget.attributes.label == "Ready"

      progress_widget = DesktopUi.Widgets.progress("test-progress", current: 75)
      assert progress_widget.kind == :progress
      assert progress_widget.state.progress == 75

      feedback_widget =
        DesktopUi.Widgets.inline_feedback("test-feedback",
          message: "Operation complete",
          severity: :success
        )

      assert feedback_widget.kind == :inline_feedback
      assert feedback_widget.attributes.message == "Operation complete"
    end

    test "stream_widget and supervision_tree_viewer render with proper structure" do
      stream_widget =
        DesktopUi.Widgets.stream_widget("test-stream",
          entries: [[timestamp: DateTime.utc_now(), message: "Line 1"]]
        )

      assert stream_widget.kind == :stream_widget
      assert length(stream_widget.attributes.entries) == 1
      assert stream_widget.state.streaming == true

      supervision_widget =
        DesktopUi.Widgets.supervision_tree_viewer("test-sup", tree: [])

      assert supervision_widget.kind == :supervision_tree_viewer
      assert is_list(supervision_widget.attributes.tree)
    end

    test "canonical mapper supports all feedback and advanced widget kinds" do
      supported = Renderer.supported_kinds() |> MapSet.new()

      feedback_kinds = [:status, :inline_feedback, :progress, :diff_banner]
      advanced_kinds = [:stream_widget, :supervision_tree_viewer, :log_viewer, :process_monitor]

      Enum.each(feedback_kinds ++ advanced_kinds, fn kind ->
        assert MapSet.member?(supported, kind),
               "Expected feedback/advanced widget #{kind} to be supported by renderer"
      end)
    end
  end

  describe "11.5 Mapper coverage and diagnostics scenarios" do
    test "canonical mapper handles all 49 IUR widget kinds without fallback" do
      supported = Renderer.supported_kinds() |> MapSet.new()

      # All IUR widget kinds should be supported
      missing_kinds = MapSet.difference(@all_iur_kinds, supported)

      assert MapSet.size(missing_kinds) == 0,
             "Expected all 49 IUR kinds to be supported, but missing: #{inspect(MapSet.to_list(missing_kinds))}"
    end

    test "renderer.supported_kinds returns at least 49 kinds" do
      count = length(Renderer.supported_kinds())

      assert count >= @iur_widget_count,
             "Expected at least #{@iur_widget_count} supported kinds, got #{count}"
    end

    test "Widgets.kinds returns all expected widget kinds" do
      widget_kinds = Widgets.kinds() |> MapSet.new()

      # All widget kinds from Widgets should be in the all IUR kinds set
      # (except structural kinds like :window which may not be in the widget families list)
      Enum.each(widget_kinds, fn kind ->
        assert MapSet.member?(@all_iur_kinds, kind) or kind in [:window, :column, :row, :stack],
               "Unexpected widget kind: #{kind}"
      end)
    end

    test "render plan reports complete IUR widget coverage" do
      # Create a simple screen to test render plan metadata
      root =
        DesktopUi.Widgets.column("test-col", [
          DesktopUi.Widgets.badge("badge-1", "Test"),
          DesktopUi.Widgets.text("text-1", "Content"),
          DesktopUi.Widgets.button("button-1", "Click")
        ])

      screen = %{id: "test-screen", title: "Test Screen", root: root}

      assert {:ok, state} = DesktopUi.Runtime.mount_native_screen(screen, platform_target: :linux)
      assert {:ok, %RenderPlan{} = plan} = RenderPlan.build(state)

      assert plan.presentation.iur_widget_coverage == :complete
      assert plan.presentation.supported_iur_kinds >= @iur_widget_count
      assert plan.presentation.validation_state == :iur_renderer_complete
    end

    test "validation passes with full IUR widget coverage" do
      validation_report = DesktopUi.Validate.validation_report()
      validation_summary = DesktopUi.Validate.validation_summary(validation_report)

      assert validation_summary =~ "release ready?: true"

      # Check that the IUR widget coverage check exists and passes
      example_coverage = validation_report.example_coverage
      assert example_coverage.status == :pass

      # Find the IUR widget coverage check
      iur_coverage_check =
        Enum.find(example_coverage.checks, fn
          %{name: :renderer_supports_all_iur_kinds} -> true
          _ -> false
        end)

      assert iur_coverage_check != nil, "Expected to find :renderer_supports_all_iur_kinds check"
      assert iur_coverage_check.ok? == true
    end
  end

  describe "11.7 Integration scenarios with visible runner" do
    test "all new widget families render in SDL3 host when capabilities are ready",
         %{capabilities: capabilities} do
      if capabilities.build.visible_runner_ready? do
        # Create a screen with all new widget types from Phase 11
        phase11_screen =
          DesktopUi.Widgets.window("phase11-window", "Phase 11 Completeness", [
            DesktopUi.Widgets.column("phase11-content", [
              # Foundational
              DesktopUi.Widgets.badge("p11-badge", "Complete", variant: :success),
              DesktopUi.Widgets.hero("p11-hero", "Phase 11",
                subheadline: "IUR Widget Completeness"
              ),
              DesktopUi.Widgets.separator("p11-sep"),
              # Input
              DesktopUi.Widgets.numeric_input("p11-numeric", value: 50, min: 0, max: 100),
              DesktopUi.Widgets.slider("p11-slider", value: 75),
              # Data
              DesktopUi.Widgets.stat("p11-stat", value: 45, label: "IUR Kinds"),
              DesktopUi.Widgets.key_value("p11-kv", key: "Status", value: "Complete"),
              # Feedback
              DesktopUi.Widgets.status("p11-status", "Ready", variant: :success),
              DesktopUi.Widgets.progress("p11-progress", value: 100)
            ])
          ])

        assert {:ok, state} = Runtime.mount_native_screen(phase11_screen, platform_target: :linux)
        assert {:ok, %RenderPlan{} = plan} = RenderPlan.build(state)

        assert plan.presentation.iur_widget_coverage == :complete
        assert plan.presentation.supported_iur_kinds >= @iur_widget_count
        assert plan.diagnostics.draw_operation_count > 0
        assert plan.diagnostics.window_count >= 1
      else
        :skip
      end
    end
  end

  # Helper functions

  defp ensure_visible_runner_capabilities do
    capabilities = Capabilities.detect()

    cond do
      capabilities.build.visible_runner_ready? ->
        capabilities

      capabilities.build.buildable? ->
        compile_plan = NativeBuild.compile_plan(capabilities: capabilities)
        File.mkdir_p!(compile_plan.output_root)
        {_, 0} = System.cmd(compile_plan.compiler, compile_plan.args, stderr_to_stdout: true)
        Capabilities.detect()

      true ->
        capabilities
    end
  end
end
