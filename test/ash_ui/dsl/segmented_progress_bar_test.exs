defmodule AshUI.DSL.SegmentedProgressBarTest do
  @moduledoc """
  Tests for the `segmented_progress_bar` widget type:
  - admission via `AshUI.DSL.Storage.valid_widget_type?/1`
  - rendering via `AshUI.Rendering.LiveUIAdapter`

  IUR shape:

      %{
        "type" => "segmented_progress_bar",
        "props" => %{
          "segments" => [
            %{"state" => "completed", "weight" => 2, "label" => "Done"},
            %{"state" => "active", "weight" => 1, "label" => "In Progress"},
            %{"state" => "planned", "weight" => 3, "label" => "Planned"}
          ],
          "label" => "Stage 2 of 3"
        }
      }
  """

  use ExUnit.Case, async: true

  alias AshUI.DSL.Storage
  alias AshUI.Rendering.LiveUIAdapter

  @all_states_segments [
    %{"state" => "completed", "weight" => 2, "label" => "Done"},
    %{"state" => "active", "weight" => 1, "label" => "In Progress"},
    %{"state" => "blocked", "weight" => 1, "label" => "Blocked"},
    %{"state" => "planned", "weight" => 1, "label" => "Planned"},
    %{"state" => "future", "weight" => 3, "label" => "Ahead"}
  ]

  @basic_segments [
    %{"state" => "completed", "weight" => 1},
    %{"state" => "active", "weight" => 2},
    %{"state" => "future", "weight" => 3}
  ]

  describe "admission (valid_widget_type?/1)" do
    test "segmented_progress_bar is a valid widget type" do
      assert Storage.valid_widget_type?("segmented_progress_bar")
    end

    test "existing widget types remain valid after adding segmented_progress_bar" do
      assert Storage.valid_widget_type?("text")
      assert Storage.valid_widget_type?("button")
      assert Storage.valid_widget_type?("card")
    end

    test "segmented_progress_bar passes validate_write when nested in a DSL" do
      dsl = %{
        type: "fragment",
        props: %{},
        children: [
          %{
            type: "segmented_progress_bar",
            props: %{"segments" => @basic_segments},
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

    test "invalid widget type is rejected" do
      refute Storage.valid_widget_type?("not_a_widget")
    end
  end

  describe "rendering via LiveUIAdapter — all five states" do
    test "renders completed state segment" do
      iur = progress_bar_iur(@all_states_segments)

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      assert heex =~ ~s(data-state="completed")
    end

    test "renders active state segment" do
      iur = progress_bar_iur(@all_states_segments)

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      assert heex =~ ~s(data-state="active")
    end

    test "renders blocked state segment" do
      iur = progress_bar_iur(@all_states_segments)

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      assert heex =~ ~s(data-state="blocked")
    end

    test "renders planned state segment" do
      iur = progress_bar_iur(@all_states_segments)

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      assert heex =~ ~s(data-state="planned")
    end

    test "renders future state segment" do
      iur = progress_bar_iur(@all_states_segments)

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      assert heex =~ ~s(data-state="future")
    end
  end

  describe "rendering via LiveUIAdapter — weight handling" do
    test "renders a segment per entry" do
      iur = progress_bar_iur(@all_states_segments)

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      segment_count = Regex.scan(~r/ash-segmented-progress-bar-segment/, heex) |> length()
      assert segment_count == length(@all_states_segments)
    end

    test "segment weight appears as flex style value" do
      segments = [%{"state" => "completed", "weight" => 3}, %{"state" => "future", "weight" => 1}]
      iur = progress_bar_iur(segments)

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      assert heex =~ ~s(style="flex: 3")
      assert heex =~ ~s(style="flex: 1")
    end

    test "missing weight defaults to flex: 1" do
      segments = [%{"state" => "completed"}, %{"state" => "future"}]
      iur = progress_bar_iur(segments)

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      assert Regex.scan(~r/style="flex: 1"/, heex) |> length() == 2
    end
  end

  describe "rendering via LiveUIAdapter — overall label" do
    test "renders label element when label prop provided" do
      iur = progress_bar_iur(@basic_segments, %{"label" => "Stage 2 of 4"})

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      assert heex =~ "Stage 2 of 4"
      assert heex =~ "ash-segmented-progress-bar-label"
    end

    test "label is used in aria-label when provided" do
      iur = progress_bar_iur(@basic_segments, %{"label" => "My Progress"})

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      assert heex =~ ~s(aria-label="My Progress")
    end

    test "fallback aria-label is Progress when no label" do
      iur = progress_bar_iur(@basic_segments)

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      assert heex =~ ~s(aria-label="Progress")
    end
  end

  describe "rendering via LiveUIAdapter — accessibility" do
    test "container has role=progressbar" do
      iur = progress_bar_iur(@basic_segments)

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      assert heex =~ ~s(role="progressbar")
    end

    test "aria-valuemin is 0" do
      iur = progress_bar_iur(@basic_segments)

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      assert heex =~ ~s(aria-valuemin="0")
    end

    test "aria-valuemax is 100" do
      iur = progress_bar_iur(@basic_segments)

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      assert heex =~ ~s(aria-valuemax="100")
    end

    test "base CSS class is rendered" do
      iur = progress_bar_iur(@basic_segments)

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      assert heex =~ "ash-segmented-progress-bar"
    end

    test "track container is rendered" do
      iur = progress_bar_iur(@basic_segments)

      assert {:ok, heex} = LiveUIAdapter.render(wrap_in_screen(iur))
      assert heex =~ "ash-segmented-progress-bar-track"
    end
  end

  # ── Helpers ───────────────────────────────────────────────────

  defp progress_bar_iur(segments, extra_props \\ %{}) do
    %{
      "type" => "segmented_progress_bar",
      "id" => "progress-1",
      "name" => "test_progress",
      "props" => Map.merge(%{"segments" => segments}, extra_props),
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
