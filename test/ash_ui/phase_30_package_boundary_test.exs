defmodule AshUI.Phase30PackageBoundaryTest do
  use ExUnit.Case, async: true

  @navigation_actions [
    :navigate_to,
    :replace_with,
    :go_back,
    :go_forward,
    :open_modal,
    :close_modal
  ]

  describe "Section 30.1 - package boundary and dependency adoption" do
    test "Unified packages expose the canonical IUR and navigation boundary" do
      assert Code.ensure_loaded?(UnifiedIUR.Element)
      assert Code.ensure_loaded?(UnifiedIUR.Element.Child)
      assert Code.ensure_loaded?(UnifiedIUR.Interaction)
      assert Code.ensure_loaded?(UnifiedIUR.Interactions.Transport)
      assert Code.ensure_loaded?(UnifiedUi.Signal)

      assert %UnifiedIUR.Element{} = UnifiedIUR.Element.new(:composite, :screen)
      assert %UnifiedIUR.Element.Child{} = UnifiedIUR.Element.Child.empty(:default)

      assert :navigation in UnifiedUi.Signal.families()
      assert :navigation in UnifiedIUR.Interaction.families()
      assert UnifiedUi.Signal.navigation_actions() == @navigation_actions
      assert UnifiedIUR.Interaction.navigation_actions() == @navigation_actions

      assert %{
               interaction: UnifiedIUR.Interaction,
               binding: UnifiedIUR.Binding,
               transport: UnifiedIUR.Interactions.Transport
             } = UnifiedIUR.Interactions.modules()
    end

    test "runtime packages expose upgraded renderer namespaces that consume canonical elements" do
      for renderer <- [LiveUi.Renderer, ElmUi.Renderer, DesktopUi.Renderer] do
        assert Code.ensure_loaded?(renderer)
        assert function_exported?(renderer, :accepts, 0)
        assert renderer.accepts() == UnifiedIUR.Element
      end
    end
  end
end
