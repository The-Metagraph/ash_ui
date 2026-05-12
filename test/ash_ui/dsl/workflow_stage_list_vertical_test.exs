defmodule AshUI.DSL.WorkflowStageListVerticalTest do
  @moduledoc """
  Tests for the workflow_stage_list_vertical widget type in AshUI.

  Covers:
    - DSL.Storage admission (valid_widget_type?/1)
    - IUR adapter mapping (map_element_type/1 via to_canonical/2)
    - LiveUIAdapter HEEx rendering (done/active/pending states + connector data-done)
    - LiveUI renderer (packages/live_ui) HEEx rendering
  """

  use ExUnit.Case, async: true

  alias AshUI.Compilation.IUR
  alias AshUI.DSL.Storage
  alias AshUI.Rendering.IURAdapter
  alias AshUI.Rendering.LiveUIAdapter

  # ── Storage admission ─────────────────────────────────────────

  describe "Storage.valid_widget_type?/1" do
    test "admits workflow_stage_list_vertical" do
      assert Storage.valid_widget_type?("workflow_stage_list_vertical") == true
    end

    test "still admits existing widget types" do
      assert Storage.valid_widget_type?("text") == true
      assert Storage.valid_widget_type?("button") == true
      assert Storage.valid_widget_type?("spacer") == true
    end

    test "still rejects unknown types" do
      assert Storage.valid_widget_type?("invalid_widget") == false
    end
  end

  # ── IUR adapter mapping ───────────────────────────────────────

  describe "IURAdapter.to_canonical/2 with workflow_stage_list_vertical element" do
    test "maps :workflow_stage_list_vertical element type to string form" do
      ash_iur =
        struct(IUR,
          id: "screen-wsl",
          type: :screen,
          name: "stage_list_screen",
          attributes: %{"layout" => :column},
          children: [
            struct(IUR,
              id: "stage-list-1",
              type: :workflow_stage_list_vertical,
              name: "stages",
              props: %{
                "stages" => [%{"label" => "Research"}, %{"label" => "Spec"}],
                "active_index" => 0
              },
              attributes: %{},
              children: [],
              bindings: [],
              metadata: %{},
              version: 1
            )
          ],
          bindings: [],
          metadata: %{},
          version: 1
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur, telemetry: false)
      [child] = canonical["children"]
      assert child["type"] == "workflow_stage_list_vertical"
    end
  end

  # ── LiveUIAdapter HEEx rendering ─────────────────────────────

  describe "LiveUIAdapter.render/2 with workflow_stage_list_vertical" do
    defp stage_iur(stages, active_index) do
      %{
        "type" => "screen",
        "id" => "screen-1",
        "name" => "test_screen",
        "layout" => "column",
        "children" => [
          %{
            "type" => "workflow_stage_list_vertical",
            "id" => "wsl-1",
            "props" => %{
              "stages" => stages,
              "active_index" => active_index
            },
            "children" => [],
            "metadata" => %{}
          }
        ],
        "bindings" => [],
        "metadata" => %{}
      }
    end

    test "renders the container with correct CSS class" do
      {:ok, html} = LiveUIAdapter.render(stage_iur([%{"label" => "Alpha"}], 0))

      assert html =~ "ash-workflow-stage-list-vertical"
    end

    test "stage at active_index gets data-state=active" do
      stages = [%{"label" => "A"}, %{"label" => "B"}, %{"label" => "C"}]
      {:ok, html} = LiveUIAdapter.render(stage_iur(stages, 1))

      assert html =~ ~s(data-state="active")
    end

    test "stages before active_index get data-state=done" do
      stages = [%{"label" => "A"}, %{"label" => "B"}, %{"label" => "C"}]
      {:ok, html} = LiveUIAdapter.render(stage_iur(stages, 2))

      assert Regex.scan(~r/data-state="done"/, html) |> length() == 2
    end

    test "stages after active_index get data-state=pending" do
      stages = [%{"label" => "A"}, %{"label" => "B"}, %{"label" => "C"}]
      {:ok, html} = LiveUIAdapter.render(stage_iur(stages, 0))

      assert Regex.scan(~r/data-state="pending"/, html) |> length() == 2
    end

    test "connectors before or at active position get data-done=true" do
      stages = [%{"label" => "A"}, %{"label" => "B"}, %{"label" => "C"}]
      {:ok, html} = LiveUIAdapter.render(stage_iur(stages, 2))

      assert Regex.scan(~r/data-done="true"/, html) |> length() == 2
    end

    test "connectors after active position get data-done=false" do
      stages = [%{"label" => "A"}, %{"label" => "B"}, %{"label" => "C"}]
      {:ok, html} = LiveUIAdapter.render(stage_iur(stages, 0))

      # N-1 connectors total (2), all data-done=false when active_index=0
      assert Regex.scan(~r/data-done="false"/, html) |> length() == 2
    end

    test "renders N-1 connector elements for N stages" do
      stages = Enum.map(1..5, &%{"label" => "Stage #{&1}"})
      {:ok, html} = LiveUIAdapter.render(stage_iur(stages, 0))

      assert Regex.scan(~r/ash-workflow-stage-list-vertical-connector/, html) |> length() == 4
    end

    test "empty stages list renders without crash" do
      {:ok, html} = LiveUIAdapter.render(stage_iur([], 0))

      assert html =~ "ash-workflow-stage-list-vertical"
      refute html =~ "ash-workflow-stage-list-vertical-item"
    end
  end
end
