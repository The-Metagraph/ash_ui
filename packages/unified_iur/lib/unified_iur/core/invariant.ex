defmodule UnifiedIUR.Core.Invariant do
  @moduledoc """
  Baseline invariants for canonical `UnifiedIUR` core values.

  These helpers guard the package against runtime-library-native values and
  unstable child-shape semantics in the core interchange layer.
  """

  alias UnifiedIUR.Element
  alias UnifiedIUR.Element.Child
  alias UnifiedIUR.Metadata
  alias UnifiedIUR.Tree

  @runtime_native_prefixes ["Elixir.LiveUi", "Elixir.ElmUi", "Elixir.DesktopUi"]

  @spec canonical_element?(term()) :: boolean()
  def canonical_element?(%Element{} = element) do
    try do
      assert_canonical_element!(element)
      true
    rescue
      ArgumentError -> false
    end
  end

  def canonical_element?(_other), do: false

  @spec assert_canonical_element!(Element.t()) :: Element.t()
  def assert_canonical_element!(%Element{} = element) do
    unless match?(%Metadata{}, element.metadata) do
      raise ArgumentError, "canonical elements must carry UnifiedIUR.Metadata"
    end

    Enum.each(element.children, &assert_child!/1)
    assert_pure_term!(element.attributes)
    assert_pure_term!(element.metadata.annotations)
    assert_pure_term!(element.metadata.extra)

    element
  end

  @spec assert_shape_stable!(Element.t(), Element.t()) :: :ok
  def assert_shape_stable!(%Element{} = before, %Element{} = transformed) do
    if Tree.shape_signature(before) != Tree.shape_signature(transformed) do
      raise ArgumentError, "canonical tree shape changed unexpectedly"
    end

    :ok
  end

  @spec runtime_native_prefixes() :: [String.t()]
  def runtime_native_prefixes do
    @runtime_native_prefixes
  end

  defp assert_child!(%Child{element: nil}), do: :ok

  defp assert_child!(%Child{element: %Element{} = child}) do
    assert_canonical_element!(child)
    :ok
  end

  defp assert_child!(_other) do
    raise ArgumentError, "canonical children must use UnifiedIUR.Element.Child wrappers"
  end

  defp assert_pure_term!(term) when is_map(term) and not is_struct(term) do
    Enum.each(term, fn {key, value} ->
      assert_pure_term!(key)
      assert_pure_term!(value)
    end)

    :ok
  end

  defp assert_pure_term!(term) when is_list(term) do
    Enum.each(term, &assert_pure_term!/1)
    :ok
  end

  defp assert_pure_term!(%Element{} = element) do
    assert_canonical_element!(element)
    :ok
  end

  defp assert_pure_term!(%Metadata{} = metadata) do
    assert_pure_term!(metadata.annotations)
    assert_pure_term!(metadata.extra)
    :ok
  end

  defp assert_pure_term!(%Child{} = child) do
    assert_child!(child)
  end

  defp assert_pure_term!(%module{} = _term) do
    module_name = Atom.to_string(module)

    if Enum.any?(@runtime_native_prefixes, &String.starts_with?(module_name, &1)) do
      raise ArgumentError,
            "runtime-library-native structs are not allowed in canonical core values"
    end

    :ok
  end

  defp assert_pure_term!(_scalar), do: :ok
end
