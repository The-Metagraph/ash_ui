defmodule UnifiedUi.Phase1IntegrationTest do
  use ExUnit.Case, async: true

  alias Spark.Dsl.Extension

  defmodule IntegrationScreen do
    use UnifiedUi.Dsl

    identity do
      id(:integration_screen)
      title("Integration Screen")
      description("Phase 1 end-to-end authored screen")
      authored_ref([:integration, :integration_screen])
      tags([:integration, :phase_1])
    end

    composition do
      root(:integration_root)
      mode(:screen)
      summary("Integration shell")
    end

    themes do
      default_theme(:workspace)

      theme do
        id(:workspace)

        palette_color do
          id(:surface)
          color(named_color(:black))
        end
      end
    end

    signals do
      namespace(:workspace)
      default_target(:session)
    end
  end

  test "boots as a pure authored library without runtime infrastructure" do
    assert UnifiedUi.package_identity() == %{
             app: :unified_ui,
             namespace: UnifiedUi,
             package_path: "packages/unified-ui",
             pure_library?: true
           }

    assert UnifiedUi.module_areas() == %{
             compiler: UnifiedUi.Compiler,
             dsl: UnifiedUi.Dsl,
             binding: UnifiedUi.Binding,
             info: UnifiedUi.Info,
             parity: UnifiedUi.Parity,
             reference: UnifiedUi.Reference,
             signal: UnifiedUi.Signal,
             signals: UnifiedUi.Signals,
             style: UnifiedUi.Style,
             theme: UnifiedUi.Theme,
             tooling: UnifiedUi.Tooling
           }

    assert UnifiedUi.module_for(:dsl) == {:ok, UnifiedUi.Dsl}
    assert UnifiedUi.module_for(:compiler) == {:ok, UnifiedUi.Compiler}
    assert UnifiedUi.module_for(:parity) == {:ok, UnifiedUi.Parity}
    assert UnifiedUi.required_runtime_services() == []
  end

  test "registers a minimal authored module through the Spark backbone and reference surfaces" do
    assert Extension.get_opt(IntegrationScreen, [:identity], :id, nil) == :integration_screen
    assert Extension.get_opt(IntegrationScreen, [:composition], :root, nil) == :integration_root

    assert UnifiedUi.Reference.supported_sections() == [
             :identity,
             :composition,
             :themes,
             :signals
           ]

    assert UnifiedUi.Reference.construct_families().layouts == [
             :container,
             :row,
             :column,
             :grid,
             :stack,
             :split,
             :viewport
           ]

    assert UnifiedUi.Info.module_summary(IntegrationScreen).validation_state == :phase_1_valid

    assert UnifiedUi.Info.module_summary(IntegrationScreen).sections == %{
             identity: true,
             composition: true,
             themes: true,
             signals: true
           }
  end

  test "keeps reference and inspection helpers usable without runtime-library packages" do
    assert UnifiedUi.Info.supported_construct_families() ==
             UnifiedUi.Reference.construct_families()

    assert UnifiedUi.Reference.identity_rules().required_sections == [:identity, :composition]

    assert UnifiedUi.Info.inspect_module(IntegrationScreen).identifiers == %{
             module_id: :integration_screen,
             root_id: :integration_root,
             default_theme: :workspace,
             signal_namespace: :workspace
           }
  end

  test "fails malformed authored modules with compile-time diagnostics instead of runtime errors" do
    assert_compile_dsl_error(
      """
      composition do
        root(:missing_identity_root)
        mode(:screen)
      end
      """,
      "identity section is required"
    )

    assert_compile_dsl_error(
      """
      identity do
        id(:duplicate_identifier)
      end

      composition do
        root(:duplicate_identifier)
        mode(:screen)
      end
      """,
      "composition.root must differ from identity.id"
    )
  end

  defp compile_module(body) do
    module_name = "Generated#{System.unique_integer([:positive])}"

    Code.compile_string("""
    defmodule UnifiedUi.Phase1IntegrationTest.#{module_name} do
      use UnifiedUi.Dsl

      #{body}
    end
    """)
  end

  defp assert_compile_dsl_error(body, expected_message) do
    {pid, ref} = spawn_monitor(fn -> compile_module(body) end)

    receive do
      {:DOWN, ^ref, :process, ^pid, :normal} ->
        flunk("expected authored module compilation to fail, but it succeeded")

      {:DOWN, ^ref, :process, ^pid, reason} ->
        assert Exception.format_exit(reason) =~ expected_message
    end
  end
end
