defmodule ElmUi.ServerRuntime.ViewState do
  @moduledoc """
  Phoenix-to-Elm hydration payload generation.
  """

  alias ElmUi.ServerRuntime.{RenderModel, State}

  @spec to_frontend_payload(State.t()) :: map()
  def to_frontend_payload(%State{} = state) do
    %{
      runtime_id: state.runtime_id,
      screen_id: state.screen_id,
      title: state.title,
      source_kind: state.source_kind,
      boundary_mode: state.boundary_mode,
      tree:
        RenderModel.build(state.rendered_tree, theme: Map.get(state.metadata, :theme, :default)),
      local_state: %{
        focused_id: nil,
        editing_ids: [],
        flash: nil
      },
      diagnostics: state.diagnostics,
      metadata:
        state.metadata
        |> Map.put(:navigation, State.navigation_summary(state))
    }
  end

  @spec authoritative_screen_payload(State.t()) :: map()
  def authoritative_screen_payload(%State{} = state) do
    ElmUi.ServerRuntime.Navigation.authoritative_screen_payload(state)
  end
end
