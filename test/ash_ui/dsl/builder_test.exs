defmodule AshUI.DSL.BuilderTest do
  use ExUnit.Case, async: true

  alias AshUI.DSL.Builder
  alias AshUI.DSL.Storage

  describe "root/2" do
    test "creates a root DSL element" do
      dsl = Builder.root("row")

      assert dsl.type == "row"
      assert dsl.props == %{}
      assert dsl.children == []
      assert dsl.signals == []
    end

    test "accepts custom props" do
      dsl = Builder.root("row", props: %{spacing: 16})

      assert dsl.props == %{spacing: 16}
    end

    test "accepts children" do
      child = Builder.text("Hello")
      dsl = Builder.root("row", children: [child])

      assert dsl.children == [child]
    end

    test "accepts signals" do
      signal = %{type: :bidirectional, target: "name", source: "User.name"}
      dsl = Builder.root("row", signals: [signal])

      assert dsl.signals == [signal]
    end

    test "accepts metadata" do
      dsl = Builder.root("screen", metadata: %{title: "Dashboard"})

      assert dsl.metadata == %{title: "Dashboard"}
    end
  end

  describe "screen/1" do
    test "creates a screen layout" do
      child = Builder.text("Hello")
      dsl = Builder.screen(children: [child], layout: :stack)

      assert dsl.type == "screen"
      assert dsl.props.layout == :stack
      assert dsl.children == [child]
    end
  end

  describe "row/1" do
    test "creates a row layout" do
      dsl = Builder.row()

      assert dsl.type == "row"
      assert dsl.props.spacing == 8
      assert dsl.props.align == :start
      assert dsl.props.justify == :start
    end

    test "accepts custom spacing" do
      dsl = Builder.row(spacing: 16)

      assert dsl.props.spacing == 16
    end

    test "accepts custom alignment" do
      dsl = Builder.row(align: :center)

      assert dsl.props.align == :center
    end

    test "accepts children" do
      child = Builder.text("Hello")
      dsl = Builder.row(children: [child])

      assert dsl.children == [child]
    end
  end

  describe "column/1" do
    test "creates a column layout" do
      dsl = Builder.column()

      assert dsl.type == "column"
      assert dsl.props.spacing == 8
    end

    test "accepts custom spacing" do
      dsl = Builder.column(spacing: 24)

      assert dsl.props.spacing == 24
    end
  end

  describe "grid/1" do
    test "creates a grid layout" do
      dsl = Builder.grid()

      assert dsl.type == "grid"
      assert dsl.props.columns == 12
      assert dsl.props.spacing == 8
      assert dsl.props.align == :stretch
    end

    test "accepts custom columns" do
      dsl = Builder.grid(columns: 3)

      assert dsl.props.columns == 3
    end
  end

  describe "stack/1" do
    test "creates a stack layout" do
      dsl = Builder.stack()

      assert dsl.type == "stack"
      assert dsl.props.spacing == 0
      assert dsl.props.align == :stretch
      assert dsl.props.justify == :start
    end
  end

  describe "text/2" do
    test "creates a text widget" do
      dsl = Builder.text("Hello, World!")

      assert dsl.type == "text"
      assert dsl.props.content == "Hello, World!"
      assert dsl.props.size == 14
    end

    test "accepts custom size" do
      dsl = Builder.text("Hello", size: 24)

      assert dsl.props.size == 24
    end

    test "accepts custom color" do
      dsl = Builder.text("Hello", color: "blue")

      assert dsl.props.color == "blue"
    end

    test "accepts custom weight" do
      dsl = Builder.text("Hello", weight: :bold)

      assert dsl.props.weight == :bold
    end
  end

  describe "button/2" do
    test "creates a button widget" do
      dsl = Builder.button("Click Me")

      assert dsl.type == "button"
      assert dsl.props.label == "Click Me"
      assert dsl.props.variant == :primary
    end

    test "accepts on_click action" do
      dsl = Builder.button("Save", on_click: "save_action")

      assert dsl.props.on_click == "save_action"
      assert length(dsl.signals) == 1
      assert hd(dsl.signals).action == "save_action"
    end

    test "accepts variant" do
      dsl = Builder.button("Cancel", variant: :secondary)

      assert dsl.props.variant == :secondary
    end
  end

  describe "input/2" do
    test "creates an input widget" do
      dsl = Builder.input("name")

      assert dsl.type == "input"
      assert dsl.props.name == "name"
    end

    test "accepts placeholder" do
      dsl = Builder.input("email", placeholder: "Enter email")

      assert dsl.props.placeholder == "Enter email"
    end

    test "accepts bind_to for signals" do
      dsl = Builder.input("name", bind_to: "User.name")

      assert length(dsl.signals) == 1
      signal = hd(dsl.signals)
      assert signal.type == :bidirectional
      assert signal.target == "name"
      assert signal.source == "User.name"
    end
  end

  describe "input-like helpers" do
    test "textarea/2 creates a textarea widget" do
      dsl = Builder.textarea("bio", bind_to: "User.bio")

      assert dsl.type == "textarea"
      assert dsl.props.name == "bio"
      assert dsl.props.rows == 4
      assert hd(dsl.signals).source == "User.bio"
    end

    test "checkbox/2 creates a checkbox widget" do
      dsl = Builder.checkbox("terms", checked: true)

      assert dsl.type == "checkbox"
      assert dsl.props.name == "terms"
      assert dsl.props.checked == true
    end

    test "radio/2 creates a radio widget" do
      dsl = Builder.radio("plan", value: "pro", label: "Pro")

      assert dsl.type == "radio"
      assert dsl.props.name == "plan"
      assert dsl.props.value == "pro"
      assert dsl.props.label == "Pro"
    end

    test "switch/2 creates a switch widget" do
      dsl = Builder.switch("dark_mode", checked: true)

      assert dsl.type == "switch"
      assert dsl.props.name == "dark_mode"
      assert dsl.props.checked == true
    end

    test "slider/2 creates a slider widget" do
      dsl = Builder.slider("volume", min: 0, max: 10, step: 2, value: 6)

      assert dsl.type == "slider"
      assert dsl.props.name == "volume"
      assert dsl.props.min == 0
      assert dsl.props.max == 10
      assert dsl.props.step == 2
      assert dsl.props.value == 6
    end

    test "select/2 creates a select widget" do
      dsl = Builder.select("team", options: [{"Core", "core"}], bind_to: "User.team")

      assert dsl.type == "select"
      assert dsl.props.name == "team"
      assert dsl.props.options == [{"Core", "core"}]
      assert hd(dsl.signals).source == "User.team"
    end
  end

  describe "content helpers" do
    test "card/1 creates a card widget" do
      child = Builder.text("Summary")
      dsl = Builder.card(title: "Overview", children: [child])

      assert dsl.type == "card"
      assert dsl.props.title == "Overview"
      assert dsl.children == [child]
    end

    test "list/1 creates a list widget" do
      dsl = Builder.list(items: ["One", "Two"], ordered: true)

      assert dsl.type == "list"
      assert dsl.props.items == ["One", "Two"]
      assert dsl.props.ordered == true
    end

    test "table/1 creates a table widget" do
      dsl = Builder.table(columns: ["Name"], rows: [%{"Name" => "Ada"}])

      assert dsl.type == "table"
      assert dsl.props.columns == ["Name"]
      assert dsl.props.rows == [%{"Name" => "Ada"}]
    end

    test "image/2 creates an image widget" do
      dsl = Builder.image("/logo.png", alt: "Logo", width: 128)

      assert dsl.type == "image"
      assert dsl.props.src == "/logo.png"
      assert dsl.props.alt == "Logo"
      assert dsl.props.width == 128
    end

    test "icon/2 creates an icon widget" do
      dsl = Builder.icon("sparkles", size: 24)

      assert dsl.type == "icon"
      assert dsl.props.name == "sparkles"
      assert dsl.props.size == 24
    end

    test "divider/1 creates a divider widget" do
      dsl = Builder.divider(orientation: :vertical, thickness: 2)

      assert dsl.type == "divider"
      assert dsl.props.orientation == :vertical
      assert dsl.props.thickness == 2
    end

    test "spacer/1 creates a spacer widget" do
      dsl = Builder.spacer(size: 24, axis: :horizontal)

      assert dsl.type == "spacer"
      assert dsl.props.size == 24
      assert dsl.props.axis == :horizontal
    end
  end

  describe "container/2" do
    test "creates a custom container" do
      dsl = Builder.container("div", padding: 16, background: "white")

      assert dsl.type == "div"
      assert dsl.props.padding == 16
      assert dsl.props.background == "white"
    end

    test "accepts children" do
      child = Builder.text("Hello")
      dsl = Builder.container("div", children: [child])

      assert dsl.children == [child]
    end

    test "does not leak reserved options into props" do
      child = Builder.text("Hello")
      dsl = Builder.container("div", children: [child], metadata: %{section: "hero"})

      refute Map.has_key?(dsl.props, :children)
      refute Map.has_key?(dsl.props, :metadata)
      assert dsl.metadata == %{section: "hero"}
    end
  end

  describe "add_signal/4" do
    test "adds a signal to an element" do
      element = Builder.text("Hello")
      element = Builder.add_signal(element, :bidirectional, "name", "User.name")

      assert length(element.signals) == 1
      signal = hd(element.signals)
      assert signal.type == :bidirectional
    end
  end

  describe "merge/1" do
    test "merges multiple elements into fragment" do
      elements = [
        Builder.text("Hello"),
        Builder.text("World")
      ]

      dsl = Builder.merge(elements)

      assert dsl.type == "fragment"
      assert length(dsl.children) == 2
    end
  end

  describe "validate/1" do
    test "returns :ok for valid DSL" do
      dsl = Builder.text("Hello")

      assert Builder.validate(dsl) == :ok
    end

    test "returns errors for missing type" do
      invalid = %{props: %{}, children: [], signals: []}

      assert {:error, errors} = Builder.validate(invalid)
      assert "Missing or invalid type field" in errors
    end

    test "returns errors for invalid children" do
      invalid = %{type: "text", props: %{}, children: "not a list", signals: []}

      assert {:error, errors} = Builder.validate(invalid)
      assert "Children must be a list" in errors
    end

    test "all widget helpers produce storage-valid DSL nodes" do
      helpers = [
        Builder.screen(children: [Builder.text("Screen")]),
        Builder.row(),
        Builder.column(),
        Builder.grid(),
        Builder.stack(),
        Builder.text("Text"),
        Builder.button("Save"),
        Builder.input("name"),
        Builder.textarea("bio"),
        Builder.checkbox("terms"),
        Builder.radio("plan"),
        Builder.switch("enabled"),
        Builder.slider("volume"),
        Builder.select("team"),
        Builder.card(),
        Builder.list(),
        Builder.table(),
        Builder.image("/logo.png"),
        Builder.icon("sparkles"),
        Builder.divider(),
        Builder.spacer(),
        Builder.container("custom:hero"),
        Builder.merge([Builder.text("Fragment")])
      ]

      Enum.each(helpers, fn dsl ->
        assert :ok = Builder.validate(dsl)
        assert :ok = Storage.validate_write(dsl)
        assert Storage.valid_widget_type?(dsl.type)
      end)
    end
  end
end
