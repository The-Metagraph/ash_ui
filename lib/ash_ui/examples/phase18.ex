defmodule AshUI.Examples.Phase18 do
  @moduledoc """
  Phase 18 example-suite definitions and path helpers.

  The standalone example directories under `examples/` are generated from these
  definitions so the checked-in projects, tests, and planning artifacts stay in
  sync.
  """

  @type definition :: %{
          directory: String.t(),
          section: atom(),
          family: atom(),
          title: String.t(),
          subject_type: atom(),
          subject_props: map(),
          story_text: String.t(),
          signal_text: String.t(),
          seed_state: map(),
          preview_field: atom() | nil,
          preview_title: String.t() | nil,
          subject_binding: map() | nil,
          subject_action: map() | nil,
          support_notice: String.t() | nil,
          notes: String.t() | nil
        }

  @sections [:foundational, :form_scaffolding, :inputs, :integration]

  @foundational_definitions [
    %{
      directory: "text",
      section: :foundational,
      family: :content,
      title: "Text Example",
      subject_type: :text,
      subject_props: %{
        content: "Resource-owned copy stays readable inside the shared Ash HQ shell.",
        class: "ashui-example-subject ashui-example-copy"
      },
      story_text:
        "Meaningful Interaction Story: review the authored copy and confirm the shared shell keeps text content legible without bypassing the resource-authority path.",
      signal_text:
        "Canonical Signal Preview: value binding -> ExampleState.display_value -> subject.content.",
      seed_state: %{
        id: "state-text",
        display_value: "Resource-owned copy stays readable inside the shared Ash HQ shell.",
        status: "Mounted through AshUI.Resource.Authority."
      },
      preview_field: :status,
      preview_title: "Persistence path",
      subject_binding: %{
        id: :display_value,
        field: :display_value,
        target: "content",
        transform: %{}
      },
      subject_action: nil,
      support_notice: nil,
      notes: "Uses the current public text widget directly."
    },
    %{
      directory: "button",
      section: :foundational,
      family: :content,
      title: "Button Example",
      subject_type: :button,
      subject_props: %{
        label: "Persist button story",
        variant: "primary",
        class: "ashui-example-primary-cta"
      },
      story_text:
        "Meaningful Interaction Story: click the primary button and confirm the current status changes without leaving the resource-authority runtime path.",
      signal_text:
        "Canonical Signal Preview: click -> ExampleState.update(status, current_value) through an element-local action.",
      seed_state: %{
        id: "state-button",
        current_value: "Idle",
        status: "Waiting for click"
      },
      preview_field: :current_value,
      preview_title: "Current state",
      subject_binding: nil,
      subject_action: %{
        id: :press_button,
        signal: :click,
        params: %{
          current_value: %{"from" => "static", "value" => "Button press persisted"},
          status: %{"from" => "static", "value" => "Action completed"}
        },
        metadata: %{intent: "button_press", success_message: "Button example updated"}
      },
      support_notice: nil,
      notes: "Uses the current public button widget directly."
    },
    %{
      directory: "label",
      section: :foundational,
      family: :content,
      title: "Label Example",
      subject_type: :label,
      subject_props: %{
        text: "Profile nickname",
        for: "profile-nickname",
        class: "ashui-example-label"
      },
      story_text:
        "Meaningful Interaction Story: review the authored label copy and confirm it remains distinct from helper text and stat surfaces inside the example shell.",
      signal_text:
        "Canonical Signal Preview: value binding -> ExampleState.display_value -> subject.text.",
      seed_state: %{
        id: "state-label",
        display_value: "Profile nickname",
        status: "Label rendered through the public authoring surface."
      },
      preview_field: :status,
      preview_title: "Renderer note",
      subject_binding: %{
        id: :label_copy,
        field: :display_value,
        target: "text",
        transform: %{}
      },
      subject_action: nil,
      support_notice:
        "The fallback renderer already understands `label`; Phase 18 admits it as a first-class authored example surface.",
      notes: "Promotes the existing label renderer into the public example suite."
    },
    %{
      directory: "link",
      section: :foundational,
      family: :content,
      title: "Link Example",
      subject_type: :"custom:link",
      subject_props: %{
        label: "Open Ash HQ",
        href: "https://www.ash-hq.org/",
        target: "_blank",
        rel: "noreferrer",
        class: "ashui-example-link"
      },
      story_text:
        "Meaningful Interaction Story: inspect the styled navigation affordance and confirm the example calls out that link semantics are still implemented through an explicit custom surface.",
      signal_text:
        "Canonical Signal Preview: custom:link surface -> browser navigation; no Ash write is implied by the example itself.",
      seed_state: %{
        id: "state-link",
        status: "Custom surface until link semantics are admitted publicly."
      },
      preview_field: :status,
      preview_title: "Support note",
      subject_binding: nil,
      subject_action: nil,
      support_notice:
        "Navigation semantics are intentionally implemented as `custom:link` so the example stays honest about the current public widget boundary.",
      notes: "Preserves the sibling directory name while using a custom surface."
    },
    %{
      directory: "icon",
      section: :foundational,
      family: :content,
      title: "Icon Example",
      subject_type: :icon,
      subject_props: %{
        name: "sparkles",
        label: "Ready",
        class: "ashui-example-icon"
      },
      story_text:
        "Meaningful Interaction Story: review the icon inside the shared presentation panel and confirm the fallback renderer exposes both the glyph token and its accessible label.",
      signal_text:
        "Canonical Signal Preview: value binding -> ExampleState.display_value -> subject.label.",
      seed_state: %{
        id: "state-icon",
        display_value: "Ready",
        status: "Icon fallback renderer admitted for standalone examples."
      },
      preview_field: :status,
      preview_title: "Renderer note",
      subject_binding: %{
        id: :icon_label,
        field: :display_value,
        target: "label",
        transform: %{}
      },
      subject_action: nil,
      support_notice: nil,
      notes: "Uses the public icon widget with a richer fallback presentation."
    },
    %{
      directory: "image",
      section: :foundational,
      family: :content,
      title: "Image Example",
      subject_type: :image,
      subject_props: %{
        src: "https://www.ash-hq.org/images/og-image.png",
        alt: "Ash HQ visual treatment",
        class: "ashui-example-image"
      },
      story_text:
        "Meaningful Interaction Story: confirm the image example renders as a real preview surface rather than a generic wrapper while still using the shared Ash HQ shell.",
      signal_text:
        "Canonical Signal Preview: static authored props -> rendered image preview; no write signal is emitted.",
      seed_state: %{
        id: "state-image",
        status: "Image preview uses the fallback renderer's image-specific markup."
      },
      preview_field: :status,
      preview_title: "Renderer note",
      subject_binding: nil,
      subject_action: nil,
      support_notice: nil,
      notes: "Uses the public image widget with real <img> fallback markup."
    },
    %{
      directory: "separator",
      section: :foundational,
      family: :content,
      title: "Separator Example",
      subject_type: :divider,
      subject_props: %{
        class: "ashui-example-divider"
      },
      story_text:
        "Meaningful Interaction Story: review how the normalized `divider` subject preserves the sibling directory name while keeping the shell visually structured.",
      signal_text:
        "Canonical Signal Preview: directory parity `separator` -> canonical Ash UI subject `divider`.",
      seed_state: %{
        id: "state-separator",
        status: "Directory parity preserved through canonical divider authoring."
      },
      preview_field: :status,
      preview_title: "Normalization",
      subject_binding: nil,
      subject_action: nil,
      support_notice: nil,
      notes: "Preserves sibling naming while authoring through divider."
    },
    %{
      directory: "spacer",
      section: :foundational,
      family: :content,
      title: "Spacer Example",
      subject_type: :spacer,
      subject_props: %{
        size: 32,
        class: "ashui-example-spacer"
      },
      story_text:
        "Meaningful Interaction Story: verify the authored spacer creates intentional breathing room inside the shared review shell without introducing fake container semantics.",
      signal_text:
        "Canonical Signal Preview: static spacer props -> rendered layout gap; no write signal is emitted.",
      seed_state: %{
        id: "state-spacer",
        status: "Spacer rendered through the public widget surface."
      },
      preview_field: :status,
      preview_title: "Renderer note",
      subject_binding: nil,
      subject_action: nil,
      support_notice: nil,
      notes: "Uses the current public spacer widget directly."
    },
    %{
      directory: "content",
      section: :foundational,
      family: :content,
      title: "Content Example",
      subject_type: :text,
      subject_props: %{
        content:
          "Composed content examples can still stay resource-first even when the primary subject is a named presentation pattern rather than one dedicated widget type.",
        class: "ashui-example-copy ashui-example-copy-wide"
      },
      story_text:
        "Meaningful Interaction Story: review the long-form content block and confirm the example treats content as a composed review pattern instead of overstating a dedicated widget surface.",
      signal_text:
        "Canonical Signal Preview: composed native content review pattern -> resource-owned text block within the shared shell.",
      seed_state: %{
        id: "state-content",
        status: "Composed content pattern mounted through the shared scaffold."
      },
      preview_field: :status,
      preview_title: "Composition note",
      subject_binding: nil,
      subject_action: nil,
      support_notice:
        "The `content` directory is intentionally implemented as a composed review pattern rather than a newly claimed public widget type.",
      notes: "Uses a composed native review pattern."
    },
    %{
      directory: "box",
      section: :foundational,
      family: :content,
      title: "Box Example",
      subject_type: :card,
      subject_props: %{
        title: "Box shell",
        class: "ashui-example-box"
      },
      story_text:
        "Meaningful Interaction Story: review the empty container shell and confirm the example is explicit that box semantics are expressed through composed card/container structure.",
      signal_text:
        "Canonical Signal Preview: composed native container review pattern -> `card` shell plus support note.",
      seed_state: %{
        id: "state-box",
        status: "Box example composes container semantics from native card structure."
      },
      preview_field: :status,
      preview_title: "Composition note",
      subject_binding: nil,
      subject_action: nil,
      support_notice:
        "The `box` directory preserves sibling parity while the current Ash UI implementation composes the experience from native container/card structure.",
      notes: "Uses a composed native container pattern."
    }
  ]

  @doc """
  Returns every currently authored Phase 18 definition.
  """
  @spec definitions() :: [definition()]
  def definitions do
    @foundational_definitions
  end

  @doc """
  Returns the authored sections known to Phase 18.
  """
  @spec sections() :: [atom()]
  def sections, do: @sections

  @doc """
  Returns the definitions for one section.
  """
  @spec definitions_for(atom()) :: [definition()]
  def definitions_for(section) when section in @sections do
    Enum.filter(definitions(), &(&1.section == section))
  end

  @doc """
  Fetches one definition by directory name.
  """
  @spec definition!(String.t()) :: definition()
  def definition!(directory) when is_binary(directory) do
    Enum.find(definitions(), &(&1.directory == directory)) ||
      raise ArgumentError, "unknown Phase 18 example directory: #{inspect(directory)}"
  end

  @doc """
  Returns the app atom for a generated standalone example.
  """
  @spec app_atom(String.t()) :: atom()
  def app_atom(directory) when is_binary(directory) do
    String.to_atom("ash_ui_example_#{directory}")
  end

  @doc """
  Returns the root Elixir module for a generated standalone example.
  """
  @spec example_module(String.t()) :: module()
  def example_module(directory) when is_binary(directory) do
    directory
    |> Macro.camelize()
    |> then(&Module.concat([AshUIExamples, &1]))
  end

  @doc """
  Returns the canonical screen name for one example directory.
  """
  @spec screen_name(String.t()) :: String.t()
  def screen_name(directory) when is_binary(directory), do: "example/#{directory}"

  @doc """
  Returns the on-disk example project path for a directory.
  """
  @spec project_path(String.t()) :: String.t()
  def project_path(directory) when is_binary(directory) do
    Path.expand("../../../examples/#{directory}", __DIR__)
  end

  @doc """
  Returns every currently authored example directory.
  """
  @spec directories() :: [String.t()]
  def directories do
    definitions()
    |> Enum.map(& &1.directory)
    |> Enum.sort()
  end
end
