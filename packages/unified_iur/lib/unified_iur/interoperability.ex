defmodule UnifiedIUR.Interoperability do
  @moduledoc """
  Runtime-library consumption helpers and compatibility surfaces for canonical
  `UnifiedIUR` values.
  """

  alias UnifiedIUR.{Element, Normalize, Tree, Validate}
  alias UnifiedIUR.Validate.Error

  @runtime_consumers [:live_ui, :elm_ui, :desktop_ui]

  @spec runtime_consumers() :: [atom()]
  def runtime_consumers do
    @runtime_consumers
  end

  @spec walk(Element.t() | map() | keyword()) :: [Element.t()]
  def walk(input) do
    input
    |> Normalize.element!()
    |> Tree.depth_first()
  end

  @spec widgets(Element.t() | map() | keyword()) :: [Element.t()]
  def widgets(input), do: filter_by_type(input, :widget)

  @spec layouts(Element.t() | map() | keyword()) :: [Element.t()]
  def layouts(input), do: filter_by_type(input, :layout)

  @spec layers(Element.t() | map() | keyword()) :: [Element.t()]
  def layers(input), do: filter_by_type(input, :layer)

  @spec composites(Element.t() | map() | keyword()) :: [Element.t()]
  def composites(input), do: filter_by_type(input, :composite)

  @spec identity(Element.t() | map() | keyword()) :: map()
  def identity(input) do
    element = Normalize.element!(input)

    %{
      id: element.id,
      type: element.type,
      kind: element.kind
    }
  end

  @spec metadata(Element.t() | map() | keyword()) :: map()
  def metadata(input) do
    element = Normalize.element!(input)

    %{
      authored_ref: element.metadata.authored_ref,
      description: element.metadata.description,
      annotations: element.metadata.annotations,
      tags: element.metadata.tags,
      extra: element.metadata.extra
    }
  end

  @spec classify(Element.t() | map() | keyword()) :: map()
  def classify(input) do
    element = Normalize.element!(input)

    %{
      widget?: element.type == :widget,
      layout?: element.type == :layout,
      layer?: element.type == :layer,
      composite?: element.type == :composite,
      child_shape: Element.child_shape(element),
      attachment_keys:
        element.attributes
        |> Map.keys()
        |> Enum.filter(&(&1 in [:style, :theme, :interactions, :bindings, :interaction_scope]))
        |> Enum.sort()
    }
  end

  @spec bindings(Element.t() | map() | keyword()) :: list()
  def bindings(input) do
    input
    |> walk()
    |> Enum.flat_map(&Map.get(&1.attributes, :bindings, []))
  end

  @spec interactions(Element.t() | map() | keyword()) :: list()
  def interactions(input) do
    input
    |> walk()
    |> Enum.flat_map(&Map.get(&1.attributes, :interactions, []))
  end

  @spec attachments(Element.t() | map() | keyword()) :: [map()]
  def attachments(input) do
    input
    |> walk()
    |> Enum.map(fn element ->
      %{
        id: element.id,
        type: element.type,
        kind: element.kind,
        attachments:
          Map.take(element.attributes, [
            :style,
            :theme,
            :interactions,
            :bindings,
            :interaction_scope
          ])
      }
    end)
  end

  @spec runtime_safe?(Element.t() | map() | keyword()) :: boolean()
  def runtime_safe?(input) do
    case Normalize.element(input) do
      {:ok, element} -> Validate.element(element) == :ok
      {:error, _errors} -> false
    end
  end

  @spec compatibility_report(Element.t() | map() | keyword()) :: map()
  def compatibility_report(input) do
    case Normalize.element(input) do
      {:ok, element} ->
        case Validate.element(element) do
          :ok ->
            %{
              valid?: true,
              runtime_safe?: true,
              consumers: runtime_consumers(),
              identity: identity(element),
              issues: []
            }

          {:error, errors} ->
            %{
              valid?: false,
              runtime_safe?: false,
              consumers: runtime_consumers(),
              identity: identity(element),
              issues: format_issues(errors)
            }
        end

      {:error, errors} ->
        %{
          valid?: false,
          runtime_safe?: false,
          consumers: runtime_consumers(),
          identity: nil,
          issues: format_issues(errors)
        }
    end
  end

  defp filter_by_type(input, type) do
    input
    |> walk()
    |> Enum.filter(&(&1.type == type))
  end

  defp format_issues(errors) do
    Enum.map(errors, fn
      %Error{} = error -> %{code: error.code, message: Error.format(error), path: error.path}
      error -> %{code: :unknown, message: inspect(error), path: []}
    end)
  end
end
