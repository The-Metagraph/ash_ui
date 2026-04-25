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
          subject_children: [map()],
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

  @form_scaffolding_definitions [
    %{
      directory: "form_builder",
      section: :form_scaffolding,
      family: :forms,
      title: "Form Builder Example",
      subject_type: :form_builder,
      subject_props: %{
        class: "ashui-example-form"
      },
      story_text:
        "Meaningful Interaction Story: edit the nested display-name field and submit the form to confirm the authored form shell owns the review surface while the write and submit flow stay local to the resource graph.",
      signal_text:
        "Canonical Signal Preview: nested input change -> ExampleState.display_value; form submit -> ExampleState.submitted_value and ExampleState.status.",
      seed_state: %{
        id: "state-form_builder",
        current_value: "Ada Example",
        display_value: "Ada Example",
        submitted_value: "Not submitted",
        status: "Awaiting form submission"
      },
      preview_field: :submitted_value,
      preview_title: "Last submitted value",
      subject_binding: nil,
      subject_action: %{
        id: :submit_profile,
        signal: :submit,
        params: %{
          submitted_value: %{"from" => "binding", "key" => "display_name"},
          status: %{"from" => "static", "value" => "Form submitted through form_builder"}
        },
        metadata: %{intent: "submit_profile", owner: "form_builder"}
      },
      subject_children: [
        %{
          key: :display_name_field,
          type: :form_field,
          props: %{
            name: "display_name",
            label: "Display name",
            help: "Bound locally and submitted through the form builder.",
            class: "ashui-example-form-field"
          },
          position: 0,
          children: [
            %{
              key: :display_name_input,
              type: :input,
              props: %{
                name: "display_name",
                type: "text",
                value: "Ada Example",
                placeholder: "Ada Example",
                class: "ashui-example-input"
              },
              position: 0,
              bindings: [
                %{
                  id: :display_name_input,
                  source: %{
                    resource: "ExampleState",
                    field: :display_value,
                    id: "state-form_builder"
                  },
                  target: "display_name",
                  binding_type: :value,
                  transform: %{},
                  metadata: %{owner: "input", owner_signal: "change"}
                }
              ],
              children: []
            }
          ]
        },
        %{
          key: :submit_button,
          type: :button,
          props: %{
            label: "Save profile",
            type: "submit",
            variant: "primary",
            class: "ashui-example-primary-cta"
          },
          position: 10,
          children: []
        }
      ],
      support_notice:
        "The example uses `form_builder` as the public subject and keeps submit handling local to the authored form resource.",
      notes: "Promotes form_builder from fallback-only rendering into the public example suite."
    },
    %{
      directory: "field",
      section: :form_scaffolding,
      family: :forms,
      title: "Field Example",
      subject_type: :form_field,
      subject_props: %{
        name: "display_name",
        label: "Display name",
        help: "Field structure stays local to the resource graph.",
        class: "ashui-example-form-field"
      },
      story_text:
        "Meaningful Interaction Story: review the field wrapper and edit the nested input to confirm the field keeps label and help context while the write remains owned by the input element.",
      signal_text:
        "Canonical Signal Preview: nested input change -> ExampleState.display_value -> preview stat, while `field` stays normalized to the canonical `form_field` widget.",
      seed_state: %{
        id: "state-field",
        display_value: "Ada Example",
        status: "Normalized from `field` into `form_field`."
      },
      preview_field: :display_value,
      preview_title: "Current field value",
      subject_binding: nil,
      subject_action: nil,
      subject_children: [
        %{
          key: :display_name_input,
          type: :input,
          props: %{
            name: "display_name",
            type: "text",
            value: "Ada Example",
            placeholder: "Ada Example",
            class: "ashui-example-input"
          },
          position: 0,
          bindings: [
            %{
              id: :field_input,
              source: %{resource: "ExampleState", field: :display_value, id: "state-field"},
              target: "display_name",
              binding_type: :value,
              transform: %{},
              metadata: %{owner: "input", owner_signal: "change"}
            }
          ],
          children: []
        }
      ],
      support_notice:
        "The sibling `field` directory is intentionally authored through the canonical `form_field` widget.",
      notes: "Preserves sibling naming while using the public form_field widget."
    },
    %{
      directory: "field_group",
      section: :form_scaffolding,
      family: :forms,
      title: "Field Group Example",
      subject_type: :"custom:field_group",
      subject_props: %{
        title: "Profile fields",
        description: "A grouped review subject can still compile from native form resources.",
        class: "ashui-example-field-group"
      },
      story_text:
        "Meaningful Interaction Story: edit either grouped field and confirm the example stays explicit that `field_group` is a composed review subject built from nested `form_field` resources.",
      signal_text:
        "Canonical Signal Preview: grouped child inputs change -> ExampleState.display_value and ExampleState.notes while the outer subject remains `custom:field_group`.",
      seed_state: %{
        id: "state-field_group",
        display_value: "Ada Example",
        notes: "Two related fields stay grouped in one review subject.",
        status: "Composed native form structure inside a custom field-group shell."
      },
      preview_field: :notes,
      preview_title: "Grouped note",
      subject_binding: nil,
      subject_action: nil,
      subject_children: [
        %{
          key: :display_name_field,
          type: :form_field,
          props: %{
            name: "display_name",
            label: "Display name",
            help: "Primary grouped field.",
            class: "ashui-example-form-field"
          },
          position: 0,
          children: [
            %{
              key: :display_name_input,
              type: :input,
              props: %{
                name: "display_name",
                type: "text",
                value: "Ada Example",
                placeholder: "Ada Example",
                class: "ashui-example-input"
              },
              position: 0,
              bindings: [
                %{
                  id: :group_display_name_input,
                  source: %{
                    resource: "ExampleState",
                    field: :display_value,
                    id: "state-field_group"
                  },
                  target: "display_name",
                  binding_type: :value,
                  transform: %{},
                  metadata: %{owner: "input", owner_signal: "change"}
                }
              ],
              children: []
            }
          ]
        },
        %{
          key: :notes_field,
          type: :form_field,
          props: %{
            name: "notes",
            label: "Notes",
            help: "Secondary grouped field.",
            class: "ashui-example-form-field"
          },
          position: 10,
          children: [
            %{
              key: :notes_input,
              type: :input,
              props: %{
                name: "notes",
                type: "text",
                value: "Two related fields stay grouped in one review subject.",
                placeholder: "Add a note",
                class: "ashui-example-input"
              },
              position: 0,
              bindings: [
                %{
                  id: :group_notes_input,
                  source: %{resource: "ExampleState", field: :notes, id: "state-field_group"},
                  target: "notes",
                  binding_type: :value,
                  transform: %{},
                  metadata: %{owner: "input", owner_signal: "change"}
                }
              ],
              children: []
            }
          ]
        }
      ],
      support_notice:
        "`field_group` is intentionally implemented as `custom:field_group` plus nested `form_field` resources until a first-class public grouping contract exists.",
      notes: "Uses a composed native screen pattern behind a custom review surface."
    }
  ]

  @input_definitions [
    %{
      directory: "text_input",
      section: :inputs,
      family: :input,
      title: "Text Input Example",
      subject_type: :input,
      subject_props: %{
        name: "headline",
        type: "text",
        value: "Ada Example",
        placeholder: "Type a label",
        class: "ashui-example-input"
      },
      story_text:
        "Meaningful Interaction Story: edit the canonical input control and confirm the preview stat updates through an element-local value binding without bypassing the shared shell.",
      signal_text:
        "Canonical Signal Preview: change -> ExampleState.display_value -> input.value and preview stat.",
      seed_state: %{
        id: "state-text_input",
        display_value: "Ada Example",
        status: "Directory parity preserved through canonical input authoring."
      },
      preview_field: :display_value,
      preview_title: "Current text",
      subject_binding: %{
        id: :text_input_value,
        field: :display_value,
        target: "value",
        transform: %{}
      },
      subject_action: nil,
      subject_children: [],
      support_notice: nil,
      notes: "Preserves the sibling directory name through the canonical input widget."
    },
    %{
      directory: "numeric_input",
      section: :inputs,
      family: :input,
      title: "Numeric Input Example",
      subject_type: :input,
      subject_props: %{
        name: "quantity",
        type: "number",
        value: "42",
        placeholder: "Enter a number",
        class: "ashui-example-input"
      },
      story_text:
        "Meaningful Interaction Story: change the numeric value and confirm the preview stat reflects the stored example-state value without pretending Ash UI is doing hidden coercion.",
      signal_text:
        "Canonical Signal Preview: change -> ExampleState.current_value -> specialized numeric input props and preview stat.",
      seed_state: %{
        id: "state-numeric_input",
        current_value: "42",
        status: "Numeric values stay explicit in the preview stat."
      },
      preview_field: :current_value,
      preview_title: "Current number",
      subject_binding: %{
        id: :numeric_input_value,
        field: :current_value,
        target: "value",
        transform: %{}
      },
      subject_action: nil,
      subject_children: [],
      support_notice:
        "The example keeps numeric values string-backed in example state so any future coercion or validation work stays explicit.",
      notes: "Uses the canonical input widget with numeric props."
    },
    %{
      directory: "date_input",
      section: :inputs,
      family: :input,
      title: "Date Input Example",
      subject_type: :input,
      subject_props: %{
        name: "launch_date",
        type: "date",
        value: "2026-04-24",
        class: "ashui-example-input"
      },
      story_text:
        "Meaningful Interaction Story: choose a date and confirm the preview stat reflects the authored input state inside the shared form-oriented shell.",
      signal_text:
        "Canonical Signal Preview: change -> ExampleState.current_value -> specialized date input props and preview stat.",
      seed_state: %{
        id: "state-date_input",
        current_value: "2026-04-24",
        status: "Date-specific props are authored through canonical input."
      },
      preview_field: :current_value,
      preview_title: "Selected date",
      subject_binding: %{
        id: :date_input_value,
        field: :current_value,
        target: "value",
        transform: %{}
      },
      subject_action: nil,
      subject_children: [],
      support_notice: nil,
      notes: "Uses the canonical input widget with date props."
    },
    %{
      directory: "time_input",
      section: :inputs,
      family: :input,
      title: "Time Input Example",
      subject_type: :input,
      subject_props: %{
        name: "start_time",
        type: "time",
        value: "09:30",
        class: "ashui-example-input"
      },
      story_text:
        "Meaningful Interaction Story: adjust the time control and confirm the preview stat stays in sync through the resource-owned binding path.",
      signal_text:
        "Canonical Signal Preview: change -> ExampleState.current_value -> specialized time input props and preview stat.",
      seed_state: %{
        id: "state-time_input",
        current_value: "09:30",
        status: "Time-specific props are authored through canonical input."
      },
      preview_field: :current_value,
      preview_title: "Selected time",
      subject_binding: %{
        id: :time_input_value,
        field: :current_value,
        target: "value",
        transform: %{}
      },
      subject_action: nil,
      subject_children: [],
      support_notice: nil,
      notes: "Uses the canonical input widget with time props."
    },
    %{
      directory: "file_input",
      section: :inputs,
      family: :input,
      title: "File Input Example",
      subject_type: :input,
      subject_props: %{
        name: "attachment",
        type: "file",
        class: "ashui-example-input"
      },
      story_text:
        "Meaningful Interaction Story: choose a representative filename and confirm the preview stat records the selection while the support note stays explicit that upload transport is not implemented here.",
      signal_text:
        "Canonical Signal Preview: change -> ExampleState.submitted_value -> reviewer-visible selected filename only; no binary upload lifecycle is implied.",
      seed_state: %{
        id: "state-file_input",
        submitted_value: "No file selected",
        status: "File selection is narrowed to filename echo only."
      },
      preview_field: :submitted_value,
      preview_title: "Selected filename",
      subject_binding: %{
        id: :file_input_value,
        field: :submitted_value,
        target: "value",
        transform: %{}
      },
      subject_action: nil,
      subject_children: [],
      support_notice:
        "Upload transport is not implemented in this example suite yet; the file-input example only echoes the selected filename through the resource-authority path.",
      notes: "Uses the canonical input widget with a narrowed file-input contract."
    },
    %{
      directory: "checkbox",
      section: :inputs,
      family: :input,
      title: "Checkbox Example",
      subject_type: :checkbox,
      subject_props: %{
        name: "receive_updates",
        checked: true,
        class: "ashui-example-checkbox"
      },
      story_text:
        "Meaningful Interaction Story: toggle the checkbox and confirm the preview stat tracks the boolean state through an element-local binding.",
      signal_text:
        "Canonical Signal Preview: change -> ExampleState.checked -> checkbox.checked and preview stat.",
      seed_state: %{
        id: "state-checkbox",
        checked: true,
        status: "Checkbox uses the current public widget surface directly."
      },
      preview_field: :checked,
      preview_title: "Checked state",
      subject_binding: %{
        id: :checkbox_value,
        field: :checked,
        target: "checked",
        transform: %{}
      },
      subject_action: nil,
      subject_children: [],
      support_notice: nil,
      notes: "Uses the current public checkbox widget directly."
    },
    %{
      directory: "radio_group",
      section: :inputs,
      family: :input,
      title: "Radio Group Example",
      subject_type: :radio,
      subject_props: %{
        name: "plan",
        value: "pro",
        options: [{"Starter", "starter"}, {"Pro", "pro"}, {"Enterprise", "enterprise"}],
        class: "ashui-example-radio-group"
      },
      story_text:
        "Meaningful Interaction Story: pick a radio option and confirm the normalized `radio` subject preserves the directory story while the preview stat reflects the selected value.",
      signal_text:
        "Canonical Signal Preview: change -> ExampleState.selected_value -> canonical radio-group markup and preview stat.",
      seed_state: %{
        id: "state-radio_group",
        selected_value: "pro",
        status: "Directory parity preserved through canonical radio authoring."
      },
      preview_field: :selected_value,
      preview_title: "Selected plan",
      subject_binding: %{
        id: :radio_group_value,
        field: :selected_value,
        target: "value",
        transform: %{}
      },
      subject_action: nil,
      subject_children: [],
      support_notice:
        "The sibling `radio_group` directory is authored through the canonical `radio` type, with dedicated group markup in the fallback renderer.",
      notes: "Preserves the sibling directory name while using the canonical radio widget."
    },
    %{
      directory: "select",
      section: :inputs,
      family: :input,
      title: "Select Example",
      subject_type: :select,
      subject_props: %{
        name: "theme",
        value: "ember",
        options: [{"Ember", "ember"}, {"Slate", "slate"}, {"Mist", "mist"}],
        class: "ashui-example-select"
      },
      story_text:
        "Meaningful Interaction Story: change the selected option and confirm the preview stat tracks the current selection through the shared example shell.",
      signal_text:
        "Canonical Signal Preview: change -> ExampleState.selected_value -> select.value and preview stat.",
      seed_state: %{
        id: "state-select",
        selected_value: "ember",
        status: "Select uses the current public widget surface directly."
      },
      preview_field: :selected_value,
      preview_title: "Selected option",
      subject_binding: %{
        id: :select_value,
        field: :selected_value,
        target: "value",
        transform: %{}
      },
      subject_action: nil,
      subject_children: [],
      support_notice: nil,
      notes: "Uses the current public select widget directly."
    },
    %{
      directory: "pick_list",
      section: :inputs,
      family: :input,
      title: "Pick List Example",
      subject_type: :"custom:pick_list",
      subject_props: %{
        name: "role",
        value: "ops",
        options: [{"Operations", "ops"}, {"Finance", "finance"}, {"Support", "support"}],
        class: "ashui-example-pick-list"
      },
      story_text:
        "Meaningful Interaction Story: choose one promoted pick-list option and confirm the custom surface stays explicit about the current single-selection runtime boundary.",
      signal_text:
        "Canonical Signal Preview: change -> ExampleState.selected_value -> custom pick-list surface and preview stat.",
      seed_state: %{
        id: "state-pick_list",
        selected_value: "ops",
        status: "Pick-list semantics are currently narrowed to one promoted selection."
      },
      preview_field: :selected_value,
      preview_title: "Promoted pick",
      subject_binding: %{
        id: :pick_list_value,
        field: :selected_value,
        target: "value",
        transform: %{}
      },
      subject_action: nil,
      subject_children: [],
      support_notice:
        "The example uses `custom:pick_list` and currently narrows the runtime to one promoted selection until a first-class multi-pick widget is admitted publicly.",
      notes: "Uses an explicit custom surface until a public pick-list contract exists."
    },
    %{
      directory: "toggle",
      section: :inputs,
      family: :input,
      title: "Toggle Example",
      subject_type: :switch,
      subject_props: %{
        label: "Enable pager alerts",
        checked: false,
        class: "ashui-example-toggle"
      },
      story_text:
        "Meaningful Interaction Story: flip the toggle and confirm the preview stat reflects the normalized `switch` state without claiming a separate public toggle widget.",
      signal_text:
        "Canonical Signal Preview: change -> ExampleState.enabled -> canonical switch state and preview stat.",
      seed_state: %{
        id: "state-toggle",
        enabled: false,
        status: "Directory parity preserved through canonical switch authoring."
      },
      preview_field: :enabled,
      preview_title: "Enabled state",
      subject_binding: %{
        id: :toggle_value,
        field: :enabled,
        target: "checked",
        transform: %{}
      },
      subject_action: nil,
      subject_children: [],
      support_notice:
        "The sibling `toggle` directory is authored through the canonical `switch` widget, and its current state is surfaced through the preview stat rather than a fake device chrome.",
      notes: "Preserves the sibling directory name while using the canonical switch widget."
    }
  ]

  @doc """
  Returns every currently authored Phase 18 definition.
  """
  @spec definitions() :: [definition()]
  def definitions do
    @foundational_definitions ++ @form_scaffolding_definitions ++ @input_definitions
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
