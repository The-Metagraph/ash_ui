defmodule LiveUi.Screen.Definition do
  @moduledoc """
  Summary of a native `live_ui` screen contract.
  """

  @enforce_keys [:module, :id, :title]
  defstruct [
    :module,
    :id,
    :title,
    mount_defaults: %{},
    metadata: %{},
    event_routes: %{},
    bridge_hooks: []
  ]

  @type t :: %__MODULE__{
          module: module(),
          id: atom(),
          title: String.t(),
          mount_defaults: map(),
          metadata: map(),
          event_routes: %{optional(String.t()) => atom()},
          bridge_hooks: [atom()]
        }
end
