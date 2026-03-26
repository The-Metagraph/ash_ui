defmodule UnifiedUi.Widgets do
  @moduledoc """
  Package-facing reference surface for authored widget kinds supported by `UnifiedUi`.
  """

  alias UnifiedUi.Dsl.Entities.{Advanced, Data, Feedback, Foundational, Input, Navigation}

  @spec foundational_kinds() :: [atom()]
  def foundational_kinds do
    Foundational.kinds()
  end

  @spec input_kinds() :: [atom()]
  def input_kinds do
    Input.kinds()
  end

  @spec navigation_kinds() :: [atom()]
  def navigation_kinds do
    Navigation.kinds()
  end

  @spec data_kinds() :: [atom()]
  def data_kinds do
    Data.kinds()
  end

  @spec feedback_kinds() :: [atom()]
  def feedback_kinds do
    Feedback.kinds()
  end

  @spec advanced_kinds() :: [atom()]
  def advanced_kinds do
    Advanced.kinds()
  end

  @spec kinds() :: [atom()]
  def kinds do
    foundational_kinds() ++
      input_kinds() ++
      navigation_kinds() ++
      data_kinds() ++
      feedback_kinds() ++
      advanced_kinds()
  end
end
