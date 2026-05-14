defmodule ElmUi.CanonicalNavigationWebRuntimeIntegrationTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element
  alias UnifiedIUR.Interactions.Transport, as: BoundaryTransport

  test "maintained navigation example keeps authoritative server and frontend screens aligned across native and canonical flows" do
    navigate_fixture = BoundaryTransport.boundary_fixture!("screen_transition--settings_profile")
    replace_fixture = BoundaryTransport.boundary_fixture!("replace_transition--home")
    modal_fixture = BoundaryTransport.boundary_fixture!("modal_transition--settings_dialog")
    second_modal_fixture = BoundaryTransport.boundary_fixture!("modal_stack--open_confirm_dialog")
    close_top_fixture = BoundaryTransport.boundary_fixture!("modal_stack--close_top")

    comparison = ElmUi.Examples.navigation_comparison()

    assert transition_summary(comparison.native.after_navigate.navigation.last_transition) ==
             transition_summary(navigate_fixture.descriptor.target.navigation)

    assert transition_summary(comparison.canonical.after_navigate.navigation.last_transition) ==
             transition_summary(navigate_fixture.descriptor.target.navigation)

    assert transition_summary(comparison.native.after_replace.navigation.last_transition) ==
             transition_summary(replace_fixture.descriptor.target.navigation)

    assert transition_summary(comparison.canonical.after_replace.navigation.last_transition) ==
             transition_summary(replace_fixture.descriptor.target.navigation)

    assert modal_summary(comparison.native.after_modal.navigation.current_modal) ==
             modal_summary(modal_fixture.descriptor.target.navigation)

    assert modal_summary(comparison.canonical.after_modal.navigation.current_modal) ==
             modal_summary(modal_fixture.descriptor.target.navigation)

    assert modal_summary(comparison.native.after_second_modal.navigation.current_modal) ==
             modal_summary(second_modal_fixture.descriptor.target.navigation)

    assert modal_summary(comparison.canonical.after_second_modal.navigation.current_modal) ==
             modal_summary(second_modal_fixture.descriptor.target.navigation)

    assert modal_stack_summary(comparison.native.after_top_close.navigation.last_transition) ==
             modal_stack_summary(close_top_fixture.descriptor.target.navigation)

    assert modal_stack_summary(comparison.canonical.after_top_close.navigation.last_transition) ==
             modal_stack_summary(close_top_fixture.descriptor.target.navigation)

    assert Enum.map(comparison.native.after_second_modal.navigation.modals, & &1.modal) == [
             :settings_dialog,
             :settings_confirm_dialog
           ]

    assert comparison.native.after_top_close.navigation.current_modal.modal == :settings_dialog
    assert comparison.canonical.after_top_close.navigation.current_modal.modal == :settings_dialog

    assert comparison.native.after_second_modal.navigation.history ==
             comparison.native.after_modal.navigation.history

    assert comparison.native.after_top_close.navigation.history ==
             comparison.native.after_second_modal.navigation.history

    assert comparison.canonical.after_second_modal.navigation.history ==
             comparison.canonical.after_modal.navigation.history

    assert comparison.canonical.after_top_close.navigation.history ==
             comparison.canonical.after_second_modal.navigation.history

    assert comparison.continuity.same_navigation_target?
    assert comparison.continuity.frontend_coordination?
    assert comparison.continuity.same_modal_identifier?
    assert comparison.continuity.same_second_modal_identifier?
    assert comparison.continuity.top_close_restores_previous_modal?
    assert comparison.continuity.modal_stack_reflected?
    assert comparison.continuity.same_replacement_target?
    assert comparison.continuity.server_authority_preserved?
  end

  test "server-authoritative modal stack fixtures are reflected in frontend acknowledgements" do
    home_element =
      Element.new(:widget, :text, id: "home", attributes: %{content: "Home"})

    first_modal = BoundaryTransport.boundary_fixture!("modal_transition--settings_dialog")
    second_modal = BoundaryTransport.boundary_fixture!("modal_stack--open_confirm_dialog")
    close_top = BoundaryTransport.boundary_fixture!("modal_stack--close_top")
    close_named = BoundaryTransport.boundary_fixture!("modal_stack--close_named_settings")

    assert {:ok, runtime_state} =
             ElmUi.Runtime.mount_iur_screen(home_element, runtime_id: "elm-ui-modal-stack")

    for fixture <- [first_modal, second_modal, close_top, close_named] do
      assert :ok = BoundaryTransport.validate_boundary_fixture(fixture)
    end

    assert {:ok, with_first_modal, _ack} = apply_fixture(runtime_state, first_modal)
    assert {:ok, with_second_modal, ack} = apply_fixture(with_first_modal, second_modal)

    navigation = ElmUi.ServerRuntime.State.navigation_summary(with_second_modal)

    assert navigation.history == []

    assert navigation.modals == [
             %{
               modal: :settings_dialog,
               params: %{mode: :advanced},
               metadata: %{surface: :workspace}
             },
             %{
               modal: :settings_confirm_dialog,
               params: %{from: :settings_dialog},
               metadata: %{previous_modal: :settings_dialog}
             }
           ]

    assert navigation.current_modal.modal == :settings_confirm_dialog
    assert navigation.last_transition.modal_stack.stack_effect == :push_modal

    assert ack.payload.authoritative_screen.metadata.navigation.current_modal.modal ==
             :settings_confirm_dialog

    assert ack.payload.authoritative_screen.metadata.navigation.modals == navigation.modals

    assert {:ok, after_named_close, _ack} = apply_fixture(with_second_modal, close_named)

    assert ElmUi.ServerRuntime.State.navigation_summary(after_named_close).modals == [
             %{
               modal: :settings_confirm_dialog,
               params: %{from: :settings_dialog},
               metadata: %{previous_modal: :settings_dialog}
             }
           ]

    assert {:ok, after_top_close, _ack} = apply_fixture(after_named_close, close_top)

    assert ElmUi.ServerRuntime.State.navigation_summary(after_top_close).modals == []
    assert ElmUi.ServerRuntime.State.navigation_summary(after_top_close).current_modal == nil
  end

  test "canonical elm_ui navigation keeps host-route state outside the transition contract" do
    comparison = ElmUi.Examples.navigation_comparison()

    refute Map.has_key?(comparison.host_route_fixture.canonical_target, :route)
    refute Map.has_key?(comparison.host_route_fixture.canonical_target, :path)

    assert comparison.native.after_navigate.authoritative_host_route.path == "/workspace/settings"

    assert comparison.canonical.after_navigate.authoritative_host_route.path ==
             "/workspace/settings"

    assert comparison.continuity.host_route_externalized?

    assert {:ok, translation} =
             ElmUi.Transport.from_native_event(
               family: :navigation,
               intent: :open_settings_screen,
               widget_id: "settings-link",
               screen: "home",
               runtime_id: "contract-check",
               source_kind: :canonical,
               boundary_mode: :canonical_boundary,
               target: %{
                 navigation: %{action: :navigate_to, screen: :settings, params: %{tab: :profile}}
               }
             )

    assert transition_summary(translation.target.navigation) ==
             transition_summary(comparison.host_route_fixture.canonical_target)
  end

  test "frontend route divergence is reported deterministically when browser-local state disagrees" do
    home_element = Element.new(:widget, :text, id: "home", attributes: %{content: "Home"})

    settings_element =
      Element.new(:widget, :text, id: "settings", attributes: %{content: "Settings"})

    assert {:ok, runtime_state} =
             ElmUi.Runtime.mount_iur_screen(home_element,
               runtime_id: "canonical-navigation-divergence",
               screen_registry: %{settings: settings_element}
             )

    assert {:ok, frontend_model} = ElmUi.Runtime.hydrate_frontend(runtime_state)

    assert {:ok, frontend_after_dispatch, event_message} =
             ElmUi.FrontendRuntime.dispatch_interaction(frontend_model,
               family: :navigation,
               intent: :open_settings_screen,
               boundary: :boundary,
               widget_id: "settings-link",
               target: %{
                 navigation: %{action: :navigate_to, screen: :settings, params: %{tab: :profile}}
               },
               route_state: %{screen_id: "wrong-screen", path: "/workspace/wrong-screen"}
             )

    assert frontend_after_dispatch.local_state.pending_boundary_event.runtime_event ==
             "navigation:open_settings_screen"

    assert {:ok, next_state, ack_message} =
             ElmUi.Runtime.handle_frontend_event(runtime_state, event_message)

    assert Enum.any?(next_state.diagnostics, fn diagnostic ->
             diagnostic.reason == :frontend_route_state_divergence and
               to_string(diagnostic.authoritative_screen) == "settings"
           end)

    assert Enum.any?(ack_message.payload.diagnostics, fn diagnostic ->
             diagnostic.reason == :frontend_route_state_divergence and
               to_string(diagnostic.authoritative_screen) == "settings"
           end)
  end

  test "modal stack diagnostics reject invalid targeted close and runtime-local stack ids" do
    home_element =
      Element.new(:widget, :text, id: "home", attributes: %{content: "Home"})

    close_named = BoundaryTransport.boundary_fixture!("modal_stack--close_named_settings")

    assert {:ok, runtime_state} =
             ElmUi.Runtime.mount_iur_screen(home_element, runtime_id: "elm-ui-modal-stack-errors")

    assert {:ok, close_translation} = translation_for_fixture(runtime_state, close_named)

    assert {:error, %ElmUi.ServerRuntime.Error{reason: :unsupported_navigation_context} = error} =
             ElmUi.ServerRuntime.handle_event(runtime_state, close_translation)

    assert error.details.modal == :settings_dialog

    assert {:error, %ElmUi.Transport.Error{reason: :host_route_syntax} = transport_error} =
             ElmUi.Transport.from_native_event(
               family: :navigation,
               intent: :open_settings_modal,
               widget_id: "settings-link",
               screen: runtime_state.screen_id,
               runtime_id: runtime_state.runtime_id,
               source_kind: :canonical,
               boundary_mode: :canonical_boundary,
               target: %{
                 navigation: %{
                   action: :open_modal,
                   modal: :settings_dialog,
                   modal_stack: %{
                     operation: :push,
                     target: :symbolic_modal,
                     stack_effect: :push_modal,
                     stack_id: "runtime-stack"
                   }
                 }
               }
             )

    assert transport_error.details.keys == [:stack_id]
  end

  defp transition_summary(target) do
    %{
      action: get_value(target, :action),
      screen: get_value(target, :screen),
      params: normalize_map(get_value(target, :params, %{}))
    }
  end

  defp modal_summary(target) do
    %{
      modal: get_value(target, :modal),
      params: normalize_map(get_value(target, :params, %{})),
      metadata: normalize_map(get_value(target, :metadata, %{}))
    }
  end

  defp modal_stack_summary(target) do
    %{
      action: get_value(target, :action),
      modal_stack: normalize_map(get_value(target, :modal_stack, %{}))
    }
  end

  defp get_value(map, key, default \\ nil) when is_map(map) do
    Map.get(map, key, Map.get(map, Atom.to_string(key), default))
  end

  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(_other), do: %{}

  defp apply_fixture(runtime_state, fixture) do
    with {:ok, translation} <- translation_for_fixture(runtime_state, fixture),
         {:ok, next_state} <- ElmUi.ServerRuntime.handle_event(runtime_state, translation) do
      {:ok, next_state,
       ElmUi.ServerRuntime.SyncBoundary.acknowledgement_envelope(next_state, translation)}
    end
  end

  defp translation_for_fixture(runtime_state, fixture) do
    with {:ok, translation} <-
           ElmUi.Transport.from_native_event(
             family: :navigation,
             intent: fixture.interaction.intent,
             widget_id: fixture.interaction.source.element_id,
             screen: runtime_state.screen_id,
             runtime_id: runtime_state.runtime_id,
             source_kind: :canonical,
             boundary_mode: :canonical_boundary,
             target: fixture.descriptor.target,
             payload: fixture.signal_data
           ),
         {:ok, decoded} <- ElmUi.Transport.from_boundary_signal(translation.signal) do
      assert decoded.target == fixture.descriptor.target
      {:ok, translation}
    end
  end
end
