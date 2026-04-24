defmodule AshUI.Test.ExampleSuiteAuthoringDomain do
  @moduledoc false

  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource(AshUI.Test.ExampleSuiteScreen)
    resource(AshUI.Test.ExampleSuiteDemoPanelElement)
    resource(AshUI.Test.ExampleSuiteCurrentValueElement)
    resource(AshUI.Test.ExampleSuiteButtonElement)
    resource(AshUI.Test.ExampleSuiteStoryTextElement)
    resource(AshUI.Test.ExampleSuiteSignalTextElement)
  end
end

defmodule AshUI.Test.ExampleSuiteElementBase do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      use Ash.Resource,
        domain: AshUI.Test.ExampleSuiteAuthoringDomain,
        data_layer: Ash.DataLayer.Ets

      use AshUI.Resource.DSL.Element

      ets do
        private?(true)
      end

      attributes do
        uuid_primary_key(:id)
        attribute(:screen_id, :uuid, allow_nil?: true)
        attribute(:parent_id, :uuid, allow_nil?: true)
      end

      actions do
        defaults([:read])
      end
    end
  end
end

defmodule AshUI.Test.ExampleSuiteDemoPanelElement do
  @moduledoc false

  use AshUI.Test.ExampleSuiteElementBase

  relationships do
    has_many :current_values, AshUI.Test.ExampleSuiteCurrentValueElement do
      destination_attribute(:parent_id)
    end

    has_many :actions_companions, AshUI.Test.ExampleSuiteButtonElement do
      destination_attribute(:parent_id)
    end
  end

  ui_relationships do
    relationship :current_values do
      kind :child
      slot :body
      placement :append
      order 0
    end

    relationship :actions_companions do
      kind :companion
      slot :actions
      placement :append
      order 1
    end
  end

  ui_element do
    type :card
    props %{title: "Button Example"}
    metadata %{id: "example-button-demo", section: "demo", slot: "body", position: 0}
  end
end

defmodule AshUI.Test.ExampleSuiteCurrentValueElement do
  @moduledoc false

  use AshUI.Test.ExampleSuiteElementBase

  ui_element do
    type :stat
    props %{title: "Current display name", value: "unhydrated"}
    variants [:primary]
    metadata %{id: "example-button-current-value", section: "demo", slot: "body", position: 0}
  end

  ui_bindings do
    binding :current_display_name do
      source %{resource: "User", field: "name"}
      target "value"
      binding_type :value
      transform %{}
      metadata %{owner: "current_value"}
    end
  end
end

defmodule AshUI.Test.ExampleSuiteButtonElement do
  @moduledoc false

  use AshUI.Test.ExampleSuiteElementBase

  ui_element do
    type :button
    props %{label: "Save profile"}
    variants [:primary]
    metadata %{id: "example-button-save", section: "demo", slot: "actions", position: 1}
  end

  ui_actions do
    action :save_profile do
      signal :click
      source %{resource: "User", action: "update"}
      target "submit"

      transform %{
        params: %{
          nickname: %{"from" => "binding", "key" => "current_display_name"}
        }
      }

      metadata %{intent: "save_profile"}
    end
  end
end

defmodule AshUI.Test.ExampleSuiteStoryTextElement do
  @moduledoc false

  use AshUI.Test.ExampleSuiteElementBase

  ui_element do
    type :text

    props %{
      content:
        "Meaningful Interaction Story: review the bound display name and click Save profile to persist it as the current nickname."
    }

    metadata %{id: "example-button-story", section: "story", slot: "body", position: 10}
  end
end

defmodule AshUI.Test.ExampleSuiteSignalTextElement do
  @moduledoc false

  use AshUI.Test.ExampleSuiteElementBase

  ui_element do
    type :text

    props %{
      content:
        "Canonical Signal Preview: click -> save_profile -> User.update using the current_display_name binding."
    }

    metadata %{
      id: "example-button-signal-preview",
      section: "signal_preview",
      slot: "body",
      position: 20
    }
  end
end

defmodule AshUI.Test.ExampleSuiteScreen do
  @moduledoc false

  use Ash.Resource,
    domain: AshUI.Test.ExampleSuiteAuthoringDomain,
    data_layer: Ash.DataLayer.Ets

  use AshUI.Resource.DSL.Screen

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read])
  end

  relationships do
    has_many :demo_panels, AshUI.Test.ExampleSuiteDemoPanelElement do
      destination_attribute(:screen_id)
    end

    has_many :story_texts, AshUI.Test.ExampleSuiteStoryTextElement do
      destination_attribute(:screen_id)
    end

    has_many :signal_texts, AshUI.Test.ExampleSuiteSignalTextElement do
      destination_attribute(:screen_id)
    end
  end

  ui_relationships do
    relationship :demo_panels do
      kind :child
      slot :body
      placement :append
      order 0
    end

    relationship :story_texts do
      kind :child
      slot :body
      placement :append
      order 10
    end

    relationship :signal_texts do
      kind :child
      slot :body
      placement :append
      order 20
    end
  end

  ui_screen do
    layout :column
    route "/"

    metadata %{
      title: "Button Example",
      example_directory: "button",
      shell_id: "example-button-shell"
    }
  end

  ui_screen_bindings do
    binding :example_notice do
      source %{resource: "User", field: "nickname"}
      target "flash.notice"
      binding_type :value
      transform %{default: "ready"}
      metadata %{scope: "screen"}
    end
  end
end

defmodule AshUI.Test.ExampleSuiteFixtures do
  @moduledoc false

  alias AshUI.Data
  alias AshUI.Resource.Authority
  alias AshUI.Test.{
    Comment,
    ExampleSuiteScreen,
    Post,
    Profile,
    RuntimeDomain,
    RuntimeFixtures,
    UIStorageBinding,
    UIStorageElement,
    UIStorageFixtures,
    UIStorageScreen,
    User
  }

  @screen_name "example/button"

  def seed_screen! do
    reset!()

    runtime = RuntimeFixtures.seed!()
    ui_storage = UIStorageFixtures.ui_storage_config()

    {:ok, screen} =
      Authority.create(ExampleSuiteScreen,
        name: @screen_name,
        route: "/",
        metadata: %{"example_directory" => "button"},
        ui_storage: ui_storage,
        authorize?: false
      )

    %{
      runtime: runtime,
      screen: screen,
      screen_name: @screen_name,
      ui_storage: ui_storage,
      user_id: runtime.user.id
    }
  end

  def reset! do
    reset_ui_storage!()
    reset_runtime_domain!()
    :ok
  end

  defp reset_ui_storage! do
    ui_storage = UIStorageFixtures.ui_storage_config()

    [UIStorageBinding, UIStorageElement, UIStorageScreen]
    |> Enum.each(fn resource ->
      {:ok, records} = Data.read(resource, ui_storage: ui_storage, authorize?: false)

      Enum.each(records, fn record ->
        {:ok, _destroyed} = Data.destroy(record, ui_storage: ui_storage, authorize?: false)
      end)
    end)
  end

  defp reset_runtime_domain! do
    [Comment, Post, User, Profile]
    |> Enum.each(fn resource ->
      {:ok, records} = Ash.read(resource, domain: RuntimeDomain, authorize?: false)

      Enum.each(records, fn record ->
        {:ok, _destroyed} = Ash.destroy(record, domain: RuntimeDomain, authorize?: false)
      end)
    end)
  end
end
