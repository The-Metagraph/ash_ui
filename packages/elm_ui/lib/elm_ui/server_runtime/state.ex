defmodule ElmUi.ServerRuntime.State do
  @moduledoc """
  Server-authoritative runtime state for `elm_ui`.
  """

  alias UnifiedIUR.Element
  alias ElmUi.Widget
  alias ElmUi.ServerRuntime.Navigation

  @type boundary_mode :: :native_local | :canonical_boundary
  @type t :: %__MODULE__{
          runtime_id: String.t(),
          source_kind: :native | :canonical,
          title: String.t(),
          screen_id: String.t() | atom(),
          rendered_tree: Widget.t(),
          canonical_element: Element.t() | nil,
          boundary_mode: boundary_mode(),
          diagnostics: [map()],
          event_log: [map()],
          last_boundary_signal: Jido.Signal.t() | nil,
          navigation: Navigation.t(),
          metadata: map()
        }

  defstruct runtime_id: "web-ui-runtime",
            source_kind: :native,
            title: "",
            screen_id: nil,
            rendered_tree: %Widget{},
            canonical_element: nil,
            boundary_mode: :native_local,
            diagnostics: [],
            event_log: [],
            last_boundary_signal: nil,
            navigation: %{},
            metadata: %{}

  @spec record_event(t(), map()) :: t()
  def record_event(%__MODULE__{} = state, event) when is_map(event) do
    %{state | event_log: state.event_log ++ [event]}
  end

  @spec record_boundary_signal(t(), Jido.Signal.t()) :: t()
  def record_boundary_signal(%__MODULE__{} = state, signal) do
    %{state | last_boundary_signal: signal}
  end

  @spec record_diagnostic(t(), map()) :: t()
  def record_diagnostic(%__MODULE__{} = state, diagnostic) when is_map(diagnostic) do
    %{state | diagnostics: state.diagnostics ++ [diagnostic]}
  end

  @spec navigation_summary(t()) :: map()
  def navigation_summary(%__MODULE__{navigation: navigation}) do
    Navigation.summary(navigation)
  end
end
