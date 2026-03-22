defmodule BasicDashboardAppSmokeTest do
  use ExUnit.Case, async: true

  test "router exposes the dashboard routes" do
    routes = BasicDashboardAppWeb.Router.__routes__()

    assert Enum.any?(routes, &(&1.path == "/"))
    assert Enum.any?(routes, &(&1.path == "/dashboard"))
  end
end
