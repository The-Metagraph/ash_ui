defmodule AshUI.DSL.PipelineStepperHorizontalTest do
  @moduledoc """
  Tests for the `pipeline_stepper_horizontal` widget type:
  - admission via `AshUI.DSL.Storage.valid_widget_type?/1`
  - rendering via `AshUI.Rendering.LiveUIAdapter`

  IUR shape:

      %{
        "type" => "pipeline_stepper_horizontal",
        "props" => %{
          "steps" => [%{"label" => "Research"}, %{"label" => "Proposal"}, ...],
          "active_index" => 2,
          "event" => "select_step",
          "event_value_key" => "step_index",
          "class" => ""
        }
      }
  """

  use ExUnit.Case, async: true

  alias AshUI.DSL.Storage
  alias AshUI.Rendering.LiveUIAdapter

  @steps [
    %{"label" => "Research"},
    %{"label" => "Proposal"},
    %{"label" => "Spec"},
    %{"label" => "Plan"},
    %{"label" => "Ship"}
  ]

  describe "admission (valid_widget_type?/1)" do
    test "pipeline_stepper_horizontal is a valid widget type" do
      assert Storage.valid_widget_type?("pipeline_stepper_horizontal")
    end

    test "existing widget types are still valid after adding pipeline_stepper_horizontal" do
      assert Storage.valid_widget_type?("text")
      assert Storage.valid_widget_type?("button")
      assert Storage.valid_widget_type?("card")
    end

    test "pipeline_stepper_horizontal passes validate_write when nested in a DSL" do
      dsl = %{
        type: "fragment",
        props: %{},
        children: [
          %{
            type: "pipeline_stepper_horizontal",
            props: %{"steps" => @steps, "active_index" => 1},
            children: [],
            signals: [],
            metadata: %{}
          }
        ],
        signals: [],
        metadata: %{}
      }

      assert Storage.validate_write(dsl) == :ok
    end
  end

  describe "rendering via LiveUIAdapter" do
    test "renders a pipeline_stepper_horizontal node" do
      iur = pipeline_stepper_iur(@steps, 2)

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      assert is_binary(heex)
      assert heex =~ "ash-pipeline-stepper-horizontal"
    end

    test "renders one button per step" do
      iur = pipeline_stepper_iur(@steps, 0)

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      button_count = Regex.scan(~r/<button/, heex) |> length()
      assert button_count == length(@steps)
    end

    test "renders data-state=active for the step at active_index" do
      iur = pipeline_stepper_iur(@steps, 2)

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      active_count = Regex.scan(~r/data-state="active"/, heex) |> length()
      assert active_count == 1
    end

    test "renders data-state=done for steps before active_index" do
      iur = pipeline_stepper_iur(@steps, 2)

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      done_count = Regex.scan(~r/data-state="done"/, heex) |> length()
      assert done_count == 2
    end

    test "renders data-state=pending for steps after active_index" do
      iur = pipeline_stepper_iur(@steps, 2)

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      pending_count = Regex.scan(~r/data-state="pending"/, heex) |> length()
      assert pending_count == 2
    end
  end

  # ── Helpers ───────────────────────────────────────────────────

  defp pipeline_stepper_iur(steps, active_index, props_extra \\ %{}) do
    %{
      "type" => "pipeline_stepper_horizontal",
      "id" => "stepper-1",
      "name" => "test_stepper",
      "props" =>
        Map.merge(
          %{
            "steps" => steps,
            "active_index" => active_index,
            "event" => "select_step",
            "event_value_key" => "step_index",
            "class" => ""
          },
          props_extra
        ),
      "children" => [],
      "metadata" => %{}
    }
  end

  defp wrap_in_screen(element) do
    %{
      "type" => "screen",
      "id" => "screen-1",
      "name" => "test_screen",
      "layout" => "column",
      "children" => [element],
      "bindings" => [],
      "metadata" => %{}
    }
  end
end
