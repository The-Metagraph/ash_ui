defmodule AshUI.DSL.RedlineInlineTest do
  @moduledoc """
  Tests for the redline_inline widget admission in DSL storage,
  IUR adapter mapping, and HEEx rendering via both renderers.
  """

  use ExUnit.Case, async: true

  alias AshUI.DSL.Storage
  alias AshUI.Rendering.IURAdapter
  alias AshUI.Rendering.LiveUIAdapter

  # ── Storage admission ─────────────────────────────────────────

  describe "valid_widget_type?/1" do
    test "redline_inline is admitted as a valid widget type" do
      assert Storage.valid_widget_type?("redline_inline") == true
    end

    test "redline_inline DSL with segments validates successfully" do
      dsl = %{
        type: "redline_inline",
        props: %{
          "state" => "proposed",
          "segments" => [
            %{"type" => "keep", "content" => "The "},
            %{"type" => "del", "content" => "old"},
            %{"type" => "ins", "content" => "new"},
            %{"type" => "keep", "content" => " text."}
          ]
        },
        children: [],
        signals: [],
        metadata: %{}
      }

      assert Storage.validate_write(dsl) == :ok
    end

    test "redline_inline DSL in accepted state validates successfully" do
      dsl = %{
        type: "redline_inline",
        props: %{"state" => "accepted", "segments" => []},
        children: [],
        signals: [],
        metadata: %{}
      }

      assert Storage.validate_write(dsl) == :ok
    end
  end

  # ── IURAdapter mapping ────────────────────────────────────────

  describe "IURAdapter.to_canonical/2 — redline_inline element" do
    test "maps :redline_inline atom to \"redline_inline\" string in canonical IUR" do
      alias AshUI.Compilation.IUR

      ash_iur =
        struct(IUR,
          id: "screen-1",
          type: :screen,
          name: "test_screen",
          attributes: %{"layout" => :column},
          children: [
            struct(IUR,
              id: "redline-1",
              type: :redline_inline,
              name: "redline",
              props: %{
                "state" => "proposed",
                "segments" => [%{"type" => "keep", "content" => "hello"}]
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
      assert child["type"] == "redline_inline"
    end
  end

  # ── LiveUIAdapter rendering ───────────────────────────────────

  describe "LiveUIAdapter — redline_inline rendering" do
    defp redline_iur(props) do
      %{
        "type" => "screen",
        "id" => "screen-1",
        "name" => "test_screen",
        "layout" => "column",
        "children" => [
          %{
            "type" => "redline_inline",
            "id" => "redline-1",
            "props" => props,
            "children" => [],
            "metadata" => %{}
          }
        ],
        "bindings" => [],
        "metadata" => %{}
      }
    end

    test "renders redline_inline span with base class" do
      assert {:ok, heex} = LiveUIAdapter.render(redline_iur(%{"state" => "proposed"}))

      assert heex =~ "ash-redline-inline"
    end

    test "renders data-state=proposed by default" do
      assert {:ok, heex} = LiveUIAdapter.render(redline_iur(%{}))

      assert heex =~ ~s(data-state="proposed")
    end

    test "renders del and ins in proposed state" do
      segments = [
        %{"type" => "keep", "content" => "The "},
        %{"type" => "del", "content" => "old"},
        %{"type" => "ins", "content" => "new"}
      ]

      assert {:ok, heex} =
               LiveUIAdapter.render(
                 redline_iur(%{"state" => "proposed", "segments" => segments})
               )

      assert heex =~ "<del>old</del>"
      assert heex =~ "<ins>new</ins>"
      assert heex =~ "The "
    end

    test "accepted state strips del segments" do
      segments = [
        %{"type" => "del", "content" => "removed"},
        %{"type" => "ins", "content" => "added"}
      ]

      assert {:ok, heex} =
               LiveUIAdapter.render(
                 redline_iur(%{"state" => "accepted", "segments" => segments})
               )

      refute heex =~ "<del"
      refute heex =~ "removed"
      assert heex =~ "<ins>added</ins>"
    end

    test "rejected state strips ins segments" do
      segments = [
        %{"type" => "del", "content" => "original"},
        %{"type" => "ins", "content" => "proposal"}
      ]

      assert {:ok, heex} =
               LiveUIAdapter.render(
                 redline_iur(%{"state" => "rejected", "segments" => segments})
               )

      refute heex =~ "<ins"
      refute heex =~ "proposal"
      assert heex =~ "<del>original</del>"
    end

    test "HTML-escapes segment content to prevent XSS" do
      segments = [%{"type" => "ins", "content" => "<script>alert('xss')</script>"}]

      assert {:ok, heex} =
               LiveUIAdapter.render(
                 redline_iur(%{"state" => "proposed", "segments" => segments})
               )

      refute heex =~ "<script>"
      assert heex =~ "&lt;script&gt;"
    end
  end

  # ── LiveUI.Renderer (fallback renderer) ──────────────────────

  describe "LiveUI.Renderer — redline_inline rendering" do
    defp renderer_redline_iur(props) do
      %{
        "type" => "redline_inline",
        "id" => "redline-1",
        "props" => props,
        "children" => [],
        "metadata" => %{}
      }
    end

    test "renders redline_inline span with base class" do
      assert {:ok, heex} = LiveUI.Renderer.render(renderer_redline_iur(%{"state" => "proposed"}))

      assert heex =~ "ash-redline-inline"
    end

    test "renders del and ins in proposed state" do
      segments = [
        %{"type" => "del", "content" => "old"},
        %{"type" => "ins", "content" => "new"}
      ]

      assert {:ok, heex} =
               LiveUI.Renderer.render(renderer_redline_iur(%{"state" => "proposed", "segments" => segments}))

      assert heex =~ "<del>old</del>"
      assert heex =~ "<ins>new</ins>"
    end

    test "accepted state strips del segments" do
      segments = [%{"type" => "del", "content" => "gone"}]

      assert {:ok, heex} =
               LiveUI.Renderer.render(renderer_redline_iur(%{"state" => "accepted", "segments" => segments}))

      refute heex =~ "<del"
      refute heex =~ "gone"
    end

    test "HTML-escapes content in renderer" do
      segments = [%{"type" => "keep", "content" => "cats & dogs"}]

      assert {:ok, heex} =
               LiveUI.Renderer.render(renderer_redline_iur(%{"state" => "proposed", "segments" => segments}))

      assert heex =~ "cats &amp; dogs"
    end
  end
end
