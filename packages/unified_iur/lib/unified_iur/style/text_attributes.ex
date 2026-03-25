defmodule UnifiedIUR.Style.TextAttributes do
  @moduledoc """
  Canonical text emphasis flags for portable `UnifiedIUR` styling.
  """

  @type t :: %__MODULE__{
          bold?: boolean(),
          dim?: boolean(),
          italic?: boolean(),
          underline?: boolean(),
          blink?: boolean(),
          reverse?: boolean(),
          hidden?: boolean(),
          strikethrough?: boolean()
        }

  defstruct bold?: false,
            dim?: false,
            italic?: false,
            underline?: false,
            blink?: false,
            reverse?: false,
            hidden?: false,
            strikethrough?: false

  @spec new(keyword() | map() | t() | nil) :: t()
  def new(nil), do: %__MODULE__{}
  def new(%__MODULE__{} = attributes), do: attributes
  def new(attributes) when is_list(attributes), do: attributes |> Enum.into(%{}) |> new()

  def new(attributes) when is_map(attributes) do
    %__MODULE__{
      bold?: fetch(attributes, :bold?, false),
      dim?: fetch(attributes, :dim?, false),
      italic?: fetch(attributes, :italic?, false),
      underline?: fetch(attributes, :underline?, false),
      blink?: fetch(attributes, :blink?, false),
      reverse?: fetch(attributes, :reverse?, false),
      hidden?: fetch(attributes, :hidden?, false),
      strikethrough?: fetch(attributes, :strikethrough?, false)
    }
  end

  @spec merge(t() | keyword() | map() | nil, t() | keyword() | map() | nil) :: t()
  def merge(left, right) do
    left = new(left)
    right = new(right)

    %__MODULE__{
      bold?: right.bold? || left.bold?,
      dim?: right.dim? || left.dim?,
      italic?: right.italic? || left.italic?,
      underline?: right.underline? || left.underline?,
      blink?: right.blink? || left.blink?,
      reverse?: right.reverse? || left.reverse?,
      hidden?: right.hidden? || left.hidden?,
      strikethrough?: right.strikethrough? || left.strikethrough?
    }
  end

  defp fetch(source, key, default) do
    Map.get(source, key, Map.get(source, Atom.to_string(key), default))
  end
end
