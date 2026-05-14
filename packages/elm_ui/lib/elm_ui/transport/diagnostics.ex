defmodule ElmUi.Transport.Diagnostics do
  @moduledoc """
  Validation helpers that keep native-local event flow distinct from canonical
  boundary translation failures.
  """

  alias Jido.Signal
  alias ElmUi.Transport.Error
  alias UnifiedIUR.Interactions.Transport, as: BoundaryTransport

  @renderer_local_event_prefixes ["phx_", "phx-", "elm:", "browser:", "dom:"]
  @renderer_local_payload_prefixes ["phx_", "elm_", "browser_", "dom_"]
  @native_input_leak_keys [:signal, :cloud_event, :native_event, :server_action, :frontend_update]
  @boundary_envelope_leak_keys [:cloud_event, :native_event, :server_action, :frontend_update]

  @spec validate_native_event(map(), [atom()]) :: :ok | {:error, Error.t()}
  def validate_native_event(attrs, supported_families)
      when is_map(attrs) and is_list(supported_families) do
    family = Map.get(attrs, :family)
    boundary = normalize_boundary(Map.get(attrs, :boundary))
    payload = Map.get(attrs, :payload, %{})

    with :ok <- validate_family(family, supported_families),
         :ok <- validate_package_local_inputs(attrs),
         :ok <- validate_payload_mapping(payload, :native_local),
         :ok <- validate_runtime_event(Map.get(attrs, :runtime_event), :native_local),
         :ok <- validate_payload_keys(payload, :native_local),
         :ok <- validate_navigation_target(Map.get(attrs, :target, %{})),
         :ok <- maybe_validate_boundary_context(attrs, boundary) do
      :ok
    end
  end

  @spec validate_boundary_signal(Signal.t(), [atom()]) :: :ok | {:error, Error.t()}
  def validate_boundary_signal(%Signal{} = signal, supported_families)
      when is_list(supported_families) do
    family = extension(signal, :elm_ui_family)
    runtime_event = extension(signal, :elm_ui_runtime_event)
    screen = extension(signal, :elm_ui_screen)
    runtime_id = extension(signal, :elm_ui_runtime_id)
    payload = signal.data || %{}
    target = extension(signal, :elm_ui_target) || %{}

    with :ok <- validate_family(family, supported_families),
         :ok <- validate_payload_mapping(payload, :canonical_boundary),
         :ok <- validate_runtime_event(runtime_event, :canonical_boundary),
         :ok <- validate_payload_keys(payload, :canonical_boundary),
         :ok <- validate_navigation_target(target),
         :ok <-
           validate_boundary_context(%{screen: screen, runtime_id: runtime_id}, signal.subject) do
      :ok
    else
      {:error, %Error{} = error} -> {:error, error}
      _other -> {:error, Error.invalid_boundary_signal(signal)}
    end
  end

  @spec validate_boundary_envelope(map(), [atom()]) :: :ok | {:error, Error.t()}
  def validate_boundary_envelope(envelope, supported_families)
      when is_map(envelope) and is_list(supported_families) do
    envelope = normalize_map(envelope)
    kind = Map.get(envelope, :kind)
    signal = Map.get(envelope, :signal)

    leaked_keys =
      envelope
      |> Map.keys()
      |> Enum.filter(&(&1 in @boundary_envelope_leak_keys))

    cond do
      kind not in [:canonical_boundary, "canonical_boundary"] ->
        {:error, Error.invalid_boundary_envelope(envelope)}

      leaked_keys != [] ->
        {:error, Error.package_local_transport_detail(leaked_keys)}

      is_nil(signal) ->
        {:error, Error.invalid_boundary_envelope(envelope)}

      true ->
        case build_signal(signal) do
          {:ok, decoded_signal} -> validate_boundary_signal(decoded_signal, supported_families)
          {:error, _reason} -> {:error, Error.invalid_boundary_envelope(envelope)}
        end
    end
  end

  @spec validate_frontend_payload(map()) :: :ok | {:error, Error.t()}
  def validate_frontend_payload(payload) when is_map(payload) do
    nested_payload = payload |> Map.get(:payload, %{}) |> normalize_map()

    leaked_keys =
      payload
      |> leaked_payload_keys()
      |> Kernel.++(leaked_payload_keys(nested_payload))
      |> Enum.uniq()

    if leaked_keys == [] do
      :ok
    else
      {:error, Error.renderer_local_payload(leaked_keys, :frontend_bridge)}
    end
  end

  def validate_frontend_payload(_payload),
    do: {:error, Error.invalid_payload_mapping(:invalid_frontend_payload, :frontend_bridge)}

  defp validate_family(family, supported_families) do
    if family in supported_families do
      :ok
    else
      {:error, Error.invalid_family(family)}
    end
  end

  defp validate_package_local_inputs(attrs) do
    leaked_keys =
      attrs
      |> Map.keys()
      |> Enum.filter(&(&1 in @native_input_leak_keys))

    if leaked_keys == [] do
      :ok
    else
      {:error, Error.package_local_transport_detail(leaked_keys)}
    end
  end

  defp validate_payload_mapping(payload, _surface) when is_map(payload), do: :ok
  defp validate_payload_mapping(nil, _surface), do: :ok

  defp validate_payload_mapping(payload, surface),
    do: {:error, Error.invalid_payload_mapping(payload, surface)}

  defp validate_runtime_event(nil, _surface), do: :ok

  defp validate_runtime_event(event_name, surface) do
    event_name = to_string(event_name)

    if Enum.any?(@renderer_local_event_prefixes, &String.starts_with?(event_name, &1)) do
      {:error, Error.renderer_local_event_name(event_name, surface)}
    else
      :ok
    end
  end

  defp validate_payload_keys(payload, surface) when is_map(payload) do
    leaked_keys = leaked_payload_keys(payload)

    if leaked_keys == [] do
      :ok
    else
      {:error, Error.renderer_local_payload(leaked_keys, surface)}
    end
  end

  defp validate_payload_keys(_payload, _surface), do: :ok

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

  defp maybe_validate_boundary_context(attrs, :boundary) do
    validate_boundary_context(attrs, Map.get(attrs, :widget_id))
  end

  defp maybe_validate_boundary_context(_attrs, _local), do: :ok

  defp validate_boundary_context(attrs, subject) do
    screen = Map.get(attrs, :screen)
    runtime_id = Map.get(attrs, :runtime_id)

    missing =
      []
      |> maybe_missing(:screen, screen)
      |> maybe_missing(
        :runtime_id_or_subject,
        if(is_nil(runtime_id) and is_nil(subject), do: nil, else: :ok)
      )

    if missing == [] do
      :ok
    else
      {:error, Error.missing_boundary_context(missing)}
    end
  end

  defp maybe_missing(fields, field, nil), do: fields ++ [field]
  defp maybe_missing(fields, field, ""), do: fields ++ [field]
  defp maybe_missing(fields, _field, _value), do: fields

  defp leaked_payload_keys(map) when is_map(map) do
    map
    |> Map.keys()
    |> Enum.filter(&renderer_local_key?/1)
  end

  defp leaked_payload_keys(_payload), do: []

  defp renderer_local_key?(key) when is_atom(key), do: renderer_local_key?(Atom.to_string(key))

  defp renderer_local_key?(key) when is_binary(key) do
    Enum.any?(@renderer_local_payload_prefixes, &String.starts_with?(key, &1))
  end

  defp renderer_local_key?(_key), do: false

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

  defp extension(signal, key) do
    Map.get(signal.extensions, key) || Map.get(signal.extensions, Atom.to_string(key))
  end

  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})
  defp normalize_map(_value), do: %{}

  defp normalize_boundary(:boundary), do: :boundary
  defp normalize_boundary("boundary"), do: :boundary
  defp normalize_boundary(_value), do: :local

  defp build_signal(%Signal{} = signal), do: {:ok, signal}
  defp build_signal(attrs) when is_map(attrs) or is_list(attrs), do: Signal.new(attrs)
  defp build_signal(_attrs), do: {:error, :invalid_boundary_signal}
end
