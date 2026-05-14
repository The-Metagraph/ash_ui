defmodule LiveUi.Examples.CanonicalForm do
  @moduledoc """
  Baseline canonical form example.
  """

  alias UnifiedIUR.Forms
  alias UnifiedIUR.Widgets.Input

  def element do
    Forms.form_builder(
      [
        Forms.field_group(
          [
            Forms.field(
              Input.text_input(name: "name", value: "Pascal"),
              id: "name-field",
              name: "name",
              label: "Name"
            )
          ],
          legend: "Identity"
        )
      ],
      id: "canonical-form"
    )
  end

  def metadata do
    %{
      id: :canonical_form,
      title: "Canonical Form",
      families: [:input, :forms],
      comparable_to: :native_form,
      summary: "Canonical foundational form workflow."
    }
  end
end
