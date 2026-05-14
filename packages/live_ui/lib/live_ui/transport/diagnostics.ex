defmodule LiveUi.Transport.Diagnostics do
  @moduledoc """
  Validation helpers that keep native event handling distinct from canonical
  boundary translation failures.
  """

  alias Jido.Signal
  alias LiveUi.Transport.Error
  alias UnifiedIUR.Interaction
  alias UnifiedIUR.Interactions.Transport, as: BoundaryTransport

  @families LiveUi.Signals.families()
  @renderer_local_event_prefixes ["phx_", "phx-", "lv:", "hook:"]
  @renderer_local_payload_prefixes ["phx_", "lv_", "renderer_", "hook_"]

  @spec validate_native_boundary(map()) :: :ok | {:error, Error.t()}
  def validate_native_boundary(attrs) when is_map(attrs) do
    with :ok <- validate_family(Map.get(attrs, :family)),
         :ok <- validate_boundary_context(attrs, [:screen]),
         :ok <- validate_element_context(attrs),
         :ok <- validate_runtime_event(Map.get(attrs, :runtime_event) || Map.get(attrs, :event)),
         :ok <- validate_payload(Map.get(attrs, :payload, %{})),
         :ok <- validate_navigation_target(Map.get(attrs, :target, %{})) do
      :ok
    end
  end

  @spec validate_canonical_boundary(Interaction.t(), map()) :: :ok | {:error, Error.t()}
  def validate_canonical_boundary(%Interaction{} = interaction, attrs) when is_map(attrs) do
    with :ok <- validate_family(interaction.family),
         :ok <- validate_boundary_context(attrs, [:screen]),
         :ok <- validate_runtime_event(Map.get(attrs, :runtime_event)),
         :ok <- validate_payload(interaction.payload),
         :ok <- validate_payload(Map.get(attrs, :payload, %{})),
         :ok <- validate_navigation_target(interaction.target),
         :ok <- validate_navigation_target(Map.get(attrs, :target, %{})) do
      :ok
    end
  end

  @spec validate_boundary_signal(Signal.t()) :: :ok | {:error, Error.t()}
  def validate_boundary_signal(%Signal{} = signal) do
    family = signal.extensions["live_ui_family"] || signal.extensions[:live_ui_family]

    runtime_event =
      signal.extensions["live_ui_runtime_event"] || signal.extensions[:live_ui_runtime_event]

    source_context =
      signal.extensions["live_ui_source_context"] || signal.extensions[:live_ui_source_context] ||
        %{}

    target = signal.extensions["live_ui_target"] || signal.extensions[:live_ui_target] || %{}

    cond do
      is_nil(family) or is_nil(runtime_event) ->
        {:error, Error.invalid_boundary_signal(signal)}

      true ->
        with :ok <- validate_family(family),
             :ok <- validate_runtime_event(runtime_event),
             :ok <- validate_signal_context(signal, normalize_map(source_context)),
             :ok <- validate_payload(signal.data || %{}),
             :ok <- validate_navigation_target(target) do
          :ok
        end
    end
  end

  @spec validate_hook_payload(atom(), map()) :: :ok | {:error, Error.t()}
  def validate_hook_payload(hook, payload) when is_atom(hook) and is_map(payload) do
    with :ok <- validate_payload(payload) do
      if LiveUi.Runtime.BrowserBridge.supported?(hook) do
        :ok
      else
        {:error, Error.unsupported_hook(hook)}
      end
    end
  end

  defp validate_family(family) when family in @families, do: :ok
  defp validate_family(family), do: {:error, Error.invalid_family(family)}

  defp validate_boundary_context(attrs, fields) do
    missing =
      Enum.filter(fields, fn field ->
        attrs
        |> Map.get(field)
        |> case do
          nil -> true
          "" -> true
          _ -> false
        end
      end)

    if missing == [], do: :ok, else: {:error, Error.missing_boundary_context(missing)}
  end

  defp validate_element_context(attrs) do
    if Map.get(attrs, :element_id) || get_in(attrs, [:source_context, :element_id]) do
      :ok
    else
      {:error, Error.missing_boundary_context([:element_id])}
    end
  end

  defp validate_signal_context(signal, attrs) do
    case validate_boundary_context(attrs, [:screen]) do
      :ok -> :ok
      {:error, _error} -> {:error, Error.invalid_boundary_signal(signal)}
    end
  end

  defp validate_runtime_event(nil), do: :ok

  defp validate_runtime_event(event_name) do
    event_name = to_string(event_name)

    if Enum.any?(@renderer_local_event_prefixes, &String.starts_with?(event_name, &1)) do
      {:error, Error.renderer_local_event_name(event_name)}
    else
      :ok
    end
  end

  defp validate_payload(payload) when is_map(payload) do
    leaked_keys =
      payload
      |> Map.keys()
      |> Enum.filter(&renderer_local_key?/1)

    if leaked_keys == [], do: :ok, else: {:error, Error.renderer_local_payload(leaked_keys)}
  end

  defp validate_payload(_payload), do: :ok

  defp validate_navigation_target(target) do
    target = normalize_map(target)
    navigation = Map.get(target, :navigation) || Map.get(target, "navigation") || %{}

    leaked_keys = forbidden_navigation_keys(navigation)

    if leaked_keys == [] do
      :ok
    else
      {:error, Error.host_route_syntax(leaked_keys)}
    end
  end

  defp renderer_local_key?(key) when is_atom(key), do: renderer_local_key?(Atom.to_string(key))

  defp renderer_local_key?(key) when is_binary(key) do
    Enum.any?(@renderer_local_payload_prefixes, &String.starts_with?(key, &1))
  end

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

  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(_other), do: %{}
end
