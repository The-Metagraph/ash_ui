defmodule ElmUi.Transport.Bridge do
  @moduledoc """
  Frontend/server bridge envelopes for `elm_ui`.
  """

  alias Jido.Signal
  alias ElmUi.FrontendRuntime.Model
  alias ElmUi.Transport.Diagnostics

  @spec event_message(Model.t(), map()) :: map()
  def event_message(%Model{} = model, translation) when is_map(translation) do
    ElmUi.FrontendRuntime.Message.new(
      :event,
      payload_for(translation),
      %{
        runtime_id: model.runtime_id,
        screen_id: model.screen_id,
        source_kind: model.source_kind,
        boundary: translation.boundary
      }
    )
  end

  @spec hydration_message(map()) :: map()
  def hydration_message(payload) when is_map(payload) do
    ElmUi.FrontendRuntime.Message.new(:hydrate, payload)
  end

  @spec boundary_envelope(Signal.t() | map(), keyword() | map()) ::
          {:ok, map()} | {:error, term()}
  def boundary_envelope(signal_or_translation, opts \\ [])

  def boundary_envelope(%Signal{} = signal, opts) do
    opts = normalize_map(opts)

    {:ok,
     %{
       kind: :canonical_boundary,
       transport: fetch(opts, :transport, :phoenix_channel),
       topic: fetch(opts, :topic, "elm_ui:boundary"),
       event: fetch(opts, :event, "canonical_boundary"),
       runtime_id: fetch(opts, :runtime_id),
       signal: signal_map(signal)
     }}
  end

  def boundary_envelope(%{signal: %Signal{} = signal} = translation, opts)
      when is_map(translation) do
    opts =
      opts
      |> normalize_map()
      |> Map.put_new(:runtime_id, Map.get(translation, :runtime_id))

    boundary_envelope(signal, opts)
  end

  def boundary_envelope(_signal_or_translation, _opts), do: {:error, :invalid_boundary_envelope}

  @spec inbound_boundary_envelope(map()) :: {:ok, Signal.t()} | {:error, term()}
  def inbound_boundary_envelope(envelope) when is_map(envelope) do
    envelope = normalize_map(envelope)

    with :ok <- Diagnostics.validate_boundary_envelope(envelope, ElmUi.Transport.families()),
         {:ok, signal} <- build_signal(fetch(envelope, :signal)) do
      {:ok, signal}
    else
      {:error, _reason} = error -> error
    end
  end

  def inbound_boundary_envelope(envelope),
    do: {:error, ElmUi.Transport.Error.invalid_boundary_envelope(envelope)}

  defp payload_for(%{boundary: :boundary, signal: signal}) do
    {:ok, message} = ElmUi.Transport.to_server_message(signal)
    message
  end

  defp payload_for(translation) do
    {:ok, message} = ElmUi.Transport.to_server_message(translation)
    message
  end

  defp build_signal(%Signal{} = signal), do: {:ok, signal}

  defp build_signal(attrs) when is_map(attrs) or is_list(attrs) do
    Signal.new(attrs)
  end

  defp build_signal(_attrs),
    do: {:error, ElmUi.Transport.Error.invalid_boundary_signal(:invalid_boundary_signal)}

  defp signal_map(%Signal{} = signal) do
    signal
    |> Map.from_struct()
    |> Map.delete(:__meta__)
  end

  defp normalize_map(attrs) when is_list(attrs), do: Enum.into(attrs, %{})
  defp normalize_map(attrs) when is_map(attrs), do: Map.new(attrs)
  defp normalize_map(_attrs), do: %{}

  defp fetch(source, key, default) do
    Map.get(source, key, Map.get(source, Atom.to_string(key), default))
  end

  defp fetch(source, key) do
    Map.get(source, key) || Map.get(source, Atom.to_string(key))
  end
end
