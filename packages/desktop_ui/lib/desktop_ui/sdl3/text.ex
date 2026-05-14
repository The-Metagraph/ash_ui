defmodule DesktopUi.Sdl3.Text do
  @moduledoc """
  SDL_ttf-first text resource seam for the SDL3 adapter boundary.
  """

  alias DesktopUi.Sdl3.Capabilities

  @spec contract() :: map()
  def contract do
    %{
      backend: :sdl_ttf_equivalent,
      capabilities: [
        :font_selection,
        :text_measurement,
        :text_surface_preparation,
        :texture_caching
      ],
      host_caching: true,
      future_platform_text_allowed: true
    }
  end

  @spec validation_state() :: atom()
  def validation_state, do: :text_resource_ready

  @spec native_support(map()) :: map()
  def native_support(capabilities \\ Capabilities.detect()) do
    library = get_in(capabilities, [:libraries, :sdl3_ttf]) || %{}
    probe = get_in(capabilities, [:build, :executable_probe]) || %{}
    native_backend_ready? = get_in(capabilities, [:build, :native_text_ready?]) || false
    available_on_rebuild? = Map.get(library, :available?, false)

    %{
      library: :sdl3_ttf,
      pkg_config_package: Map.get(library, :package),
      native_backend_ready?: native_backend_ready?,
      available_on_rebuild?: available_on_rebuild?,
      active_mode:
        if(native_backend_ready?,
          do: :native_companion_library,
          else: :elixir_measurement_fallback
        ),
      measurement_mode:
        if(native_backend_ready?, do: :sdl3_ttf_measurement, else: :elixir_measurement_fallback),
      texture_cache:
        if(native_backend_ready?, do: :compiled_host_texture_cache, else: :no_native_cache),
      host_probe_mode: Map.get(probe, :text_mode),
      fallback_mode: :elixir_measurement_fallback,
      requests_bounded_when_missing?: true
    }
  end

  @spec prepare(String.t(), keyword()) :: {:ok, map()} | {:error, map()}
  def prepare(content, opts \\ [])

  def prepare(content, opts) when is_binary(content) do
    font = Keyword.get(opts, :font, "default-ui")
    size = Keyword.get(opts, :size, 14)
    weight = Keyword.get(opts, :weight, :regular)

    {:ok,
     %{
       backend: :sdl_ttf_equivalent,
       content: content,
       font: font,
       size: size,
       weight: weight,
       cache_key: cache_key(content, opts),
       measurement: measure(content, opts),
       validation_state: validation_state()
     }}
  end

  def prepare(content, _opts), do: {:error, %{reason: :invalid_text_content, content: content}}

  @spec cache_key(String.t(), keyword()) :: String.t()
  def cache_key(content, opts \\ []) when is_binary(content) do
    font = Keyword.get(opts, :font, "default-ui")
    size = Keyword.get(opts, :size, 14)
    weight = Keyword.get(opts, :weight, :regular)

    "text:#{font}:#{size}:#{weight}:#{:erlang.phash2(content)}"
  end

  @spec measure(String.t(), keyword()) :: map()
  def measure(content, opts \\ []) when is_binary(content) do
    size = Keyword.get(opts, :size, 14)

    %{
      width: max(String.length(content), 1) * max(div(size, 2), 1),
      height: size + 4,
      units: :logical
    }
  end
end
