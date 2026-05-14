defmodule AshUI.WidgetComponents do
  @moduledoc """
  Ash UI boundary for the canonical Unified UI widget-component catalog.

  The Unified package owns the canonical component vocabulary. Ash UI exposes
  this wrapper so resource admission, canonical conversion, examples, and tests
  can all depend on one local boundary and detect catalog drift explicitly.
  """

  @type kind :: atom()
  @type alias_name :: atom()
  @type family :: atom()
  @type component :: UnifiedUi.WidgetComponents.component()
  @type name_diagnostic :: UnifiedUi.WidgetComponents.name_diagnostic()

  @doc """
  Returns the explicit list of upstream component kinds Ash UI has chosen not to
  support yet.

  Phase 31 starts with no exclusions. Keeping this as a function makes any
  future delay visible in package-boundary tests and review diffs.
  """
  @spec explicit_exclusions() :: [kind()]
  def explicit_exclusions, do: []

  @doc """
  Returns the canonical component catalog after applying explicit exclusions.
  """
  @spec catalog() :: [component()]
  def catalog do
    exclusions = MapSet.new(explicit_exclusions())

    UnifiedUi.WidgetComponents.catalog()
    |> Enum.reject(&MapSet.member?(exclusions, &1.kind))
  end

  @doc """
  Returns canonical component kinds supported by Ash UI.
  """
  @spec kinds() :: [kind()]
  def kinds do
    Enum.map(catalog(), & &1.kind)
  end

  @doc """
  Returns compatibility aliases accepted at Ash UI authoring boundaries.
  """
  @spec aliases() :: %{alias_name() => kind()}
  def aliases do
    supported = MapSet.new(kinds())

    UnifiedUi.WidgetComponents.aliases()
    |> Map.filter(fn {_alias_name, canonical} -> MapSet.member?(supported, canonical) end)
  end

  @doc """
  Returns component kinds grouped by semantic family.
  """
  @spec families() :: %{family() => [kind()]}
  def families do
    catalog()
    |> Enum.group_by(& &1.family, & &1.kind)
    |> Map.new(fn {family, kinds} -> {family, kinds} end)
  end

  @doc """
  Returns true when a name is a canonical component kind or supported alias.
  """
  @spec known?(atom() | String.t()) :: boolean()
  def known?(name) do
    match?({:ok, _kind}, canonical_kind(name))
  end

  @doc """
  Resolves a component name or compatibility alias to its canonical kind.
  """
  @spec canonical_kind(atom() | String.t()) :: {:ok, kind()} | {:error, name_diagnostic()}
  def canonical_kind(name) do
    case UnifiedUi.WidgetComponents.canonical_kind(name) do
      {:ok, kind} ->
        if kind in kinds() do
          {:ok, kind}
        else
          {:error, name_diagnostic(name)}
        end

      {:error, diagnostic} ->
        {:error, diagnostic}
    end
  end

  @doc """
  Resolves a component name or raises with the upstream diagnostic message.
  """
  @spec canonical_kind!(atom() | String.t()) :: kind()
  def canonical_kind!(name) do
    case canonical_kind(name) do
      {:ok, kind} -> kind
      {:error, diagnostic} -> raise ArgumentError, diagnostic.message
    end
  end

  @doc """
  Returns the Unified UI name diagnostic for review and error reporting.
  """
  @spec name_diagnostic(atom() | String.t()) :: name_diagnostic()
  def name_diagnostic(name) do
    UnifiedUi.WidgetComponents.name_diagnostic(name)
  end
end
