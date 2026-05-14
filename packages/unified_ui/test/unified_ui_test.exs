defmodule UnifiedUiTest do
  use ExUnit.Case, async: true

  test "exposes package identity and module areas" do
    assert UnifiedUi.package_identity() == %{
             app: :unified_ui,
             namespace: UnifiedUi,
             package_path: "packages/unified-ui",
             pure_library?: true
           }

    assert UnifiedUi.module_areas() == %{
             dsl: UnifiedUi.Dsl,
             compiler: UnifiedUi.Compiler,
             parity: UnifiedUi.Parity,
             signals: UnifiedUi.Signals,
             signal: UnifiedUi.Signal,
             binding: UnifiedUi.Binding,
             style: UnifiedUi.Style,
             theme: UnifiedUi.Theme,
             reference: UnifiedUi.Reference,
             info: UnifiedUi.Info,
             tooling: UnifiedUi.Tooling
           }

    assert {:ok, UnifiedUi.Dsl} = UnifiedUi.module_for(:dsl)
    assert {:ok, UnifiedUi.Info} = UnifiedUi.module_for(:info)
    assert {:ok, UnifiedUi.Parity} = UnifiedUi.module_for(:parity)
    assert :error = UnifiedUi.module_for(:missing)
  end

  test "does not require runtime services for package use" do
    assert UnifiedUi.required_runtime_services() == []
  end
end
