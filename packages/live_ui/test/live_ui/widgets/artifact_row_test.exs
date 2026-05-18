defmodule LiveUi.Widgets.ArtifactRowTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component
  alias UnifiedIUR.Interaction

  @moduledoc """
  Tests for the ArtifactRow widget Phoenix.Component.

  Covers:
  - Widget metadata / family registration
  - Component renders all attrs correctly
  - Each `kind` sets the right glyph and `data-artifact-kind`
  - `selected?` adds `aria-selected="true"` and the selected CSS modifier
  - `status_badges` render with `is-tone-{tone}` classes
  - `counts` render with `data-count-key`
  - Actions slot renders when given
  - Renderer integration: `:artifact_row` IUR element dispatches to this component
  """

  describe "artifact_row widget metadata" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.ArtifactRow)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.ArtifactRow.Component
      assert metadata.family == :data
      assert metadata.name == :artifact_row
    end

    test "has actions slot registered" do
      metadata = Component.metadata(LiveUi.Widgets.ArtifactRow)

      assert :actions in metadata.slots
    end

    test "has click event registered" do
      metadata = Component.metadata(LiveUi.Widgets.ArtifactRow)

      assert :click in metadata.events
    end

    test "is present in data modules list" do
      assert LiveUi.Widgets.ArtifactRow in LiveUi.Widgets.Data.modules()
    end
  end

  describe "artifact_row component rendering" do
    test "renders with widget boundary and data-live-ui-widget attribute" do
      html =
        render_component(&LiveUi.Widgets.ArtifactRow.component/1, %{
          id: "ar-1",
          title: "My Artifact"
        })

      assert html =~ ~s(data-live-ui-widget-boundary="artifact_row")
      assert html =~ ~s(data-live-ui-widget="artifact-row")
      assert html =~ "My Artifact"
    end

    test "renders title and subtitle" do
      html =
        render_component(&LiveUi.Widgets.ArtifactRow.component/1, %{
          id: "ar-2",
          title: "PR Title",
          subtitle: "Some secondary info"
        })

      assert html =~ "PR Title"
      assert html =~ "Some secondary info"
    end

    test "subtitle is omitted when nil" do
      html =
        render_component(&LiveUi.Widgets.ArtifactRow.component/1, %{
          id: "ar-no-sub",
          title: "No Subtitle"
        })

      refute html =~ "live-ui-artifact-row__subtitle"
    end

    test "renders default kind as :generic" do
      html =
        render_component(&LiveUi.Widgets.ArtifactRow.component/1, %{
          id: "ar-default-kind",
          title: "Default"
        })

      assert html =~ ~s(data-artifact-kind="generic")
    end
  end

  describe "kind glyphs and data-artifact-kind" do
    for {kind, expected_glyph} <- [
          {:pr, "↳"},
          {:doc, "❐"},
          {:spec, "✓"},
          {:file, "□"},
          {:grain, "◆"},
          {:generic, "○"}
        ] do
      @kind kind
      @glyph expected_glyph

      test "kind #{kind} sets data-artifact-kind and renders glyph #{expected_glyph}" do
        html =
          render_component(&LiveUi.Widgets.ArtifactRow.component/1, %{
            id: "ar-kind-#{@kind}",
            title: "#{@kind} artifact",
            kind: @kind
          })

        assert html =~ ~s(data-artifact-kind="#{@kind}")
        assert html =~ @glyph
      end
    end
  end

  describe "selected state" do
    test "selected? true sets aria-selected=true and CSS modifier" do
      html =
        render_component(&LiveUi.Widgets.ArtifactRow.component/1, %{
          id: "ar-selected",
          title: "Selected Row",
          selected?: true
        })

      assert html =~ ~s(aria-selected="true")
      assert html =~ "is-selected"
    end

    test "selected? false sets aria-selected=false and no selected modifier" do
      html =
        render_component(&LiveUi.Widgets.ArtifactRow.component/1, %{
          id: "ar-not-selected",
          title: "Not Selected",
          selected?: false
        })

      assert html =~ ~s(aria-selected="false")
      refute html =~ "is-selected"
    end

    test "selected? defaults to false" do
      html =
        render_component(&LiveUi.Widgets.ArtifactRow.component/1, %{
          id: "ar-default-selected",
          title: "Default Selection"
        })

      assert html =~ ~s(aria-selected="false")
      refute html =~ "is-selected"
    end
  end

  describe "status_badges" do
    test "renders status badges with label and tone class" do
      html =
        render_component(&LiveUi.Widgets.ArtifactRow.component/1, %{
          id: "ar-badges",
          title: "Badged Row",
          status_badges: [
            %{label: "Open", tone: :positive},
            %{label: "Draft", tone: :warning}
          ]
        })

      assert html =~ "Open"
      assert html =~ "is-tone-positive"
      assert html =~ "Draft"
      assert html =~ "is-tone-warning"
    end

    test "renders badges without tone class when tone is nil" do
      html =
        render_component(&LiveUi.Widgets.ArtifactRow.component/1, %{
          id: "ar-badge-no-tone",
          title: "No Tone",
          status_badges: [%{label: "Merged"}]
        })

      assert html =~ "Merged"
      refute html =~ "is-tone-"
    end

    test "empty status_badges renders no badge markup" do
      html =
        render_component(&LiveUi.Widgets.ArtifactRow.component/1, %{
          id: "ar-no-badges",
          title: "Clean Row",
          status_badges: []
        })

      refute html =~ "live-ui-artifact-row__status-badge"
    end
  end

  describe "counts" do
    test "renders count chips with data-count-key" do
      html =
        render_component(&LiveUi.Widgets.ArtifactRow.component/1, %{
          id: "ar-counts",
          title: "With Counts",
          counts: [
            %{key: :comments, value: 5, label: "Comments"},
            %{key: :replies, value: 2}
          ]
        })

      assert html =~ ~s(data-count-key="comments")
      assert html =~ ~s(data-count-key="replies")
      assert html =~ "Comments"
      assert html =~ "2"
    end

    test "empty counts renders no count markup" do
      html =
        render_component(&LiveUi.Widgets.ArtifactRow.component/1, %{
          id: "ar-no-counts",
          title: "No Counts",
          counts: %{}
        })

      refute html =~ "data-count-key"
    end
  end

  describe "timestamp" do
    test "renders timestamp element when timestamp_at is given" do
      ts = ~U[2026-01-01 10:00:00Z]

      html =
        render_component(&LiveUi.Widgets.ArtifactRow.component/1, %{
          id: "ar-ts",
          title: "Timestamped",
          timestamp_at: ts
        })

      assert html =~ ~s(<time)
      assert html =~ "2026-01-01"
    end

    test "no timestamp element rendered when timestamp_at is nil" do
      html =
        render_component(&LiveUi.Widgets.ArtifactRow.component/1, %{
          id: "ar-no-ts",
          title: "No Timestamp"
        })

      refute html =~ ~s(<time)
    end
  end

  describe "actions slot" do
    test "actions slot renders rendered content when provided" do
      # Drive the render/1 function directly with a synthesized actions slot
      # so we do not need ~H inside the test module.
      html =
        render_component(&LiveUi.Widgets.ArtifactRow.render/1, %{
          id: "ar-actions",
          title: "With Actions",
          subtitle: nil,
          kind: :doc,
          selected?: false,
          active?: false,
          status_badges: [],
          counts: %{},
          timestamp_at: nil,
          tone: nil,
          variant: nil,
          state: nil,
          class: nil,
          metadata: %{},
          rest: %{},
          actions: [
            %{
              __slot__: :actions,
              inner_block: fn _changed, _arg -> "Merge" end
            }
          ]
        })

      assert html =~ "live-ui-artifact-row__actions"
      assert html =~ "Merge"
    end

    test "actions slot wrapper is absent when no actions given" do
      html =
        render_component(&LiveUi.Widgets.ArtifactRow.render/1, %{
          id: "ar-no-actions",
          title: "No Actions",
          subtitle: nil,
          kind: :generic,
          selected?: false,
          active?: false,
          status_badges: [],
          counts: %{},
          timestamp_at: nil,
          tone: nil,
          variant: nil,
          state: nil,
          class: nil,
          metadata: %{},
          rest: %{},
          actions: []
        })

      refute html =~ "live-ui-artifact-row__actions"
    end
  end

  describe "renderer integration" do
    test "artifact_row kind is in supported_kinds" do
      assert :artifact_row in LiveUi.Renderer.supported_kinds()
    end

    test "artifact_row renders via IUR element through the dedicated renderer clause" do
      element =
        UnifiedIUR.Widgets.Components.artifact_row("PR #42 — Add widget", [],
          title: "PR #42 — Add widget"
        )

      html =
        Phoenix.HTML.raw(render_component(&LiveUi.Renderer.render/1, %{element: element}))
        |> Phoenix.HTML.safe_to_string()

      assert html =~ ~s(data-live-ui-widget="artifact-row")
      assert html =~ "PR #42"
      # Must NOT fall through to the generic unsupported-component fallback
      refute html =~ ~s(data-live-ui-unsupported-native-component="fallback")
      refute html =~ "Unsupported canonical kind"
    end

    test "artifact_row renderer consumes first-class canonical artifact fields" do
      element =
        UnifiedIUR.Widgets.Components.artifact_row(
          "Spec Subject",
          [
            UnifiedIUR.Widgets.Foundational.button("Open")
          ],
          artifact_kind: :spec,
          status_badges: [%{label: "Accepted", tone: :positive}],
          counts: [%{key: :comments, value: 3, label: "Comments"}],
          timestamp_at: "2026-05-18T10:00:00Z",
          active?: true,
          interactions: [Interaction.click(intent: :open_artifact)]
        )

      html =
        Phoenix.HTML.raw(
          render_component(&LiveUi.Renderer.render/1, %{element: element, event_target: "#target"})
        )
        |> Phoenix.HTML.safe_to_string()

      assert html =~ ~s(data-artifact-kind="spec")
      assert html =~ ~s(aria-selected="true")
      assert html =~ "Accepted"
      assert html =~ "is-tone-positive"
      assert html =~ ~s(data-count-key="comments")
      assert html =~ "Comments"
      assert html =~ ~s(datetime="2026-05-18T10:00:00Z")
      assert html =~ "Open"
      assert html =~ ~s(phx-click="canonical_interaction")
    end

    test "artifact_row IUR element does not produce unsupported-component output" do
      element = UnifiedIUR.Widgets.Components.artifact_row("Spec Subject")

      html =
        Phoenix.HTML.raw(render_component(&LiveUi.Renderer.render/1, %{element: element}))
        |> Phoenix.HTML.safe_to_string()

      refute html =~ ~s(data-live-ui-unsupported-native-component)
    end
  end
end
