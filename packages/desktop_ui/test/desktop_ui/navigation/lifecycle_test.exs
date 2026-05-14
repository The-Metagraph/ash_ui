defmodule DesktopUi.Navigation.LifecycleTest do
  use ExUnit.Case
  alias DesktopUi.Navigation.Lifecycle

  @moduletag :navigation

  describe "mount/3" do
    defmodule WithMount do
      @behaviour Lifecycle

      def on_mount(_screen_id, _params) do
        {:cont, %{mounted: true}}
      end
    end

    test "calls on_mount callback when defined" do
      assert {:ok, %{mounted: true}} = Lifecycle.mount(WithMount, :test_screen, %{})
    end

    test "returns empty state when on_mount not defined" do
      defmodule NoMount do
        @behaviour Lifecycle
      end

      assert {:ok, %{}} = Lifecycle.mount(NoMount, :test_screen, %{})
    end

    test "returns error for invalid mount result" do
      defmodule BadMount do
        @behaviour Lifecycle

        def on_mount(_screen_id, _params) do
          :invalid
        end
      end

      assert {:error, {:invalid_mount_result, :invalid}} =
               Lifecycle.mount(BadMount, :test_screen, %{})
    end

    test "halts when callback returns halt" do
      defmodule HaltingMount do
        @behaviour Lifecycle

        def on_mount(_screen_id, _params) do
          {:halt, %{stopped: true}}
        end
      end

      # Even with halt, we return ok with the halted state
      assert {:ok, %{stopped: true}} = Lifecycle.mount(HaltingMount, :test_screen, %{})
    end
  end

  describe "unmount/3" do
    defmodule WithUnmount do
      @behaviour Lifecycle

      def on_unmount(_screen_id, _state) do
        :unmounted
      end
    end

    test "calls on_unmount callback when defined" do
      assert :ok = Lifecycle.unmount(WithUnmount, :test_screen, %{})
    end

    test "returns :ok when on_unmount not defined" do
      defmodule NoUnmount do
        @behaviour Lifecycle
      end

      assert :ok = Lifecycle.unmount(NoUnmount, :test_screen, %{})
    end
  end

  describe "handle_transition/5" do
    defmodule WithHandler do
      @behaviour Lifecycle

      def handle_navigation(_from, _to, _action, _params) do
        {:cont, intercepted: true}
      end
    end

    test "calls handle_navigation when defined" do
      # When callback returns opts without :params, params are used as-is
      assert {:cont, %{}} = Lifecycle.handle_transition(WithHandler, :from, :to, :navigate, %{})
    end

    test "allows callback to override params" do
      defmodule ParamsOverride do
        @behaviour Lifecycle

        def handle_navigation(_from, _to, _action, _params) do
          {:cont, params: %{overridden: true}}
        end
      end

      assert {:cont, %{overridden: true}} =
               Lifecycle.handle_transition(ParamsOverride, :from, :to, :navigate, %{})
    end

    test "returns {:cont, params} when handle_navigation not defined" do
      defmodule NoHandler do
        @behaviour Lifecycle
      end

      params = %{key: :value}
      assert {:cont, ^params} = Lifecycle.handle_transition(NoHandler, :from, :to, :navigate, params)
    end

    test "halts when callback returns halt" do
      defmodule HaltingHandler do
        @behaviour Lifecycle

        def handle_navigation(_from, _to, _action, _params) do
          {:halt, %{cancelled: true}}
        end
      end

      assert {:halt, %{cancelled: true}} =
               Lifecycle.handle_transition(HaltingHandler, :from, :to, :navigate, %{})
    end

    test "returns error for invalid result" do
      defmodule BadHandler do
        @behaviour Lifecycle

        def handle_navigation(_from, _to, _action, _params) do
          :invalid
        end
      end

      assert {:error, {:invalid_navigation_result, :invalid}} =
               Lifecycle.handle_transition(BadHandler, :from, :to, :navigate, %{})
    end
  end
end
