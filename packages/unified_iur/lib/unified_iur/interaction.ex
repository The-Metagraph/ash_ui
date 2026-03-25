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

  @spec families() :: [family()]
  def families do
    @families
  end

  @spec new(keyword() | map() | t()) :: t()
  def new(%__MODULE__{} = interaction), do: normalize(interaction)
  def new(interaction) when is_list(interaction), do: interaction |> Enum.into(%{}) |> new()

  def new(interaction) when is_map(interaction) do
    %__MODULE__{
      family: fetch(interaction, :family, :click),
      intent: fetch(interaction, :intent),
      source: normalize_map(fetch(interaction, :source, %{})),
      target: normalize_map(fetch(interaction, :target, %{})),
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

  @spec command(keyword() | map()) :: t()
  def command(opts \\ []), do: build(:command, opts)

  defp build(family, opts) do
    opts = normalize_map(opts)

    %__MODULE__{
      family: family,
      intent: fetch(opts, :intent),
      source:
        %{}
        |> maybe_put(:element_id, fetch(opts, :element_id))
        |> maybe_put(:slot, fetch(opts, :slot))
        |> maybe_put(:scope, fetch(opts, :scope)),
      target:
        %{}
        |> maybe_put(:path, fetch(opts, :path))
        |> maybe_put(:entity, fetch(opts, :entity))
        |> maybe_put(:binding, fetch(opts, :binding)),
      payload:
        %{}
        |> maybe_put(:mapping, normalize_optional_map(fetch(opts, :mapping)))
        |> maybe_put(:value, fetch(opts, :value))
        |> maybe_put(:selection, fetch(opts, :selection))
        |> maybe_put(:command, fetch(opts, :command)),
      metadata:
        %{}
        |> maybe_put(:phase, fetch(opts, :phase))
        |> maybe_put(:propagation, fetch(opts, :propagation))
        |> maybe_put(:transient?, fetch(opts, :transient?))
    }
  end

  defp normalize(%__MODULE__{} = interaction) do
    %__MODULE__{
      family: interaction.family,
      intent: interaction.intent,
      source: normalize_map(interaction.source),
      target: normalize_map(interaction.target),
      payload: normalize_map(interaction.payload),
      metadata: normalize_map(interaction.metadata)
    }
  end

  defp normalize_map(nil), do: %{}
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp normalize_optional_map(nil), do: nil
  defp normalize_optional_map(map), do: normalize_map(map)

  defp fetch(source, key, default \\ nil) do
    Map.get(source, key, Map.get(source, Atom.to_string(key), default))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
