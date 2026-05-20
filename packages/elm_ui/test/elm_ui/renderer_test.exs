defmodule ElmUi.RendererTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element
  alias UnifiedIUR.Widgets.Feedback
  alias UnifiedIUR.Widgets.Navigation
  alias ElmUi.Renderer.Error
  alias ElmUi.Widget

  test "renderer accepts canonical iur input and maps it to native widgets" do
    element = Element.new(:widget, :text, id: :headline, attributes: %{content: "Hello"})

    assert {:ok, %Widget{kind: :text, attributes: %{content: "Hello"}}} =
             ElmUi.Renderer.render(element)
  end

  test "renderer produces deterministic output for equivalent canonical input" do
    element = Element.new(:widget, :button, id: :cta, attributes: %{label: "Open"})

    assert ElmUi.Renderer.render(element) == ElmUi.Renderer.render(element)
  end

  test "renderer maps context_selector as a native navigation widget" do
    element =
      Navigation.context_selector(
        id: "workspace-context",
        selector_id: "workspace-context",
        groups: [
          %{
            id: :workspace,
            label: "Workspace",
            items: [%{value: :all, label: "All workspaces"}]
          }
        ],
        selected_values: [:all],
        max_selections: :unlimited,
        open?: true
      )

    assert {:ok, %Widget{} = widget} = ElmUi.Renderer.render(element)
    assert widget.kind == :context_selector
    assert widget.family == :navigation
    assert widget.attributes.selector_id == "workspace-context"
    assert widget.attributes.selected_values == [:all]
    assert widget.attributes.multiple?
    assert widget.state.open
    assert [%{label: "Workspace", items: [%{label: "All workspaces"}]}] = widget.attributes.groups
  end

  test "renderer maps diff_banner as a native feedback widget" do
    element =
      Feedback.diff_banner(
        id: "ask-diff",
        new_count: 3,
        changed_count: 5,
        removed_count: 1,
        active_filter: :new
      )

    assert {:ok, %Widget{} = widget} = ElmUi.Renderer.render(element)
    assert widget.kind == :diff_banner
    assert widget.family == :feedback
    assert widget.attributes.new_count == 3
    assert widget.attributes.changed_count == 5
    assert widget.attributes.removed_count == 1
    assert widget.state.active_filter == :new
  end

  test "renderer rejects unsupported canonical kinds with structured diagnostics" do
    element =
      Element.new(:widget, :timeline, id: :timeline_root, attributes: %{title: "Unsupported"})

    assert {:error, %Error{code: :unsupported_kind, details: %{kind: :timeline}}} =
             ElmUi.Renderer.render(element)
  end
end
