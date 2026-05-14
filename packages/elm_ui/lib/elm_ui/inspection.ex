defmodule ElmUi.Inspection do
  @moduledoc """
  Package and runtime inspection helpers for `elm_ui`.
  """

  alias ElmUi.FrontendRuntime
  alias ElmUi.FrontendRuntime.Model
  alias ElmUi.ServerRuntime
  alias ElmUi.ServerRuntime.State

  @spec helpers() :: [atom()]
  def helpers do
    [:package_overview, :runtime_snapshot, :server_style_nodes, :frontend_style_nodes]
  end

  @spec package_overview() :: map()
  def package_overview do
    %{
      widgets: %{
        families: ElmUi.Widgets.families(),
        kinds: ElmUi.Widgets.kinds()
      },
      style: %{
        primitives: Map.keys(ElmUi.Style.primitives()),
        hooks: ElmUi.Style.widget_style_hooks(),
        responsibilities: ElmUi.Style.responsibilities()
      },
      theme: %{
        catalog: ElmUi.Theme.catalog_ids(),
        default: ElmUi.Theme.default_theme().id,
        continuity_rules: ElmUi.Theme.continuity_rules()
      },
      renderer: %{
        accepts: ElmUi.Renderer.accepts(),
        supported_kinds: ElmUi.Renderer.supported_kinds(),
        responsibilities: ElmUi.Renderer.responsibilities()
      },
      runtime: %{
        capabilities: ElmUi.Runtime.capabilities(),
        assumptions: ElmUi.Runtime.assumptions(),
        server_modules: ElmUi.Server.modules(),
        frontend_modules: ElmUi.Frontend.modules()
      }
    }
  end

  @spec runtime_snapshot(State.t(), map()) :: {:ok, map()} | {:error, term()}
  def runtime_snapshot(%State{} = state, local_state_override \\ %{})
      when is_map(local_state_override) do
    payload = ServerRuntime.frontend_payload(state)
    local_state = Map.merge(payload.local_state, local_state_override)

    with {:ok, frontend_model} <- FrontendRuntime.hydrate(%{payload | local_state: local_state}) do
      {:ok, snapshot(state, payload.tree, frontend_model)}
    end
  end

  @spec server_style_nodes(map()) :: [map()]
  def server_style_nodes(tree) when is_map(tree) do
    collect_server_nodes(tree)
  end

  @spec frontend_style_nodes(map()) :: [map()]
  def frontend_style_nodes(tree) when is_map(tree) do
    collect_frontend_nodes(tree)
  end

  defp snapshot(%State{} = state, server_tree, %Model{} = frontend_model) do
    server_nodes = server_style_nodes(server_tree)
    frontend_nodes = frontend_style_nodes(frontend_model.tree)

    %{
      runtime: %{
        runtime_id: state.runtime_id,
        screen_id: state.screen_id,
        source_kind: state.source_kind,
        boundary_mode: state.boundary_mode,
        theme: Map.get(state.metadata, :theme, :default)
      },
      server: %{
        node_count: length(server_nodes),
        themes: server_nodes |> Enum.map(& &1.theme) |> Enum.uniq() |> Enum.sort(),
        style_nodes: server_nodes,
        style_diagnostics: Enum.flat_map(server_nodes, & &1.style_diagnostics)
      },
      frontend: %{
        node_count: length(frontend_nodes),
        themes: frontend_nodes |> Enum.map(& &1.theme) |> Enum.uniq() |> Enum.sort(),
        style_nodes: frontend_nodes,
        focused_ids:
          frontend_nodes
          |> Enum.filter(& &1.behavior.focused?)
          |> Enum.map(& &1.id)
          |> Enum.sort()
      }
    }
  end

  defp collect_server_nodes(node) do
    [
      %{
        id: node.id,
        family: node.family,
        kind: node.kind,
        theme: get_in(node, [:theme, :id]),
        token_refs: get_in(node, [:theme, :token_refs]) || %{},
        active_states: get_in(node, [:theme, :active_states]) || [],
        resolved_styles: Map.get(node, :resolved_styles, %{}),
        style_diagnostics: get_in(node, [:diagnostics, :style_diagnostics]) || []
      }
    ] ++
      (node.slots
       |> Enum.flat_map(& &1.children)
       |> Enum.flat_map(&collect_server_nodes/1))
  end

  defp collect_frontend_nodes(node) do
    [
      %{
        id: node.id,
        kind: node.kind,
        tag: node.tag,
        theme: get_in(node, [:theme, :id]),
        resolved_styles: get_in(node, [:styles, :resolved]) || %{},
        browser_style: get_in(node, [:browser, :style]) || %{},
        behavior:
          Map.take(node.browser, [
            :interactive?,
            :focusable?,
            :editable?,
            :navigable?,
            :focused?,
            :editing?
          ]),
        style_diagnostics: get_in(node, [:diagnostics, :style_diagnostics]) || []
      }
    ] ++
      (node.slots
       |> Enum.flat_map(& &1.children)
       |> Enum.flat_map(&collect_frontend_nodes/1))
  end
end
