defmodule UnifiedUi.Signal do
  @moduledoc """
  Canonical authored interaction descriptors for `UnifiedUi`.
  """

  alias UnifiedUi.Binding

  @type family ::
          :click
          | :change
          | :submit
          | :open
          | :close
          | :focus
          | :selection
          | :navigation
          | :command

  @type t :: %__MODULE__{
          __identifier__: atom() | nil,
          id: atom() | nil,
          family: family(),
          intent: atom() | String.t() | nil,
          source_context: map(),
          target_intent: map(),
          payload_mapping: map(),
          binding_refs: [Binding.ref_t()],
          summary: String.t() | nil,
          metadata: map()
        }

  @families [:click, :change, :submit, :open, :close, :focus, :selection, :navigation, :command]

  defstruct __identifier__: nil,
            __spark_metadata__: nil,
            id: nil,
            family: :click,
            intent: nil,
            source_context: %{},
            target_intent: %{},
            payload_mapping: %{},
            binding_refs: [],
            summary: nil,
            metadata: %{}

  @spec families() :: [family()]
  def families, do: @families

  @spec new(keyword() | map() | t()) :: t()
  def new(%__MODULE__{} = signal), do: normalize(signal)
  def new(signal) when is_list(signal), do: signal |> Enum.into(%{}) |> new()

  def new(signal) when is_map(signal) do
    %__MODULE__{
      id: fetch(signal, :id),
      family: fetch(signal, :family, :click),
      intent: fetch(signal, :intent),
      source_context: signal |> fetch(:source_context, %{}) |> normalize_map(),
      target_intent: signal |> fetch(:target_intent, %{}) |> normalize_map(),
      payload_mapping: signal |> fetch(:payload_mapping, %{}) |> normalize_map(),
      binding_refs: signal |> fetch(:binding_refs, []) |> normalize_binding_refs(),
      summary: fetch(signal, :summary),
      metadata: signal |> fetch(:metadata, %{}) |> normalize_map()
    }
  end

  @spec summary(t() | keyword() | map()) :: map()
  def summary(signal) do
    signal = new(signal)

    %{
      id: signal.id,
      family: signal.family,
      intent: signal.intent,
      source_context: signal.source_context,
      target_intent: signal.target_intent,
      payload_mapping: signal.payload_mapping,
      binding_refs: signal.binding_refs,
      summary: signal.summary,
      metadata: signal.metadata
    }
    |> Enum.reject(fn {_key, value} -> value in [nil, [], %{}] end)
    |> Enum.into(%{})
  end

  defp normalize(%__MODULE__{} = signal) do
    %__MODULE__{
      signal
      | source_context: normalize_map(signal.source_context),
        target_intent: normalize_map(signal.target_intent),
        payload_mapping: normalize_map(signal.payload_mapping),
        binding_refs: normalize_binding_refs(signal.binding_refs),
        metadata: normalize_map(signal.metadata)
    }
  end

  defp normalize_binding_refs(refs) do
    refs
    |> List.wrap()
    |> Enum.map(fn
      %{kind: :binding_ref, id: id} when is_atom(id) or is_binary(id) ->
        Binding.ref(id)

      %{"kind" => :binding_ref, "id" => id} when is_atom(id) or is_binary(id) ->
        Binding.ref(id)

      id when is_atom(id) or is_binary(id) ->
        Binding.ref(id)
    end)
  end

  defp normalize_map(nil), do: %{}
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp fetch(source, key, default \\ nil) do
    Map.get(source, key, Map.get(source, Atom.to_string(key), default))
  end
end
