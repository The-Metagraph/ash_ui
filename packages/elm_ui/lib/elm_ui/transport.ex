defmodule ElmUi.Transport do
  @moduledoc """
  Transport helpers for native-local and canonical-boundary interactions.
  """

  alias Jido.Signal
  alias ElmUi.Transport.Signals, as: SignalTranslations

  @type boundary :: :local | :boundary

  @spec modes() :: [atom()]
  def modes do
    [:native_local, :canonical_boundary]
  end

  @spec families() :: [atom()]
  def families do
    SignalTranslations.families()
  end

  @spec integration_points() :: [atom()]
  def integration_points do
    [:frontend_bridge, :server_runtime, :canonical_boundary, :signal_translation, :diagnostics]
  end

  @spec modules() :: [module()]
  def modules do
    [
      __MODULE__,
      ElmUi.Signals,
      ElmUi.Transport.Signals,
      ElmUi.Transport.Bridge,
      ElmUi.Transport.Diagnostics,
      ElmUi.Transport.Error
    ]
  end

  @spec local_default_families() :: [atom()]
  def local_default_families do
    SignalTranslations.local_default_families()
  end

  @spec boundary_crossing_families() :: [atom()]
  def boundary_crossing_families do
    SignalTranslations.boundary_crossing_families()
  end

  @spec from_native_event(keyword() | map()) :: {:ok, map()} | {:error, term()}
  def from_native_event(attrs) do
    SignalTranslations.from_native_event(attrs)
  end

  @spec from_boundary_signal(Signal.t() | map()) :: {:ok, map()} | {:error, term()}
  def from_boundary_signal(signal) do
    SignalTranslations.from_boundary_signal(signal)
  end

  @spec to_server_message(Signal.t() | map()) :: {:ok, map()} | {:error, term()}
  def to_server_message(event) do
    SignalTranslations.to_server_message(event)
  end

  @spec cloud_event_envelope(Signal.t()) :: map()
  def cloud_event_envelope(signal) do
    SignalTranslations.cloud_event_envelope(signal)
  end
end
