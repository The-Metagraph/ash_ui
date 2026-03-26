defmodule UnifiedUi.Theme do
  @moduledoc """
  Canonical authored theme declarations for `UnifiedUi`.
  """

  alias Spark.Dsl.Extension
  alias UnifiedIUR.Token
  alias UnifiedUi.Style

  @type t :: %__MODULE__{
          __identifier__: atom() | nil,
          id: atom() | nil,
          description: String.t() | nil,
          authored_ref: [atom()] | nil,
          summary: String.t() | nil,
          extends: atom() | nil,
          inherit?: boolean(),
          children: [
            PaletteColor.t() | SemanticRole.t() | TokenDeclaration.t() | ComponentStyle.t()
          ]
        }

  defstruct __identifier__: nil,
            __spark_metadata__: nil,
            id: nil,
            description: nil,
            authored_ref: nil,
            summary: nil,
            extends: nil,
            inherit?: true,
            children: []

  defmodule PaletteColor do
    @moduledoc false

    alias UnifiedIUR.Style.Color

    @type t :: %__MODULE__{
            __identifier__: atom() | nil,
            id: atom() | nil,
            color: Color.t() | nil,
            summary: String.t() | nil
          }

    defstruct __identifier__: nil,
              __spark_metadata__: nil,
              id: nil,
              color: nil,
              summary: nil

    @spec new(keyword() | map() | t()) :: t()
    def new(%__MODULE__{} = color), do: normalize(color)
    def new(color) when is_list(color), do: color |> Enum.into(%{}) |> new()

    def new(color) when is_map(color) do
      %__MODULE__{
        id: fetch(color, :id),
        color: color |> fetch(:color) |> Color.new(),
        summary: fetch(color, :summary)
      }
    end

    defp normalize(%__MODULE__{} = color) do
      %__MODULE__{color | color: Color.new(color.color)}
    end

    defp fetch(source, key, default \\ nil) do
      Map.get(source, key, Map.get(source, Atom.to_string(key), default))
    end
  end

  defmodule SemanticRole do
    @moduledoc false

    alias UnifiedIUR.Token
    alias UnifiedUi.Style

    @type t :: %__MODULE__{
            __identifier__: atom() | nil,
            id: atom() | nil,
            value: Style.color_value(),
            summary: String.t() | nil
          }

    defstruct __identifier__: nil,
              __spark_metadata__: nil,
              id: nil,
              value: nil,
              summary: nil

    @spec new(keyword() | map() | t()) :: t()
    def new(%__MODULE__{} = role), do: normalize(role)
    def new(role) when is_list(role), do: role |> Enum.into(%{}) |> new()

    def new(role) when is_map(role) do
      %__MODULE__{
        id: fetch(role, :id),
        value: role |> fetch(:value) |> normalize_value(),
        summary: fetch(role, :summary)
      }
    end

    defp normalize(%__MODULE__{} = role) do
      %__MODULE__{role | value: normalize_value(role.value)}
    end

    defp normalize_value(value) do
      cond do
        is_nil(value) -> nil
        Style.role_reference?(value) -> Style.role_ref(Map.get(value, :id, Map.get(value, "id")))
        token_reference_value?(value) -> Token.new(value)
        true -> UnifiedIUR.Style.Color.new(value)
      end
    end

    defp token_reference_value?(%{kind: :token_ref, path: path}) when is_list(path), do: true

    defp token_reference_value?(%{"kind" => :token_ref, "path" => path}) when is_list(path),
      do: true

    defp token_reference_value?(_other), do: false

    defp fetch(source, key, default \\ nil) do
      Map.get(source, key, Map.get(source, Atom.to_string(key), default))
    end
  end

  defmodule TokenDeclaration do
    @moduledoc false

    alias UnifiedUi.Style

    @type t :: %__MODULE__{
            __identifier__: atom() | nil,
            id: atom() | nil,
            value: term(),
            summary: String.t() | nil
          }

    defstruct __identifier__: nil,
              __spark_metadata__: nil,
              id: nil,
              value: nil,
              summary: nil

    @spec new(keyword() | map() | t()) :: t()
    def new(%__MODULE__{} = token), do: normalize(token)
    def new(token) when is_list(token), do: token |> Enum.into(%{}) |> new()

    def new(token) when is_map(token) do
      %__MODULE__{
        id: fetch(token, :id),
        value: normalize_value(fetch(token, :value)),
        summary: fetch(token, :summary)
      }
    end

    defp normalize(%__MODULE__{} = token) do
      %__MODULE__{token | value: normalize_value(token.value)}
    end

    defp normalize_value(value) when is_map(value) or is_list(value) do
      if style_value?(value) do
        Style.new(value)
      else
        value
      end
    end

    defp normalize_value(value), do: value

    defp style_value?(value) when is_list(value) do
      keys = Keyword.keys(value)

      Enum.any?(
        keys,
        &(&1 in [
            :theme_ref,
            :component,
            :variant,
            :tone,
            :token_refs,
            :foreground,
            :background,
            :border_color,
            :typography,
            :spacing,
            :sizing,
            :alignment,
            :border,
            :visibility,
            :emphasis,
            :state_variants,
            :inherit?,
            :metadata
          ])
      )
    end

    defp style_value?(value) when is_map(value) do
      keys = Map.keys(value)

      Enum.any?(
        keys,
        &(&1 in [
            :theme_ref,
            :component,
            :variant,
            :tone,
            :token_refs,
            :foreground,
            :background,
            :border_color,
            :typography,
            :spacing,
            :sizing,
            :alignment,
            :border,
            :visibility,
            :emphasis,
            :state_variants,
            :inherit?,
            :metadata,
            "theme_ref",
            "component",
            "variant",
            "tone",
            "token_refs",
            "foreground",
            "background",
            "border_color",
            "typography",
            "spacing",
            "sizing",
            "alignment",
            "border",
            "visibility",
            "emphasis",
            "state_variants",
            "inherit?",
            "metadata"
          ])
      )
    end

    defp fetch(source, key, default \\ nil) do
      Map.get(source, key, Map.get(source, Atom.to_string(key), default))
    end
  end

  defmodule ComponentStyle do
    @moduledoc false

    alias UnifiedIUR.Token
    alias UnifiedUi.Style

    @type t :: %__MODULE__{
            __identifier__: atom() | nil,
            id: atom() | nil,
            component: atom() | nil,
            variant: atom() | nil,
            state: atom() | nil,
            style: Style.t() | nil,
            token_refs: [Token.ref_t()],
            inherit?: boolean(),
            summary: String.t() | nil
          }

    defstruct __identifier__: nil,
              __spark_metadata__: nil,
              id: nil,
              component: nil,
              variant: nil,
              state: nil,
              style: nil,
              token_refs: [],
              inherit?: true,
              summary: nil

    @spec new(keyword() | map() | t()) :: t()
    def new(%__MODULE__{} = component_style), do: normalize(component_style)

    def new(component_style) when is_list(component_style),
      do: component_style |> Enum.into(%{}) |> new()

    def new(component_style) when is_map(component_style) do
      %__MODULE__{
        id: fetch(component_style, :id),
        component: fetch(component_style, :component),
        variant: fetch(component_style, :variant),
        state: fetch(component_style, :state),
        style: component_style |> fetch(:style) |> normalize_style(),
        token_refs: component_style |> fetch(:token_refs, []) |> normalize_token_refs(),
        inherit?: fetch(component_style, :inherit?, true),
        summary: fetch(component_style, :summary)
      }
    end

    defp normalize(%__MODULE__{} = component_style) do
      %__MODULE__{
        component_style
        | style: normalize_style(component_style.style),
          token_refs: normalize_token_refs(component_style.token_refs)
      }
    end

    defp normalize_style(nil), do: nil
    defp normalize_style(style), do: Style.new(style)

    defp normalize_token_refs(token_refs) do
      token_refs
      |> List.wrap()
      |> Enum.map(&Token.new/1)
      |> Enum.reject(&is_nil/1)
    end

    defp fetch(source, key, default \\ nil) do
      Map.get(source, key, Map.get(source, Atom.to_string(key), default))
    end
  end

  @spec themes(module()) :: [t()]
  def themes(module) when is_atom(module) do
    module
    |> Extension.get_entities([:themes])
    |> Enum.filter(&match?(%__MODULE__{}, &1))
  end

  @spec default_theme(module()) :: atom() | nil
  def default_theme(module) when is_atom(module) do
    Extension.get_opt(module, [:themes], :default_theme, nil)
  end

  @spec summaries(module()) :: [map()]
  def summaries(module) when is_atom(module) do
    module
    |> themes()
    |> Enum.map(&summary/1)
  end

  @spec module_summary(module()) :: map()
  def module_summary(module) when is_atom(module) do
    %{
      default_theme: default_theme(module),
      inherit?: Extension.get_opt(module, [:themes], :inherit?, true),
      summary: Extension.get_opt(module, [:themes], :summary, nil),
      themes: summaries(module)
    }
  end

  @spec summary(t()) :: map()
  def summary(%__MODULE__{} = theme) do
    %{
      id: theme.id,
      description: theme.description,
      authored_ref: theme.authored_ref,
      summary: theme.summary,
      extends: theme.extends,
      inherit?: theme.inherit?,
      palette_colors:
        Enum.map(palette_colors(theme), fn color ->
          %{
            id: color.id,
            color: color.color,
            summary: color.summary
          }
          |> Enum.reject(fn {_key, value} -> is_nil(value) end)
          |> Enum.into(%{})
        end),
      semantic_roles:
        Enum.map(semantic_roles(theme), fn role ->
          %{
            id: role.id,
            value: role.value,
            summary: role.summary
          }
          |> Enum.reject(fn {_key, value} -> is_nil(value) end)
          |> Enum.into(%{})
        end),
      tokens:
        Enum.map(tokens(theme), fn token ->
          %{
            id: token.id,
            value:
              case token.value do
                %Style{} = style -> Style.summary(style)
                value -> value
              end,
            summary: token.summary
          }
          |> Enum.reject(fn {_key, value} -> is_nil(value) end)
          |> Enum.into(%{})
        end),
      component_styles:
        Enum.map(component_styles(theme), fn component_style ->
          %{
            id: component_style.id,
            component: component_style.component,
            variant: component_style.variant,
            state: component_style.state,
            style:
              case component_style.style do
                nil -> nil
                style -> Style.summary(style)
              end,
            token_refs: component_style.token_refs,
            inherit?: component_style.inherit?,
            summary: component_style.summary
          }
          |> Enum.reject(fn {_key, value} -> value in [nil, [], %{}] end)
          |> Enum.into(%{})
        end)
    }
    |> Enum.reject(fn {_key, value} -> value in [nil, [], %{}] end)
    |> Enum.into(%{})
  end

  @spec palette_colors(t()) :: [PaletteColor.t()]
  def palette_colors(%__MODULE__{} = theme) do
    Enum.filter(theme.children, &match?(%PaletteColor{}, &1))
  end

  @spec semantic_roles(t()) :: [SemanticRole.t()]
  def semantic_roles(%__MODULE__{} = theme) do
    Enum.filter(theme.children, &match?(%SemanticRole{}, &1))
  end

  @spec tokens(t()) :: [TokenDeclaration.t()]
  def tokens(%__MODULE__{} = theme) do
    Enum.filter(theme.children, &match?(%TokenDeclaration{}, &1))
  end

  @spec component_styles(t()) :: [ComponentStyle.t()]
  def component_styles(%__MODULE__{} = theme) do
    Enum.filter(theme.children, &match?(%ComponentStyle{}, &1))
  end
end
