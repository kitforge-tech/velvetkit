# frozen_string_literal: true

require "test_helper"

class UI::DateRangePickerTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_picker(**options)
    render_inline(UI::DateRangePicker.new(**options))
  end

  def root = page.find("[data-controller='ui--date-range-picker']")
  def hidden(name) = page.find("input[type='hidden'][name='#{name}']", visible: :all)
  def typed(which) = page.find("input[data-ui--date-range-picker-target='#{which}']")
  def presets = page.all("button[data-ui--date-range-picker-target='preset']", visible: :all)

  def test_submits_from_and_to_as_iso_and_types_them_in_the_locale_format
    render_picker(from: Date.new(2026, 11, 1), to: "2026-11-30")
    assert_equal "2026-11-01", hidden("from").value
    assert_equal "2026-11-30", hidden("to").value
    assert_equal "01/11/2026", typed(:from).value
    assert_equal "30/11/2026", typed(:to).value
  end

  def test_only_the_hidden_fields_are_named
    render_picker
    assert_nil typed(:from)[:name]
    assert_nil typed(:to)[:name]
  end

  def test_names_can_be_changed
    render_picker(from_name: "period[start]", to_name: "period[end]")
    assert hidden("period[start]")
    assert hidden("period[end]")
  end

  Report = Struct.new(:starts_on, :ends_on) do
    def to_model = self
    def model_name = ActiveModel::Name.new(self.class, nil, "Report")
    def persisted? = false
  end

  def test_form_builder_names_both_fields_and_reads_them
    builder = ActionView::Helpers::FormBuilder.new(:report, Report.new(Date.new(2026, 4, 1), Date.new(2027, 3, 31)),
                                                   vc_test_controller.view_context, {})
    render_picker(form: builder, from_field: :starts_on, to_field: :ends_on)
    assert_equal "2026-04-01", hidden("report[starts_on]").value
    assert_equal "2027-03-31", hidden("report[ends_on]").value
  end

  def test_typed_fields_are_named_for_screen_readers_and_carry_the_placeholder
    render_picker(label: "Period")
    assert_selector "label[for='#{typed(:from)[:id]}']", text: "Period"
    assert_equal "Start date", typed(:from)["aria-label"]
    assert_equal "End date", typed(:to)["aria-label"]
    assert_equal "DD/MM/YYYY", typed(:from)[:placeholder]
  end

  def test_the_order_and_separator_come_from_the_locale_format
    render_picker
    assert_equal "DMY", root["data-ui--date-range-picker-order-value"]
    assert_equal "/", root["data-ui--date-range-picker-separator-value"]
    assert_match(/cally.*\.js\z/, root["data-ui--date-range-picker-module-url-value"])
  end

  def test_presets_are_worked_out_from_todays_date
    travel_to(Date.new(2026, 11, 6)) do
      render_picker
      by_label = presets.to_h { |b| [ b.text, [ b["data-ui--date-range-picker-from-param"], b["data-ui--date-range-picker-to-param"] ] ] }
      assert_equal %w[2026-11-06 2026-11-06], by_label["Today"]
      assert_equal %w[2026-10-31 2026-11-06], by_label["Last 7 days"]
      assert_equal %w[2026-11-01 2026-11-06], by_label["This month"]
      assert_equal %w[2026-10-01 2026-10-31], by_label["Last month"]
      assert_equal %w[2026-01-01 2026-11-06], by_label["This year"]
    end
  end

  def test_the_preset_matching_the_range_is_pressed
    travel_to(Date.new(2026, 11, 6)) do
      render_picker(from: "2026-11-01", to: "2026-11-06")
      pressed = presets.select { _1["aria-pressed"] == "true" }.map(&:text)
      assert_equal [ "This month" ], pressed
    end
  end

  def test_presets_can_be_replaced_or_left_out
    render_picker(presets: [ [ "Q1", "2026-01-01", "2026-03-31" ] ])
    assert_equal [ "Q1" ], presets.map(&:text)
    render_picker(presets: false)
    assert_empty presets
  end

  def test_the_calendar_is_a_two_month_range_that_starts_hidden
    render_picker(min: Date.new(2026, 1, 1), max: "2026-12-31")
    assert_selector "[role='dialog'][hidden] calendar-range[months='2'][min='2026-01-01'][max='2026-12-31']", visible: :all
    assert_selector "calendar-range calendar-month[offset='1'][data-ui--date-range-picker-target='secondMonth']", visible: :all
    assert_selector "button[aria-haspopup='dialog'][aria-expanded='false'][aria-label='Open the calendar']"
  end

  def test_hint_explains_the_format_and_can_be_turned_off
    render_picker
    assert_text "Type the dates as DD/MM/YYYY"
    render_picker(hint: false)
    assert_no_text "Type the dates as"
  end

  def test_error_and_required_and_disabled
    render_picker(label: "Period", error: "Too long", required: true, disabled: true)
    assert_text "Too long"
    assert_equal "true", typed(:from)["aria-invalid"]
    assert typed(:to)[:required]
    assert typed(:from)[:disabled]
    assert_selector "label span", text: "*"
  end

  def test_class_and_attributes_pass_through
    render_picker(class: "w-80", id: "period", data: { foo: "bar" })
    assert_selector "#period.w-80[data-foo='bar'][data-controller='ui--date-range-picker']"
  end
end
