# frozen_string_literal: true

require "test_helper"

class UI::NativeSelectTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  SECTIONS = [ [ "Grade 8 A", 1 ], [ "Grade 8 B", 2 ] ].freeze

  def test_renders_a_native_select_with_options
    render_inline(UI::NativeSelect.new(name: "enrollment[section_id]", options: SECTIONS))
    assert_selector "select[name='enrollment[section_id]']"
    assert_selector "select option", count: 2
    assert_selector "select option[value='2']", text: "Grade 8 B"
  end

  # Native rather than a custom listbox: it gets the platform picker on a
  # phone, keyboard support and screen-reader behaviour for free.
  def test_accepts_a_plain_array_of_strings
    render_inline(UI::NativeSelect.new(name: "board", options: %w[cbse icse]))
    assert_selector "option[value='cbse']", text: "cbse"
  end

  def test_marks_the_selected_option
    render_inline(UI::NativeSelect.new(name: "s", options: SECTIONS, selected: 2))
    assert_equal "selected", page.find("option[value='2']")[:selected]
    assert_nil page.find("option[value='1']")[:selected]
  end

  # Without a prompt a select silently submits its first option, so a required
  # choice looks already-made.
  def test_prompt_renders_a_blank_first_option
    render_inline(UI::NativeSelect.new(name: "s", options: SECTIONS, prompt: "Choose a section"))
    first = page.all("option").first
    assert_equal "", first[:value]
    assert_equal "Choose a section", first.text
  end

  def test_label_is_associated_with_the_select
    render_inline(UI::NativeSelect.new(name: "s", options: SECTIONS, label: "Section"))
    assert_equal page.find("label")[:for], page.find("select")[:id]
    assert_selector "label", text: "Section"
  end

  def test_no_label_element_without_one
    render_inline(UI::NativeSelect.new(name: "s", options: SECTIONS))
    assert_no_selector "label"
  end

  def test_required_and_disabled_pass_through
    render_inline(UI::NativeSelect.new(name: "s", options: SECTIONS, required: true, disabled: true))
    select = page.find("select", visible: :all)
    assert select[:required].present?
    assert select[:disabled].present?
  end

  def test_error_state_marks_the_select_invalid
    render_inline(UI::NativeSelect.new(name: "s", options: SECTIONS, error: true))
    assert_equal "true", page.find("select")[:"aria-invalid"]
    assert_includes page.find("select")[:class].split, "border-destructive"
  end

  def test_sizes_change_the_control_height
    render_inline(UI::NativeSelect.new(name: "s", options: SECTIONS, size: :sm))
    assert_includes page.find("select")[:class].split, "h-8"
  end

  def test_user_class_overrides_default_via_tailwind_merge
    render_inline(UI::NativeSelect.new(name: "s", options: SECTIONS, class: "h-20"))
    classes = page.find("select")[:class].split
    assert_includes classes, "h-20"
    refute_includes classes, "h-9"
  end

  def test_html_attrs_pass_through
    render_inline(UI::NativeSelect.new(name: "s", options: SECTIONS, id: "sec", data: { test_id: "x" }))
    assert_selector "select#sec[data-test-id='x']"
  end

  # --- form binding ---
  #
  # The label alone is not enough: a bound select must also render a scoped
  # name, or the form submits nothing for the field.

  # A plain object rather than a tenant-scoped model: the component only needs
  # something the form builder can name fields against.
  Enrolment = Struct.new(:section_id) do
    def self.human_attribute_name(name, *) = name.to_s.humanize
    def to_model = self
    def model_name = ActiveModel::Name.new(self.class, nil, "Enrollment")
    def persisted? = false
  end

  def form_builder_for(record = Enrolment.new)
    ActionView::Helpers::FormBuilder.new(:enrollment, record, vc_test_controller.view_context, {})
  end

  def test_form_binding_scopes_the_field_name
    render_inline(UI::NativeSelect.new(form: form_builder_for, field: :section_id,
                                 options: SECTIONS))
    assert_selector "select[name='enrollment[section_id]']"
  end

  def test_form_binding_derives_the_label_and_associates_it
    render_inline(UI::NativeSelect.new(form: form_builder_for, field: :section_id,
                                 options: SECTIONS))
    assert_selector "label"
    assert_equal page.find("label")[:for], page.find("select")[:id]
  end

  def test_form_binding_still_renders_the_prompt_and_selection
    render_inline(UI::NativeSelect.new(form: form_builder_for, field: :section_id,
                                 options: SECTIONS, prompt: "Choose", selected: 2))
    assert_equal "", page.all("option").first[:value]
    assert_equal "selected", page.find("option[value='2']")[:selected]
  end
end
