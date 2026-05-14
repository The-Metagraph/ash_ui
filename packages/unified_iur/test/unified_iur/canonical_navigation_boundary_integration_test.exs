defmodule UnifiedIUR.CanonicalNavigationBoundaryIntegrationTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Interactions.Transport

  test "shared boundary fixtures preserve canonical transition meaning deterministically" do
    first =
      Transport.boundary_fixtures()
      |> Enum.map(&Map.take(&1, [:id, :signal_data, :extensions, :summary]))

    second =
      Transport.boundary_fixtures()
      |> Enum.map(&Map.take(&1, [:id, :signal_data, :extensions, :summary]))

    assert first == second

    assert Enum.all?(
             Transport.boundary_fixtures(),
             &(Transport.validate_boundary_fixture(&1) == :ok)
           )

    assert Enum.find(first, &(&1.id == "screen_transition--settings_profile")) == %{
             id: "screen_transition--settings_profile",
             signal_data: %{mapping: %{origin: :workspace}},
             extensions: %{
               unified_iur_boundary: %{
                 family: :navigation,
                 intent: :open_settings_screen,
                 source_context: %{element_id: "settings-link", scope: :screen},
                 target: %{
                   navigation: %{
                     action: :navigate_to,
                     kind: :screen_transition,
                     params: %{tab: :profile},
                     screen: :settings
                   }
                 },
                 metadata: %{}
               },
               unified_iur_boundary_summary: %{
                 family: :navigation,
                 intent: :open_settings_screen,
                 action: :navigate_to,
                 screen: :settings,
                 modal: nil,
                 params: %{tab: :profile},
                 metadata: %{},
                 params?: true,
                 targetless?: false,
                 modal_stack?: false,
                 modal_stack_operation: nil,
                 modal_stack_target: nil,
                 modal_stack_effect: nil,
                 modal_stack_close: nil
               }
             },
             summary: %{
               family: :navigation,
               intent: :open_settings_screen,
               action: :navigate_to,
               screen: :settings,
               modal: nil,
               params: %{tab: :profile},
               metadata: %{},
               params?: true,
               targetless?: false,
               modal_stack?: false,
               modal_stack_operation: nil,
               modal_stack_target: nil,
               modal_stack_effect: nil,
               modal_stack_close: nil
             }
           }
  end

  test "shared modal stack fixtures validate before runtime package consumption" do
    fixtures =
      [
        "modal_transition--settings_dialog",
        "modal_stack--open_confirm_dialog",
        "modal_stack--close_top",
        "modal_stack--close_named_settings"
      ]
      |> Enum.map(&Transport.boundary_fixture!/1)

    assert Enum.all?(fixtures, &(Transport.validate_boundary_fixture(&1) == :ok))

    assert Enum.map(fixtures, & &1.summary.modal_stack_effect) == [
             :push_modal,
             :push_modal,
             :close_topmost_or_named_modal,
             :close_topmost_or_named_modal
           ]

    assert Enum.map(fixtures, & &1.summary.modal_stack_close) == [
             nil,
             nil,
             :topmost,
             :targeted
           ]

    for fixture <- fixtures do
      assert fixture.extensions.unified_iur_boundary == fixture.descriptor
      assert fixture.extensions.unified_iur_boundary_summary == fixture.summary
      refute Map.has_key?(fixture.descriptor.target.navigation, :route)
      refute Map.has_key?(fixture.descriptor.target.navigation, :module)
      refute Map.has_key?(fixture.descriptor.target.navigation.modal_stack, :stack_id)
    end
  end

  test "shared boundary validation rejects malformed payloads and leaked route syntax" do
    assert {:error, {:invalid_boundary_payload, "oops"}} =
             Transport.validate_boundary_payload("oops")

    assert {:error, {:forbidden_navigation_keys, [:route]}} =
             Transport.validate_boundary_extensions(%{
               unified_iur_boundary: %{
                 family: :navigation,
                 intent: :open_settings_screen,
                 source_context: %{element_id: "settings-link"},
                 target: %{
                   navigation: %{action: :navigate_to, screen: :settings, route: "/settings"}
                 },
                 metadata: %{}
               },
               unified_iur_boundary_summary: %{
                 family: :navigation,
                 intent: :open_settings_screen,
                 action: :navigate_to,
                 screen: :settings,
                 modal: nil,
                 params?: false,
                 targetless?: false
               }
             })
  end

  test "shared boundary validation rejects URL-like targets, router names, and runtime modules" do
    for {key, value} <- [
          url: "https://example.invalid/settings",
          router: :workspace_router,
          runtime_module: LiveUi.Runtime
        ] do
      assert {:error, {:forbidden_navigation_keys, [^key]}} =
               Transport.validate_boundary_extensions(%{
                 unified_iur_boundary: %{
                   family: :navigation,
                   intent: :open_settings_screen,
                   source_context: %{element_id: "settings-link"},
                   target: %{
                     navigation:
                       Map.merge(%{action: :navigate_to, screen: :settings}, %{key => value})
                   },
                   metadata: %{}
                 },
                 unified_iur_boundary_summary: %{}
               })
    end
  end
end
