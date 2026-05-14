defmodule UnifiedUi.Dsl.InvariantsTest do
  use ExUnit.Case, async: true

  alias UnifiedUi.Dsl.{Identity, Placement}

  defmodule ValidScreen do
    use UnifiedUi.Dsl

    identity do
      id(:valid_screen)
      title("Valid Screen")
      authored_ref([:examples, :valid_screen])
      annotations(source: :test)
      tags([:reference])
    end

    composition do
      root(:screen_shell)
      mode(:screen)
    end
  end

  test "exposes baseline identity and placement rule surfaces" do
    assert Identity.required_sections() == [:identity, :composition]
    assert :authored_ref in Identity.traceability_fields()
    assert :root in Identity.reserved_ids()

    assert Identity.module_identity(ValidScreen) == %{
             id: :valid_screen,
             title: "Valid Screen",
             description: nil,
             authored_ref: [:examples, :valid_screen],
             annotations: [source: :test],
             tags: [:reference]
           }

    assert Placement.section_boundaries().composition == [:root, :mode, :summary, :default_slot]

    assert Enum.any?(
             Placement.placement_rules(),
             &(&1.id == :default_slot_requires_fragment_mode)
           )
  end

  test "rejects authored modules without an identity section" do
    assert_compile_dsl_error(
      """
      composition do
        root(:screen_shell)
        mode(:screen)
      end
      """,
      "identity section is required"
    )
  end

  test "rejects authored modules whose root duplicates the module identity" do
    assert_compile_dsl_error(
      """
      identity do
        id(:duplicate_identity)
      end

      composition do
        root(:duplicate_identity)
        mode(:screen)
      end
      """,
      "composition.root must differ from identity.id"
    )
  end

  test "rejects screen modules that declare a default slot" do
    assert_compile_dsl_error(
      """
      identity do
        id(:screen_with_slot)
      end

      composition do
        root(:screen_shell)
        mode(:screen)
        default_slot(:content)
      end
      """,
      "composition.default_slot may only be declared when composition.mode is :fragment"
    )
  end

  test "rejects authored_ref values that do not end with the module id" do
    assert_compile_dsl_error(
      """
      identity do
        id(:profile_screen)
        authored_ref([:examples, :wrong_tail])
      end

      composition do
        root(:profile_root)
        mode(:screen)
      end
      """,
      "identity.authored_ref must end with identity.id"
    )
  end

  defp compile_module(body) do
    module_name = "Generated#{System.unique_integer([:positive])}"

    Code.compile_string("""
    defmodule UnifiedUi.Dsl.InvariantsTest.#{module_name} do
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
