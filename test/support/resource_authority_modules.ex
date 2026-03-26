defmodule AshUI.Test.ResourceAuthorityDomain do
  @moduledoc false

  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource(AshUI.Test.ResourceAuthorityScreen)
    resource(AshUI.Test.ResourceAuthorityStatElement)
    resource(AshUI.Test.ResourceAuthorityFormElement)
  end
end

defmodule AshUI.Test.ResourceAuthorityStatElement do
  @moduledoc false

  use Ash.Resource,
    domain: AshUI.Test.ResourceAuthorityDomain,
    data_layer: Ash.DataLayer.Ets

  use AshUI.Resource.DSL.Element

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read])
  end

  ui_element do
    type :text
    props %{content: "Current value"}
    variants [:primary]
    metadata %{section: "hero"}
  end

  ui_bindings do
    binding :current_value do
      source %{resource: "Demo.User", field: "name", id: "user-1"}
      target "content"
      binding_type :value
      transform %{}
      metadata %{owner: "stat"}
    end
  end
end

defmodule AshUI.Test.ResourceAuthorityFormElement do
  @moduledoc false

  use Ash.Resource,
    domain: AshUI.Test.ResourceAuthorityDomain,
    data_layer: Ash.DataLayer.Ets

  use AshUI.Resource.DSL.Element

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read])
  end

  ui_element do
    type :button
    props %{label: "Save profile"}
    variants [:primary]
    metadata %{section: "form"}
  end

  ui_actions do
    action :save_profile do
      signal :click
      source %{resource: "Demo.Profile", action: "save_profile", id: "user-1"}
      target "submit"
      transform %{
        params: %{
          display_name: %{"from" => "binding", "key" => "display_name"}
        }
      }
      metadata %{intent: "save_profile"}
    end
  end
end

defmodule AshUI.Test.ResourceAuthorityScreen do
  @moduledoc false

  use Ash.Resource,
    domain: AshUI.Test.ResourceAuthorityDomain,
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

  ui_screen do
    layout :column
    route "/resource-authority"
    metadata %{title: "Resource Authority Screen", priority: 13}
    elements [AshUI.Test.ResourceAuthorityStatElement, AshUI.Test.ResourceAuthorityFormElement]
    inline_fragment %{
      type: "column",
      props: %{spacing: 16},
      children: [],
      signals: [],
      metadata: %{source: "screen"}
    }
  end

  ui_screen_bindings do
    binding :screen_notice do
      source %{resource: "Demo.Page", field: "notice", id: "page-1"}
      target "flash.notice"
      binding_type :value
      transform %{default: "ready"}
      metadata %{scope: "screen"}
    end
  end
end
