defmodule DesktopUi.Navigation.ControllerTest do
  use ExUnit.Case

  alias DesktopUi.Navigation.Controller
  alias DesktopUi.Navigation.State

  @moduletag :navigation

  describe "start_link/1" do
    test "starts without initial screen" do
      {:ok, pid} = Controller.start_link([])
      state = Controller.get_state(pid)

      assert is_nil(state.current)
      assert is_nil(state.current_module)
      assert state.history == []
      assert state.forward == []

      GenServer.stop(pid)
    end

    test "starts with initial screen" do
      {:ok, pid} =
        Controller.start_link(initial_screen: {:home, nil, %{foo: "bar"}})

      state = Controller.get_state(pid)

      assert state.current == :home
      assert state.current_module == DesktopUi.Navigation.Controller.MockScreen.Home
      assert state.current_params == %{foo: "bar"}
      assert state.history == []
      assert state.forward == []

      GenServer.stop(pid)
    end

    test "starts with a name" do
      {:ok, _pid} = Controller.start_link(name: :test_nav)

      state = Controller.get_state(:test_nav)
      assert %State{} = state

      :ok = GenServer.stop(:test_nav)
    end
  end

  describe "navigate/3" do
    setup do
      {:ok, pid} = Controller.start_link(initial_screen: {:home, nil, %{}})
      %{pid: pid}
    end

    test "navigates to a new screen, pushing current to history", %{pid: pid} do
      {:ok, state, {:transition, :navigated}} =
        Controller.navigate(pid, :detail, %{item_id: 123})

      assert state.current == :detail
      assert state.current_module == DesktopUi.Navigation.Controller.MockScreen.Detail
      assert state.current_params == %{item_id: 123}
      assert [{:home, DesktopUi.Navigation.Controller.MockScreen.Home, %{}}] = state.history
      assert state.forward == []
    end

    test "clears forward stack on navigate", %{pid: pid} do
      # Navigate forward first
      {:ok, _, {:transition, :navigated}} = Controller.navigate(pid, :list, %{})
      # Go back
      {:ok, _, {:transition, :back}} = Controller.go_back(pid)
      # Navigate again - forward should be cleared
      {:ok, state, {:transition, :navigated}} =
        Controller.navigate(pid, :detail, %{item_id: 456})

      assert state.forward == []
      assert length(state.history) == 1
    end
  end

  describe "replace/3" do
    setup do
      {:ok, pid} =
        Controller.start_link(initial_screen: {:home, nil, %{foo: "bar"}})

      %{pid: pid}
    end

    test "replaces current screen without modifying history", %{pid: pid} do
      {:ok, state, {:transition, :replaced}} =
        Controller.replace(pid, :error, %{code: 404})

      assert state.current == :error
      assert state.current_module == DesktopUi.Navigation.Controller.MockScreen.Error
      assert state.current_params == %{code: 404}
      assert state.history == []
    end
  end

  describe "go_back/1" do
    setup do
      {:ok, pid} = Controller.start_link(initial_screen: {:home, nil, %{}})

      # Navigate to detail
      {:ok, _, {:transition, :navigated}} =
        Controller.navigate(pid, :detail, %{id: 1})

      %{pid: pid}
    end

    test "goes back to previous screen", %{pid: pid} do
      {:ok, state, {:transition, :back}} = Controller.go_back(pid)

      assert state.current == :home
      assert state.current_module == DesktopUi.Navigation.Controller.MockScreen.Home
      assert state.history == []

      assert [{:detail, DesktopUi.Navigation.Controller.MockScreen.Detail, %{id: 1}}] =
               state.forward
    end

    test "returns error when history is empty", %{pid: pid} do
      # Go back to home
      {:ok, _, {:transition, :back}} = Controller.go_back(pid)
      # Try to go back again
      assert {:error, :empty_history} = Controller.go_back(pid)
    end
  end

  describe "go_forward/1" do
    setup do
      {:ok, pid} = Controller.start_link(initial_screen: {:home, nil, %{}})

      # Navigate to detail
      {:ok, _, {:transition, :navigated}} =
        Controller.navigate(pid, :detail, %{id: 1})

      # Go back
      {:ok, _, {:transition, :back}} = Controller.go_back(pid)

      %{pid: pid}
    end

    test "goes forward to next screen", %{pid: pid} do
      {:ok, state, {:transition, :forward}} = Controller.go_forward(pid)

      assert state.current == :detail
      assert state.current_module == DesktopUi.Navigation.Controller.MockScreen.Detail
      assert state.forward == []
      assert [{:home, DesktopUi.Navigation.Controller.MockScreen.Home, %{}}] = state.history
    end

    test "returns error when forward is empty", %{pid: pid} do
      # Go forward to detail
      {:ok, _, {:transition, :forward}} = Controller.go_forward(pid)
      # Try to go forward again
      assert {:error, :empty_forward} = Controller.go_forward(pid)
    end
  end

  describe "open_modal/3" do
    setup do
      {:ok, pid} = Controller.start_link(initial_screen: {:home, nil, %{}})
      %{pid: pid}
    end

    test "opens a modal, keeping current screen", %{pid: pid} do
      {:ok, state, {:transition, :modal_opened}} =
        Controller.open_modal(pid, :confirm_dialog, %{action: :delete})

      assert state.current == :home
      assert state.current_module == DesktopUi.Navigation.Controller.MockScreen.Home
      assert state.modal_open?

      assert [
               {:confirm_dialog, DesktopUi.Navigation.Controller.MockScreen.ConfirmDialog,
                %{action: :delete}}
             ] = state.modals
    end

    test "stacks multiple modals", %{pid: pid} do
      {:ok, _, {:transition, :modal_opened}} =
        Controller.open_modal(pid, :modal1, %{})

      {:ok, state, {:transition, :modal_opened}} =
        Controller.open_modal(pid, :modal2, %{})

      assert state.modal_open?
      assert length(state.modals) == 2
      assert {:modal2, DesktopUi.Navigation.Controller.MockScreen.Modal2, %{}} = hd(state.modals)
      assert State.modal_depth(state) == 2

      assert State.top_modal(state) ==
               {:modal2, DesktopUi.Navigation.Controller.MockScreen.Modal2, %{}}
    end
  end

  describe "close_modal/1" do
    setup do
      {:ok, pid} = Controller.start_link(initial_screen: {:home, nil, %{}})

      # Open a modal
      {:ok, _, {:transition, :modal_opened}} =
        Controller.open_modal(pid, :confirm_dialog, %{action: :delete})

      %{pid: pid}
    end

    test "closes the top modal", %{pid: pid} do
      {:ok, state, {:transition, :modal_closed}} = Controller.close_modal(pid)

      refute state.modal_open?
      assert state.modals == []
      assert state.current == :home
    end

    test "returns error when no modal is open", %{pid: pid} do
      # Close the modal
      {:ok, _, {:transition, :modal_closed}} = Controller.close_modal(pid)
      # Try to close again
      assert {:error, :no_modal} = Controller.close_modal(pid)
    end

    test "closes a named modal without changing screen history", %{pid: pid} do
      {:ok, _, {:transition, :modal_opened}} =
        Controller.open_modal(pid, :modal2, %{step: 2})

      {:ok, state, {:transition, :modal_closed}} =
        Controller.close_modal(pid, :confirm_dialog)

      assert state.current == :home
      assert state.history == []
      assert state.modal_open?

      assert state.modals == [
               {:modal2, DesktopUi.Navigation.Controller.MockScreen.Modal2, %{step: 2}}
             ]

      assert {:error, {:unknown_modal, :confirm_dialog}} =
               Controller.close_modal(pid, :confirm_dialog)
    end
  end

  describe "with registry" do
    defmodule TestRegistry do
      def get_screen(:home), do: HomeScreen
      def get_screen(:list), do: ListScreen
      def get_screen(:detail), do: DetailScreen
      def get_screen(_), do: nil
    end

    setup do
      {:ok, pid} =
        Controller.start_link(
          registry: TestRegistry,
          initial_screen: {:home, nil, %{}}
        )

      %{pid: pid}
    end

    test "resolves screens from registry", %{pid: pid} do
      {:ok, state, {:transition, :navigated}} =
        Controller.navigate(pid, :list, %{})

      assert state.current == :list
      assert state.current_module == ListScreen
    end

    test "returns error for unknown screen", %{pid: pid} do
      assert {:error, {:unknown_screen, :unknown}} =
               Controller.navigate(pid, :unknown, %{})
    end
  end

  describe "current_screen/1" do
    setup do
      {:ok, pid} = Controller.start_link(initial_screen: {:home, nil, %{id: 123}})
      %{pid: pid}
    end

    test "returns the current screen tuple", %{pid: pid} do
      assert Controller.current_screen(pid) ==
               {:home, DesktopUi.Navigation.Controller.MockScreen.Home, %{id: 123}}
    end

    test "returns nil when no current screen" do
      {:ok, no_screen_pid} = Controller.start_link([])

      assert is_nil(Controller.current_screen(no_screen_pid))

      GenServer.stop(no_screen_pid)
    end
  end
end
