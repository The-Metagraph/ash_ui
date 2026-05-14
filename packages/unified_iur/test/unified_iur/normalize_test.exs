defmodule UnifiedIUR.NormalizeTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Binding
  alias UnifiedIUR.Element
  alias UnifiedIUR.Normalize
  alias UnifiedIUR.Style

  test "normalizes raw authored-style input into canonical element shape" do
    input = %{
      "id" => "hero-title",
      "type" => :widget,
      "kind" => :text,
      "metadata" => %{"description" => "Hero title", "tags" => [:hero]},
      "content" => %{"text" => "Unified IUR"},
      "style_refs" => [:headline],
      "variant" => :hero,
      "children" => []
    }

    assert {:ok,
            %Element{
              id: "hero-title",
              kind: :text,
              metadata: %{description: "Hero title", tags: [:hero]},
              attributes: %{
                content: %{text: "Unified IUR"},
                theme: %{
                  component: :text,
                  token_refs: [%{kind: :token_ref, path: [:headline]}],
                  variant: :hero
                }
              },
              children: []
            }} = Normalize.element(input)
  end

  test "normalizes existing canonical elements recursively and preserves canonical attachments" do
    element =
      Element.new(:widget, :text_input,
        id: "email-input",
        attributes: %{
          input: %{value_kind: :text},
          binding: %{name: :email, path: [:profile, :email]},
          style: %{foreground: :primary}
        },
        children: []
      )

    assert {:ok,
            %Element{
              attributes: %{
                input: %{value_kind: :text},
                bindings: [%Binding{name: :email, path: [:profile, :email]}],
                style: %Style{foreground: %{mode: :named, name: :primary}}
              }
            }} = Normalize.element(element)
  end

  test "returns typed errors when canonical shape cannot be produced" do
    assert {:error, [error]} = Normalize.element(%{id: "broken", type: :widget})

    assert error.code == :missing_kind
    assert error.message =~ "missing :kind"
  end
end
