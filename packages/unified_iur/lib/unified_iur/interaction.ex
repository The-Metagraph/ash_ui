defmodule UnifiedIUR.Interaction do
  @moduledoc """
  Canonical renderer-independent interaction descriptors for `UnifiedIUR`.
  """

  @type family ::
          :click
          | :change
          | :submit
          | :open
          | :close
          | :selection
          | :focus
          | :navigation
          | :command

  @type navigation_action ::
          :navigate_to
          | :replace_with
          | :go_back
          | :go_forward
          | :open_modal
          | :close_modal

  @type navigation_kind ::
          :screen_transition
          | :replace_transition
          | :history_transition
          | :modal_transition

  @type modal_stack_semantics :: %{
          optional(:operation) => :push | :close | atom() | String.t(),
          optional(:target) => :symbolic_modal | :topmost_modal | atom() | String.t(),
          optional(:target_required?) => boolean(),
          optional(:named_target_allowed?) => boolean(),
          optional(:containment_required?) => boolean(),
          optional(:stack_effect) =>
            :push_modal | :close_topmost_or_named_modal | atom() | String.t()
        }

  @type navigation_descriptor :: %{
          optional(:kind) => navigation_kind(),
          optional(:action) => navigation_action() | atom() | String.t(),
          optional(:screen) => atom() | String.t(),
          optional(:modal) => atom() | String.t(),
          optional(:params) => map(),
          optional(:metadata) => map(),
          optional(:modal_stack) => modal_stack_semantics()
        }

  @type t :: %__MODULE__{
          family: family(),
          intent: atom() | String.t() | nil,
          source: map(),
          target: map(),
          payload: map(),
          metadata: map()
        }

  defstruct family: :click,
            intent: nil,
            source: %{},
            target: %{},
            payload: %{},
            metadata: %{}

  @families [:click, :change, :submit, :open, :close, :selection, :focus, :navigation, :command]
  @navigation_actions [
    :navigate_to,
    :replace_with,
    :go_back,
    :go_forward,
    :open_modal,
    :close_modal
  ]
  @navigation_kinds [
    :screen_transition,
    :replace_transition,
    :history_transition,
    :modal_transition
  ]

  @spec families() :: [family()]
  def families do
    @families
  end

  @spec navigation_actions() :: [navigation_action()]
  def navigation_actions do
    @navigation_actions
  end

  @spec navigation_kinds() :: [navigation_kind()]
  def navigation_kinds do
    @navigation_kinds
  end

  @spec new(keyword() | map() | t()) :: t()
  def new(%__MODULE__{} = interaction), do: normalize(interaction)
  def new(interaction) when is_list(interaction), do: interaction |> Enum.into(%{}) |> new()

  def new(interaction) when is_map(interaction) do
    %__MODULE__{
      family: fetch(interaction, :family, :click),
      intent: fetch(interaction, :intent),
      source: normalize_map(fetch(interaction, :source, %{})),
      target: normalize_target(fetch(interaction, :target, %{})),
      payload: normalize_map(fetch(interaction, :payload, %{})),
      metadata: normalize_map(fetch(interaction, :metadata, %{}))
    }
  end

  @spec click(keyword() | map()) :: t()
  def click(opts \\ []), do: build(:click, opts)

  @spec change(keyword() | map()) :: t()
  def change(opts \\ []), do: build(:change, opts)

  @spec submit(keyword() | map()) :: t()
  def submit(opts \\ []), do: build(:submit, opts)

  @spec open(keyword() | map()) :: t()
  def open(opts \\ []), do: build(:open, opts)

  @spec close(keyword() | map()) :: t()
  def close(opts \\ []), do: build(:close, opts)

  @spec selection(keyword() | map()) :: t()
  def selection(opts \\ []), do: build(:selection, opts)

  @spec focus(keyword() | map()) :: t()
  def focus(opts \\ []), do: build(:focus, opts)

  @spec navigation(keyword() | map()) :: t()
  def navigation(opts \\ []), do: build(:navigation, opts)

  @spec navigation_transition(keyword() | map()) :: t()
  def navigation_transition(opts \\ []), do: build(:navigation, opts)

  @spec command(keyword() | map()) :: t()
  def command(opts \\ []), do: build(:command, opts)

  @spec navigation_descriptor(t() | map() | keyword() | nil) :: navigation_descriptor() | nil
  def navigation_descriptor(%__MODULE__{} = interaction) do
    interaction.target
    |> fetch(:navigation)
    |> navigation_descriptor()
  end

  def navigation_descriptor(nil), do: nil

  def navigation_descriptor(descriptor) when is_list(descriptor),
    do: descriptor |> Enum.into(%{}) |> navigation_descriptor()

  def navigation_descriptor(descriptor) when is_map(descriptor) do
    descriptor =
      descriptor
      |> unwrap_navigation_descriptor()
      |> normalize_navigation_descriptor()

    if descriptor == %{}, do: nil, else: descriptor
  end

  defp build(family, opts) do
    opts = normalize_map(opts)

    %__MODULE__{
      family: family,
      intent: fetch(opts, :intent),
      source: build_source(opts),
      target: build_target(family, opts),
      payload: build_payload(opts),
      metadata: build_metadata(opts)
    }
  end

  defp normalize(%__MODULE__{} = interaction) do
    %__MODULE__{
      family: interaction.family,
      intent: interaction.intent,
      source: normalize_map(interaction.source),
      target: normalize_target(interaction.target),
      payload: normalize_map(interaction.payload),
      metadata: normalize_map(interaction.metadata)
    }
  end

  defp build_source(opts) do
    %{}
    |> maybe_put(:element_id, fetch(opts, :element_id))
    |> maybe_put(:slot, fetch(opts, :slot))
    |> maybe_put(:scope, fetch(opts, :scope))
  end

  defp build_target(:navigation, opts) do
    %{}
    |> maybe_put(:path, fetch(opts, :path))
    |> maybe_put(:entity, fetch(opts, :entity))
    |> maybe_put(:binding, fetch(opts, :binding))
    |> maybe_put(:navigation, navigation_descriptor(opts))
  end

  defp build_target(_family, opts) do
    %{}
    |> maybe_put(:path, fetch(opts, :path))
    |> maybe_put(:entity, fetch(opts, :entity))
    |> maybe_put(:binding, fetch(opts, :binding))
  end

  defp build_payload(opts) do
    %{}
    |> maybe_put(:mapping, normalize_optional_map(fetch(opts, :mapping)))
    |> maybe_put(:value, fetch(opts, :value))
    |> maybe_put(:selection, fetch(opts, :selection))
    |> maybe_put(:command, fetch(opts, :command))
  end

  defp build_metadata(opts) do
    %{}
    |> maybe_put(:phase, fetch(opts, :phase))
    |> maybe_put(:propagation, fetch(opts, :propagation))
    |> maybe_put(:transient?, fetch(opts, :transient?))
  end

  defp normalize_target(target) do
    target = normalize_map(target)

    case navigation_descriptor(target) do
      nil ->
        target

      descriptor ->
        target
        |> Map.delete(:navigation)
        |> Map.delete("navigation")
        |> Map.put(:navigation, descriptor)
    end
  end

  defp unwrap_navigation_descriptor(descriptor) do
    case fetch(descriptor, :navigation) do
      nil -> normalize_map(descriptor)
      nested -> normalize_map(nested)
    end
  end

  defp normalize_navigation_descriptor(descriptor) do
    action = fetch(descriptor, :action)
    kind = fetch(descriptor, :kind, infer_navigation_kind(action))

    %{}
    |> maybe_put(:kind, kind)
    |> maybe_put(:action, action)
    |> maybe_put(:screen, fetch(descriptor, :screen))
    |> maybe_put(:modal, fetch(descriptor, :modal))
    |> maybe_put(:params, normalize_optional_non_empty_map(fetch(descriptor, :params)))
    |> maybe_put(:metadata, normalize_optional_non_empty_map(fetch(descriptor, :metadata)))
    |> maybe_put(:modal_stack, normalize_optional_non_empty_map(fetch(descriptor, :modal_stack)))
  end

  defp infer_navigation_kind(:navigate_to), do: :screen_transition
  defp infer_navigation_kind("navigate_to"), do: :screen_transition
  defp infer_navigation_kind(:replace_with), do: :replace_transition
  defp infer_navigation_kind("replace_with"), do: :replace_transition
  defp infer_navigation_kind(:go_back), do: :history_transition
  defp infer_navigation_kind("go_back"), do: :history_transition
  defp infer_navigation_kind(:go_forward), do: :history_transition
  defp infer_navigation_kind("go_forward"), do: :history_transition
  defp infer_navigation_kind(:open_modal), do: :modal_transition
  defp infer_navigation_kind("open_modal"), do: :modal_transition
  defp infer_navigation_kind(:close_modal), do: :modal_transition
  defp infer_navigation_kind("close_modal"), do: :modal_transition
  defp infer_navigation_kind(_action), do: nil

  defp normalize_map(nil), do: %{}
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp normalize_optional_map(nil), do: nil
  defp normalize_optional_map(map), do: normalize_map(map)

  defp normalize_optional_non_empty_map(nil), do: nil

  defp normalize_optional_non_empty_map(map) do
    case normalize_map(map) do
      empty when empty == %{} -> nil
      normalized -> normalized
    end
  end

  defp fetch(source, key, default \\ nil) do
    Map.get(source, key, Map.get(source, Atom.to_string(key), default))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
