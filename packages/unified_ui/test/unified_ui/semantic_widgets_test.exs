defmodule UnifiedUi.SemanticWidgetsTest do
  use ExUnit.Case, async: true

  alias Spark.Dsl.Extension
  alias UnifiedUi.Compiler

  defmodule SemanticDashboard do
    use UnifiedUi.Dsl

    identity do
      id(:semantic_dashboard)
      authored_ref([:examples, :semantic_dashboard])
    end

    composition do
      root(:semantic_dashboard_root)
      mode(:screen)

      hero :launch_hero do
        eyebrow("UnifiedUi")
        title("Semantic dashboards")
        message("Compose richer authored surfaces with semantic widgets.")
        summary("Semantic launch hero")

        badge :runtime_badge do
          value("Live")
          name(:sparkles)
          set(:system)
        end

        button :launch_action do
          label("Open dashboard")
        end
      end

      stat :coverage_stat do
        title("Coverage")
        value("82%")
        message("semantic surface parity")
      end

      key_value :owner_pair do
        label("Owner")
        value("Platform UI")
        description("Maintaining the semantic widget rollout")
      end

      info_list :rollout_notes do
        ordered?(true)
        empty_state("No rollout notes")

        items([
          [
            id: :badge,
            title: "Badge",
            value: "Ready",
            description: "Foundational semantic display"
          ],
          [
            id: :form_field,
            title: "Form field",
            value: "Ready",
            description: "Forms semantic composite",
            status: :active
          ]
        ])
      end

      form_builder :settings_form do
        form_field :dashboard_name do
          field_name(:dashboard_name)
          label("Dashboard name")
          help("Used in admin and docs views")

          text_input :dashboard_name_input do
            placeholder("Semantic workspace")
          end
        end
      end
    end
  end

  test "stores semantic widgets and form_field constructs in the authored composition tree" do
    [hero, stat, key_value, info_list, form] =
      Extension.get_entities(SemanticDashboard, [:composition])

    assert {hero.family, hero.kind} == {:foundational, :hero}
    assert Enum.map(hero.children, & &1.kind) == [:badge, :button]
    assert {stat.family, stat.kind} == {:data, :stat}
    assert {key_value.family, key_value.kind} == {:data, :key_value}
    assert {info_list.family, info_list.kind} == {:data, :info_list}
    assert {form.family, form.kind} == {:forms, :form_builder}
    assert Enum.map(form.children, & &1.kind) == [:form_field]
  end

  test "summarizes semantic authored widgets without a renderer runtime" do
    assert UnifiedUi.Info.composition_summary(SemanticDashboard) == [
             %{
               id: :launch_hero,
               family: :foundational,
               kind: :hero,
               eyebrow: "UnifiedUi",
               title: "Semantic dashboards",
               message: "Compose richer authored surfaces with semantic widgets.",
               summary: "Semantic launch hero",
               children: [
                 %{
                   id: :runtime_badge,
                   family: :foundational,
                   kind: :badge,
                   value: "Live",
                   presentation: :pill
                 },
                 %{
                   id: :launch_action,
                   family: :foundational,
                   kind: :button,
                   label: "Open dashboard"
                 }
               ]
             },
             %{
               id: :coverage_stat,
               family: :data,
               kind: :stat,
               title: "Coverage",
               value: "82%",
               message: "semantic surface parity"
             },
             %{
               id: :owner_pair,
               family: :data,
               kind: :key_value,
               label: "Owner",
               value: "Platform UI"
             },
             %{
               id: :rollout_notes,
               family: :data,
               kind: :info_list,
               items: [
                 [
                   id: :badge,
                   title: "Badge",
                   value: "Ready",
                   description: "Foundational semantic display"
                 ],
                 [
                   id: :form_field,
                   title: "Form field",
                   value: "Ready",
                   description: "Forms semantic composite",
                   status: :active
                 ]
               ],
               ordered?: true,
               empty_state: "No rollout notes"
             },
             %{
               id: :settings_form,
               family: :forms,
               kind: :form_builder,
               children: [
                 %{
                   id: :dashboard_name,
                   family: :forms,
                   kind: :form_field,
                   label: "Dashboard name",
                   children: [
                     %{id: :dashboard_name_input, family: :input, kind: :text_input}
                   ]
                 }
               ]
             }
           ]
  end

  test "compiler lowers semantic widgets into canonical IUR constructs" do
    {:ok, result} = Compiler.compile(SemanticDashboard)

    [hero_child, stat_child, key_value_child, info_list_child, form_child] = result.iur.children

    assert hero_child.element.kind == :hero
    assert get_in(hero_child.element.attributes, [:hero, :eyebrow]) == "UnifiedUi"
    assert Enum.map(hero_child.element.children, & &1.element.kind) == [:badge, :button]

    assert stat_child.element.kind == :stat
    assert get_in(stat_child.element.attributes, [:stat, :title]) == "Coverage"
    assert get_in(stat_child.element.attributes, [:stat, :value]) == "82%"

    assert key_value_child.element.kind == :key_value
    assert get_in(key_value_child.element.attributes, [:key_value, :label]) == "Owner"
    assert get_in(key_value_child.element.attributes, [:key_value, :value]) == "Platform UI"

    assert info_list_child.element.kind == :info_list
    assert get_in(info_list_child.element.attributes, [:info_list, :ordered?]) == true
    assert length(get_in(info_list_child.element.attributes, [:info_list, :items])) == 2

    form_field =
      form_child.element.children
      |> List.first()
      |> Map.fetch!(:element)

    assert form_field.kind == :form_field
    assert get_in(form_field.attributes, [:field, :control_id]) == :dashboard_name_input
  end
end
