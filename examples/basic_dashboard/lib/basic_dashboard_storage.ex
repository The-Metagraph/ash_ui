defmodule BasicDashboard.Storage do
  @moduledoc """
  Configuration helpers for the example ETS-backed UI storage resources.
  """

  @spec config() :: keyword()
  def config do
    [
      domain: BasicDashboard.Storage.Domain,
      resources: [
        screen: BasicDashboard.Storage.Screen,
        element: BasicDashboard.Storage.Element,
        binding: BasicDashboard.Storage.Binding
      ],
      repo: nil
    ]
  end
end

defmodule BasicDashboard.Storage.Domain do
  @moduledoc """
  Example ETS-backed UI storage domain for the basic dashboard reference app.

  Copy these modules into your application if you want the dashboard example to
  run without Postgres-backed UI definition storage.
  """

  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource BasicDashboard.Storage.Screen
    resource BasicDashboard.Storage.Element
    resource BasicDashboard.Storage.Binding
  end
end

defmodule BasicDashboard.Storage.Screen do
  @moduledoc false

  use Ash.Resource,
    domain: BasicDashboard.Storage.Domain,
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
    has_many :elements, BasicDashboard.Storage.Element do
      destination_attribute :screen_id
    end

    has_many :bindings, BasicDashboard.Storage.Binding do
      destination_attribute :screen_id
    end
  end

  actions do
    defaults [:read]

    read :mount do
      get? true

      argument :user_id, :string do
        allow_nil? false
      end

      argument :params, :map do
        allow_nil? false
        default %{}
      end
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

    policy action([:create, :update]) do
      authorize_if {AshUI.Authorization.Checks.ScreenAccess, mode: :manage}
    end
  end
end

defmodule BasicDashboard.Storage.Element do
  @moduledoc false

  use Ash.Resource,
    domain: BasicDashboard.Storage.Domain,
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
    belongs_to :screen, BasicDashboard.Storage.Screen do
      attribute_type :uuid
      allow_nil? true
    end

    has_many :bindings, BasicDashboard.Storage.Binding do
      destination_attribute :element_id
    end
  end

  actions do
    defaults [:read]

    create :create do
      primary? true
      accept [:type, :props, :variants, :position, :screen_id, :metadata, :active, :version]
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

    policy action(:create) do
      authorize_if {AshUI.Authorization.Checks.ElementAccess, mode: :manage}
    end
  end
end

defmodule BasicDashboard.Storage.Binding do
  @moduledoc false

  use Ash.Resource,
    domain: BasicDashboard.Storage.Domain,
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
    belongs_to :element, BasicDashboard.Storage.Element do
      attribute_type :uuid
      allow_nil? true
    end

    belongs_to :screen, BasicDashboard.Storage.Screen do
      attribute_type :uuid
      allow_nil? true
    end
  end

  actions do
    defaults [:read]

    create :create do
      primary? true
      accept [:source, :target, :binding_type, :transform, :element_id, :screen_id, :metadata, :active, :version]
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

    policy action(:create) do
      authorize_if {AshUI.Authorization.Checks.BindingAccess, mode: :manage}
    end
  end
end
