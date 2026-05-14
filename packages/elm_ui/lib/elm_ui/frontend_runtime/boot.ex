defmodule ElmUi.FrontendRuntime.Boot do
  @moduledoc """
  Frontend hydration and boot diagnostics.
  """

  alias ElmUi.FrontendRuntime.{Error, Message, Model, Realization}

  @required_fields ~w[runtime_id screen_id title source_kind boundary_mode tree local_state diagnostics metadata]a

  @spec hydrate(map()) :: {:ok, Model.t()} | {:error, Error.t()}
  def hydrate(payload) when is_map(payload) do
    missing =
      Enum.reject(@required_fields, fn field ->
        Map.has_key?(payload, field) or Map.has_key?(payload, Atom.to_string(field))
      end)

    case missing do
      [] ->
        render_tree = fetch(payload, :tree)
        local_state = fetch(payload, :local_state)

        {:ok,
         %Model{
           runtime_id: fetch(payload, :runtime_id),
           screen_id: fetch(payload, :screen_id),
           title: fetch(payload, :title),
           source_kind: fetch(payload, :source_kind),
           boundary_mode: fetch(payload, :boundary_mode),
           render_tree: render_tree,
           tree: Realization.realize(render_tree, local_state),
           local_state: local_state,
           diagnostics: fetch(payload, :diagnostics),
           metadata: fetch(payload, :metadata)
         }}

      fields ->
        {:error,
         Error.new(:invalid_hydration_payload, "Missing hydration fields", %{fields: fields})}
    end
  end

  def hydrate(_payload) do
    {:error, Error.new(:invalid_hydration_payload, "Expected hydration payload to be a map")}
  end

  @spec hydrate_message(map()) :: {:ok, Model.t()} | {:error, Error.t()}
  def hydrate_message(message) when is_map(message) do
    with {:ok, %{kind: :hydrate, payload: payload}} <- Message.from_payload(message) do
      hydrate(payload)
    else
      {:ok, %{kind: other_kind}} ->
        {:error,
         Error.new(
           :invalid_boot_order,
           "Expected a hydrate message before other frontend messages",
           %{
             kind: other_kind
           }
         )}

      {:error, reason} ->
        {:error,
         Error.new(:invalid_hydration_payload, "Invalid hydration message", %{reason: reason})}
    end
  end

  defp fetch(map, key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end
end
