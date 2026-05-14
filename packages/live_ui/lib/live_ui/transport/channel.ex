defmodule LiveUi.Transport.Channel do
  @moduledoc """
  Canonical channel-envelope helpers for boundary signal exchange.
  """

  alias Jido.Signal

  @spec outbound(Signal.t() | map(), keyword() | map()) :: {:ok, map()} | {:error, term()}
  def outbound(signal_or_attrs, opts \\ [])

  @spec outbound(Signal.t() | map(), keyword() | map()) :: {:ok, map()} | {:error, term()}
  def outbound(%Signal{} = signal, opts) do
    opts = normalize_map(opts)

    {:ok,
     %{
       kind: :canonical_boundary,
       topic: fetch(opts, :topic, "live_ui:boundary"),
       channel: fetch(opts, :channel, "live_ui"),
       signal: signal_map(signal)
     }}
  end

  def outbound(attrs, opts) when is_map(attrs) or is_list(attrs) do
    case Signal.new(attrs) do
      {:ok, signal} -> outbound(signal, opts)
      {:error, reason} -> {:error, reason}
    end
  end

  @spec inbound(map()) :: {:ok, Signal.t()} | {:error, term()}
  def inbound(%{kind: :canonical_boundary, signal: signal_attrs}), do: build_signal(signal_attrs)

  def inbound(%{"kind" => "canonical_boundary", "signal" => signal_attrs}),
    do: build_signal(signal_attrs)

  def inbound(%{"kind" => :canonical_boundary, "signal" => signal_attrs}),
    do: build_signal(signal_attrs)

  def inbound(%{signal: signal_attrs}), do: build_signal(signal_attrs)
  def inbound(envelope), do: {:error, LiveUi.Transport.Error.invalid_channel_envelope(envelope)}

  defp build_signal(%Signal{} = signal) do
    case LiveUi.Transport.Diagnostics.validate_boundary_signal(signal) do
      :ok -> {:ok, signal}
      {:error, error} -> {:error, error}
    end
  end

  defp build_signal(attrs) when is_map(attrs) or is_list(attrs) do
    with {:ok, signal} <- Signal.new(attrs),
         :ok <- LiveUi.Transport.Diagnostics.validate_boundary_signal(signal) do
      {:ok, signal}
    end
  end

  defp signal_map(%Signal{} = signal) do
    signal
    |> Map.from_struct()
    |> Map.delete(:__meta__)
  end

  defp normalize_map(attrs) when is_list(attrs), do: Enum.into(attrs, %{})
  defp normalize_map(attrs) when is_map(attrs), do: Map.new(attrs)

  defp fetch(source, key, default) do
    Map.get(source, key, Map.get(source, Atom.to_string(key), default))
  end
end
