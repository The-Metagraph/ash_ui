defmodule AshUI.CanonicalNavigationTest do
  use ExUnit.Case, async: true

  alias AshUI.Compilation.IUR
  alias AshUI.Navigation.Intent
  alias AshUI.Rendering.IURAdapter
  alias UnifiedIUR.Interactions.Transport

  describe "Section 30.3 - resource-authored canonical navigation intent" do
    test "normalizes supported symbolic navigation actions" do
      assert %{
               action: :navigate_to,
               screen: :settings,
               params: %{tab: :profile}
             } =
               Intent.normalize!(%{
                 action: :navigate_to,
                 screen: :settings,
                 params: %{tab: :profile}
               })
    end

    test "rejects host runtime fields in navigation intent" do
      assert_raise ArgumentError, ~r/route/, fn ->
        Intent.normalize!(%{
          action: :navigate_to,
          screen: :settings,
          route: "/settings"
        })
      end

      assert_raise ArgumentError, ~r/modal_stack_id/, fn ->
        Intent.normalize!(%{
          action: :open_modal,
          modal: :confirm,
          modal_stack_id: "runtime-stack"
        })
      end
    end

    test "allows element resources to declare navigation actions without Ash action sources" do
      assert {:ok, [action]} =
               AshUI.Resource.Info.element_actions(
                 AshUI.Test.ResourceAuthorityNavigationButtonElement
               )

      assert action[:id] == :open_settings
      assert action[:navigation][:action] == :navigate_to
      assert action[:navigation][:screen] == :settings
    end

    test "compiles navigation actions into canonical Unified IUR interactions" do
      ash_iur =
        IUR.new(:screen,
          children: [
            IUR.new(:button,
              id: "settings-button",
              props: %{
                label: "Settings",
                actions: [
                  %{
                    id: :open_settings,
                    signal: :click,
                    navigation: %{
                      action: :navigate_to,
                      screen: :settings,
                      params: %{tab: :profile}
                    }
                  }
                ]
              }
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      [button_child] = canonical.children
      [interaction] = button_child.element.attributes.interactions

      assert interaction.family == :navigation
      assert interaction.intent == :navigate_to
      assert get_in(interaction.target, [:navigation, :screen]) == :settings
      assert get_in(interaction.target, [:navigation, :params, :tab]) == :profile

      assert :ok =
               interaction
               |> Transport.boundary_descriptor()
               |> Transport.validate_boundary_descriptor()
    end

    test "compiles modal close as symbolic topmost stack intent" do
      ash_iur =
        IUR.new(:screen,
          attributes: %{
            actions: [
              %{
                id: :close_dialog,
                signal: :click,
                navigation: %{action: :close_modal}
              }
            ]
          }
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      [interaction] = canonical.attributes.interactions
      navigation = interaction.target.navigation

      assert navigation.action == :close_modal
      assert navigation.modal_stack.stack_effect == :close_topmost_or_named_modal
      refute Map.has_key?(navigation, :modal_stack_id)
    end
  end
end
