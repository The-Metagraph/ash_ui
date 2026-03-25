defmodule UnifiedIUR.Element do
  @moduledoc """
  Canonical base element model for all `unified_iur` construct families.

  The element model captures stable identity, type information, descriptive
  metadata, construct-specific attributes, and child slots in one pure value.
  """

  alias UnifiedIUR.Element.Child
  alias UnifiedIUR.Metadata

  @type element_type ::
          :widget
          | :layout
          | :layer
          | :style
          | :theme
          | :interaction
          | :composite
          | atom()

  @type element_kind :: atom() | String.t()

  @type t :: %__MODULE__{
          id: String.t() | atom() | nil,
          type: element_type(),
          kind: element_kind(),
          metadata: Metadata.t(),
          attributes: map(),
          children: [Child.t()]
        }

  defstruct id: nil,
            type: :widget,
            kind: nil,
            metadata: nil,
            attributes: %{},
            children: []

  @spec new(element_type(), element_kind(), keyword() | map()) :: t()
  def new(type, kind, attrs \\ %{}) when is_atom(type) and (is_atom(kind) or is_binary(kind)) do
    attrs = normalize_attrs(attrs)

    %__MODULE__{
      id: Map.get(attrs, :id),
      type: type,
      kind: kind,
      metadata: attrs |> Map.get(:metadata) |> Metadata.new(),
      attributes: attrs |> Map.get(:attributes, %{}) |> normalize_map(),
      children: attrs |> Map.get(:children, []) |> normalize_children()
    }
  end

  @spec merge_metadata(t(), Metadata.t() | map() | keyword() | nil) :: t()
  def merge_metadata(%__MODULE__{} = element, metadata) do
    %{element | metadata: Metadata.merge(element.metadata, metadata)}
  end

  @spec put_children(t(), [Child.t() | t() | {Child.slot(), t() | nil} | map()]) :: t()
  def put_children(%__MODULE__{} = element, children) do
    %{element | children: normalize_children(children)}
  end

  @spec put_attribute(t(), term(), term()) :: t()
  def put_attribute(%__MODULE__{} = element, key, value) do
    %{element | attributes: Map.put(element.attributes, key, value)}
  end

  @spec put_id(t(), String.t() | atom() | nil) :: t()
  def put_id(%__MODULE__{} = element, id) do
    %{element | id: id}
  end

  @spec child_shape(t()) :: :leaf | :single | :multi
  def child_shape(%__MODULE__{children: []}), do: :leaf
  def child_shape(%__MODULE__{children: [_]}), do: :single
  def child_shape(%__MODULE__{}), do: :multi

  @spec children_for_slot(t(), Child.slot()) :: [Child.t()]
  def children_for_slot(%__MODULE__{} = element, slot) do
    Enum.filter(element.children, &(&1.slot == slot))
  end

  defp normalize_attrs(attrs) when is_list(attrs), do: Enum.into(attrs, %{})
  defp normalize_attrs(attrs) when is_map(attrs), do: Map.new(attrs)

  defp normalize_map(nil), do: %{}
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp normalize_children(nil), do: []

  defp normalize_children(children) when is_list(children) do
    Enum.map(children, &normalize_child/1)
  end

  defp normalize_child(%Child{} = child), do: child

  defp normalize_child({slot, element}) when is_atom(slot) or is_binary(slot),
    do: Child.new(slot, element)

  defp normalize_child(%{slot: slot, element: element}) when is_atom(slot) or is_binary(slot) do
    Child.new(slot, element)
  end

  defp normalize_child(%{"slot" => slot, "element" => element})
       when is_atom(slot) or is_binary(slot) do
    Child.new(slot, element)
  end

  defp normalize_child(%__MODULE__{} = element), do: Child.new(:default, element)
end
