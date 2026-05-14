defmodule LiveUi.Examples.CanonicalBoundaryProfile do
  @moduledoc """
  Maintained canonical example for `UnifiedIUR`-driven boundary translation.
  """

  alias UnifiedIUR.Forms
  alias UnifiedIUR.Interaction
  alias UnifiedIUR.Widgets.Input

  def element do
    Forms.form_builder(
      [
        Forms.field_group(
          [
            Forms.field(
              Input.text_input(
                id: "profile-name",
                name: "name",
                value: "Pascal",
                binding: %{name: :profile_name, path: [:profile, :name], default: "Pascal"},
                interaction: interaction()
              ),
              id: "profile-name-field",
              name: "name",
              label: "Name"
            )
          ],
          legend: "Identity"
        )
      ],
      id: "canonical-profile-form",
      binding: %{name: :profile_form_data, path: [:profile]},
      submission: [intent: :save_profile, binding: :profile_form_data]
    )
  end

  def interaction do
    Interaction.change(
      intent: :rename_profile,
      element_id: :profile_name,
      binding: :profile_name,
      mapping: %{name: :profile_name},
      phase: :change
    )
  end

  def boundary_event_example do
    [
      screen: :canonical_boundary,
      mode: :screen,
      boundary: :boundary,
      runtime_event: "rename",
      payload: %{"name" => "Ari"}
    ]
  end

  def translation do
    LiveUi.Transport.translate_canonical(interaction(), boundary_event_example())
  end

  def metadata do
    %{
      id: :canonical_boundary,
      title: "Canonical Boundary",
      families: [:transport, :change, :forms],
      comparable_to: :native_boundary,
      summary: "Canonical IUR example for boundary-safe event translation."
    }
  end
end
