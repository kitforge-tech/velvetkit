# frozen_string_literal: true

require "test_helper"

class UI::DatePickerTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_picker(**options)
    render_inline(UI::DatePicker.new(**options))
  end

  def root = page.find("div[data-controller='ui--date-picker']")
  def typed = page.all("input[data-ui--date-picker-target='field']")
  def hidden(name) = page.find("input[type='hidden'][name='#{name}']", visible: :all)
  def presets = page.all("button[data-ui--date-picker-target='preset']", visible: :all)

  def with_format(format)
    original = I18n.backend.translate(:en, "date.formats.typed")
    I18n.backend.store_translations(:en, date: { formats: { typed: format } })
    yield
  ensure
    I18n.backend.store_translations(:en, date: { formats: { typed: original } })
  end

  # ── A single date ─────────────────────────────────────────────────────────

  def test_only_the_hidden_field_is_submitted
    render_picker(name: "event[date]", value: Date.new(2026, 8, 15))
    assert_equal "2026-08-15", hidden("event[date]").value
    assert_nil typed.first[:name]
  end

  def test_the_typed_field_shows_the_locale_format
    render_picker(name: "d", value: "2026-08-15")
    assert_equal "15/08/2026", typed.first.value
    assert_equal "DD/MM/YYYY", typed.first[:placeholder]
    assert_equal "10", typed.first[:maxlength]
    assert_equal "numeric", typed.first[:inputmode]
  end

  def test_both_fields_are_empty_without_a_value
    render_picker(name: "d")
    assert_equal "", typed.first.value.to_s
    assert_equal "", hidden("d").value.to_s
  end

  def test_the_field_opens_the_calendar_on_focus_and_click
    render_picker(name: "d")
    action = typed.first["data-action"]
    assert_includes action, "focus->ui--date-picker#open"
    assert_includes action, "click->ui--date-picker#open"
    assert_includes action, "input->ui--date-picker#typed"
  end

  def test_order_and_separator_come_from_the_locale_format
    render_picker(name: "d")
    assert_equal "DMY", root["data-ui--date-picker-order-value"]
    assert_equal "/", root["data-ui--date-picker-separator-value"]
  end

  def test_a_different_locale_format_changes_the_placeholder_and_the_parser
    with_format("%m-%d-%Y") do
      render_picker(name: "d", value: "2026-08-15")
      assert_equal "MM-DD-YYYY", typed.first[:placeholder]
      assert_equal "08-15-2026", typed.first.value
      assert_equal "MDY", root["data-ui--date-picker-order-value"]
      assert_equal "-", root["data-ui--date-picker-separator-value"]
    end
  end

  def test_the_calendar_loads_with_its_stylesheet_and_starts_hidden
    render_picker(name: "d", min: Date.new(2026, 1, 1), max: "2026-12-31")
    assert_match(/vanilla_calendar.*\.js\z/, root["data-ui--date-picker-module-url-value"])
    assert_match(/vanilla_calendar.*\.css\z/, root["data-ui--date-picker-style-url-value"])
    assert_equal "2026-01-01", root["data-ui--date-picker-min-value"]
    assert_equal "2026-12-31", root["data-ui--date-picker-max-value"]
    assert_selector "[role='dialog'][hidden] .velvetkit-calendar > [data-ui--date-picker-target='calendar']", visible: :all
    assert_selector "button[aria-haspopup='dialog'][aria-expanded='false'][aria-label='Open the calendar']"
  end

  def test_a_single_date_has_no_presets_or_range_prompt
    render_picker(name: "d")
    assert_empty presets
    assert_no_selector "[data-ui--date-picker-target='status']", visible: :all
    assert_equal "false", root["data-ui--date-picker-range-value"]
  end

  def test_clear_shows_only_with_a_value_that_can_be_emptied
    render_picker(name: "d")
    assert_selector "button[aria-label='Clear'][hidden]", visible: :all
    render_picker(name: "d", value: "2026-08-15")
    assert_selector "button[aria-label='Clear']:not([hidden])"
    render_picker(name: "d", value: "2026-08-15", required: true)
    assert_selector "button[aria-label='Clear'][hidden]", visible: :all
  end

  Holiday = Struct.new(:starts_on) do
    def self.human_attribute_name(name, *) = name.to_s.humanize
    def to_model = self
    def model_name = ActiveModel::Name.new(self.class, nil, "Holiday")
    def persisted? = false
  end

  def builder(record) = ActionView::Helpers::FormBuilder.new(:holiday, record, vc_test_controller.view_context, {})

  def test_form_binding_names_the_hidden_field_reads_the_value_and_derives_the_label
    render_picker(form: builder(Holiday.new(Date.new(2026, 8, 15))), field: :starts_on)
    assert_equal "2026-08-15", hidden("holiday[starts_on]").value
    assert_selector "label[for='#{typed.first[:id]}']", text: "Starts on"
  end

  def test_required_marks_the_field_and_the_label
    render_picker(name: "d", label: "Date", required: true)
    assert typed.first[:required]
    assert_selector "label span", text: "*"
  end

  def test_the_hint_explains_the_format_and_can_be_turned_off
    render_picker(name: "d")
    assert_text "Type the date as DD/MM/YYYY"
    assert_includes typed.first["aria-describedby"], "-hint"
    render_picker(name: "d", hint: false)
    assert_no_text "Type the date as"
  end

  def test_error_message_shows_and_describes_the_field
    render_picker(name: "d", error: "Too early")
    assert_text "Too early"
    assert_equal "true", typed.first["aria-invalid"]
    assert_includes typed.first["aria-describedby"], page.find("p", text: "Too early")[:id]
  end

  # ── A range ───────────────────────────────────────────────────────────────

  def test_a_range_submits_from_and_to_as_iso
    render_picker(range: true, from: Date.new(2026, 11, 1), to: "2026-11-30")
    assert_equal "2026-11-01", hidden("from").value
    assert_equal "2026-11-30", hidden("to").value
    assert_equal %w[01/11/2026 30/11/2026], typed.map(&:value)
    assert_equal [ "Start date", "End date" ], typed.map { _1["aria-label"] }
    assert_equal "true", root["data-ui--date-picker-range-value"]
  end

  def test_a_range_can_rename_its_fields
    render_picker(range: true, from_name: "period[start]", to_name: "period[end]")
    assert hidden("period[start]")
    assert hidden("period[end]")
  end

  Report = Struct.new(:starts_on, :ends_on) do
    def to_model = self
    def model_name = ActiveModel::Name.new(self.class, nil, "Report")
    def persisted? = false
  end

  def test_a_range_binds_to_a_form
    form = ActionView::Helpers::FormBuilder.new(:report, Report.new(Date.new(2026, 4, 1), Date.new(2027, 3, 31)), vc_test_controller.view_context, {})
    render_picker(range: true, form: form, from_field: :starts_on, to_field: :ends_on)
    assert_equal "2026-04-01", hidden("report[starts_on]").value
    assert_equal "2027-03-31", hidden("report[ends_on]").value
  end

  def test_a_range_says_to_pick_an_end_date_after_the_first
    render_picker(range: true)
    assert_selector "[data-ui--date-picker-target='status'][role='status']", visible: :all
    assert_includes JSON.parse(root["data-ui--date-picker-labels-value"])["pickEnd"], "end date"
  end

  def test_range_presets_are_worked_out_from_today
    travel_to(Date.new(2026, 11, 6)) do
      render_picker(range: true)
      by_label = presets.to_h { |b| [ b.text, [ b["data-ui--date-picker-from-param"], b["data-ui--date-picker-to-param"] ] ] }
      assert_equal %w[2026-11-06 2026-11-06], by_label["Today"]
      assert_equal %w[2026-10-31 2026-11-06], by_label["Last 7 days"]
      assert_equal %w[2026-11-01 2026-11-06], by_label["This month"]
      assert_equal %w[2026-10-01 2026-10-31], by_label["Last month"]
      assert_equal %w[2026-01-01 2026-11-06], by_label["This year"]
    end
  end

  def test_the_preset_matching_the_range_is_pressed
    travel_to(Date.new(2026, 11, 6)) do
      render_picker(range: true, from: "2026-11-01", to: "2026-11-06")
      assert_equal [ "This month" ], presets.select { _1["aria-pressed"] == "true" }.map(&:text)
    end
  end

  def test_range_presets_can_be_replaced_or_left_out
    render_picker(range: true, presets: [ [ "Q1", "2026-01-01", "2026-03-31" ] ])
    assert_equal [ "Q1" ], presets.map(&:text)
    render_picker(range: true, presets: false)
    assert_empty presets
  end

  def test_class_and_attributes_pass_through
    render_picker(name: "d", class: "max-w-xs", id: "when", data: { foo: "bar" })
    assert_selector "#when.max-w-xs[data-foo='bar'][data-controller='ui--date-picker']"
  end
end
