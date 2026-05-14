defmodule ElmUi.PhaseTwoIntegrationTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element

  test "foundational native screens hydrate and preserve bounded frontend behavior" do
    assert {:ok, runtime_state} =
             ElmUi.Runtime.mount_native_screen(ElmUi.Examples.native_foundational_screen())

    assert {:ok, frontend_model} = ElmUi.Runtime.hydrate_frontend(runtime_state)

    tabs = find_node(frontend_model.tree, "workspace-tabs")
    input = find_node(frontend_model.tree, "query-input")

    assert runtime_state.source_kind == :native
    assert tabs.browser.navigable?
    assert input.browser.editable?

    assert {:ok, focused_model} =
             ElmUi.FrontendRuntime.put_local_state(frontend_model, :focused_id, "query-input")

    assert find_node(focused_model.tree, "query-input").browser.focused?
    assert focused_model.render_tree == frontend_model.render_tree
  end

  test "canonical foundational screens reuse the same runtime and preserve continuity" do
    assert {:ok, runtime_state} =
             ElmUi.Runtime.mount_iur_screen(ElmUi.Examples.canonical_foundational_screen())

    assert {:ok, frontend_model} = ElmUi.Runtime.hydrate_frontend(runtime_state)

    comparison = ElmUi.Examples.foundational_comparison()

    assert runtime_state.boundary_mode == :canonical_boundary
    assert find_node(frontend_model.tree, "workspace-actions").tag == "div"
    assert comparison.continuity.widget_kinds_match?
    assert comparison.continuity.render_tags_match?
    assert "query-input" in comparison.continuity.shared_ids
    assert "save-button" in comparison.continuity.shared_ids
  end

  test "unsupported canonical inputs fail with coverage-oriented diagnostics" do
    unsupported =
      Element.new(:widget, :timeline,
        id: "timeline-root",
        attributes: %{title: "Unsupported"}
      )

    assert {:error,
            %ElmUi.ServerRuntime.Error{reason: :invalid_canonical_screen, details: details}} =
             ElmUi.Runtime.mount_iur_screen(unsupported)

    assert details.renderer_code == :unsupported_kind
    assert details.renderer_details.kind == :timeline
    assert :text_input in details.renderer_details.supported_kinds
  end

  defp find_node(node, id) when is_map(node) do
    if node.id == id do
      node
    else
      node.slots
      |> Enum.flat_map(& &1.children)
      |> Enum.find_value(&find_node(&1, id))
    end
  end

  defp find_node(nil, _id), do: nil
end
