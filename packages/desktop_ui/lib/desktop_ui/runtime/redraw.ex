defmodule DesktopUi.Runtime.Redraw do
  @moduledoc """
  Redraw coordination scaffold for the shared SDL3 runtime loop.
  """

  @spec scaffold() :: map()
  def scaffold do
    %{
      status: :idle,
      requests: 0,
      last_reason: nil
    }
  end

  @spec request(map(), atom()) :: map()
  def request(state, reason) when is_map(state) and is_atom(reason) do
    state
    |> Map.update!(:requests, &(&1 + 1))
    |> Map.put(:status, :requested)
    |> Map.put(:last_reason, reason)
  end
end
