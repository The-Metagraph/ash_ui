defmodule DesktopUi.Transport.Signal do
  @moduledoc """
  Canonical `Jido.Signal` translation for `desktop_ui`.
  """

  alias Jido.Signal
  alias DesktopUi.Transport.Error
  alias UnifiedIUR.Interaction
  alias UnifiedIUR.Interactions.Transport, as: BoundaryTransport

  @families Interaction.families()
  @local_default_families [:change, :open, :close, :focus]
  @boundary_crossing_families [:click, :submit, :selection, :navigation, :command]

  @spec families() :: [atom()]
  def families, do: @families

  @spec local_default_families() :: [atom()]
  def local_default_families, do: @local_default_families

  @spec boundary_crossing_families() :: [atom()]
  def boundary_crossing_families, do: @boundary_crossing_families

  @spec from_normalized_event(map()) :: {:ok, map()} | {:error, Error.t() | term()}
  def from_normalized_event(%{} = normalized) do
    family = Map.get(normalized, :family)

    with :ok <- validate_family(family),
         :ok <- validate_payload(Map.get(normalized, :payload, %{}), :boundary_translation),
         :ok <- validate_navigation_target(Map.get(normalized, :target, %{})),
         :ok <- maybe_validate_boundary_context(normalized) do
      translation = %{
        boundary: Map.get(normalized, :boundary, :local),
        family: family,
        intent: Map.get(normalized, :intent, family),
        runtime_event: Map.get(normalized, :runtime_event, "#{family}:#{family}"),
        source_kind: Map.get(normalized, :source_kind, :native),
        platform_target:
          Map.get(normalized, :platform_target, DesktopUi.Platform.current_target()),
        input_family: Map.get(normalized, :input_family),
        widget_id: Map.get(normalized, :widget_id),
        runtime_id: Map.get(normalized, :runtime_id),
        screen: Map.get(normalized, :screen, "unknown"),
        target: normalize_map(Map.get(normalized, :target, %{})),
        payload: normalize_map(Map.get(normalized, :payload, %{})),
        normalized_input: normalize_map(Map.get(normalized, :normalized_input, %{})),
        local_handling: Map.get(normalized, :local_handling)
      }

      case translation.boundary do
        :boundary ->
          with {:ok, signal} <- build_signal(translation) do
            {:ok,
             translation
             |> Map.put(:signal, signal)
             |> Map.put(:cloud_event, cloud_event_envelope(signal))}
          end

        _local ->
          {:ok, Map.put(translation, :signal, nil)}
      end
    end
  end

  @spec from_interaction(Interaction.t() | keyword() | map(), keyword() | map()) ::
          {:ok, map()} | {:error, Error.t() | term()}
  def from_interaction(interaction, attrs \\ []) do
    interaction = Interaction.new(interaction)
    attrs = normalize_map(attrs)

    normalized = %{
      family: interaction.family,
      intent: Map.get(attrs, :intent, interaction.intent),
      runtime_event:
        Map.get(
          attrs,
          :runtime_event,
          "#{interaction.family}:#{interaction.intent || interaction.family}"
        ),
      boundary: normalize_boundary(Map.get(attrs, :boundary, :boundary)),
      source_kind: :canonical,
      platform_target: Map.get(attrs, :platform_target, DesktopUi.Platform.current_target()),
      input_family: Map.get(attrs, :input_family, :keyboard),
      widget_id: Map.get(attrs, :widget_id),
      runtime_id: Map.get(attrs, :runtime_id),
      screen: Map.get(attrs, :screen, "unknown"),
      target: merge_maps(interaction.target, Map.get(attrs, :target, %{})),
      payload: merge_maps(interaction.payload, Map.get(attrs, :payload, %{})),
      normalized_input: Map.get(attrs, :normalized_input, %{}),
      local_handling: Map.get(attrs, :local_handling, :canonical_translation)
    }

    from_normalized_event(normalized)
  end

  @spec from_boundary_signal(Signal.t() | map()) :: {:ok, map()} | {:error, Error.t() | term()}
  def from_boundary_signal(%Signal{} = signal) do
    family = extension(signal, :desktop_ui_family)
    target = normalize_map(extension(signal, :desktop_ui_target, %{}))

    with :ok <- validate_family(family),
         :ok <- validate_payload(signal.data || %{}, :boundary_signal),
         :ok <- validate_navigation_target(target) do
      {:ok,
       %{
         boundary: :boundary,
         family: family,
         intent: extension(signal, :desktop_ui_intent),
         runtime_event: extension(signal, :desktop_ui_runtime_event),
         source_kind: extension(signal, :desktop_ui_source_kind, :canonical),
         platform_target: extension(signal, :desktop_ui_platform_target, :linux),
         input_family: extension(signal, :desktop_ui_input_family),
         widget_id: signal.subject,
         runtime_id: extension(signal, :desktop_ui_runtime_id),
         screen: extension(signal, :desktop_ui_screen, "unknown"),
         target: target,
         payload: normalize_map(signal.data || %{}),
         normalized_input: %{},
         local_handling: extension(signal, :desktop_ui_local_handling),
         signal: signal,
         cloud_event: cloud_event_envelope(signal)
       }}
    end
  end

  def from_boundary_signal(%{signal: %Signal{} = signal}), do: from_boundary_signal(signal)

  def from_boundary_signal(attrs) when is_map(attrs) or is_list(attrs) do
    case Signal.new(attrs) do
      {:ok, signal} -> from_boundary_signal(signal)
      {:error, _reason} -> {:error, Error.invalid_boundary_signal(attrs)}
    end
  end

  def from_boundary_signal(value), do: {:error, Error.invalid_boundary_signal(value)}

  @spec cloud_event_envelope(Signal.t()) :: map()
  def cloud_event_envelope(%Signal{} = signal) do
    %{
      specversion: signal.specversion,
      id: signal.id,
      type: signal.type,
      source: signal.source,
      subject: signal.subject,
      time: signal.time,
      datacontenttype: signal.datacontenttype,
      dataschema: signal.dataschema,
      data: signal.data,
      extensions: signal.extensions
    }
  end

  defp validate_family(family) when family in @families, do: :ok
  defp validate_family(family), do: {:error, Error.invalid_family(family)}

  defp validate_payload(payload, _surface) when is_map(payload), do: :ok
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

  defp maybe_validate_boundary_context(%{boundary: :boundary} = normalized) do
    missing =
      []
      |> maybe_missing(:screen, Map.get(normalized, :screen))
      |> maybe_missing(
        :runtime_id_or_widget_id,
        if(is_nil(Map.get(normalized, :runtime_id)) and is_nil(Map.get(normalized, :widget_id)),
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

  defp maybe_validate_boundary_context(_normalized), do: :ok

  defp build_signal(translation) do
    Signal.new(
      cloud_event_type(translation.family, translation.intent),
      translation.payload,
      source: cloud_event_source(translation.source_kind, translation.screen),
      subject: signal_subject(translation),
      extensions: %{
        desktop_ui_family: translation.family,
        desktop_ui_intent: translation.intent,
        desktop_ui_runtime_event: translation.runtime_event,
        desktop_ui_source_kind: translation.source_kind,
        desktop_ui_platform_target: translation.platform_target,
        desktop_ui_input_family: translation.input_family,
        desktop_ui_runtime_id: translation.runtime_id,
        desktop_ui_screen: translation.screen,
        desktop_ui_target: translation.target,
        desktop_ui_local_handling: translation.local_handling
      }
    )
  end

  defp cloud_event_type(family, intent) do
    ["desktop_ui", family, intent]
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&normalize_segment/1)
    |> Enum.join(".")
  end

  defp cloud_event_source(source_kind, screen) do
    "/desktop_ui/#{normalize_segment(source_kind)}/#{normalize_segment(screen)}"
  end

  defp signal_subject(translation) do
    [translation.source_kind, translation.screen, translation.widget_id]
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&normalize_segment/1)
    |> Enum.join("/")
  end

  defp normalize_boundary(:boundary), do: :boundary
  defp normalize_boundary("boundary"), do: :boundary
  defp normalize_boundary(_value), do: :local

  defp normalize_segment(value) when is_atom(value),
    do: value |> Atom.to_string() |> normalize_segment()

  defp normalize_segment(value) when is_binary(value),
    do: value |> String.replace(~r/[^a-zA-Z0-9:_-]+/, "-") |> String.trim("-")

  defp normalize_segment(value), do: value |> to_string() |> normalize_segment()

  defp extension(signal, key, default \\ nil) do
    Map.get(signal.extensions, key, Map.get(signal.extensions, Atom.to_string(key), default))
  end

  defp maybe_missing(fields, field, nil), do: fields ++ [field]
  defp maybe_missing(fields, field, ""), do: fields ++ [field]
  defp maybe_missing(fields, _field, _value), do: fields

  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})
  defp normalize_map(_value), do: %{}

  defp merge_maps(left, right) do
    Map.merge(normalize_map(left), normalize_map(right))
  end
end
