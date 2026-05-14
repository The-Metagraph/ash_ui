defmodule LiveUi.Forms do
  @moduledoc """
  Reference surface for native `live_ui` form composition helpers.
  """

  @modules [
    LiveUi.Forms.FormBuilder,
    LiveUi.Forms.FieldGroup,
    LiveUi.Forms.Field
  ]

  @spec modules() :: [module()]
  def modules do
    @modules
  end
end
