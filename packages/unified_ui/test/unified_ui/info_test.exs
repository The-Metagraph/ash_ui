defmodule UnifiedUi.InfoTest do
  use ExUnit.Case, async: true

  defmodule SummaryScreen do
    use UnifiedUi.Dsl

    identity do
      id(:summary_screen)
      title("Summary Screen")
      description("Screen used for package introspection tests")
      authored_ref([:examples, :summary_screen])
      tags([:reference])
    end

    composition do
      root(:summary_root)
      mode(:screen)
      summary("Summary shell")
    end

    themes do
      default_theme(:workspace)
      inherit?(false)

      theme do
        id(:workspace)

        palette_color do
          id(:surface)
          color(named_color(:black))
        end
      end
    end

    signals do
      namespace(:workspace)
      default_target(:session)
    end
  end

  test "summarizes authored modules without requiring runtime libraries" do
    assert UnifiedUi.Info.module_summary(SummaryScreen) == %{
             module: SummaryScreen,
             sections: %{
               identity: true,
               composition: true,
               themes: true,
               signals: true
             },
             identifiers: %{
               module_id: :summary_screen,
               root_id: :summary_root,
               default_theme: :workspace,
               signal_namespace: :workspace
             },
             identity: %{
               id: :summary_screen,
               title: "Summary Screen",
               description: "Screen used for package introspection tests",
               authored_ref: [:examples, :summary_screen],
               annotations: [],
               tags: [:reference]
             },
             composition: %{
               root: :summary_root,
               mode: :screen,
               summary: "Summary shell"
             },
             themes: %{
               default_theme: :workspace,
               inherit?: false
             },
             signals: %{
               namespace: :workspace,
               default_target: :session,
               mode: :canonical
             },
             theme_catalog: %{
               default_theme: :workspace,
               inherit?: false,
               summary: nil,
               themes: [
                 %{
                   id: :workspace,
                   inherit?: true,
                   palette_colors: [%{id: :surface, color: %{mode: :named, name: :black}}]
                 }
               ]
             },
             signal_catalog: %{
               namespace: :workspace,
               default_target: :session,
               mode: :canonical,
               families: [
                 :click,
                 :change,
                 :submit,
                 :open,
                 :close,
                 :focus,
                 :selection,
                 :navigation,
                 :command
               ],
               bindings: [],
               interactions: [],
               navigation_descriptors: []
             },
             validation_state: :phase_1_valid
           }
  end

  test "exposes section usage and supported construct families" do
    assert UnifiedUi.Info.section_usage(SummaryScreen) == %{
             identity: true,
             composition: true,
             themes: true,
             signals: true
           }

    assert UnifiedUi.Info.supported_construct_families() ==
             UnifiedUi.Reference.construct_families()

    assert UnifiedUi.Info.inspect_module(SummaryScreen) ==
             UnifiedUi.Info.module_summary(SummaryScreen)
  end
end
