defmodule LiveUi.Examples.MixedBoundaryTransport do
  @moduledoc """
  Maintained mixed-flow example comparing direct-native and canonical boundary
  translation for the same workflow.
  """

  alias LiveUi.Examples.{CanonicalBoundaryProfile, NativeBoundaryScreen}

  def compare_paths do
    with {:ok, native_local} <-
           LiveUi.Transport.translate_native(NativeBoundaryScreen.local_event_example()),
         {:ok, native_boundary} <-
           LiveUi.Transport.translate_native(NativeBoundaryScreen.boundary_event_example()),
         {:ok, canonical_boundary} <- CanonicalBoundaryProfile.translation(),
         {:ok, envelope} <-
           LiveUi.Transport.Channel.outbound(
             canonical_boundary.signal,
             topic: "live_ui:boundary:profile",
             channel: "profile"
           ),
         {:ok, decoded_signal} <- LiveUi.Transport.Channel.inbound(envelope),
         {:ok, runtime_action} <- LiveUi.Transport.decode_boundary_signal(decoded_signal) do
      {:ok,
       %{
         native_local: native_local,
         native_boundary: native_boundary,
         canonical_boundary: canonical_boundary,
         envelope: envelope,
         runtime_action: runtime_action
       }}
    end
  end

  def hook_flow do
    NativeBoundaryScreen.hook_event_example()
  end

  def metadata do
    %{
      id: :boundary_transport_compare,
      title: "Boundary Transport Comparison",
      families: [:transport, :change, :comparison],
      comparable_to: [:native_boundary, :canonical_boundary],
      summary: "Mixed example comparing local, boundary-native, and canonical signal flows."
    }
  end
end
