defmodule DesktopUi.Transport.Normalize do
  @moduledoc """
  Shared native desktop event normalization for `desktop_ui`.
  """

  alias DesktopUi.Platform
  alias DesktopUi.Transport.Error

  @type input_family :: :focus | :keyboard | :menu | :pointer | :shortcut | :window

  @raw_leak_keys [
    :backend_payload,
    :keycode,
    :native_handle,
    :platform_payload,
    :scancode,
    :sdl_event,
    :window_handle
  ]

  @input_families [:pointer, :keyboard, :focus, :window, :menu, :shortcut]

  @spec input_families() :: [input_family()]
  def input_families, do: @input_families

  @spec normalize(keyword() | map()) :: {:ok, map()} | {:error, Error.t()}
  def normalize(attrs) when is_map(attrs) or is_list(attrs) do
    attrs = normalize_map(attrs)
    platform_target = fetch(attrs, :platform_target, Platform.current_target())

    with :ok <- validate_platform_target(platform_target),
         :ok <- validate_no_platform_leakage(attrs),
         {:ok, input_family} <- resolve_input_family(attrs),
         {:ok, family} <- resolve_canonical_family(attrs, input_family),
         {:ok, payload} <- normalize_payload(fetch(attrs, :payload, %{}), :native_local) do
      normalized = %{
        input_family: input_family,
        family: family,
        intent: fetch(attrs, :intent, default_intent(input_family, family)),
        runtime_event: fetch(attrs, :runtime_event, default_runtime_event(input_family, family)),
        boundary: resolve_boundary(attrs, family),
        source_kind: normalize_source_kind(fetch(attrs, :source_kind, :native)),
        platform_target: platform_target,
        widget_id: fetch(attrs, :widget_id),
        runtime_id: fetch(attrs, :runtime_id),
        screen: fetch(attrs, :screen, "unknown"),
        target: normalize_map(fetch(attrs, :target, %{})),
        payload: payload,
        normalized_input: normalized_input(attrs, input_family, platform_target),
        local_handling: local_handling(input_family)
      }

      {:ok, normalized}
    end
  end

  def normalize(value), do: {:error, Error.invalid_native_event(value)}

  @spec diagnostics() :: map()
  def diagnostics do
    %{
      platform_targets: Platform.targets(),
      input_families: @input_families,
      leaked_platform_keys: @raw_leak_keys
    }
  end

  defp validate_platform_target(target) when target in [:windows, :macos, :linux], do: :ok
  defp validate_platform_target(target), do: {:error, Error.unsupported_platform_target(target)}

  defp validate_no_platform_leakage(attrs) do
    leaked_keys =
      attrs
      |> Map.keys()
      |> Enum.filter(&(&1 in @raw_leak_keys))

    if leaked_keys == [] do
      :ok
    else
      {:error, Error.leaked_platform_detail(leaked_keys)}
    end
  end

  defp resolve_input_family(attrs) do
    case normalize_input_family(fetch(attrs, :input_family)) do
      family when family in @input_families ->
        {:ok, family}

      nil ->
        infer_input_family(attrs)

      invalid ->
        {:error, Error.invalid_native_event(invalid)}
    end
  end

  defp infer_input_family(attrs) do
    matches =
      [
        if(present?(fetch(attrs, :shortcut)), do: :shortcut),
        if(present?(fetch(attrs, :menu_item)) or present?(fetch(attrs, :menu_path)), do: :menu),
        if(present?(fetch(attrs, :window_action)) or present?(fetch(attrs, :window_id)),
          do: :window
        ),
        if(present?(fetch(attrs, :focus_target)) or present?(fetch(attrs, :focused)), do: :focus),
        if(
          present?(fetch(attrs, :pointer_action)) or present?(fetch(attrs, :button)) or
            map_size(normalize_map(fetch(attrs, :pointer, %{}))) > 0,
          do: :pointer
        ),
        if(present?(fetch(attrs, :key)) or present?(fetch(attrs, :text)), do: :keyboard)
      ]
      |> Enum.reject(&is_nil/1)

    case Enum.uniq(matches) do
      [family] -> {:ok, family}
      [] -> {:error, Error.invalid_native_event(attrs)}
      _many -> {:error, Error.ambiguous_native_event(attrs)}
    end
  end

  defp resolve_canonical_family(attrs, input_family) do
    case normalize_family(fetch(attrs, :family)) do
      nil ->
        {:ok, default_family_for(input_family, attrs)}

      family ->
        if family in DesktopUi.Transport.Signal.families() do
          {:ok, family}
        else
          {:error, Error.invalid_family(family)}
        end
    end
  end

  defp default_family_for(:shortcut, _attrs), do: :command
  defp default_family_for(:menu, _attrs), do: :command
  defp default_family_for(:window, _attrs), do: :navigation
  defp default_family_for(:focus, _attrs), do: :focus

  defp default_family_for(:pointer, attrs) do
    case normalize_pointer_action(fetch(attrs, :pointer_action)) do
      :move -> :navigation
      :scroll -> :navigation
      :select -> :selection
      :click -> :click
      nil -> :selection
    end
  end

  defp default_family_for(:keyboard, attrs) do
    case normalize_key(fetch(attrs, :key)) do
      "enter" -> :submit
      "return" -> :submit
      "tab" -> :navigation
      "up" -> :navigation
      "down" -> :navigation
      "left" -> :navigation
      "right" -> :navigation
      _other -> :change
    end
  end

  defp resolve_boundary(attrs, family) do
    case normalize_boundary(fetch(attrs, :boundary)) do
      boundary when boundary in [:local, :boundary] ->
        boundary

      _other ->
        if family in DesktopUi.Transport.Signal.boundary_crossing_families() or
             fetch(attrs, :source_kind) in [:canonical, "canonical"] do
          :boundary
        else
          :local
        end
    end
  end

  defp normalize_payload(payload, _surface) when is_map(payload), do: {:ok, Map.new(payload)}
  defp normalize_payload(nil, _surface), do: {:ok, %{}}

  defp normalize_payload(payload, surface),
    do: {:error, Error.invalid_payload_mapping(payload, surface)}

  defp normalized_input(attrs, :shortcut, platform_target) do
    %{
      shortcut: fetch(attrs, :shortcut),
      modifiers: List.wrap(fetch(attrs, :modifiers, [])),
      platform_target: platform_target
    }
  end

  defp normalized_input(attrs, :menu, platform_target) do
    %{
      menu_item: fetch(attrs, :menu_item),
      menu_path: List.wrap(fetch(attrs, :menu_path, [])),
      platform_target: platform_target
    }
  end

  defp normalized_input(attrs, :window, platform_target) do
    %{
      action: fetch(attrs, :window_action),
      window_id: fetch(attrs, :window_id),
      platform_target: platform_target
    }
  end

  defp normalized_input(attrs, :focus, platform_target) do
    %{
      target: fetch(attrs, :focus_target),
      focused: fetch(attrs, :focused, true),
      platform_target: platform_target
    }
  end

  defp normalized_input(attrs, :pointer, platform_target) do
    %{
      action: normalize_pointer_action(fetch(attrs, :pointer_action)),
      button: fetch(attrs, :button),
      pointer: normalize_map(fetch(attrs, :pointer, %{})),
      modifiers: List.wrap(fetch(attrs, :modifiers, [])),
      platform_target: platform_target
    }
  end

  defp normalized_input(attrs, :keyboard, platform_target) do
    %{
      key: normalize_key(fetch(attrs, :key)),
      text: fetch(attrs, :text),
      modifiers: List.wrap(fetch(attrs, :modifiers, [])),
      platform_target: platform_target
    }
  end

  defp local_handling(:focus), do: :focus_handoff
  defp local_handling(:window), do: :window_management
  defp local_handling(:menu), do: :menu_navigation
  defp local_handling(:shortcut), do: :shortcut_dispatch
  defp local_handling(:pointer), do: :pointer_dispatch
  defp local_handling(:keyboard), do: :text_input_dispatch

  defp default_intent(input_family, family), do: :"#{input_family}_#{family}"
  defp default_runtime_event(input_family, family), do: "#{input_family}:#{family}"

  defp normalize_input_family(value) when is_atom(value), do: value
  defp normalize_input_family(value) when is_binary(value), do: String.to_atom(value)
  defp normalize_input_family(_value), do: nil

  defp normalize_family(value) when is_atom(value), do: value
  defp normalize_family(value) when is_binary(value), do: String.to_atom(value)
  defp normalize_family(_value), do: nil

  defp normalize_source_kind(:native), do: :native
  defp normalize_source_kind("native"), do: :native
  defp normalize_source_kind(:canonical), do: :canonical
  defp normalize_source_kind("canonical"), do: :canonical
  defp normalize_source_kind(_value), do: :native

  defp normalize_boundary(:local), do: :local
  defp normalize_boundary("local"), do: :local
  defp normalize_boundary(:boundary), do: :boundary
  defp normalize_boundary("boundary"), do: :boundary
  defp normalize_boundary(_value), do: nil

  defp normalize_key(key) when is_atom(key), do: Atom.to_string(key)
  defp normalize_key(key) when is_binary(key), do: String.downcase(key)
  defp normalize_key(_key), do: nil

  defp normalize_pointer_action(action) when action in [:click, :move, :scroll, :select],
    do: action

  defp normalize_pointer_action(action) when is_binary(action), do: String.to_atom(action)
  defp normalize_pointer_action(_action), do: nil

  defp present?(nil), do: false
  defp present?(""), do: false
  defp present?([]), do: false
  defp present?(_value), do: true

  defp normalize_map(value) when is_map(value), do: Map.new(value)
  defp normalize_map(value) when is_list(value), do: Enum.into(value, %{})
  defp normalize_map(_value), do: %{}

  defp fetch(map, key, default \\ nil) do
    Map.get(map, key, Map.get(map, Atom.to_string(key), default))
  end
end
