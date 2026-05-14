#!/usr/bin/env elixir

# Visual test script for Phase 11 - IUR Widget Completeness
# Run with: elixir visual_test_phase11.exs

# Mix.install/2 is not available in scripts, so we'll use mix run instead

# To run this visual test:
#   mix run visual_test_phase11.exs
#   OR
#   elixir -S mix run visual_test_phase11.exs

alias DesktopUi.Widgets

# Create a comprehensive screen demonstrating all Phase 11 widgets

phase11_screen = %{
  id: "phase11-visual-test",
  title: "Phase 11 - IUR Widget Completeness Visual Test",
  root:
    Widgets.column("phase11-root", [],
      gap: 16,
      children: [
        # Header
        Widgets.content("header-content", [
          Widgets.text("title", "Phase 11 - IUR Widget Completeness"),
          Widgets.text("subtitle", "All 45 canonical IUR widget kinds with dedicated rendering")
        ], styles: %{bg: "muted", fg: "light"}),

        # Section 11.1: Foundational Widgets
        Widgets.content("foundational-section", [
          Widgets.text("foundational-title", "11.1 Foundational Widgets"),
          Widgets.row("foundational-row", [],
            gap: 8,
            children: [
              Widgets.badge("badge-1", "New", variant: :default),
              Widgets.badge("badge-2", "Success", variant: :success),
              Widgets.badge("badge-3", "Warning", variant: :warning),
              Widgets.badge("badge-4", "Error", variant: :error),
              Widgets.badge("badge-5", "Small", size: :sm),
              Widgets.badge("badge-6", "Large", size: :lg)
            ]
          ),
          Widgets.hero("hero-1", "Welcome to Phase 11",
            subheadline: "Complete IUR widget coverage with dedicated rendering",
            actions: ["Get Started", "Learn More"]
          ),
          Widgets.link("link-1", "Documentation", "/docs"),
          Widgets.separator("sep-1", orientation: :horizontal),
          Widgets.spacer("spacer-1", size: :md)
        ]),

        # Section 11.2: Form Input Widgets
        Widgets.content("input-section", [
          Widgets.text("input-title", "11.2 Form Input Widgets"),
          Widgets.row("input-row-1", [],
            gap: 16,
            children: [
              Widgets.numeric_input("num-1", value: 42, min: 0, max: 100),
              Widgets.slider("slider-1", value: 75, min: 0, max: 100)
            ]
          ),
          Widgets.row("input-row-2", [],
            gap: 16,
            children: [
              Widgets.date_input("date-1", value: Date.utc_today()),
              Widgets.time_input("time-1", value: Time.utc_now())
            ]
          ),
          Widgets.file_input("file-1", accept: [".png", ".jpg"]),
          Widgets.pick_list("pick-1",
            options: [
              [label: "Option 1", value: "1"],
              [label: "Option 2", value: "2"],
              [label: "Option 3", value: "3"]
            ]
          )
        ]),

        # Section 11.3: Data Display Widgets
        Widgets.content("data-section", [
          Widgets.text("data-title", "11.3 Data Display Widgets"),
          Widgets.row("stat-row", [],
            gap: 16,
            children: [
              Widgets.stat("stat-1",
                value: 45,
                label: "IUR Kinds",
                trend: :up,
                previous_value: 17
              ),
              Widgets.stat("stat-2",
                value: 100,
                label: "Coverage %",
                trend: :neutral,
                unit: "%"
              ),
              Widgets.stat("stat-3",
                value: 28,
                label: "New Widgets",
                trend: :up
              )
            ]
          ),
          Widgets.row("kv-row", [],
            gap: 16,
            children: [
              Widgets.key_value("kv-1", key: "Status", value: "Complete"),
              Widgets.key_value("kv-2", key: "Phase", value: "11")
            ]
          ),
          Widgets.info_list("info-1",
            items: [
              [label: "Badge", value: "Added"],
              [label: "Hero", value: "Added"],
              [label: "Slider", value: "Added"],
              [label: "Stat", value: "Added"]
            ]
          )
        ]),

        # Section 11.4: Feedback Widgets
        Widgets.content("feedback-section", [
          Widgets.text("feedback-title", "11.4 Feedback Widgets"),
          Widgets.row("status-row", [],
            gap: 8,
            children: [
              Widgets.status("status-1", "Ready", severity: :info),
              Widgets.status("status-2", "Success", severity: :success),
              Widgets.status("status-3", "Warning", severity: :warning),
              Widgets.status("status-4", "Error", severity: :error)
            ]
          ),
          Widgets.progress("progress-1", current: 75, total: 100),
          Widgets.inline_feedback("feedback-1",
            message: "All Phase 11 widgets rendered successfully!",
            severity: :success
          )
        ]),

        # Section 11.5: Advanced Widgets
        Widgets.content("advanced-section", [
          Widgets.text("advanced-title", "11.5 Advanced Operational Widgets"),
          Widgets.stream_widget("stream-1",
            entries: [
              [timestamp: DateTime.utc_now(), level: :info, message: "Phase 11 complete"],
              [timestamp: DateTime.utc_now(), level: :success, message: "All widgets rendering"],
              [timestamp: DateTime.utc_now(), level: :info, message: "Validation passed"]
            ],
            follow: true
          )
        ])
      ]
    )
}

# Run the visual test
IO.puts("""
Phase 11 Visual Test
===================

This screen demonstrates all new Phase 11 widgets:

• Foundational: badge, hero, link, separator, spacer
• Form Input: numeric_input, slider, date_input, time_input, file_input, pick_list
• Data Display: stat, key_value, info_list
• Feedback: status, progress, inline_feedback
• Advanced: stream_widget

Running desktop_ui visible runner...
""")

# Mount and run the screen
case DesktopUi.Runtime.mount_native_screen(phase11_screen, platform_target: :linux) do
  {:ok, state} ->
    IO.puts("Screen mounted successfully!")
    IO.puts("Runtime ID: #{state.runtime_id}")
    IO.puts("Screen ID: #{state.screen_id}")

    # Build render plan
    case DesktopUi.Sdl3.RenderPlan.build(state) do
      {:ok, plan} ->
        IO.puts("Render plan built successfully!")
        IO.puts("IUR Widget Coverage: #{plan.presentation.iur_widget_coverage}")
        IO.puts("Supported Kinds: #{plan.presentation.supported_iur_kinds}")
        IO.puts("Draw Operations: #{plan.diagnostics.draw_operation_count}")
        IO.puts("Windows: #{plan.diagnostics.window_count}")

        # Try to run with visible runner if available
        capabilities = DesktopUi.Sdl3.Capabilities.detect()

        if capabilities.build.visible_runner_ready? do
          IO.puts("\nStarting visible window (will close automatically)...\n")

          case DesktopUi.Tooling.run_screen(phase11_screen,
                 backend: :compiled,
                 capabilities: capabilities,
                 linger_ms: 5000
               ) do
            {:ok, execution} ->
              IO.puts("Execution completed!")
              IO.puts("Mode: #{execution.execution_mode}")
              IO.puts("Presented frame: #{execution.presented_frame?}")

            {:error, reason} ->
              IO.puts("Execution error: #{inspect(reason)}")
          end
        else
          IO.puts("\nVisible runner not available.")
          IO.puts("To enable visual testing, ensure SDL3 is installed and the native host is compiled.")
          IO.puts("Run: mix desktop_ui.run native_foundational")
        end

      {:error, reason} ->
        IO.puts("Render plan error: #{inspect(reason)}")
    end

  {:error, reason} ->
    IO.puts("Mount error: #{inspect(reason)}")
end
