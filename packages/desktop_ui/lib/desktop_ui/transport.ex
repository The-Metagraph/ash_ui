defmodule DesktopUi.Transport do
  @moduledoc """
  Transport helpers for desktop-local and canonical-boundary events.
  """

  alias Jido.Signal
  alias DesktopUi.Transport.{Diagnostics, Normalize}
  alias DesktopUi.Transport.Signal, as: TransportSignal
  alias UnifiedIUR.Interaction

  @spec modes() :: [atom()]
  def modes, do: [:native_local, :canonical_boundary]

  @spec families() :: [atom()]
  def families, do: TransportSignal.families()

  @spec local_default_families() :: [atom()]
  def local_default_families, do: TransportSignal.local_default_families()

  @spec boundary_crossing_families() :: [atom()]
  def boundary_crossing_families, do: TransportSignal.boundary_crossing_families()

  @spec input_families() :: [atom()]
  def input_families, do: Normalize.input_families()

  @spec integration_points() :: [atom()]
  def integration_points do
    [
      :runtime,
      :platform_input_normalization,
      :canonical_signal_translation,
      :transport_diagnostics
    ]
  end

  @spec modules() :: [module()]
  def modules do
    [__MODULE__, Normalize, TransportSignal, Diagnostics, DesktopUi.Transport.Error]
  end

  @spec normalize_native_event(keyword() | map()) ::
          {:ok, map()} | {:error, DesktopUi.Transport.Error.t()}
  def normalize_native_event(attrs), do: Normalize.normalize(attrs)

  @spec from_native_event(keyword() | map()) :: {:ok, map()} | {:error, term()}
  def from_native_event(attrs) do
    with {:ok, normalized} <- Normalize.normalize(attrs) do
      TransportSignal.from_normalized_event(normalized)
    end
  end

  @spec from_interaction(Interaction.t() | keyword() | map(), keyword() | map()) ::
          {:ok, map()} | {:error, term()}
  def from_interaction(interaction, attrs \\ []) do
    TransportSignal.from_interaction(interaction, attrs)
  end

  @spec from_boundary_signal(Signal.t() | map()) :: {:ok, map()} | {:error, term()}
  def from_boundary_signal(signal), do: TransportSignal.from_boundary_signal(signal)

  @spec cloud_event_envelope(Signal.t()) :: map()
  def cloud_event_envelope(signal), do: TransportSignal.cloud_event_envelope(signal)

  @spec diagnostics() :: map()
  def diagnostics do
    %{
      mapping_summary: Diagnostics.mapping_summary(),
      normalized_event_families: Diagnostics.normalized_event_families()
    }
  end

  @spec validate_native_event(keyword() | map()) :: :ok | {:error, DesktopUi.Transport.Error.t()}
  def validate_native_event(attrs), do: Diagnostics.validate_native_event(attrs)

  @spec validate_translation(map()) :: :ok | {:error, DesktopUi.Transport.Error.t()}
  def validate_translation(translation), do: Diagnostics.validate_translation(translation)

  @spec validate_boundary_signal(Signal.t() | map()) ::
          :ok | {:error, DesktopUi.Transport.Error.t()}
  def validate_boundary_signal(signal), do: Diagnostics.validate_boundary_signal(signal)

  @spec validation_state() :: atom()
  def validation_state, do: :transport_diagnostics_ready
end
