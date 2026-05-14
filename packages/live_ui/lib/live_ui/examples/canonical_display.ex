defmodule LiveUi.Examples.CanonicalDisplay do
  @moduledoc """
  Baseline canonical display example.
  """

  alias UnifiedIUR.{Container, Layout}
  alias UnifiedIUR.Widgets.Foundational

  def element do
    Container.box(
      [
        Layout.column([
          Foundational.label("Status", label: %{for: "status-value"}),
          Foundational.text("online", id: "status-value", style: %{emphasis: %{tone: :positive}}),
          Foundational.button("Refresh")
        ])
      ],
      id: "canonical-display"
    )
  end

  def metadata do
    %{
      id: :canonical_display,
      title: "Canonical Display",
      families: [:content, :layout],
      comparable_to: :native_display,
      summary: "Canonical foundational display workflow."
    }
  end
end
