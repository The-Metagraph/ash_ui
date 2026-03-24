defmodule BasicDashboard.AdapterRunner do
  @moduledoc """
  Renders the basic dashboard example through a specific Ash UI adapter.
  """

  alias AshUI.Compiler
  alias AshUI.Config
  alias AshUI.Rendering.DesktopUIAdapter
  alias AshUI.Rendering.ElmUIAdapter
  alias AshUI.Rendering.IURAdapter
  alias AshUI.Rendering.LiveUIAdapter
  alias AshUI.Rendering.Registry

  @renderers [:liveview, :elm, :desktop]

  @type renderer :: :liveview | :elm | :desktop
  @type render_result :: %{
          renderer: renderer(),
          adapter_module: module(),
          selected_module: module(),
          mode: :external | :adapter_fallback | :unavailable,
          canonical_iur: map(),
          output: String.t() | map(),
          runtime: map(),
          screen: struct()
        }

  @spec supported_renderers() :: [renderer()]
  def supported_renderers, do: @renderers

  @spec render(renderer(), keyword()) :: {:ok, render_result()} | {:error, term()}
  def render(renderer, opts \\ [])

  def render(renderer, opts) when renderer in @renderers do
    with_example_env(fn ->
      with {:ok, _started} <- Application.ensure_all_started(:ash_ui),
           {:ok, info} <- renderer_info(renderer, opts),
           runtime <- BasicDashboard.Data.seed!(),
           screen <- BasicDashboard.seed!(),
           {:ok, iur} <- Compiler.compile(screen, ui_storage: Config.ui_storage()),
           {:ok, canonical_iur} <- IURAdapter.to_canonical(iur),
           {:ok, output} <-
             render_with_adapter(renderer, canonical_iur, render_opts(renderer, opts)) do
        {:ok,
         %{
           renderer: renderer,
           adapter_module: adapter_module(renderer),
           selected_module: info.module,
           mode: info.mode,
           canonical_iur: canonical_iur,
           output: output,
           runtime: runtime,
           screen: screen
         }}
      end
    end)
  end

  def render(renderer, _opts), do: {:error, {:invalid_renderer, renderer}}

  @spec render_many([renderer()], keyword()) ::
          {:ok, %{renderer() => render_result()}} | {:error, term()}
  def render_many(renderers, opts \\ [])

  def render_many(renderers, opts) when is_list(renderers) do
    with {:ok, normalized_renderers} <- normalize_renderers(renderers) do
      with_example_env(fn ->
        with {:ok, _started} <- Application.ensure_all_started(:ash_ui),
             {:ok, renderer_info} <- renderer_info_map(normalized_renderers, opts),
             runtime <- BasicDashboard.Data.seed!(),
             screen <- BasicDashboard.seed!(),
             {:ok, iur} <- Compiler.compile(screen, ui_storage: Config.ui_storage()),
             {:ok, canonical_iur} <- IURAdapter.to_canonical(iur),
             {:ok, outputs} <- render_outputs(normalized_renderers, canonical_iur, opts) do
          {:ok,
           Enum.reduce(normalized_renderers, %{}, fn renderer, acc ->
             info = Map.fetch!(renderer_info, renderer)
             output = Map.fetch!(outputs, renderer)

             Map.put(acc, renderer, %{
               renderer: renderer,
               adapter_module: adapter_module(renderer),
               selected_module: info.module,
               mode: info.mode,
               canonical_iur: canonical_iur,
               output: output,
               runtime: runtime,
               screen: screen
             })
           end)}
        end
      end)
    end
  end

  def render_many(_renderers, _opts), do: {:error, {:invalid_renderers, :not_a_list}}

  @spec format_output(render_result(), keyword()) :: String.t()
  def format_output(%{renderer: :desktop, output: output}, opts) when is_map(output) do
    pretty? = Keyword.get(opts, :pretty, true)
    Jason.encode!(output, pretty: pretty?)
  end

  def format_output(%{output: output}, _opts) when is_binary(output), do: output

  def format_output(%{output: output}, _opts) do
    inspect(output, pretty: true, limit: :infinity)
  end

  @spec example_ui_storage() :: keyword()
  def example_ui_storage do
    BasicDashboard.Storage.config()
  end

  @spec example_runtime_domains() :: [module()]
  def example_runtime_domains do
    [BasicDashboard.Domain]
  end

  defp renderer_info(renderer, opts) do
    registry_opts =
      if Keyword.get(opts, :strict_external, false) do
        [allow_adapter_fallback: false]
      else
        []
      end

    with {:ok, info} <- Registry.renderer_info(renderer, registry_opts),
         true <- info.renderable or {:error, {:renderer_not_available, renderer}} do
      {:ok, info}
    end
  end

  defp renderer_info_map(renderers, opts) do
    Enum.reduce_while(renderers, {:ok, %{}}, fn renderer, {:ok, acc} ->
      case renderer_info(renderer, opts) do
        {:ok, info} -> {:cont, {:ok, Map.put(acc, renderer, info)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp render_opts(renderer, opts) do
    configured =
      Application.get_env(:ash_ui, :rendering, [])
      |> Keyword.get(:renderers, %{})
      |> Map.get(renderer, [])

    configured ++ Keyword.get(opts, :render_opts, [])
  end

  defp render_outputs(renderers, canonical_iur, opts) do
    Enum.reduce_while(renderers, {:ok, %{}}, fn renderer, {:ok, acc} ->
      case render_with_adapter(renderer, canonical_iur, render_opts(renderer, opts)) do
        {:ok, output} -> {:cont, {:ok, Map.put(acc, renderer, output)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp render_with_adapter(:liveview, canonical_iur, opts) do
    LiveUIAdapter.render(canonical_iur, opts)
  end

  defp render_with_adapter(:elm, canonical_iur, opts) do
    ElmUIAdapter.render(canonical_iur, opts)
  end

  defp render_with_adapter(:desktop, canonical_iur, opts) do
    DesktopUIAdapter.render(canonical_iur, opts)
  end

  defp adapter_module(:liveview), do: LiveUIAdapter
  defp adapter_module(:elm), do: ElmUIAdapter
  defp adapter_module(:desktop), do: DesktopUIAdapter

  defp normalize_renderers(renderers) do
    normalized =
      renderers
      |> Enum.uniq()

    case Enum.find(normalized, &(&1 not in @renderers)) do
      nil -> {:ok, normalized}
      invalid -> {:error, {:invalid_renderer, invalid}}
    end
  end

  defp with_example_env(fun) when is_function(fun, 0) do
    previous_ui_storage = Application.get_env(:ash_ui, :ui_storage)
    previous_domains = Application.get_env(:ash_ui, :ash_domains)

    try do
      Application.put_env(:ash_ui, :ui_storage, example_ui_storage())
      Application.put_env(:ash_ui, :ash_domains, example_runtime_domains())
      fun.()
    after
      Application.put_env(:ash_ui, :ui_storage, previous_ui_storage)
      Application.put_env(:ash_ui, :ash_domains, previous_domains)
    end
  end
end
