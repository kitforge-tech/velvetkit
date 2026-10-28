# frozen_string_literal: true

require "test_helper"

class UI::DatePickerTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_picker(**options)
    render_inline(UI::DatePicker.new(**{ name: "holiday[date]" }.merge(options)))
  end

  def typed = page.find("input[type='text']")
  def hidden = page.find("input[type='hidden']", visible: :all)
  def root = page.find("div[data-controller='ui--date-picker']")

  # --- the two fields ------------------------------------------------------

  # The typed field carries no name, so a half-typed date can never reach the
  # server: only the hidden ISO field is submitted.
  def test_only_the_hidden_field_is_submitted
    render_picker
    assert_nil typed[:name]
    assert_equal "holiday[date]", hidden[:name]
  end

  def test_the_typed_field_shows_the_locale_format_and_the_hidden_one_iso
    render_picker(value: Date.new(2012, 5, 2))
    assert_equal "02/05/2012", typed[:value]
    assert_equal "2012-05-02", hidden[:value]
  end

  def test_both_fields_are_empty_without_a_value
    render_picker
    assert_equal "", typed[:value].to_s
    assert_equal "", hidden[:value].to_s
  end

  # --- the format is not hardcoded ----------------------------------------
  #
  # date.formats.typed is the authority: the placeholder, the parse order and
  # the separator are all derived from it, so they cannot drift apart.

  def test_the_placeholder_is_derived_from_the_locale_format
    render_picker
    assert_equal "DD/MM/YYYY", typed[:placeholder]
  end

  def test_the_parse_order_and_separator_are_derived_from_the_locale_format
    render_picker
    assert_equal "DMY", root["data-ui--date-picker-order-value"]
    assert_equal "/", root["data-ui--date-picker-separator-value"]
  end

  # A locale that writes dates the other way round changes all three together
  # and needs no change here.
  def test_a_different_locale_format_changes_the_placeholder_and_the_parser
    with_format("%m-%d-%Y") do
      render_picker(value: Date.new(2012, 5, 2))
      assert_equal "MM-DD-YYYY", typed[:placeholder]
      assert_equal "MDY", root["data-ui--date-picker-order-value"]
      assert_equal "-", root["data-ui--date-picker-separator-value"]
      assert_equal "05-02-2012", typed[:value]
    end
  end

  def with_format(format)
    original = I18n.backend.translate(:en, "date.formats.typed")
    I18n.backend.store_translations(:en, date: { formats: { typed: format } })
    yield
  ensure
    I18n.backend.store_translations(:en, date: { formats: { typed: original } })
  end

  # --- form binding --------------------------------------------------------

  Holiday = Struct.new(:date) do
    def self.human_attribute_name(name, *) = name.to_s.humanize
    def to_model = self
    def model_name = ActiveModel::Name.new(self.class, nil, "Holiday")
    def persisted? = false
  end

  def form_for(record = Holiday.new(Date.new(2026, 8, 15)))
    ActionView::Helpers::FormBuilder.new(:holiday, record, vc_test_controller.view_context, {})
  end

  def test_form_binding_names_the_hidden_field_and_reads_the_value
    render_inline(UI::DatePicker.new(form: form_for, field: :date))
    assert_equal "holiday[date]", hidden[:name]
    assert_equal "2026-08-15", hidden[:value]
    assert_equal "15/08/2026", typed[:value]
  end

  def test_form_binding_derives_the_label
    render_inline(UI::DatePicker.new(form: form_for, field: :date))
    assert_selector "label", text: "Date"
    assert_equal page.find("label")[:for], typed[:id]
  end

  # --- state ---------------------------------------------------------------

  def test_required_marks_the_typed_field
    render_picker(required: true)
    assert_selector "input[type='text'][required]"
  end

  def test_required_marks_the_label_with_an_asterisk
    render_picker(required: true, label: "Date of birth")
    assert_selector "label span.text-destructive", text: "*"
  end

  def test_min_and_max_reach_the_calendar
    render_picker(min: "2026-04-01", max: "2027-03-31")
    calendar = page.find("calendar-date", visible: :all)
    assert_equal "2026-04-01", calendar[:min]
    assert_equal "2027-03-31", calendar[:max]
  end

  # The calendar chunk is only fetched when the button is pressed, so a form
  # nobody opens a calendar on downloads nothing.
  def test_the_calendar_panel_starts_hidden_and_carries_the_module_url
    render_picker
    assert_selector "div[role='dialog'][hidden]", visible: :all
    assert_match(/cally/, root["data-ui--date-picker-module-url-value"])
  end

  # The hint teaches the format on a data-entry form; in a filter toolbar the
  # value is already on screen and three wrapped lines of hint per field push
  # the page heading down.
  def test_the_hint_can_be_turned_off
    render_picker
    assert_selector "p", text: "DD/MM/YYYY"
    assert_equal "#{typed[:id]}-hint", typed["aria-describedby"]

    render_picker(hint: false)
    assert_no_selector "p"
    assert_nil typed["aria-describedby"]
  end

  def test_the_toggle_is_labelled_and_marked_closed
    render_picker
    button = page.find("button[aria-haspopup='dialog']")
    assert_equal "false", button["aria-expanded"]
    assert_equal I18n.t("ui.date_picker.open"), button["aria-label"]
  end

  # --- the calendar header ---------------------------------------------------

  # Month and year sit in Cally's heading slot, between the arrows, rather
  # than under a second, duplicate heading.
  def test_month_and_year_selects_fill_the_calendar_heading
    render_picker
    heading = page.find("calendar-date [slot='heading']", visible: :all)
    assert heading.has_css?("calendar-select-month", visible: :all)
    assert heading.has_css?("calendar-select-year", visible: :all)
  end

  # Cally wraps the arrows in its own buttons, so ours must not be buttons.
  def test_arrows_are_labelled_icons_not_nested_buttons
    render_picker
    [ [ "previous", "ui.date_picker.previous" ], [ "next", "ui.date_picker.next" ] ].each do |slot, key|
      arrow = page.find("calendar-date [slot='#{slot}']", visible: :all)
      refute_equal "button", arrow.tag_name
      assert_includes arrow.text(:all), I18n.t(key)
    end
  end

  def test_error_message_shows_under_the_hint_and_describes_the_input
    render_inline(UI::DatePicker.new(name: "starts_on", label: "Start date", error: "Pick a date in the future"))
    input = page.find("input[type='text'][aria-invalid='true']")
    assert_equal "#{input[:id]}-hint #{input[:id]}-error", input["aria-describedby"]
    assert_selector "p##{input[:id]}-error.text-destructive", text: "Pick a date in the future"
  end

  def test_no_error_only_the_hint_describes
    render_inline(UI::DatePicker.new(name: "starts_on"))
    input = page.find("input[type='text']")
    assert_equal "#{input[:id]}-hint", input["aria-describedby"]
    refute input["aria-invalid"]
  end
end
