defmodule ElmUi.FrontendRuntime.Error do
  @moduledoc """
  Deterministic frontend runtime diagnostics.
  """

  defexception [:reason, :message, details: %{}]

  @type t :: %__MODULE__{
          reason: atom(),
          message: String.t(),
          details: map()
        }

  @spec new(atom(), String.t(), map()) :: t()
  def new(reason, message, details \\ %{}) do
    %__MODULE__{reason: reason, message: message, details: details}
  end
end
