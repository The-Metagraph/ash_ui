defmodule ElmUi.Renderer.Error do
  @moduledoc """
  Structured canonical renderer diagnostics.
  """

  defexception [:code, :message, details: %{}]

  @type t :: %__MODULE__{
          code: atom(),
          message: String.t(),
          details: map()
        }

  @spec unsupported_kind(UnifiedIUR.Element.t(), [atom()]) :: t()
  def unsupported_kind(element, supported_kinds) do
    %__MODULE__{
      code: :unsupported_kind,
      message: "Unsupported canonical elm_ui kind #{inspect(element.kind)}",
      details: %{
        id: element.id,
        type: element.type,
        kind: element.kind,
        supported_kinds: supported_kinds
      }
    }
  end

  @spec missing_identity(UnifiedIUR.Element.t()) :: t()
  def missing_identity(element) do
    %__MODULE__{
      code: :missing_identity,
      message: "Canonical elm_ui elements require stable ids",
      details: %{
        type: element.type,
        kind: element.kind
      }
    }
  end

  @spec missing_required_slot(UnifiedIUR.Element.t(), atom()) :: t()
  def missing_required_slot(element, slot) do
    %__MODULE__{
      code: :missing_required_slot,
      message: "Canonical #{inspect(element.kind)} requires a #{inspect(slot)} slot",
      details: %{
        id: element.id,
        type: element.type,
        kind: element.kind,
        slot: slot
      }
    }
  end
end
