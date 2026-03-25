defmodule UnifiedIUR.Element.Child do
  @moduledoc """
  Canonical child-slot wrapper for nested `UnifiedIUR.Element` values.

  Child slots allow leaf, single-child, multi-child, and optional-empty child
  relationships to share one consistent representation.
  """

  @type slot :: atom() | String.t()

  @type t :: %__MODULE__{
          slot: slot(),
          element: UnifiedIUR.Element.t() | nil
        }

  defstruct slot: :default, element: nil

  @spec new(slot(), UnifiedIUR.Element.t() | nil) :: t()
  def new(slot \\ :default, element) when is_atom(slot) or is_binary(slot) do
    %__MODULE__{slot: slot, element: element}
  end

  @spec empty(slot()) :: t()
  def empty(slot \\ :default) do
    new(slot, nil)
  end

  @spec present?(t()) :: boolean()
  def present?(%__MODULE__{element: nil}), do: false
  def present?(%__MODULE__{}), do: true
end
