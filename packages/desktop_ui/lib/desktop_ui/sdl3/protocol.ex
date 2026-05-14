defmodule DesktopUi.Sdl3.Protocol do
  @moduledoc """
  Framed Elixir-to-native protocol for the SDL3 host boundary.
  """

  alias DesktopUi.Runtime.Error

  @magic "DUIH"
  @version 1
  @message_families [:boot, :window, :frame, :events, :text, :image, :diagnostics, :shutdown]
  @message_kinds [:request, :ack, :update, :batch, :ready, :report, :error]

  @spec contract() :: map()
  def contract do
    %{
      framing: :desktop_ui_sdl3_frame,
      magic: @magic,
      version: @version,
      message_families: @message_families,
      message_kinds: @message_kinds,
      shape: [:id, :family, :kind, :correlation_id, :protocol, :payload, :diagnostics, :meta],
      resource_channels: [:text, :image],
      control_channels: [:boot, :window, :frame, :events, :diagnostics, :shutdown]
    }
  end

  @spec validation_state() :: atom()
  def validation_state, do: :framed_protocol_ready

  @spec supported_versions() :: [non_neg_integer()]
  def supported_versions, do: [@version]

  @spec new_message(atom(), atom(), map() | keyword(), keyword()) :: map()
  def new_message(family, kind, payload \\ %{}, opts \\ []) when is_atom(family) and is_atom(kind) do
    payload = normalize_value(payload)

    %{
      id: Keyword.get(opts, :id, "dui-msg-#{System.unique_integer([:positive])}"),
      family: family,
      kind: kind,
      correlation_id: Keyword.get(opts, :correlation_id),
      protocol: %{
        name: :desktop_ui_sdl3_host,
        version: Keyword.get(opts, :version, @version)
      },
      payload: payload,
      diagnostics: normalize_value(Keyword.get(opts, :diagnostics, %{})),
      meta:
        %{}
        |> maybe_put(:channel, Keyword.get(opts, :channel))
        |> maybe_put(:runtime_id, Keyword.get(opts, :runtime_id))
        |> maybe_put(:screen_id, Keyword.get(opts, :screen_id))
        |> maybe_put(:window_id, Keyword.get(opts, :window_id))
        |> maybe_put(:resource_kind, Keyword.get(opts, :resource_kind))
    }
  end

  @spec error_envelope(atom(), map() | keyword(), keyword()) :: map()
  def error_envelope(reason, details \\ %{}, opts \\ []) when is_atom(reason) do
    new_message(
      :diagnostics,
      :error,
      %{
        reason: reason,
        details: normalize_value(details)
      },
      opts
    )
  end

  @spec frame(map() | keyword()) :: {:ok, binary()} | {:error, Error.t()}
  def frame(message) when is_map(message) or is_list(message) do
    message = normalize_message(message)

    with :ok <- validate_message(message) do
      payload =
        message
        |> json_safe()
        |> JSON.encode!()
        |> IO.iodata_to_binary()

      {:ok,
       <<@magic::binary, @version::unsigned-16, byte_size(payload)::unsigned-32, payload::binary>>}
    else
      {:error, _} = error -> error
    end
  end

  @spec next_message(binary()) :: {:ok, map(), binary()} | :more | {:error, Error.t()}
  def next_message(binary) when is_binary(binary) do
    header_size = byte_size(@magic) + 2 + 4

    cond do
      byte_size(binary) < header_size ->
        :more

      binary_part(binary, 0, byte_size(@magic)) != @magic ->
        {:error, Error.new(:invalid_sdl3_protocol_magic, %{binary: Base.encode16(binary)}, :sdl3_protocol)}

      true ->
        <<_magic::binary-size(4), version::unsigned-16, payload_size::unsigned-32, rest::binary>> =
          binary

        cond do
          version not in supported_versions() ->
            {:error, Error.new(:unsupported_sdl3_protocol_version, %{version: version}, :sdl3_protocol)}

          byte_size(rest) < payload_size ->
            :more

          true ->
            <<payload::binary-size(payload_size), remainder::binary>> = rest

            case JSON.decode(payload) do
              {:ok, decoded} when is_map(decoded) ->
                message = normalize_message(decoded)

                with :ok <- validate_message(message) do
                  {:ok, message, remainder}
                end

              {:ok, decoded} ->
                {:error,
                 Error.new(
                   :invalid_sdl3_protocol_payload,
                   %{payload: decoded},
                   :sdl3_protocol
                 )}

              {:error, reason} ->
                {:error,
                 Error.new(
                   :invalid_sdl3_protocol_payload,
                   %{payload: payload, reason: inspect(reason)},
                   :sdl3_protocol
                 )}
            end
        end
    end
  end

  def next_message(value) do
    {:error, Error.new(:invalid_sdl3_protocol_frame, %{frame: value}, :sdl3_protocol)}
  end

  defp validate_message(message) do
    cond do
      Map.get(message, :family) not in @message_families ->
        {:error,
         Error.new(
           :unsupported_sdl3_message_family,
           %{family: Map.get(message, :family)},
           :sdl3_protocol
         )}

      Map.get(message, :kind) not in @message_kinds ->
        {:error,
         Error.new(
           :unsupported_sdl3_message_kind,
           %{kind: Map.get(message, :kind)},
           :sdl3_protocol
         )}

      not is_binary(Map.get(message, :id, "")) ->
        {:error, Error.new(:invalid_sdl3_message_id, %{message: message}, :sdl3_protocol)}

      get_in(message, [:protocol, :version]) not in supported_versions() ->
        {:error,
         Error.new(
           :unsupported_sdl3_protocol_version,
           %{version: get_in(message, [:protocol, :version])},
           :sdl3_protocol
         )}

      true ->
        :ok
    end
  end

  defp normalize_message(message) when is_map(message) do
    message =
      Map.new(message, fn {key, value} ->
        {normalize_key(key), normalize_value(value)}
      end)

    %{
      id: Map.get(message, :id, "dui-msg-#{System.unique_integer([:positive])}"),
      family: normalize_atom(Map.get(message, :family)),
      kind: normalize_atom(Map.get(message, :kind)),
      correlation_id: Map.get(message, :correlation_id),
      protocol:
        message
        |> Map.get(:protocol, %{})
        |> normalize_value()
        |> then(fn protocol ->
          %{
            name: normalize_atom(Map.get(protocol, :name, :desktop_ui_sdl3_host)),
            version: Map.get(protocol, :version, @version)
          }
        end),
      payload: Map.get(message, :payload, %{}),
      diagnostics: Map.get(message, :diagnostics, %{}),
      meta:
        message
        |> Map.get(:meta, %{})
        |> normalize_value()
        |> then(fn meta ->
          meta
          |> maybe_put(:channel, normalize_atom(Map.get(meta, :channel)))
          |> maybe_put(:resource_kind, normalize_atom(Map.get(meta, :resource_kind)))
        end)
    }
  end

  defp normalize_message(message) when is_list(message), do: message |> Enum.into(%{}) |> normalize_message()

  defp normalize_key(key) when key in [:id, "id"], do: :id
  defp normalize_key(key) when key in [:family, "family"], do: :family
  defp normalize_key(key) when key in [:kind, "kind"], do: :kind
  defp normalize_key(key) when key in [:correlation_id, "correlation_id"], do: :correlation_id
  defp normalize_key(key) when key in [:protocol, "protocol"], do: :protocol
  defp normalize_key(key) when key in [:payload, "payload"], do: :payload
  defp normalize_key(key) when key in [:diagnostics, "diagnostics"], do: :diagnostics
  defp normalize_key(key) when key in [:meta, "meta"], do: :meta
  defp normalize_key(key) when key in [:name, "name"], do: :name
  defp normalize_key(key) when key in [:version, "version"], do: :version
  defp normalize_key(key) when key in [:channel, "channel"], do: :channel
  defp normalize_key(key) when key in [:runtime_id, "runtime_id"], do: :runtime_id
  defp normalize_key(key) when key in [:screen_id, "screen_id"], do: :screen_id
  defp normalize_key(key) when key in [:window_id, "window_id"], do: :window_id
  defp normalize_key(key) when key in [:resource_kind, "resource_kind"], do: :resource_kind
  defp normalize_key(key) when key in [:reason, "reason"], do: :reason
  defp normalize_key(key) when key in [:details, "details"], do: :details
  defp normalize_key(key) when is_atom(key), do: key
  defp normalize_key(key) when is_binary(key), do: String.to_atom(key)
  defp normalize_key(key), do: key

  defp normalize_value(%_{} = value) do
    value
    |> Map.from_struct()
    |> normalize_value()
  end

  defp normalize_value(value) when is_tuple(value) do
    value
    |> Tuple.to_list()
    |> Enum.map(&normalize_value/1)
  end

  defp normalize_value(value) when is_map(value) do
    Map.new(value, fn {key, nested} ->
      {normalize_key(key), normalize_value(nested)}
    end)
  end

  defp normalize_value(value) when is_list(value), do: Enum.map(value, &normalize_value/1)
  defp normalize_value(value) when is_binary(value), do: maybe_normalize_existing_atom(value)
  defp normalize_value(value), do: value

  defp normalize_atom(value) when is_atom(value), do: value

  defp normalize_atom(value) when is_binary(value) do
    try do
      String.to_existing_atom(value)
    rescue
      ArgumentError -> String.to_atom(value)
    end
  end

  defp normalize_atom(value), do: value

  defp json_safe(%_{} = value) do
    value
    |> Map.from_struct()
    |> json_safe()
  end

  defp json_safe(value) when is_tuple(value) do
    value
    |> Tuple.to_list()
    |> Enum.map(&json_safe/1)
  end

  defp json_safe(value) when is_map(value) do
    Map.new(value, fn {key, nested} ->
      {json_key(key), json_safe(nested)}
    end)
  end

  defp json_safe(value) when is_list(value), do: Enum.map(value, &json_safe/1)
  defp json_safe(value), do: value

  defp json_key(key) when is_atom(key), do: Atom.to_string(key)
  defp json_key(key), do: key

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, []), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_normalize_existing_atom(value) do
    if String.match?(value, ~r/^[a-z][a-z0-9_]*$/) do
      try do
        String.to_existing_atom(value)
      rescue
        ArgumentError -> value
      end
    else
      value
    end
  end
end
