defmodule LiveUi.Examples.StyledContinuityComparison do
  @moduledoc """
  Maintained mixed-flow example comparing styled native and canonical paths.
  """

  alias LiveUi.Examples.{
    CanonicalStyledOperations,
    CanonicalStyledProfile,
    MixedBoundaryTransport,
    NativeStyledOperationsScreen,
    NativeStyledProfileScreen
  }

  def compare do
    with {:ok, profile} <-
           LiveUi.Tooling.compare_native_and_canonical(
             NativeStyledProfileScreen,
             CanonicalStyledProfile.element()
           ),
         {:ok, operations} <-
           LiveUi.Tooling.compare_native_and_canonical(
             NativeStyledOperationsScreen,
             CanonicalStyledOperations.element()
           ),
         {:ok, boundary} <- MixedBoundaryTransport.compare_paths() do
      {:ok,
       %{
         profile: profile,
         operations: operations,
         boundary: boundary
       }}
    end
  end

  def metadata do
    %{
      id: :styled_continuity_compare,
      title: "Styled Continuity Comparison",
      families: [:comparison, :styling, :signal],
      comparable_to: [
        :native_styled_profile,
        :canonical_styled_profile,
        :native_styled_operations,
        :canonical_styled_operations
      ],
      summary: "Mixed example comparing styled native, canonical, and boundary transport flows."
    }
  end
end
