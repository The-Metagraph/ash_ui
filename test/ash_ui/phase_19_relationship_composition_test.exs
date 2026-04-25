defmodule AshUI.Phase19RelationshipCompositionTest do
  use ExUnit.Case, async: false

  alias AshUI.Compiler
  alias AshUI.Examples.Phase19

  @moduletag :integration
  @moduletag :examples

  setup_all do
    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(["row", "menu", "viewport", "split_pane"], &load_example_module!/1)

    :ok
  end

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()
    :ok
  end

  describe "Section 19.4 - Relationship-Driven Composition Proof" do
    test "19.4.1.3 - the scaffold contract tells reviewers to reject monolithic screen-level composition for structural examples" do
      scaffold_contract = File.read!(Path.expand("../../examples/scaffold_contract.md", __DIR__))

      assert scaffold_contract =~ "## Relationship-First Review Guidance"
      assert scaffold_contract =~ "the screen resource grows a large `inline_fragment`"
      assert scaffold_contract =~ "screen roots only for shell glue"
      assert scaffold_contract =~ "custom example shell (`custom:*`)"
    end

    test "19.4.1.4 - representative apps persist nil screen inline fragments and compile from related element graphs" do
      Enum.each(representative_examples(), fn {directory, related_ids} ->
        module = Phase19.example_module(directory)
        mounted = module.mount_seeded!()
        screen = mounted.screen
        unified_dsl = screen.unified_dsl

        assert get_in(unified_dsl, ["screen", "inline_fragment"]) == nil
        assert composition_root_count(unified_dsl) == 3

        element_ids = element_ids(unified_dsl)
        assert length(element_ids) > composition_root_count(unified_dsl)

        Enum.each(related_ids, fn related_id ->
          assert related_id in element_ids
        end)

        subject =
          mounted.socket.assigns.ash_ui_iur
          |> find_iur_by_id("example-#{directory}-subject")

        assert is_map(subject)
        assert length(subject["children"]) >= length(related_ids)
      end)
    end
  end

  defp representative_examples do
    [
      {"row", ["primary-lane", "inspector-lane", "action-lane"]},
      {"menu", ["overview-button", "monitoring-button", "handoff-button"]},
      {"viewport", ["viewport-focus-copy", "timeline-viewport-button", "viewport-status"]},
      {"split_pane", ["primary-review-panel", "secondary-focus-copy", "handoff-pane-button"]}
    ]
  end

  defp composition_root_count(unified_dsl),
    do: unified_dsl |> get_in(["composition", "roots"]) |> length()

  defp element_ids(unified_dsl) do
    unified_dsl
    |> get_in(["elements"])
    |> Enum.map(fn element ->
      get_in(element, ["dsl", "metadata", "id"]) || element["id"]
    end)
  end

  defp find_iur_by_id(nil, _id), do: nil

  defp find_iur_by_id(%{"id" => id} = iur, id), do: iur

  defp find_iur_by_id(%{"children" => children}, id) when is_list(children) do
    Enum.find_value(children, &find_iur_by_id(&1, id))
  end

  defp find_iur_by_id(_iur, _id), do: nil

  defp load_example_module!(directory) do
    module = Phase19.example_module(directory)

    if Code.ensure_loaded?(module) do
      module
    else
      directory
      |> Phase19.project_path()
      |> Path.join("lib/ash_ui_examples/#{directory}.ex")
      |> Code.require_file()

      module
    end
  end
end
