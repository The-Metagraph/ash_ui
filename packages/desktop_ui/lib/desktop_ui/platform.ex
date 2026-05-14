defmodule DesktopUi.Platform do
  @moduledoc """
  Platform integration boundary for `desktop_ui`.
  """

  alias DesktopUi.Platform.{Adapter, Integration, Registry}

  @type target :: :windows | :macos | :linux

  @spec targets() :: [target()]
  def targets, do: [:windows, :macos, :linux]

  @spec modules() :: [module()]
  def modules do
    [
      __MODULE__,
      Adapter,
      Integration,
      Registry,
      DesktopUi.Platform.Windows,
      DesktopUi.Platform.MacOS,
      DesktopUi.Platform.Linux
    ]
  end

  @spec capability_contract() :: map()
  def capability_contract do
    %{
      shared_categories: [:windowing, :menus, :shortcuts, :notifications],
      target_specific_callbacks: [:lifecycle, :focus, :file_open, :window_management],
      bounded_fallbacks: [:menu_shape, :notification_style, :window_controls, :shortcut_scope],
      shared_semantics_outside_platform: Integration.shared_semantics()
    }
  end

  @spec callback_contract() :: map()
  def callback_contract do
    %{
      shared: [:lifecycle, :focus, :window_management],
      optional: [:file_open, :notifications],
      payload_shape: :map
    }
  end

  @spec select(keyword()) ::
          {:ok, %{target: target(), adapter: module()}}
          | {:error, {:unsupported_platform_target, term()} | {:invalid_platform_adapter, term()}}
  def select(opts \\ []) do
    target = Keyword.get(opts, :platform_target, current_target())
    registry = Keyword.get(opts, :adapter_registry, Registry.default())

    case Registry.resolve(registry, target) do
      {:ok, adapter} -> {:ok, %{target: target, adapter: adapter}}
      {:error, :unsupported_target} -> {:error, {:unsupported_platform_target, target}}
      {:error, :invalid_adapter} -> {:error, {:invalid_platform_adapter, target}}
    end
  end

  @spec current_target() :: target()
  def current_target do
    case :os.type() do
      {:win32, _} -> :windows
      {:unix, :darwin} -> :macos
      _other -> :linux
    end
  end

  @spec adapter_summary(target()) :: map()
  def adapter_summary(target) do
    {:ok, adapter} = Registry.resolve(Registry.default(), target)
    adapter.summary()
  end

  @spec supports_capability?(target(), atom()) :: boolean()
  def supports_capability?(target, capability) when is_atom(capability) do
    capability in adapter_summary(target).capabilities
  end

  @spec validate_callback_payload(atom(), term()) :: :ok | {:error, map()}
  def validate_callback_payload(callback, payload) when is_atom(callback) do
    cond do
      callback not in (callback_contract().shared ++ callback_contract().optional) ->
        {:error, %{reason: :unsupported_platform_callback, callback: callback}}

      not is_map(payload) ->
        {:error, %{reason: :invalid_callback_payload, callback: callback, payload: payload}}

      true ->
        :ok
    end
  end

  @spec diagnostics(keyword()) :: map()
  def diagnostics(opts \\ []) do
    registry = Keyword.get(opts, :adapter_registry, Registry.default())

    %{
      targets: targets(),
      current_target: current_target(),
      registered_targets: Registry.registered_targets(registry),
      callback_contract: callback_contract(),
      capability_contract: capability_contract(),
      integration: Integration.diagnostics(),
      invalid_targets:
        targets()
        |> Enum.reject(fn target ->
          match?({:ok, _adapter}, Registry.resolve(registry, target))
        end)
    }
  end

  @spec validation_state() :: atom()
  def validation_state, do: :platform_adapter_ready
end
