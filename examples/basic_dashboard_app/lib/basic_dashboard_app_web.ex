defmodule BasicDashboardAppWeb do
  @moduledoc """
  Web interface entrypoint for the standalone basic dashboard app.
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

      import Phoenix.Controller,
        only: [
          get_csrf_token: 0,
          view_module: 1,
          view_template: 1
        ]

      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      alias Phoenix.LiveView.JS
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
