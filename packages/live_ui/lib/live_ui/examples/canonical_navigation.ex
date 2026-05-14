defmodule LiveUi.Examples.CanonicalNavigation do
  @moduledoc """
  Baseline canonical navigation example.
  """

  alias UnifiedIUR.Layout
  alias UnifiedIUR.Widgets.Navigation

  def element do
    Layout.column([
      Navigation.menu(
        [
          %{id: "details", label: "Details", active?: true},
          %{id: "activity", label: "Activity"}
        ],
        active_item: "details"
      ),
      Navigation.tabs(
        [
          %{id: "details", label: "Details", active?: true},
          %{id: "activity", label: "Activity"}
        ],
        active_item: "details"
      )
    ])
  end

  def metadata do
    %{
      id: :canonical_navigation,
      title: "Canonical Navigation",
      families: [:navigation],
      comparable_to: :native_navigation,
      summary: "Canonical foundational navigation workflow."
    }
  end
end
