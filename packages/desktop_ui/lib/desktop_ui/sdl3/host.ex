defmodule DesktopUi.Sdl3.Host do
  @moduledoc """
  Behaviour and shared contract for SDL3-native host process ownership.
  """

  alias DesktopUi.Runtime.Error

  @type session :: term()
  @type status :: map()
  @type launch_spec :: map()

  @callback contract() :: map()
  @callback validation_state() :: atom()
  @callback launch_spec(keyword()) :: launch_spec()
  @callback launch(keyword()) :: {:ok, session()} | {:error, Error.t()}
  @callback status(session()) :: status()
  @callback send_message(session(), map()) :: {:ok, session()} | {:error, Error.t()}
  @callback recv_message(session(), timeout()) ::
              {:ok, map(), session()} | {:error, Error.t()}
  @callback shutdown(session()) :: {:ok, session()} | {:error, Error.t()}
end
