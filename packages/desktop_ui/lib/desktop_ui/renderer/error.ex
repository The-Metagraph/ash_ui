defmodule DesktopUi.Renderer.Error do
  @moduledoc """
  Renderer diagnostics for `desktop_ui`.
  """

  @enforce_keys [:reason]
  defstruct [:reason, details: %{}]

  @type t :: %__MODULE__{
          reason: atom(),
          details: map()
        }

  @spec new(atom(), map()) :: t()
  def new(reason, details \\ %{}) when is_atom(reason) and is_map(details) do
    %__MODULE__{reason: reason, details: details}
  end
end
