defmodule DesktopUi.Navigation.SignalTest do
  use ExUnit.Case
  alias DesktopUi.Navigation.Signal
  alias DesktopUi.Navigation.State

  @moduletag :navigation

  describe "navigate/2" do
    test "creates a navigate_to signal with atom screen_id" do
      signal = Signal.navigate(:detail, %{item_id: 123})

      assert signal.type == :navigate_to
      assert signal.screen_id == :detail
      assert signal.params == %{item_id: 123}
    end

    test "creates a navigate_to signal with binary screen_id" do
      signal = Signal.navigate("detail", %{item_id: 123})

      assert signal.type == :navigate_to
      assert signal.screen_id == "detail"
    end

    test "creates a navigate_to signal with empty params" do
      signal = Signal.navigate(:home)

      assert signal.type == :navigate_to
      assert signal.screen_id == :home
      assert signal.params == %{}
    end
  end

  describe "replace/2" do
    test "creates a replace_with signal" do
      signal = Signal.replace(:error, %{code: 404})

      assert signal.type == :replace_with
      assert signal.screen_id == :error
      assert signal.params == %{code: 404}
    end

    test "creates a replace_with signal with empty params" do
      signal = Signal.replace(:home)

      assert signal.type == :replace_with
      assert signal.screen_id == :home
      assert signal.params == %{}
    end
  end

  describe "go_back/0" do
    test "creates a go_back signal" do
      signal = Signal.go_back()

      assert signal.type == :go_back
      assert signal.screen_id == nil
      assert signal.params == %{}
    end
  end

  describe "go_forward/0" do
    test "creates a go_forward signal" do
      signal = Signal.go_forward()

      assert signal.type == :go_forward
      assert signal.screen_id == nil
      assert signal.params == %{}
    end
  end

  describe "open_modal/2" do
    test "creates an open_modal signal" do
      signal = Signal.open_modal(:confirm_dialog, %{message: "Are you sure?"})

      assert signal.type == :open_modal
      assert signal.screen_id == :confirm_dialog
      assert signal.params == %{message: "Are you sure?"}
    end

    test "creates an open_modal signal with empty params" do
      signal = Signal.open_modal(:settings)

      assert signal.type == :open_modal
      assert signal.screen_id == :settings
      assert signal.params == %{}
    end
  end

  describe "close_modal/0" do
    test "creates a close_modal signal" do
      signal = Signal.close_modal()

      assert signal.type == :close_modal
      assert signal.screen_id == nil
      assert signal.params == %{}
    end

    test "creates a targeted close_modal signal" do
      signal = Signal.close_modal(:settings_dialog)

      assert signal.type == :close_modal
      assert signal.screen_id == :settings_dialog
      assert signal.params == %{}
    end
  end

  describe "from_map/1" do
    test "creates navigate_to signal from map" do
      assert {:ok, signal} = Signal.from_map(%{type: :navigate_to, screen_id: :home, params: %{}})

      assert signal.type == :navigate_to
      assert signal.screen_id == :home
    end

    test "creates replace_with signal from map" do
      assert {:ok, signal} = Signal.from_map(%{type: :replace_with, screen_id: :error})

      assert signal.type == :replace_with
      assert signal.screen_id == :error
    end

    test "creates go_back signal from map" do
      assert {:ok, signal} = Signal.from_map(%{type: :go_back})

      assert signal.type == :go_back
    end

    test "creates go_forward signal from map" do
      assert {:ok, signal} = Signal.from_map(%{type: :go_forward})

      assert signal.type == :go_forward
    end

    test "creates open_modal signal from map" do
      assert {:ok, signal} =
               Signal.from_map(%{
                 type: :open_modal,
                 screen_id: :confirm,
                 params: %{message: "OK"}
               })

      assert signal.type == :open_modal
      assert signal.screen_id == :confirm
    end

    test "creates close_modal signal from map" do
      assert {:ok, signal} = Signal.from_map(%{type: :close_modal})

      assert signal.type == :close_modal
    end

    test "returns error for unknown navigation type" do
      assert {:error, :unknown_navigation_type} = Signal.from_map(%{type: :invalid})
    end

    test "returns error for invalid format" do
      assert {:error, :invalid_signal_format} = Signal.from_map("not a map")
      assert {:error, :invalid_signal_format} = Signal.from_map(nil)
    end
  end

  describe "validate/1" do
    test "validates navigate_to signal with screen_id" do
      signal = Signal.navigate(:home)
      assert :ok = Signal.validate(signal)
    end

    test "validates replace_with signal with screen_id" do
      signal = Signal.replace(:error)
      assert :ok = Signal.validate(signal)
    end

    test "validates go_back signal" do
      signal = Signal.go_back()
      assert :ok = Signal.validate(signal)
    end

    test "validates go_forward signal" do
      signal = Signal.go_forward()
      assert :ok = Signal.validate(signal)
    end

    test "validates open_modal signal with screen_id" do
      signal = Signal.open_modal(:confirm)
      assert :ok = Signal.validate(signal)
    end

    test "validates close_modal signal" do
      signal = Signal.close_modal()
      assert :ok = Signal.validate(signal)
    end

    test "returns error for navigate_to without screen_id" do
      signal = %Signal{type: :navigate_to, screen_id: nil, params: %{}}
      assert {:error, :screen_id_required} = Signal.validate(signal)
    end

    test "returns error for replace_with without screen_id" do
      signal = %Signal{type: :replace_with, screen_id: nil, params: %{}}
      assert {:error, :screen_id_required} = Signal.validate(signal)
    end

    test "returns error for open_modal without screen_id" do
      signal = %Signal{type: :open_modal, screen_id: nil, params: %{}}
      assert {:error, :screen_id_required} = Signal.validate(signal)
    end

    test "returns error for unknown type" do
      signal = %Signal{type: :invalid, screen_id: :home, params: %{}}
      assert {:error, :unknown_navigation_type} = Signal.validate(signal)
    end
  end

  describe "execute/2" do
    setup do
      defmodule MockScreen do
        def render(_assigns), do: %{}
      end

      {:ok, controller} =
        DesktopUi.Navigation.Controller.start_link(
          name: nil,
          initial_screen: {:home, MockScreen, %{}}
        )

      %{controller: controller}
    end

    test "executes navigate_to signal", %{controller: controller} do
      signal = Signal.navigate(:detail, %{item_id: 1})
      result = Signal.execute(signal, controller)

      assert {:ok, _state, {:transition, :navigated}} = result
    end

    test "executes replace_with signal", %{controller: controller} do
      signal = Signal.replace(:error, %{code: 404})
      result = Signal.execute(signal, controller)

      assert {:ok, _state, {:transition, :replaced}} = result
    end

    test "executes go_back signal when history is empty", %{controller: controller} do
      signal = Signal.go_back()
      result = Signal.execute(signal, controller)

      assert {:error, :empty_history} = result
    end

    test "executes go_forward signal when forward is empty", %{controller: controller} do
      signal = Signal.go_forward()
      result = Signal.execute(signal, controller)

      assert {:error, :empty_forward} = result
    end

    test "executes open_modal signal", %{controller: controller} do
      signal = Signal.open_modal(:confirm_dialog)
      result = Signal.execute(signal, controller)

      assert {:ok, _state, {:transition, :modal_opened}} = result
    end

    test "executes close_modal signal", %{controller: controller} do
      Signal.open_modal(:confirm_dialog) |> Signal.execute(controller)
      signal = Signal.close_modal()
      result = Signal.execute(signal, controller)

      assert {:ok, _state, {:transition, :modal_closed}} = result
    end

    test "executes targeted close_modal signal", %{controller: controller} do
      Signal.open_modal(:confirm_dialog) |> Signal.execute(controller)
      Signal.open_modal(:modal2) |> Signal.execute(controller)

      signal = Signal.close_modal(:confirm_dialog)
      result = Signal.execute(signal, controller)

      assert {:ok, state, {:transition, :modal_closed}} = result

      assert State.top_modal(state) ==
               {:modal2, DesktopUi.Navigation.Controller.MockScreen.Modal2, %{}}
    end
  end
end
