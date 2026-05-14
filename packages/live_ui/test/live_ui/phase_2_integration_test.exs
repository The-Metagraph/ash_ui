defmodule LiveUi.Phase2IntegrationTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias UnifiedIUR.{Container, Forms, Layout}
  alias UnifiedIUR.Widgets.{Foundational, Input, Navigation}

  defmodule NativeWorkflowScreen do
    use LiveUi.Screen, id: :native_workflow, title: "Native Workflow"

    @impl true
    def mount_defaults do
      %{name: "Pascal", active_tab: "details"}
    end

    @impl true
    def event_routes do
      %{
        "switch_tab" => :switch_tab,
        "rename" => :rename
      }
    end

    @impl true
    def handle_event(:switch_tab, %{"tab" => tab}, assigns) do
      {:ok, %{assigns | active_tab: tab}}
    end

    @impl true
    def handle_event(:rename, %{"name" => name}, assigns) do
      {:ok, %{assigns | name: name}}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <LiveUi.Widgets.ScreenShell.render id="native-workflow" title={title()}>
        <LiveUi.Forms.FormBuilder.render id="profile-form">
          <LiveUi.Forms.Field.render id="name-field" name="name">
            <:label>Name</:label>
            <:control>
              <LiveUi.Widgets.TextInput.render id="name" name="name" value={@name} />
            </:control>
          </LiveUi.Forms.Field.render>
        </LiveUi.Forms.FormBuilder.render>

        <LiveUi.Widgets.Tabs.render
          id="tabs"
          active_item={@active_tab}
          items={[
            %{id: "details", label: "Details"},
            %{id: "activity", label: "Activity"}
          ]}
        />

        <LiveUi.Layout.Row.render id="row">
          <LiveUi.Widgets.Text.render id="name-display" content={@name} />
          <LiveUi.Widgets.Text.render id="tab-display" content={@active_tab} />
        </LiveUi.Layout.Row.render>
      </LiveUi.Widgets.ScreenShell.render>
      """
    end
  end

  test "foundational native screens preserve assigns-driven state updates through the runtime backbone" do
    assert {:ok, runtime_state} = LiveUi.Runtime.mount(NativeWorkflowScreen)

    assert {:ok, runtime_state} =
             LiveUi.Runtime.handle_event(runtime_state, "rename", %{"name" => "Ari"})

    assert {:ok, runtime_state} =
             LiveUi.Runtime.handle_event(runtime_state, "switch_tab", %{"tab" => "activity"})

    html =
      render_component(LiveUi.Runtime.component(), id: "native", runtime_state: runtime_state)

    assert html =~ "data-live-ui-widget=\"form-builder\""
    assert html =~ "data-live-ui-widget=\"tabs\""
    assert html =~ "Ari"
    assert html =~ "activity"
  end

  test "foundational layout primitives preserve child ordering and slot semantics" do
    html =
      render_component(&LiveUi.Layout.Column.render/1, %{
        id: "column",
        inner_block: [
          %{
            __slot__: :inner_block,
            inner_block: fn _, _ ->
              Phoenix.HTML.raw("""
              #{render_component(&LiveUi.Layout.Row.render/1, %{id: "row", inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "First" end}, %{__slot__: :inner_block, inner_block: fn _, _ -> "Second" end}]})}
              #{render_component(&LiveUi.Layout.Grid.render/1, %{id: "grid", columns: 2, inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Third" end}]})}
              """)
            end
          }
        ]
      })

    assert html =~ "data-live-ui-widget=\"column\""
    assert html =~ "data-live-ui-widget=\"row\""
    assert html =~ "data-live-ui-widget=\"grid\""
    assert html =~ "First"
    assert html =~ "Second"
    assert html =~ "Third"
  end

  test "canonical foundational widgets and layouts reuse the same native widget families" do
    canonical =
      Container.box(
        [
          Layout.column([
            Foundational.label("Status"),
            Foundational.text("online"),
            Input.select(
              [
                %{value: "draft", label: "Draft"},
                %{value: "published", label: "Published", selected?: true}
              ],
              name: "status"
            ),
            Navigation.menu(
              [
                %{id: "details", label: "Details", active?: true},
                %{id: "activity", label: "Activity"}
              ],
              active_item: "details"
            )
          ])
        ],
        id: "canonical-root"
      )

    assert {:ok, runtime_state} = LiveUi.Runtime.mount_iur(canonical)

    html =
      render_component(LiveUi.Runtime.component(), id: "canonical", runtime_state: runtime_state)

    assert html =~ "data-live-ui-widget=\"box\""
    assert html =~ "data-live-ui-widget=\"column\""
    assert html =~ "data-live-ui-widget=\"label\""
    assert html =~ "data-live-ui-widget=\"text\""
    assert html =~ "data-live-ui-widget=\"select\""
    assert html =~ "data-live-ui-widget=\"menu\""
  end

  test "canonical foundational rendering stays deterministic and examples remain comparable" do
    left =
      Forms.form_builder(
        [
          Forms.field_group(
            [
              Forms.field(
                Input.text_input(name: "name", value: "Pascal"),
                id: "name-field",
                name: "name",
                label: "Name"
              )
            ],
            legend: "Identity"
          )
        ],
        id: "profile-form"
      )

    right = LiveUi.Examples.CanonicalForm.element()

    left_html = render_component(&LiveUi.Renderer.render/1, %{element: left})
    right_html = render_component(&LiveUi.Renderer.render/1, %{element: right})
    native_html = render_component(&LiveUi.Examples.NativeFormScreen.render/1, %{name: "Pascal"})

    assert String.replace(left_html, "profile-form", "canonical-form") == right_html
    assert native_html =~ "data-live-ui-widget=\"form-builder\""
    assert right_html =~ "data-live-ui-widget=\"form-builder\""
    assert right_html =~ "data-live-ui-widget=\"field\""
    assert right_html =~ "data-live-ui-widget=\"text-input\""
  end
end
