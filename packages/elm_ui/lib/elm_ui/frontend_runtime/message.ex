defmodule ElmUi.FrontendRuntime.Message do
  @moduledoc """
  Browser bridge message envelopes for hydration, events, and acknowledgements.
  """

  @type kind :: :hydrate | :event | :ack
  @type t :: %{
          kind: kind(),
          payload: map(),
          metadata: map()
        }

  @kinds [:hydrate, :event, :ack]

  @spec kinds() :: [kind()]
  def kinds, do: @kinds

  @spec new(kind(), map(), keyword() | map()) :: map()
  def new(kind, payload, metadata \\ %{}) when kind in @kinds and is_map(payload) do
    %{
      kind: kind,
      payload: payload,
      metadata: normalize_map(metadata)
    }
  end

  @spec from_payload(map()) :: {:ok, t()} | {:error, term()}
  def from_payload(payload) when is_map(payload) do
    kind = fetch(payload, :kind)
    inner_payload = fetch(payload, :payload, %{})
    metadata = normalize_map(fetch(payload, :metadata, %{}))

    cond do
      kind in @kinds and is_map(inner_payload) ->
        {:ok, %{kind: kind, payload: inner_payload, metadata: metadata}}

      kind in Enum.map(@kinds, &Atom.to_string/1) and is_map(inner_payload) ->
        {:ok, %{kind: String.to_atom(kind), payload: inner_payload, metadata: metadata}}

      true ->
        {:error, :invalid_message_payload}
    end
  end

  def from_payload(_payload), do: {:error, :invalid_message_payload}

  defp fetch(map, key, default \\ nil) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key)) || default
  end

  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})
  defp normalize_map(_other), do: %{}
end
