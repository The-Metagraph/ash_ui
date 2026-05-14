defmodule DesktopUi.Runtime.Shutdown do
  @moduledoc """
  Shutdown handling scaffold for `desktop_ui`.
  """

  alias DesktopUi.Runtime.{Error, State}

  @spec stop(State.t()) :: {:ok, State.t()} | {:error, Error.t()}
  def stop(%State{} = runtime_state) do
    if get_in(runtime_state.lifecycle, [:runtime]) == :ready do
      {:ok,
       %{
         runtime_state
         | lifecycle: %{runtime_state.lifecycle | runtime: :stopped, shutdown: :completed}
       }}
    else
      {:error,
       Error.new(
         :invalid_shutdown_state,
         %{lifecycle: runtime_state.lifecycle},
         :runtime_shutdown
       )}
    end
  end
end
