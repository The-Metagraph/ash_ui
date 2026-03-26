defmodule UnifiedIUR.Validate.Error do
  @moduledoc """
  Typed validation error for malformed or non-canonical `UnifiedIUR` values.
  """

  @enforce_keys [:code, :message]
  defstruct code: :invalid_canonical_value,
            message: nil,
            path: [],
            details: %{}

  @type t :: %__MODULE__{
          code: atom(),
          message: String.t(),
          path: [atom() | String.t() | integer()],
          details: map()
        }

  @spec new(atom(), String.t(), keyword()) :: t()
  def new(code, message, opts \\ []) when is_atom(code) and is_binary(message) do
    %__MODULE__{
      code: code,
      message: message,
      path: Keyword.get(opts, :path, []),
      details: Keyword.get(opts, :details, %{})
    }
  end

  @spec format(t()) :: String.t()
  def format(%__MODULE__{} = error) do
    location =
      case error.path do
        [] -> ""
        path -> " at " <> Enum.map_join(path, ".", &to_string/1)
      end

    detail_suffix =
      case error.details do
        details when map_size(details) == 0 -> ""
        details -> " " <> inspect(details)
      end

    "[#{error.code}] #{error.message}#{location}#{detail_suffix}"
  end
end
