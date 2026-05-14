defmodule DesktopUi.CanonicalNavigationTransportIntegrationTest do
  use ExUnit.Case, async: true

  alias Jido.Signal
  alias DesktopUi.Navigation.{Controller, State}
  alias DesktopUi.Navigation.Signal, as: NavigationSignal
  alias DesktopUi.Transport
  alias UnifiedIUR.Interactions.Transport, as: BoundaryTransport

  test "consumes shared modal-transition fixtures without runtime-module identifiers" do
    fixture = BoundaryTransport.boundary_fixture!("modal_transition--settings_dialog")

    assert {:ok, translation} =
             Transport.from_interaction(
               fixture.interaction,
               platform_target: :linux,
               widget_id: "settings-trigger",
               runtime_id: "desktop-ui:workspace",
               screen: "workspace",
               payload: fixture.signal_data
             )

    assert :ok = BoundaryTransport.validate_boundary_fixture(fixture)
    assert translation.target == fixture.descriptor.target
    assert %Signal{} = translation.signal
    assert translation.signal.data == fixture.signal_data
    assert translation.signal.extensions.desktop_ui_target == fixture.descriptor.target
    refute translation.signal.extensions.desktop_ui_target.navigation[:module]
  end

  test "validated shared modal stack fixtures drive desktop modal state without mutating history" do
    first_modal = translate_fixture("modal_transition--settings_dialog")
    second_modal = translate_fixture("modal_stack--open_confirm_dialog")
    close_top = translate_fixture("modal_stack--close_top")

    assert {:ok, controller} =
             Controller.start_link(initial_screen: {:workspace, nil, %{section: :home}})

    try do
      assert {:ok, after_first_modal, {:transition, :modal_opened}} =
               first_modal |> navigation_signal() |> NavigationSignal.execute(controller)

      assert {:ok, after_second_modal, {:transition, :modal_opened}} =
               second_modal |> navigation_signal() |> NavigationSignal.execute(controller)

      assert Enum.map(after_second_modal.modals, &elem(&1, 0)) == [
               :settings_confirm_dialog,
               :settings_dialog
             ]

      assert State.top_modal(after_second_modal) |> elem(0) == :settings_confirm_dialog
      assert after_second_modal.history == after_first_modal.history
      assert after_second_modal.current == :workspace

      assert {:ok, after_top_close, {:transition, :modal_closed}} =
               close_top |> navigation_signal() |> NavigationSignal.execute(controller)

      assert Enum.map(after_top_close.modals, &elem(&1, 0)) == [:settings_dialog]
      assert State.top_modal(after_top_close) |> elem(0) == :settings_dialog
      assert after_top_close.history == after_second_modal.history
      assert after_top_close.current == :workspace
    after
      Controller.stop(controller)
    end
  end

  test "desktop transport rejects host-router and runtime-module navigation leakage" do
    fixture = BoundaryTransport.boundary_fixture!("screen_transition--settings_profile")

    for {key, value} <- [
          url: "https://example.invalid/settings",
          router: :desktop_router,
          module: DesktopUi.Navigation.Controller.MockScreen.Settings
        ] do
      assert {:error,
              %DesktopUi.Transport.Error{reason: :host_route_syntax, details: %{keys: [^key]}}} =
               Transport.from_interaction(
                 fixture.interaction,
                 platform_target: :linux,
                 widget_id: "settings-trigger",
                 runtime_id: "desktop-ui:workspace",
                 screen: "workspace",
                 target: %{
                   navigation:
                     Map.merge(%{action: :navigate_to, screen: :settings}, %{key => value})
                 }
               )
    end
  end

  defp translate_fixture(fixture_id) do
    fixture = BoundaryTransport.boundary_fixture!(fixture_id)
    assert :ok = BoundaryTransport.validate_boundary_fixture(fixture)

    assert {:ok, translation} =
             Transport.from_interaction(
               fixture.interaction,
               platform_target: :linux,
               widget_id: fixture.interaction.source.element_id,
               runtime_id: "desktop-ui:workspace",
               screen: "workspace",
               payload: fixture.signal_data
             )

    assert :ok = Transport.validate_translation(translation)
    assert :ok = Transport.validate_boundary_signal(translation.signal)
    assert translation.target == fixture.descriptor.target

    translation
  end

  defp navigation_signal(translation) do
    navigation = translation.target.navigation

    case navigation.action do
      :open_modal ->
        NavigationSignal.open_modal(navigation.modal, Map.get(navigation, :params, %{}))

      :close_modal ->
        NavigationSignal.close_modal(Map.get(navigation, :modal))
    end
  end
end
