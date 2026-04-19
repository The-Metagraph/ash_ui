defmodule AshUI.ConformanceTraceabilityTest do
  use ExUnit.Case, async: true

  @moduletag :conformance

  @repo_root Path.expand("../..", __DIR__)
  @state_path Path.join(@repo_root, ".spec/state.json")

  test "spec workspace validates and writes generated state" do
    {output, status} = AshUI.TestShell.run_spec_validate(@repo_root)

    assert status == 0, output
    assert File.exists?(@state_path)

    state = Jason.decode!(File.read!(@state_path))
    subjects = get_in(state, ["index", "subjects"]) || []
    decisions = get_in(state, ["decisions", "items"]) || []

    assert state["summary"]["subjects"] >= 6
    assert length(subjects) >= 6
    assert length(decisions) >= 4
  end
end
