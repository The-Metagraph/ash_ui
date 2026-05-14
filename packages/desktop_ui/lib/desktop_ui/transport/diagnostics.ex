defmodule DesktopUi.Transport.Diagnostics do
  @moduledoc """
  Inspection and validation helpers for the `desktop_ui` transport layer.
  """

  alias Jido.Signal
  alias DesktopUi.Transport.{Error, Normalize}
  alias DesktopUi.Transport.Signal, as: TransportSignal
  alias UnifiedIUR.Interactions.Transport, as: BoundaryTransport

  @payload_leak_keys [
    :backend_payload,
    :keycode,
    :native_handle,
    :platform_payload,
    :scancode,
    :sdl_event
  ]
  @payload_leak_prefixes ["sdl_", "platform_", "native_"]

  @spec mapping_summary() :: map()
  def mapping_summary do
    %{
      families: TransportSignal.families(),
      input_families: Normalize.input_families(),
      local_default_families: TransportSignal.local_default_families(),
      boundary_crossing_families: TransportSignal.boundary_crossing_families(),
      modes: DesktopUi.Transport.modes(),
      platform_targets: DesktopUi.Platform.targets()
    }
  end

  @spec normalized_event_families() :: [atom()]
  def normalized_event_families, do: Normalize.input_families()

  @spec validate_native_event(keyword() | map()) :: :ok | {:error, Error.t()}
  def validate_native_event(attrs) when is_map(attrs) or is_list(attrs) do
    with {:ok, normalized} <- Normalize.normalize(attrs),
         :ok <- validate_payload(Map.get(normalized, :payload, %{}), :native_event),
         :ok <- validate_navigation_target(Map.get(normalized, :target, %{})) do
      if Map.get(normalized, :boundary) == :boundary do
        validate_boundary_context(normalized)
      else
        :ok
      end
    end
  end

  def validate_native_event(value), do: {:error, Error.invalid_native_event(value)}

  @spec validate_translation(map()) :: :ok | {:error, Error.t()}
  def validate_translation(%{} = translation) do
    with :ok <- validate_payload(Map.get(translation, :payload, %{}), :translation_payload),
         :ok <- validate_payload(Map.get(translation, :target, %{}), :translation_target),
         :ok <- validate_navigation_target(Map.get(translation, :target, %{})),
         :ok <- maybe_validate_boundary_signal(translation) do
      if Map.get(translation, :boundary) == :boundary do
        validate_boundary_context(translation)
      else
        :ok
      end
    end
  end

  def validate_translation(value), do: {:error, Error.invalid_native_event(value)}

  @spec validate_boundary_signal(Signal.t() | map()) :: :ok | {:error, Error.t()}
  def validate_boundary_signal(%Signal{} = signal) do
    with {:ok, translation} <- TransportSignal.from_boundary_signal(signal),
         :ok <- validate_translation(translation) do
      :ok
    end
  end

  def validate_boundary_signal(%{signal: %Signal{} = signal}),
    do: validate_boundary_signal(signal)

  def validate_boundary_signal(attrs) when is_map(attrs) or is_list(attrs) do
    case Signal.new(attrs) do
      {:ok, signal} -> validate_boundary_signal(signal)
      {:error, _reason} -> {:error, Error.invalid_boundary_signal(attrs)}
    end
  end

  def validate_boundary_signal(value), do: {:error, Error.invalid_boundary_signal(value)}

  defp maybe_validate_boundary_signal(%{boundary: :boundary, signal: %Signal{} = signal}) do
    validate_signal_payload(signal)
  end

  defp maybe_validate_boundary_signal(%{boundary: :boundary}) do
    {:error, Error.invalid_boundary_signal(:missing_signal)}
  end

  defp maybe_validate_boundary_signal(_translation), do: :ok

  defp validate_signal_payload(%Signal{} = signal) do
    validate_payload(signal.data || %{}, :boundary_signal)
  end

  defp validate_payload(payload, _surface) when is_map(payload) do
    leaked_keys = leaked_keys(payload)

    if leaked_keys == [] do
      :ok
    else
      {:error, Error.leaked_platform_detail(leaked_keys)}
    end
  end

  defp validate_payload(nil, _surface), do: :ok

  defp validate_payload(payload, surface),
    do: {:error, Error.invalid_payload_mapping(payload, surface)}

  defp validate_navigation_target(target) do
    target = normalize_map(target)
    navigation = Map.get(target, :navigation) || Map.get(target, "navigation") || %{}

    leaked_keys = forbidden_navigation_keys(normalize_map(navigation))

    if leaked_keys == [] do
      :ok
    else
      {:error, Error.host_route_syntax(leaked_keys)}
    end
  end

  defp validate_boundary_context(translation) do
    missing =
      []
      |> maybe_missing(:screen, Map.get(translation, :screen))
      |> maybe_missing(
        :runtime_id_or_widget_id,
        if(is_nil(Map.get(translation, :runtime_id)) and is_nil(Map.get(translation, :widget_id)),
          do: nil,
          else: :ok
        )
      )

    if missing == [] do
      :ok
    else
      {:error, Error.missing_boundary_context(missing)}
    end
  end

  defp leaked_keys(map) when is_map(map) do
    map
    |> Map.keys()
    |> Enum.filter(&leaked_key?/1)
  end

  defp leaked_key?(key) when key in @payload_leak_keys, do: true
  defp leaked_key?(key) when is_atom(key), do: leaked_key?(Atom.to_string(key))

  defp leaked_key?(key) when is_binary(key) do
    Enum.any?(@payload_leak_prefixes, &String.starts_with?(key, &1))
  end

  defp leaked_key?(_key), do: false

  defp forbidden_navigation_keys(navigation) do
    modal_stack =
      navigation
      |> Map.get(:modal_stack, Map.get(navigation, "modal_stack", %{}))
      |> normalize_map()

    (Map.keys(navigation) ++ Map.keys(modal_stack))
    |> Enum.filter(&forbidden_navigation_key?/1)
    |> Enum.uniq()
  end

  defp forbidden_navigation_key?(key) when is_atom(key),
    do: key in BoundaryTransport.forbidden_navigation_keys()

  defp forbidden_navigation_key?(key) when is_binary(key) do
    key in Enum.map(BoundaryTransport.forbidden_navigation_keys(), &Atom.to_string/1)
  end

  defp forbidden_navigation_key?(_key), do: false

  defp maybe_missing(fields, field, nil), do: fields ++ [field]
  defp maybe_missing(fields, field, ""), do: fields ++ [field]
  defp maybe_missing(fields, _field, _value), do: fields

  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})
  defp normalize_map(_value), do: %{}
end
