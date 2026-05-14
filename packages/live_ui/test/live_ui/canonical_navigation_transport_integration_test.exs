defmodule LiveUi.CanonicalNavigationTransportIntegrationTest do
  use ExUnit.Case, async: true

  alias Jido.Signal
  alias UnifiedIUR.Interactions.Transport, as: BoundaryTransport

  test "consumes shared screen-transition fixtures without browser-only route fields" do
    fixture = BoundaryTransport.boundary_fixture!("screen_transition--settings_profile")

    assert {:ok, translation} =
             LiveUi.Signals.from_interaction(
               fixture.interaction,
               screen: :workspace,
               mode: :screen,
               boundary: :boundary,
               payload: fixture.signal_data
             )

    assert :ok = BoundaryTransport.validate_boundary_fixture(fixture)
    assert translation.target == fixture.descriptor.target
    assert %Signal{} = translation.signal
    assert translation.signal.data == fixture.signal_data
    assert translation.signal.extensions.live_ui_target == fixture.descriptor.target
    refute translation.signal.extensions.live_ui_target.navigation[:route]
  end

  test "validates shared modal stack fixtures before live_ui boundary transport consumes them" do
    fixtures =
      [
        "modal_transition--settings_dialog",
        "modal_stack--open_confirm_dialog",
        "modal_stack--close_top",
        "modal_stack--close_named_settings"
      ]
      |> Enum.map(&BoundaryTransport.boundary_fixture!/1)

    for fixture <- fixtures do
      assert :ok = BoundaryTransport.validate_boundary_fixture(fixture)

      assert {:ok, translation} =
               LiveUi.Transport.translate_canonical(
                 fixture.interaction,
                 screen: :workspace,
                 mode: :screen,
                 boundary: :boundary,
                 payload: fixture.signal_data
               )

      assert :ok = LiveUi.Transport.Diagnostics.validate_boundary_signal(translation.signal)
      assert {:ok, runtime_action} = LiveUi.Transport.decode_boundary_signal(translation.signal)

      assert translation.target == fixture.descriptor.target
      assert runtime_action.target == fixture.descriptor.target
      assert translation.signal.data == fixture.signal_data
      assert translation.signal.extensions.live_ui_target == fixture.descriptor.target

      assert translation.signal.extensions.live_ui_target.navigation.modal_stack ==
               fixture.descriptor.target.navigation.modal_stack
    end
  end
end
