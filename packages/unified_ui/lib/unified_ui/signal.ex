defmodule UnifiedUi.Signal do
  @moduledoc """
  Canonical authored interaction descriptors for `UnifiedUi`.
  """

  alias UnifiedUi.Binding

  @type navigation_transition_action ::
          :navigate_to
          | :replace_with
          | :go_back
          | :go_forward
          | :open_modal
          | :close_modal

  @type navigation_target_kind ::
          :screen_transition
          | :replace_transition
          | :history_transition
          | :modal_transition
          | :local_destination
          | :generic

  @type navigation_action_contract :: %{
          kind: navigation_target_kind(),
          required_fields: [atom()],
          optional_fields: [atom()]
        }

  @type modal_stack_semantics :: %{
          operation: :push | :close,
          target: :symbolic_modal | :topmost_modal,
          target_required?: boolean(),
          named_target_allowed?: boolean(),
          containment_required?: false,
          stack_effect: :push_modal | :close_topmost_or_named_modal
        }

  @type navigation_descriptor :: map()

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
  @navigation_action_contracts [
    navigate_to: %{
      kind: :screen_transition,
      required_fields: [:screen],
      optional_fields: [:params, :metadata]
    },
    replace_with: %{
      kind: :replace_transition,
      required_fields: [:screen],
      optional_fields: [:params, :metadata]
    },
    go_back: %{
      kind: :history_transition,
      required_fields: [],
      optional_fields: [:metadata]
    },
    go_forward: %{
      kind: :history_transition,
      required_fields: [],
      optional_fields: [:metadata]
    },
    open_modal: %{
      kind: :modal_transition,
      required_fields: [:modal],
      optional_fields: [:params, :metadata]
    },
    close_modal: %{
      kind: :modal_transition,
      required_fields: [],
      optional_fields: [:modal, :metadata]
    }
  ]
  @navigation_actions Keyword.keys(@navigation_action_contracts)
  @navigation_transition_fields [:action, :screen, :modal, :params, :metadata]
  @local_navigation_fields [:binding, :destination]
  @navigation_modal_stack_semantics [
    open_modal: %{
      operation: :push,
      target: :symbolic_modal,
      target_required?: true,
      named_target_allowed?: true,
      containment_required?: false,
      stack_effect: :push_modal
    },
    close_modal: %{
      operation: :close,
      target: :topmost_modal,
      target_required?: false,
      named_target_allowed?: true,
      containment_required?: false,
      stack_effect: :close_topmost_or_named_modal
    }
  ]

  defstruct __identifier__: nil,
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

  @spec navigation_actions() :: [navigation_transition_action()]
  def navigation_actions, do: @navigation_actions

  @spec navigation_action_contracts() :: %{
          navigation_transition_action() => navigation_action_contract()
        }
  def navigation_action_contracts, do: Map.new(@navigation_action_contracts)

  @spec navigation_transition_fields() :: [atom()]
  def navigation_transition_fields, do: @navigation_transition_fields

  @spec local_navigation_fields() :: [atom()]
  def local_navigation_fields, do: @local_navigation_fields

  @spec navigation_modal_stack_semantics() :: %{
          navigation_transition_action() => modal_stack_semantics()
        }
  def navigation_modal_stack_semantics, do: Map.new(@navigation_modal_stack_semantics)

  @spec navigation_target_kind(t() | keyword() | map()) :: navigation_target_kind()
  def navigation_target_kind(%__MODULE__{target_intent: target_intent}),
    do: do_navigation_target_kind(target_intent)

  def navigation_target_kind(signal) when is_list(signal),
    do: signal |> Enum.into(%{}) |> navigation_target_kind()

  def navigation_target_kind(%{target_intent: target_intent}),
    do: do_navigation_target_kind(target_intent)

  def navigation_target_kind(target_intent) when is_map(target_intent),
    do: do_navigation_target_kind(target_intent)

  @spec navigation_descriptor(t() | keyword() | map()) :: navigation_descriptor()
  def navigation_descriptor(signal) do
    signal = new(signal)
    target_intent = signal.target_intent
    action = fetch(target_intent, :action)

    %{id: signal.id, kind: navigation_target_kind(signal)}
    |> maybe_put(:action, action)
    |> maybe_put(:screen, fetch(target_intent, :screen))
    |> maybe_put(:modal, fetch(target_intent, :modal))
    |> maybe_put(:params, fetch(target_intent, :params))
    |> maybe_put(:metadata, fetch(target_intent, :metadata))
    |> maybe_put(:binding, fetch(target_intent, :binding))
    |> maybe_put(:destination, fetch(target_intent, :destination))
    |> maybe_put(:modal_stack, navigation_modal_stack_semantics()[action])
  end

  @spec new(keyword() | map() | t()) :: t()
  def new(%__MODULE__{} = signal), do: normalize(signal)
  def new(signal) when is_list(signal), do: signal |> Enum.into(%{}) |> new()

  def new(signal) when is_map(signal) do
    %__MODULE__{
      id: fetch(signal, :id),
      family: fetch(signal, :family, :click),
      intent: fetch(signal, :intent),
      source_context: signal |> fetch(:source_context, %{}) |> normalize_map(),
      target_intent: signal |> fetch(:target_intent, %{}) |> normalize_target_intent(),
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
        target_intent: normalize_target_intent(signal.target_intent),
        payload_mapping: normalize_map(signal.payload_mapping),
        binding_refs: normalize_binding_refs(signal.binding_refs),
        metadata: normalize_map(signal.metadata)
    }
  end

  defp do_navigation_target_kind(target_intent) do
    target_intent = normalize_target_intent(target_intent)

    case navigation_action_contracts()[fetch(target_intent, :action)] do
      %{kind: kind} ->
        kind

      nil ->
        if fetch(target_intent, :binding) != nil and fetch(target_intent, :destination) != nil do
          :local_destination
        else
          :generic
        end
    end
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

  defp normalize_target_intent(target_intent) do
    target_intent
    |> normalize_map()
    |> normalize_nested_target_field(:params)
    |> normalize_nested_target_field(:metadata)
  end

  defp normalize_nested_target_field(values, key) do
    case fetch(values, key) do
      nested when is_map(nested) or is_list(nested) ->
        values
        |> Map.delete(Atom.to_string(key))
        |> Map.put(key, normalize_map(nested))

      _other ->
        values
    end
  end

  defp normalize_map(nil), do: %{}
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp fetch(source, key, default \\ nil) do
    Map.get(source, key, Map.get(source, Atom.to_string(key), default))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, value) when value in [%{}, []], do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
