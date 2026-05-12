defmodule AshUI.DSL.EventCalloutTest do
  @moduledoc """
  Tests for the event_callout widget admission in DSL storage,
  IUR adapter mapping, and HEEx rendering via both renderers.
  """

  use ExUnit.Case, async: true

  alias AshUI.DSL.Storage
  alias AshUI.Rendering.IURAdapter
  alias AshUI.Rendering.LiveUIAdapter

  # ── Storage admission ─────────────────────────────────────────

  describe "valid_widget_type?/1" do
    test "event_callout is admitted as a valid widget type" do
      assert Storage.valid_widget_type?("event_callout") == true
    end

    test "event_callout DSL validates successfully" do
      dsl = %{
        type: "event_callout",
        props: %{"tone" => "info", "text" => "Ingestion completed."},
        children: [],
        signals: [],
        metadata: %{}
      }

      assert Storage.validate_write(dsl) == :ok
    end

    test "event_callout with kicker prop validates successfully" do
      dsl = %{
        type: "event_callout",
        props: %{"tone" => "warn", "kicker" => "Warning", "text" => "Schema mismatch."},
        children: [],
        signals: [],
        metadata: %{}
      }

      assert Storage.validate_write(dsl) == :ok
    end
  end

  # ── IURAdapter mapping ────────────────────────────────────────

  describe "IURAdapter.to_canonical/2 — event_callout element" do
    test "maps :event_callout atom to \"event_callout\" string in canonical IUR" do
      alias AshUI.Compilation.IUR

      ash_iur =
        struct(IUR,
          id: "screen-1",
          type: :screen,
          name: "test_screen",
          attributes: %{"layout" => :column},
          children: [
            struct(IUR,
              id: "callout-1",
              type: :event_callout,
              name: "callout",
              props: %{"tone" => "info", "text" => "All good."},
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
      assert child["type"] == "event_callout"
    end
  end

  # ── LiveUIAdapter rendering ───────────────────────────────────

  describe "LiveUIAdapter — event_callout rendering" do
    defp callout_iur(props, children \\ []) do
      %{
        "type" => "screen",
        "id" => "screen-1",
        "name" => "test_screen",
        "layout" => "column",
        "children" => [
          %{
            "type" => "event_callout",
            "id" => "callout-1",
            "props" => props,
            "children" => children,
            "metadata" => %{}
          }
        ],
        "bindings" => [],
        "metadata" => %{}
      }
    end

    test "renders event_callout with data-tone info" do
      assert {:ok, heex} = LiveUIAdapter.render(callout_iur(%{"tone" => "info"}))

      assert heex =~ "ash-event-callout"
      assert heex =~ ~s(data-tone="info")
    end

    test "renders event_callout with data-tone warn" do
      assert {:ok, heex} = LiveUIAdapter.render(callout_iur(%{"tone" => "warn"}))

      assert heex =~ ~s(data-tone="warn")
    end

    test "renders event_callout with data-tone success" do
      assert {:ok, heex} = LiveUIAdapter.render(callout_iur(%{"tone" => "success"}))

      assert heex =~ ~s(data-tone="success")
    end

    test "renders kicker when kicker prop is present" do
      assert {:ok, heex} =
               LiveUIAdapter.render(
                 callout_iur(%{"tone" => "warn", "kicker" => "Warning", "text" => "body"})
               )

      assert heex =~ "Warning"
      assert heex =~ "ash-event-callout-kicker"
    end

    test "omits kicker element when kicker prop is absent" do
      assert {:ok, heex} = LiveUIAdapter.render(callout_iur(%{"tone" => "info", "text" => "body"}))

      refute heex =~ "ash-event-callout-kicker"
    end

    test "renders body text from text prop" do
      assert {:ok, heex} =
               LiveUIAdapter.render(callout_iur(%{"tone" => "info", "text" => "Analysis complete."}))

      assert heex =~ "Analysis complete."
      assert heex =~ "ash-event-callout-body"
    end

    test "default tone is info when tone prop is omitted" do
      assert {:ok, heex} = LiveUIAdapter.render(callout_iur(%{"text" => "body"}))

      assert heex =~ ~s(data-tone="info")
    end
  end

  # ── LiveUI.Renderer (fallback renderer) ──────────────────────

  describe "LiveUI.Renderer — event_callout rendering" do
    defp renderer_callout_iur(props, children \\ []) do
      %{
        "type" => "event_callout",
        "id" => "callout-1",
        "props" => props,
        "children" => children,
        "metadata" => %{}
      }
    end

    test "renders event_callout section with base class" do
      assert {:ok, heex} = LiveUI.Renderer.render(renderer_callout_iur(%{"tone" => "info"}))

      assert heex =~ "ash-event-callout"
    end

    test "renders data-tone attribute" do
      assert {:ok, heex} = LiveUI.Renderer.render(renderer_callout_iur(%{"tone" => "success"}))

      assert heex =~ ~s(data-tone="success")
    end

    test "renders kicker text when provided" do
      assert {:ok, heex} =
               LiveUI.Renderer.render(
                 renderer_callout_iur(%{"tone" => "info", "kicker" => "Info", "text" => "body"})
               )

      assert heex =~ "Info"
      assert heex =~ "ash-event-callout-kicker"
    end
  end
end
