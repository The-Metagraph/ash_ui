defmodule BasicDashboardLive do
  @moduledoc """
  Ash-inspired LiveView for the ETS-backed basic dashboard example.
  """

  use Phoenix.LiveView

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.LiveView.UpdateIntegration
  alias BasicDashboard.Data

  @ash_theme_css """
  #basic-dashboard-example {
    --ash-bg: #020617;
    --ash-bg-soft: #0f172a;
    --ash-surface: rgba(22, 23, 29, 0.92);
    --ash-surface-strong: rgba(34, 36, 45, 0.96);
    --ash-border: rgba(70, 73, 93, 0.8);
    --ash-border-soft: rgba(255, 145, 77, 0.18);
    --ash-copy: #c2c4d1;
    --ash-muted: #878ba5;
    --ash-title: #f9fafb;
    --ash-primary: #ff5757;
    --ash-primary-soft: #ff7676;
    --ash-accent: #ff914d;
    --ash-accent-soft: #ffcaa9;
    min-height: 100vh;
    padding: clamp(1.5rem, 4vw, 3rem);
    color: var(--ash-title);
    font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    background:
      radial-gradient(circle at top left, rgba(255, 145, 77, 0.24), transparent 30rem),
      radial-gradient(circle at top right, rgba(255, 87, 87, 0.18), transparent 22rem),
      linear-gradient(180deg, #020617 0%, #0f172a 48%, #16171d 100%);
  }

  #basic-dashboard-example * {
    box-sizing: border-box;
  }

  #basic-dashboard-example .ash-demo-shell {
    max-width: 1180px;
    margin: 0 auto;
  }

  #basic-dashboard-example .ash-demo-topbar,
  #basic-dashboard-example .ash-demo-hero,
  #basic-dashboard-example .ash-demo-card,
  #basic-dashboard-example .ash-demo-stat,
  #basic-dashboard-example .ash-demo-note {
    border: 1px solid var(--ash-border);
    background: linear-gradient(180deg, rgba(22, 23, 29, 0.94), rgba(15, 23, 42, 0.9));
    box-shadow:
      0 28px 80px rgba(2, 6, 23, 0.48),
      inset 0 1px 0 rgba(255, 255, 255, 0.04);
    backdrop-filter: blur(18px);
  }

  #basic-dashboard-example .ash-demo-topbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 1rem;
    padding: 0.95rem 1.15rem;
    border-radius: 999px;
    margin-bottom: 1.5rem;
  }

  #basic-dashboard-example .ash-demo-brand {
    display: flex;
    align-items: center;
    gap: 0.9rem;
  }

  #basic-dashboard-example .ash-demo-mark {
    width: 2.5rem;
    height: 2.5rem;
    border-radius: 999px;
    background: linear-gradient(135deg, var(--ash-accent), var(--ash-primary));
    box-shadow: 0 0 26px rgba(255, 87, 87, 0.35);
    display: inline-flex;
    align-items: center;
    justify-content: center;
    color: #020617;
    font-weight: 800;
    text-transform: lowercase;
  }

  #basic-dashboard-example .ash-demo-brand-copy {
    display: grid;
    gap: 0.12rem;
  }

  #basic-dashboard-example .ash-demo-overline,
  #basic-dashboard-example .ash-demo-kicker,
  #basic-dashboard-example .ash-demo-label,
  #basic-dashboard-example .ash-demo-mini-label {
    letter-spacing: 0.12em;
    text-transform: uppercase;
    font-size: 0.72rem;
    color: var(--ash-accent-soft);
  }

  #basic-dashboard-example .ash-demo-brand-title {
    font-size: 1rem;
    font-weight: 700;
    color: var(--ash-title);
  }

  #basic-dashboard-example .ash-demo-topbar-links {
    display: flex;
    flex-wrap: wrap;
    gap: 0.6rem;
    justify-content: flex-end;
  }

  #basic-dashboard-example .ash-demo-pill {
    display: inline-flex;
    align-items: center;
    gap: 0.45rem;
    padding: 0.45rem 0.85rem;
    border-radius: 999px;
    border: 1px solid rgba(255, 145, 77, 0.28);
    background: rgba(255, 145, 77, 0.08);
    color: var(--ash-accent-soft);
    font-size: 0.8rem;
  }

  #basic-dashboard-example .ash-demo-pill strong {
    color: var(--ash-title);
    font-weight: 600;
  }

  #basic-dashboard-example .ash-demo-hero {
    position: relative;
    overflow: hidden;
    padding: clamp(1.5rem, 4vw, 2.5rem);
    border-radius: 1.75rem;
    margin-bottom: 1.5rem;
  }

  #basic-dashboard-example .ash-demo-hero::after {
    content: "";
    position: absolute;
    inset: auto -6rem -7rem auto;
    width: 16rem;
    height: 16rem;
    border-radius: 999px;
    background: radial-gradient(circle, rgba(255, 87, 87, 0.3), transparent 70%);
    pointer-events: none;
  }

  #basic-dashboard-example .ash-demo-hero-grid,
  #basic-dashboard-example .ash-demo-main {
    display: grid;
    gap: 1.25rem;
  }

  #basic-dashboard-example .ash-demo-hero-grid {
    grid-template-columns: minmax(0, 1.45fr) minmax(17rem, 0.95fr);
    align-items: start;
  }

  #basic-dashboard-example .ash-demo-hero-copy {
    position: relative;
    z-index: 1;
  }

  #basic-dashboard-example .ash-demo-title {
    margin: 0.35rem 0 0.9rem;
    font-size: clamp(2.4rem, 4.8vw, 4rem);
    line-height: 0.98;
    font-weight: 800;
    letter-spacing: -0.05em;
    background: linear-gradient(90deg, var(--ash-accent-soft), var(--ash-accent), var(--ash-primary-soft), var(--ash-primary));
    -webkit-background-clip: text;
    background-clip: text;
    color: transparent;
    text-wrap: balance;
  }

  #basic-dashboard-example .ash-demo-copy {
    max-width: 42rem;
    color: var(--ash-copy);
    font-size: 1rem;
    line-height: 1.75;
  }

  #basic-dashboard-example .ash-demo-hero-actions {
    display: flex;
    flex-wrap: wrap;
    gap: 0.8rem;
    margin-top: 1.1rem;
  }

  #basic-dashboard-example .ash-demo-button,
  #basic-dashboard-example .ash-demo-secondary {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-height: 3rem;
    padding: 0.85rem 1.25rem;
    border-radius: 999px;
    border: 1px solid transparent;
    text-decoration: none;
    font-weight: 700;
    transition:
      transform 120ms ease,
      box-shadow 120ms ease,
      border-color 120ms ease,
      background 120ms ease;
  }

  #basic-dashboard-example .ash-demo-button {
    background: linear-gradient(90deg, var(--ash-accent), var(--ash-primary));
    color: #020617;
    box-shadow: 0 0 22px rgba(255, 87, 87, 0.28);
  }

  #basic-dashboard-example .ash-demo-button:hover,
  #basic-dashboard-example .ash-demo-button:focus-visible {
    transform: translateY(-1px);
    box-shadow: 0 0 30px rgba(255, 87, 87, 0.36);
  }

  #basic-dashboard-example .ash-demo-secondary {
    border-color: rgba(255, 145, 77, 0.32);
    background: rgba(255, 145, 77, 0.08);
    color: var(--ash-accent-soft);
  }

  #basic-dashboard-example .ash-demo-secondary:hover,
  #basic-dashboard-example .ash-demo-secondary:focus-visible {
    transform: translateY(-1px);
    border-color: rgba(255, 145, 77, 0.45);
  }

  #basic-dashboard-example .ash-demo-note {
    padding: 1.1rem;
    border-radius: 1.2rem;
    display: grid;
    gap: 0.9rem;
  }

  #basic-dashboard-example .ash-demo-note h2,
  #basic-dashboard-example .ash-demo-card h2 {
    margin: 0;
    font-size: 1.15rem;
    font-weight: 700;
    color: var(--ash-title);
  }

  #basic-dashboard-example .ash-demo-note-copy,
  #basic-dashboard-example .ash-demo-card-copy {
    color: var(--ash-copy);
    font-size: 0.95rem;
    line-height: 1.65;
  }

  #basic-dashboard-example .ash-demo-keyline {
    display: grid;
    gap: 0.75rem;
  }

  #basic-dashboard-example .ash-demo-keyline-row {
    display: flex;
    justify-content: space-between;
    gap: 1rem;
    align-items: baseline;
    border-bottom: 1px solid rgba(70, 73, 93, 0.45);
    padding-bottom: 0.6rem;
  }

  #basic-dashboard-example .ash-demo-keyline-row:last-child {
    border-bottom: 0;
    padding-bottom: 0;
  }

  #basic-dashboard-example .ash-demo-keyline-label {
    color: var(--ash-muted);
    font-size: 0.84rem;
  }

  #basic-dashboard-example .ash-demo-keyline-value {
    color: var(--ash-title);
    font-weight: 600;
    text-align: right;
  }

  #basic-dashboard-example .ash-demo-stats {
    display: grid;
    gap: 1rem;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    margin-bottom: 1.5rem;
  }

  #basic-dashboard-example .ash-demo-stat {
    padding: 1.15rem;
    border-radius: 1.2rem;
    display: grid;
    gap: 0.6rem;
  }

  #basic-dashboard-example .ash-demo-stat-value {
    font-size: 1.35rem;
    font-weight: 700;
    color: var(--ash-title);
  }

  #basic-dashboard-example .ash-demo-stat-copy {
    color: var(--ash-copy);
    font-size: 0.92rem;
  }

  #basic-dashboard-example .ash-demo-main {
    grid-template-columns: minmax(0, 1.1fr) minmax(0, 0.9fr);
  }

  #basic-dashboard-example .ash-demo-stack {
    display: grid;
    gap: 1rem;
  }

  #basic-dashboard-example .ash-demo-card {
    padding: 1.25rem;
    border-radius: 1.35rem;
  }

  #basic-dashboard-example .ash-demo-form {
    display: grid;
    gap: 0.9rem;
    margin-top: 1.15rem;
  }

  #basic-dashboard-example .ash-demo-input {
    width: 100%;
    border-radius: 1rem;
    border: 1px solid rgba(255, 145, 77, 0.24);
    background: rgba(15, 23, 42, 0.88);
    color: var(--ash-title);
    padding: 0.95rem 1rem;
    min-height: 3.2rem;
    box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.03);
  }

  #basic-dashboard-example .ash-demo-input:focus {
    outline: none;
    border-color: rgba(255, 145, 77, 0.6);
    box-shadow: 0 0 0 3px rgba(255, 145, 77, 0.12);
  }

  #basic-dashboard-example .ash-demo-input::placeholder {
    color: #878ba5;
  }

  #basic-dashboard-example .ash-demo-meta {
    display: grid;
    gap: 0.75rem;
    margin-top: 1rem;
  }

  #basic-dashboard-example .ash-demo-meta-row {
    display: flex;
    justify-content: space-between;
    gap: 1rem;
    color: var(--ash-copy);
    font-size: 0.92rem;
  }

  #basic-dashboard-example .ash-demo-meta-row strong {
    color: var(--ash-title);
  }

  #basic-dashboard-example .ash-demo-status {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    font-weight: 600;
    color: var(--ash-title);
  }

  #basic-dashboard-example .ash-demo-status::before {
    content: "";
    width: 0.75rem;
    height: 0.75rem;
    border-radius: 999px;
    background: linear-gradient(135deg, #22c55e, #50fa7b);
    box-shadow: 0 0 12px rgba(80, 250, 123, 0.4);
  }

  #basic-dashboard-example .ash-demo-list {
    display: grid;
    gap: 0.75rem;
    margin-top: 1rem;
  }

  #basic-dashboard-example .ash-demo-list li {
    list-style: none;
    border: 1px solid rgba(70, 73, 93, 0.5);
    border-radius: 1rem;
    padding: 0.9rem 1rem;
    background: rgba(15, 23, 42, 0.68);
    color: var(--ash-copy);
  }

  #basic-dashboard-example .ash-demo-list strong {
    color: var(--ash-title);
    display: block;
    margin-bottom: 0.2rem;
  }

  #basic-dashboard-example .ash-demo-flash {
    margin-top: 1rem;
    padding: 0.9rem 1rem;
    border-radius: 1rem;
    border: 1px solid rgba(255, 118, 118, 0.26);
    background: rgba(255, 87, 87, 0.12);
    color: #ffe4e4;
  }

  #basic-dashboard-example .ash-demo-code {
    margin: 0;
    overflow-x: auto;
    border-radius: 1rem;
    border: 1px solid rgba(70, 73, 93, 0.52);
    background: rgba(15, 23, 42, 0.92);
    color: #dbeafe;
    padding: 1rem;
    font-size: 0.82rem;
    line-height: 1.6;
  }

  @media (max-width: 960px) {
    #basic-dashboard-example .ash-demo-hero-grid,
    #basic-dashboard-example .ash-demo-main,
    #basic-dashboard-example .ash-demo-stats {
      grid-template-columns: 1fr;
    }

    #basic-dashboard-example .ash-demo-topbar {
      border-radius: 1.2rem;
      align-items: flex-start;
      flex-direction: column;
    }

    #basic-dashboard-example .ash-demo-topbar-links {
      justify-content: flex-start;
    }
  }
  """

  def mount(_params, _session, socket) do
    Data.seed!()
    BasicDashboard.seed!()

    socket =
      socket
      |> assign(:current_user, Data.actor())
      |> assign(:ash_ui_domains, [BasicDashboard.Domain, AshUI.Domain])

    with {:ok, socket} <- Integration.mount_ui_screen(socket, :basic_dashboard, %{}) do
      {:ok, assign_dashboard_snapshot(socket)}
    end
  end

  def handle_event("ash_ui_change", %{"profile" => %{"display_name" => value}}, socket) do
    handle_event("ash_ui_change", %{"target" => "value", "value" => value}, socket)
  end

  def handle_event("ash_ui_change", params, socket) do
    case EventHandler.handle_value_change(params, socket) do
      {:noreply, updated_socket} -> {:noreply, assign_dashboard_snapshot(updated_socket)}
      other -> other
    end
  end

  def handle_event(
        "ash_ui_action",
        %{"action_id" => action_id, "display_name" => display_name},
        socket
      ) do
    handle_event(
      "ash_ui_action",
      %{"action_id" => action_id, "data" => %{"display_name" => display_name}},
      socket
    )
  end

  def handle_event("ash_ui_action", %{"profile" => %{"display_name" => display_name}}, socket) do
    handle_event(
      "ash_ui_action",
      %{
        "action_id" => current_action_binding_id(socket.assigns[:ash_ui_bindings] || %{}),
        "data" => %{"display_name" => display_name}
      },
      socket
    )
  end

  def handle_event("ash_ui_action", params, socket) do
    case EventHandler.handle_action_event(params, socket) do
      {:reply, reply, updated_socket} ->
        {:reply, reply, assign_dashboard_snapshot(updated_socket)}

      other ->
        other
    end
  end

  def handle_info(%Ash.Notifier.Notification{} = notification, socket) do
    case UpdateIntegration.handle_resource_change(notification, socket) do
      {:noreply, updated_socket} -> {:noreply, assign_dashboard_snapshot(updated_socket)}
      other -> other
    end
  end

  def render(assigns) do
    ~H"""
    <section id="basic-dashboard-example">
      <style><%= theme_css() %></style>
      <% binding_value = current_binding_value(@ash_ui_bindings) %>
      <% action_id = current_action_binding_id(@ash_ui_bindings) %>
      <% flash_error = flash_message(@flash, :error) %>
      <% flash_info = flash_message(@flash, :info) %>
      <div class="ash-demo-shell">
        <div class="ash-demo-topbar">
          <div class="ash-demo-brand">
            <div class="ash-demo-mark">ash</div>
            <div class="ash-demo-brand-copy">
              <span class="ash-demo-overline">Ash UI example</span>
              <strong class="ash-demo-brand-title">Basic dashboard on ETS-backed Ash resources</strong>
            </div>
          </div>
          <div class="ash-demo-topbar-links">
            <span class="ash-demo-pill"><strong>Theme</strong> Ash HQ palette</span>
            <span class="ash-demo-pill"><strong>Data</strong> ETS + PubSub</span>
            <span class="ash-demo-pill"><strong>Runtime</strong> LiveView bindings</span>
          </div>
        </div>

        <section class="ash-demo-hero">
          <div class="ash-demo-hero-grid">
            <div class="ash-demo-hero-copy">
              <p class="ash-demo-kicker">Ash-inspired example</p>
              <h1 class="ash-demo-title">Model your dashboard. Let the runtime do the wiring.</h1>
              <p class="ash-demo-copy">
                This demo borrows the current Ash site palette, glow accents, dark surfaces, and warm gradient emphasis
                while keeping the dashboard itself focused on live Ash UI bindings.
              </p>
              <div class="ash-demo-hero-actions">
                <span class="ash-demo-secondary">Route {@ash_ui_screen.route}</span>
                <span class="ash-demo-secondary">Screen {Map.get(@ash_ui_screen.metadata || %{}, "title", "Basic Dashboard")}</span>
              </div>
            </div>

            <aside class="ash-demo-note">
              <h2>Live signal preview</h2>
              <p class="ash-demo-note-copy">
                The input is bidirectionally bound to a real ETS-backed `BasicDashboard.User`, and the save button runs the
                `save_profile` Ash action with actor context.
              </p>
              <div class="ash-demo-keyline">
                <div class="ash-demo-keyline-row">
                  <span class="ash-demo-keyline-label">Current value</span>
                  <strong class="ash-demo-keyline-value">{binding_value}</strong>
                </div>
                <div class="ash-demo-keyline-row">
                  <span class="ash-demo-keyline-label">Last actor</span>
                  <strong class="ash-demo-keyline-value">{display_last_actor(@dashboard_data.user.last_actor_id)}</strong>
                </div>
                <div class="ash-demo-keyline-row">
                  <span class="ash-demo-keyline-label">Bindings</span>
                  <strong class="ash-demo-keyline-value">{map_size(@ash_ui_bindings || %{})}</strong>
                </div>
              </div>
            </aside>
          </div>
        </section>

        <section class="ash-demo-stats">
          <article class="ash-demo-stat">
            <span class="ash-demo-label">User</span>
            <strong class="ash-demo-stat-value">{@dashboard_data.user.name}</strong>
            <span class="ash-demo-stat-copy">{@dashboard_data.user.email}</span>
          </article>

          <article class="ash-demo-stat">
            <span class="ash-demo-label">Status</span>
            <strong class="ash-demo-stat-value ash-demo-status">{@dashboard_data.user.status}</strong>
            <span class="ash-demo-stat-copy">Actor-scoped updates enabled</span>
          </article>

          <article class="ash-demo-stat">
            <span class="ash-demo-label">Team</span>
            <strong class="ash-demo-stat-value">{@dashboard_data.profile.team}</strong>
            <span class="ash-demo-stat-copy">Profile name: {@dashboard_data.profile.name}</span>
          </article>

          <article class="ash-demo-stat">
            <span class="ash-demo-label">Renderer path</span>
            <strong class="ash-demo-stat-value">Ash UI -> LiveView</strong>
            <span class="ash-demo-stat-copy">Compiled screen + runtime bindings</span>
          </article>
        </section>

        <section class="ash-demo-main">
          <div class="ash-demo-stack">
            <article class="ash-demo-card">
              <p class="ash-demo-kicker">Interactive profile editor</p>
              <h2>Update the current user</h2>
              <p class="ash-demo-card-copy">
                Type into the bound field to update the in-memory resource immediately, then click save to persist through
                the `save_profile` Ash action.
              </p>

              <.form for={%{}} as={:profile} phx-change="ash_ui_change" class="ash-demo-form">
                <label class="ash-demo-mini-label" for="dashboard-display-name">Display name</label>
                <input
                  id="dashboard-display-name"
                  class="ash-demo-input"
                  type="text"
                  name="profile[display_name]"
                  value={binding_value}
                  placeholder="Enter your name"
                  phx-debounce="150"
                />
              </.form>

              <button
                type="button"
                class="ash-demo-button"
                phx-click="ash_ui_action"
                phx-value-action_id={action_id}
                phx-value-display_name={binding_value}
                disabled={is_nil(action_id)}
              >
                Save profile
              </button>

              <div class="ash-demo-meta">
                <div class="ash-demo-meta-row">
                  <span>Resource</span>
                  <strong>BasicDashboard.User</strong>
                </div>
                <div class="ash-demo-meta-row">
                  <span>Action</span>
                  <strong>save_profile</strong>
                </div>
                <div class="ash-demo-meta-row">
                  <span>Actor</span>
                  <strong>{@current_user.id}</strong>
                </div>
              </div>

              <%= if flash_error do %>
                <div class="ash-demo-flash"><strong>Error:</strong> {flash_error}</div>
              <% end %>

              <%= if flash_info do %>
                <div class="ash-demo-flash"><strong>Info:</strong> {flash_info}</div>
              <% end %>
            </article>

            <article class="ash-demo-card">
              <p class="ash-demo-kicker">What this demo is showing</p>
              <h2>ETS-backed dashboard data</h2>
              <ul class="ash-demo-list">
                <li>
                  <strong>Real Ash resources</strong>
                  `BasicDashboard.User` and `BasicDashboard.Profile` live in an ETS data layer domain.
                </li>
                <li>
                  <strong>Runtime reactivity</strong>
                  PubSub notifications refresh the LiveView snapshot when the resource changes.
                </li>
                <li>
                  <strong>Persisted UI contract</strong>
                  The screen, elements, and bindings are still stored through Ash UI resources.
                </li>
              </ul>
            </article>
          </div>

          <div class="ash-demo-stack">
            <article class="ash-demo-card">
              <p class="ash-demo-kicker">Snapshot</p>
              <h2>Current dashboard state</h2>
              <div class="ash-demo-keyline">
                <div class="ash-demo-keyline-row">
                  <span class="ash-demo-keyline-label">Display name</span>
                  <strong class="ash-demo-keyline-value">{@dashboard_data.user.name}</strong>
                </div>
                <div class="ash-demo-keyline-row">
                  <span class="ash-demo-keyline-label">Email</span>
                  <strong class="ash-demo-keyline-value">{@dashboard_data.user.email}</strong>
                </div>
                <div class="ash-demo-keyline-row">
                  <span class="ash-demo-keyline-label">Team</span>
                  <strong class="ash-demo-keyline-value">{@dashboard_data.profile.team}</strong>
                </div>
                <div class="ash-demo-keyline-row">
                  <span class="ash-demo-keyline-label">Last actor</span>
                  <strong class="ash-demo-keyline-value">{display_last_actor(@dashboard_data.user.last_actor_id)}</strong>
                </div>
              </div>
            </article>

            <article class="ash-demo-card">
              <p class="ash-demo-kicker">Compiled screen</p>
              <h2>IUR preview</h2>
              <pre class="ash-demo-code">{iur_preview(@ash_ui_iur)}</pre>
            </article>
          </div>
        </section>
      </div>
    </section>
    """
  end

  defp assign_dashboard_snapshot(socket) do
    assign(socket, :dashboard_data, Data.snapshot!())
  end

  defp current_binding_value(bindings) do
    bindings
    |> Map.values()
    |> Enum.find_value(fn binding ->
      if binding.binding_type == :value and binding.target == "value" do
        binding.value
      end
    end)
    |> case do
      nil -> ""
      value -> value
    end
  end

  defp current_action_binding_id(bindings) do
    bindings
    |> Map.values()
    |> Enum.find_value(fn binding ->
      if binding.binding_type == :action do
        binding.id
      end
    end)
  end

  defp display_last_actor(nil), do: "none yet"
  defp display_last_actor(actor_id), do: actor_id

  defp flash_message(flash, key) when is_map(flash) do
    Map.get(flash, key) || Map.get(flash, Atom.to_string(key))
  end

  defp iur_preview(iur) do
    inspect(iur, pretty: true, limit: :infinity)
  end

  defp theme_css, do: @ash_theme_css
end
