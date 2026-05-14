defmodule DesktopUi.Runtime.Error do
  @moduledoc """
  Runtime diagnostics for `desktop_ui`.
  """

  @enforce_keys [:reason]
  defstruct [:reason, details: %{}, phase: :runtime_boot]

  @type t :: %__MODULE__{
          reason: atom(),
          details: map(),
          phase: atom()
        }

  @spec new(atom(), map(), atom()) :: t()
  def new(reason, details \\ %{}, phase \\ :runtime_boot)
      when is_atom(reason) and is_map(details) and is_atom(phase) do
    %__MODULE__{reason: reason, details: details, phase: phase}
  end
end
