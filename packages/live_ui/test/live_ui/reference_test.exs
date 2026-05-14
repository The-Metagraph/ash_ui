defmodule LiveUi.ReferenceTest do
  use ExUnit.Case, async: true

  test "reference helpers report widget families and runtime boundaries" do
    assert :content in LiveUi.Reference.widget_families()
    assert LiveUi.Runtime.State in LiveUi.Reference.runtime_modules()
    assert :canonical_boundary_translation in LiveUi.Reference.transport_integration_points()
    assert :command in LiveUi.Reference.signal_families()
  end

  test "reference surfaces distinguish direct native and canonical responsibilities" do
    responsibilities = LiveUi.Reference.responsibilities()

    assert :native_widgets in responsibilities.direct_native
    assert :consume_canonical_iur in responsibilities.canonical_renderer
  end

  test "runtime assumptions are visible through reference helpers" do
    assert %{
             server_authoritative?: true,
             browser_bridge_authoritative?: false,
             shared_runtime_for_native_and_iur?: true
           } = LiveUi.Reference.runtime_assumptions()
  end
end
