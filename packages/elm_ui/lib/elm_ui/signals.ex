defmodule ElmUi.Signals do
  @moduledoc """
  Package-facing canonical signal translation helpers for `elm_ui`.
  """

  alias Jido.Signal
  alias ElmUi.Transport.Signals, as: TransportSignals

  @type family ::
          :click | :change | :submit | :open | :close | :navigation | :selection | :command

  @spec responsibilities() :: [atom()]
  def responsibilities do
    [
      :canonical_signal_translation,
      :cloud_event_envelopes,
      :runtime_action_mapping,
      :native_and_canonical_event_convergence,
      :boundary_validation
    ]
  end

  @spec families() :: [family()]
  defdelegate families, to: TransportSignals

  @spec local_default_families() :: [family()]
  defdelegate local_default_families, to: TransportSignals

  @spec boundary_crossing_families() :: [family()]
  defdelegate boundary_crossing_families, to: TransportSignals

  @spec from_native_event(keyword() | map()) :: {:ok, map()} | {:error, term()}
  defdelegate from_native_event(attrs), to: TransportSignals

  @spec from_boundary_signal(Signal.t() | map()) :: {:ok, map()} | {:error, term()}
  defdelegate from_boundary_signal(signal), to: TransportSignals

  @spec cloud_event_envelope(Signal.t()) :: map()
  defdelegate cloud_event_envelope(signal), to: TransportSignals
end
