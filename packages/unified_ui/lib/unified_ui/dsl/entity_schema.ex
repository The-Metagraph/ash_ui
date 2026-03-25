defmodule UnifiedUi.Dsl.EntitySchema do
  @moduledoc false

  @common [
    id: [type: :atom, required: true, doc: "Stable authored identifier for the node."],
    description: [type: :string, required: false],
    authored_ref: [type: {:list, :atom}, required: false],
    annotations: [type: :keyword_list, required: false, default: []],
    tags: [type: {:list, :atom}, required: false, default: []],
    variant: [type: :atom, required: false],
    tone: [type: :atom, required: false],
    theme_ref: [type: :atom, required: false],
    style_refs: [type: {:list, :atom}, required: false, default: []],
    style: [type: :any, required: false],
    interaction_refs: [type: {:list, :atom}, required: false, default: []],
    binding_refs: [type: {:list, :atom}, required: false, default: []],
    accessibility_label: [type: :string, required: false],
    accessibility_description: [type: :string, required: false],
    disabled?: [type: :boolean, required: false, default: false]
  ]

  @spec widget(keyword()) :: keyword()
  def widget(extra) do
    merge(@common, extra)
  end

  defp merge(left, right) do
    Keyword.merge(left, right, fn _key, _left, right -> right end)
  end
end
