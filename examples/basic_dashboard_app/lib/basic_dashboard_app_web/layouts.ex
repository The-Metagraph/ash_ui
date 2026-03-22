defmodule BasicDashboardAppWeb.Layouts do
  @moduledoc """
  Root layouts for the standalone basic dashboard app.
  """

  use BasicDashboardAppWeb, :html

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={get_csrf_token()} />
        <title>Ash UI Basic Dashboard</title>
      </head>
      <body>
        {@inner_content}
      </body>
    </html>
    """
  end
end
