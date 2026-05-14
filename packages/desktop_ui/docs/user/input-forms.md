# Input & Forms

This guide covers input widgets and form handling in DesktopUi.

## Table of Contents
1. [Text Inputs](#text-inputs)
2. [Numeric Inputs](#numeric-inputs)
3. [Selection Widgets](#selection-widgets)
4. [Form Building](#form-building)
5. [Validation](#validation)
6. [Complete Form Example](#complete-form-example)

## Text Inputs

### TextInput

Basic text entry:

```elixir
Widgets.text_input("username",
  placeholder: "Enter username",
  binding: {:form, :username}
)
```

### TextInput Options

```elixir
Widgets.text_input("email",
  placeholder: "your@email.com",
  value: "",
  disabled: false,
  binding: {:form, :email}
)

# With max length
Widgets.text_input("code",
  placeholder: "Enter code",
  max_length: 6
)

# Password-style input
Widgets.text_input("password",
  placeholder: "Password",
  secret: true
)
```

### TextArea (multi-line)

```elixir
Widgets.text_input("description",
  placeholder: "Enter description...",
  multiline: true,
  rows: 5
)
```

## Numeric Inputs

### NumericInput

Number entry with bounds:

```elixir
Widgets.numeric_input("age",
  value: 25,
  min: 0,
  max: 120,
  step: 1
)
```

### NumericInput Options

```elixir
# With increment/decrement buttons
Widgets.numeric_input("quantity",
  value: 1,
  min: 1,
  max: 100,
  step: 1
)

# Decimal values
Widgets.numeric_input("price",
  value: 9.99,
  min: 0.0,
  max: 1000.0,
  step: 0.01
)

# Read-only
Widgets.numeric_input("readonly",
  value: 42,
  disabled: true
)
```

### Slider

Range selection:

```elixir
Widgets.slider("volume",
  value: 75,
  min: 0,
  max: 100
)
```

### Slider Options

```elixir
# With value display
Widgets.slider("progress",
  value: 50,
  min: 0,
  max: 100,
  show_value: true
)

# Vertical slider
Widgets.slider("vslider",
  value: 50,
  min: 0,
  max: 100,
  orientation: :vertical
)
```

## Selection Widgets

### Checkbox

Single boolean choice:

```elixir
Widgets.checkbox("agree", "I agree to the terms",
  checked: false,
  binding: {:form, :agreed}
)
```

### Checkbox Options

```elixir
# Indeterminate state
Widgets.checkbox("partial", "Select all",
  checked: :indeterminate
)

# With description
Widgets.checkbox("featured", "Feature this item",
  description: "Show on homepage"
)
```

### RadioGroup

Single choice from options:

```elixir
Widgets.radio_group("role",
  options: [
    [label: "User", value: "user"],
    [label: "Admin", value: "admin"],
    [label: "Moderator", value: "mod"]
  ],
  selected: "user"
)
```

### RadioGroup Options

```elixir
# With binding
Widgets.radio_group("plan",
  options: plans,
  binding: {:form, :plan_id}
)

# Horizontal layout
Widgets.radio_group("orientation",
  options: [
    [label: "Horizontal", value: :horizontal],
    [label: "Vertical", value: :vertical]
  ],
  layout: :row
)
```

### Select

Dropdown selection:

```elixir
Widgets.select("country",
  options: [
    [label: "United States", value: "us"],
    [label: "Canada", value: "ca"],
    [label: "United Kingdom", value: "uk"]
  ]
)
```

### Select Options

```elixir
# With placeholder
Widgets.select("state",
  options: states,
  placeholder: "Select a state..."
)

# With search
Widgets.select("user",
  options: users,
  searchable: true
)

# Multi-select
Widgets.select("tags",
  options: tags,
  multiple: true
)
```

### PickList

Searchable list with more options:

```elixir
Widgets.pick_list("assignee",
  options: users,
  placeholder: "Assign to...",
  searchable: true,
  multiple: false
)
```

### Toggle

Switch-style boolean:

```elixir
Widgets.toggle("notifications", "Enable notifications",
  checked: true,
  on_change: fn %{checked: enabled} ->
    MyApp.Settings.update_notifications(enabled)
  end
)
```

## Temporal Inputs

### DateInput

```elixir
Widgets.date_input("birthday",
  value: ~D[1990-01-01],
  min: ~D[1900-01-01],
  max: Date.utc_today()
)
```

### DateInput Options

```elixir
# With format
Widgets.date_input("start",
  value: Date.utc_today(),
  format: :ymd
)

# Date range
Widgets.date_input("end",
  value: nil,
  min: ~D[2025-01-01],
  max: ~D[2025-12-31]
)
```

### TimeInput

```elixir
Widgets.time_input("alarm",
  value: ~T[07:30:00],
  format: :hms
)
```

### TimeInput Options

```elixir
# 12-hour format
Widgets.time_input("meeting",
  value: ~T[14:30:00],
  format: :"12h"
)

# 24-hour format
Widgets.time_input("deadline",
  value: ~T[17:00:00],
  format: :"24h"
)
```

## Form Building

### Form Structure

```elixir
defmodule MyApp.Screens.Settings do
  alias DesktopUi.Widgets

  def screen do
    %{
      id: "settings",
      title: "Settings",
      root: form()
    }
  end

  defp form do
    Widgets.column("form", [],
      gap: 16,
      padding: 24,
      children: [
        form_header(),
        text_fields(),
        numeric_fields(),
        selection_fields(),
        form_actions()
      ]
    )
  end

  defp form_header do
    Widgets.text("header", "User Settings",
      styles: %{size: :xl}
    )
  end

  defp text_fields do
    Widgets.column("text-fields", [],
      gap: 12,
      children: [
        field("Name",
          Widgets.text_input("name",
            placeholder: "Full name"
          )
        ),
        field("Email",
          Widgets.text_input("email",
            type: :email,
            placeholder: "email@example.com"
          )
        ),
        field("Bio",
          Widgets.text_input("bio",
            multiline: true,
            rows: 4,
            placeholder: "Tell us about yourself..."
          )
        )
      ]
    )
  end

  defp numeric_fields do
    Widgets.column("numeric-fields", [],
      gap: 12,
      children: [
        field("Age",
          Widgets.numeric_input("age",
            value: 25,
            min: 0,
            max: 120
          )
        ),
        field("Volume",
          Widgets.slider("volume",
            value: 75,
            min: 0,
            max: 100
          )
        )
      ]
    )
  end

  defp selection_fields do
    Widgets.column("selection-fields", [],
      gap: 12,
      children: [
        field("Country",
          Widgets.select("country",
            options: country_options()
          )
        ),
        field("Notifications",
          Widgets.toggle("notifications",
            "Enable email notifications",
            checked: true
          )
        ),
        field("Topics",
          Widgets.checkbox_group("topics",
            options: [
              [label: "News", value: "news"],
              [label: "Updates", value: "updates"],
              [label: "Promos", value: "promos"]
            ]
          )
        )
      ]
    )
  end

  defp form_actions do
    Widgets.row("actions", [],
      gap: 8,
      justify: :end,
      children: [
        Widgets.button("cancel", "Cancel",
          variant: :secondary
        ),
        Widgets.button("submit", "Save Changes",
          variant: :primary
        )
      ]
    )
  end

  defp field(label, input_widget) do
    Widgets.column("field", [],
      gap: 4,
      children: [
        Widgets.label("label", label,
          for: input_widget.id
        ),
        input_widget
      ]
    )
  end

  defp country_options do
    [
      [label: "United States", value: "us"],
      [label: "Canada", value: "ca"],
      [label: "United Kingdom", value: "uk"],
      [label: "Australia", value: "au"]
    ]
  end
end
```

## Validation

### Client-Side Validation

```elixir
Widgets.text_input("email",
  placeholder: "Email",
  validate: fn value ->
    case Regex.run(~r/^[^@]+@[^@]+\.[^@]+$/, value) do
      nil -> {:error, "Invalid email format"}
      _ -> :ok
    end
  end
)
```

### Required Fields

```elixir
Widgets.text_input("required",
  placeholder: "Required field",
  required: true,
  validate: fn
    "" -> {:error, "This field is required"}
    _ -> :ok
  end
)
```

### Validation States

```elixir
Widgets.text_input("username",
  placeholder: "Username",
  validate: &validate_username/1
)

defp validate_username(value) do
  cond do
    String.length(value) < 3 ->
      {:error, "Must be at least 3 characters"}

    String.length(value) > 20 ->
      {:error, "Must be 20 characters or less"}

    not Regex.match?(~r/^[a-zA-Z0-9_]+$/, value) ->
      {:error, "Only letters, numbers, and underscores"}

    true ->
      :ok
  end
end
```

## Complete Form Example

```elixir
defmodule MyApp.Screens.Signup do
  alias DesktopUi.Widgets

  def screen do
    %{
      id: "signup",
      title: "Sign Up",
      root: signup_form()
    }
  end

  def signup_form do
    Widgets.column("form", [],
      gap: 16,
      padding: 32,
      styles: %{max_width: 400},
      children: [
        header(),
        Widgets.text("subtitle", "Create your account",
          styles: %{variant: :muted}
        ),
        Widgets.separator("sep"),
        username_field(),
        email_field(),
        password_field(),
        password_confirm_field(),
        terms_field(),
        submit_button()
      ]
    )
  end

  defp header do
    Widgets.text("header", "Sign Up",
      styles: %{size: :xxl}
    )
  end

  defp username_field do
    Widgets.column("username-field", [],
      gap: 4,
      children: [
        Widgets.label("label", "Username"),
        Widgets.text_input("username",
          placeholder: "Choose a username",
          validate: &validate_username/1,
          binding: {:form, :username}
        )
      ]
    )
  end

  defp email_field do
    Widgets.column("email-field", [],
      gap: 4,
      children: [
        Widgets.label("label", "Email"),
        Widgets.text_input("email",
          type: :email,
          placeholder: "you@example.com",
          validate: &validate_email/1,
          binding: {:form, :email}
        )
      ]
    )
  end

  defp password_field do
    Widgets.column("password-field", [],
      gap: 4,
      children: [
        Widgets.label("label", "Password"),
        Widgets.text_input("password",
          type: :password,
          placeholder: "Choose a password",
          secret: true,
          validate: &validate_password/1,
          binding: {:form, :password}
        )
      ]
    )
  end

  defp password_confirm_field do
    Widgets.column("confirm-field", [],
      gap: 4,
      children: [
        Widgets.label("label", "Confirm Password"),
        Widgets.text_input("password_confirm",
          type: :password,
          placeholder: "Confirm your password",
          secret: true,
          validate: fn value ->
            if value == get_form_value(:password) do
              :ok
            else
              {:error, "Passwords don't match"}
            end
          end
        )
      ]
    )
  end

  defp terms_field do
    Widgets.checkbox("terms", "I agree to the Terms of Service",
      required: true,
      binding: {:form, :accepted_terms}
    )
  end

  defp submit_button do
    Widgets.button("submit", "Create Account",
      variant: :primary,
      size: :lg,
      disabled: false,
      on_click: &submit_form/1
    )
  end

  # Validators
  defp validate_username(""), do: {:error, "Username is required"}
  defp validate_username(value) when byte_size(value) < 3, do: {:error, "Too short (min 3 characters)"}
  defp validate_username(value) when byte_size(value) > 20, do: {:error, "Too long (max 20 characters)"}
  defp validate_username(_), do: :ok

  defp validate_email(""), do: {:error, "Email is required"}
  defp validate_email(value) do
    if Regex.match?(~r/^[^@]+@[^@]+\.[^@]+$/, value) do
      :ok
    else
      {:error, "Invalid email format"}
    end
  end

  defp validate_password(""), do: {:error, "Password is required"}
  defp validate_password(value) when byte_size(value) < 8, do: {:error, "Too short (min 8 characters)"}
  defp validate_password(_), do: :ok
end
```

## Quick Reference

| Widget | Purpose | Key Options |
|--------|---------|-------------|
| `text_input/2` | Text entry | `placeholder`, `secret`, `multiline` |
| `numeric_input/2` | Number entry | `min`, `max`, `step` |
| `slider/2` | Range slider | `min`, `max`, `show_value` |
| `checkbox/3` | Boolean choice | `checked`, `label` |
| `radio_group/3` | Single select | `options`, `selected` |
| `select/3` | Dropdown | `options`, `searchable`, `multiple` |
| `pick_list/3` | List selector | `options`, `searchable` |
| `toggle/2` | Switch | `checked` |
| `date_input/2` | Date picker | `min`, `max`, `format` |
| `time_input/2` | Time picker | `format` |

## Next Steps

- [Basic Widgets](./basic-widgets.md) - More widget options
- [Layout & Composition](./layout-composition.md) - Form layout
- [Events & Interactions](./events-interactions.md) - Form submission
