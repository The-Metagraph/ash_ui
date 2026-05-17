defmodule LiveUi.ToolingTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.{Container, Layout}
  alias UnifiedIUR.Token
  alias UnifiedIUR.Widgets.Foundational

  defmodule StyledInspectableScreen do
    use LiveUi.Screen, id: :styled_inspectable, title: "Styled Inspectable"

    @impl true
    def mount_defaults do
      %{message: "Ready"}
    end

    @impl true
    def render(assigns) do
      assigns =
        assigns
        |> Map.put(
          :shell_style,
          LiveUi.Style.component_assigns(:screen_shell,
            theme: LiveUi.Theme.default(),
            variant: :workspace,
            class: "native-shell"
          )
        )
        |> Map.put(
          :text_style,
          LiveUi.Style.component_assigns(:text,
            theme: LiveUi.Theme.default(),
            tone: :success,
            class: "native-status"
          )
        )

      ~H"""
      <LiveUi.Widgets.ScreenShell.render id="styled-screen" title={title()} {@shell_style}>
        <LiveUi.Widgets.Text.render id="status" content={@message} {@text_style} />
      </LiveUi.Widgets.ScreenShell.render>
      """
    end
  end

  defp canonical_element do
    Container.box(
      [
        Layout.column([
          Foundational.text("Ready",
            id: "status",
            style: %{emphasis: %{tone: :success}, extra: %{class: "native-status"}},
            theme: %{id: :live_ui}
          )
        ])
      ],
      id: "styled-screen",
      style: %{extra: %{class: "native-shell"}},
      theme: %{id: :live_ui, variant: :panel}
    )
  end

  defp canonical_drift_element do
    Container.box(
      [
        Layout.column([
          Foundational.text("Ready",
            id: "status",
            style: %{foreground: "#f97316", extra: %{class: "native-status"}},
            theme: %{id: :live_ui}
          )
        ])
      ],
      id: "styled-screen",
      style: %{extra: %{class: "native-shell"}},
      theme: %{id: :live_ui, variant: :panel}
    )
  end

  defp canonical_diagnostic_element do
    Container.box(
      [
        Layout.column([
          Foundational.text("Needs review",
            id: "status",
            style: %{
              foreground: "#10b981",
              text: %{blink?: true},
              state_variants: %{hovered: %{foreground: "#f97316"}}
            },
            theme: %{id: :live_ui, token_refs: [Token.ref([:missing, :panel])]}
          )
        ])
      ],
      id: "styled-screen",
      style: %{extra: %{class: "native-shell"}},
      theme: %{id: :live_ui, variant: :panel}
    )
  end

  test "tooling inspects native and canonical runtime output through one snapshot shape" do
    assert {:ok, native} = LiveUi.Tooling.inspect_native(StyledInspectableScreen)
    assert {:ok, canonical} = LiveUi.Tooling.inspect_canonical(canonical_element())

    assert native.path == :native
    assert canonical.path == :canonical
    assert "screen-shell" in native.widgets
    assert "text" in native.widgets
    assert "box" in canonical.widgets
    assert "text" in canonical.widgets
    assert "success" in native.tones
    assert "success" in canonical.tones
    assert "--live-ui-gap" in native.browser_style.css_var_keys
    assert native.browser_style.realized_fields != []
    assert canonical.browser_style.css_var_keys != []
  end

  test "tooling compares native and canonical outputs and reports continuity diagnostics" do
    assert {:ok, report} =
             LiveUi.Tooling.compare_native_and_canonical(
               StyledInspectableScreen,
               canonical_element()
             )

    assert "text" in report.shared_widgets
    assert report.continuity.runtime_model_aligned?
    assert report.continuity.tone_overlap?
    refute report.continuity.browser_style_aligned?
    assert report.native_only_widgets != []
    assert report.canonical_only_widgets != []
    assert Enum.any?(report.diagnostics, &(&1.reason == :native_only_behavior))
    assert Enum.any?(report.diagnostics, &(&1.reason == :canonical_only_behavior))
    assert Enum.any?(report.diagnostics, &(&1.reason == :browser_style_drift))
    assert report.browser_style.shape_mismatches != []
  end

  test "tooling reports browser-style drift for shared entries with conflicting realized output" do
    assert {:ok, report} =
             LiveUi.Tooling.compare_native_and_canonical(
               StyledInspectableScreen,
               canonical_drift_element()
             )

    refute report.browser_style.aligned?
    assert "status" in report.browser_style.drift_ids

    status_report = Enum.find(report.browser_style.entry_reports, &(&1.id == "status"))

    assert status_report.status == :drift
    assert status_report.native_only_css_vars == []
    assert status_report.canonical_only_css_vars != []
    assert Enum.any?(report.diagnostics, &(&1.reason == :browser_style_drift))
  end

  test "render_runtime produces distinct wrapper ids across multiple calls" do
    # Regression test: LiveUi.Tooling.render_runtime/1 previously hardcoded
    # id: "tooling-runtime" on the wrapper element. When render_widget!/1 is called
    # more than once per LiveView render cycle (e.g. ariston-ui /operator renders
    # top_strip and sidebar_shell in the same cycle), both wrappers would emit the
    # same id → Phoenix.HTML duplicate-id crash. Each inspect_canonical call exercises
    # render_runtime/1 internally. We extract the wrapper id from the rendered HTML
    # and assert the two calls produce different ids.
    element = canonical_element()

    assert {:ok, first} = LiveUi.Tooling.inspect_canonical(element)
    assert {:ok, second} = LiveUi.Tooling.inspect_canonical(element)

    # Extract "tooling-runtime..." id attribute from each rendered HTML string
    extract_tooling_id = fn html ->
      case Regex.run(~r/id="(tooling-runtime[^"]*)"/, html) do
        [_, id] -> id
        nil -> nil
      end
    end

    first_id = extract_tooling_id.(first.html)
    second_id = extract_tooling_id.(second.html)

    assert first_id != nil, "expected tooling-runtime wrapper id in first render"
    assert second_id != nil, "expected tooling-runtime wrapper id in second render"

    assert first_id != second_id,
           "render_runtime must produce unique ids per call (got #{first_id} twice)"
  end

  test "tooling summarizes unsupported ignored and unresolved browser-style inputs" do
    assert {:ok, canonical} = LiveUi.Tooling.inspect_canonical(canonical_diagnostic_element())

    assert "text.blink?" in canonical.browser_style.unsupported_fields
    assert "state_variants.hovered" in canonical.browser_style.ignored_fields
    assert "missing.panel" in canonical.browser_style.unresolved_token_refs
    assert "status" in canonical.browser_style.unsupported_entry_ids
    assert "status" in canonical.browser_style.ignored_entry_ids
    assert "status" in canonical.browser_style.unresolved_reference_entry_ids

    status_node = Enum.find(canonical.browser_style_nodes, &(&1.id == "status"))

    assert status_node.mode == "mixed"
    assert status_node.fallback == "mixed"
    assert "--live-ui-foreground" in status_node.css_var_keys
    assert status_node.unresolved_token_refs == ["missing.panel"]
  end
end
