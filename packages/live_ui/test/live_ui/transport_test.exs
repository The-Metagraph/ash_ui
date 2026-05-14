defmodule LiveUi.TransportTest do
  use ExUnit.Case, async: true

  alias Jido.Signal
  alias UnifiedIUR.Interaction

  test "transport exposes canonical modes, families, and integration points" do
    assert LiveUi.Transport.modes() == [:native_local, :canonical_boundary]
    assert :submit in LiveUi.Transport.supported_families()
    assert :canonical_signal_translation in LiveUi.Transport.integration_points()
    assert :channel_boundary_delivery in LiveUi.Transport.integration_points()
  end

  test "transport distinguishes local and boundary events" do
    assert LiveUi.Transport.local_event?(family: :click, boundary: :local)
    assert LiveUi.Transport.boundary_event?(family: :submit, boundary: :boundary)
  end

  test "transport translates native and canonical events through the same signal surface" do
    assert {:ok, native} =
             LiveUi.Transport.translate_native(
               family: :command,
               intent: :open_palette,
               screen: :workspace,
               element_id: :workspace_commands,
               boundary: :boundary,
               payload: %{source: :keyboard}
             )

    assert %Signal{} = native.signal

    interaction =
      Interaction.command(
        intent: :open_palette,
        element_id: :workspace_commands,
        command: :workspace_palette
      )

    assert {:ok, canonical} =
             LiveUi.Transport.translate_canonical(
               interaction,
               screen: :workspace,
               boundary: :boundary,
               payload: %{source: :keyboard}
             )

    assert %Signal{} = canonical.signal

    assert {:ok, decoded} = LiveUi.Transport.decode_boundary_signal(canonical.signal)
    assert decoded.family == :command
    assert decoded.intent == :open_palette
  end
end
