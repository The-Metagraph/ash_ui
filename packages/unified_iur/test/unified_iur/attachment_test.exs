defmodule UnifiedIUR.AttachmentTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Attachment
  alias UnifiedIUR.Binding
  alias UnifiedIUR.Interaction
  alias UnifiedIUR.Style

  test "normalizes local style and theme hooks into canonical attachment shapes" do
    attributes =
      Attachment.merge(
        %{},
        [
          style_refs: [:surface],
          variant: :hero
        ],
        component: :text,
        local_style: %{foreground: :primary, tone: :accent}
      )

    assert %{
             style: %Style{emphasis: %{tone: :accent}},
             theme: %{
               component: :text,
               variant: :hero,
               token_refs: [%{kind: :token_ref, path: [:surface]}]
             }
           } = attributes
  end

  test "normalizes canonical bindings, interactions, and container interaction scope" do
    attributes =
      Attachment.merge(
        %{},
        [
          interaction_scope: [mode: :bubble, namespace: :workspace],
          interaction_scope_target_path: [:screen, :toolbar]
        ],
        fallback_bindings: %{name: :email, path: [:profile, :email]},
        fallback_interactions: Interaction.submit(intent: :save_profile, binding: [:profile])
      )

    assert %{
             bindings: [%Binding{name: :email, path: [:profile, :email]}],
             interactions: [%Interaction{family: :submit, intent: :save_profile}],
             interaction_scope: %{
               mode: :bubble,
               namespace: :workspace,
               target_path: [:screen, :toolbar]
             }
           } = attributes
  end

  test "rejects ambiguous singular and plural attachment inputs" do
    assert_raise ArgumentError, ~r/binding and bindings/, fn ->
      Attachment.merge(%{}, %{binding: %{name: :email}, bindings: [%{name: :email}]})
    end

    assert_raise ArgumentError, ~r/interaction and interactions/, fn ->
      Attachment.merge(
        %{},
        %{interaction: %{family: :click}, interactions: [%{family: :click}]}
      )
    end
  end
end
