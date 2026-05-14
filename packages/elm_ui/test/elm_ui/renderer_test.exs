defmodule ElmUi.RendererTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element
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

  test "renderer rejects unsupported canonical kinds with structured diagnostics" do
    element =
      Element.new(:widget, :timeline, id: :timeline_root, attributes: %{title: "Unsupported"})

    assert {:error, %Error{code: :unsupported_kind, details: %{kind: :timeline}}} =
             ElmUi.Renderer.render(element)
  end
end
