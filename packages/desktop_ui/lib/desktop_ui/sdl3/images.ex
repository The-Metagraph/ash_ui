defmodule DesktopUi.Sdl3.Images do
  @moduledoc """
  SDL_image-first image resource seam for the SDL3 adapter boundary.
  """

  alias DesktopUi.Sdl3.Capabilities

  @spec contract() :: map()
  def contract do
    %{
      backend: :sdl_image_equivalent,
      capabilities: [:asset_decode, :surface_preparation, :texture_caching, :raw_pixel_fallback],
      host_caching: true,
      future_platform_image_allowed: true
    }
  end

  @spec validation_state() :: atom()
  def validation_state, do: :image_resource_ready

  @spec native_support(map()) :: map()
  def native_support(capabilities \\ Capabilities.detect()) do
    library = get_in(capabilities, [:libraries, :sdl3_image]) || %{}
    probe = get_in(capabilities, [:build, :executable_probe]) || %{}
    native_backend_ready? = get_in(capabilities, [:build, :native_image_ready?]) || false
    available_on_rebuild? = Map.get(library, :available?, false)

    %{
      library: :sdl3_image,
      pkg_config_package: Map.get(library, :package),
      native_backend_ready?: native_backend_ready?,
      available_on_rebuild?: available_on_rebuild?,
      active_mode:
        if(native_backend_ready?, do: :native_companion_library, else: :raw_pixel_fallback),
      decode_mode: if(native_backend_ready?, do: :sdl3_image_decode, else: :raw_pixel_fallback),
      texture_cache:
        if(native_backend_ready?, do: :compiled_host_texture_cache, else: :no_native_cache),
      host_probe_mode: Map.get(probe, :image_mode),
      fallback_mode: :raw_pixel_fallback,
      requests_bounded_when_missing?: true
    }
  end

  @spec prepare(String.t(), keyword()) :: {:ok, map()} | {:error, map()}
  def prepare(source, opts \\ [])

  def prepare(source, opts) when is_binary(source) do
    {:ok,
     %{
       backend: :sdl_image_equivalent,
       source: source,
       requested_size: Keyword.get(opts, :size, :original),
       cache_key: cache_key(source, opts),
       decoding: :asset_decode,
       validation_state: validation_state()
     }}
  end

  def prepare(source, _opts), do: {:error, %{reason: :invalid_image_source, source: source}}

  @spec cache_key(String.t(), keyword()) :: String.t()
  def cache_key(source, opts \\ []) when is_binary(source) do
    requested_size = Keyword.get(opts, :size, :original)
    "image:#{requested_size |> inspect()}:#{:erlang.phash2(source)}"
  end

  @spec from_pixels(binary() | [term()], keyword()) :: {:ok, map()} | {:error, map()}
  def from_pixels(pixels, opts \\ [])

  def from_pixels(pixels, opts)
      when (is_binary(pixels) and byte_size(pixels) > 0) or (is_list(pixels) and pixels != []) do
    {:ok,
     %{
       backend: :raw_pixels,
       width: Keyword.get(opts, :width),
       height: Keyword.get(opts, :height),
       pixel_count: pixel_count(pixels),
       validation_state: validation_state()
     }}
  end

  def from_pixels(pixels, _opts), do: {:error, %{reason: :invalid_pixel_buffer, pixels: pixels}}

  defp pixel_count(pixels) when is_binary(pixels), do: byte_size(pixels)
  defp pixel_count(pixels) when is_list(pixels), do: length(pixels)
end
