defmodule LiveUi.Examples.StyledExampleStyles do
  @moduledoc false

  @spec profile_shell() :: map()
  def profile_shell do
    %{
      background: "#0f172a",
      border_color: "#334155",
      border: %{radius: :xl, weight: :thin},
      spacing: %{gap: :md}
    }
  end

  @spec profile_title() :: map()
  def profile_title do
    %{
      emphasis: %{tone: :success},
      foreground: "#7dd3fc",
      text: %{bold?: true}
    }
  end

  @spec profile_status() :: map()
  def profile_status do
    %{
      emphasis: %{tone: :success},
      foreground: "#86efac"
    }
  end

  @spec profile_input() :: map()
  def profile_input do
    %{
      background: "#111827",
      border_color: "#38bdf8",
      border: %{radius: :lg, weight: :thin}
    }
  end

  @spec profile_button() :: map()
  def profile_button do
    %{
      background: "#1d4ed8",
      foreground: "#eff6ff",
      border_color: "#60a5fa",
      border: %{radius: :full, weight: :thin},
      spacing: %{padding_x: :lg, padding_y: :sm}
    }
  end

  @spec operations_overlay() :: map()
  def operations_overlay do
    %{
      background: "#0b1220",
      border_color: "#1e293b",
      border: %{radius: :xl, weight: :thin}
    }
  end

  @spec operations_viewport() :: map()
  def operations_viewport do
    %{
      background: "#08101c",
      border_color: "#164e63",
      border: %{radius: :xl, weight: :thin},
      spacing: %{padding: :md}
    }
  end

  @spec operations_canvas() :: map()
  def operations_canvas do
    %{
      background: "#0f172a",
      border_color: "#0ea5e9",
      border: %{radius: :lg, weight: :thin}
    }
  end

  @spec operations_dialog() :: map()
  def operations_dialog do
    %{
      background: "#111827",
      border_color: "#38bdf8",
      border: %{radius: :xl, weight: :thin},
      spacing: %{padding: :lg},
      sizing: %{width: "34rem"}
    }
  end

  @spec operations_cluster() :: map()
  def operations_cluster do
    %{spacing: %{gap: :sm}}
  end
end
