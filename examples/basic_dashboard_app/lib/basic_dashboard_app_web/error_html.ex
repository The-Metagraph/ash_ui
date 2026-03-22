defmodule BasicDashboardAppWeb.ErrorHTML do
  @moduledoc """
  Minimal HTML error rendering for the standalone basic dashboard app.
  """

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
