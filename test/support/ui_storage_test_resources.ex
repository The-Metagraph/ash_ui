defmodule AshUI.Test.UIStorageDomain do
  @moduledoc false

  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource AshUI.Test.UIStorageScreen
    resource AshUI.Test.UIStorageElement
    resource AshUI.Test.UIStorageBinding
  end
end

defmodule AshUI.Test.UIStorageScreen do
  @moduledoc false

  use Ash.Resource,
    domain: AshUI.Test.UIStorageDomain,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: Ash.DataLayer.Ets

  ets do
    private? true
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :unified_dsl, :map, default: %{}
    attribute :layout, :atom, default: :default
    attribute :route, :string
    attribute :metadata, :map, default: %{}
    attribute :active, :boolean, default: true
    attribute :version, :integer, default: 1
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :elements, AshUI.Test.UIStorageElement do
      destination_attribute :screen_id
    end

    has_many :bindings, AshUI.Test.UIStorageBinding do
      destination_attribute :screen_id
    end
  end

  actions do
    defaults [:read]

    read :mount do
      get? true
    end

    create :create do
      primary? true
      accept [:name, :unified_dsl, :layout, :route, :metadata, :active, :version]
    end

    update :update do
      primary? true
      accept [:name, :unified_dsl, :layout, :route, :metadata, :active]
      change increment(:version)
    end

    destroy :destroy do
      primary? true
    end
  end

  policies do
    bypass actor_absent() do
      authorize_if always()
    end

    bypass actor_attribute_equals(:role, :admin) do
      authorize_if always()
    end

    policy action([:read, :mount]) do
      authorize_if {AshUI.Authorization.Checks.ScreenAccess, mode: :read}
    end

    policy action(:create) do
      authorize_if {AshUI.Authorization.Checks.ScreenAccess, mode: :manage}
    end

    policy action([:update, :destroy]) do
      authorize_if {AshUI.Authorization.Checks.ScreenAccess, mode: :manage}
    end
  end
end

defmodule AshUI.Test.UIStorageElement do
  @moduledoc false

  use Ash.Resource,
    domain: AshUI.Test.UIStorageDomain,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: Ash.DataLayer.Ets

  ets do
    private? true
  end

  attributes do
    uuid_primary_key :id
    attribute :type, :atom, allow_nil?: false
    attribute :props, :map, default: %{}
    attribute :variants, {:array, :atom}, default: []
    attribute :position, :integer, default: 0
    attribute :metadata, :map, default: %{}
    attribute :active, :boolean, default: true
    attribute :version, :integer, default: 1
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :screen, AshUI.Test.UIStorageScreen do
      attribute_type :uuid
      allow_nil? true
    end

    has_many :bindings, AshUI.Test.UIStorageBinding do
      destination_attribute :element_id
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:type, :props, :variants, :position, :screen_id, :metadata, :active, :version]
    end

    update :update do
      primary? true
      accept [:type, :props, :variants, :position, :screen_id, :metadata, :active]
      change increment(:version)
    end
  end

  policies do
    bypass actor_absent() do
      authorize_if always()
    end

    bypass actor_attribute_equals(:role, :admin) do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if {AshUI.Authorization.Checks.ElementAccess, mode: :read}
    end

    policy action([:create, :update, :destroy]) do
      authorize_if {AshUI.Authorization.Checks.ElementAccess, mode: :manage}
    end
  end
end

defmodule AshUI.Test.UIStorageBinding do
  @moduledoc false

  use Ash.Resource,
    domain: AshUI.Test.UIStorageDomain,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: Ash.DataLayer.Ets

  ets do
    private? true
  end

  attributes do
    uuid_primary_key :id
    attribute :source, :map, allow_nil?: false, default: %{}
    attribute :target, :string, allow_nil?: false
    attribute :binding_type, :atom, constraints: [one_of: [:value, :list, :action]]
    attribute :transform, :map, default: %{}
    attribute :metadata, :map, default: %{}
    attribute :active, :boolean, default: true
    attribute :version, :integer, default: 1
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :element, AshUI.Test.UIStorageElement do
      attribute_type :uuid
      allow_nil? true
    end

    belongs_to :screen, AshUI.Test.UIStorageScreen do
      attribute_type :uuid
      allow_nil? true
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:source, :target, :binding_type, :transform, :element_id, :screen_id, :metadata, :active, :version]
    end

    update :update do
      primary? true
      accept [:source, :target, :binding_type, :transform, :element_id, :screen_id, :metadata, :active]
      change increment(:version)
    end

    read :read_with_filter do
      filter expr(active == true)
    end
  end

  policies do
    bypass actor_absent() do
      authorize_if always()
    end

    bypass actor_attribute_equals(:role, :admin) do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if {AshUI.Authorization.Checks.BindingAccess, mode: :read}
    end

    policy action([:create, :update, :destroy]) do
      authorize_if {AshUI.Authorization.Checks.BindingAccess, mode: :manage}
    end
  end
end

defmodule AshUI.Test.UIStorageFixtures do
  @moduledoc false

  alias AshUI.Test.RuntimeFixtures
  alias AshUI.Test.UIStorageBinding
  alias AshUI.Test.UIStorageDomain
  alias AshUI.Test.UIStorageElement
  alias AshUI.Test.UIStorageScreen

  def ui_storage_config do
    [
      domain: UIStorageDomain,
      resources: [
        screen: UIStorageScreen,
        element: UIStorageElement,
        binding: UIStorageBinding
      ],
      repo: nil
    ]
  end

  def seed_screen! do
    runtime = RuntimeFixtures.seed!()
    suffix = System.unique_integer([:positive])

    {:ok, screen} =
      Ash.create(
        UIStorageScreen,
        %{
          name: "ets_dashboard_#{suffix}",
          route: "/ets-dashboard",
          layout: :column,
          unified_dsl: %{"type" => "screen"},
          metadata: %{"title" => "ETS Dashboard"}
        },
        domain: UIStorageDomain
      )

    {:ok, element} =
      Ash.create(
        UIStorageElement,
        %{
          screen_id: screen.id,
          type: :textinput,
          props: %{"label" => "Display name"},
          position: 0
        },
        domain: UIStorageDomain
      )

    {:ok, binding} =
      Ash.create(
        UIStorageBinding,
        %{
          screen_id: screen.id,
          element_id: element.id,
          binding_type: :value,
          target: "value",
          source: %{"resource" => "User", "field" => "name", "id" => runtime.user.id}
        },
        domain: UIStorageDomain
      )

    %{runtime: runtime, screen: screen, element: element, binding: binding}
  end
end
