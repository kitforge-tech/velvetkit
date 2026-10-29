# frozen_string_literal: true

require "test_helper"

class UI::SelectTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  TEAMS = [ [ "Design", 1 ], [ "Engineering", 2 ], [ "Marketing", 3 ] ].freeze

  Member = Struct.new(:team_id) do
    def to_model = self
    def model_name = ActiveModel::Name.new(self.class, nil, "Member")
    def persisted? = false
  end

  def form_builder_for(record = Member.new)
    ActionView::Helpers::FormBuilder.new(:member, record, vc_test_controller.view_context, {})
  end

  def trigger = page.find("button[role='combobox']")
  def listbox = page.find("[role='listbox']", visible: :all)
  def native = page.find("select", visible: :all)

  # --- the visible control (WAI-ARIA select-only combobox) ---------------

  def test_trigger_is_a_collapsed_combobox_controlling_the_listbox
    render_inline(UI::Select.new(name: "section", options: TEAMS))
    assert_equal "button", trigger[:type]
    assert_equal "listbox", trigger["aria-haspopup"]
    assert_equal "false", trigger["aria-expanded"]
    assert_equal listbox[:id], trigger["aria-controls"]
    assert page.find("[data-ui--select-target='panel']", visible: :all)[:hidden], "the panel starts closed"
  end

  def test_each_option_is_an_aria_option_carrying_its_value
    render_inline(UI::Select.new(name: "section", options: TEAMS))
    options = page.all("[role='option']", visible: :all)
    assert_equal [ "1", "2", "3" ], options.map { _1["data-value"] }
    assert_equal [ "Design", "Engineering", "Marketing" ], options.map { _1.text(:all).strip }
  end

  def test_selected_option_is_marked_and_shown_on_the_trigger
    render_inline(UI::Select.new(name: "section", options: TEAMS, selected: 2))
    assert_equal "true", page.find("[role='option'][data-value='2']", visible: :all)["aria-selected"]
    assert_equal "false", page.find("[role='option'][data-value='1']", visible: :all)["aria-selected"]
    assert_includes trigger.text, "Engineering"
  end

  def test_prompt_shows_when_nothing_is_selected_and_clears_the_value
    render_inline(UI::Select.new(name: "section", options: TEAMS, prompt: "Choose a team"))
    assert_includes trigger.text, "Choose a team"
    assert_selector "[role='option'][data-value='']", text: "Choose a team", visible: :all
  end

  def test_without_a_prompt_the_first_option_shows_as_a_native_select_would
    render_inline(UI::Select.new(name: "section", options: TEAMS))
    assert_includes trigger.text, "Design"
  end

  def test_plain_values_are_their_own_labels
    render_inline(UI::Select.new(name: "role", options: %w[Admin Editor], selected: "Editor"))
    assert_includes trigger.text, "Editor"
    assert_selector "[role='option'][data-value='Admin']", visible: :all
  end

  # --- the value, carried by a hidden native select ------------------------

  def test_a_hidden_native_select_carries_the_name_value_and_options
    render_inline(UI::Select.new(name: "section", options: TEAMS, selected: 3))
    assert_equal "section", native[:name]
    assert_equal "-1", native[:tabindex]
    assert_equal "true", native["aria-hidden"]
    assert_includes native[:class], "sr-only"
    assert_selector "select option[value='3'][selected]", visible: :all
  end

  def test_required_and_disabled_reach_the_native_select_and_the_trigger
    render_inline(UI::Select.new(name: "section", options: TEAMS, required: true, disabled: true))
    assert native[:required]
    assert native[:disabled]
    assert trigger[:disabled]
  end

  def test_extra_attributes_stay_on_the_native_select_so_change_listeners_keep_working
    render_inline(UI::Select.new(name: "section", options: TEAMS, id: "section-picker", data: { action: "change->filters#apply" }))
    assert_equal "section-picker", native[:id]
    assert_equal "change->filters#apply", native["data-action"]
  end

  # --- label, states, sizes ---------------------------------------------

  def test_label_is_associated_with_the_trigger
    render_inline(UI::Select.new(name: "section", options: TEAMS, label: "Team"))
    assert_equal trigger[:id], page.find("label")[:for]
  end

  def test_error_marks_the_trigger_invalid
    render_inline(UI::Select.new(name: "section", options: TEAMS, error: true))
    assert_equal "true", trigger["aria-invalid"]
    assert_includes trigger[:class], "border-destructive"
  end

  def test_sizes
    { sm: "h-8", default: "h-9", lg: "h-10" }.each do |size, height|
      render_inline(UI::Select.new(name: "s", options: TEAMS, size: size))
      assert_includes trigger[:class].split, height
    end
  end

  def test_user_class_goes_on_the_trigger
    render_inline(UI::Select.new(name: "s", options: TEAMS, class: "w-48"))
    assert_includes trigger[:class].split, "w-48"
  end

  def test_wires_the_stimulus_controller
    render_inline(UI::Select.new(name: "s", options: TEAMS))
    assert_selector "[data-controller='ui--select']"
    assert_equal "trigger", trigger["data-ui--select-target"]
    assert_equal "listbox", listbox["data-ui--select-target"]
    assert_equal "native", native["data-ui--select-target"]
  end

  # --- form builder --------------------------------------------------------

  def test_form_binding_scopes_the_name_and_reads_the_value
    render_inline(UI::Select.new(form: form_builder_for(Member.new(2)), field: :team_id, options: TEAMS))
    assert_equal "member[team_id]", native[:name]
    assert_includes trigger.text, "Engineering"
    assert_equal "true", page.find("[role='option'][data-value='2']", visible: :all)["aria-selected"]
  end

  def test_form_binding_derives_the_label
    render_inline(UI::Select.new(form: form_builder_for, field: :team_id, options: TEAMS))
    assert_selector "label", text: "Team"
  end
  # --- searchable ------------------------------------------------------------

  def test_searchable_adds_a_search_box_that_controls_the_listbox
    render_inline(UI::Select.new(name: "s", options: TEAMS, searchable: true))
    search = page.find("input[type='search']", visible: :all)
    assert_equal "search", search["data-ui--select-target"]
    assert_equal listbox[:id], search["aria-controls"]
    assert_equal "Search", search[:placeholder]
    assert_selector "[data-ui--select-target='empty']", text: "No matches", visible: :all
  end

  def test_not_searchable_by_default
    render_inline(UI::Select.new(name: "s", options: TEAMS))
    assert_no_selector "input[type='search']", visible: :all
  end

  # --- multiple --------------------------------------------------------------

  def test_multiple_marks_every_chosen_option_and_posts_an_array
    render_inline(UI::Select.new(name: "tags", options: TEAMS, multiple: true, selected: [ 1, 3 ]))
    assert_equal "true", listbox["aria-multiselectable"]
    assert native[:multiple]
    assert_equal "tags[]", native[:name]
    assert_equal %w[true false true], page.all("[role='option']", visible: :all).map { _1["aria-selected"] }
    assert_includes trigger.text, "Design, Marketing"
  end

  def test_multiple_summarises_more_than_two_choices
    render_inline(UI::Select.new(name: "tags", options: TEAMS, multiple: true, selected: [ 1, 2, 3 ]))
    assert_includes trigger.text, "3 selected"
  end

  def test_multiple_with_nothing_chosen_shows_the_prompt_and_offers_no_blank_option
    render_inline(UI::Select.new(name: "tags", options: TEAMS, multiple: true, prompt: "Pick sections"))
    assert_includes trigger.text, "Pick sections"
    assert_no_selector "[role='option'][data-value='']", visible: :all
  end

  def test_multiple_hands_the_summary_wording_to_the_controller
    render_inline(UI::Select.new(name: "tags", options: TEAMS, multiple: true))
    root = page.find("[data-controller='ui--select']")
    assert_equal "true", root["data-ui--select-multiple-value"]
    assert_equal "%{count} selected", root["data-ui--select-summary-value"]
  end

  def test_hint_and_error_describe_the_trigger
    render_inline(UI::Select.new(options: %w[Free Pro], label: "Plan", hint: "Billed monthly", error: "Choose a plan"))
    trigger = page.find("button[role='combobox'][aria-invalid='true']")
    assert_equal "#{trigger[:id]}-hint #{trigger[:id]}-error", trigger["aria-describedby"]
    assert_selector "p##{trigger[:id]}-hint", text: "Billed monthly"
    assert_selector "p##{trigger[:id]}-error.text-destructive", text: "Choose a plan"
  end

  def test_no_messages_no_describedby
    render_inline(UI::Select.new(options: %w[Free Pro]))
    refute_selector "button[aria-describedby]"
    refute_selector "p.text-destructive"
  end
end
