defmodule UnifiedIUR.Interactions do
  @moduledoc """
  Reference surface for canonical interaction descriptors and binding metadata.
  """

  @spec modules() :: %{binding: module(), interaction: module(), transport: module()}
  def modules do
    %{
      interaction: UnifiedIUR.Interaction,
      binding: UnifiedIUR.Binding,
      transport: UnifiedIUR.Interactions.Transport
    }
  end
end
