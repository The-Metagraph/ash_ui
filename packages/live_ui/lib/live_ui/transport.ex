defmodule LiveUi.Transport do
  @moduledoc """
  Package-facing entrypoint for boundary transport translation helpers.
  """

  alias Jido.Signal
  alias UnifiedIUR.Interaction

  @type mode :: :native_local | :canonical_boundary
  @type event_source :: :native | :canonical
  @type boundary_kind :: :local | :boundary
  @type translation :: %{
          family: atom(),
          intent: atom() | String.t() | nil,
          source: event_source(),
          boundary: boundary_kind(),
          runtime_event: String.t(),
          signal: Signal.t() | nil
        }

  @spec modes() :: [mode()]
  def modes do
    [:native_local, :canonical_boundary]
  end

  @spec supported_families() :: [UnifiedIUR.Interaction.family()]
  def supported_families do
    LiveUi.Signals.families()
  end

  @spec integration_points() :: [atom()]
  def integration_points do
    [
      :native_liveview_events,
      :browser_hooks,
      :canonical_signal_translation,
      :canonical_boundary_translation,
      :channel_boundary_delivery
    ]
  end

  @spec translate_native(keyword() | map()) :: {:ok, translation()} | {:error, term()}
  def translate_native(attrs) do
    LiveUi.Signals.from_native(attrs)
  end

  @spec translate_canonical(Interaction.t() | keyword() | map(), keyword() | map()) ::
          {:ok, translation()} | {:error, term()}
  def translate_canonical(interaction, attrs \\ []) do
    LiveUi.Signals.from_interaction(interaction, attrs)
  end

  @spec decode_boundary_signal(Signal.t() | map()) :: {:ok, map()} | {:error, term()}
  def decode_boundary_signal(signal) do
    LiveUi.Signals.to_runtime_action(signal)
  end

  @spec local_event?(keyword() | map()) :: boolean()
  def local_event?(attrs) do
    attrs
    |> normalize_map()
    |> Map.get(:boundary, :local) == :local
  end

  @spec boundary_event?(keyword() | map()) :: boolean()
  def boundary_event?(attrs) do
    attrs
    |> normalize_map()
    |> Map.get(:boundary, :local) == :boundary
  end

  @spec namespace() :: module()
  def namespace, do: __MODULE__

  defp normalize_map(attrs) when is_list(attrs), do: Enum.into(attrs, %{})
  defp normalize_map(attrs) when is_map(attrs), do: Map.new(attrs)
end
