defmodule UnifiedIUR.InteractionsTransportTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Interactions.Transport

  test "exposes maintained shared boundary fixtures and review summaries" do
    assert Transport.boundary_fixture_ids() == [
             "screen_transition--settings_profile",
             "replace_transition--home",
             "history_transition--back",
             "modal_transition--settings_dialog",
             "modal_stack--open_confirm_dialog",
             "modal_stack--close_top",
             "modal_stack--close_named_settings"
           ]

    assert {:ok, fixture} = Transport.boundary_fixture("screen_transition--settings_profile")

    assert fixture.signal_data == %{mapping: %{origin: :workspace}}

    assert fixture.summary == %{
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

    assert fixture.extensions == %{
             unified_iur_boundary: fixture.descriptor,
             unified_iur_boundary_summary: fixture.summary
           }

    assert :ok = Transport.validate_boundary_fixture(fixture)
  end

  test "keeps targetless history transitions portable without fake screen ids" do
    fixture = Transport.boundary_fixture!("history_transition--back")

    assert fixture.summary.targetless?

    assert fixture.descriptor.target == %{
             navigation: %{
               action: :go_back,
               kind: :history_transition,
               metadata: %{source: :header}
             }
           }

    assert :ok = Transport.validate_boundary_extensions(fixture.extensions)
  end

  test "summarizes and validates modal stack boundary semantics" do
    open_fixture = Transport.boundary_fixture!("modal_stack--open_confirm_dialog")
    close_top_fixture = Transport.boundary_fixture!("modal_stack--close_top")
    close_named_fixture = Transport.boundary_fixture!("modal_stack--close_named_settings")

    assert open_fixture.summary == %{
             family: :navigation,
             intent: :open_confirm_modal,
             action: :open_modal,
             screen: nil,
             modal: :settings_confirm_dialog,
             params: %{from: :settings_dialog},
             metadata: %{previous_modal: :settings_dialog},
             params?: true,
             targetless?: false,
             modal_stack?: true,
             modal_stack_operation: :push,
             modal_stack_target: :symbolic_modal,
             modal_stack_effect: :push_modal,
             modal_stack_close: nil
           }

    assert close_top_fixture.summary == %{
             family: :navigation,
             intent: :close_top_modal,
             action: :close_modal,
             screen: nil,
             modal: nil,
             params: %{},
             metadata: %{reason: :cancel},
             params?: false,
             targetless?: true,
             modal_stack?: true,
             modal_stack_operation: :close,
             modal_stack_target: :topmost_modal,
             modal_stack_effect: :close_topmost_or_named_modal,
             modal_stack_close: :topmost
           }

    assert close_named_fixture.summary.modal == :settings_dialog
    refute close_named_fixture.summary.targetless?
    assert close_named_fixture.summary.modal_stack_close == :targeted
    assert close_named_fixture.summary.modal_stack_effect == :close_topmost_or_named_modal

    assert :ok = Transport.validate_boundary_fixture(open_fixture)
    assert :ok = Transport.validate_boundary_fixture(close_top_fixture)
    assert :ok = Transport.validate_boundary_fixture(close_named_fixture)
  end

  test "rejects leaked router syntax and missing required canonical fields" do
    assert {:error, {:forbidden_navigation_keys, [:route]}} =
             Transport.validate_boundary_extensions(%{
               unified_iur_boundary: %{
                 family: :navigation,
                 intent: :open_settings_screen,
                 source_context: %{element_id: "settings-link"},
                 target: %{navigation: %{action: :navigate_to, route: "/settings"}},
                 metadata: %{}
               },
               unified_iur_boundary_summary: %{}
             })

    assert {:error, {:missing_field, :screen}} =
             Transport.validate_boundary_extensions(%{
               unified_iur_boundary: %{
                 family: :navigation,
                 intent: :open_settings_screen,
                 source_context: %{element_id: "settings-link"},
                 target: %{navigation: %{action: :navigate_to}},
                 metadata: %{}
               },
               unified_iur_boundary_summary: %{
                 family: :navigation,
                 intent: :open_settings_screen,
                 action: :navigate_to,
                 screen: nil,
                 modal: nil,
                 params: %{},
                 metadata: %{},
                 params?: false,
                 targetless?: true,
                 modal_stack?: false,
                 modal_stack_operation: nil,
                 modal_stack_target: nil,
                 modal_stack_effect: nil,
                 modal_stack_close: nil
               }
             })
  end

  test "rejects URL-like targets, host-router names, and runtime module references" do
    for {key, value} <- [
          url: "/settings?tab=profile",
          router: :workspace_router,
          runtime_module: DesktopUi.Navigation.Controller.MockScreen.Settings
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

  test "rejects runtime-local modal stack identifiers crossing the boundary" do
    assert {:error, {:forbidden_navigation_keys, [:stack_id]}} =
             Transport.validate_boundary_extensions(%{
               unified_iur_boundary: %{
                 family: :navigation,
                 intent: :open_confirm_modal,
                 source_context: %{element_id: "confirm-settings-button"},
                 target: %{
                   navigation: %{
                     action: :open_modal,
                     modal: :settings_confirm_dialog,
                     modal_stack: %{
                       operation: :push,
                       target: :symbolic_modal,
                       stack_effect: :push_modal,
                       stack_id: "runtime-stack-1"
                     }
                   }
                 },
                 metadata: %{}
               },
               unified_iur_boundary_summary: %{}
             })
  end

  test "rejects structural modal containment in shared stack descriptors" do
    assert {:error, {:invalid_modal_stack_containment, true}} =
             Transport.validate_boundary_extensions(%{
               unified_iur_boundary: %{
                 family: :navigation,
                 intent: :open_confirm_modal,
                 source_context: %{element_id: "confirm-settings-button"},
                 target: %{
                   navigation: %{
                     action: :open_modal,
                     modal: :settings_confirm_dialog,
                     modal_stack: %{
                       operation: :push,
                       target: :symbolic_modal,
                       stack_effect: :push_modal,
                       containment_required?: true
                     }
                   }
                 },
                 metadata: %{}
               },
               unified_iur_boundary_summary: %{}
             })
  end
end
