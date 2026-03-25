defmodule UnifiedIUR.Theme do
  @moduledoc """
  Canonical theme definitions and style resolution for `UnifiedIUR`.
  """

  alias UnifiedIUR.Style
  alias UnifiedIUR.Style.Color
  alias UnifiedIUR.Token

  @type component_key :: atom() | String.t()
  @type variant_key :: atom() | String.t()
  @type state_key :: atom() | String.t()

  @type component_style_t :: %{
          optional(:default) => Style.t(),
          optional(:variants) => %{optional(variant_key()) => Style.t()},
          optional(:states) => %{optional(state_key()) => Style.t()}
        }

  @type t :: %__MODULE__{
          id: atom() | String.t() | nil,
          palette: map(),
          roles: map(),
          tokens: map(),
          defaults: Style.t(),
          components: %{optional(component_key()) => component_style_t()},
          extra: map()
        }

  defstruct id: nil,
            palette: %{},
            roles: %{},
            tokens: %{},
            defaults: %Style{},
            components: %{},
            extra: %{}

  @spec new(keyword() | map() | t() | nil) :: t()
  def new(nil), do: %__MODULE__{}

  def new(%__MODULE__{} = theme) do
    %__MODULE__{
      id: theme.id,
      palette: normalize_palette(theme.palette),
      roles: normalize_roles(theme.roles),
      tokens: normalize_tokens(theme.tokens),
      defaults: Style.new(theme.defaults),
      components: normalize_components(theme.components),
      extra: normalize_map(theme.extra)
    }
  end

  def new(theme) when is_list(theme), do: theme |> Enum.into(%{}) |> new()

  def new(theme) when is_map(theme) do
    %__MODULE__{
      id: fetch(theme, :id),
      palette: theme |> fetch(:palette, %{}) |> normalize_palette(),
      roles: theme |> fetch(:roles, %{}) |> normalize_roles(),
      tokens: theme |> fetch(:tokens, %{}) |> normalize_tokens(),
      defaults: theme |> fetch(:defaults, %{}) |> Style.new(),
      components: theme |> fetch(:components, %{}) |> normalize_components(),
      extra: theme |> fetch(:extra, %{}) |> normalize_map()
    }
  end

  @spec put_token(
          t() | keyword() | map() | nil,
          [Token.path_segment()] | Token.path_segment(),
          term()
        ) :: t()
  def put_token(theme, path, value) do
    theme = new(theme)
    path = normalize_path(path)
    key = path_key(path)

    %{
      theme
      | tokens: Map.put(theme.tokens, key, Token.define(path, normalize_token_value(value)))
    }
  end

  @spec token(t() | keyword() | map() | nil, [Token.path_segment()] | Token.path_segment()) ::
          term() | nil
  def token(theme, path) do
    theme = new(theme)
    path = normalize_path(path)

    case Map.get(theme.tokens, path_key(path)) do
      %{value: value} when is_map(value) or is_list(value) -> Style.new(value)
      %{value: value} -> value
      _other -> nil
    end
  end

  @spec resolve_style(t() | keyword() | map() | nil, component_key() | nil, keyword() | map()) ::
          Style.t()
  def resolve_style(theme, component, opts \\ []) do
    theme = new(theme)
    opts = normalize_map(opts)

    variant = fetch(opts, :variant)
    state = fetch(opts, :state)
    token_refs = fetch(opts, :token_refs, []) |> List.wrap()
    local_style = fetch(opts, :local_style, %{}) |> Style.new()

    component_style = if(component, do: Map.get(theme.components, component, %{}), else: %{})

    base =
      theme.defaults
      |> merge_token_refs(theme, token_refs)
      |> Style.merge(Map.get(component_style, :default))
      |> Style.merge(component_variant(component_style, variant))
      |> Style.merge(component_state(component_style, state))
      |> Style.merge(local_style)

    if state && Map.has_key?(local_style.state_variants, state) do
      Style.merge(base, Style.state_variant(local_style, state))
    else
      base
    end
  end

  defp merge_token_refs(style, _theme, []), do: style

  defp merge_token_refs(style, theme, token_refs) do
    Enum.reduce(token_refs, style, fn ref_value, acc ->
      case Token.new(ref_value) do
        %{kind: :token_ref, path: path} ->
          case token(theme, path) do
            nil ->
              acc

            %Style{} = token_style ->
              Style.merge(acc, token_style)

            token_style when is_map(token_style) or is_list(token_style) ->
              Style.merge(acc, token_style)

            _other ->
              acc
          end

        _other ->
          acc
      end
    end)
  end

  defp component_variant(_component_style, nil), do: nil

  defp component_variant(component_style, variant) do
    component_style
    |> Map.get(:variants, %{})
    |> Map.get(variant)
  end

  defp component_state(_component_style, nil), do: nil

  defp component_state(component_style, state) do
    component_style
    |> Map.get(:states, %{})
    |> Map.get(state)
  end

  defp normalize_components(nil), do: %{}

  defp normalize_components(components) when is_map(components) do
    components
    |> Map.new(fn {component, style_map} ->
      style_map = normalize_map(style_map)

      {component,
       %{}
       |> maybe_put(:default, style_map |> fetch(:default) |> Style.new())
       |> maybe_put(:variants, style_map |> fetch(:variants, %{}) |> normalize_variant_map())
       |> maybe_put(:states, style_map |> fetch(:states, %{}) |> normalize_variant_map())}
    end)
  end

  defp normalize_variant_map(variants) when is_map(variants) do
    variants
    |> Map.new(fn {key, style_value} -> {key, Style.new(style_value)} end)
  end

  defp normalize_palette(nil), do: %{}

  defp normalize_palette(palette) when is_map(palette) do
    palette
    |> Map.new(fn {key, value} -> {key, Color.new(value)} end)
  end

  defp normalize_roles(nil), do: %{}

  defp normalize_roles(roles) when is_map(roles) do
    roles
    |> Map.new(fn {key, value} ->
      {key,
       case value do
         %{kind: :token_ref} = ref_value -> Token.new(ref_value)
         %{"kind" => :token_ref} = ref_value -> Token.new(ref_value)
         _other -> Color.new(value)
       end}
    end)
  end

  defp normalize_tokens(nil), do: %{}

  defp normalize_tokens(tokens) when is_map(tokens) do
    tokens
    |> Map.new(fn {key, value} ->
      case value do
        %{kind: :token, path: path, value: token_value} when is_list(path) ->
          {path_key(path), Token.define(path, normalize_token_value(token_value))}

        %{"kind" => :token, "path" => path, "value" => token_value} when is_list(path) ->
          {path_key(path), Token.define(path, normalize_token_value(token_value))}

        _other ->
          path =
            case key do
              path when is_list(path) -> path
              key when is_atom(key) -> [key]
              key when is_binary(key) -> String.split(key, ".", trim: true)
            end

          {path_key(path), Token.define(path, normalize_token_value(value))}
      end
    end)
  end

  defp normalize_token_value(value) when is_map(value) or is_list(value), do: Style.new(value)
  defp normalize_token_value(value), do: value

  defp normalize_map(nil), do: %{}
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp normalize_path(path) when is_atom(path) or is_binary(path), do: [path]
  defp normalize_path(path) when is_list(path), do: path

  defp path_key(path), do: Enum.join(Enum.map(path, &to_string/1), ".")

  defp fetch(source, key, default \\ nil) do
    Map.get(source, key, Map.get(source, Atom.to_string(key), default))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
