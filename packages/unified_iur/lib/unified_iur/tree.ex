defmodule UnifiedIUR.Tree do
  @moduledoc """
  Pure traversal and immutable transformation helpers for canonical IUR trees.
  """

  alias UnifiedIUR.Element
  alias UnifiedIUR.Element.Child

  @spec depth_first(Element.t()) :: [Element.t()]
  def depth_first(%Element{} = root) do
    [root | Enum.flat_map(root.children, &depth_first_child/1)]
  end

  @spec breadth_first(Element.t()) :: [Element.t()]
  def breadth_first(%Element{} = root) do
    do_breadth_first([root], [])
  end

  @spec map(Element.t(), (Element.t() -> Element.t())) :: Element.t()
  def map(%Element{} = root, fun) when is_function(fun, 1) do
    mapped_children =
      Enum.map(root.children, fn %Child{slot: slot, element: child} ->
        %Child{slot: slot, element: map_child(child, fun)}
      end)

    root
    |> Map.put(:children, mapped_children)
    |> fun.()
  end

  @spec update(Element.t(), String.t() | atom(), (Element.t() -> Element.t())) :: Element.t()
  def update(%Element{} = root, id, fun) when is_function(fun, 1) do
    map(root, fn element ->
      if element.id == id, do: fun.(element), else: element
    end)
  end

  @spec find_by_id(Element.t(), String.t() | atom()) :: Element.t() | nil
  def find_by_id(%Element{} = root, id) do
    Enum.find(depth_first(root), &(&1.id == id))
  end

  @spec find_by_type(Element.t(), Element.element_type()) :: [Element.t()]
  def find_by_type(%Element{} = root, type) do
    Enum.filter(depth_first(root), &(&1.type == type))
  end

  @spec shape_signature(Element.t()) :: map()
  def shape_signature(%Element{} = root) do
    %{
      type: root.type,
      kind: root.kind,
      child_shape: Element.child_shape(root),
      slots:
        Enum.map(root.children, fn %Child{slot: slot, element: child} ->
          %{
            slot: slot,
            present?: not is_nil(child),
            child: if(child, do: shape_signature(child), else: nil)
          }
        end)
    }
  end

  defp depth_first_child(%Child{element: nil}), do: []
  defp depth_first_child(%Child{element: %Element{} = child}), do: depth_first(child)

  defp do_breadth_first([], acc), do: Enum.reverse(acc)

  defp do_breadth_first([%Element{} = current | rest], acc) do
    children =
      current.children
      |> Enum.map(& &1.element)
      |> Enum.reject(&is_nil/1)

    do_breadth_first(rest ++ children, [current | acc])
  end

  defp map_child(nil, _fun), do: nil
  defp map_child(%Element{} = child, fun), do: map(child, fun)
end
