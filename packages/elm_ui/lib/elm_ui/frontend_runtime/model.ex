defmodule ElmUi.FrontendRuntime.Model do
  @moduledoc """
  Bounded browser-side runtime model for `elm_ui`.
  """

  @type tree :: map()
  @type t :: %__MODULE__{
          runtime_id: String.t(),
          screen_id: String.t() | atom() | nil,
          title: String.t(),
          source_kind: :native | :canonical,
          boundary_mode: :native_local | :canonical_boundary,
          render_tree: tree(),
          tree: tree(),
          local_state: map(),
          diagnostics: [map()],
          metadata: map()
        }

  defstruct runtime_id: "",
            screen_id: nil,
            title: "",
            source_kind: :native,
            boundary_mode: :native_local,
            render_tree: %{},
            tree: %{},
            local_state: %{focused_id: nil, editing_ids: [], flash: nil},
            diagnostics: [],
            metadata: %{}

  @spec put_local_state(t(), atom(), term()) :: t()
  def put_local_state(%__MODULE__{} = model, key, value) do
    local_state = Map.put(model.local_state, key, value)

    %{
      model
      | local_state: local_state,
        tree: ElmUi.FrontendRuntime.Realization.realize(model.render_tree, local_state)
    }
  end
end
