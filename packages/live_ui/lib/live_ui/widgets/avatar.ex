defmodule LiveUi.Widgets.Avatar do
  @moduledoc """
  Baseline native avatar widget.

  Renders an actor identity chip: either an `<img>` (when `image_url` is
  present) or a two-letter initials fallback `<span>`.

  ## Attribute notes

  * `actor_id` — opaque identity reference attached as a `data-actor-id` DOM
    hook so JavaScript hydration can address the element without coupling to
    internal structure.
  * `size_variant` — `:small | :medium | :large`; translates to the CSS class
    `live-ui-avatar--small`, `live-ui-avatar--medium`, or `live-ui-avatar--large`.
    Sizing is CSS-only; the component emits the class and steps back.
  * `tone` — `:neutral | :positive | :warning | :danger`; CSS class only,
    exactly like other widgets.
  * `state` — `:idle | :selected | :highlight`; CSS class only.
  * `label_text` — used as `aria-label` on the outer `<span>` and as `alt`
    text on the `<img>`. When neither visible text nor image alt is present,
    providing `label_text` satisfies WCAG 2.1 SC 4.1.2 for icon-only avatars.
  * `initials` — shown only when `image_url` is nil; gets `aria-hidden="true"`
    when an image is present (the image alt carries the accessible name).
  """

  use LiveUi.Component,
    family: :content,
    name: :avatar,
    assigns: [:actor_id, :initials, :image_url, :size_variant, :label_text]

  LiveUi.Component.common_attrs()
  attr(:actor_id, :string, required: true)
  attr(:initials, :string, default: nil)
  attr(:image_url, :string, default: nil)
  attr(:size_variant, :atom, default: :small, values: [:small, :medium, :large])
  attr(:label_text, :string, default: nil)

  @impl true
  def render(assigns) do
    ~H"""
    <span
      id={@id}
      class={["live-ui-avatar", size_class(@size_variant), @class]}
      data-live-ui-widget="avatar"
      data-live-ui-tone={@tone}
      data-live-ui-state={@state}
      data-actor-id={@actor_id}
      aria-label={@label_text}
      {@rest}
    >
      <%= if @image_url do %>
        <img
          src={@image_url}
          alt={@label_text}
          class="live-ui-avatar-image"
        />
      <% else %>
        <span
          class="live-ui-avatar-initials"
          aria-hidden={if @label_text, do: "true", else: "false"}
        >
          {@initials}
        </span>
      <% end %>
    </span>
    """
  end

  defp size_class(:small), do: "live-ui-avatar--small"
  defp size_class(:medium), do: "live-ui-avatar--medium"
  defp size_class(:large), do: "live-ui-avatar--large"
  defp size_class(_other), do: "live-ui-avatar--small"
end
