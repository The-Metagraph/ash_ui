defmodule BasicDashboardExampleWeb do
  @moduledoc """
  Web entrypoint helpers for the standalone basic dashboard example app.
  """

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def html do
    quote do
      use Phoenix.Component

      import Phoenix.Controller, only: [get_csrf_token: 0]
    end
  end

  defmacro __using__(which) when is_atom(which) do
    case which do
      :router -> router()
      :html -> html()
      other -> raise ArgumentError, "unknown BasicDashboardExampleWeb helper: #{inspect(other)}"
    end
  end
end
