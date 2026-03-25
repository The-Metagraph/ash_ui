defmodule UnifiedIUR do
  @moduledoc """
  Canonical intermediate representation package for the unified ecosystem.

  `UnifiedIUR` is the pure package boundary between authored `unified_ui`
  output and runtime-library renderer entry points.
  """

  @type module_area ::
          :display
          | :core
          | :constructs
          | :interactions
          | :fixtures
          | :inspect
          | :export
          | :validate
          | :normalize
          | :interoperability
          | :extension
          | :reference
          | :tooling

  @module_areas %{
    display: UnifiedIUR.Display,
    core: UnifiedIUR.Core,
    constructs: UnifiedIUR.Constructs,
    interactions: UnifiedIUR.Interactions,
    fixtures: UnifiedIUR.Fixtures,
    inspect: UnifiedIUR.Inspect,
    export: UnifiedIUR.Export,
    validate: UnifiedIUR.Validate,
    normalize: UnifiedIUR.Normalize,
    interoperability: UnifiedIUR.Interoperability,
    extension: UnifiedIUR.Extension,
    reference: UnifiedIUR.Reference,
    tooling: UnifiedIUR.Tooling
  }

  @spec module_areas() :: %{module_area() => module()}
  def module_areas do
    @module_areas
  end

  @spec module_for(module_area()) :: {:ok, module()} | :error
  def module_for(area) do
    Map.fetch(@module_areas, area)
  end

  @doc """
  Backwards-compatible validation entrypoint for downstream runtime libraries.

  Existing consumers may still pass the older Ash UI screen-shaped maps here.
  Those values are translated into canonical `UnifiedIUR.Element` values before
  validation so the stricter package surface can be adopted incrementally.
  """
  @spec validate(map() | keyword() | UnifiedIUR.Element.t()) :: :ok | {:error, [term()]}
  def validate(input) do
    input
    |> compat_element()
    |> UnifiedIUR.Normalize.element()
    |> case do
      {:ok, element} -> UnifiedIUR.Validate.element(element)
      {:error, errors} -> {:error, errors}
    end
  end

  defp compat_element(%UnifiedIUR.Element{} = element), do: element

  defp compat_element(input) when is_list(input) do
    input
    |> Enum.into(%{})
    |> compat_element()
  end

  defp compat_element(input) when is_map(input) do
    case fetch(input, :type) do
      "screen" ->
        %{
          id: fetch(input, :id),
          type: :composite,
          kind: :screen,
          metadata: fetch(input, :metadata, %{}),
          attributes: %{
            screen: %{
              name: fetch(input, :name),
              layout: fetch(input, :layout),
              route: fetch(input, :route),
              version: fetch(input, :version)
            },
            bindings:
              input
              |> fetch(:bindings, [])
              |> Enum.map(&compat_binding/1)
          },
          children:
            input
            |> fetch(:children, [])
            |> Enum.map(&compat_element/1)
        }

      type when is_binary(type) ->
        {element_type, kind} = compat_type(type)

        %{
          id: fetch(input, :id),
          type: element_type,
          kind: kind,
          metadata: fetch(input, :metadata, %{}),
          attributes: compat_attributes(element_type, fetch(input, :props, %{})),
          children:
            input
            |> fetch(:children, [])
            |> Enum.map(&compat_element/1)
        }

      _other ->
        input
    end
  end

  defp compat_element(other), do: other

  defp compat_binding(binding) when is_list(binding) do
    binding
    |> Enum.into(%{})
    |> compat_binding()
  end

  defp compat_binding(binding) when is_map(binding) do
    UnifiedIUR.Binding.new(%{
      name: fetch(binding, :id, fetch(binding, :target)),
      path: List.wrap(fetch(binding, :target, [])),
      source: fetch(binding, :type, fetch(binding, :binding_type)),
      metadata: Map.new(binding)
    })
  end

  defp compat_binding(other) do
    UnifiedIUR.Binding.new(%{metadata: %{legacy_value: inspect(other)}})
  end

  defp compat_type(type) do
    case to_string(type) do
      value when value in ["row", "column", "grid", "stack"] -> {:layout, String.to_atom(value)}
      "container" -> {:layout, :column}
      "fragment" -> {:composite, :fragment}
      "input" -> {:widget, :text_input}
      "textarea" -> {:widget, :text_input}
      "checkbox" -> {:widget, :checkbox}
      "radio" -> {:widget, :radio_group}
      "switch" -> {:widget, :toggle}
      "slider" -> {:widget, :slider}
      "select" -> {:widget, :select}
      "divider" -> {:widget, :separator}
      other -> {:widget, String.to_atom(other)}
    end
  end

  defp compat_attributes(:layout, props) when is_map(props), do: %{layout: Map.new(props)}
  defp compat_attributes(:composite, props) when is_map(props), do: %{composite: Map.new(props)}
  defp compat_attributes(_type, props) when is_map(props), do: Map.new(props)
  defp compat_attributes(_type, _props), do: %{}

  defp fetch(map, key, default \\ nil) do
    Map.get(map, key, Map.get(map, Atom.to_string(key), default))
  end
end
