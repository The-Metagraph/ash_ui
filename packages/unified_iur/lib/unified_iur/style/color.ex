defmodule UnifiedIUR.Style.Color do
  @moduledoc """
  Canonical portable color values for `UnifiedIUR.Style`.
  """

  @type name :: atom() | String.t()

  @type t ::
          %{mode: :named, name: name()}
          | %{mode: :indexed, index: non_neg_integer()}
          | %{mode: :rgb, red: 0..255, green: 0..255, blue: 0..255}

  @spec named(name()) :: t()
  def named(name) when is_atom(name) or is_binary(name) do
    %{mode: :named, name: name}
  end

  @spec indexed(non_neg_integer()) :: t()
  def indexed(index) when is_integer(index) and index >= 0 do
    %{mode: :indexed, index: index}
  end

  @spec rgb(non_neg_integer(), non_neg_integer(), non_neg_integer()) :: t()
  def rgb(red, green, blue)
      when is_integer(red) and red in 0..255 and is_integer(green) and green in 0..255 and
             is_integer(blue) and blue in 0..255 do
    %{mode: :rgb, red: red, green: green, blue: blue}
  end

  @spec new(term()) :: t() | nil
  def new(nil), do: nil
  def new(%{mode: :named, name: name}) when is_atom(name) or is_binary(name), do: named(name)

  def new(%{"mode" => :named, "name" => name}) when is_atom(name) or is_binary(name),
    do: named(name)

  def new(%{mode: :indexed, index: index}) when is_integer(index) and index >= 0,
    do: indexed(index)

  def new(%{"mode" => :indexed, "index" => index}) when is_integer(index) and index >= 0,
    do: indexed(index)

  def new(%{mode: :rgb, red: red, green: green, blue: blue}),
    do: rgb(red, green, blue)

  def new(%{"mode" => :rgb, "red" => red, "green" => green, "blue" => blue}),
    do: rgb(red, green, blue)

  def new(name) when is_atom(name) or is_binary(name), do: named(name)

  def new({:indexed, index}) when is_integer(index) and index >= 0 do
    indexed(index)
  end

  def new({:rgb, red, green, blue}), do: rgb(red, green, blue)
end
