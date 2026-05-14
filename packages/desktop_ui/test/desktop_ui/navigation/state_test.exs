defmodule DesktopUi.Navigation.StateTest do
  use ExUnit.Case, async: true

  alias DesktopUi.Navigation.State

  describe "new/3" do
    test "creates a new navigation state with a screen" do
      state = State.new(:home, HomeScreen, %{foo: "bar"})

      assert state.current == :home
      assert state.current_module == HomeScreen
      assert state.current_params == %{foo: "bar"}
      assert state.history == []
      assert state.forward == []
      assert state.modals == []
      refute state.modal_open?
    end

    test "creates empty state when no screen provided" do
      state = %State{}

      assert is_nil(state.current)
      assert is_nil(state.current_module)
      assert state.current_params == %{}
      assert state.history == []
      assert state.forward == []
      assert state.modals == []
      refute state.modal_open?
    end
  end

  describe "can_go_back?/1" do
    test "returns false when history is empty" do
      state = State.new(:home, HomeScreen, %{})
      refute State.can_go_back?(state)
    end

    test "returns true when history has entries" do
      state = %State{history: [{:list, ListScreen, %{}}]}
      assert State.can_go_back?(state)
    end
  end

  describe "can_go_forward?/1" do
    test "returns false when forward stack is empty" do
      state = State.new(:home, HomeScreen, %{})
      refute State.can_go_forward?(state)
    end

    test "returns true when forward has entries" do
      state = %State{forward: [{:detail, DetailScreen, %{}}]}
      assert State.can_go_forward?(state)
    end
  end

  describe "modal_open?/1" do
    test "returns false when no modals are open" do
      state = State.new(:home, HomeScreen, %{})
      refute State.modal_open?(state)
    end

    test "returns true when modal_open? is true" do
      state = %State{modal_open?: true}
      assert State.modal_open?(state)
    end
  end

  describe "current_screen/1" do
    test "returns nil when no current screen" do
      state = %State{}
      assert is_nil(State.current_screen(state))
    end

    test "returns the current screen tuple" do
      state = State.new(:home, HomeScreen, %{id: 123})
      assert State.current_screen(state) == {:home, HomeScreen, %{id: 123}}
    end
  end

  describe "top_modal/1" do
    test "returns nil when no modals" do
      state = State.new(:home, HomeScreen, %{})
      assert is_nil(State.top_modal(state))
    end

    test "returns the top modal" do
      state = %State{modals: [{:modal, ModalScreen, %{}}]}
      assert State.top_modal(state) == {:modal, ModalScreen, %{}}
    end
  end

  describe "modal_depth/1" do
    test "returns 0 for no modals" do
      state = State.new(:home, HomeScreen, %{})
      assert State.modal_depth(state) == 0
    end

    test "returns the number of modals" do
      state = %State{modals: [{:m1, M1, %{}}, {:m2, M2, %{}}]}
      assert State.modal_depth(state) == 2
    end
  end
end
