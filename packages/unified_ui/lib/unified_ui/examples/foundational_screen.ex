defmodule UnifiedUi.Examples.FoundationalScreen do
  @moduledoc """
  Reference screen for foundational widgets and baseline layout primitives.
  """

  use UnifiedUi.Dsl

  identity do
    id(:foundational_example)
    title("Foundational Example")
    authored_ref([:examples, :foundational_example])
    tags([:example, :foundational])
  end

  composition do
    root(:foundational_example_root)
    mode(:screen)

    box :shell do
      summary("Foundational shell")

      text :headline do
        value("Welcome to UnifiedUi")
      end

      button :primary_action do
        label("Get started")
        action_intent(:start)
      end
    end

    row :shortcut_bar do
      menu :main_menu do
        items(home: "Home", docs: "Docs")
        active_item(:home)
      end

      link :docs_link do
        label("Open docs")
        target("https://specled.dev/home")
      end
    end
  end
end
