defmodule LiveUi.Widgets.ToolCallCardTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component
  alias UnifiedIUR.Widgets.Components

  describe "tool_call_card widget metadata" do
    test "registers as a row_and_artifact widget with expand_toggled event" do
      metadata = Component.metadata(LiveUi.Widgets.ToolCallCard)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.ToolCallCard.Component
      assert metadata.family == :row_and_artifact
      assert metadata.name == :tool_call_card
      assert :expand_toggled in metadata.events
    end

    test "is present in row_and_artifact aggregation" do
      assert LiveUi.Widgets.ToolCallCard in LiveUi.Widgets.RowAndArtifact.modules()
      assert LiveUi.Widgets.ToolCallCard in LiveUi.Widgets.row_and_artifact_modules()
    end
  end

  describe "tool_call_card component rendering" do
    test "renders the canonical root hooks and header content" do
      html =
        render_component(
          &LiveUi.Widgets.ToolCallCard.component/1,
          base_assigns()
        )

      assert html =~ ~s(data-live-ui-widget="tool-call-card")
      assert html =~ ~s(data-tool-kind="bash")
      assert html =~ ~s(data-status="pending")
      assert html =~ "Bash"
      assert html =~ "mix test"
      assert html =~ "Run focused tests."
      assert html =~ "live-ui-tool-call-card__header"
      assert html =~ "live-ui-tool-call-card__status-badge"
    end

    test "renders status variants as data and BEM hooks" do
      for status <- [:pending, :approved, :denied, :complete, :failed] do
        html =
          render_component(
            &LiveUi.Widgets.ToolCallCard.component/1,
            base_assigns(%{id: "tool-#{status}", status: status})
          )

        assert html =~ ~s(data-status="#{status}")
        assert html =~ "live-ui-tool-call-card--#{status}"
        assert html =~ "is-status-#{status}"
      end
    end

    test "keeps args collapsed until expanded" do
      collapsed =
        render_component(
          &LiveUi.Widgets.ToolCallCard.component/1,
          base_assigns(%{id: "tool-collapsed", expanded?: false})
        )

      expanded =
        render_component(
          &LiveUi.Widgets.ToolCallCard.component/1,
          base_assigns(%{id: "tool-expanded", expanded?: true})
        )

      refute collapsed =~ "live-ui-tool-call-card__args"
      assert collapsed =~ ~s(aria-expanded="false")
      assert expanded =~ "live-ui-tool-call-card__args"
      assert expanded =~ "path: &quot;test/live_ui"
      assert expanded =~ ~s(aria-expanded="true")
    end

    test "renders expand button with fallback event attrs" do
      html =
        render_component(
          &LiveUi.Widgets.ToolCallCard.component/1,
          base_assigns(%{id: "tool-expand"})
        )

      assert html =~ "live-ui-tool-call-card__expand-toggle"
      assert html =~ ~s(aria-label="Toggle tool call Bash details")
      assert html =~ ~s(phx-click="expand_toggled")
    end

    test "renders optional result summary child data" do
      html =
        render_component(
          &LiveUi.Widgets.ToolCallCard.component/1,
          base_assigns(%{
            id: "tool-result",
            status: :complete,
            tool_result_summary: %{
              event_id: "result-1",
              status: :complete,
              compact_output: "All tests passed.",
              diff_summary: "No source diff.",
              error?: false
            }
          })
        )

      assert html =~ "live-ui-tool-call-card__result"
      assert html =~ "result-1"
      assert html =~ "All tests passed."
      assert html =~ "No source diff."
      refute html =~ "live-ui-tool-call-card__result-error"
    end
  end

  describe "renderer dispatch" do
    test "tool_call_card kind is in supported_kinds" do
      assert :tool_call_card in LiveUi.Renderer.supported_kinds()
    end

    test "renders via dedicated renderer clause with canonical interaction attrs" do
      element =
        Components.tool_call_card(
          id: "tool-call-r1",
          tool_name: "Bash",
          tool_kind: :bash,
          target: "mix test",
          summary: "Run focused tests.",
          status: :pending,
          args: %{cmd: "mix test"}
        )

      html =
        render_component(&LiveUi.Renderer.render/1, %{
          element: element,
          event_target: "#runtime-host"
        })

      assert html =~ ~s(data-live-ui-widget="tool-call-card")
      assert html =~ ~s(phx-click="canonical_interaction")
      assert html =~ ~s(phx-target="#runtime-host")
      assert html =~ ~s(phx-value-widget="tool_call_card")
      assert html =~ ~s(phx-value-element_id="tool-call-r1")
      refute html =~ ~s(data-live-ui-component-kind="tool_call_card")
      refute html =~ ~s(data-live-ui-unsupported-native-component)
    end

    test "renderer propagates expanded state and paired result child" do
      element =
        Components.tool_call_card(
          id: "tool-call-r2",
          tool_name: "Read",
          tool_kind: :read,
          target: "lib/ash_ui.ex",
          summary: "Read the file.",
          status: :complete,
          args: %{path: "lib/ash_ui.ex"},
          expanded?: true,
          paired_result_event_id: "tool-result-r2",
          tool_result_summary: %{
            event_id: "tool-result-r2",
            status: :complete,
            compact_output: "Loaded file.",
            error?: false
          }
        )

      html = render_component(&LiveUi.Renderer.render/1, %{element: element})

      assert html =~ ~s(aria-expanded="true")
      assert html =~ "live-ui-tool-call-card__args"
      assert html =~ "Loaded file."
      assert html =~ "tool-result-r2"
      refute html =~ "Unsupported canonical kind"
    end
  end

  defp base_assigns(overrides \\ %{}) do
    Map.merge(
      %{
        id: "tool-card",
        tool_name: "Bash",
        tool_kind: :bash,
        target: "mix test",
        summary: "Run focused tests.",
        status: :pending,
        args: %{cmd: "mix test", path: "test/live_ui/widgets/tool_call_card_test.exs"},
        expanded?: false
      },
      overrides
    )
  end
end
