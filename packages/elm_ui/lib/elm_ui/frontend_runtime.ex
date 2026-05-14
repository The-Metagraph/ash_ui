defmodule ElmUi.FrontendRuntime do
  @moduledoc """
  Elm-facing frontend runtime scaffold for `elm_ui`.
  """

  alias ElmUi.FrontendRuntime.{Boot, Bridge, Error, Message, Model, Realization, StyleRealization}

  @spec modules() :: [module()]
  def modules do
    [__MODULE__, Boot, Bridge, Message, Model, Realization, StyleRealization, Error]
  end

  @spec capabilities() :: [atom()]
  def capabilities do
    [
      :elm_bootstrap,
      :bounded_local_state,
      :bridge_translation,
      :bounded_browser_event_dispatch,
      :server_acknowledgement_handling,
      :foundational_realization,
      :style_realization
    ]
  end

  @spec hydrate(map()) :: {:ok, Model.t()} | {:error, Error.t()}
  def hydrate(payload) when is_map(payload) do
    Boot.hydrate(payload)
  end

  @spec dispatch_interaction(Model.t(), keyword() | map()) ::
          {:ok, Model.t(), map()} | {:error, Error.t() | term()}
  def dispatch_interaction(%Model{} = model, attrs) do
    Bridge.dispatch_interaction(model, attrs)
  end

  @spec apply_server_message(Model.t(), map()) :: {:ok, Model.t()} | {:error, Error.t()}
  def apply_server_message(%Model{} = model, payload) do
    Bridge.apply_server_message(model, payload)
  end

  @spec put_local_state(Model.t(), atom(), term()) :: {:ok, Model.t()}
  def put_local_state(%Model{} = model, key, value) do
    {:ok, Model.put_local_state(model, key, value)}
  end
end
