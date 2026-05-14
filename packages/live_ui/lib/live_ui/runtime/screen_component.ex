defmodule LiveUi.Runtime.ScreenComponent do
  @moduledoc """
  Shared LiveComponent host for mounted native and renderer-driven screens.
  """

  use Phoenix.LiveComponent

  alias LiveUi.Runtime.State
  alias UnifiedIUR.Interaction

  @impl true
  def update(%{runtime_state: %State{} = runtime_state} = assigns, socket) do
    socket =
      socket
      |> assign(Map.put(assigns, :runtime_state, runtime_state))
      |> assign_new(:last_translation, fn -> nil end)
      |> assign_new(:runtime_event_error, fn -> nil end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> Map.put_new(:last_translation, nil)
      |> Map.put_new(:runtime_event_error, nil)
      |> Map.put_new(:interaction_demo, interaction_demo(assigns.runtime_state))
      |> Map.put_new(:show_demo_panels, true)
      |> Map.put(:demo_active?, not is_nil(assigns[:last_translation]))

    ~H"""
    <section
      id={@id}
      data-live-ui-runtime="screen"
      data-example-demo-active={to_string(@demo_active?)}
    >
      <%= render_screen(@runtime_state, "##{@id}") %>

      <%= if @show_demo_panels do %>
        <section data-live-ui-demo-story="true">
          <h2>Meaningful Interaction Story</h2>

          <%= if @last_translation && @last_translation.signal do %>
            <p data-live-ui-demo-status="true">
              <%= runtime_summary(@interaction_demo, @last_translation) %>
            </p>
            <p :if={@interaction_demo[:outcome]} data-live-ui-demo-outcome="true">
              <%= @interaction_demo[:outcome] %>
            </p>
            <p :if={payload_highlight(@last_translation)} data-live-ui-demo-payload="true">
              Latest payload highlight: <%= payload_highlight(@last_translation) %>
            </p>
          <% end %>
        </section>

        <section data-live-ui-signal-preview="true">
          <h2>Canonical Signal Preview</h2>

          <%= if @last_translation && @last_translation.signal do %>
            <p data-live-ui-signal-status="true">Signal captured from the latest interaction.</p>
            <p data-live-ui-signal-type="true"><%= @last_translation.signal.type %></p>
            <p data-live-ui-runtime-event="true"><%= @last_translation.runtime_event %></p>
            <pre data-live-ui-signal-payload="true"><%= inspect(@last_translation.signal.data, pretty: true, limit: :infinity) %></pre>
            <pre data-live-ui-signal-translation="true"><%= inspect(@last_translation, pretty: true, limit: :infinity) %></pre>
          <% end %>
        </section>
      <% end %>

      <pre :if={@runtime_event_error} data-live-ui-runtime-event-error="true"><%= inspect(@runtime_event_error, pretty: true, limit: :infinity) %></pre>
    </section>
    """
  end

  @impl true
  def handle_event(
        "canonical_interaction",
        %{"interaction" => encoded_interaction} = params,
        socket
      ) do
    handle_canonical_event(encoded_interaction, params, socket)
  end

  @impl true
  def handle_event(
        "canonical_change_interaction",
        %{"change_interaction" => encoded_interaction} = params,
        socket
      ) do
    handle_canonical_event(encoded_interaction, params, socket)
  end

  @impl true
  def handle_event(
        "canonical_submit_interaction",
        %{"submit_interaction" => encoded_interaction} = params,
        socket
      ) do
    handle_canonical_event(encoded_interaction, params, socket)
  end

  @impl true
  def handle_event(event, params, socket) when is_binary(event) and is_map(params) do
    case event do
      "widget_component_event" ->
        handle_widget_component_event(params, socket)

      _other ->
        handle_screen_event(event, params, socket)
    end
  end

  defp handle_widget_component_event(params, socket) do
    case State.handle_widget_event(socket.assigns.runtime_state, params) do
      {:ok, updated_runtime_state} ->
        {:noreply,
         socket
         |> assign(:runtime_state, updated_runtime_state)
         |> assign(:runtime_event_error, nil)}

      {:error, reason} ->
        {:noreply, assign(socket, :runtime_event_error, reason)}
    end
  end

  defp handle_screen_event(event, params, socket) do
    case State.handle_event(socket.assigns.runtime_state, event, params) do
      {:ok, updated_runtime_state} ->
        {:noreply,
         socket
         |> assign(:runtime_state, updated_runtime_state)
         |> assign(:runtime_event_error, nil)}

      {:error, reason} ->
        {:noreply, assign(socket, :runtime_event_error, reason)}
    end
  end

  defp handle_canonical_event(encoded_interaction, params, socket) do
    runtime_state = socket.assigns.runtime_state

    with {:ok, interaction} <- decode_interaction(encoded_interaction),
         payload = canonical_payload(params),
         {:ok, translation} <-
           LiveUi.Signals.from_interaction(
             interaction,
             screen: State.screen_id(runtime_state),
             mode: runtime_state.mode,
             boundary: :boundary,
             element_id: Map.get(params, "element_id"),
             widget: Map.get(params, "widget"),
             payload: payload
           ),
         {:ok, updated_runtime_state} <- State.handle_runtime_action(runtime_state, translation) do
      updated_runtime_state = maybe_apply_interaction_hook(updated_runtime_state, translation)

      {:noreply,
       socket
       |> assign(:runtime_state, updated_runtime_state)
       |> assign(:last_translation, translation)
       |> assign(:runtime_event_error, nil)}
    else
      {:error, reason} ->
        {:noreply, assign(socket, :runtime_event_error, reason)}
    end
  end

  defp render_screen(runtime_state, event_target) do
    rendered_assigns =
      runtime_state.assigns
      |> Map.put(:runtime_state, runtime_state)
      |> Map.put(:event_target, event_target)
      |> Map.put_new(:id, to_string(runtime_state.screen.id()))

    runtime_state.screen.render(rendered_assigns)
  end

  defp decode_interaction(encoded_interaction) when is_binary(encoded_interaction) do
    case Base.url_decode64(encoded_interaction, padding: false) do
      {:ok, binary} ->
        try do
          {:ok, Interaction.new(:erlang.binary_to_term(binary, [:safe]))}
        rescue
          ArgumentError -> {:error, :invalid_canonical_interaction}
        end

      :error ->
        {:error, :invalid_canonical_interaction}
    end
  end

  defp decode_interaction(_other), do: {:error, :invalid_canonical_interaction}

  defp canonical_payload(params) when is_map(params) do
    params
    |> Map.drop([
      "interaction",
      "change_interaction",
      "submit_interaction",
      "element_id",
      "widget",
      "_target"
    ])
  end

  defp maybe_apply_interaction_hook(%State{} = runtime_state, translation)
       when is_map(translation) do
    case Map.get(runtime_state.assigns, :canonical_interaction_hook) do
      hook when is_function(hook, 2) ->
        case hook.(runtime_state, translation) do
          %State{} = updated_runtime_state -> updated_runtime_state
          _other -> runtime_state
        end

      _other ->
        runtime_state
    end
  end

  defp interaction_demo(%State{assigns: assigns}) when is_map(assigns) do
    Map.get(assigns, :example_interaction_demo, %{})
  end

  defp runtime_summary(interaction_demo, translation) do
    widget =
      interaction_demo
      |> Map.get(:widget, :example)
      |> to_string()
      |> String.replace("_", " ")

    family =
      translation
      |> Map.get(:family, Map.get(interaction_demo, :family, :interaction))
      |> to_string()
      |> String.replace("_", " ")

    payload_hint = payload_highlight(translation)

    base = "The #{widget} example just captured a #{family} interaction."

    if payload_hint in [nil, ""] do
      base
    else
      base <> " Highlighted payload: " <> payload_hint <> "."
    end
  end

  defp payload_highlight(translation) when is_map(translation) do
    translation
    |> Map.get(:signal)
    |> case do
      nil ->
        nil

      signal ->
        signal.data
        |> Map.new()
        |> Map.drop([
          :source,
          :example,
          :widget,
          :phase,
          "source",
          "example",
          "widget",
          "phase"
        ])
        |> Enum.take(3)
        |> Enum.map_join(", ", fn {key, value} -> "#{key}=#{normalize_value(value)}" end)
    end
    |> case do
      "" -> nil
      value -> value
    end
  end

  defp normalize_value(%{name: name}) when is_atom(name), do: Atom.to_string(name)
  defp normalize_value(value) when is_binary(value), do: value
  defp normalize_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_value(value), do: inspect(value)
end
