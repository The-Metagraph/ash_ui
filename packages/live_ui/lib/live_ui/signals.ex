defmodule LiveUi.Signals do
  @moduledoc """
  Canonical signal translation between native `live_ui` events and `Jido.Signal`
  boundary envelopes.
  """

  alias Jido.Signal
  alias UnifiedIUR.Interaction

  @type family :: Interaction.family()
  @type source_kind :: :native | :canonical
  @type boundary_kind :: :local | :boundary
  @type native_attrs :: keyword() | map()
  @type translation :: %{
          family: family(),
          intent: atom() | String.t() | nil,
          source: source_kind(),
          boundary: boundary_kind(),
          runtime_event: String.t(),
          signal: Signal.t() | nil,
          payload: map(),
          source_context: map(),
          target: map(),
          metadata: map()
        }

  @families [:click, :change, :submit, :open, :close, :selection, :focus, :navigation, :command]
  @boundary_families [:click, :change, :submit, :open, :navigation, :command]

  @spec families() :: [family()]
  def families, do: @families

  @spec boundary_families() :: [family()]
  def boundary_families, do: @boundary_families

  @spec source_kinds() :: [source_kind()]
  def source_kinds, do: [:native, :canonical]

  @spec from_native(native_attrs()) :: {:ok, translation()} | {:error, term()}
  def from_native(attrs) do
    attrs = normalize_map(attrs)
    family = fetch_family(attrs)

    with :ok <- validate_family(family),
         :ok <-
           maybe_validate_boundary(
             attrs,
             &LiveUi.Transport.Diagnostics.validate_native_boundary/1
           ),
         {:ok, signal} <- maybe_signal(family, attrs, :native) do
      {:ok,
       %{
         family: family,
         intent: fetch(attrs, :intent),
         source: :native,
         boundary: boundary_kind(attrs),
         runtime_event: native_runtime_event(family, attrs),
         signal: signal,
         payload: native_payload(attrs),
         source_context: source_context(attrs, :native),
         target: target(attrs),
         metadata: metadata(attrs, :native)
       }}
    end
  end

  @spec from_interaction(Interaction.t() | keyword() | map(), native_attrs()) ::
          {:ok, translation()} | {:error, term()}
  def from_interaction(interaction, attrs \\ []) do
    interaction = Interaction.new(interaction)
    attrs = normalize_map(attrs)
    family = interaction.family

    with :ok <- validate_family(family),
         :ok <-
           maybe_validate_boundary(
             attrs,
             &LiveUi.Transport.Diagnostics.validate_canonical_boundary(interaction, &1)
           ),
         {:ok, signal} <- maybe_signal(family, attrs, :canonical, interaction) do
      {:ok,
       %{
         family: family,
         intent: interaction.intent,
         source: :canonical,
         boundary: boundary_kind(attrs, :boundary),
         runtime_event: canonical_runtime_event(interaction, attrs),
         signal: signal,
         payload: merge_payloads(interaction.payload, fetch(attrs, :payload, %{})),
         source_context: merge_maps(interaction.source, fetch(attrs, :source_context, %{})),
         target: merge_maps(interaction.target, fetch(attrs, :target, %{})),
         metadata: merge_maps(interaction.metadata, metadata(attrs, :canonical))
       }}
    end
  end

  @spec to_runtime_action(Signal.t() | map()) :: {:ok, map()} | {:error, term()}
  def to_runtime_action(%Signal{} = signal) do
    with :ok <- LiveUi.Transport.Diagnostics.validate_boundary_signal(signal) do
      family = signal.extensions["live_ui_family"] || signal.extensions[:live_ui_family]

      {:ok,
       %{
         family: family,
         intent: signal.extensions["live_ui_intent"] || signal.extensions[:live_ui_intent],
         runtime_event:
           signal.extensions["live_ui_runtime_event"] || signal.extensions[:live_ui_runtime_event],
         source_kind: signal.extensions["live_ui_source"] || signal.extensions[:live_ui_source],
         boundary: :boundary,
         payload: normalize_map(signal.data || %{}),
         source_context:
           normalize_map(
             signal.extensions["live_ui_source_context"] ||
               signal.extensions[:live_ui_source_context] || %{}
           ),
         target:
           normalize_map(
             signal.extensions["live_ui_target"] || signal.extensions[:live_ui_target] || %{}
           ),
         metadata:
           normalize_map(
             signal.extensions["live_ui_metadata"] || signal.extensions[:live_ui_metadata] || %{}
           )
       }}
    end
  end

  def to_runtime_action(attrs) when is_map(attrs) or is_list(attrs) do
    attrs = normalize_map(attrs)

    cond do
      Map.has_key?(attrs, :type) or Map.has_key?(attrs, "type") ->
        case Signal.new(attrs) do
          {:ok, signal} -> to_runtime_action(signal)
          {:error, reason} -> {:error, reason}
        end

      true ->
        {:error, :invalid_signal}
    end
  end

  @spec cloud_event_type(family(), atom() | String.t() | nil) :: String.t()
  def cloud_event_type(family, intent) do
    segments =
      ["live_ui", family, intent]
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&normalize_segment/1)

    Enum.join(segments, ".")
  end

  @spec cloud_event_source(source_kind(), keyword() | map()) :: String.t()
  def cloud_event_source(source_kind, attrs) do
    attrs = normalize_map(attrs)
    mode = fetch(attrs, :mode, :screen)
    screen = fetch(attrs, :screen, "unknown")
    "/live_ui/#{source_kind}/#{normalize_segment(mode)}/#{normalize_segment(screen)}"
  end

  @spec native_runtime_event(family(), native_attrs()) :: String.t()
  def native_runtime_event(family, attrs) do
    attrs = normalize_map(attrs)

    fetch(attrs, :runtime_event) || fetch(attrs, :event) ||
      "#{family}:#{normalize_segment(fetch(attrs, :intent, family))}"
  end

  @spec canonical_runtime_event(Interaction.t(), native_attrs()) :: String.t()
  def canonical_runtime_event(%Interaction{} = interaction, attrs) do
    attrs = normalize_map(attrs)

    fetch(attrs, :runtime_event) ||
      "#{interaction.family}:#{normalize_segment(interaction.intent || interaction.family)}"
  end

  defp maybe_signal(family, attrs, source_kind, interaction \\ nil) do
    case boundary_kind(attrs) do
      :local ->
        {:ok, nil}

      :boundary ->
        signal_attrs =
          %{
            source: cloud_event_source(source_kind, attrs),
            subject: signal_subject(attrs, source_kind),
            extensions: %{
              live_ui_family: family,
              live_ui_intent: interaction_intent(attrs, interaction),
              live_ui_source: source_kind,
              live_ui_runtime_event: runtime_event(attrs, family, interaction),
              live_ui_source_context: source_context(attrs, source_kind, interaction),
              live_ui_target: target(attrs, interaction),
              live_ui_metadata: metadata(attrs, source_kind, interaction)
            }
          }

        Signal.new(
          cloud_event_type(family, interaction_intent(attrs, interaction)),
          payload(attrs, interaction),
          signal_attrs
        )
    end
  end

  defp interaction_intent(attrs, nil), do: fetch(attrs, :intent)

  defp interaction_intent(attrs, %Interaction{} = interaction),
    do: fetch(attrs, :intent, interaction.intent)

  defp runtime_event(attrs, family, nil), do: native_runtime_event(family, attrs)

  defp runtime_event(attrs, _family, %Interaction{} = interaction),
    do: canonical_runtime_event(interaction, attrs)

  defp signal_subject(attrs, source_kind) do
    attrs = normalize_map(attrs)

    [source_kind, fetch(attrs, :screen), fetch(attrs, :element_id)]
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&normalize_segment/1)
    |> Enum.join("/")
  end

  defp payload(attrs, nil), do: native_payload(attrs)

  defp payload(attrs, %Interaction{} = interaction) do
    merge_payloads(interaction.payload, fetch(attrs, :payload, %{}))
  end

  defp native_payload(attrs) do
    attrs
    |> normalize_map()
    |> fetch(:payload, %{})
    |> normalize_map()
  end

  defp source_context(attrs, source_kind, interaction \\ nil) do
    attrs_context = normalize_map(fetch(normalize_map(attrs), :source_context, %{}))

    base =
      %{}
      |> maybe_put(:screen, fetch(attrs, :screen))
      |> maybe_put(:element_id, fetch(attrs, :element_id))
      |> maybe_put(:widget, fetch(attrs, :widget))
      |> maybe_put(:mode, fetch(attrs, :mode))
      |> maybe_put(:source_kind, source_kind)

    merge_maps(interaction_source(interaction), merge_maps(base, attrs_context))
  end

  defp interaction_source(nil), do: %{}
  defp interaction_source(%Interaction{} = interaction), do: interaction.source

  defp target(attrs, interaction \\ nil) do
    merge_maps(interaction_target(interaction), fetch(attrs, :target, %{}))
  end

  defp interaction_target(nil), do: %{}
  defp interaction_target(%Interaction{} = interaction), do: interaction.target

  defp metadata(attrs, source_kind, interaction \\ nil) do
    attrs = normalize_map(attrs)

    base =
      %{}
      |> maybe_put(:boundary, boundary_kind(attrs))
      |> maybe_put(:source_kind, source_kind)
      |> maybe_put(:hook, fetch(attrs, :hook))
      |> maybe_put(:channel, fetch(attrs, :channel))
      |> maybe_put(:phase, fetch(attrs, :phase))

    merge_maps(interaction_metadata(interaction), merge_maps(base, fetch(attrs, :metadata, %{})))
  end

  defp interaction_metadata(nil), do: %{}
  defp interaction_metadata(%Interaction{} = interaction), do: interaction.metadata

  defp boundary_kind(attrs, default \\ :local) do
    case fetch(normalize_map(attrs), :boundary, default) do
      :canonical_boundary -> :boundary
      :boundary -> :boundary
      _ -> :local
    end
  end

  defp validate_family(family) when family in @families, do: :ok
  defp validate_family(family), do: {:error, LiveUi.Transport.Error.invalid_family(family)}

  defp maybe_validate_boundary(attrs, validator) do
    if boundary_kind(attrs) == :boundary do
      validator.(attrs)
    else
      :ok
    end
  end

  defp fetch(source, key, default \\ nil) do
    Map.get(source, key, Map.get(source, Atom.to_string(key), default))
  end

  defp normalize_map(attrs) when is_list(attrs), do: Enum.into(attrs, %{})
  defp normalize_map(attrs) when is_map(attrs), do: Map.new(attrs)
  defp normalize_map(nil), do: %{}

  defp normalize_segment(value) do
    value
    |> to_string()
    |> String.replace(~r/[^a-zA-Z0-9]+/, "_")
    |> String.trim("_")
    |> String.downcase()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp merge_maps(left, right) do
    left
    |> normalize_map()
    |> Map.merge(normalize_map(right))
  end

  defp merge_payloads(left, right) do
    merge_maps(left, right)
  end

  defp fetch_family(attrs) do
    attrs
    |> normalize_map()
    |> fetch(:family, :click)
  end
end
