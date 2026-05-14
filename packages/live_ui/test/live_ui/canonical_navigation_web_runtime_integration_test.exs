defmodule LiveUi.CanonicalNavigationWebRuntimeIntegrationTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Interactions.Transport, as: BoundaryTransport
  alias LiveUi.Examples.WebNavigationTransitionComparison
  alias LiveUi.Runtime
  alias LiveUi.Runtime.Error

  test "maintained web navigation example preserves canonical transition meaning across native and canonical runtime paths" do
    navigate_fixture = BoundaryTransport.boundary_fixture!("screen_transition--settings_profile")
    replace_fixture = BoundaryTransport.boundary_fixture!("replace_transition--home")
    modal_fixture = BoundaryTransport.boundary_fixture!("modal_transition--settings_dialog")
    second_modal_fixture = BoundaryTransport.boundary_fixture!("modal_stack--open_confirm_dialog")
    close_top_fixture = BoundaryTransport.boundary_fixture!("modal_stack--close_top")

    assert {:ok, comparison} = WebNavigationTransitionComparison.compare()

    assert transition_summary(comparison.native.transition_targets.navigate) ==
             transition_summary(navigate_fixture.descriptor.target.navigation)

    assert transition_summary(comparison.canonical.transition_targets.navigate) ==
             transition_summary(navigate_fixture.descriptor.target.navigation)

    assert transition_summary(comparison.native.transition_targets.replace) ==
             transition_summary(replace_fixture.descriptor.target.navigation)

    assert transition_summary(comparison.canonical.transition_targets.replace) ==
             transition_summary(replace_fixture.descriptor.target.navigation)

    assert modal_summary(comparison.native.transition_targets.modal) ==
             modal_summary(modal_fixture.descriptor.target.navigation)

    assert modal_summary(comparison.canonical.transition_targets.modal) ==
             modal_summary(modal_fixture.descriptor.target.navigation)

    assert modal_summary(comparison.native.transition_targets.second_modal) ==
             modal_summary(second_modal_fixture.descriptor.target.navigation)

    assert modal_summary(comparison.canonical.transition_targets.second_modal) ==
             modal_summary(second_modal_fixture.descriptor.target.navigation)

    assert modal_stack_summary(comparison.native.transition_targets.close_top) ==
             modal_stack_summary(close_top_fixture.descriptor.target.navigation)

    assert modal_stack_summary(comparison.canonical.transition_targets.close_top) ==
             modal_stack_summary(close_top_fixture.descriptor.target.navigation)

    assert Enum.map(comparison.native.after_second_modal.modal_stack, & &1.modal) == [
             :settings_dialog,
             :settings_confirm_dialog
           ]

    assert comparison.native.after_top_close.current_modal.modal == :settings_dialog
    assert comparison.canonical.after_top_close.current_modal.modal == :settings_dialog
    assert comparison.native.after_second_modal.history == comparison.native.after_modal.history

    assert comparison.native.after_top_close.history ==
             comparison.native.after_second_modal.history

    assert comparison.canonical.after_second_modal.history ==
             comparison.canonical.after_modal.history

    assert comparison.canonical.after_top_close.history ==
             comparison.canonical.after_second_modal.history

    assert comparison.continuity.same_navigation_target?
    assert comparison.continuity.same_modal_identifier?
    assert comparison.continuity.same_second_modal_identifier?
    assert comparison.continuity.top_close_restores_previous_modal?
    assert comparison.continuity.modal_stack_reflected?
    assert comparison.continuity.same_replacement_target?
    assert comparison.continuity.history_meaning_preserved?
    assert comparison.continuity.server_authoritative?
  end

  test "host route integration remains optional and external to the canonical live_ui navigation contract" do
    assert {:ok, comparison} = WebNavigationTransitionComparison.compare()

    refute Map.has_key?(comparison.host_route_fixture.canonical_target, :route)
    refute Map.has_key?(comparison.host_route_fixture.canonical_target, :path)

    assert comparison.host_route_fixture.host_application.live_view_route.path ==
             "/workspace/settings"

    assert comparison.native.after_navigate.host_route.path == "/workspace/settings"
    assert comparison.canonical.after_navigate.host_route.path == "/workspace/settings"
    assert comparison.continuity.host_route_externalized?
  end

  test "invalid symbolic targets and leaked host-route syntax fail with actionable diagnostics" do
    assert {:ok, runtime_state} = Runtime.mount(WebNavigationTransitionComparison.HomeScreen)

    assert {:error, %Error{reason: :unresolved_navigation_target}} =
             Runtime.dispatch_native_event(
               runtime_state,
               "navigation:missing_screen",
               %{},
               family: :navigation,
               intent: :open_missing_screen,
               target: %{navigation: %{action: :navigate_to, screen: :missing}}
             )

    assert {:error, %Error{reason: :host_route_navigation_syntax}} =
             Runtime.dispatch_native_event(
               runtime_state,
               "navigation:route_syntax",
               %{},
               family: :navigation,
               intent: :open_settings_screen,
               target: %{
                 navigation: %{action: :navigate_to, screen: :settings, route: "/settings"}
               }
             )
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
      action: get_value(target, :action),
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
end
